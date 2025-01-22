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

    // FOR DEBUGGING ONLY
    local procedure FormatDurationAsString(DurationValue: Duration): Text
    var
        Hours: Integer;
        Minutes: Integer;
        Seconds: Integer;
        Milliseconds: Integer;
    begin
        // Convert milliseconds into hours, minutes, seconds
        Hours := DurationValue div (60 * 60 * 1000);
        DurationValue := DurationValue mod (60 * 60 * 1000);

        Minutes := DurationValue div (60 * 1000);
        DurationValue := DurationValue mod (60 * 1000);

        Seconds := DurationValue div 1000;
        Milliseconds := DurationValue mod 1000;

        // Format as HH:MM:SS.mmm
        exit(StrSubstNo('%1:%2:%3.%4',
            Format(Hours, 2, '<Sign><Integer,2>'),
            Format(Minutes, 2, '<Sign><Integer,2>'),
            Format(Seconds, 2, '<Sign><Integer,2>'),
            Format(Milliseconds, 3, '<Sign><Integer,3>')));
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
        AuthFailedWithinGracePeriodLogMessageLbl: Label 'Azure Open AI authorization failed for account %1 on %2 because it is not authorized to access AI services. The connection will be terminated in %3 if not rectified', Comment = 'Telemetry message where %1 is the name of the Azure Open AI account name, %2 is the date where verification has taken place, and %3 is the remaining time until the grace period expires';
        AuthFailedOutsideGracePeriodLogMessageLbl: Label 'Azure Open AI authorization failed for account %1 on %2 because it is not authorized to access AI services. The grace period has been exceeded and the connection has been terminated', Comment = 'Telemetry message where %1 is the name of the Azure Open AI account name and %2 is the date where verification has taken place';
        AuthFailedWithinGracePeriodUserNotificationLbl: Label 'Azure Open AI authorization failed. AI functionality will be disabled in %1. Please contact your system administrator or the extension developer for assistance.', Comment = 'User notification explaining that AI functionality will be disabled soon, where %1 is the remaining time until the grace period expires';
        AuthFailedOutsideGracePeriodUserNotificationLbl: Label 'Azure Open AI authorization failed and the AI functionality has been disabled. Please contact your system administrator or the extension developer for assistance.', Comment = 'User notification explaining that AI functionality has been disabled';

    begin
        Message('Starting VerifyAOAIAccount procedure. Variables: AOAIAccountName=' + AccountName);
        GracePeriod := 15 * 60 * 1000;//14 * 24 * 60 * 60 * 1000; // 2 weeks in milliseconds
        CachePeriod := 1 * 60 * 1000;//24 * 60 * 60 * 1000; // 1 day in milliseconds
        TruncatedAccountName := CopyStr(DelChr(AccountName, '<>', ' '), 1, 100);
        Message('Variables: GracePeriod=' + FormatDurationAsString(GracePeriod) + ', CachePeriod=' + FormatDurationAsString(CachePeriod) + ', TruncatedAccountName=' + TruncatedAccountName);

        // Within CACHE period
        IsWithinCachePeriod := IsAccountVerifiedWithinPeriod(TruncatedAccountName, CachePeriod);
        if IsWithinCachePeriod then begin
            Message('Function IsAccountVerifiedWithinPeriod called. Result: Verification skipped (within cache period).');
            exit(true);
        end;

        AccountVerified := PerformAOAIAccountVerification(AccountName, NewApiKey);
        Message('Function PerformAOAIAccountVerification called. Result: IsVerified=' + Format(AccountVerified));

        if not AccountVerified then begin
            // Calculate remaining grace period
            if VerificationLog.Get(TruncatedAccountName) then
                RemainingGracePeriod := GracePeriod - (CurrentDateTime - VerificationLog.LastSuccessfulVerification)
            else
                RemainingGracePeriod := GracePeriod;

            // Within GRACE period
            if IsAccountVerifiedWithinPeriod(TruncatedAccountName, GracePeriod) then begin
                ShowUserNotification(StrSubstNo(AuthFailedWithinGracePeriodUserNotificationLbl, FormatDurationAsDays(RemainingGracePeriod)));
                LogTelemetry(AccountName, Today, StrSubstNo(AuthFailedWithinGracePeriodLogMessageLbl, AccountName, Today, FormatDurationAsDays(RemainingGracePeriod)));
                Message('Function IsAccountVerifiedWithinPeriod called. Result: Verification failed, but account is still valid (within grace period).');
                exit(true); // Verified if within grace period
            end
            // Outside GRACE period
            else begin
                ShowUserNotification(AuthFailedOutsideGracePeriodUserNotificationLbl);
                LogTelemetry(AccountName, Today, AuthFailedOutsideGracePeriodLogMessageLbl);
                Message('Function IsAccountVerifiedWithinPeriod called. Result: Verification failed, and account is no longer valid (grace period expired).');
                exit(false); // Failed verification if grace period has been exceeded
            end;
        end;

        SaveVerificationTime(TruncatedAccountName);
        Message('Function SaveVerificationTime called. Verification successful. Record saved.');
        exit(true);
    end;

    local procedure IsAccountVerifiedWithinPeriod(AccountName: Text[100]; Period: Duration): Boolean
    var
        VerificationLog: Record "AOAI Account Verification Log";
        IsVerified: Boolean;
    begin
        Message('Starting IsAccountVerifiedWithinPeriod procedure. Variables: AccountName=' + AccountName + ', Period=' + FormatDurationAsString(Period));

        if VerificationLog.Get(AccountName) then begin
            Message('Record found. Variables: CurrentDateTime=' + Format(CurrentDateTime) + ', Rec.LastSuccessfulVerification=' + Format(VerificationLog.LastSuccessfulVerification));
            IsVerified := CurrentDateTime - VerificationLog.LastSuccessfulVerification <= Period;
            Message('Verification result: ' + Format(IsVerified));
            exit(IsVerified);
        end;

        Message('Record not found. Exiting with false.');
        exit(false);
    end;

    local procedure SaveVerificationTime(AccountName: Text[100])
    var
        VerificationLog: Record "AOAI Account Verification Log";
    begin

        Message('Starting SaveVerificationTime procedure. Variables: AccountName=' + AccountName);
        if VerificationLog.Get(AccountName) then begin
            VerificationLog.LastSuccessfulVerification := CurrentDateTime;
            VerificationLog.Modify();
            Message('Record updated. Variables: Rec.LastSuccessfulVerification=' + Format(VerificationLog.LastSuccessfulVerification));
        end else begin
            VerificationLog.Init();
            VerificationLog.AccountName := AccountName;
            VerificationLog.LastSuccessfulVerification := CurrentDateTime;
            if VerificationLog.Insert() then
                Message('Record inserted. Variables: Rec.AccountName=' + VerificationLog.AccountName + ', Rec.LastSuccessfulVerification=' + Format(VerificationLog.LastSuccessfulVerification))
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
        Message('Starting LogTelemetry procedure. Variables: AccountName=' + AccountName + ', VerificationDate=' + Format(VerificationDate));

        // Add default dimensions
        CustomDimensions.Add('AccountName', AccountName);
        CustomDimensions.Add('VerificationDate', Format(VerificationDate));

        // Log the telemetry with the custom message
        Telemetry.LogMessage(
            '0000AA1', // Event ID
            StrSubstNo(LogMessage, AccountName, VerificationDate),
            Verbosity::Warning,
            DataClassification::SystemMetadata,
            Enum::"AL Telemetry Scope"::All,
            CustomDimensions
        );

        Message('Telemetry logged successfully. CustomDimensions: AccountName=' + AccountName + ', VerificationDate=' + Format(VerificationDate));
    end;

    local procedure FormatDurationAsDays(DurationValue: Duration): Text
    var
        Days: Decimal;
        Hours: Decimal;
        DaysLabelLbl: Label '%1 days', Comment = '%1 is the number of days';
        HoursLabelLbl: Label '%1 hours', Comment = '%1 is the number of hours';
    begin
        // Convert milliseconds into days and hours
        Days := DurationValue / (24 * 60 * 60 * 1000); // Total days
        Hours := (DurationValue mod (24 * 60 * 60 * 1000)) / (60 * 60 * 1000); // Remaining hours

        if Days >= 1 then
            exit(StrSubstNo(DaysLabelLbl, Format(Days, 0, 9))) // Display days if more than 1 day
        else
            exit(StrSubstNo(HoursLabelLbl, Format(Hours, 0, 9))); // Display hours if less than 1 day
    end;
}