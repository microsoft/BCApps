// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139529 "Connectivity App Defn. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ConnectivityAppDefinitions: Codeunit "Connectivity App Definitions";

    [Test]
    procedure TestGetConnectivityAppDefinitions()
    var
        TempConnectivityApp: Record "Connectivity App" temporary;
        TempApprovedForConnectivityAppCountryOrRegion: Record "Conn. App Country/Region" temporary;
        TempWorksOnConnectivityAppLocalization: Record "Conn. App Country/Region" temporary;
    begin
        Initialize();

        // This test will ensure the data in the codeunit "Connectivity App Definitions" is parsed and loaded onto the temporary tables
        ConnectivityAppDefinitions.GetConnectivityAppDefinitions(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization);
        Assert.RecordIsNotEmpty(TempConnectivityApp);
        Assert.RecordIsNotEmpty(TempApprovedForConnectivityAppCountryOrRegion);
        Assert.RecordIsNotEmpty(TempWorksOnConnectivityAppLocalization);
    end;

    [Test]
    procedure TestApprovedConnectivityAppShouldAlsoWorkOnACountry()
    var
        TempConnectivityApp: Record "Connectivity App" temporary;
        TempApprovedForConnectivityAppCountryOrRegion: Record "Conn. App Country/Region" temporary;
        TempWorksOnConnectivityAppLocalization: Record "Conn. App Country/Region" temporary;
    begin
        Initialize();

        ConnectivityAppDefinitions.GetConnectivityAppDefinitions(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization);

        if TempWorksOnConnectivityAppLocalization.FindSet() then
            repeat
                TempApprovedForConnectivityAppCountryOrRegion.Get(TempApprovedForConnectivityAppCountryOrRegion."App Id", TempApprovedForConnectivityAppCountryOrRegion."Country/Region");
            until TempWorksOnConnectivityAppLocalization.Next() = 0;
    end;

    [Test]
    procedure TestContiniaBankingDefinitions()
    var
        TempConnectivityApp: Record "Connectivity App" temporary;
        TempApprovedForConnectivityAppCountryOrRegion: Record "Conn. App Country/Region" temporary;
        TempWorksOnConnectivityAppLocalization: Record "Conn. App Country/Region" temporary;
    begin
        Initialize();

        ConnectivityAppDefinitions.GetConnectivityAppDefinitions(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization);

        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, '5028cc6e-2288-4894-84a0-5934504a660c', 'AT', 'AT', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-at%7CPAPPID.5028cc6e-2288-4894-84a0-5934504a660c', Enum::"Conn. Apps Country/Region"::AT, Enum::"Connectivity Apps Localization"::AT);
        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, '99f643c2-bf89-4fe2-bb3a-e2a380635faf', 'CH', 'CH', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-ch%7CPAPPID.99f643c2-bf89-4fe2-bb3a-e2a380635faf', Enum::"Conn. Apps Country/Region"::CH, Enum::"Connectivity Apps Localization"::CH);
        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, '009dc3e3-3080-4e48-92fc-1bc7a0ef4caa', 'DE', 'DE', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-de%7CPAPPID.009dc3e3-3080-4e48-92fc-1bc7a0ef4caa', Enum::"Conn. Apps Country/Region"::DE, Enum::"Connectivity Apps Localization"::DE);
        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, '62235b56-656d-4e85-989b-fd47130bf4e5', 'DK', 'DK', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-dk%7CPAPPID.62235b56-656d-4e85-989b-fd47130bf4e5', Enum::"Conn. Apps Country/Region"::DK, Enum::"Connectivity Apps Localization"::DK);
        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, 'fb89b25e-b8be-4d31-b509-a29de965f12b', 'FI', 'FI', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-fi%7CPAPPID.fb89b25e-b8be-4d31-b509-a29de965f12b', Enum::"Conn. Apps Country/Region"::FI, Enum::"Connectivity Apps Localization"::FI);
        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, '4b595a5f-4e4f-49fb-9d25-b052a309f9c5', 'GB', 'UK', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-uk%7CPAPPID.4b595a5f-4e4f-49fb-9d25-b052a309f9c5', Enum::"Conn. Apps Country/Region"::GB, Enum::"Connectivity Apps Localization"::GB);
        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, 'f2303be5-5ecd-44db-b4e8-b1be22af4a53', 'NL', 'NL', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-nl%7CPAPPID.f2303be5-5ecd-44db-b4e8-b1be22af4a53', Enum::"Conn. Apps Country/Region"::NL, Enum::"Connectivity Apps Localization"::NL);
        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, 'e7b8a6d4-3c4e-4f8b-9a6e-8d3b8a6d4f8b', 'NO', 'NO', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-no%7CPAPPID.e7b8a6d4-3c4e-4f8b-9a6e-8d3b8a6d4f8b', Enum::"Conn. Apps Country/Region"::NO, Enum::"Connectivity Apps Localization"::NO);
        VerifyContiniaBankingDefinition(TempConnectivityApp, TempApprovedForConnectivityAppCountryOrRegion, TempWorksOnConnectivityAppLocalization, 'ffec28be-01ad-4e63-bcee-bed076b3aecc', 'SE', 'SE', 'https://marketplace.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.continia365%7CAID.continia-banking-se%7CPAPPID.ffec28be-01ad-4e63-bcee-bed076b3aecc', Enum::"Conn. Apps Country/Region"::SE, Enum::"Connectivity Apps Localization"::SE);
    end;

    local procedure Initialize()
    begin
        ConnectivityAppDefinitions.ClearConnectivityAppDefinitions();
    end;

    local procedure VerifyContiniaBankingDefinition(var TempConnectivityApp: Record "Connectivity App" temporary; var TempApprovedForConnectivityAppCountryOrRegion: Record "Conn. App Country/Region" temporary; var TempWorksOnConnectivityAppLocalization: Record "Conn. App Country/Region" temporary; AppIdText: Text[250]; LocalizationCode: Text[2]; ProductCode: Text[2]; ExpectedAppSourceURL: Text[2048]; CountryRegion: Enum "Conn. Apps Country/Region"; AppLocalization: Enum "Connectivity Apps Localization")
    var
        AppId: Guid;
    begin
        Evaluate(AppId, AppIdText);
        TempConnectivityApp.SetRange("App Id", AppId);
        if not TempConnectivityApp.FindFirst() then
            Assert.Fail(StrSubstNo('Continia Banking app %1 should be registered.', LocalizationCode));
        Assert.AreEqual('Continia Banking (' + ProductCode + ')', TempConnectivityApp.Name, 'Unexpected Continia Banking app name.');
        Assert.AreEqual('Continia Software', TempConnectivityApp.Publisher, 'Unexpected Continia Banking publisher.');
        Assert.AreEqual('https://www.continia.com/solutions/banking/', TempConnectivityApp."Provider Support URL", 'Unexpected Continia Banking support URL.');
        Assert.AreEqual(ExpectedAppSourceURL, TempConnectivityApp."AppSource URL", 'Unexpected Continia Banking AppSource URL.');
        Assert.AreEqual("Connectivity Apps Category"::Banking, TempConnectivityApp.Category, 'Unexpected Continia Banking category.');
        TempConnectivityApp.Reset();

        TempApprovedForConnectivityAppCountryOrRegion.SetRange("App Id", AppId);
        TempApprovedForConnectivityAppCountryOrRegion.SetRange("Country/Region", CountryRegion);
        TempApprovedForConnectivityAppCountryOrRegion.SetRange(Category, "Connectivity Apps Category"::Banking);
        Assert.IsFalse(TempApprovedForConnectivityAppCountryOrRegion.IsEmpty(), StrSubstNo('Continia Banking app %1 should be approved for %2.', LocalizationCode, Format(CountryRegion)));
        TempApprovedForConnectivityAppCountryOrRegion.Reset();

        TempWorksOnConnectivityAppLocalization.SetRange("App Id", AppId);
        TempWorksOnConnectivityAppLocalization.SetRange(Localization, AppLocalization);
        TempWorksOnConnectivityAppLocalization.SetRange(Category, "Connectivity Apps Category"::Banking);
        Assert.IsFalse(TempWorksOnConnectivityAppLocalization.IsEmpty(), StrSubstNo('Continia Banking app %1 should work on %2.', LocalizationCode, Format(AppLocalization)));
        TempWorksOnConnectivityAppLocalization.Reset();
    end;
}
