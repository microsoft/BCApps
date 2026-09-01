// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Azure.Identity;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Privacy;
using System.Utilities;

page 9553 "Document Service Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'OneDrive Setup';
    AdditionalSearchTerms = 'onedrive,sharepoint,app,storage,Office,O365,M365,Microsoft 365';
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = NavigatePage;
    Extensible = false;
    Permissions = TableData "Document Service" = rimd, TableData "Document Service Scenario" = rimd;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(TopBanner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (not CompletedBannerVisible);
                field(NotDoneIcon; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(CompletedBanner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = CompletedBannerVisible;
                field(CompletedIcon; CompletedMediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(IntroStep)
            {
                Visible = IntroStepVisible;
                group("Welcome to OneDrive")
                {
                    Caption = 'Set up how to handle files with OneDrive for Business';

                    group("IntroductionSubgroup")
                    {
                        Caption = '';

                        label(IntroductionLabel)
                        {
                            ApplicationArea = All;
                            CaptionClass = IntroductionText;
                        }

                        label(IntroductionPart2Label)
                        {
                            ApplicationArea = All;
                            CaptionClass = IntroductionPart2Text;
                        }
                        field(LearnMoreFileSharing; LearnMoreFileSharingText)
                        {
                            ShowCaption = false;
                            Editable = false;
                            ApplicationArea = All;

                            trigger OnDrillDown()
                            begin
                                Hyperlink('https://go.microsoft.com/fwlink/?linkid=2195963');
                            end;
                        }
                    }
                }

                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    group(GetStartedGroup)
                    {
                        Caption = '';
                        InstructionalText = 'Choose Next to get started.';
                        Visible = NextActionEnabled;
                    }
                    group(MissingPermissions)
                    {
                        Caption = '';
                        InstructionalText = 'You do not have sufficient permissions to run this setup.';
                        Visible = not NextActionEnabled;
                    }
                }
            }

            group(PrivacyStep)
            {
                Visible = PrivacyStepVisible;

                group(PrivacySubgroup)
                {
                    Caption = 'Your privacy';

                    group(PrivacyIntro)
                    {
                        Caption = '';
                        InstructionalText = 'By enabling this service connection you agree:';
                    }

                    label(PrivacyLabel)
                    {
                        ApplicationArea = All;
                        CaptionClass = PrivacyText;
                    }
                }
            }

            group(MigrationStep)
            {
                Visible = MigrationStepVisible;

                group(MigrationOverview)
                {
                    Caption = 'Some settings need to change';

                    label(MigrationIntroLabel)
                    {
                        ApplicationArea = All;
                        CaptionClass = MigrationIntroText;
                    }

                    group(MigrationSummary)
                    {
                        Caption = '';

                        field(MigrationSummaryList; MigrationSummaryList)
                        {
                            Editable = false;
                            ApplicationArea = All;
                            MultiLine = true;
                            ShowCaption = false;
                        }
                    }

                    group(MigrationLinks)
                    {
                        Caption = '';

                        label(MigrationNotify)
                        {
                            ApplicationArea = All;
                            CaptionClass = ProductNotNotify;
                        }

                        field(MigrationLearnMoreFileSharing; LearnChangesToExperienceTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            ApplicationArea = All;

                            trigger OnDrillDown()
                            begin
                                Hyperlink('https://go.microsoft.com/fwlink/?linkid=2195964');
                            end;
                        }
                    }
                }
            }

            group(ConfigureStep)
            {
                Visible = ConfigureStepVisible;
                group(ConfigureIntroduction)
                {
                    Caption = 'Configure OneDrive file handling';

                    group(ConfigureAppFeatures)
                    {
                        Caption = '';

                        label(AppFeaturesIntro)
                        {
                            ApplicationArea = All;
                            CaptionClass = AppFeaturesIntroText;
                        }

                        field(EnableAppFeatures; EnableAppFeatures)
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies if users can use OneDrive for Business for application features, such as Open in OneDrive and Share';
                            Caption = 'Use with app features';
                        }
                    }

                    group(ConfigureSystemFeatures)
                    {
                        Caption = '';
                        label(SystemFeaturesIntro)
                        {
                            ApplicationArea = All;
                            CaptionClass = SystemFeaturesIntroText;
                        }
                        field(EnableSystemFeatures; EnableSystemFeatures)
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies if users can use OneDrive for Business for system features, such as Open in Excel';
                            Caption = 'Use with system features';
                        }
                    }

                    group(ConfigureLearnMore)
                    {
                        Caption = '';

                        field(LearnMoreFeatures; LearnMoreFeaturesTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            ApplicationArea = All;

                            trigger OnDrillDown()
                            begin
                                Hyperlink('https://go.microsoft.com/fwlink/?linkid=2195965');
                            end;
                        }
                    }
                }
            }

            group(ConfigureOnPremStep)
            {
                Visible = ConfigureOnPremStepVisible;
                group(ConfigureOnPrem)
                {
                    Caption = 'Configure Business Central';

                    group(ConfigureLocation)
                    {
                        Caption = '';

                        label(ConfigureOnPremIntroduction)
                        {
                            ApplicationArea = All;
                            CaptionClass = ConfigureOnPremIntroText;
                        }

                        field(OneDriveUrl; OneDriveUrl)
                        {
                            ApplicationArea = All;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the URL to your organization''s OneDrive for Business, typically something like https://myTenant-my.sharepoint.com/';
                            Caption = 'OneDrive URL';

                            trigger OnValidate()
                            var
                                Uri: Codeunit Uri;
                            begin
                                if OneDriveUrl = '' then
                                    Error(SpecifyOneDriveUrlErr);

                                OneDriveUrl := DelChr(OneDriveUrl, '=', ' ');

                                if (not Uri.IsValidUri(OneDriveUrl)) then
                                    Error(InvalidOneDriveUrlErr);

                                Uri.Init(OneDriveUrl);
                                OneDriveUrl := 'https://' + Uri.GetHost() + '/';
                            end;
                        }

                        field(LearnOneDriveURL; LearnOneDriveURLTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            ApplicationArea = All;

                            trigger OnDrillDown()
                            begin
                                Hyperlink('https://go.microsoft.com/fwlink/?linkid=2196125');
                            end;
                        }
                    }
                }
            }

            group(ConfigureSuccessStep)
            {
                Visible = DoneStepVisible;
                group(ConfigureSetupCompleteGroup)
                {
                    Caption = 'Success!';
                    Visible = HasEnabledSetup;

                    label(ConfigureSetupComplete)
                    {
                        ApplicationArea = All;
                        CaptionClass = ConfigureSetupEnabledText;
                    }

                    label(ConfigureSetupPolicies)
                    {
                        ApplicationArea = All;
                        CaptionClass = ConfigureSetupPoliciesText;
                    }
                }
                group(ConfigureOneDriveDisabledGroup)
                {
                    Caption = 'Success!';
                    Visible = not HasEnabledSetup;

                    label(ConfigureOneDriveDisabled)
                    {
                        ApplicationArea = All;
                        CaptionClass = ConfigureOneDriveDisabledText;
                    }

                    label(ConfigureOneDriveDisabledRerun)
                    {
                        ApplicationArea = All;
                        CaptionClass = ConfigureOneDriveDisabledRerunLbl;
                    }
                }
            }

            group(ConfigureM365Step)
            {
                Visible = ConfigureM365StepVisible;
                group(ConfigureM365Group)
                {
                    Caption = 'Configure Microsoft 365';

                    label(ConfigureM365Introduction)
                    {
                        ApplicationArea = All;
                        CaptionClass = ConfigureM365IntroText;
                    }

                    label(ConfigureM365Step1)
                    {
                        ApplicationArea = All;
                        CaptionClass = ConfigureM365Step1Text;
                    }

                    label(ConfigureM365Step2)
                    {
                        ApplicationArea = All;
                        CaptionClass = ConfigureM365Step2Text;
                    }

                    label(ConfigureM365Step3)
                    {
                        ApplicationArea = All;
                        CaptionClass = ConfigureM365Step3Text;
                    }
                    group(ConfigureM365LearnMore)
                    {
                        Caption = '';

                        field(LearnM365IndividualSettings; LearnM365IndividualSettingsTxt)
                        {
                            ShowCaption = false;
                            Editable = false;
                            ApplicationArea = All;

                            trigger OnDrillDown()
                            begin
                                Hyperlink('https://go.microsoft.com/fwlink/?linkid=2195966');
                            end;
                        }
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
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Visible = not HasEnabledSetup;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionConfigurePolicy)
            {
                ApplicationArea = All;
                Caption = 'Help me configure policy';
                Visible = HasEnabledSetup;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Visible = (not DoneActionEnabled) and (not AgreeActionEnabled) and (not TestConnectionActionEnabled);
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionAgree)
            {
                ApplicationArea = All;
                Caption = 'Agree';
                Visible = AgreeActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }

            action(ActionTestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test connection';
                Visible = TestConnectionActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    TestConnection();
                    NextStep(false);
                end;
            }

            action(ActionDone)
            {
                ApplicationArea = All;
                Caption = 'Done';
                Visible = DoneActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    DoneAction();
                end;
            }
        }
    }

    trigger OnInit()
    var
        ProductNameShort: Text;
    begin
        LoadTopBanner();
        ProductNameShort := ProductName.Short();

        IntroductionPart2Text := StrSubstNo(IntroductionPart2Lbl, ProductNameShort);
        ProductNotNotify := StrSubstNo(ProductNotNotifyTxt, ProductNameShort);
        LearnMoreFileSharingText := StrSubstNo(LearnMoreFileSharingLbl, ProductNameShort);
        PrivacyText := StrSubstNo(PrivacyLbl, ProductName.Full());
        AppFeaturesIntroText := StrSubstNo(AppFeaturesIntroLbl, ProductNameShort);
        SystemFeaturesIntroText := StrSubstNo(SystemFeaturesIntroLbl, ProductNameShort);
        ConfigureOnPremIntroText := StrSubstNo(ConfigureOnPremIntroLbl, ProductNameShort);
        ConfigureM365IntroText := StrSubstNo(ConfigureM365IntroLbl, ProductNameShort);
        ConfigureM365Step1Text := ConfigureM365Step1Lbl;
        ConfigureM365Step2Text := StrSubstNo(ConfigureM365Step2Lbl, ProductNameShort);
        ConfigureM365Step3Text := ConfigureM365Step3Lbl;
        ConfigureSetupEnabledText := StrSubstNo(ConfigureSetupEnabledLbl, ProductNameShort);
        ConfigureSetupPoliciesText := StrSubstNo(ConfigureSetupPoliciesLbl, ProductNameShort);
        ConfigureOneDriveDisabledText := StrSubstNo(ConfigureOneDriveDisabledLbl, ProductNameShort);
    end;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin

        IsSaaS := EnvironmentInformation.IsSaaSInfrastructure();
        EnableAppFeatures := IsSaaS; // By default, only enable file sharing in SaaS

        if IsSaaS then
            IntroductionText := StrSubstNo(IntroductionSaasLbl, ProductName.Short())
        else
            IntroductionText := StrSubstNo(IntroductionOnPremLbl, ProductName.Short());

        Step := Step::Intro;
        EnableControls(false);
    end;

    local procedure LoadSettings(var DocumentServiceScenario: Record "Document Service Scenario"): Boolean
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        exit(DocumentServiceManagement.GetOneDriveScenario(DocumentServiceScenario));
    end;

    local procedure EnableControls(Backwards: Boolean)
    begin
        ResetControls();

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::Privacy:
                ShowPrivacyStep(Backwards);
            Step::Migration:
                ShowMigrationStep(Backwards);
            Step::Configure:
                ShowConfigureStep();
            Step::ConfigureOnPrem:
                ShowConfigureOnPremStep(Backwards);
            Step::Done:
                ShowDoneStep();
            Step::ConfigureM365:
                ShowConfigureM365Step();
        end;
    end;

    local procedure DoneAction()
    begin
        CurrPage.Close();
    end;

    local procedure TestConnection()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        DocumentServiceManagement: Codeunit "Document Service Management";
        AccessToken: SecretText;
    begin
        if OneDriveUrl = '' then
            Error(SpecifyOneDriveUrlErr);

        AccessToken := AzureAdMgt.GetAccessTokenAsSecretText(OneDriveUrl, OneDriveUrl, true);
        if AccessToken.IsEmpty()  then
            Error(FailedToGetTokenErr);

        if not DocumentServiceManagement.TestLocationResolves(OneDriveUrl, AccessToken) then
            Error(LocationNotFoundErr);
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls(Backwards);
    end;

    local procedure ShowIntroStep()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        DocumentServiceScenario: Record "Document Service Scenario";
    begin
        IntroStepVisible := true;
        BackActionEnabled := false;

        NextActionEnabled := DocumentServiceScenario.ReadPermission() and DocumentServiceScenario.WritePermission();
    end;

    local procedure ShowPrivacyStep(Backwards: Boolean)
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        PrivacyApprovalState: Enum "Privacy Notice Approval State";
    begin
        PrivacyStepVisible := true;

        PrivacyApprovalState := PrivacyNotice.GetPrivacyNoticeApprovalState(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId());

        AgreeActionEnabled := true;

        if PrivacyApprovalState = PrivacyApprovalState::Agreed then
            NextStep(Backwards);
    end;

    local procedure ShowMigrationStep(Backwards: Boolean)
    var
        DocumentService: Record "Document Service";
        DocumentServiceScenario: Record "Document Service Scenario";
        DocumentServiceManagement: Codeunit "Document Service Management";
        DefaultFolderName: Text;
    begin
        DocumentServiceScenario.SetRange("Service Integration", DocumentServiceScenario."Service Integration"::OneDrive);
        if not DocumentServiceScenario.IsEmpty() then begin
            NextStep(Backwards);
            exit;
        end;

        if not DocumentServiceManagement.IsConfigured() then begin
            NextStep(Backwards);
            exit;
        end;

        if not DocumentService.FindFirst() then begin
            NextStep(Backwards);
            exit;
        end;

        // As an existing setup was detected, this means the features were previously enabled.
        EnableAppFeatures := true;
        EnableSystemFeatures := true;

        // Determine potentially breaking changes:
        MigrationSummaryList := '';
        if (DocumentService."User Name" <> '') and (DocumentService."Document Repository" <> '') then begin
            AppendToSummaryList(SharePointToPersonalStoreTxt);
            MigrationIntroText := MigrationSharePointIntroLbl;
        end else
            MigrationIntroText := MigrationIntroLbl;

        DefaultFolderName := DocumentServiceManagement.GetDefaultFolderName();
        if (DocumentService.Folder <> '') and (DocumentService.Folder <> DefaultFolderName) then
            AppendToSummaryList(StrSubstNo(FolderNameChangeTxt, DefaultFolderName, DocumentService.Folder));

        if IsSaaS then
            AppendSaasChangesToSummaryList(DocumentService);

        if DocumentService."Authentication Type" <> DocumentService."Authentication Type"::OAuth2 then
            AppendToSummaryList(AuthChangeTxt)
        else
            AppendOAuthChangeToSummaryList();

        MigrationStepVisible := true;
    end;

    local procedure AppendSaasChangesToSummaryList(var DocumentService: Record "Document Service")
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
        DefaultLocation: Text[250];
    begin
        if not DocumentServiceManagement.TryGetDefaultLocation(DefaultLocation) then begin
            AppendToSummaryList(StrSubstNo(DefaultFailedTxt, DocumentService.Location));
            exit;
        end;

        if DocumentService.Location <> DefaultLocation then
            AppendToSummaryList(StrSubstNo(LocationChangeTxt, DefaultLocation, DocumentService.Location));
    end;

    local procedure AppendOAuthChangeToSummaryList()
    var
        AzureADAppSetup: Record "Azure AD App Setup";
        DocumentService: Record "Document Service";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        CentralizedClientId: Text;
    begin
        if IsSaaS then begin
            AppendToSummaryList(OAuthSaasTxt);
            exit;
        end;

        if not AzureAdMgt.IsAzureADAppSetupDone() then begin
            AppendToSummaryList(StrSubstNo(OAuthChangeNotSetupTxt, ProductName.Short()));
            exit;
        end;

        AzureADAppSetup.FindFirst();
        DocumentService.FindFirst();
        CentralizedClientId := Format(AzureADAppSetup."App ID", 0, 4);
        if LowerCase(DocumentService."Client ID") = LowerCase(CentralizedClientId) then
            AppendToSummaryList(StrSubstNo(OAuthChangeWithSetupSameClientTxt, ProductName.Short(), CentralizedClientId))
        else
            AppendToSummaryList(StrSubstNo(OAuthChangeWithSetupTxt, ProductName.Short(), CentralizedClientId));
    end;

    local procedure AppendToSummaryList(SummaryText: Text)
    begin
        if SummaryText = '' then
            exit;

        MigrationSummaryList += StrSubstNo(MigrationSummaryItemLbl, SummaryText);
    end;

    local procedure ShowConfigureStep()
    var
        DocumentServiceScenario: Record "Document Service Scenario";
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        PrivacyApprovalState: Enum "Privacy Notice Approval State";
    begin
        ConfigureStepVisible := true;

        if LoadSettings(DocumentServiceScenario) then begin
            EnableAppFeatures := DocumentServiceScenario."Use for Application";
            EnableSystemFeatures := DocumentServiceScenario."Use for Platform";
        end;

        // If the privacy notice was originally explicitly disagreed to, then set the default state to false
        PrivacyApprovalState := PrivacyNotice.GetPrivacyNoticeApprovalState(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId());
        if PrivacyApprovalState = PrivacyApprovalState::Disagreed then begin
            EnableAppFeatures := false;
            EnableSystemFeatures := false;
        end;
    end;

    local procedure ShowConfigureOnPremStep(Backwards: Boolean)
    var
        DocumentService: Record "Document Service";
    begin
        ConfigureOnPremStepVisible := not IsSaaS and (EnableAppFeatures or EnableSystemFeatures);

        if not ConfigureOnPremStepVisible then begin
            NextStep(Backwards);
            exit;
        end;

        if DocumentService.FindFirst() then
            OneDriveUrl := DocumentService.Location;

        TestConnectionActionEnabled := true;
    end;

    local procedure ShowDoneStep()
    begin
        SaveChanges();

        DoneStepVisible := true;

        NextActionEnabled := false;
        DoneActionEnabled := true;

        HasEnabledSetup := EnableAppFeatures or EnableSystemFeatures;
        CompletedBannerVisible := HasEnabledSetup and CompletedMediaResourcesStandard."Media Reference".HasValue();
    end;

    local procedure ShowConfigureM365Step()
    begin
        ConfigureM365StepVisible := true;

        NextActionEnabled := false;
        DoneActionEnabled := true;
    end;

    local procedure ResetControls()
    begin
        DoneActionEnabled := false;
        AgreeActionEnabled := false;
        TestConnectionActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        IntroStepVisible := false;
        PrivacyStepVisible := false;
        MigrationStepVisible := false;
        ConfigureStepVisible := false;
        ConfigureOnPremStepVisible := false;
        DoneStepVisible := false;
        CompletedBannerVisible := false;
        ConfigureM365StepVisible := false;

        HasEnabledSetup := false;
    end;

    local procedure SaveChanges()
    var
        DocumentService: Record "Document Service";
        DocumentServiceScenario: Record "Document Service Scenario";
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        GuidedExperience: Codeunit "Guided Experience";
        PrivacyApprovalState: Enum "Privacy Notice Approval State";
        DocumentServiceCode: Code[30];
        NullGuid: Guid;
    begin
        DocumentService.DeleteAll();
        if not IsSaaS and (EnableAppFeatures or EnableSystemFeatures) then begin
            DocumentServiceCode := GetDocumentServiceCode();
            if DocumentServiceCode = '' then begin // could not generate a new name, revert setup
                EnableAppFeatures := false;
                EnableSystemFeatures := false;
                exit;
            end;

            if DocumentService.Get(DocumentServiceCode) then
                DocumentService.Delete();

            DocumentService."Service ID" := DocumentServiceCode;
            DocumentService.Location := OneDriveUrl;
            DocumentService.Insert();
        end;

        DocumentServiceScenario.SetRange("Service Integration", DocumentServiceScenario."Service Integration"::OneDrive);
        DocumentServiceScenario.DeleteAll(); // Clear OneDrive setups for all companies

        // Configure a setup for all companies
        DocumentServiceScenario.Validate("Service Integration", DocumentServiceScenario."Service Integration"::OneDrive);
        DocumentServiceScenario.Validate("Company", NullGuid);

        DocumentServiceScenario.Validate("Use for Application", EnableAppFeatures);
        DocumentServiceScenario.Validate("Use for Platform", EnableSystemFeatures);

        if not IsSaaS then
            DocumentServiceScenario.Validate("Document Service", DocumentService."Service ID");

        DocumentServiceScenario.Insert(true);

        // Agree to privacy notice
        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId(), PrivacyApprovalState::Agreed);

        // Mark setup completed
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Document Service Setup");
    end;

    local procedure GetDocumentServiceCode(): Code[30]
    var
        DocumentServiceScenario: Record "Document Service Scenario";
    begin
        if not LoadSettings(DocumentServiceScenario) then
            exit(GetNewDocumentServiceCode());

        if DocumentServiceScenario."Document Service" = '' then
            exit(GetNewDocumentServiceCode());

        exit(DocumentServiceScenario."Document Service");
    end;

    local procedure GetNewDocumentServiceCode(): Code[30]
    var
        DocumentService: Record "Document Service";
        CandidateName: Code[30];
        Suffix: Integer;
    begin
        if not DocumentService.Get(DocumentServiceCodeTemplateTxt) then
            exit(CopyStr(DocumentServiceCodeTemplateTxt, 1, MaxStrLen(DocumentService."Service ID")));

        for Suffix := 1 to 10000 do begin
            CandidateName := CopyStr(DocumentServiceCodeTemplateTxt + Format(Suffix), 1, MaxStrLen(DocumentService."Service ID"));
            if not DocumentService.Get(CandidateName) then
                exit(CandidateName);
        end;

        if Confirm(StrSubstNo(OverwriteExistingDocServiceQst, DocumentServiceCodeTemplateTxt)) then begin
            DocumentService.Get(DocumentServiceCodeTemplateTxt);
            DocumentService.Delete();
            exit(CandidateName);
        end;

        exit('');
    end;

    local procedure LoadTopBanner()
    begin
        if MediaResourcesStandard.Get('ASSISTEDSETUP-NOTEXT-400PX.PNG') and (CurrentClientType() = ClientType::Web)
        then
            TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue();

        if CompletedMediaResourcesStandard.Get('ASSISTEDSETUPDONE-NOTEXT-400px.PNG') and (CurrentClientType() = ClientType::Web) then;
    end;

    var
        MediaResourcesStandard: Record "Media Resources";
        CompletedMediaResourcesStandard: Record "Media Resources";
        OneDriveUrl: Text[250];
        MigrationSummaryList: Text;
        ProductNotNotify: Text;
        IntroductionText: Text;
        IntroductionPart2Text: Text;
        LearnMoreFileSharingText: Text;
        PrivacyText: Text;
        MigrationIntroText: Text;
        AppFeaturesIntroText: Text;
        SystemFeaturesIntroText: Text;
        ConfigureOnPremIntroText: Text;
        ConfigureM365IntroText: Text;
        ConfigureM365Step1Text: Text;
        ConfigureM365Step2Text: Text;
        ConfigureM365Step3Text: Text;
        ConfigureSetupEnabledText: Text;
        ConfigureSetupPoliciesText: Text;
        ConfigureOneDriveDisabledText: Text;
        IsSaaS: Boolean;
        TopBannerVisible: Boolean;
        CompletedBannerVisible: Boolean;
        BackActionEnabled: Boolean;
        DoneActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        AgreeActionEnabled: Boolean;
        TestConnectionActionEnabled: Boolean;
        IntroStepVisible: Boolean;
        PrivacyStepVisible: Boolean;
        MigrationStepVisible: Boolean;
        ConfigureStepVisible: Boolean;
        EnableAppFeatures: Boolean;
        EnableSystemFeatures: Boolean;
        ConfigureOnPremStepVisible: Boolean;
        DoneStepVisible: Boolean;
        ConfigureM365StepVisible: Boolean;
        HasEnabledSetup: Boolean;
        Step: Option Intro,Privacy,Migration,Configure,ConfigureOnPrem,Done,ConfigureM365;
        IntroductionSaasLbl: Label '%1 automatically enables integration to OneDrive for each new environment.', Comment = '%1=The short product name (e.g. Business Central)';
        IntroductionPart2Lbl: Label 'Administrators can configure how %1 users work with business files using their OneDrive, such as for sharing reports or exporting lists to Excel.', Comment = '%1=The short product name (e.g. Business Central)';
        IntroductionOnPremLbl: Label '%1 enables integration to OneDrive for each new environment.', Comment = '%1=The short product name (e.g. Business Central)';
        LearnMoreFileSharingLbl: Label 'Learn about working with %1 files in OneDrive', Comment = '%1=The short product name (e.g. Business Central)';
        PrivacyLbl: Label '(a) to share data from this %1 with the service provider, who will use it according to its terms and privacy policy; (b) the compliance levels of the service provider may be different than %1; and (c) Microsoft may share your contact information with this service provider if needed for it to operate and troubleshoot the service.', Comment = '%1=The short product name (e.g. Business Central)';
        LearnChangesToExperienceTxt: Label 'Learn how these changes affect your experience';
        MigrationIntroLbl: Label 'We found that you have connected this environment to OneDrive before. If you proceed with setup, some settings will be optimized for newer features that work with OneDrive:';
        MigrationSharePointIntroLbl: Label 'We found that you have connected this environment to SharePoint before. The ''SharePoint connection setup'' page will be deprecated in a future release. If you proceed with setup, this environment will connect to OneDrive instead of SharePoint and use different settings:';
        AppFeaturesIntroLbl: Label 'Some business application features that handle files can work with OneDrive. When OneDrive is enabled for app features, users can choose to download a %1 file, open it in the browser using OneDrive, or share it with others using the OneDrive sharing window.', Comment = '%1=The short product name (e.g. Business Central)';
        SystemFeaturesIntroLbl: Label 'Some system features in %1 can work with OneDrive. When OneDrive is enabled for these system features, files will always open in Excel for the web, Word for the web, or in OneDrive''s PDF viewer.', Comment = '%1=The short product name (e.g. Business Central)';
        LearnMoreFeaturesTxt: Label 'Learn which features are affected';
        ConfigureOnPremIntroLbl: Label 'When connecting %1 on premises to OneDrive for Business in the cloud, you must specify the URL to your organization''s OneDrive.', Comment = '%1=The short product name (e.g. Business Central)';
        ConfigureM365IntroLbl: Label 'The SharePoint admin center is where SharePoint admins can configure policies that govern how users share OneDrive files across Microsoft 365 apps, including %1.', Comment = '%1=The short product name (e.g. Business Central)';
        ConfigureM365Step1Lbl: Label '1. Navigate to Sharing in the SharePoint admin center.';
        ConfigureM365Step2Lbl: Label '2. Choose the defaults for file and folder links, sharing with external users, and other settings that will affect %1 and other apps.', Comment = '%1=The short product name (e.g. Business Central)';
        ConfigureM365Step3Lbl: Label '3. Save and close. The changes are immediately effective.';
        LearnOneDriveURLTxt: Label 'How do I find my OneDrive URL?';
        ConfigureSetupEnabledLbl: Label 'All companies in this %1 environment are now set up to use OneDrive.', Comment = '%1=The short product name (e.g. Business Central)';
        ConfigureSetupPoliciesLbl: Label '%1 users will be able to share files depending on your organization''s Microsoft 365 sharing policies.', Comment = '%1=The short product name (e.g. Business Central)';
        ConfigureOneDriveDisabledLbl: Label 'OneDrive has been turned off for all companies in this %1 environment.', Comment = '%1=The short product name (e.g. Business Central)';
        ConfigureOneDriveDisabledRerunLbl: Label 'When you are ready to enable OneDrive integration, just run this guide again.';
        LearnM365IndividualSettingsTxt: Label 'Learn how to change the external sharing setting for an individual user''s OneDrive';
        SpecifyOneDriveUrlErr: Label 'You must specify a OneDrive URL to connect to';
        InvalidOneDriveUrlErr: Label 'The specified OneDrive URL is not a valid URL.';
        FolderNameChangeTxt: Label 'Files will be saved to a folder named %1 instead of ''%2''', Comment = '%1=The short product name (e.g. Business Central), %2=The old folder name that had previously been configured';
        SharePointToPersonalStoreTxt: Label 'Instead of using a SharePoint site, documents will be uploaded to OneDrive';
        LocationChangeTxt: Label 'The OneDrive domain %1 will be used instead of ''%2''', Comment = '%1=The new OneDrive domain to be used, %2=The old OneDrive location that had previously been configured.';
        DefaultFailedTxt: Label 'Your OneDrive location could not be automatically determined and could change from ''%1''. Check https://portal.office.com/onedrive for more information.', Comment = '%1=The old OneDrive location that had previously been configured.';
        AuthChangeTxt: Label 'OAuth will be used for authentication';
        OAuthSaasTxt: Label 'The Microsoft Entra Application used for authentication no longer requires admin approval.';
        OAuthChangeNotSetupTxt: Label 'The Microsoft Entra Application used for authentication will be configured for all %1 integrations.', Comment = '%1=The short product name (e.g. Business Central)';
        OAuthChangeWithSetupTxt: Label 'The Microsoft Entra Application used for authentication will be configured for all %1 integrations. This means the client id will change to %2, you may want to test it has the correct permissions.', Comment = '%1=The short product name (e.g. Business Central), %2=The new client id, this is in the form of a guid.';
        OAuthChangeWithSetupSameClientTxt: Label 'The Microsoft Entra Application used for authentication will be configured for all %1 integrations. This has already been configured with the same client id (%2).', Comment = '%1=The short product name (e.g. Business Central), %2=The client id, this is in the form of a guid.';
        ProductNotNotifyTxt: Label '%1 does not notify users about these changes.', Comment = '%1=The short product name (e.g. Business Central)';
        DocumentServiceCodeTemplateTxt: Label 'ONEDRIVE', Locked = true;
        OverwriteExistingDocServiceQst: Label 'An existing setup already exists for %1. Can this be replaced?', Comment = '%1=The short product name (e.g. Business Central)';
        FailedToGetTokenErr: Label 'Failed to get a token for the specified OneDrive URL.';
        LocationNotFoundErr: Label 'Could not resolve your OneDrive location from the specified OneDrive URL.';
        MigrationSummaryItemLbl: Label '- %1\', Locked = true;
}
