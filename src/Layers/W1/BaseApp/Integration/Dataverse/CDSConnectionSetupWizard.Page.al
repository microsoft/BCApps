// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using System;
using System.Environment;
using System.Environment.Configuration;
using System.Security.Authentication;
using System.Telemetry;
using System.Utilities;

page 7201 "CDS Connection Setup Wizard"
{
    Caption = 'Dataverse Connection Setup', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

    PageType = NavigatePage;
    SourceTable = "CDS Connection Setup";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            group(BannerStandard)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and not CredentialsStepVisible;
                field(MediaResourceStandardReference; MediaResourcesStandard."Media Reference")
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
                field(MediaResourceDoneReference; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step0)
            {
                Visible = InfoStepVisible;

                Caption = '';
                group(Control2)
                {
                    InstructionalText = 'Quickly set up the connection, couple records, and even synchronize data.';
                    ShowCaption = false;

                    field(Synchronization; Synchronization)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Enable data synchronization';
                        ToolTip = 'Enable Business Central to synchronize data with Dataverse.';

                        trigger OnValidate()
                        begin
                            NextActionEnabled := Synchronization or BusinessEvents;
                        end;
                    }
                }
                group(Control1)
                {
                    InstructionalText = 'Connect Business Central to Dataverse to synchronize data with other business apps.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    ShowCaption = false;
                }
                group(BusinessEventsOption)
                {
                    InstructionalText = 'Quickly set up Business Central virtual tables in Dataverse and enable business events that Business Central sends to Dataverse.';
                    ShowCaption = false;

                    field("Business Events"; BusinessEvents)
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = BusinessEventsSupported;
                        Caption = 'Enable virtual tables and events';
                        ToolTip = 'Set up virtual tables and enable business events.';
                        trigger OnValidate()
                        begin
                            NextActionEnabled := Synchronization or BusinessEvents;
                        end;
                    }
                }
                group(Control3)
                {
                    InstructionalText = 'If you choose Next we will try to find your Dataverse environments so you can choose the one to connect to.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    ShowCaption = false;
                }
            }
            group(StepConsent)
            {
                InstructionalText = 'Please review terms and conditions.';
                Visible = ConsentStepVisible;
                field(ConsentLbl; ConsentLbl)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Editable = false;
                    Caption = ' ';
                    MultiLine = true;
                    ToolTip = 'Agree with the customer consent.';
                }
                field(Consent; ConsentVar)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'I accept';
                    ToolTip = 'Agree with the customer consent.';
                    trigger OnValidate()
                    begin
                        NextActionEnabled := false;
                        if ConsentVar then
                            NextActionEnabled := true;
                    end;
                }
                field(LearnMore; LearnMoreTok)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Caption = ' ';
                    ToolTip = 'View information about the privacy.';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(PrivacyLinkTxt);
                    end;
                }
            }
            group(StepApplication)
            {
                InstructionalText = 'Specify the ID, secret and redirect URL of the Microsoft Entra application that will be used to connect to Dataverse.', Comment = 'Dataverse and Microsoft Entra are names of Microsoft services and should not be translated.';
                ShowCaption = false;
                Visible = ApplicationStepVisible;

                field("Client Id"; Rec."Client Id")
                {
                    ApplicationArea = Suite;
                    Caption = 'Client ID';
                    ToolTip = 'Specifies the ID of the Microsoft Entra application that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Microsoft Entra are names of Microsoft services and should not be translated.';
                }
                field("Client Secret"; ClientSecret)
                {
                    ApplicationArea = Suite;
                    ExtendedDatatype = Masked;
                    Caption = 'Client Secret';
                    ToolTip = 'Specifies the secret of the Microsoft Entra application that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Microsoft Entra are names of Microsoft services and should not be translated.';

                    trigger OnValidate()
                    begin
                        ClientSecretEdited := true;
                        Rec.SetClientSecret(ClientSecret);
                    end;
                }
                field("Redirect URL"; Rec."Redirect URL")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the Redirect URL of the Microsoft Entra application that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Microsoft Entra are names of Microsoft services and should not be translated.';
                }
            }
            group(Step1)
            {
                Visible = AdminStepVisible;

                group(Control11)
                {
                    Caption = 'SET UP THE CONNECTION';
                    InstructionalText = 'Specify the URL of the Dataverse environment. Your environments appear in the list, or you can enter the URL.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    field(ServerAddress; Rec."Server Address")
                    {
                        ApplicationArea = Suite;
                        AssistEdit = true;
                        ToolTip = 'The Dataverse environment URL.';
                        Caption = 'The Dataverse environment URL.';
                        ShowCaption = false;

                        trigger OnValidate()
                        begin
                            CDSIntegrationImpl.CheckModifyConnectionURL(Rec."Server Address");
                            if Rec."Server Address" <> xRec."Server Address" then begin
                                HasAdminSignedIn := false;
                                NextActionEnabled := false;
                            end;
                            CurrPage.Update();
                        end;

                        trigger OnAssistEdit()
                        var
                            CDSEnvironment: Codeunit "CDS Environment";
                        begin
                            CDSEnvironment.SelectTenantEnvironment(Rec, CDSEnvironment.GetGlobalDiscoverabilityToken(), false);

                            if Rec."Server Address" <> xRec."Server Address" then begin
                                HasAdminSignedIn := false;
                                NextActionEnabled := false;
                            end;
                            CurrPage.Update();
                        end;
                    }
                }

                group(Control12)
                {
                    Caption = '';
                    InstructionalText = 'Sign in with an administrator user account and give consent to the application that will be used to connect to Dataverse. The account will be used one time to install and configure components that the integration requires.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    ShowCaption = false;

                    group(Control13)
                    {
                        Visible = not HasAdminSignedIn;
                        ShowCaption = false;

                        field(SignInAdmin; SignInAdminTxt)
                        {
                            Caption = 'Sign in';
                            ShowCaption = false;
                            Editable = false;
                            ApplicationArea = Suite;

                            trigger OnDrillDown()
                            begin
                                if Rec."Server Address" = '' then
                                    Error(NoEnvironmentSelectedErr);

                                HasAdminSignedIn := true;
                                CDSIntegrationImpl.SignInCDSAdminUser(Rec, CrmHelper, AdminUserName, AdminPassword, AdminAccessToken, AdminADDomain, false);
                                CDSIntegrationImpl.JITProvisionFirstPartyApp(CrmHelper);
                                Sleep(5000);

                                AreAdminCredentialsCorrect := true;
                                if UserPasswordEdited then
                                    Rec.SetPassword(UserPassword)
                                else
                                    Rec.SetPassword(CurrentCDSConnectionSetupPassword());
                                NextActionEnabled := true;

                                if BusinessEvents then
                                    ShowDifferentTenantWarning := CDSEnvironment.CheckIfEnvironmentInDifferentTenant(Rec."Server Address", CDSEnvironment.GetGlobalDiscoverabilityOnBehalfTokenAsSecretText());

                                CurrPage.Update(false);
                            end;
                        }
                    }

                    group(Control14)
                    {
                        Visible = HasAdminSignedIn and AreAdminCredentialsCorrect;
                        ShowCaption = false;

                        field(SuccesfullyLoggedIn; SuccesfullyLoggedInTxt)
                        {
                            ApplicationArea = Suite;
                            ToolTip = 'Indicates whether the administrator user has logged in successfully.';
                            Caption = 'The administrator is signed in.';
                            Editable = false;
                            ShowCaption = false;
                            Style = Favorable;
                        }
                    }

                    group(Control17)
                    {
                        Visible = HasAdminSignedIn and ShowDifferentTenantWarning;
                        ShowCaption = false;

                        field(DifferentTenantWarning; DifferentTenantWarningTxt)
                        {
                            ApplicationArea = Suite;
                            Tooltip = 'Indicates that the environment URL is from a different than Business Central environment and virtual tables will not work.';
                            Caption = 'The environment URL is from a different tenant.';
                            Editable = false;
                            ShowCaption = false;
                            Style = Unfavorable;
                        }
                    }

                    group(Control15)
                    {
                        Visible = HasAdminSignedIn and (not AreAdminCredentialsCorrect);
                        ShowCaption = false;

                        field(UnsuccesfullyLoggedIn; UnsuccesfullyLoggedInTxt)
                        {
                            ApplicationArea = Suite;
                            Tooltip = 'Indicates that the administrator user has not logged in successfully';
                            Caption = 'Could not sign in the administrator.';
                            Editable = false;
                            ShowCaption = false;
                            Style = Unfavorable;
                        }
                    }
                }

                group(Control16)
                {
                    InstructionalText = 'To install and configure integration components, choose Next. This might take a few minutes.';
                    ShowCaption = false;
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = CredentialsStepVisible;
                group("Integration User")
                {
                    Caption = '';
                    InstructionalText = 'Provide credentials for the user account that the business apps will use to authenticate when they exchange data. This should be an account that is used only for integration with Dataverse.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    group(Control22)
                    {
                        InstructionalText = 'This account must be a valid user in Dataverse and must not be assigned to the System Administrator role. When you finish this guide the account will become non-interactive.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                        ShowCaption = false;
                    }

                    field(Email; Rec."User Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'User Name';
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email of the user that will be used to connect to the Dataverse environment and synchronize data. This must not be the administrator user account.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                        trigger OnValidate()
                        begin
                            CDSIntegrationImpl.CheckUserName(Rec);
                        end;
                    }
                    field(Password; UserPassword)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password of the user that will be used to connect to the Dataverse environment and synchronize data.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                        trigger OnValidate()
                        begin
                            UserPasswordEdited := true;
                            Rec.SetPassword(UserPassword);
                        end;
                    }
                }

            }
            group(Step3)
            {
                Caption = '';
                Visible = OwnershipModelStepVisible;
                group("Ownership Model Selection")
                {
                    Caption = 'Choose an ownership model.';
                    InstructionalText = 'People or a team own records in Dataverse that are created from data in Business Central. We recommend the Team model.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    field("Ownership Model"; TempCDSConnectionSetup."Ownership Model")
                    {
                        Caption = 'Ownership Model';
                        ShowCaption = false;
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies the type of owner that will be assigned to any record that is created while synchronizing from Business Central to Dataverse.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                        trigger OnValidate()
                        begin
                            IsPersonOwnershipModelSelected := TempCDSConnectionSetup."Ownership Model" = TempCDSConnectionSetup."Ownership Model"::Person;
                            CurrPage.Update(false);
                        end;

                    }
                }
                group("Team Ownership Model")
                {
                    Caption = '';
                    InstructionalText = 'We will create a business unit and a team in Dataverse. Members of the team will own the synchronized data and can assign records to other users or teams in the business unit.';
                    Visible = not IsPersonOwnershipModelSelected;
                }
                group("Salesperson Ownership Model")
                {
                    Caption = '';
                    InstructionalText = 'Couple salespeople in Business Central with users in Dataverse. The salespeople will automatically own all synchronized data. Owners (people) can assign synchronized records to other users or teams in the business unit.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    Visible = IsPersonOwnershipModelSelected;
                }

                group("Skip Synchronization")
                {
                    Caption = 'Complete setup without synchronization';
                    InstructionalText = 'Choose this option to enable the connection without synchronizing data.';
                    field(FinishWithoutSynchronizingData; FinishWithoutSynchronizingData)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Complete without synchronization ';
                        ShowCaption = false;
                        ToolTip = 'Complete the Dataverse Assisted Setup without synchronizing data.';

                        trigger OnValidate()
                        begin
                            if FinishWithoutSynchronizingData then begin
                                NextActionEnabled := BusinessEvents;
                                FinishActionEnabled := not BusinessEvents;
                            end else begin
                                NextActionEnabled := true;
                                FinishActionEnabled := false;
                            end;

                            CurrPage.Update(false);
                        end;
                    }
                    group(Control31)
                    {
                        Visible = FinishWithoutSynchronizingData and BusinessEvents;
                        InstructionalText = 'When you choose Next, the Dataverse connection is enabled and you can start synchronizing data.';
                        ShowCaption = false;
                    }
                    group(Control32)
                    {
                        Visible = FinishWithoutSynchronizingData and (not BusinessEvents);
                        InstructionalText = 'When you choose Finish, the Dataverse connection is enabled and you can start synchronizing data.';
                        ShowCaption = false;
                    }
                }
            }
            group(Step4)
            {
                Visible = CoupleSalespersonsStepVisible;
                Caption = '';
                InstructionalText = 'The Person ownership model requires that you couple salespeople in Business Central with users in Dataverse before you synchronize data. Otherwise, synchronization will not be successful.';
                group(Control41)
                {
                    InstructionalText = 'The salespeople will own the synchronized data and can assign records to other users or teams in the business unit.';
                    ShowCaption = false;
                }
                field(CoupleSalesPeople; CoupleSalesPeopleTxt)
                {
                    Caption = 'Couple Salespeople';
                    ShowCaption = false;
                    Editable = false;
                    ApplicationArea = Suite;

                    trigger OnDrillDown()
                    var
                        CDSCoupleSalespersons: Page "CDS Couple Salespersons";
                    begin
                        if UserPasswordEdited then
                            Rec.SetPassword(UserPassword)
                        else
                            Rec.SetPassword(CurrentCDSConnectionSetupPassword());
                        CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);

                        CDSCoupleSalespersons.Editable := true;
                        CDSCoupleSalespersons.Initialize(CrmHelper);
                        if CDSCoupleSalespersons.RunModal() = Action::OK then begin
                            CoupledSalesPeople := true;
                            AddCoupledUsersToDefaultOwningTeam();
                        end;

                        CurrPage.Update(false);
                    end;
                }

            }
            group(Step5)
            {
                Caption = 'Review Recommendations for first-time synchronization.';
                Visible = FullSynchReviewStepVisible;

                group(Control51)
                {
                    InstructionalText = 'First-time synchronization depends on whether there is data in both business apps and the direction.';
                    ShowCaption = false;
                }
                group(Control52)
                {
                    InstructionalText = 'If you have data in both apps and want bi-directional synchronization you must couple each record using match-based coupling or manually.';
                    ShowCaption = false;
                }
                group(Control53)
                {
                    InstructionalText = 'We can analyze both business apps and provide recommendations for your first synchronization.';
                    ShowCaption = false;
                }
                field(SynchronizationRecommendations; SynchronizationRecommendationsLbl)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Caption = 'Show initial synchronization recommendations list.';
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;

                    trigger OnDrillDown()
                    var
                        CDSFullSynchReview: Page "CDS Full Synch. Review";
                    begin
                        Window.Open(GettingThingsReadyTxt);
                        if UserPasswordEdited then
                            Rec.SetPassword(UserPassword)
                        else
                            Rec.SetPassword(CurrentCDSConnectionSetupPassword());

                        CDSFullSynchReview.SetRecord(CRMFullSynchReviewLine);
                        CDSFullSynchReview.SetTableView(CRMFullSynchReviewLine);
                        CDSFullSynchReview.LookupMode := true;
                        Window.Close();
                        if CDSFullSynchReview.RunModal() = Action::LookupOK then;
                        CRMFullSynchReviewLine.FindSet();
                        repeat
                            if InitialSynchRecommendations.ContainsKey(CRMFullSynchReviewLine.Name) then
                                InitialSynchRecommendations.Set(CRMFullSynchReviewLine.Name, CRMFullSynchReviewLine."Initial Synch Recommendation")
                            else
                                InitialSynchRecommendations.Add(CRMFullSynchReviewLine.Name, CRMFullSynchReviewLine."Initial Synch Recommendation")
                        until CRMFullSynchReviewLine.Next() = 0;
                    end;
                }
                group(Control45)
                {
                    InstructionalText = 'After you choose Next, you can follow the progress of your first synchronization on the Dataverse Full Synch Review page. You might need to refresh the page to update the status.';
                    ShowCaption = false;
                    Visible = BusinessEvents;
                }
                group(Control46)
                {
                    InstructionalText = 'After you choose Finish, you can follow the progress of your first synchronization on the Dataverse Full Synch Review page. You might need to refresh the page to update the status.';
                    ShowCaption = false;
                    Visible = not BusinessEvents;
                }
            }
            group(StepBusinessEvents)
            {
                Visible = BusinessEventsStepVisible;

                group(Control61)
                {
                    Caption = 'SET UP VIRTUAL TABLES';
                    InstructionalText = 'Set up Business Central Virtual Tables app in a Dataverse environment to allow Business Central to send business events to Dataverse.';
                }
                group(Control62)
                {
                    InstructionalText = 'Use the link below to go to AppSource and get the the Business Central Virtual Table app, so you can install it in your Dataverse environment. To refresh status after you install, click back and next.';
                    ShowCaption = false;

                    field(InstallVirtualTableApp; VirtualTableAppInstallTxt)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        Caption = ' ';
                        ToolTip = 'Get the Business Central Virtual Table app from Microsoft AppSource.';

                        trigger OnDrillDown()
                        begin
                            Hyperlink(CDSIntegrationImpl.GetVirtualTablesAppSourceLink());
                            FinishActionEnabled := true;
                        end;
                    }
                }
                group(Control63)
                {
                    Visible = VirtualTableAppInstalled;
                    ShowCaption = false;

                    field(VirtualTableAppInstalledLbl; VirtualTableAppInstalledTxt)
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Indicates whether the Business Central Virtual Table app is installed in the Dataverse environment.';
                        Caption = 'The Business Central Virtual Table app is installed.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Favorable;
                    }
                    field(EnableVirtualTablesLbl; 'Review and enable virtual tables')
                    {
                        ApplicationArea = Suite;
                        Caption = ' ';
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;

                        trigger OnDrillDown()
                        var
                            CDSAvailableVirtualTables: Page "CDS Available Virtual Tables";
                        begin
                            SetupBusinessEvents();
                            CDSAvailableVirtualTables.Run();
                        end;
                    }
                }
                group(Control64)
                {
                    Visible = not VirtualTableAppInstalled;
                    ShowCaption = false;

                    field(VirtualTableAppNotInstalledLbl; VirtualTableAppNotInstalledTxt)
                    {
                        ApplicationArea = Suite;
                        Tooltip = 'Indicates that the Business Central Virtual Table app is not installed in the Dataverse environment.';
                        Caption = 'The Business Central Virtual Table app is not installed.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Ambiguous;
                    }
                }
                group(Control66)
                {
                    InstructionalText = 'Choose Finish to set up the connection from Dataverse to Business Central and configure virtual tables in your Dataverse environment.';
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    CDSConnectionSetup: Record "CDS Connection Setup";
                begin
                    case Step of
                        Step::FullSynchReview:
                            if not IsPersonOwnershipModelSelected then begin
                                CDSConnectionSetup.Get();
                                CDSConnectionSetup.Validate("Is Enabled", false);
                                CDSConnectionSetup.Modify(true);
                                Commit();
                            end;
                        Step::CoupleSalespersons:
                            begin
                                CDSConnectionSetup.Get();
                                CDSConnectionSetup.Validate("Is Enabled", false);
                                CDSConnectionSetup.Modify(true);
                                Commit();
                            end;
                    end;

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
                var
                    CDSConnectionSetup: Record "CDS Connection Setup";
                    AuthenticationType: Option Office365,AD,IFD,OAuth;
                begin
                    case Step of
                        Step::Consent:
                            begin
                                AuthenticationType := Rec."Authentication Type";
                                GetCDSEnvironment();
                                Rec."Authentication Type" := AuthenticationType;
                            end;

                        Step::Application:
                            begin
                                if not CDSConnectionSetup.Get() then begin
                                    CDSConnectionSetup.Init();
                                    CDSConnectionSetup.Insert();
                                end;

                                CDSConnectionSetup.Validate("Client Id", Rec."Client Id");
                                if ClientSecretEdited then
                                    CDSConnectionSetup.SetClientSecret(ClientSecret)
                                else
                                    CDSConnectionSetup.SetClientSecret(CDSConnectionSetup.GetSecretClientSecret());
                                CDSConnectionSetup.Validate("Redirect URL", Rec."Redirect URL");
                                Rec.Modify();
                            end;

                        Step::Admin:
                            begin
                                if (Rec."Server Address" = '') then
                                    Error(URLShouldNotBeEmptyErr);

                                if Synchronization then
                                    ImportCDSSolution();
                            end;

                        Step::IntegrationUser:
                            begin
                                if (Rec."User Name" = '') or (UserPassword = '') then
                                    Error(UsernameAndPasswordShouldNotBeEmptyErr);
                                if UserPasswordEdited then
                                    Rec.SetPassword(UserPassword)
                                else
                                    Rec.SetPassword(CurrentCDSConnectionSetupPassword());
                                if not CDSIntegrationImpl.TryCheckCredentials(Rec) then
                                    Error(WrongCredentialsErr);
                                CDSIntegrationImpl.CheckIntegrationUserPrerequisites(Rec, AdminUserName, AdminPassword, AdminAccessToken, AdminADDomain);
                            end;

                        Step::CoupleSalespersons:
                            begin
                                if (CoupledSalesPeople = false) then
                                    Error(SalespeoplShouldBeCoupledErr);
                                Window.Open(GettingThingsReadyTxt);
                                CRMFullSynchReviewLine.DeleteAll();
                                CRMFullSynchReviewLine.Generate();
                                Commit();
                                Window.Close();
                            end;

                        Step::OwnershipModel:
                            begin
                                Window.Open(GettingThingsReadyTxt);
                                ConfigureCDSSolution();
                                if not IsPersonOwnershipModelSelected then begin
                                    CRMFullSynchReviewLine.DeleteAll();
                                    CRMFullSynchReviewLine.Generate();
                                    Commit();
                                end;
                                Window.Close();
                            end;
                    end;

                    NextStep(false);

                    if Step = Step::BusinessEvents then begin
                        VirtualTableAppInstalled := IsVirtualTablesAppInstalled();
                        FinishActionEnabled := VirtualTableAppInstalled;
                    end;
                end;
            }
            action(ActionRefresh)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh';
                Visible = Step = Step::BusinessEvents;
                Enabled = not VirtualTableAppInstalled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    VirtualTableAppInstalled := IsVirtualTablesAppInstalled();
                    ShowBusinessEventsStep();
                    CurrPage.Update();
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
                    GuidedExperience: Codeunit "Guided Experience";
                    FeatureTelemetry: Codeunit "Feature Telemetry";
                    CRMFullSynchReview: Page "CRM Full Synch. Review";
                    CDSCoupleSalespersons: Page "CDS Couple Salespersons";
                begin
                    if Synchronization then begin
                        Session.LogMessage('0000GBE', SetupSynchronizationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        if FinishWithoutSynchronizingData then begin
                            Window.Open(GettingThingsReadyTxt);
                            ConfigureCDSSolution();
                            Session.LogMessage('0000CDW', FinishWithoutSynchronizingDataTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                            if IsPersonOwnershipModelSelected then
                                if Confirm(OpenCoupleSalespeoplePageQst) then begin
                                    Window.Close();
                                    CDSCoupleSalespersons.Initialize(CrmHelper);
                                    CDSCoupleSalespersons.Run();
                                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"CDS Connection Setup Wizard");
                                    SetupCompleted := true;
                                    AddCoupledUsersToDefaultOwningTeam();
                                    CurrPage.Close();
                                    exit;
                                end;
                            Window.Close();
                            Page.Run(Page::"CDS Connection Setup");
                        end else begin
                            Window.Open(GettingThingsReadyTxt);
                            CRMFullSynchReviewLine.DeleteAll(true);
                            CRMFullSynchReviewLine.Generate(InitialSynchRecommendations);
                            CRMFullSynchReviewLine.Start();
                            CRMFullSynchReview.SetRecord(CRMFullSynchReviewLine);
                            CRMFullSynchReview.SetTableView(CRMFullSynchReviewLine);
                            CRMFullSynchReview.LookupMode := true;
                            Session.LogMessage('0000CDZ', FinishWithSynchronizingDataTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                            Window.Close();
                            CRMFullSynchReview.Run();
                        end;
                    end;

                    if BusinessEvents then
                        SetupBusinessEvents();

                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"CDS Connection Setup Wizard");
                    FeatureTelemetry.LogUptake('0000H7H', 'Dataverse', Enum::"Feature Uptake Status"::"Set up");
                    FeatureTelemetry.LogUptake('0000IIO', 'Dataverse Base Entities', Enum::"Feature Uptake Status"::"Set up");
                    SetupCompleted := true;
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
        SoftwareAsAService := EnvironmentInfo.IsSaaSInfrastructure();
        BusinessEventsSupported := CDSIntegrationImpl.GetBusinessEventsSupported();
        Synchronization := true;
        BusinessEvents := BusinessEventsSupported;
    end;

    trigger OnOpenPage()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        CDSConnectionSetup2: Record "CDS Connection Setup";
        OAuth2: Codeunit "OAuth2";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        RedirectUrl: Text;
        SecretUserPassword: SecretText;
        SecretClientSecret: SecretText;
    begin
        if not CDSConnectionSetup2.WritePermission() then
            Error(NoPermissionsErr);
        FeatureTelemetry.LogUptake('0000H7I', 'Dataverse', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000IIP', 'Dataverse Base Entities', Enum::"Feature Uptake Status"::Discovered);
        CDSConnectionSetup.EnsureCRMConnectionSetupIsDisabled();
        Rec.Init();
        if CDSConnectionSetup.Get() then begin
            TempCDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model";
            Rec."Proxy Version" := CDSConnectionSetup."Proxy Version";
            Rec."Authentication Type" := CDSConnectionSetup."Authentication Type";
            Rec."Server Address" := CDSConnectionSetup."Server Address";
            Rec."User Name" := CDSConnectionSetup."User Name";
            UserPassword := '**********';
            SecretUserPassword := CDSConnectionSetup.GetSecretPassword();
            Rec.SetPassword(SecretUserPassword);
            if not SoftwareAsAService then begin
                Rec."Client Id" := CDSConnectionSetup."Client Id";
                ClientSecret := '**********';
                SecretClientSecret := CDSConnectionSetup.GetSecretClientSecret();
                Rec.SetClientSecret(SecretClientSecret);
                Rec."Redirect URL" := CDSConnectionSetup."Redirect URL";
            end;
        end else begin
            CDSConnectionSetup.Init();
            CDSConnectionSetup.Insert();
            TempCDSConnectionSetup."Ownership Model" := TempCDSConnectionSetup."Ownership Model"::Team;
            InitializeDefaultAuthenticationType();
            InitializeDefaultProxyVersion();
        end;
        if not SoftwareAsAService then
            if Rec."Redirect URL" = '' then begin
                OAuth2.GetDefaultRedirectUrl(RedirectUrl);
                Rec."Redirect URL" := CopyStr(RedirectUrl, 1, MaxStrLen(Rec."Redirect URL"));
            end;
        IsPersonOwnershipModelSelected := TempCDSConnectionSetup."Ownership Model" = TempCDSConnectionSetup."Ownership Model"::Person;
        Rec.Insert();
        Step := Step::Info;
        EnableControls();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if CloseAction <> ACTION::OK then
            exit;

        if SetupCompleted then
            exit;

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Is Enabled" then begin
                if not Confirm(ConnectionNotCompletedQst, false) then
                    Error('');
                CDSConnectionSetup.Validate("Is Enabled", false);
                CDSConnectionSetup.Modify(true);
                exit;
            end;

        if not Confirm(ConnectionNotSetUpQst, false) then
            Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CDSEnvironment: Codeunit "CDS Environment";
        ClientTypeManagement: Codeunit "Client Type Management";
        CrmHelper: DotNet CrmHelper;
        Step: Option Info,Consent,Application,Admin,IntegrationUser,OwnershipModel,CoupleSalespersons,FullSynchReview,BusinessEvents,Finish;
        Window: Dialog;
        AdminAccessToken: SecretText;
        [NonDebuggable]
        AdminUserName: Text;
        AdminPassword: SecretText;
        [NonDebuggable]
        AdminADDomain: Text;
        [NonDebuggable]
        ClientSecret: Text;
        ClientSecretEdited: Boolean;
        SoftwareAsAService: Boolean;
        ApplicationStepVisible: Boolean;
        TopBannerVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        InfoStepVisible: Boolean;
        AdminStepVisible: Boolean;
        CredentialsStepVisible: Boolean;
        OwnershipModelStepVisible: Boolean;
        CoupleSalespersonsStepVisible: Boolean;
        FullSynchReviewStepVisible: Boolean;
        BusinessEventsStepVisible: Boolean;
        CoupledSalesPeople: Boolean;
        IsPersonOwnershipModelSelected: Boolean;
        HasAdminSignedIn: Boolean;
        AreAdminCredentialsCorrect: Boolean;
        FinishWithoutSynchronizingData: Boolean;
        SetupCompleted: Boolean;
        Synchronization: Boolean;
        BusinessEvents: Boolean;
        BusinessEventsSupported: Boolean;
        VirtualTableAppInstalled: Boolean;
        ConsentVar: Boolean;
        ConsentStepVisible: Boolean;
        ShowDifferentTenantWarning: Boolean;
        InitialSynchRecommendations: Dictionary of [Code[20], Integer];
        ScopesLbl: Label 'https://globaldisco.crm.dynamics.com/user_impersonation', Locked = true;
        OpenCoupleSalespeoplePageQst: Label 'The Person ownership model requires that you couple salespeople in Business Central with users in Dataverse before you synchronize data. Otherwise, synchronization will not be successful.\\ Do you want to want to couple salespeople and users now?';
        SynchronizationRecommendationsLbl: Label 'Show synchronization recommendations';
        ConsentLbl: Label 'By enabling this feature, you consent to your data being shared with a Microsoft service that might be outside of your organization''s selected geographic boundaries and might have different compliance and security standards than Microsoft Dynamics Business Central. Your privacy is important to us, and you can choose whether to share data with the service. To learn more, follow the link below.';
        PrivacyLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=521839';
        LearnMoreTok: Label 'Privacy and Cookies';
        [NonDebuggable]
        UserPassword: Text;
        UserPasswordEdited: Boolean;
        SuccesfullyLoggedInTxt: Label 'The administrator is signed in.';
        UnsuccesfullyLoggedInTxt: Label 'Could not sign in the administrator.';
        VirtualTableAppInstalledTxt: Label 'The Business Central Virtual Table app is installed.';
        VirtualTableAppNotInstalledTxt: Label 'The Business Central Virtual Table app is not installed.';
        SignInAdminTxt: Label 'Sign in with administrator user';
        CoupleSalesPeopleTxt: Label 'Couple Salespeople to Users';
        NoEnvironmentSelectedErr: Label 'To sign in the administrator user you must specify an environment.';
        ConnectionNotSetUpQst: Label 'The connection to Dataverse environment has not been set up.\\Are you sure you want to exit?';
        ConnectionNotCompletedQst: Label 'The setup for Dataverse is not complete. The connection to the Dataverse environment will be disabled.\\Are you sure you want to exit?';
        WrongCredentialsErr: Label 'The credentials provided are incorrect.';
        UsernameAndPasswordShouldNotBeEmptyErr: Label 'You must specify a username and a password for the integration user';
        SalespeoplShouldBeCoupledErr: Label 'When the Person ownership model is selected, coupling of salespeople is required.';
        URLShouldNotBeEmptyErr: Label 'You must specify the URL of your Dataverse environment.';
        AdminUserShouldBesignedInErr: Label 'The admin user must be connected in order to proceed.';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        SetupVirtualTablesTxt: Label 'Setup virtual tables.', Locked = true;
        SetupSynchronizationTxt: Label 'Setup data synchronization.', Locked = true;
        FinishWithoutSynchronizingDataTxt: Label 'User has chosen to finalize Dataverse configuration without synchronizing data.', Locked = true;
        FinishWithSynchronizingDataTxt: Label 'User has chosen to finalize Dataverse configuration also synchronizing data.', Locked = true;
        GettingThingsReadyTxt: Label 'Getting things ready for you.';
        VirtualTableAppNotInstalledErr: Label 'Business Central Virtual Table app is not installed.';
        VirtualTableAppInstallTxt: Label 'Install Business Central Virtual Table app';
        NoPermissionsErr: Label 'Your license does not allow you to set up the connection to Dataverse. To view details about your permissions, see the Effective Permissions page.';
        DifferentTenantWarningTxt: Label 'Environment URL is from a different tenant. Virtual tables won''t work.';

    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure GetCDSEnvironment()
    var
        OAuth2: Codeunit OAuth2;
        Scopes: List of [Text];
        Token: SecretText;
        RedirectUrl: Text;
    begin
        if SoftwareAsAService then
            RedirectUrl := CDSIntegrationImpl.GetRedirectURL()
        else
            RedirectUrl := Rec."Redirect URL";
        Scopes.Add(ScopesLbl);
        OAuth2.AcquireOnBehalfOfToken(RedirectUrl, Scopes, Token);
        CDSEnvironment.SelectTenantEnvironment(Rec, Token, false);
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    local procedure NextStep(Backward: Boolean)
    begin
        UpdateAvailableStepNumber(Backward);
        EnableControls();
        SetupCompleted := false;
    end;

    local procedure UpdateAvailableStepNumber(Backward: Boolean)
    begin
        repeat
            UpdateStepNumber(Backward);
        until IsStepAvailable();
    end;

    local procedure UpdateStepNumber(Backward: Boolean)
    begin
        if Backward then
            Step := Step - 1
        else
            Step := Step + 1;
    end;

    local procedure IsStepAvailable(): Boolean
    begin
        case Step of
            Step::OwnershipModel:
                if not Synchronization then
                    exit(false);

            Step::FullSynchReview:
                if (not Synchronization) or FinishWithoutSynchronizingData then
                    exit(false);

            Step::IntegrationUser:
                begin
                    if not Synchronization then
                        exit(false);
                    if Rec."Authentication Type" = Rec."Authentication Type"::Office365 then
                        // skip the user credentials step in Office365 authentication
                        // we don't use username/password authentication
                        // we inject an application user and use ClientId/ClientSecret authentication
                        exit(false);
                end;

            Step::CoupleSalespersons:
                begin
                    if not Synchronization then
                        exit(false);
                    if not IsPersonOwnershipModelSelected then
                        exit(false);
                end;

            Step::Application:
                if SoftwareAsAService then
                    // skip the application step in SaaS as we use the default application
                    exit(false);

            Step::BusinessEvents:
                if not BusinessEvents then
                    exit(false);
        end;

        exit(true);
    end;

    local procedure EnableControls()
    begin
        case Step of
            Step::Info:
                ShowInfoStep();
            Step::Consent:
                ShowConsentStep();
            Step::Application:
                ShowApplicationStep();
            Step::Admin:
                ShowAdminStep();
            Step::IntegrationUser:
                ShowIntegrationUserStep();
            Step::OwnershipModel:
                ShowOwnershipModelStep();
            Step::CoupleSalespersons:
                ShowCoupleSalespersonsStep();
            Step::FullSynchReview:
                ShowFullSynchReviewStep();
            Step::BusinessEvents:
                ShowBusinessEventsStep();
        end;
    end;

    local procedure ShowInfoStep()
    begin
        BackActionEnabled := false;
        NextActionEnabled := true;
        FinishActionEnabled := false;

        InfoStepVisible := true;
        ConsentStepVisible := false;
        ApplicationStepVisible := false;
        AdminStepVisible := false;
        BusinessEventsStepVisible := false;
        CredentialsStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;
    end;

    local procedure ShowConsentStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;
        if not ConsentVar then
            NextActionEnabled := false;
        FinishActionEnabled := false;

        InfoStepVisible := false;
        ConsentStepVisible := true;
        ApplicationStepVisible := false;
        AdminStepVisible := false;
        BusinessEventsStepVisible := false;
        CredentialsStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;
    end;

    local procedure ShowApplicationStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;
        FinishActionEnabled := false;

        ConsentStepVisible := false;
        InfoStepVisible := false;
        ApplicationStepVisible := true;
        AdminStepVisible := false;
        BusinessEventsStepVisible := false;
        CredentialsStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;
    end;

    local procedure ShowAdminStep()
    begin
        BackActionEnabled := true;
        if HasAdminSignedIn then
            NextActionEnabled := true
        else
            NextActionEnabled := false;
        FinishActionEnabled := false;

        InfoStepVisible := false;
        ConsentStepVisible := false;
        ApplicationStepVisible := false;
        AdminStepVisible := true;
        BusinessEventsStepVisible := false;
        CredentialsStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;

        Rec."Authentication Type" := Rec."Authentication Type"::Office365;
    end;

    local procedure ShowIntegrationUserStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;
        FinishActionEnabled := false;

        InfoStepVisible := false;
        ConsentStepVisible := false;
        ApplicationStepVisible := false;
        AdminStepVisible := false;
        BusinessEventsStepVisible := false;
        CredentialsStepVisible := true;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;
    end;

    local procedure ShowOwnershipModelStep()
    begin
        BackActionEnabled := true;
        if FinishWithoutSynchronizingData then begin
            NextActionEnabled := BusinessEvents;
            FinishActionEnabled := not BusinessEvents;
        end else begin
            NextActionEnabled := true;
            FinishActionEnabled := false;
        end;

        InfoStepVisible := false;
        ApplicationStepVisible := false;
        AdminStepVisible := false;
        BusinessEventsStepVisible := false;
        CredentialsStepVisible := false;
        OwnershipModelStepVisible := true;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;

        CoupledSalesPeople := false;
    end;

    local procedure ShowCoupleSalespersonsStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;
        FinishActionEnabled := false;

        InfoStepVisible := false;
        ApplicationStepVisible := false;
        AdminStepVisible := false;
        BusinessEventsStepVisible := false;
        CredentialsStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := true;
        FullSynchReviewStepVisible := false;

        CoupledSalesPeople := false;
    end;

    local procedure ShowFullSynchReviewStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := BusinessEvents;
        FinishActionEnabled := not BusinessEvents;

        InfoStepVisible := false;
        ApplicationStepVisible := false;
        AdminStepVisible := false;
        BusinessEventsStepVisible := false;
        CredentialsStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := true;
    end;

    local procedure ShowBusinessEventsStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := false;
        FinishActionEnabled := VirtualTableAppInstalled;

        InfoStepVisible := false;
        ApplicationStepVisible := false;
        AdminStepVisible := false;
        BusinessEventsStepVisible := true;
        CredentialsStepVisible := false;
        OwnershipModelStepVisible := false;
        CoupleSalespersonsStepVisible := false;
        FullSynchReviewStepVisible := false;
    end;

    local procedure InitializeDefaultAuthenticationType()
    begin
        Rec.Validate("Authentication Type", Rec."Authentication Type"::Office365);
    end;

    local procedure InitializeDefaultProxyVersion()
    begin
        Rec.Validate("Proxy Version", CDSIntegrationImpl.GetLastProxyVersionItem());
    end;

    local procedure FinalizeBusinessEventsSetup()
    begin
        Rec."Business Events Enabled" := true;
        if not SoftwareAsAService then
            if ClientSecretEdited then
                Rec.SetClientSecret(ClientSecret)
            else
                Rec.SetClientSecret(CurrentCDSConnectionSetupClientSecret());
        CDSIntegrationImpl.UpdateBusinessEventsSetupFromWizard(Rec);
    end;

    local procedure FinalizeSynchronizationSetup()
    begin
        Rec."Ownership Model" := TempCDSConnectionSetup."Ownership Model";
        Rec."Is Enabled" := true;
        if not SoftwareAsAService then
            if ClientSecretEdited then
                Rec.SetClientSecret(ClientSecret)
            else
                Rec.SetClientSecret(CurrentCDSConnectionSetupClientSecret());
        if UserPasswordEdited then
            CDSIntegrationImpl.UpdateConnectionSetupFromWizard(Rec, UserPassword)
        else
            CDSIntegrationImpl.UpdateConnectionSetupFromWizard(Rec, CurrentCDSConnectionSetupPassword());
    end;

    local procedure CurrentCDSConnectionSetupClientSecret(): SecretText
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        CDSConnectionSetup.Get();
        exit(CDSConnectionSetup.GetSecretClientSecret());
    end;

    local procedure CurrentCDSConnectionSetupPassword(): SecretText
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        CDSConnectionSetup.Get();
        exit(CDSConnectionSetup.GetSecretPassword());
    end;

    [NonDebuggable]
    local procedure ConfigureCDSSolution()
    var
        CDSConectionSetup: Record "CDS Connection Setup";
    begin
        if Rec."Authentication Type" <> Rec."Authentication Type"::Office365 then begin
            if UserPasswordEdited then
                Rec.SetPassword(UserPassword)
            else
                Rec.SetPassword(CurrentCDSConnectionSetupPassword());
            CDSIntegrationImpl.CheckCredentials(Rec);
        end;
        CDSIntegrationImpl.ConfigureIntegrationSolution(Rec, CrmHelper, AdminUserName, AdminPassword, AdminAccessToken, AdminADDomain, true);

        FinalizeSynchronizationSetup();

        if CDSConectionSetup.Get() then begin
            CDSIntegrationImpl.RegisterConnection(CDSConectionSetup, false);
            CDSIntegrationImpl.ActivateConnection();
            CDSIntegrationImpl.ClearConnectionDisableReason(CDSConectionSetup);
            CDSConectionSetup.EnableIntegrationTables();
        end;

        Commit();
    end;

    [NonDebuggable]
    local procedure ImportCDSSolution()
    begin
        if not HasAdminSignedIn then
            Error(AdminUserShouldBesignedInErr);

        Window.Open(GettingThingsReadyTxt);
        CDSIntegrationImpl.ImportIntegrationSolution(Rec, CrmHelper, AdminUserName, AdminPassword, AdminAccessToken, AdminADDomain, false);
        Window.Close();
    end;

    local procedure AddCoupledUsersToDefaultOwningTeam()
    begin
        CDSIntegrationImpl.AddCoupledUsersToDefaultOwningTeam(Rec, CrmHelper);
    end;

    local procedure IsVirtualTablesAppInstalled(): Boolean
    var
        [NonDebuggable]
        TempAdminCDSConnectionSetup: Record "CDS Connection Setup" temporary;
    begin
        CDSIntegrationImpl.GetTempConnectionSetup(TempAdminCDSConnectionSetup, Rec, AdminAccessToken);
        exit(CDSIntegrationImpl.IsVirtualTablesAppInstalled(TempAdminCDSConnectionSetup));
    end;

    local procedure SetupBusinessEvents()
    begin
        VirtualTableAppInstalled := IsVirtualTablesAppInstalled();
        if not VirtualTableAppInstalled then begin
            FinishActionEnabled := false;
            Error(VirtualTableAppNotInstalledErr);
        end;

        Session.LogMessage('0000GBD', SetupVirtualTablesTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        Window.Open(GettingThingsReadyTxt);
        CDSIntegrationImpl.SetupVirtualTables(Rec, CrmHelper, AdminAccessToken, Rec."Virtual Tables Config Id");
        FinalizeBusinessEventsSetup();
        Window.Close();
    end;
}
