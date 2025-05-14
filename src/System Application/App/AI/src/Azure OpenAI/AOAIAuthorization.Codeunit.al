// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Store the authorization information for the AOAI service.
/// </summary>
codeunit 7767 "AOAI Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AzureOpenAIImpl: Codeunit "Azure OpenAI Impl";
        [NonDebuggable]
        Endpoint: Text;
        [NonDebuggable]
        Deployment: Text;
        [NonDebuggable]
        ApiKey: SecretText;
        [NonDebuggable]
        ManagedResourceDeployment: Text;
        [NonDebuggable]
        AOAIAccountName: Text;
        ResourceUtilization: Enum "AOAI Resource Utilization";
        TelemetryInvalidAOAIAccountNameFormatTxt: Label 'Attempted use of invalid Azure Open AI account name', Locked = true;
        TelemetryInvalidAOAIUrlTxt: Label 'Attempted call with invalid URL', Locked = true;
        TelemetryAOAIVerificationFailedTxt: Label 'Failed to authenticate account against Azure Open AI', Locked = true;
        TelemetryAOAIVerificationSucceededTxt: Label 'Successfully authenticated account against Azure Open AI', Locked = true;
        TelemetryAccessWithinCachePeriodTxt: Label 'Cached access to Azure Open AI was used', Locked = true;
        TelemetryAccessTokenWithinGracePeriodTxt: Label 'Failed to authenticate against Azure Open AI but last successful authentication is within grace period. System still has access for %1', Locked = true;
        TelemetryAccessTokenOutsideCachePeriodTxt: Label 'Failed to authenticate against Azure Open AI and last successful authentication is outside grace period. System no longer has access', Locked = true;
        AuthFailedWithinGracePeriodLogMessageLbl: Label 'Azure Open AI authorization failed for account %1 on %2 because it is not authorized to access AI services. The connection will be terminated within %3 if not rectified', Comment = 'Telemetry message where %1 is the name of the Azure Open AI account name, %2 is the date where verification has taken place, and %3 is the remaining time until the grace period expires';
        AuthFailedOutsideGracePeriodLogMessageLbl: Label 'Azure Open AI authorization failed for account %1 on %2 because it is not authorized to access AI services. The grace period has been exceeded and the connection has been terminated', Comment = 'Telemetry message where %1 is the name of the Azure Open AI account name and %2 is the date where verification has taken place';
        AuthFailedWithinGracePeriodUserNotificationLbl: Label 'Azure Open AI authorization failed. AI functionality will be disabled within %1. Please contact your system administrator or the extension developer for assistance.', Comment = 'User notification explaining that AI functionality will be disabled soon, where %1 is the remaining time until the grace period expires';
        AuthFailedOutsideGracePeriodUserNotificationLbl: Label 'Azure Open AI authorization failed and the AI functionality has been disabled. Please contact your system administrator or the extension developer for assistance.', Comment = 'User notification explaining that AI functionality has been disabled';
        TelemetryAOAIDatetimeParseFailedTxt: Label 'Failed to parse datetime for account %1. Value: %2', Locked = true;

    [NonDebuggable]
    procedure IsConfigured(CallerModule: ModuleInfo): Boolean
    var
        CurrentModule: ModuleInfo;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);

        case ResourceUtilization of
            Enum::"AOAI Resource Utilization"::"First Party":
                exit((ManagedResourceDeployment <> '') and ALCopilotFunctions.IsPlatformAuthorizationConfigured(CallerModule.Publisher(), CurrentModule.Publisher()));
            Enum::"AOAI Resource Utilization"::"Self-Managed":
                exit((Deployment <> '') and (Endpoint <> '') and (not ApiKey.IsEmpty()));
            Enum::"AOAI Resource Utilization"::"Microsoft Managed":
#if CLEAN26
                if (AOAIAccountName <> '') and (ManagedResourceDeployment <> '') and (not ApiKey.IsEmpty()) then
                    exit(VerifyAOAIAccount(AOAIAccountName, ApiKey))
