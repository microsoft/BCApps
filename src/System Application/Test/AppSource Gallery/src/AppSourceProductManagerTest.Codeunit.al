// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps.AppSource.Test;

using System.Apps.AppSource;
using System.RestClient;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 135074 "AppSource Product Manager Test" implements "IAppSource Product Manager Dependencies"
{
    Subtype = Test;

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

    [Test]
    procedure TestExtractAppIDFromUniqueProductIDReturnsExpectedAppId()
    var
        AppSourceProductManager: codeunit "AppSource Product Manager";
        UniqueId: Text;
        AppId: Text;
    begin
        // Given
        UniqueId := 'PUBID.nav24spzoo1579516366010%7CAID.n24_test_transactability%7CPAPPID.0984da34-5ec1-4ac1-9575-b73fb2212327';

        // When 
        AppId := AppSourceProductManager.ExtractAppIDFromUniqueProductID(UniqueId);

        // Then
        Assert.AreEqual('0984da34-5ec1-4ac1-9575-b73fb2212327', AppId, 'Expected AppId to be extracted from UniqueId');
    end;

    [Test]
    procedure TestExtractAppIDFromUniqueProductIDReturnsEmptyAppIdWhenNotValid()
    var
        AppSourceProductManager: codeunit "AppSource Product Manager";
        UniqueId: Text;
        AppId: Text;
    begin
        // Given
        UniqueId := 'articentgroupllc1635512619530.ackee-ubuntu-18-04-minimal';

        // When 
        AppId := AppSourceProductManager.ExtractAppIDFromUniqueProductID(UniqueId);

        // Then
        Assert.AreEqual('', AppId, 'Expected AppId to be empty when not present in the UniqueId');
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure TestOpenAppSourceHyperlink()
    var
        AppSourceProductManager: codeunit "AppSource Product Manager";
        AppSourceProductManagerTest: Codeunit "AppSource Product Manager Test";
    begin
        Initialize();
        // Initialize this copy
        AppSourceProductManagerTest.Initialize();
        // Override dependencies
        AppSourceProductManager.SetDependencies(AppSourceProductManagerTest);

        // Given
        AppSourceProductManagerTest.AddToFormatRegionStore('da-DK');

        // With handler expectation
        HyperlinkStorage.Enqueue('https://appsource.microsoft.com/da-DK/marketplace/apps?product=dynamics-365-business-central');

        // When 
        AppSourceProductManager.OpenAppSource();

        // Then
        // Asserted in handler
        AppSourceProductManagerTest.AssertCleanedUp();
        AssertCleanedUp();
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure TestOpenInAppSourceHyperlink()
    var
        AppSourceProductManager: codeunit "AppSource Product Manager";
        AppSourceProductManagerTest: Codeunit "AppSource Product Manager Test";
        UniqueId: Text;
    begin
        Initialize();
        // Initialize this copy
        AppSourceProductManagerTest.Initialize();
        // Override dependencies
        AppSourceProductManager.SetDependencies(AppSourceProductManagerTest);

        // Given
        AppSourceProductManagerTest.AddToUserSettingsLanguageIDStore(3082); //es-ES

        UniqueId := 'PUBID.nav24spzoo1579516366010%7CAID.n24_test_transactability%7CPAPPID.0984da34-5ec1-4ac1-9575-b73fb2212327';

        // With handler expectation
        HyperlinkStorage.Enqueue('https://appsource.microsoft.com/es-ES/product/dynamics-365-business-central/PUBID.nav24spzoo1579516366010%7CAID.n24_test_transactability%7CPAPPID.0984da34-5ec1-4ac1-9575-b73fb2212327');

        // When 
        AppSourceProductManager.OpenInAppSource(UniqueId);

        // Then
        // Asserted in handler
        AppSourceProductManagerTest.AssertCleanedUp();
        AssertCleanedUp();
    end;

    [Test]
    procedure TestLoadProductNotAllowedOnPremises()
    var
        TempProduct: Record "AppSource Product" temporary;
        AppSourceProductManager: codeunit "AppSource Product Manager";
        AppSourceProductManagerTest: Codeunit "AppSource Product Manager Test";
    begin
        Initialize();
        // Initialize this copy
        AppSourceProductManagerTest.Initialize();
        // Override dependencies
        AppSourceProductManager.SetDependencies(AppSourceProductManagerTest);

        // Given
        AppSourceProductManagerTest.AddToIsSaasStore(false);
        AppSourceProductManagerTest.AddToUserSettingsLanguageIDStore(3082); //es-ES
        AppSourceProductManagerTest.AddToApplicationFamilyStore('W1');

        // When   
        asserterror AppSourceProductManager.GetProductsAndPopulateRecord(TempProduct);

        // Then
        Assert.ExpectedError('Not Supported On Premises');

        AppSourceProductManagerTest.AssertCleanedUp();
        AssertCleanedUp();
    end;

    [Test]
    procedure TestLoadProduct()
    var
        TempProduct: Record "AppSource Product" temporary;
        AppSourceProductManager: codeunit "AppSource Product Manager";
        AppSourceProductManagerTest: Codeunit "AppSource Product Manager Test";
    begin
        Initialize();
        // Initialize this copy
        AppSourceProductManagerTest.Initialize();
        // Override dependencies
        AppSourceProductManager.SetDependencies(AppSourceProductManagerTest);

        // Given
        AppSourceProductManagerTest.AddToIsSaasStore(true);
        AppSourceProductManagerTest.AddToApplicationFamilyStore('W1');
        AppSourceProductManagerTest.AddToUserSettingsLanguageIDStore(3082); //es-ES
        AppSourceProductManagerTest.AddToKeyVaultStore('secret');
        AppSourceProductManagerTest.AddToTenantIdStore('tenantId');
        AppSourceProductManagerTest.AddToRestClientGetJsonStore('{"items": [{"uniqueProductId": "PUBID.pbsi_software|AID.247timetracker|PAPPID.9a12247e-8564-4b90-b80b-cd5f4b64217e","displayName": "Dynamics 365 Business Central","publisherId": "pbsi_software","publisherDisplayName": "David Boehm, CPA and Company Inc.","publisherType": "ThirdParty","ratingAverage": 5.0,"ratingCount": 2,"productType": "DynamicsBC","popularity": 7.729569120865367,"privacyPolicyUri": "https://pbsisoftware.com/24-7-tt-privacy-statement","lastModifiedDateTime": "2023-09-03T11:08:28.5348241+00:00"}]}');

        // When
        AppSourceProductManager.GetProductsAndPopulateRecord(TempProduct);

        // Then
        Assert.AreEqual(TempProduct.Count, 1, 'The number of products is incorrect.');
        Assert.AreEqual('Dynamics 365 Business Central', TempProduct.DisplayName, 'The product name is incorrect.');
        AppSourceProductManagerTest.AssertCleanedUp();
        AssertCleanedUp();
    end;

    [Test]
    procedure TestLoadProductWithNextPageLink()
    var
        TempProduct: Record "AppSource Product" temporary;
        AppSourceProductManager: codeunit "AppSource Product Manager";
        AppSourceProductManagerTest: Codeunit "AppSource Product Manager Test";
    begin
        Initialize();
        // Initialize this copy
        AppSourceProductManagerTest.Initialize();
        // Override dependencies
        AppSourceProductManager.SetDependencies(AppSourceProductManagerTest);

        // Given
        AppSourceProductManagerTest.AddToIsSaasStore(true);
        AppSourceProductManagerTest.AddToApplicationFamilyStore('W1');
        AppSourceProductManagerTest.AddToUserSettingsLanguageIDStore(3082); //es-ES
        AppSourceProductManagerTest.AddToKeyVaultStore('secret');
        AppSourceProductManagerTest.AddToTenantIdStore('tenantId');
        AppSourceProductManagerTest.AddToCountryLetterCodeStore('dk');
        // Push first with next page link
        AppSourceProductManagerTest.AddToRestClientGetJsonStore('{"items": [{"uniqueProductId": "PUBID.advania|AID.advania_approvals|PAPPID.603d81ef-542b-46ae-9cb5-17dc16fa3842","displayName": "Dynamics 365 Business Central - First","publisherId": "advania","publisherDisplayName": "Advania","publisherType": "ThirdParty","ratingAverage": 0.0,"ratingCount": 0,"productType": "DynamicsBC","popularity": 7.729569120865367,"privacyPolicyUri": "https://privacy.d365bc.is/","lastModifiedDateTime": "2024-01-19T03:23:15.4319343+00:00"}],"nextPageLink": "next page uri"}');
        // Push second without next page link
        AppSourceProductManagerTest.AddToRestClientGetJsonStore('{"items": [{"uniqueProductId": "PUBID.pbsi_software|AID.247timetracker|PAPPID.9a12247e-8564-4b90-b80b-cd5f4b64217e","displayName": "Dynamics 365 Business Central - Second","publisherId": "pbsi_software","publisherDisplayName": "David Boehm, CPA and Company Inc.","publisherType": "ThirdParty","ratingAverage": 5.0,"ratingCount": 2,"productType": "DynamicsBC","popularity": 7.729569120865367,"privacyPolicyUri": "https://pbsisoftware.com/24-7-tt-privacy-statement","lastModifiedDateTime": "2023-09-03T11:08:28.5348241+00:00"}]}');

        // When
        AppSourceProductManager.GetProductsAndPopulateRecord(TempProduct);

        // Then
        Assert.AreEqual(2, TempProduct.Count, 'The number of products is incorrect.');
        TempProduct.FindSet();
        Assert.AreEqual('Dynamics 365 Business Central - First', TempProduct.DisplayName, 'The first product name is incorrect.');
        TempProduct.Next();
        Assert.AreEqual('Dynamics 365 Business Central - Second', TempProduct.DisplayName, 'The second product name is incorrect.');

        AppSourceProductManagerTest.AssertCleanedUp();
        AssertCleanedUp();
    end;

    [HyperlinkHandler]
    procedure HyperlinkHandler(Message: Text[1024])
    begin
        Assert.AreEqual(HyperlinkStorage.DequeueText(), Message, 'The hyperlink is incorrect.');
    end;

    internal procedure Initialize()
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

    internal procedure AssertCleanedUp()
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

    #region this helpers
    internal procedure AddToFormatRegionStore(FormatRegion: Text[80])
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

    #endregion

    #region dependencies implementation
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
    #endregion

}