// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;

/// <summary>
/// Store the authorization information for the AOAI service.
/// </summary>
codeunit 7767 "AOAI Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata AOAIAccountVerificationLog = RIMD;

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
        [NonDebuggable]
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
        IsVerified := VerifyAOAIAccount(AOAIAccountName, NewApiKey.Unwrap());

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
    local procedure PerformAOAIAccountVerification(AOAIAccountName: Text; NewApiKey: Text): Boolean
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

    local procedure VerifyAOAIAccount(AOAIAccountName: Text; NewApiKey: Text): Boolean
    var
        AOAIAccountVerificationLog: Record "AOAIAccountVerificationLog";
        GracePeriod: Duration;
        CachePeriod: Duration;
        LastSuccessfulVerification: DateTime;
        IsVerified: Boolean;
        TruncatedAccountName: Text[100];
    begin
        GracePeriod := 14 * 24 * 60 * 60 * 1000; // 2 weeks in milliseconds
        CachePeriod := 24 * 60 * 60 * 1000; // 1 day in milliseconds

        TruncatedAccountName := CopyStr(AOAIAccountName, 1, 100);

        // Check if the account has been successfully verified within the cache period
        if AOAIAccountVerificationLog.Get(TruncatedAccountName) then begin
            LastSuccessfulVerification := AOAIAccountVerificationLog.LastSuccessfulVerification;
            if CurrentDateTime - LastSuccessfulVerification <= CachePeriod then
                exit(true);
        end;

        IsVerified := PerformAOAIAccountVerification(AOAIAccountName, NewApiKey);

        if not IsVerified then begin
            // If verification fails, check if the last successful verification is within the grace period
            if AOAIAccountVerificationLog.Get(TruncatedAccountName) then begin
                LastSuccessfulVerification := AOAIAccountVerificationLog.LastSuccessfulVerification;
                if CurrentDateTime - LastSuccessfulVerification <= GracePeriod then
                    exit(true);
            end;
            exit(false);
        end;

        // Save verification date
        if AOAIAccountVerificationLog.Get(TruncatedAccountName) then begin
            AOAIAccountVerificationLog.LastSuccessfulVerification := CurrentDateTime;
            AOAIAccountVerificationLog.Modify(true);
        end else begin
            AOAIAccountVerificationLog.Init();
            AOAIAccountVerificationLog.AccountName := TruncatedAccountName;
            AOAIAccountVerificationLog.LastSuccessfulVerification := CurrentDateTime;
            AOAIAccountVerificationLog.Insert(true);
        end;

        exit(true);
    end;
}