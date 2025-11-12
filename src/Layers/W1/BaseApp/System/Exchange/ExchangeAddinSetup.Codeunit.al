namespace System.Integration;

using Microsoft.CRm.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System;
using System.Azure.Identity;
using System.Environment;
using System.Security.AccessControl;
using System.Security.User;

codeunit 5323 "Exchange Add-in Setup"
{

    trigger OnRun()
    begin
    end;

    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        Initialized: Boolean;
        InvalidCredentialsErr: Label 'The provided email address and password are not valid Office 365 or Exchange credentials.';
        NoMailboxErr: Label 'An Office 365 or Exchange mailbox could not be found for this account.';
        AutodiscoverMsg: Label 'Searching for your mailbox.';
        WelcomeSubjectTxt: Label 'Welcome to %1 in Outlook', Comment = '%1 - Application name';
        WelcomeEmailFromNameTxt: Label '%1 Admin', Comment = '%1 - Application Name';
        SalesEmailAddrTxt: Label 'admin@contoso.com', Locked = true;
        ExchangeTelemetryCategoryTxt: Label 'AL Exchange', Locked = true;
        TryInitializeWithEmailTxt: Label 'Trying to initialize the service with email.', Locked = true;
        TryInitializeWithCredentialsTxt: Label 'Trying to initialize the service with credentials.', Locked = true;
        InitializedWithOAuthTokenTxt: Label 'The service is initialized with OAuth token.', Locked = true;
        InitializedWithCertificateTxt: Label 'The service is initialized with certificate.', Locked = true;
        InitializedWithCredentialsTxt: Label 'The service is initialized with credentials.', Locked = true;
        NotInitializedWithCredentialsTxt: Label 'The service is not initialized with credentials.', Locked = true;
        TryAutodiscoverEndpointTxt: Label 'Try to autodiscover endpoint.', Locked = true;
        ImpersonateUserTxt: Label 'Impersonate user.', Locked = true;
        DeployAddInTxt: Label 'Deploy add-in.', Locked = true;
        DeploySampleEmailsTxt: Label 'Deploy sample emails.', Locked = true;
        SampleEmailsDeployedTxt: Label 'sample emails are deployed.', Locked = true;
        ValidCredentialsTxt: Label 'The provided email address and password are valid Office 365 or Exchange credentials.', Locked = true;
        InvalidCredentialsTxt: Label 'The provided email address and password are not valid Office 365 or Exchange credentials.', Locked = true;
        NoMailboxTxt: Label 'An Office 365 or Exchange mailbox could not be found for this account.', Locked = true;
        ToSpecifiedEmailTxt: Label 'Recipient email is the specified email.', Locked = true;
        ToUserEmailTxt: Label 'Recipient email is the user email.', Locked = true;
        FromContactEmailTxt: Label 'Sender email is the contact email.', Locked = true;
        FromSalesEmailTxt: Label 'Sender email is the sales email.', Locked = true;
        DemoCompanyEmailTxt: Label 'trey.research@contoso.com', Locked = true;

    [TryFunction]
    local procedure Initialize(AuthenticationEmail: Text[80])
    var
        ExchangeServiceSetup: Record "Exchange Service Setup";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        AccessToken: SecretText;
    begin
        Session.LogMessage('0000BX8', TryInitializeWithEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);

        AccessToken := AzureADMgt.GetAccessTokenAsSecretText(AzureADMgt.GetO365Resource(), AzureADMgt.GetO365ResourceName(), false);

        if not AccessToken.IsEmpty() then begin
            ExchangeWebServicesServer.InitializeWithOAuthToken(AccessToken, ExchangeWebServicesServer.GetEndpoint());
            if ValidateCredentials() then begin
                Session.LogMessage('0000BX9', InitializedWithOAuthTokenTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
                exit;
            end;
        end;

        ExchangeServiceSetup.Get();
        ExchangeWebServicesServer.InitializeWithCertificate(ExchangeServiceSetup."Azure AD App. ID", ExchangeServiceSetup."Azure AD App. Cert. Thumbprint",
              ExchangeServiceSetup."Azure AD Auth. Endpoint", ExchangeServiceSetup."Exchange Service Endpoint", ExchangeServiceSetup."Exchange Resource Uri");

        ExchangeWebServicesServer.SetImpersonatedIdentity(AuthenticationEmail);
        Initialized := true;

        Session.LogMessage('0000BYR', InitializedWithCertificateTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure InitializeServiceWithCredentials(Email: Text[80]; Password: Text)
    var
        WebCredentials: DotNet WebCredentials;
        ProgressWindow: Dialog;
        ErrorText: Text;
    begin
        Session.LogMessage('0000BXA', TryInitializeWithCredentialsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);

        WebCredentials := WebCredentials.WebCredentials(Email, Password);

        ProgressWindow.Open('#1');
        ProgressWindow.Update(1, AutodiscoverMsg);

        // Production O365 endpoint
        Initialized := ExchangeWebServicesServer.Initialize(Email, ExchangeWebServicesServer.GetEndpoint(), WebCredentials, false) and
          ValidateCredentials();
        ErrorText := GetLastErrorText;

        // Autodiscover endpoint (can be slow)
        if not Initialized then begin
            Session.LogMessage('0000BXB', TryAutodiscoverEndpointTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
            Initialized := ExchangeWebServicesServer.Initialize(Email, '', WebCredentials, true) and ValidateCredentials();
            ErrorText := GetLastErrorText;
        end;

        ProgressWindow.Close();

        if not Initialized then begin
            Session.LogMessage('0000BXC', NotInitializedWithCredentialsTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
            Error(ErrorText);
        end;

        Session.LogMessage('0000BXD', InitializedWithCredentialsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
    end;

    [Scope('OnPrem')]
    procedure CredentialsRequired(AuthenticationEmail: Text[80]) Required: Boolean
    begin
        Required := not Initialize(AuthenticationEmail);
    end;

    [Scope('OnPrem')]
    procedure ImpersonateUser(Email: Text[80])
    begin
        Session.LogMessage('0000BXI', ImpersonateUserTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);

        if not Initialized then
            Initialize(Email);

        ExchangeWebServicesServer.SetImpersonatedIdentity(Email);
    end;

    procedure SampleEmailsAvailable(): Boolean
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        exit(CompanyInformationMgt.IsDemoCompany() and EnvironmentInfo.IsSaaS());
    end;

    [Scope('OnPrem')]
    procedure DeployAddin(OfficeAddin: Record "Office Add-in")
    var
        UserPreference: Record "User Preference";
        InstructionMgt: Codeunit "Instruction Mgt.";
        Stream: DotNet MemoryStream;
        Encoding: DotNet UTF8Encoding;
        ManifestText: Text;
    begin
        Session.LogMessage('0000BXJ', DeployAddInTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);

        AddinManifestManagement.GenerateManifest(OfficeAddin, ManifestText);
        Encoding := Encoding.UTF8Encoding();
        Stream := Stream.MemoryStream(Encoding.GetBytes(ManifestText));
        ExchangeWebServicesServer.InstallApp(Stream);

        UserPreference.SetRange("Instruction Code", InstructionMgt.OfficeUpdateNotificationCode());
        UserPreference.SetRange("User ID", UserId);
        UserPreference.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure DeployAddins(var OfficeAddin: Record "Office Add-in")
    begin
        if OfficeAddin.GetAddins() then
            repeat
                DeployAddin(OfficeAddin);
            until OfficeAddin.Next() = 0;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TryDeployAddins(var OfficeAddin: Record "Office Add-in")
    begin
        DeployAddins(OfficeAddin);
    end;

    [Scope('OnPrem')]
    procedure DeploySampleEmails(EmailAddress: Text)
    var
        User: Record User;
        OfficeAddinSampleEmails: Codeunit "Office Add-In Sample Emails";
        RecipientEmail: Text;
        FromEmail: Text;
        HTMlBody: Text;
    begin
        Session.LogMessage('0000BXK', DeploySampleEmailsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);

        if EmailAddress <> '' then begin
            Session.LogMessage('0000BXL', ToSpecifiedEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
            RecipientEmail := EmailAddress
        end else begin
            User.SetRange("User Name", UserId);
            if User.FindFirst() then begin
                Session.LogMessage('0000BXM', ToUserEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
                RecipientEmail := User."Authentication Email";
            end;
        end;

        FromEmail := GetFromEmail();
        if FromEmail <> '' then
            Session.LogMessage('0000BXN', FromContactEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt)
        else begin
            // Fallback to SalesEmailAddrTxt
            FromEmail := SalesEmailAddrTxt;
            Session.LogMessage('0000BYS', FromSalesEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
        end;

        HTMlBody := OfficeAddinSampleEmails.GetHTMLSampleMsg();
        ExchangeWebServicesServer.SaveHTMLEmailToInbox(StrSubstNo(WelcomeSubjectTxt, PRODUCTNAME.Marketing()), HTMlBody,
          FromEmail, StrSubstNo(WelcomeEmailFromNameTxt, PRODUCTNAME.Full()), RecipientEmail);

        Session.LogMessage('0000BXO', SampleEmailsDeployedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
    end;

    [TryFunction]
    local procedure ValidateCredentials()
    begin
        if not ExchangeWebServicesServer.ValidCredentials() then begin
            if StrPos(GetLastErrorText, '401') > 0 then begin
                Session.LogMessage('0000BXP', InvalidCredentialsTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
                Error(InvalidCredentialsErr);
            end;
            Session.LogMessage('0000BXQ', NoMailboxTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
            Error(NoMailboxErr);
        end;
        Session.LogMessage('0000BXR', ValidCredentialsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExchangeTelemetryCategoryTxt);
    end;

    local procedure GetFromEmail(): Text
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        FirstContactEmail: Text;
    begin
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if ContactBusinessRelation.FindSet() then
            repeat
                if Contact.Get(ContactBusinessRelation."Contact No.") then begin
                    if (FirstContactEmail = '') and (Contact."E-Mail" <> '') then
                        FirstContactEmail := Contact."E-Mail";
                    if Contact."E-Mail" = DemoCompanyEmailTxt then
                        exit(Contact."E-Mail");
                end;
            until ContactBusinessRelation.Next() = 0;

        if FirstContactEmail <> '' then
            exit(FirstContactEmail);
    end;
}

