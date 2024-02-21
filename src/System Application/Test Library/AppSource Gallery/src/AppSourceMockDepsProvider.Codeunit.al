// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.Apps.AppSource;

using System.Environment.Configuration;
using System.RestClient;
using System.Apps.AppSource;

/// <summary>
/// Library for managing AppSource product retrival and usage.
/// </summary>
codeunit 132913 "AppSource Mock Deps. Provider" implements "AppSource Product Manager Dependencies"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FormatRegionStore: Text[80];
        CountryLetterCode: Code[2];
        PreferredLanguage: Text;
        LanguageID: Variant;
        IsInSaas: Boolean;
        Json: JsonToken;
        ApplicationFamily: Text;

    // Dependency to Azure AD Tenant
    procedure GetCountryLetterCode(): Code[2]
    begin
        exit(CountryLetterCode)
    end;

    procedure SetCountryLetterCode(InputCountryLetterCode: Code[2])
    begin
        CountryLetterCode := InputCountryLetterCode;
    end;

    procedure GetPreferredLanguage(): Text
    begin
        exit(PreferredLanguage);
    end;

    procedure SetPreferredLanguage(InputPreferredLanguage: Text)
    begin
        PreferredLanguage := InputPreferredLanguage;
    end;

    // Dependency to Environment Information 
    procedure GetApplicationFamily(): Text
    begin
        exit(ApplicationFamily);
    end;

    procedure SetApplicationFamily(InputApplicationFamily: Text)
    begin
        ApplicationFamily := InputApplicationFamily;
    end;

    procedure IsSaas(): Boolean
    begin
        exit(IsInSaas);
    end;

    procedure SetIsSaas(InputIsSaas: Boolean)
    begin
        IsInSaas := InputIsSaas;
    end;

    // Dependency to Language 
    procedure GetFormatRegionOrDefault(InputFormatRegion: Text[80]): Text
    begin
        if (InputFormatRegion <> '') then
            exit(InputFormatRegion);
        exit(FormatRegionStore);
    end;

    procedure SetFormatRegionStore(InputFormatRegion: Text[80])
    begin
        FormatRegionStore := InputFormatRegion;
    end;

    // Rest client override
    procedure GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken
    begin
        exit(Json);
    end;

    procedure SetJSon(JsonText: Text)
    begin
        Json.ReadFrom(JsonText);
    end;

    procedure ShouldSetCommonHeaders(): Boolean
    begin
        exit(false);
    end;

    // Dependency to User Settings
    procedure GetUserSettings(UserSecurityID: Guid; var TempUserSettingsRecord: Record "User Settings" temporary)
    begin
        TempUserSettingsRecord.Init();
        TempUserSettingsRecord."User Security ID" := UserSecurityID;
        TempUserSettingsRecord."Language ID" := LanguageID;
    end;

    procedure SetUserSettings(InputLanguageId: Variant)
    begin
        LanguageID := InputLanguageId;
    end;
}