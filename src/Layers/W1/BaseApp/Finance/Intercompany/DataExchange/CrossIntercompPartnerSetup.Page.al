// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using System.Environment;

page 561 "CrossIntercomp. Partner Setup"
{
    Caption = 'IC Partner Cross-Environment Setup';
    PageType = NavigatePage;
    UsageCategory = None;
    SourceTable = "IC Partner";
    DeleteAllowed = false;
    SourceTableTemporary = true;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(WelcomeTab)
            {
                ShowCaption = false;
                Visible = Step = Step::Welcome;
                group(Introduction)
                {
                    Caption = 'Welcome';
                    InstructionalText = 'This setup guide will help you create a connection to a partner company in a different environment. Before you continue, make sure that the partner has enabled this extension in their company. You will need some information about their environment.';
                }
                group(TermsAndConditions)
                {
                    Caption = 'Review the terms and conditions';
                    InstructionalText = 'By enabling this feature, you consent to your data being shared with a Microsoft service that might be outside of your organization''s selected geographic boundaries and might have different compliance and security standards than Microsoft Dynamics Business Central. Your privacy is important to us, and you can choose whether to share data with the service. To learn more, follow the link below.';

                    field(Consent; ConsentState)
                    {
                        ApplicationArea = All;
                        Caption = 'I accept';
                        ToolTip = 'Accept the terms and conditions.';

                        trigger OnValidate()
                        begin
                            NextEnabled := false;
                            if ConsentState then
                                NextEnabled := true;
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
            }
            group(AuthenticationSetup_SaaSTab)
            {
                ShowCaption = false;
                Editable = true;
                Enabled = true;
                Visible = Step = Step::SaaS;
                group(CurrentCompanySaaSConnectionDetails)
                {
                    Caption = 'Your connection details';
                    InstructionalText = 'Provide some information about the partner''s company that you will link to. For reference, this is the information for your company.';

#pragma warning disable AA0218 // Ignore warning about missing tooltip
                    field(CCSaaSConnectionUrl; CurrentCompanyConnectionUrl)
                    {
                        Caption = 'Current Connection URL';
                        Editable = false;
                        ApplicationArea = Intercompany;
                    }
                    field(CCSaaSCompanyId; CurrentCompanyCompanyId)
                    {
                        Caption = 'Current Company ID';
                        Editable = false;
                        ApplicationArea = Intercompany;
                    }
                    field(CCSaaSIntercompanyId; CurrentCompanyIntercompanyId)
                    {
                        Caption = 'Intercompany ID';
                        Editable = false;
                        ApplicationArea = Intercompany;
                    }
                    field(CCSaaSCompanyName; CurrentCompanyName)
                    {
                        Caption = 'Company Name';
                        Editable = false;
                        ApplicationArea = Intercompany;
                    }
#pragma warning restore AA0218
                }
                group(PartnerSaaSConnectionDetails)
                {
                    Caption = 'Intercompany Partner''s connection details';
                    InstructionalText = 'Provide the information below to create an intercompany partner from a different environment.';

                    field(PartnerSaaSConnectionUrl; PartnerSaaSConnectionUrl)
                    {
                        Caption = 'IC Partner''s Connection URL';
                        ApplicationArea = Intercompany;
                        ToolTip = 'Specifies the connection URL for the intercompany partner''s environment.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
                        end;
                    }
                    field(PartnerSaaSCompanyId; PartnerSaaSCompanyId)
                    {
                        Caption = 'IC Partner''s Company ID';
                        ApplicationArea = Intercompany;
                        ToolTip = 'Specifies the intercompany partner''s company ID in their environment.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
                        end;
                    }
                    field(PartnerSaaSCompanyIntercompanyId; Rec.Code)
                    {
                        Caption = 'IC Partner''s Intercompany ID';
                        ApplicationArea = Intercompany;
                        ToolTip = 'Specifies the intercompany partner''s intercompany identifier in their environment.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
                        end;
                    }
                    field(PartnerSaaSCompanyName; PartnerSaaSCompanyName)
                    {
                        Caption = 'IC Partner''s Company Name';
                        ApplicationArea = Intercompany;
                        ToolTip = 'Specifies the intercompany partner''s company name in their environment.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
                        end;
                    }
                }
                group(OAuth2ConnectionDetails)
                {
                    Caption = 'Authentication details';
                    InstructionalText = 'Provide information about the Microsoft Entra authentication application that will be used to connect with the partner.';

                    field(OAuth2ClientID; OAuth2ClientID)
                    {
                        ApplicationArea = Intercompany;
                        ExtendedDatatype = Masked;
                        Caption = 'Client ID';
                        ToolTip = 'Specifies the client ID of the Microsoft Entra authentication application.';
                        trigger OnValidate()
                        begin
                            NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
                        end;
                    }
                    field(OAuth2ClientSecret; OAuth2ClientSecret)
                    {
                        ApplicationArea = Intercompany;
                        ExtendedDatatype = Masked;
                        Caption = 'Client Secret';
                        ToolTip = 'Specifies the client secret of the Microsoft Entra authentication application.';
                        trigger OnValidate()
                        begin
                            NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
                        end;
                    }
                    field(OAuth2TokenEndpoint; OAuth2TokenEndpoint)
                    {
                        ApplicationArea = Intercompany;
                        ExtendedDatatype = URL;
                        Caption = 'Token Endpoint';
                        ToolTip = 'Specifies the OAuth 2.0 token endpoint of the Microsoft Entra authentication application. The endpoint indicates a directory to which tokens can be requested. In most scenarios this will be: https://login.microsoftonline.com/<tenantID>/oauth2/v2.0/token .';
                        trigger OnValidate()
                        begin
                            NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
                        end;
                    }
                    field(OAuth2RedirectUrl; OAuth2RedirectUrl)
                    {
                        ApplicationArea = Intercompany;
                        ExtendedDatatype = URL;
                        Caption = 'Redirect URL';
                        ToolTip = 'Specifies the OAuth 2.0 redirect URL of the Microsoft Entra authentication application. In most scenarios this will be: https://businesscentral.dynamics.com/OAuthLanding.htm .';
                        trigger OnValidate()
                        begin
                            NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
                        end;
                    }
                }
            }
            group(TestConnectionTab)
            {
                ShowCaption = false;
                Visible = Step = Step::TestConnection;
                group(VerifyConnection)
                {
                    Caption = 'Verify connection';
                    InstructionalText = 'Before proceeding, let''s ensure that the connection to the partner is working correctly. Start a test connection to the partner''s company by selecting the ''Test Connection'' button.';
                    Visible = not FinishEnabled;
                }
            }
            group(FinishTab)
            {
                ShowCaption = false;
                Visible = Step = Step::Finish;
                group(AllDone)
                {
                    Caption = 'All done';
                    InstructionalText = 'You''re all set. Choose Finish to save your settings.';
                    Visible = FinishEnabled;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = Intercompany;
                Caption = 'Test Connection';
                ToolTip = 'Test the connection to the partner''s company to check whether authentication is correctly set up.';
                Visible = TestConnectionEnabled;
                Image = InteractionTemplateSetup;
                InFooterBar = true;

                trigger OnAction()
                var
                    TempICPartner: Record "IC Partner" temporary;
                    CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
                begin
                    FinishEnabled := false;
                    SaveConfigurationToTemporaryPartner(TempICPartner);
                    if CrossIntercompanyConnector.TestICPartnerSetup(TempICPartner) then
                        NextEnabled := true;
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = Intercompany;
                Caption = 'Back';
                ToolTip = 'Go to previous page';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    PreviousStep();
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Intercompany;
                Caption = 'Next';
                ToolTip = 'Go to the next page';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction();
                var
                begin
                    NextStep();
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Intercompany;
                Caption = 'Finish';
                ToolTip = 'Finish the setup';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    TempICPartner: Record "IC Partner" temporary;
                    CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
                begin
                    SaveConfigurationToTemporaryPartner(TempICPartner);
                    CrossIntercompanyConnector.FinishICPartnerSetup(TempICPartner);
                    Rec.TransferFields(TempICPartner, true);
                    Rec.Modify();
                    SkipOnCloseQuestion := true;
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        ICPartnerChangeMonitor: Codeunit "IC Partner Change Monitor";
    begin
        ICPartnerChangeMonitor.CheckHasPermissionsToChangeSensitiveFields();
        LoadSaaSDataForCurrentCompany();

        Step := Step::Welcome;
        ResetNavigation();
        ConsentState := false;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if SkipOnCloseQuestion then
            exit(true);
        exit(Confirm(NotSetUpQst, false));
    end;

    var
        Step: Option Welcome,SaaS,TestConnection,Finish;
        NextEnabled, BackEnabled, FinishEnabled, TestConnectionEnabled, SkipOnCloseQuestion : Boolean;
        CurrentCompanyConnectionUrl, CurrentCompanyCompanyId, CurrentCompanyIntercompanyId, CurrentCompanyName : Text;
        PartnerSaaSCompanyName: Text[100];
        ConsentState: Boolean;

        [NonDebuggable]
        PartnerSaaSCompanyId, OAuth2ClientID : Guid;
        [NonDebuggable]
        PartnerSaaSConnectionUrl, OAuth2ClientSecret, OAuth2TokenEndpoint, OAuth2RedirectUrl : Text;

        NotSetUpQst: Label 'The setup for the connection to the intercompany partner''s environment isn''t complete. If you leave this guide, your settings will be deleted.\\Are you sure you want to exit?';
        LearnMoreTok: Label 'Privacy and Cookies';
        PrivacyLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=521839';


    local procedure LoadSaaSDataForCurrentCompany()
    var
        ICSetup: Record "IC Setup";
        Company: Record Company;
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
    begin
        CurrentCompanyConnectionUrl := GetUrl(ClientType::Api);

        Company.Get(CompanyName());
        CurrentCompanyCompanyId := CrossIntercompanyConnector.RemoveCurlyBracketsAndUpperCases(Company.Id);

        ICSetup.Get();
        CurrentCompanyIntercompanyId := ICSetup."IC Partner Code";

        CurrentCompanyName := CompanyName();
    end;

    local procedure SaveConfigurationToTemporaryPartner(var TempICPartner: Record "IC Partner" temporary)
    var
        ICPartnerChangeMonitor: Codeunit "IC Partner Change Monitor";
        CompanyId, Auth2ClientId : SecretText;
    begin
        ICPartnerChangeMonitor.CheckHasPermissionsToChangeSensitiveFields();
        TempICPartner.Reset();
        TempICPartner.DeleteAll();
        TempICPartner.Init();

        CompanyId := Format(PartnerSaaSCompanyId);
        Auth2ClientId := Format(OAuth2ClientID);

        TempICPartner.Code := Rec.Code;
        TempICPartner.Name := PartnerSaaSCompanyName;
        TempICPartner."Inbox Details" := PartnerSaaSCompanyName;
        TempICPartner."Connection Url Key" := TempICPartner.SetSecret(TempICPartner."Connection Url Key", PartnerSaaSConnectionUrl);
        TempICPartner."Company Id Key" := TempICPartner.SetSecret(TempICPartner."Company Id Key", CompanyId);
        TempICPartner."Client Id Key" := TempICPartner.SetSecret(TempICPartner."Client Id Key", Auth2ClientId);
        TempICPartner."Client Secret Key" := TempICPartner.SetSecret(TempICPartner."Client Secret Key", OAuth2ClientSecret);
        TempICPartner."Token Endpoint Key" := TempICPartner.SetSecret(TempICPartner."Token Endpoint Key", OAuth2TokenEndpoint);
        TempICPartner."Redirect Url Key" := TempICPartner.SetSecret(TempICPartner."Redirect Url Key", OAuth2RedirectUrl);
        TempICPartner."Token Expiration Time" := CurrentDateTime;

        TempICPartner."Inbox Type" := Enum::Microsoft.Intercompany.Partner."IC Partner Inbox Type"::Database;
        TempICPartner."Data Exchange Type" := Enum::"IC Data Exchange Type"::API;

        TempICPartner.Insert();
    end;

    #region Visibility for sections
    local procedure ResetNavigation()
    begin
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;
        TestConnectionEnabled := false;
        SkipOnCloseQuestion := false;

        case Step of
            Step::Welcome:
                ShowWelcomeTab();
            Step::SaaS:
                ShowAuthenticationSetupForSaaSTab();
            Step::TestConnection:
                ShowTestConnectionTab();
            Step::Finish:
                ShowFinishTab();
        end;
    end;

    local procedure PreviousStep()
    begin
        case Step of
            Step::SaaS:
                Step := Step::Welcome;
            Step::TestConnection:
                Step := Step::SaaS;
            Step::Finish:
                Step := Step::TestConnection;
        end;
        ResetNavigation();
    end;

    local procedure NextStep()
    begin
        case Step of
            Step::Welcome:
                Step := Step::SaaS;
            Step::SaaS:
                Step := Step::TestConnection;
            Step::TestConnection:
                Step := Step::Finish;
        end;
        ResetNavigation();
    end;

    local procedure ShowWelcomeTab()
    begin
        BackEnabled := false;
        NextEnabled := ConsentState;
    end;

    local procedure ShowAuthenticationSetupForSaaSTab()
    begin
        NextEnabled := CheckIfSaaSConnectionDetailsAreFilled();
    end;

    local procedure ShowTestConnectionTab()
    begin
        NextEnabled := false;
        TestConnectionEnabled := true;
    end;

    local procedure ShowFinishTab()
    begin
        NextEnabled := false;
        FinishEnabled := true;
    end;

    procedure CheckIfSaaSConnectionDetailsAreFilled(): Boolean
    var
        PartnerConnectionDetailsAreFilled: Boolean;
        OAuth2ClientIDDetailsAreFilled: Boolean;
    begin
        PartnerConnectionDetailsAreFilled := (PartnerSaaSConnectionUrl <> '') and (not IsNullGuid(PartnerSaaSCompanyId)) and (Rec.Code <> '') and (PartnerSaaSCompanyName <> '');
        OAuth2ClientIDDetailsAreFilled := (not IsNullGuid(OAuth2ClientID)) and (OAuth2ClientSecret <> '') and (OAuth2TokenEndpoint <> '');
        exit(PartnerConnectionDetailsAreFilled and OAuth2ClientIDDetailsAreFilled);
    end;
    #endregion
}