#else
                if (AOAIAccountName <> '') and (ManagedResourceDeployment <> '') and (not ApiKey.IsEmpty()) then
                    exit(VerifyAOAIAccount(AOAIAccountName, ApiKey))
                else
                    exit((Deployment <> '') and (Endpoint <> '') and (not ApiKey.IsEmpty()) and (ManagedResourceDeployment <> ''));
#endif
        end;

        exit(false);
    end;

#if not CLEAN26
    [NonDebuggable]
    procedure SetMicrosoftManagedAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText; NewManagedResourceDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Microsoft Managed";
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
        ManagedResourceDeployment := NewManagedResourceDeployment;
    end;
#endif

    [NonDebuggable]
    procedure SetMicrosoftManagedAuthorization(NewAOAIAccountName: Text; NewApiKey: SecretText; NewManagedResourceDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Microsoft Managed";
        AOAIAccountName := NewAOAIAccountName;
        ApiKey := NewApiKey;
        ManagedResourceDeployment := NewManagedResourceDeployment;
    end;

    [NonDebuggable]
    procedure SetSelfManagedAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Self-Managed";
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
    end;

    [NonDebuggable]
    procedure SetFirstPartyAuthorization(NewDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"First Party";
        ManagedResourceDeployment := NewDeployment;
    end;

    [NonDebuggable]
    procedure GetEndpoint(): SecretText
    begin
        exit(Endpoint);
    end;

    [NonDebuggable]
    procedure GetDeployment(): SecretText
    begin
        exit(Deployment);
    end;

    [NonDebuggable]
    procedure GetApiKey(): SecretText
    begin
        exit(ApiKey);
    end;

    [NonDebuggable]
    procedure GetManagedResourceDeployment(): SecretText
    begin
        exit(ManagedResourceDeployment);
    end;

    procedure GetResourceUtilization(): Enum "AOAI Resource Utilization"
    begin
        exit(ResourceUtilization);
    end;

    local procedure ClearVariables()
    begin
        Clear(Endpoint);
        Clear(ApiKey);
        Clear(Deployment);
        Clear(AOAIAccountName);
        Clear(ManagedResourceDeployment);
        Clear(ResourceUtilization);
    end;

    [NonDebuggable]
    local procedure PerformAOAIAccountVerification(AOAIAccountNameToVerify: Text; NewApiKey: SecretText): Boolean
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        Url: Text;
        IsSuccessful: Boolean;
        UrlFormatTxt: Label 'https://%1.openai.azure.com/openai/models?api-version=2024-06-01', Locked = true;
        TrustedDomainTxt: Label 'openai.azure.com', Locked = true;
    begin
        Url := StrSubstNo(UrlFormatTxt, AOAIAccountNameToVerify);

        if not IsValidUrl(Url, TrustedDomainTxt) then begin
            Session.LogMessage('0000OQM', TelemetryInvalidAOAIUrlTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureOpenAIImpl.GetAzureOpenAICategory());
            exit(false);
        end;

        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');
        ContentHeaders.Add('api-key', NewApiKey);
        HttpRequestMessage.Method := 'GET';
        HttpRequestMessage.SetRequestUri(Url);
        HttpRequestMessage.Content(HttpContent);

        IsSuccessful := HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        if not IsSuccessful or not HttpResponseMessage.IsSuccessStatusCode() then begin
            Session.LogMessage('0000OLQ', TelemetryAOAIVerificationFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureOpenAIImpl.GetAzureOpenAICategory());
            exit(false);
        end;

        Session.LogMessage('0000OLR', TelemetryAOAIVerificationSucceededTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureOpenAIImpl.GetAzureOpenAICategory());
        exit(true);
    end;

    local procedure IsValidUrl(Url: Text; TrustedDomain: Text): Boolean
    var
        UriBuilder: Codeunit "Uri Builder";
        HostName: Text;
    begin
        if (Url = '') or not Url.StartsWith('https://') then
            exit(false);
        UriBuilder.Init(Url);
        HostName := UriBuilder.GetHost();
        exit(HostName.EndsWith(TrustedDomain));
    end;

    local procedure VerifyAOAIAccount(AccountName: Text; NewApiKey: SecretText): Boolean
    var
        AccountVerified: Boolean;
        GracePeriod: Duration;
        CachePeriod: Duration;
        TruncatedAccountName: Text[100];
        RemainingGracePeriod: Duration;
    begin
        GracePeriod := 14 * 24 * 60 * 60 * 1000; // 2 weeks in milliseconds
        CachePeriod := 24 * 60 * 60 * 1000; // 1 day in milliseconds
        TruncatedAccountName := CopyStr(DelChr(AccountName, '<>', ' '), 1, 100);

        if not IsValidAOAIAccountName(TruncatedAccountName) then
            exit(false);

        // Within CACHE period
        if IsAccountVerifiedWithinPeriod(TruncatedAccountName, CachePeriod) then begin
            Session.LogMessage('0000OLS', TelemetryAccessWithinCachePeriodTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureOpenAIImpl.GetAzureOpenAICategory());
            exit(true);
        end;

        // Outside CACHE period
        AccountVerified := PerformAOAIAccountVerification(TruncatedAccountName, NewApiKey);

        if not AccountVerified then begin
            // Never verified - no GRACE period
            if not IsVerificationTimeSet(TruncatedAccountName) then begin
                Session.LogMessage('0000OQL', TelemetryInvalidAOAIAccountNameFormatTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureOpenAIImpl.GetAzureOpenAICategory());
                exit(false);
            end;

            // Within GRACE period
            if IsAccountVerifiedWithinPeriod(TruncatedAccountName, GracePeriod) then begin
                RemainingGracePeriod := GetRemainingGracePeriod(TruncatedAccountName, GracePeriod);
                ShowUserNotification(StrSubstNo(AuthFailedWithinGracePeriodUserNotificationLbl, FormatDurationAsDays(RemainingGracePeriod)));
                LogTelemetry(TruncatedAccountName, CurrentDateTime, StrSubstNo(AuthFailedWithinGracePeriodLogMessageLbl, TruncatedAccountName, CurrentDateTime, FormatDurationAsDays(RemainingGracePeriod)));
                Session.LogMessage('0000OLT', StrSubstNo(TelemetryAccessTokenWithinGracePeriodTxt, FormatDurationAsDays(RemainingGracePeriod)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureOpenAIImpl.GetAzureOpenAICategory());
                exit(true);
            end
            // Outside GRACE period
            else begin
                ShowUserNotification(AuthFailedOutsideGracePeriodUserNotificationLbl);
                LogTelemetry(TruncatedAccountName, CurrentDateTime, StrSubstNo(AuthFailedOutsideGracePeriodLogMessageLbl, TruncatedAccountName, CurrentDateTime));
                Session.LogMessage('0000OLU', TelemetryAccessTokenOutsideCachePeriodTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureOpenAIImpl.GetAzureOpenAICategory());
                exit(false);
            end;
        end;

        SaveVerificationTime(TruncatedAccountName);
        exit(true);
    end;

    local procedure IsValidAOAIAccountName(Subdomain: Text): Boolean
    var
        RegexPattern: Codeunit Regex;
    begin
        if Subdomain = '' then begin
            Session.LogMessage('0000XYZ', 'Account name is empty or null', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureOpenAIImpl.GetAzureOpenAICategory());
            exit(false);
        end;
        // Regular expression to validate the Azure OpenAI Instance name according to these requirements "Only alphanumeric characters and hyphens are allowed. The value must be 2-64 characters long and cannot start or end with a hyphen."
        // ^[a-zA-Z0-9]     : Starts with an alphanumeric character
        // [a-zA-Z0-9\-]{0,62} : Allows alphanumeric characters and hyphens, up to 62 characters
        // [a-zA-Z0-9]$     : Ends with an alphanumeric character
        // Total length: 2-64 characters (1 + 62 + 1)
        exit(RegexPattern.IsMatch(Subdomain, '^[a-zA-Z0-9][a-zA-Z0-9\-]{0,62}[a-zA-Z0-9]$'));
    end;

    local procedure SaveVerificationTime(AccountName: Text[100])
    begin
        // Save DateTime in XML format (format 9)
        IsolatedStorage.Set('AOAI_Verification_' + AccountName, Format(CurrentDateTime, 0, 9), DataScope::Module);
    end;

    local procedure GetVerificationTime(AccountName: Text[100]) LastVerificationDateTime: DateTime
    var
        LastVerificationDateTimeText: Text;
        EvaluateSuccess: Boolean;
    begin
        if IsolatedStorage.Get('AOAI_Verification_' + AccountName, DataScope::Module, LastVerificationDateTimeText) then begin
            if LastVerificationDateTimeText <> '' then begin
                // Parse the DateTime using format 9 (XML datetime)
                EvaluateSuccess := Evaluate(LastVerificationDateTime, LastVerificationDateTimeText, 9);
                if not EvaluateSuccess then begin
                    // Handle parsing failure
                    Session.LogMessage('0000OS7',
                        StrSubstNo(TelemetryAOAIDatetimeParseFailedTxt, AccountName, LastVerificationDateTimeText),
                        Verbosity::Warning,
                        DataClassification::SystemMetadata,
                        TelemetryScope::ExtensionPublisher,
                        'Category', AzureOpenAIImpl.GetAzureOpenAICategory()
                    );
                    Clear(LastVerificationDateTime);
                end;
            end else
                // Handle empty value
                Clear(LastVerificationDateTime);
        end else
            // Key doesn't exist in isolated storage
            Clear(LastVerificationDateTime);
    end;

    local procedure IsVerificationTimeSet(AccountName: Text[100]): Boolean
    begin
        if GetVerificationTime(AccountName) <> 0DT then
            exit(true)
        else
            exit(false);
    end;

    local procedure GetRemainingGracePeriod(AccountName: Text[100]; GracePeriod: Duration) RemainingGracePeriod: Duration
    var
        LastVerificationDateTime: DateTime;
    begin
        LastVerificationDateTime := GetVerificationTime(AccountName);
        if LastVerificationDateTime <= 0DT then begin
            RemainingGracePeriod := 0;
            exit;
        end;
        RemainingGracePeriod := GracePeriod - (CurrentDateTime - LastVerificationDateTime);
    end;

    local procedure IsAccountVerifiedWithinPeriod(AccountName: Text[100]; Period: Duration): Boolean
    var
        LastVerificationDateTime: DateTime;
    begin
        LastVerificationDateTime := GetVerificationTime(AccountName);
        if LastVerificationDateTime <= 0DT then
            exit(false);
        if CurrentDateTime - LastVerificationDateTime <= Period then
            exit(true)
        else
            exit(false);
    end;


    local procedure ShowUserNotification(Message: Text)
    var
        Notif: Notification;
        Guid: Guid;
    begin
        Guid := CreateGuid();

        Notif.Id := Guid;
        Notif.Message := Message;
        Notif.Scope := NotificationScope::LocalScope;

        Notif.Send();
    end;

    local procedure LogTelemetry(AccountName: Text; VerificationDateTime: DateTime; FormattedLogMessage: Text)
    var
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('AccountName', AccountName);
        CustomDimensions.Add('VerificationDate', Format(VerificationDateTime));

        Telemetry.LogMessage(
            '0000AA1', // Event ID
            FormattedLogMessage,
            Verbosity::Warning,
            DataClassification::OrganizationIdentifiableInformation,
            Enum::"AL Telemetry Scope"::All,
            CustomDimensions
        );
    end;

    local procedure FormatDurationAsDays(DurationValue: Duration): Text
    var
        Days: Decimal;
        DaysLabelLbl: Label '%1 days', Comment = 'Days in plural. %1 is the number of days';
        DayLabelLbl: Label '1 day', Comment = 'A single day';
    begin
        Days := DurationValue / (24 * 60 * 60 * 1000);

        if Days <= 1 then
            exit(DayLabelLbl)
        else
            // Round up to the nearest whole day
            Days := Round(Days, 1, '>');
        exit(StrSubstNo(DaysLabelLbl, Format(Days, 0, 0)));
    end;
}