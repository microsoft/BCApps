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
        ResourceUtilization: Enum "AOAI Resource Utilization";
        FirstPartyAuthorization: Boolean;
        SelfManagedAuthorization: Boolean;
        MicrosoftManagedAuthorization: Boolean;

    [NonDebuggable]
    procedure IsConfigured(CallerModule: ModuleInfo): Boolean
    var
        AzureOpenAiImpl: Codeunit "Azure OpenAI Impl";
        CurrentModule: ModuleInfo;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);

        case ResourceUtilization of
            Enum::"AOAI Resource Utilization"::"First Party":
                exit(FirstPartyAuthorization and ALCopilotFunctions.IsPlatformAuthorizationConfigured(CallerModule.Publisher(), CurrentModule.Publisher()));
            Enum::"AOAI Resource Utilization"::"Self-Managed":
                exit(SelfManagedAuthorization);
            Enum::"AOAI Resource Utilization"::"Microsoft Managed":
                exit(MicrosoftManagedAuthorization and AzureOpenAiImpl.IsTenantAllowlistedForFirstPartyCopilotCalls());
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
        MicrosoftManagedAuthorization := true;
    end;

    [NonDebuggable]
    procedure SetMicrosoftManagedAuthorization(AOAIAccountName: Text; NewApiKey: SecretText; NewManagedResourceDeployment: Text)
    var
        IsVerified: Boolean;
    begin
        ClearVariables();
        IsVerified := VerifyAOAIAccount(AOAIAccountName, NewApiKey);

        if IsVerified then begin
            ResourceUtilization := Enum::"AOAI Resource Utilization"::"Microsoft Managed";
            ManagedResourceDeployment := NewManagedResourceDeployment;
            MicrosoftManagedAuthorization := true;
        end;
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
        Clear(ManagedResourceDeployment);
        Clear(ResourceUtilization);
        Clear(FirstPartyAuthorization);
        clear(SelfManagedAuthorization);
        Clear(MicrosoftManagedAuthorization);
    end;

    [NonDebuggable]
    local procedure PerformAOAIAccountVerification(AOAIAccountName: Text; NewApiKey: SecretText): Boolean
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
        Url := StrSubstNo(UrlFormatTxt, AOAIAccountName);

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

    local procedure VerifyAOAIAccount(AOAIAccountName: Text; NewApiKey: SecretText): Boolean
    var
        Notif: Notification;
        IsVerified: Boolean;
        GracePeriod: Duration;
        CachePeriod: Duration;
        TruncatedAccountName: Text[100];
    begin
        Message('Starting VerifyAOAIAccount procedure. Variables: AOAIAccountName=' + AOAIAccountName);

        GracePeriod := 15 * 60 * 1000;//14 * 24 * 60 * 60 * 1000; // 2 weeks in milliseconds
        CachePeriod := 1 * 60 * 1000;//24 * 60 * 60 * 1000; // 1 day in milliseconds

        TruncatedAccountName := CopyStr(AOAIAccountName, 1, 100);

        Message('Variables: GracePeriod=' + FormatDurationAsString(GracePeriod) + ', CachePeriod=' + FormatDurationAsString(CachePeriod) + ', TruncatedAccountName=' + TruncatedAccountName);

        if IsAccountVerifiedWithinPeriod(TruncatedAccountName, CachePeriod) then begin
            Message('Function IsAccountVerifiedWithinPeriod called. Result: Verification skipped (within cache period).');
            exit(true);
        end;

        IsVerified := PerformAOAIAccountVerification(AOAIAccountName, NewApiKey);

        Message('Function PerformAOAIAccountVerification called. Result: IsVerified=' + Format(IsVerified, 0, '<Boolean>'));

        // Handle failed verification
        if not IsVerified then begin
            SendNotification(Notif);
            LogTelemetry(AOAIAccountName, Today);
            if IsAccountVerifiedWithinPeriod(TruncatedAccountName, GracePeriod) then begin
                Message('Function IsAccountVerifiedWithinPeriod called. Result: Verification failed, but account is still valid (within grace period).');
                exit(true); // Verified if within grace period
            end;
            Message('Function IsAccountVerifiedWithinPeriod called. Result: Verification failed, and account is no longer valid (grace period expired).');
            exit(false); // Failed verification if grace period has been exceeded
        end;
        SaveVerificationTime(TruncatedAccountName);
        Message('Function SaveVerificationTime called. Verification successful. Record saved.');
        exit(true);
    end;

    local procedure IsAccountVerifiedWithinPeriod(AccountName: Text[100]; Period: Duration): Boolean
    var
        Rec: Record "AOAI Account Verification Log";
        IsVerified: Boolean;
    begin
        ;
        Message('Starting IsAccountVerifiedWithinPeriod procedure. Variables: AccountName=' + AccountName + ', Period=' + FormatDurationAsString(Period));

        if Rec.Get(AccountName) then begin
            Message('Record found. Variables: CurrentDateTime=' + Format(CurrentDateTime, 0, '<DateTime>') + ', Rec.LastSuccessfulVerification=' + Format(Rec.LastSuccessfulVerification, 0, '<DateTime>'));
            IsVerified := CurrentDateTime - Rec.LastSuccessfulVerification <= Period;
            Message('Verification result: ' + Format(IsVerified, 0, '<Boolean>'));
            exit(IsVerified);
        end;

        Message('Record not found. Exiting with false.');
        exit(false);
    end;

    local procedure SaveVerificationTime(AccountName: Text[100])
    var
        Rec: Record "AOAI Account Verification Log";
    begin
        Message('Starting SaveVerificationTime procedure. Variables: AccountName=' + AccountName);
        if Rec.Get(AccountName) then begin
            Rec.LastSuccessfulVerification := CurrentDateTime;
            Rec.Modify(true);
            Message('Record updated. Variables: Rec.LastSuccessfulVerification=' + Format(Rec.LastSuccessfulVerification, 0, '<DateTime>'));
        end else begin
            Rec.Init();
            Rec.AccountName := AccountName;
            Rec.LastSuccessfulVerification := CurrentDateTime;
            Rec.Insert(true);
            Message('Record inserted. Variables: Rec.AccountName=' + Rec.AccountName + ', Rec.LastSuccessfulVerification=' + Format(Rec.LastSuccessfulVerification, 0, '<DateTime>'));
        end;
    end;

    local procedure SendNotification(var Notif: Notification)
    var
        MessageLbl: Label 'Azure Open AI authorization failed. AI functionality will be disabled within 2 weeks. Please contact your system administrator or the extension developer for assistance.';
    begin
        Notif.Message := MessageLbl;
        Notif.Scope := NotificationScope::LocalScope;
        Notif.Send();
    end;

    local procedure LogTelemetry(AccountName: Text; VerificationDate: Date)
    var
        Telemetry: Codeunit Telemetry;
        MessageLbl: Label 'Azure Open AI authorization failed for account %1 on %2 because it is not authorized to access AI services. The connection will be terminated within 2 weeks if not rectified', Comment = 'Telemetry message where %1 is the name of the Azure Open AI account name and %2 is the date where verification has taken place';
        CustomDimensions: Dictionary of [Text, Text];
    begin
        Message('Starting LogTelemetry procedure. Variables: AccountName=' + AccountName + ', VerificationDate=' + Format(VerificationDate, 0, '<Year4>-<Month,2>-<Day,2>'));

        CustomDimensions.Add('AccountName', AccountName);
        CustomDimensions.Add('VerificationDate', Format(VerificationDate, 0, '<Year4>-<Month,2>-<Day,2>'));

        Telemetry.LogMessage(
            '0000AA1', // Event ID
            StrSubstNo(MessageLbl, AccountName, VerificationDate), // Message
            Verbosity::Warning,
            DataClassification::SystemMetadata,
            Enum::"AL Telemetry Scope"::All,
            CustomDimensions
        );
        Message('Telemetry logged successfully. CustomDimensions: AccountName=' + AccountName + ', VerificationDate=' + Format(VerificationDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;
}