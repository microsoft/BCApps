// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Environment.Configuration;
using System.Globalization;
using System.Azure.Identity;
using System.Environment;
using System.Azure.KeyVault;
using System.RestClient;

/// <summary>
/// Utility library for managing AppSource product retrival and usage.
/// </summary>
codeunit 2516 "AppSource Settings Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure AzureADTenant_GetCountryLetterCode(): Text[2]
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetCountryLetterCode());
    end;

    procedure AzureAdTenant_GetPreferredLanguage(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetPreferredLanguage());
    end;

    procedure AzureADTenant_GetAadTenantID(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetAadTenantID());
    end;

    procedure AzureKeyVault_GetAzureKeyVaultSecret(SecretName: Text; var Secret: SecretText);
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        AzureKeyVault.GetAzureKeyVaultSecret(SecretName, Secret);
    end;

    procedure EnvironmentInformation_GetApplicationFamily(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetApplicationFamily());
    end;

    procedure EnvironmentInformation_IsSaas(): boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSaas());
    end;

    procedure Language_GetFormatRegionOrDefault(FormatRegion: Text[80]): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetFormatRegionOrDefault(FormatRegion));
    end;

    procedure RestClient_GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken
    begin
        exit(RestClient.GetAsJSon(RequestUri));
    end;

    procedure UserSettings_GetUserSettings(UserSecurityId: Guid; var TempUserSettingsRecord: record "User Settings" temporary)
    var
        UserSettings: Codeunit "User Settings";
    begin
        UserSettings.GetUserSettings(Database.UserSecurityID(), TempUserSettingsRecord);
    end;
}