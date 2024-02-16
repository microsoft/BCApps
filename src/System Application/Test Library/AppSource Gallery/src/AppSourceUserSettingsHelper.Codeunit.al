// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.Apps.AppSource;

using System.Apps.AppSource;
using System.Environment.Configuration;
using System.Globalization;
using System.Azure.Identity;
using System.Environment;
using System.Azure.KeyVault;
using System.RestClient;

/// <summary>
/// Utility library for managing AppSource product retrival and usage.
/// </summary>
codeunit 133921 "Test Dependency Provider" implements "Dependency Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AadTenantId: Text;
        CountryLetterCode: Code[2];
        PreferredLanguage: Text;

        FormatRegion: Text[80];

        KeyVault: Dictionary of [Text, SecretText];

    procedure GetAADTenantId(): Text
    begin
        exit(AadTenantId);
    end;

    procedure SetAADTenantId(InputAadTenantId: Text)
    begin
        AadTenantId := InputAadTenantId;
    end;


    procedure GetCountryLetterCode(): Code[2]
    begin
        exit(CountryLetterCode);
    end;

    procedure SetCountryLetterCode(InputCountryLetterCode: Code[2])
    begin
        CountryLetterCode := InputCountryLetterCode;
    end;

    procedure GetPreferredLanguage(): Text
    begin
        exit(PreferredLanguage);
    end;

    // Dependency to  Azure Key Vault 
    procedure GetAzureKeyVaultSecret(SecretName: Text; var Secret: SecretText)
    begin
        Secret := KeyVault.Get(SecretName)
    end;

    // Dependency to Environment Information 
    procedure GetApplicationFamily(): Text
    begin
    end;

    procedure IsSaas(): boolean
    begin
    end;

    // Dependency to Language 
    procedure GetFormatRegionOrDefault(InputFormatRegion: Text[80]): Text
    begin
        if InputFormatRegion <> '' then
            exit(InputFormatRegion);

        exit(InputFormatRegion);
    end;

    procedure SetFormatRegionOrDefault(InputFormatRegion: Text[80]): Text
    begin
        FormatRegion := InputFormatRegion;
    end;

    procedure GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken
    var
        ValueVariant: Variant;
    begin
    end;

    // Dependency to User Settings
    procedure GetUserSettings(UserSecurityID: Guid; var TempUserSettingsRecord: Record "User Settings" temporary)
    var
        LanguageID: Variant;
    begin
    end;

    procedure InitDefaults()
    begin
        FormatRegion := 'en-US';
    end;
}