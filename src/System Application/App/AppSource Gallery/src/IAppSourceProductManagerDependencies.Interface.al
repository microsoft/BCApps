
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Environment.Configuration;
using System.RestClient;

/// <summary>
/// Interface for managing dependencies to the AppSource Product Manager codeunit.
/// </summary>
interface "IAppSource Product Manager Dependencies"
{
    Access = Internal;

    // Dependency to Azure AD Tenant
    procedure AzureADTenant_GetAadTenantID(): Text
    procedure AzureADTenant_GetCountryLetterCode(): Text[2];
    procedure AzureAdTenant_GetPreferredLanguage(): Text

    // Dependency to  Azure Key Vault 
    procedure AzureKeyVault_GetAzureKeyVaultSecret(SecretName: Text; var Secret: SecretText);

    // Dependency to Environment Information 
    procedure EnvironmentInformation_GetApplicationFamily(): text;
    procedure EnvironmentInformation_IsSaas(): boolean;

    // Dependency to Language 
    procedure Language_GetFormatRegionOrDefault(FormatRegion: Text[80]): Text;

    // Rest client override
    procedure RestClient_GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken;

    // Dependency to User Settings
    procedure UserSettings_GetUserSettings(UserSecurityID: Guid; var TempUserSettingsRecord: Record "User Settings" temporary);
}
