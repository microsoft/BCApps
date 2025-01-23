// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;

using System.Telemetry;
/// <summary>
/// Store the authorization information for the AOAI service.
/// </summary>
codeunit 7767 "AOAI Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "AOAI Account Verification Log" = RIMD;

    var
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
        FirstPartyAuthorization: Boolean;
        SelfManagedAuthorization: Boolean;
        MicrosoftManagedAuthorizationWithDeployment: Boolean;
        MicrosoftManagedAuthorizationWithAOAIAccount: Boolean;

    [NonDebuggable]
    procedure IsConfigured(CallerModule: ModuleInfo): Boolean
    var
        AzureOpenAiImpl: Codeunit "Azure OpenAI Impl";
        CurrentModule: ModuleInfo;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AOAIAccountIsVerified: Boolean;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);

        case ResourceUtilization of
            Enum::"AOAI Resource Utilization"::"First Party":
                exit(FirstPartyAuthorization and ALCopilotFunctions.IsPlatformAuthorizationConfigured(CallerModule.Publisher(), CurrentModule.Publisher()));
            Enum::"AOAI Resource Utilization"::"Self-Managed":
                exit(SelfManagedAuthorization);
            Enum::"AOAI Resource Utilization"::"Microsoft Managed":
                if MicrosoftManagedAuthorizationWithAOAIAccount then begin
                    AOAIAccountIsVerified := VerifyAOAIAccount(AOAIAccountName, ApiKey);
                    exit(AOAIAccountIsVerified and AzureOpenAiImpl.IsTenantAllowlistedForFirstPartyCopilotCalls());
                end
                else
                    if MicrosoftManagedAuthorizationWithDeployment then
                        exit(AzureOpenAiImpl.IsTenantAllowlistedForFirstPartyCopilotCalls());
        end;
        exit(false);
    end;

    [NonDebuggable]
    procedure SetMicrosoftManagedAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText; NewManagedResourceDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Microsoft Managed";
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
        ManagedResourceDeployment := NewManagedResourceDeployment;
        MicrosoftManagedAuthorizationWithDeployment := true;
    end;

    [NonDebuggable]
    procedure SetMicrosoftManagedAuthorization(NewAOAIAccountName: Text; NewApiKey: SecretText; NewManagedResourceDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Microsoft Managed";
        AOAIAccountName := NewAOAIAccountName;
        ApiKey := NewApiKey;
        ManagedResourceDeployment := NewManagedResourceDeployment;
        MicrosoftManagedAuthorizationWithAOAIAccount := true;
    end;

    [NonDebuggable]
    procedure SetSelfManagedAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Self-Managed";
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
        SelfManagedAuthorization := true;
    end;

    [NonDebuggable]
    procedure SetFirstPartyAuthorization(NewDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"First Party";
        ManagedResourceDeployment := NewDeployment;
        FirstPartyAuthorization := true;
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
        Clear(FirstPartyAuthorization);
        clear(SelfManagedAuthorization);
        Clear(MicrosoftManagedAuthorizationWithDeployment);
        Clear(MicrosoftManagedAuthorizationWithAOAIAccount);
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
    begin
        Url := StrSubstNo(UrlFormatTxt, AOAIAccountNameToVerify);

        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');
        ContentHeaders.Add('api-key', NewApiKey);

        HttpRequestMessage.Method := 'GET';
        HttpRequestMessage.SetRequestUri(Url);
        HttpRequestMessage.Content(HttpContent);

        IsSuccessful := HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        if not IsSuccessful then
            exit(false);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit(false);

        exit(true);
    end;

    local procedure VerifyAOAIAccount(AccountName: Text; NewApiKey: SecretText): Boolean
    var
        VerificationLog: Record "AOAI Account Verification Log";
        AccountVerified: Boolean;
        GracePeriod: Duration;
        CachePeriod: Duration;
        TruncatedAccountName: Text[100];
        IsWithinCachePeriod: Boolean;
        RemainingGracePeriod: Duration;
        AuthFailedWithinGracePeriodLogMessageLbl: Label 'Azure Open AI authorization failed for account %1 on %2 because it is not authorized to access AI services. The connection will be terminated within %3 if not rectified', Comment = 'Telemetry message where %1 is the name of the Azure Open AI account name, %2 is the date where verification has taken place, and %3 is the remaining time until the grace period expires';
        AuthFailedOutsideGracePeriodLogMessageLbl: Label 'Azure Open AI authorization failed for account %1 on %2 because it is not authorized to access AI services. The grace period has been exceeded and the connection has been terminated', Comment = 'Telemetry message where %1 is the name of the Azure Open AI account name and %2 is the date where verification has taken place';
        AuthFailedWithinGracePeriodUserNotificationLbl: Label 'Azure Open AI authorization failed. AI functionality will be disabled within %1. Please contact your system administrator or the extension developer for assistance.', Comment = 'User notification explaining that AI functionality will be disabled soon, where %1 is the remaining time until the grace period expires';
        AuthFailedOutsideGracePeriodUserNotificationLbl: Label 'Azure Open AI authorization failed and the AI functionality has been disabled. Please contact your system administrator or the extension developer for assistance.', Comment = 'User notification explaining that AI functionality has been disabled';

    begin
        GracePeriod := 14 * 24 * 60 * 60 * 1000; // 2 weeks in milliseconds
        CachePeriod := 24 * 60 * 60 * 1000; // 1 day in milliseconds
        TruncatedAccountName := CopyStr(DelChr(AccountName, '<>', ' '), 1, 100);

        IsWithinCachePeriod := IsAccountVerifiedWithinPeriod(TruncatedAccountName, CachePeriod);
        // Within CACHE period
        if IsWithinCachePeriod then
            exit(true);

        // Outside CACHE period
        AccountVerified := PerformAOAIAccountVerification(AccountName, NewApiKey);

        if not AccountVerified then begin
            if VerificationLog.Get(TruncatedAccountName) then
                RemainingGracePeriod := GracePeriod - (CurrentDateTime - VerificationLog.LastSuccessfulVerification)
            else
                RemainingGracePeriod := GracePeriod;

            // Within GRACE period
            if IsAccountVerifiedWithinPeriod(TruncatedAccountName, GracePeriod) then begin
                ShowUserNotification(StrSubstNo(AuthFailedWithinGracePeriodUserNotificationLbl, FormatDurationAsDays(RemainingGracePeriod)));
                LogTelemetry(AccountName, Today, StrSubstNo(AuthFailedWithinGracePeriodLogMessageLbl, AccountName, Today, FormatDurationAsDays(RemainingGracePeriod)));
                exit(true);
            end
            // Outside GRACE period
            else begin
                ShowUserNotification(AuthFailedOutsideGracePeriodUserNotificationLbl);
                LogTelemetry(AccountName, Today, AuthFailedOutsideGracePeriodLogMessageLbl);
                exit(false);
            end;
        end;

        SaveVerificationTime(TruncatedAccountName);
        exit(true);
    end;

    local procedure IsAccountVerifiedWithinPeriod(AccountName: Text[100]; Period: Duration): Boolean
    var
        VerificationLog: Record "AOAI Account Verification Log";
        IsVerified: Boolean;
    begin
        if VerificationLog.Get(AccountName) then begin
            IsVerified := CurrentDateTime - VerificationLog.LastSuccessfulVerification <= Period;
            exit(IsVerified);
        end;

        exit(false);
    end;

    local procedure SaveVerificationTime(AccountName: Text[100])
    var
        VerificationLog: Record "AOAI Account Verification Log";
    begin
        if VerificationLog.Get(AccountName) then begin
            VerificationLog.LastSuccessfulVerification := CurrentDateTime;
            VerificationLog.Modify();
        end else begin
            VerificationLog.Init();
            VerificationLog.AccountName := AccountName;
            VerificationLog.LastSuccessfulVerification := CurrentDateTime;
            VerificationLog.Insert()
        end;
    end;

    local procedure ShowUserNotification(Message: Text)
    var
        Notif: Notification;
    begin
        Notif.Message := Message;
        Notif.Scope := NotificationScope::LocalScope;
        Notif.Send();
    end;

    local procedure LogTelemetry(AccountName: Text; VerificationDate: Date; LogMessage: Text)
    var
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('AccountName', AccountName);
        CustomDimensions.Add('VerificationDate', Format(VerificationDate));

        Telemetry.LogMessage(
            '0000AA1', // Event ID
            StrSubstNo(LogMessage, AccountName, VerificationDate),
            Verbosity::Warning,
            DataClassification::SystemMetadata,
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