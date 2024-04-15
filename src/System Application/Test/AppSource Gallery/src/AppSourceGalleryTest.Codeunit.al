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

    [Test]
    // In AppSource this shows up as having the Buy Now button enabled
    procedure TestCanInstallProduct_BuyNow()
    var
        PlansList: JsonArray;
        CanInstall: Boolean;
    begin
        // Given
        // Hello world sample: PUBID.microsoftdynsmb%7CAID.helloworld%7CPAPPID.8e315acc-413d-46d5-abb9-c16912d3f3e3
        PlansList.ReadFrom('[{"id": "0002","availabilities": [{"id": "DZH318Z0BMGT","actions": ["Browse","Curate","Details","License","Purchase"],"meter": null,"pricingAudience": "DirectCommercial","terms": [{"termDescriptionParameters": null,"termId": "bh3541oe15ry","termUnit": "P1M","prorationPolicy": {"minimumProratedUnits": "P1D"},"termDescription": "1 Month Trial to 1 Year Subscription","price": {"currencyCode": "USD","isPIRequired": true,"listPrice": 0.0,"msrp": 0.0},"renewTermId": "qdp73gtwa5dy","renewTermUnits": "P1Y","isAutorenewable": true},{"termDescriptionParameters": null,"termId": "njspcsugneyy","termUnit": "P1M","prorationPolicy": {"minimumProratedUnits": "P1D"},"termDescription": "1 Month Trial to 1 Month Subscription","price": {"currencyCode": "USD","isPIRequired": true,"listPrice": 0.0,"msrp": 0.0},"renewTermId": "usrac41besqy","renewTermUnits": "P1M","isAutorenewable": true}],"hasFreeTrials": true,"consumptionUnitType": "DAY","displayRank": 0},{"id": "DZH318Z0BMGP","actions": ["Browse","Curate","Details","License","Purchase","Renew"],"meter": null,"pricingAudience": "DirectCommercial","terms": [{"termDescriptionParameters": null,"termId": "qdp73gtwa5dy","termUnit": "P1Y","prorationPolicy": {"minimumProratedUnits": "P1D"},"termDescription": "1 Year Subscription","price": {"currencyCode": "USD","isPIRequired": true,"listPrice": 0.02,"msrp": 0.02},"renewTermId": "qdp73gtwa5dy","renewTermUnits": "P1Y","isAutorenewable": true},{"termDescriptionParameters": null,"termId": "usrac41besqy","termUnit": "P1M","prorationPolicy": {"minimumProratedUnits": "P1D"},"termDescription": "1 Month Subscription","price": {"currencyCode": "USD","isPIRequired": true,"listPrice": 0.01,"msrp": 0.01},"renewTermId": "usrac41besqy","renewTermUnits": "P1M","isAutorenewable": true}],"hasFreeTrials": false,"consumptionUnitType": "DAY","displayRank": 1}],"uiDefinitionUri": "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RW15J0G","isHidden": false,"isStopSell": false,"cspState": "OptOut","minQuantity": 1,"maxQuantity": 10,"isQuantifiable": true,"purchaseDurationDiscounts": [],"planId": "transactableplan1","uniquePlanId": "microsoftdynsmb.helloworldtransactableplan1","displayName": "First 10 users","metadata": {"generation": null,"altStackReference": null},"categoryIds": [],"pricingTypes": ["FreeTrial","Payg"],"description": "Test plan to test first 10 users configurations","skuId": "0002","planType": "DynamicsBC","displayRank": "2147483647","isPrivate": false},{"id": "0003","availabilities": [{"id": "DZH318Z0BMGW","actions": ["Browse","Curate","Details","License","Purchase","Renew"],"meter": null,"pricingAudience": "DirectCommercial","terms": [{"termDescriptionParameters": null,"termId": "qdp73gtwa5dy","termUnit": "P1Y","prorationPolicy": {"minimumProratedUnits": "P1D"},"termDescription": "1 Year Subscription","price": {"currencyCode": "USD","isPIRequired": true,"listPrice": 0.03,"msrp": 0.03},"renewTermId": "qdp73gtwa5dy","renewTermUnits": "P1Y","isAutorenewable": true},{"termDescriptionParameters": null,"termId": "usrac41besqy","termUnit": "P1M","prorationPolicy": {"minimumProratedUnits": "P1D"},"termDescription": "1 Month Subscription","price": {"currencyCode": "USD","isPIRequired": true,"listPrice": 0.02,"msrp": 0.02},"renewTermId": "usrac41besqy","renewTermUnits": "P1M","isAutorenewable": true}],"hasFreeTrials": false,"consumptionUnitType": "DAY","displayRank": 0}],"uiDefinitionUri": "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RW15J0H","isHidden": false,"isStopSell": false,"cspState": "OptOut","minQuantity": 10,"maxQuantity": 100,"isQuantifiable": true,"purchaseDurationDiscounts": [],"planId": "transactableplan2","uniquePlanId": "microsoftdynsmb.helloworldtransactableplan2","displayName": "Ten to Hundred plan","metadata": {"generation": null,"altStackReference": null},"categoryIds": [],"pricingTypes": ["Payg"],"description": "Test 10 - 100 User plan","skuId": "0003","planType": "DynamicsBC","displayRank": "2147483647","isPrivate": false}]');

        // When
        CanInstall := AppSrcProductMgrTestImpl.CanInstallProductWithPlans(PlansList);

        // Then
        LibraryAssert.IsTrue(CanInstall, 'The product should be installable.');
    end;

    [Test]
    // In AppSource this shows up as having the Get It Now button enabled
    procedure TestCanInstallProduct_GetItNow()
    var
        PlansList: JsonArray;
        CanInstall: Boolean;
    begin
        // Given
        // Hello world too sample: PUBID.microsoftdynsmb%7CAID.helloworldtoo%7CPAPPID.37447a59-b131-4e9c-83a3-a7856bfc30ff
        PlansList.ReadFrom('[{"id": "0001","availabilities": [{"id": "DZH318Z0BMTW","actions": ["Browse","Curate","Details"],"meter": null,"pricingAudience": "DirectCommercial","terms": null,"hasFreeTrials": false,"displayRank": 0}],"uiDefinitionUri": "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE5c9A4","isHidden": false,"isStopSell": false,"isQuantifiable": false,"purchaseDurationDiscounts": [],"planId": "69fe2a5e-cb01-43ea-9af3-2417d0c843f2","uniquePlanId": "microsoftdynsmb.helloworldtoo69fe2a5e-cb01-43ea-9af3-2417d0c843f2","displayName": "HelloWorldToo","metadata": {"generation": null,"altStackReference": null},"categoryIds": [],"pricingTypes": [],"description": "<div>desc</div>","skuId": "0001","planType": "DynamicsBC","isPrivate": false}]');

        // When
        CanInstall := AppSrcProductMgrTestImpl.CanInstallProductWithPlans(PlansList);

        // Then
        if (CanInstall) then
            LibraryAssert.Fail('Test now produces expected outcome and should be update.');
    end;


    [Test]
    // In AppSource this shows up as having the Free Trial button enabled
    procedure TestCanInstallProduct_FreeTrial()
    var
        PlansList: JsonArray;
        CanInstall: Boolean;
    begin
        // Given
        // Manufacturing Central by Intech: PUBID.intechsystems%7CAID.manufacturing_central%7CPAPPID.cea8e27e-050e-4880-840c-954ceb2e3f13
        PlansList.ReadFrom('[{"id": "0001","availabilities": [{"id": "DZH318Z0BMV3","actions": ["Browse","Curate","Details"],"meter": null,"pricingAudience": "DirectCommercial","terms": null,"hasFreeTrials": false,"displayRank": 0}],"uiDefinitionUri": "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RW1fI7S","isHidden": false,"isStopSell": false,"isQuantifiable": false,"purchaseDurationDiscounts": [],"planId": "77447b7c-9737-4132-8191-b9ce21d35a0e","uniquePlanId": "intechsystems.manufacturing_central77447b7c-9737-4132-8191-b9ce21d35a0e","displayName": "Manufacturing Central","metadata": {"generation": null,"altStackReference": null},"categoryIds": [],"pricingTypes": [],"description": "<p>Hey there</p>","skuId": "0001","planType": "DynamicsBC","isPrivate": false}]');

        // When
        CanInstall := AppSrcProductMgrTestImpl.CanInstallProductWithPlans(PlansList);

        // Then
        if (CanInstall) then
            LibraryAssert.Fail('Test now produces expected outcome and should be update.');
    end;

    [Test]

    // In AppSource this shows up as having the Contact Me button enabled
    procedure TestCanInstallProduct_ContactMe()
    var
        PlansList: JsonArray;
        CanInstall: Boolean;
    begin
        // Given
        // Salesforce Integration by Celigo Inc: PUBID.celigoinc-causa1621285384596%7CAID.salesforce-integration-celigo%7CPAPPID.0595b87b-7670-4bd2-91e2-bd98a7fe2f5a
        PlansList.ReadFrom('[{"id": "0001","availabilities": [{"id": "DZH318Z0BMV7","actions": ["Browse","Curate","Details"],"meter": null,"pricingAudience": "DirectCommercial","terms": null,"hasFreeTrials": false,"displayRank": 0}],"uiDefinitionUri": "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE5fzzR","isHidden": false,"isStopSell": false,"isQuantifiable": false,"purchaseDurationDiscounts": [],"planId": "4b4a5c29-40ad-4169-b23c-1ea9a51fd176","uniquePlanId": "celigoinc-causa1621285384596.salesforce-integration-celigo4b4a5c29-40ad-4169-b23c-1ea9a51fd176","displayName": "Salesforce Integration for Dynamics 365 Business Central","metadata": {"generation": null,"altStackReference": null},"categoryIds": [],"pricingTypes": [],"description": "<div>Celigo</div>","skuId": "0001","planType": "DynamicsBC","isPrivate": false}]');

        // When
        CanInstall := AppSrcProductMgrTestImpl.CanInstallProductWithPlans(PlansList);

        // Then
        LibraryAssert.IsFalse(CanInstall, 'The product NOT should be installable.');
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