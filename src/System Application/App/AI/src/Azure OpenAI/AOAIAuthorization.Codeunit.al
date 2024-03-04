// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Azure.Identity;
using System.Azure.KeyVault;
using System.Environment;

/// <summary>
/// Store the authorization information for the AOAI service.
/// </summary>
codeunit 7767 "AOAI Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        Endpoint: Text;
        [NonDebuggable]
        Deployment: Text;
        [NonDebuggable]
        ApiKey: SecretText;
        EmptyTenantIdTelemetryMsg: Label 'Empty or malformed tenant ID.', Locked = true;
        TenantIsAllowListedTelemetryMsg: Label 'The current tenant is allowlisted for first party auth.', Locked = true;
        AllowlistedTenantsAkvKeyTok: Label 'AOAI-Allow-1P-Auth', Locked = true;

    [NonDebuggable]
    procedure IsConfigured(CallerModule: ModuleInfo): Boolean
    var
        CurrentModule: ModuleInfo;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);

        if Deployment = '' then
            exit(false);

        if (Endpoint = '') and ApiKey.IsEmpty() then
            exit(IsTenantAllowlistedForPlatformAuthorization()
                or ALCopilotFunctions.IsPlatformAuthorizationConfigured(CallerModule.Publisher(), CurrentModule.Publisher()));

        if (Endpoint = '') or ApiKey.IsEmpty() then
            exit(false);

        exit(true);
    end;

    [NonDebuggable]
    procedure SetAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText)
    begin
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
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
    local procedure IsTenantAllowlistedForPlatformAuthorization(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureAdTenant: Codeunit "Azure AD Tenant";
        AllowlistedTenants: Text;
        EntraTenantIdAsText: Text;
        EntraTenantIdAsGuid: Guid;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit(false);

        if (not AzureKeyVault.GetAzureKeyVaultSecret(AllowlistedTenantsAkvKeyTok, AllowlistedTenants)) or (AllowlistedTenants.Trim() = '') then
            exit(false);

        EntraTenantIdAsText := AzureAdTenant.GetAadTenantId();

        if (EntraTenantIdAsText = '') or not Evaluate(EntraTenantIdAsGuid, EntraTenantIdAsText) or IsNullGuid(EntraTenantIdAsGuid) then begin
            Session.LogMessage('0000MLN', EmptyTenantIdTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetAzureOpenAICategory());
            exit(false);
        end;

        if not AllowlistedTenants.Contains(EntraTenantIdAsText) then
            exit(false);

        Session.LogMessage('0000MLE', TenantIsAllowListedTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetAzureOpenAICategory());
        exit(true);
    end;
}