// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps.AppSource;

using System.RestClient;
using System.TestLibraries.Utilities;

codeunit 132921 "AppSource Gallery Test Library"
{
    var
        Assert: Codeunit "Library Assert";
        HyperlinkStorage: Codeunit "Library - Variable Storage";
        FormatRegionStore: Codeunit "Library - Variable Storage";
        UserSettingsLanguageIDStore: Codeunit "Library - Variable Storage";
        ApplicationFamilyStore: Codeunit "Library - Variable Storage";
        IsSaasStore: Codeunit "Library - Variable Storage";
        KeyVaultStore: Codeunit "Library - Variable Storage";
        TenantIdStore: Codeunit "Library - Variable Storage";
        RestClientGetJsonStore: Codeunit "Library - Variable Storage";
        CountryLetterCodeStore: Codeunit "Library - Variable Storage";

        Dependencies: Codeunit "AppSource Gallery Test Library";
        AppSourceUriLbl: Label 'https://appsource.microsoft.com/%1/marketplace/apps?product=dynamics-365-business-central', Comment = '1%=Language ID, such as en-US', Locked = true;

    procedure ExtractAppIDFromUniqueProductID(UniqueProductIDValue: Text): Text[36]
    var
        AppIDPos: Integer;
    begin
        AppIDPos := StrPos(UniqueProductIDValue, 'PAPPID.');
        if (AppIDPos > 0) then
            exit(CopyStr(UniqueProductIDValue, AppIDPos + 7, 36));
        exit('');
    end;

    procedure Initialize()
    begin
        HyperlinkStorage.Clear();
        FormatRegionStore.Clear();
        UserSettingsLanguageIDStore.Clear();
        ApplicationFamilyStore.Clear();
        IsSaasStore.Clear();
        KeyVaultStore.Clear();
        TenantIdStore.Clear();
        RestClientGetJsonStore.Clear();
        CountryLetterCodeStore.Clear();
    end;

    procedure SetDependencies(AppSourceSettingsHelper: Codeunit "AppSource Gallery Test Library")
    begin
        Dependencies := AppSourceSettingsHelper;
    end;

    procedure OpenAppSource()
    begin
        Hyperlink(StrSubstNo(AppSourceUriLbl, Dependencies.Language_GetFormatRegionOrDefault('')));
    end;

    procedure EnqueueHyperLink()
    begin
        HyperlinkStorage.Enqueue('https://appsource.microsoft.com/da-DK/marketplace/apps?product=dynamics-365-business-central');
    end;

    procedure AssertCleanedUp()
    begin
        HyperlinkStorage.AssertEmpty();
        FormatRegionStore.AssertEmpty();
        UserSettingsLanguageIDStore.AssertEmpty();
        ApplicationFamilyStore.AssertEmpty();
        IsSaasStore.AssertEmpty();
        KeyVaultStore.AssertEmpty();
        TenantIdStore.AssertEmpty();
        RestClientGetJsonStore.AssertEmpty();
        CountryLetterCodeStore.AssertEmpty();
    end;

    procedure AddToFormatRegionStore(FormatRegion: Text[80])
    begin
        FormatRegionStore.Enqueue(FormatRegion);
    end;

    internal procedure AddToUserSettingsLanguageIDStore(LanguageId: Integer)
    begin
        UserSettingsLanguageIDStore.Enqueue(LanguageId);
    end;

    internal procedure AddToApplicationFamilyStore(ApplicationFamily: Text)
    begin
        ApplicationFamilyStore.Enqueue(ApplicationFamily);
    end;

    internal procedure AddToIsSaasStore(IsSaas: Boolean)
    begin
        IsSaasStore.Enqueue(IsSaas);
    end;

    internal procedure AddToKeyVaultStore(Secret: Text)
    begin
        KeyVaultStore.Enqueue(Secret);
    end;

    internal procedure AddToTenantIdStore(TenantId: Text)
    begin
        TenantIdStore.Enqueue(TenantId);
    end;

    internal procedure AddToRestClientGetJsonStore(JsonText: Text)
    var
        JsonToken: JsonToken;
    begin
        JsonToken.ReadFrom(JsonText);
        RestClientGetJsonStore.Enqueue(JsonToken);
    end;

    internal procedure AddToCountryLetterCodeStore(CountryLetterCode: Text[2])
    begin
        CountryLetterCodeStore.Enqueue(CountryLetterCode);
    end;

    procedure AzureADTenant_GetAADTenantId(): Text
    begin
        if (TenantIdStore.Length() > 0) then
            exit(TenantIdStore.DequeueText());

        Assert.Fail('AzureADTenant_GetTenantId should not be called');
    end;

    procedure AzureADTenant_GetCountryLetterCode(): Text[2]
    begin
        if (CountryLetterCodeStore.Length() > 0) then
            exit(CopyStr(CountryLetterCodeStore.DequeueText(), 1, 2));

        Assert.Fail('AzureADTenant_GetCountryLetterCode should not be called');
    end;

    procedure AzureAdTenant_GetPreferredLanguage(): Text
    begin
        Assert.Fail('AzureAdTenant_GetPreferredLanguage should not be called');
    end;

    // Dependency to  Azure Key Vault 
    procedure AzureKeyVault_GetAzureKeyVaultSecret(SecretName: Text; var Secret: SecretText)
    begin
        if (KeyVaultStore.Length() > 0) then begin
            Secret := KeyVaultStore.DequeueText();
            exit;
        end;

        Assert.Fail('AzureKeyVault_GetAzureKeyVaultSecret should not be called');
    end;

    // Dependency to Environment Information 
    procedure EnvironmentInformation_GetApplicationFamily(): Text
    begin
        if (ApplicationFamilyStore.Length() > 0) then
            exit(ApplicationFamilyStore.DequeueText());

        Assert.Fail('EnvironmentInformation_GetApplicationFamily should not be called');
    end;

    procedure EnvironmentInformation_IsSaas(): boolean
    begin
        if (IsSaasStore.Length() > 0) then
            exit(IsSaasStore.DequeueBoolean());

        Assert.Fail('EnvironmentInformation_IsSaas should not be called');
    end;

    // Dependency to Language 
    procedure Language_GetFormatRegionOrDefault(FormatRegion: Text[80]): Text
    begin
        if (FormatRegionStore.Length() > 0) then
            exit(FormatRegionStore.DequeueText());

        Assert.Fail('Language_GetFormatRegionOrDefault should not be called');
    end;

    procedure RestClient_GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken
    var
        ValueVariant: Variant;
    begin
        if (RestClientGetJsonStore.Length() > 0) then begin
            RestClientGetJsonStore.Dequeue(ValueVariant);
            exit(ValueVariant);
        end;

        Assert.Fail('RestClient_GetAsJSon should not be called');
    end;

    // Dependency to User Settings
    procedure UserSettings_GetUserSettings(UserSecurityID: Guid; var TempUserSettingsRecord: Record "User Settings" temporary)
    var
        LanguageID: Variant;
    begin
        if (UserSettingsLanguageIDStore.Length() > 0) then begin
            TempUserSettingsRecord.Init();
            TempUserSettingsRecord."User Security ID" := UserSecurityID;
            UserSettingsLanguageIDStore.Dequeue(LanguageID);
            TempUserSettingsRecord."Language ID" := LanguageID;
            exit;
        end;
        Assert.Fail('UserSettings_GetUserSettings should not be called');
    end;
}