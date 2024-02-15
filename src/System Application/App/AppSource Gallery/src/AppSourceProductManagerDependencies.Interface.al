
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
interface "AppSource Product Manager Dependencies"
{
    Access = Internal;

    // Dependency to Azure AD Tenant
    procedure GetAadTenantID(): Text
    procedure GetCountryLetterCode(): Code[2];
    procedure GetPreferredLanguage(): Text

    // Dependency to  Azure Key Vault 
    procedure GetAzureKeyVaultSecret(SecretName: Text; var Secret: SecretText);

    // Dependency to Environment Information 
    procedure GetApplicationFamily(): text;
    procedure IsSaas(): boolean;

    // Dependency to Language 
    procedure GetFormatRegionOrDefault(FormatRegion: Text[80]): Text;

    // Rest client override
    procedure GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken;

    // Dependency to User Settings
    procedure GetUserSettings(UserSecurityID: Guid; var TempUserSettingsRecord: Record "User Settings" temporary);
}
