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
codeunit 2519 "AppSource Dependency Provider" implements "Dependency Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetPreferredLanguage(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetPreferredLanguage());
    end;

    procedure GetAadTenantID(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetAadTenantID());
    end;

    procedure GetUserSettings(UserSecurityId: Guid; var TempUserSettingsRecord: record "User Settings" temporary)
    var
        UserSettings: Codeunit "User Settings";
    begin
        UserSettings.GetUserSettings(Database.UserSecurityID(), TempUserSettingsRecord);
    end;

    procedure GetCountryLetterCode(): Code[2]
    var
        entraTenant: Codeunit "Azure AD Tenant";
    begin
        exit(entraTenant.GetCountryLetterCode());
    end;

    procedure GetAzureKeyVaultSecret(SecretName: Text; var Secret: SecretText);
    var
        KeyVault: Codeunit "Azure Key Vault";
    begin
        KeyVault.GetAzureKeyVaultSecret(SecretName, Secret);
    end;

    procedure GetApplicationFamily(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetApplicationFamily());
    end;

    procedure IsSaas(): boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSaas());
    end;

    procedure GetFormatRegionOrDefault(FormatRegion: Text[80]): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetFormatRegionOrDefault(FormatRegion));
    end;

    procedure GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken
    begin
        exit(RestClient.GetAsJSon(RequestUri));
    end;
}