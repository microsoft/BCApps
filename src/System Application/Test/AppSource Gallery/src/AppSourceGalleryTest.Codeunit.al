// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps.AppSource.Test;

using System.TestLibraries.Apps.AppSource;
using System.TestLibraries.Utilities;

codeunit 135074 "AppSource Gallery Test"
{
    Subtype = Test;

    var
        AppSrcProductMgrTestImpl: Codeunit "AppSrc Product Mgr. Test Impl.";
        LibraryAssert: Codeunit "Library Assert";
        HyperlinkStorage: Codeunit "Library - Variable Storage";

    [Test]
    procedure TestExtractAppIDFromUniqueProductIDReturnsExpectedAppId()
    var
        UniqueId: Text;
        AppId: Guid;
        ExpectedAppId: Guid;
    begin
        // Given
        UniqueId := 'PUBID.nav24spzoo1579516366010%7CAID.n24_test_transactability%7CPAPPID.0984da34-5ec1-4ac1-9575-b73fb2212327';
        ExpectedAppId := '0984da34-5ec1-4ac1-9575-b73fb2212327';

        // When 
        AppId := AppSrcProductMgrTestImpl.ExtractAppIDFromUniqueProductID(UniqueId);

        // Then
        LibraryAssert.AreEqual(ExpectedAppId, AppId, 'Expected AppId to be extracted from UniqueId');
    end;

    [Test]
    procedure TestExtractAppIDFromUniqueProductIDReturnsEmptyAppIdWhenNotValid()
    var
        UniqueId: Text;
        AppId: Guid;
    begin
        // Given
        UniqueId := 'articentgroupllc1635512619530.ackee-ubuntu-18-04-minimal';

        // When 
        AppId := AppSrcProductMgrTestImpl.ExtractAppIDFromUniqueProductID(UniqueId);

        // Then
        LibraryAssert.IsTrue(IsNullGuid(AppId), 'Expected AppId to be empty when not present in the UniqueId');
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure TestOpenAppSourceHyperlink()
    var
        AppSourceMockDepsProvider: Codeunit "AppSource Mock Deps. Provider";
    begin
        // Given
        AppSourceMockDepsProvider.SetFormatRegionStore('da-DK');
        AppSrcProductMgrTestImpl.SetDependencies(AppSourceMockDepsProvider);

        // With handler expectation
        HyperlinkStorage.Enqueue('https://appsource.microsoft.com/da-DK/marketplace/apps?product=dynamics-365-business-central');

        // When 
        AppSrcProductMgrTestImpl.OpenAppSource();

        // Then
        // Asserted in handler
        AssertCleanedUp();
        AppSrcProductMgrTestImpl.ResetDependencies();
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure TestOpenInAppSourceHyperlink()
    var
        AppSourceMockDepsProvider: Codeunit "AppSource Mock Deps. Provider";
        UniqueId: Text;
    begin
        // Given
        AppSourceMockDepsProvider.SetUserSettings(3082); //es-ES
        // Override dependencies
        AppSrcProductMgrTestImpl.SetDependencies(AppSourceMockDepsProvider);

        UniqueId := 'PUBID.nav24spzoo1579516366010%7CAID.n24_test_transactability%7CPAPPID.0984da34-5ec1-4ac1-9575-b73fb2212327';

        // With handler expectation
        HyperlinkStorage.Enqueue('https://appsource.microsoft.com/es-ES/product/dynamics-365-business-central/PUBID.nav24spzoo1579516366010%7CAID.n24_test_transactability%7CPAPPID.0984da34-5ec1-4ac1-9575-b73fb2212327');

        // When 
        AppSrcProductMgrTestImpl.OpenAppInAppSource(UniqueId);

        // Then
        // Asserted in handler
        AssertCleanedUp();
        AppSrcProductMgrTestImpl.ResetDependencies();
    end;

    [Test]
    procedure TestLoadProductNotAllowedOnPremises()
    var
        AppSourceMockDepsProvider: Codeunit "AppSource Mock Deps. Provider";
    begin
        // Given
        AppSourceMockDepsProvider.SetIsSaas(false);
        AppSourceMockDepsProvider.SetUserSettings(3082); //es-ES
        AppSourceMockDepsProvider.SetApplicationFamily('W1');
        AppSourceMockDepsProvider.SetCountryLetterCode('dk');
        AppSrcProductMgrTestImpl.SetDependencies(AppSourceMockDepsProvider);

        // When   
        asserterror AppSrcProductMgrTestImpl.GetProductsAndPopulateRecord();

        // Then
        LibraryAssert.ExpectedError('Not supported on premises.');

        AppSrcProductMgrTestImpl.ResetDependencies();
    end;

    [Test]
    procedure TestLoadProduct()
    var
        AppSourceMockDepsProvider: Codeunit "AppSource Mock Deps. Provider";
    begin

        // Given
        AppSourceMockDepsProvider.SetIsSaas(true);
        AppSourceMockDepsProvider.SetApplicationFamily('W1');
        AppSourceMockDepsProvider.SetUserSettings(3082); //es-ES
        AppSourceMockDepsProvider.SetCountryLetterCode('us');
        AppSourceMockDepsProvider.SetJson('{"items": [{"uniqueProductId": "PUBID.pbsi_software|AID.247timetracker|PAPPID.9a12247e-8564-4b90-b80b-cd5f4b64217e","displayName": "Dynamics 365 Business Central","publisherId": "pbsi_software","publisherDisplayName": "David Boehm, CPA and Company Inc.","publisherType": "ThirdParty","ratingAverage": 5.0,"ratingCount": 2,"productType": "DynamicsBC","popularity": 7.729569120865367,"privacyPolicyUri": "https://pbsisoftware.com/24-7-tt-privacy-statement","lastModifiedDateTime": "2023-09-03T11:08:28.5348241+00:00"}]}');
        AppSrcProductMgrTestImpl.SetDependencies(AppSourceMockDepsProvider);

        // When
        AppSrcProductMgrTestImpl.GetProductsAndPopulateRecord();

        // Then
        LibraryAssert.AreEqual(AppSrcProductMgrTestImpl.GetProductTableCount(), 1, 'The number of products is incorrect.');
        LibraryAssert.IsTrue(AppSrcProductMgrTestImpl.IsRecordWithDisplayNameinProductTable('Dynamics 365 Business Central'), 'The product name is incorrect.');

        AppSrcProductMgrTestImpl.ResetDependencies();
    end;

    [Test]
    procedure TestLoadProductWithNextPageLink()
    var
        AppSourceMockDepsProvider: Codeunit "AppSource Mock Deps. Provider";
    begin
        // Given
        AppSourceMockDepsProvider.SetIsSaas(true);
        AppSourceMockDepsProvider.SetApplicationFamily('W1');
        AppSourceMockDepsProvider.SetUserSettings(3082); //es-ES
        AppSourceMockDepsProvider.SetCountryLetterCode('dk');

        // Push items
        AppSourceMockDepsProvider.SetJson('{"items": [{"uniqueProductId": "PUBID.advania|AID.advania_approvals|PAPPID.603d81ef-542b-46ae-9cb5-17dc16fa3842","displayName": "Dynamics 365 Business Central - First","publisherId": "advania","publisherDisplayName": "Advania","publisherType": "ThirdParty","ratingAverage": 0.0,"ratingCount": 0,"productType": "DynamicsBC","popularity": 7.729569120865367,"privacyPolicyUri": "https://privacy.d365bc.is/","lastModifiedDateTime": "2024-01-19T03:23:15.4319343+00:00"}],"nextPageLink": "next page uri"}');
        // Push second without next page link
        AppSourceMockDepsProvider.SetJson('{"items": [{"uniqueProductId": "PUBID.pbsi_software|AID.247timetracker|PAPPID.9a12247e-8564-4b90-b80b-cd5f4b64217e","displayName": "Dynamics 365 Business Central - Second","publisherId": "pbsi_software","publisherDisplayName": "David Boehm, CPA and Company Inc.","publisherType": "ThirdParty","ratingAverage": 5.0,"ratingCount": 2,"productType": "DynamicsBC","popularity": 7.729569120865367,"privacyPolicyUri": "https://pbsisoftware.com/24-7-tt-privacy-statement","lastModifiedDateTime": "2023-09-03T11:08:28.5348241+00:00"}]}');
        AppSrcProductMgrTestImpl.SetDependencies(AppSourceMockDepsProvider);

        // When
        AppSrcProductMgrTestImpl.GetProductsAndPopulateRecord();

        //Then
        LibraryAssert.AreEqual(2, AppSrcProductMgrTestImpl.GetProductTableCount(), 'The number of products is incorrect.');
        LibraryAssert.IsTrue(AppSrcProductMgrTestImpl.IsRecordWithDisplayNameinProductTable('Dynamics 365 Business Central - First'), 'The first product name is incorrect.');
        LibraryAssert.IsTrue(AppSrcProductMgrTestImpl.IsRecordWithDisplayNameinProductTable('Dynamics 365 Business Central - Second'), 'The second product name is incorrect.');

        AppSrcProductMgrTestImpl.ResetDependencies();
    end;

    [HyperlinkHandler]
    procedure HyperlinkHandler(Message: Text[1024])
    begin
        LibraryAssert.AreEqual(HyperlinkStorage.DequeueText(), Message, 'The hyperlink is incorrect.');
    end;

    internal procedure Initialize()
    begin
        HyperlinkStorage.Clear();
    end;

    internal procedure AssertCleanedUp()
    begin
        HyperlinkStorage.AssertEmpty();
    end;
}