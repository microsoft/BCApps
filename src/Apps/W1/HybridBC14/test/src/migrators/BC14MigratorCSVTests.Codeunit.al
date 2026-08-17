// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Bank.BankAccount;
using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using System.Globalization;

/// <summary>
/// CSV-driven happy-path tests for BC14 migrators. Pattern mirrors HybridSL:
/// load buffer rows from a CSV resource, run the migrator on each row,
/// then compare each migrated record to the expected row loaded from another CSV.
/// All migrator CSV tests live in this codeunit; add new tests here rather than
/// creating one codeunit per migrator.
/// </summary>
codeunit 148912 "BC14 Migrator CSV Tests"
{
    // [FEATURE] [BC14 Migrators] [CSV Driven]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        BC14TestHelper: Codeunit "BC14 Test Helper Functions";
        FieldMismatchLbl: Label 'Field %1 of %2 %3 does not match expected.', Comment = '%1 = field name, %2 = entity name, %3 = key';
        RecordNotFoundLbl: Label 'Expected %1 %2 was not migrated.', Comment = '%1 = entity name, %2 = key';
        CountMismatchLbl: Label 'Number of migrated %1 does not match expected.', Comment = '%1 = entity name';

    // ====================================================================
    // Customer
    // ====================================================================

    [Test]
    procedure TestMigrateCustomers_FromCsv_MatchesExpected()
    var
        BC14Customer: Record "BC14 Customer";
        Customer: Record Customer;
        TempExpectedCustomer: Record Customer temporary;
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
        ExpectedXmlPort: XmlPort "BC14 Expected Customer Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetCustomers();
        BC14TestHelper.ClearBC14CustomerBuffer();
        BC14TestHelper.ClearGLSetupLCYCode();
        BC14TestHelper.ImportBC14CustomerData();

        if BC14Customer.FindSet() then
            repeat
                BC14CustomerMigrator.MigrateCustomer(BC14Customer);
            until BC14Customer.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/Customer.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedCustomers(TempExpectedCustomer);

        Assert.AreEqual(TempExpectedCustomer.Count(), Customer.Count(), StrSubstNo(CountMismatchLbl, 'Customers'));

        TempExpectedCustomer.FindSet();
        repeat
            Assert.IsTrue(Customer.Get(TempExpectedCustomer."No."), StrSubstNo(RecordNotFoundLbl, 'Customer', TempExpectedCustomer."No."));
            AssertCustomerFieldsMatch(TempExpectedCustomer, Customer);
        until TempExpectedCustomer.Next() = 0;
    end;

    local procedure AssertCustomerFieldsMatch(Expected: Record Customer; Actual: Record Customer)
    begin
        Assert.AreEqual(Expected.Name, Actual.Name, Mismatch('Name', 'Customer', Expected."No."));
        Assert.AreEqual(Expected.Address, Actual.Address, Mismatch('Address', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Address 2", Actual."Address 2", Mismatch('Address 2', 'Customer', Expected."No."));
        Assert.AreEqual(Expected.City, Actual.City, Mismatch('City', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Post Code", Actual."Post Code", Mismatch('Post Code', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Country/Region Code", Actual."Country/Region Code", Mismatch('Country/Region Code', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Phone No.", Actual."Phone No.", Mismatch('Phone No.', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."E-Mail", Actual."E-Mail", Mismatch('E-Mail', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Home Page", Actual."Home Page", Mismatch('Home Page', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Customer Posting Group", Actual."Customer Posting Group", Mismatch('Customer Posting Group', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Gen. Bus. Posting Group", Actual."Gen. Bus. Posting Group", Mismatch('Gen. Bus. Posting Group', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Payment Terms Code", Actual."Payment Terms Code", Mismatch('Payment Terms Code', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Currency Code", Actual."Currency Code", Mismatch('Currency Code', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Language Code", Actual."Language Code", Mismatch('Language Code', 'Customer', Expected."No."));
        Assert.AreEqual(Expected."Credit Limit (LCY)", Actual."Credit Limit (LCY)", Mismatch('Credit Limit (LCY)', 'Customer', Expected."No."));
        Assert.AreEqual(Expected.Blocked, Actual.Blocked, Mismatch('Blocked', 'Customer', Expected."No."));
    end;

    // ====================================================================
    // Vendor
    // ====================================================================

    [Test]
    procedure TestMigrateVendors_FromCsv_MatchesExpected()
    var
        BC14Vendor: Record "BC14 Vendor";
        Vendor: Record Vendor;
        TempExpectedVendor: Record Vendor temporary;
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
        ExpectedXmlPort: XmlPort "BC14 Expected Vendor Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetVendors();
        BC14TestHelper.ClearBC14VendorBuffer();
        BC14TestHelper.ClearGLSetupLCYCode();
        BC14TestHelper.ImportBC14VendorData();

        if BC14Vendor.FindSet() then
            repeat
                BC14VendorMigrator.MigrateVendor(BC14Vendor);
            until BC14Vendor.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/Vendor.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedVendors(TempExpectedVendor);

        Assert.AreEqual(TempExpectedVendor.Count(), Vendor.Count(), StrSubstNo(CountMismatchLbl, 'Vendors'));

        TempExpectedVendor.FindSet();
        repeat
            Assert.IsTrue(Vendor.Get(TempExpectedVendor."No."), StrSubstNo(RecordNotFoundLbl, 'Vendor', TempExpectedVendor."No."));
            AssertVendorFieldsMatch(TempExpectedVendor, Vendor);
        until TempExpectedVendor.Next() = 0;
    end;

    local procedure AssertVendorFieldsMatch(Expected: Record Vendor; Actual: Record Vendor)
    begin
        Assert.AreEqual(Expected.Name, Actual.Name, Mismatch('Name', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected.Address, Actual.Address, Mismatch('Address', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected.City, Actual.City, Mismatch('City', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."Post Code", Actual."Post Code", Mismatch('Post Code', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."Country/Region Code", Actual."Country/Region Code", Mismatch('Country/Region Code', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."Phone No.", Actual."Phone No.", Mismatch('Phone No.', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."E-Mail", Actual."E-Mail", Mismatch('E-Mail', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."Vendor Posting Group", Actual."Vendor Posting Group", Mismatch('Vendor Posting Group', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."Gen. Bus. Posting Group", Actual."Gen. Bus. Posting Group", Mismatch('Gen. Bus. Posting Group', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."Payment Terms Code", Actual."Payment Terms Code", Mismatch('Payment Terms Code', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."Currency Code", Actual."Currency Code", Mismatch('Currency Code', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected."Language Code", Actual."Language Code", Mismatch('Language Code', 'Vendor', Expected."No."));
        Assert.AreEqual(Expected.Blocked, Actual.Blocked, Mismatch('Blocked', 'Vendor', Expected."No."));
    end;

    // ====================================================================
    // Item
    // ====================================================================

    [Test]
    procedure TestMigrateItems_FromCsv_MatchesExpected()
    var
        BC14Item: Record "BC14 Item";
        Item: Record Item;
        TempExpectedItem: Record Item temporary;
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
        ExpectedXmlPort: XmlPort "BC14 Expected Item Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetItems();
        BC14TestHelper.ClearBC14ItemBuffer();
        BC14TestHelper.SeedGenProdPostingGroupsForItemTests();
        BC14TestHelper.SeedInventoryPostingGroupsForItemTests();
        BC14TestHelper.ImportBC14ItemData();

        if BC14Item.FindSet() then
            repeat
                BC14ItemMigrator.MigrateItem(BC14Item);
            until BC14Item.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/Item.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedItems(TempExpectedItem);

        Assert.AreEqual(TempExpectedItem.Count(), Item.Count(), StrSubstNo(CountMismatchLbl, 'Items'));

        TempExpectedItem.FindSet();
        repeat
            Assert.IsTrue(Item.Get(TempExpectedItem."No."), StrSubstNo(RecordNotFoundLbl, 'Item', TempExpectedItem."No."));
            AssertItemFieldsMatch(TempExpectedItem, Item);
        until TempExpectedItem.Next() = 0;
    end;

    local procedure AssertItemFieldsMatch(Expected: Record Item; Actual: Record Item)
    begin
        Assert.AreEqual(Expected.Description, Actual.Description, Mismatch('Description', 'Item', Expected."No."));
        Assert.AreEqual(Expected.Type, Actual.Type, Mismatch('Type', 'Item', Expected."No."));
        Assert.AreEqual(Expected."Unit Price", Actual."Unit Price", Mismatch('Unit Price', 'Item', Expected."No."));
        Assert.AreEqual(Expected."Standard Cost", Actual."Standard Cost", Mismatch('Standard Cost', 'Item', Expected."No."));
        Assert.AreEqual(Expected."Unit Cost", Actual."Unit Cost", Mismatch('Unit Cost', 'Item', Expected."No."));
        Assert.AreEqual(Expected.Blocked, Actual.Blocked, Mismatch('Blocked', 'Item', Expected."No."));
        Assert.AreEqual(Expected."Inventory Posting Group", Actual."Inventory Posting Group", Mismatch('Inventory Posting Group', 'Item', Expected."No."));
        Assert.AreEqual(Expected."Gen. Prod. Posting Group", Actual."Gen. Prod. Posting Group", Mismatch('Gen. Prod. Posting Group', 'Item', Expected."No."));
        Assert.AreEqual(Expected."Costing Method", Actual."Costing Method", Mismatch('Costing Method', 'Item', Expected."No."));
        Assert.AreEqual(Expected."Net Weight", Actual."Net Weight", Mismatch('Net Weight', 'Item', Expected."No."));
        Assert.AreEqual(Expected."Unit Volume", Actual."Unit Volume", Mismatch('Unit Volume', 'Item', Expected."No."));
    end;

    // ====================================================================
    // G/L Account
    // ====================================================================

    [Test]
    procedure TestMigrateGLAccounts_FromCsv_MatchesExpected()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        GLAccount: Record "G/L Account";
        TempExpectedGLAccount: Record "G/L Account" temporary;
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
        ExpectedXmlPort: XmlPort "BC14 Expected GL Account Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetGLAccounts();
        BC14TestHelper.ClearBC14GLAccountBuffer();
        BC14TestHelper.ImportBC14GLAccountData();

        if BC14GLAccount.FindSet() then
            repeat
                BC14GLAccountMigrator.MigrateGLAccount(BC14GLAccount);
            until BC14GLAccount.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/GLAccount.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedGLAccounts(TempExpectedGLAccount);

        Assert.AreEqual(TempExpectedGLAccount.Count(), GLAccount.Count(), StrSubstNo(CountMismatchLbl, 'G/L Accounts'));

        TempExpectedGLAccount.FindSet();
        repeat
            Assert.IsTrue(GLAccount.Get(TempExpectedGLAccount."No."), StrSubstNo(RecordNotFoundLbl, 'G/L Account', TempExpectedGLAccount."No."));
            AssertGLAccountFieldsMatch(TempExpectedGLAccount, GLAccount);
        until TempExpectedGLAccount.Next() = 0;
    end;

    local procedure AssertGLAccountFieldsMatch(Expected: Record "G/L Account"; Actual: Record "G/L Account")
    begin
        Assert.AreEqual(Expected.Name, Actual.Name, Mismatch('Name', 'G/L Account', Expected."No."));
        Assert.AreEqual(Expected."Account Type", Actual."Account Type", Mismatch('Account Type', 'G/L Account', Expected."No."));
        Assert.AreEqual(Expected."Income/Balance", Actual."Income/Balance", Mismatch('Income/Balance', 'G/L Account', Expected."No."));
        Assert.AreEqual(Expected."Debit/Credit", Actual."Debit/Credit", Mismatch('Debit/Credit', 'G/L Account', Expected."No."));
        Assert.AreEqual(Expected.Blocked, Actual.Blocked, Mismatch('Blocked', 'G/L Account', Expected."No."));
        Assert.AreEqual(Expected."Account Category", Actual."Account Category", Mismatch('Account Category', 'G/L Account', Expected."No."));
        Assert.AreEqual(Expected."Account Subcategory Entry No.", Actual."Account Subcategory Entry No.", Mismatch('Account Subcategory Entry No.', 'G/L Account', Expected."No."));
    end;

    // ====================================================================
    // Customer Bank Account / Vendor Bank Account
    // ====================================================================
    // TODO: Re-add CSV-driven happy-path tests for BC14 Customer Bank Account
    // and BC14 Vendor Bank Account migrators. The previous versions
    // (TestMigrateCustomerBankAccounts_FromCsv_MatchesExpected,
    //  TestMigrateVendorBankAccounts_FromCsv_MatchesExpected) were removed
    // because the CSV fixture had no "Country/Region Code" column and used
    // non-localized bank account numbers, which the migrator then fed into
    // Validate("Bank Account No.") on the live table. Country localizations
    // that inject strict format validation on that OnValidate trigger
    // (e.g. FI codeunit 32000002 "Bank Nos Check" requiring "xxxxxx-xxxxx")
    // rejected the fixture and made the test fail in those builds.
    //
    // To restore coverage:
    //   1. Add a "Country/Region Code" column to
    //      .resources/datasets/input/BC14CustomerBankAccount.csv,
    //      .resources/datasets/input/BC14VendorBankAccount.csv and the
    //      matching results CSVs; pick country codes that line up with the
    //      IBAN prefix on each row.
    //   2. Extend the four bank account XmlPorts (BC14CustomerBankAcctData,
    //      BC14ExpCustomerBankAcct, BC14VendorBankAcctData,
    //      BC14ExpVendorBankAcct) with a CountryRegionCode textelement that
    //      Validates "Country/Region Code".
    //   3. Add a SeedCountriesForBankAccountTests helper in
    //      BC14TestHelperFunctions covering the codes used in the CSVs.
    //   4. Extend AssertCustomerBankAccountFieldsMatch /
    //      AssertVendorBankAccountFieldsMatch to also compare
    //      "Country/Region Code".

    // ====================================================================
    // Ship-to Address
    // ====================================================================

    [Test]
    procedure TestMigrateShipToAddresses_FromCsv_MatchesExpected()
    var
        BC14ShipToAddress: Record "BC14 Ship-to Address";
        ShipToAddress: Record "Ship-to Address";
        TempExpected: Record "Ship-to Address" temporary;
        BC14ShipToAddrMigrator: Codeunit "BC14 Ship-to Address Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Ship-to Address";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetShipToAddresses();
        BC14TestHelper.ClearBC14ShipToAddressBuffer();
        BC14TestHelper.SeedCountriesForShipToAddressTests();
        BC14TestHelper.ImportBC14ShipToAddressData();

        if BC14ShipToAddress.FindSet() then
            repeat
                BC14ShipToAddrMigrator.MigrateShipToAddress(BC14ShipToAddress);
            until BC14ShipToAddress.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/ShipToAddress.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedShipToAddresses(TempExpected);

        Assert.AreEqual(TempExpected.Count(), ShipToAddress.Count(), StrSubstNo(CountMismatchLbl, 'Ship-to Addresses'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(ShipToAddress.Get(TempExpected."Customer No.", TempExpected.Code),
                StrSubstNo(RecordNotFoundLbl, 'Ship-to Address', TempExpected."Customer No." + '/' + TempExpected.Code));
            AssertShipToAddressFieldsMatch(TempExpected, ShipToAddress);
        until TempExpected.Next() = 0;
    end;

    local procedure AssertShipToAddressFieldsMatch(Expected: Record "Ship-to Address"; Actual: Record "Ship-to Address")
    var
        KeyTxt: Text;
    begin
        KeyTxt := Expected."Customer No." + '/' + Expected.Code;
        Assert.AreEqual(Expected.Name, Actual.Name, Mismatch('Name', 'Ship-to Address', KeyTxt));
        Assert.AreEqual(Expected.Address, Actual.Address, Mismatch('Address', 'Ship-to Address', KeyTxt));
        Assert.AreEqual(Expected.City, Actual.City, Mismatch('City', 'Ship-to Address', KeyTxt));
        Assert.AreEqual(Expected."Post Code", Actual."Post Code", Mismatch('Post Code', 'Ship-to Address', KeyTxt));
        Assert.AreEqual(Expected."Country/Region Code", Actual."Country/Region Code", Mismatch('Country/Region Code', 'Ship-to Address', KeyTxt));
    end;

    // ====================================================================
    // BOM Component
    // ====================================================================

    [Test]
    procedure TestMigrateBOMComponents_FromCsv_MatchesExpected()
    var
        BC14BOMComponent: Record "BC14 BOM Component";
        BOMComponent: Record "BOM Component";
        TempExpected: Record "BOM Component" temporary;
        BC14BOMComponentMigrator: Codeunit "BC14 BOM Component Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp BOM Component Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetBOMComponents();
        BC14TestHelper.ClearBC14BOMComponentBuffer();
        BC14TestHelper.SeedItemsForBOMTests();
        BC14TestHelper.SeedUnitsOfMeasureForBOMTests();
        BC14TestHelper.ImportBC14BOMComponentData();

        if BC14BOMComponent.FindSet() then
            repeat
                BC14BOMComponentMigrator.MigrateBOMComponent(BC14BOMComponent);
            until BC14BOMComponent.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/BOMComponent.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedBOMComponents(TempExpected);

        Assert.AreEqual(TempExpected.Count(), BOMComponent.Count(), StrSubstNo(CountMismatchLbl, 'BOM Components'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(BOMComponent.Get(TempExpected."Parent Item No.", TempExpected."Line No."),
                StrSubstNo(RecordNotFoundLbl, 'BOM Component', TempExpected."Parent Item No." + '/' + Format(TempExpected."Line No.")));
            AssertBOMComponentFieldsMatch(TempExpected, BOMComponent);
        until TempExpected.Next() = 0;
    end;

    local procedure AssertBOMComponentFieldsMatch(Expected: Record "BOM Component"; Actual: Record "BOM Component")
    var
        KeyTxt: Text;
    begin
        KeyTxt := Expected."Parent Item No." + '/' + Format(Expected."Line No.");
        Assert.AreEqual(Expected.Type, Actual.Type, Mismatch('Type', 'BOM Component', KeyTxt));
        Assert.AreEqual(Expected."No.", Actual."No.", Mismatch('No.', 'BOM Component', KeyTxt));
        Assert.AreEqual(Expected.Description, Actual.Description, Mismatch('Description', 'BOM Component', KeyTxt));
        Assert.AreEqual(Expected."Unit of Measure Code", Actual."Unit of Measure Code", Mismatch('Unit of Measure Code', 'BOM Component', KeyTxt));
        Assert.AreEqual(Expected."Quantity per", Actual."Quantity per", Mismatch('Quantity per', 'BOM Component', KeyTxt));
    end;

    // ====================================================================
    // Country/Region
    // ====================================================================

    [Test]
    procedure TestMigrateCountryRegions_FromCsv_MatchesExpected()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        CountryRegion: Record "Country/Region";
        TempExpectedCountryRegion: Record "Country/Region" temporary;
        BC14CountryRegionMigrator: Codeunit "BC14 Country/Region Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Country/Region Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetCountryRegions();
        BC14TestHelper.ClearBC14CountryRegionBuffer();
        BC14TestHelper.ImportBC14CountryRegionData();

        if BC14CountryRegion.FindSet() then
            repeat
                BC14CountryRegionMigrator.MigrateCountryRegion(BC14CountryRegion);
            until BC14CountryRegion.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/CountryRegion.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedCountryRegions(TempExpectedCountryRegion);

        Assert.AreEqual(TempExpectedCountryRegion.Count(), CountryRegion.Count(), StrSubstNo(CountMismatchLbl, 'Country/Regions'));

        TempExpectedCountryRegion.FindSet();
        repeat
            Assert.IsTrue(CountryRegion.Get(TempExpectedCountryRegion.Code), StrSubstNo(RecordNotFoundLbl, 'Country/Region', TempExpectedCountryRegion.Code));
            AssertCountryRegionFieldsMatch(TempExpectedCountryRegion, CountryRegion);
        until TempExpectedCountryRegion.Next() = 0;
    end;

    local procedure AssertCountryRegionFieldsMatch(Expected: Record "Country/Region"; Actual: Record "Country/Region")
    begin
        Assert.AreEqual(Expected.Name, Actual.Name, Mismatch('Name', 'Country/Region', Expected.Code));
        Assert.AreEqual(Expected."ISO Code", Actual."ISO Code", Mismatch('ISO Code', 'Country/Region', Expected.Code));
        Assert.AreEqual(Expected."ISO Numeric Code", Actual."ISO Numeric Code", Mismatch('ISO Numeric Code', 'Country/Region', Expected.Code));
        Assert.AreEqual(Expected."EU Country/Region Code", Actual."EU Country/Region Code", Mismatch('EU Country/Region Code', 'Country/Region', Expected.Code));
        Assert.AreEqual(Expected."Intrastat Code", Actual."Intrastat Code", Mismatch('Intrastat Code', 'Country/Region', Expected.Code));
        Assert.AreEqual(Expected."Address Format", Actual."Address Format", Mismatch('Address Format', 'Country/Region', Expected.Code));
        Assert.AreEqual(Expected."Contact Address Format", Actual."Contact Address Format", Mismatch('Contact Address Format', 'Country/Region', Expected.Code));
        Assert.AreEqual(Expected."VAT Scheme", Actual."VAT Scheme", Mismatch('VAT Scheme', 'Country/Region', Expected.Code));
        Assert.AreEqual(Expected."County Name", Actual."County Name", Mismatch('County Name', 'Country/Region', Expected.Code));
    end;

    // ====================================================================
    // Language
    // ====================================================================

    [Test]
    procedure TestMigrateLanguages_FromCsv_MatchesExpected()
    var
        BC14Language: Record "BC14 Language";
        Language: Record Language;
        TempExpectedLanguage: Record Language temporary;
        BC14LanguageMigrator: Codeunit "BC14 Language Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Language Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetLanguages();
        BC14TestHelper.ClearBC14LanguageBuffer();
        BC14TestHelper.ImportBC14LanguageData();

        if BC14Language.FindSet() then
            repeat
                BC14LanguageMigrator.MigrateLanguage(BC14Language);
            until BC14Language.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/Language.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedLanguages(TempExpectedLanguage);

        Assert.AreEqual(TempExpectedLanguage.Count(), Language.Count(), StrSubstNo(CountMismatchLbl, 'Languages'));

        TempExpectedLanguage.FindSet();
        repeat
            Assert.IsTrue(Language.Get(TempExpectedLanguage.Code), StrSubstNo(RecordNotFoundLbl, 'Language', TempExpectedLanguage.Code));
            Assert.AreEqual(TempExpectedLanguage.Name, Language.Name, Mismatch('Name', 'Language', TempExpectedLanguage.Code));
            Assert.AreEqual(TempExpectedLanguage."Windows Language ID", Language."Windows Language ID", Mismatch('Windows Language ID', 'Language', TempExpectedLanguage.Code));
        until TempExpectedLanguage.Next() = 0;
    end;

    // ====================================================================
    // Territory
    // ====================================================================

    [Test]
    procedure TestMigrateTerritories_FromCsv_MatchesExpected()
    var
        BC14Territory: Record "BC14 Territory";
        Territory: Record Territory;
        TempExpectedTerritory: Record Territory temporary;
        BC14TerritoryMigrator: Codeunit "BC14 Territory Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Territory Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetTerritories();
        BC14TestHelper.ClearBC14TerritoryBuffer();
        BC14TestHelper.ImportBC14TerritoryData();

        if BC14Territory.FindSet() then
            repeat
                BC14TerritoryMigrator.MigrateTerritory(BC14Territory);
            until BC14Territory.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/Territory.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedTerritories(TempExpectedTerritory);

        Assert.AreEqual(TempExpectedTerritory.Count(), Territory.Count(), StrSubstNo(CountMismatchLbl, 'Territories'));

        TempExpectedTerritory.FindSet();
        repeat
            Assert.IsTrue(Territory.Get(TempExpectedTerritory.Code), StrSubstNo(RecordNotFoundLbl, 'Territory', TempExpectedTerritory.Code));
        until TempExpectedTerritory.Next() = 0;
    end;

    // ====================================================================
    // Source Code
    // ====================================================================

    [Test]
    procedure TestMigrateSourceCodes_FromCsv_MatchesExpected()
    var
        BC14SourceCode: Record "BC14 Source Code";
        SourceCode: Record "Source Code";
        TempExpectedSourceCode: Record "Source Code" temporary;
        BC14SourceCodeMigrator: Codeunit "BC14 Source Code Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Source Code Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetSourceCodes();
        BC14TestHelper.ClearBC14SourceCodeBuffer();
        BC14TestHelper.ImportBC14SourceCodeData();

        if BC14SourceCode.FindSet() then
            repeat
                BC14SourceCodeMigrator.MigrateSourceCode(BC14SourceCode);
            until BC14SourceCode.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/SourceCode.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedSourceCodes(TempExpectedSourceCode);

        Assert.AreEqual(TempExpectedSourceCode.Count(), SourceCode.Count(), StrSubstNo(CountMismatchLbl, 'Source Codes'));

        TempExpectedSourceCode.FindSet();
        repeat
            Assert.IsTrue(SourceCode.Get(TempExpectedSourceCode.Code), StrSubstNo(RecordNotFoundLbl, 'Source Code', TempExpectedSourceCode.Code));
            Assert.AreEqual(TempExpectedSourceCode.Description, SourceCode.Description, Mismatch('Description', 'Source Code', TempExpectedSourceCode.Code));
        until TempExpectedSourceCode.Next() = 0;
    end;

    // ====================================================================
    // Reason Code
    // ====================================================================

    [Test]
    procedure TestMigrateReasonCodes_FromCsv_MatchesExpected()
    var
        BC14ReasonCode: Record "BC14 Reason Code";
        ReasonCode: Record "Reason Code";
        TempExpectedReasonCode: Record "Reason Code" temporary;
        BC14ReasonCodeMigrator: Codeunit "BC14 Reason Code Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Reason Code Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetReasonCodes();
        BC14TestHelper.ClearBC14ReasonCodeBuffer();
        BC14TestHelper.ImportBC14ReasonCodeData();

        if BC14ReasonCode.FindSet() then
            repeat
                BC14ReasonCodeMigrator.MigrateReasonCode(BC14ReasonCode);
            until BC14ReasonCode.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/ReasonCode.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedReasonCodes(TempExpectedReasonCode);

        Assert.AreEqual(TempExpectedReasonCode.Count(), ReasonCode.Count(), StrSubstNo(CountMismatchLbl, 'Reason Codes'));

        TempExpectedReasonCode.FindSet();
        repeat
            Assert.IsTrue(ReasonCode.Get(TempExpectedReasonCode.Code), StrSubstNo(RecordNotFoundLbl, 'Reason Code', TempExpectedReasonCode.Code));
            Assert.AreEqual(TempExpectedReasonCode.Description, ReasonCode.Description, Mismatch('Description', 'Reason Code', TempExpectedReasonCode.Code));
        until TempExpectedReasonCode.Next() = 0;
    end;

    // ====================================================================
    // Tariff Number
    // ====================================================================

    [Test]
    procedure TestMigrateTariffNumbers_FromCsv_MatchesExpected()
    var
        BC14TariffNumber: Record "BC14 Tariff Number";
        TariffNumber: Record "Tariff Number";
        TempExpectedTariffNumber: Record "Tariff Number" temporary;
        BC14TariffNumberMigrator: Codeunit "BC14 Tariff Number Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Tariff Number Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetTariffNumbers();
        BC14TestHelper.ClearBC14TariffNumberBuffer();
        BC14TestHelper.ImportBC14TariffNumberData();

        if BC14TariffNumber.FindSet() then
            repeat
                BC14TariffNumberMigrator.MigrateTariffNumber(BC14TariffNumber);
            until BC14TariffNumber.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/TariffNumber.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedTariffNumbers(TempExpectedTariffNumber);

        Assert.AreEqual(TempExpectedTariffNumber.Count(), TariffNumber.Count(), StrSubstNo(CountMismatchLbl, 'Tariff Numbers'));

        TempExpectedTariffNumber.FindSet();
        repeat
            Assert.IsTrue(TariffNumber.Get(TempExpectedTariffNumber."No."), StrSubstNo(RecordNotFoundLbl, 'Tariff Number', TempExpectedTariffNumber."No."));
            Assert.AreEqual(TempExpectedTariffNumber.Description, TariffNumber.Description, Mismatch('Description', 'Tariff Number', TempExpectedTariffNumber."No."));
            Assert.AreEqual(TempExpectedTariffNumber."Supplementary Units", TariffNumber."Supplementary Units", Mismatch('Supplementary Units', 'Tariff Number', TempExpectedTariffNumber."No."));
        until TempExpectedTariffNumber.Next() = 0;
    end;

    // ====================================================================
    // Payment Method
    // ====================================================================

    [Test]
    procedure TestMigratePaymentMethods_FromCsv_MatchesExpected()
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
        PaymentMethod: Record "Payment Method";
        TempExpectedPaymentMethod: Record "Payment Method" temporary;
        BC14PaymentMethodMigrator: Codeunit "BC14 Payment Method Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Payment Method Data";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetPaymentMethods();
        BC14TestHelper.ClearBC14PaymentMethodBuffer();
        BC14TestHelper.ImportBC14PaymentMethodData();

        if BC14PaymentMethod.FindSet() then
            repeat
                BC14PaymentMethodMigrator.MigratePaymentMethod(BC14PaymentMethod);
            until BC14PaymentMethod.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/PaymentMethod.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedPaymentMethods(TempExpectedPaymentMethod);

        Assert.AreEqual(TempExpectedPaymentMethod.Count(), PaymentMethod.Count(), StrSubstNo(CountMismatchLbl, 'Payment Methods'));

        TempExpectedPaymentMethod.FindSet();
        repeat
            Assert.IsTrue(PaymentMethod.Get(TempExpectedPaymentMethod.Code), StrSubstNo(RecordNotFoundLbl, 'Payment Method', TempExpectedPaymentMethod.Code));
            Assert.AreEqual(TempExpectedPaymentMethod.Description, PaymentMethod.Description, Mismatch('Description', 'Payment Method', TempExpectedPaymentMethod.Code));
            Assert.AreEqual(TempExpectedPaymentMethod."Bal. Account Type", PaymentMethod."Bal. Account Type", Mismatch('Bal. Account Type', 'Payment Method', TempExpectedPaymentMethod.Code));
            Assert.AreEqual(TempExpectedPaymentMethod."Bal. Account No.", PaymentMethod."Bal. Account No.", Mismatch('Bal. Account No.', 'Payment Method', TempExpectedPaymentMethod.Code));
            Assert.AreEqual(TempExpectedPaymentMethod."Direct Debit", PaymentMethod."Direct Debit", Mismatch('Direct Debit', 'Payment Method', TempExpectedPaymentMethod.Code));
            Assert.AreEqual(TempExpectedPaymentMethod."Direct Debit Pmt. Terms Code", PaymentMethod."Direct Debit Pmt. Terms Code", Mismatch('Direct Debit Pmt. Terms Code', 'Payment Method', TempExpectedPaymentMethod.Code));
        until TempExpectedPaymentMethod.Next() = 0;
    end;

    // ====================================================================
    // Gen. Business Posting Group
    // ====================================================================

    [Test]
    procedure TestMigrateGenBusPostingGroups_FromCsv_MatchesExpected()
    var
        BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        TempExpected: Record "Gen. Business Posting Group" temporary;
        Migrator: Codeunit "BC14 GenBus PG Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp GenBusPG";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetGenBusPostingGroups();
        BC14TestHelper.ClearBC14GenBusPostingGroupBuffer();
        BC14TestHelper.ImportBC14GenBusPGData();

        if BC14GenBusPostingGroup.FindSet() then
            repeat
                Migrator.MigrateGenBusPostingGroup(BC14GenBusPostingGroup);
            until BC14GenBusPostingGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/GenBusPG.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedGenBusPostingGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), GenBusPostingGroup.Count(), StrSubstNo(CountMismatchLbl, 'Gen. Business Posting Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(GenBusPostingGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Gen. Business Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, GenBusPostingGroup.Description, Mismatch('Description', 'Gen. Business Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected."Auto Insert Default", GenBusPostingGroup."Auto Insert Default", Mismatch('Auto Insert Default', 'Gen. Business Posting Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Gen. Product Posting Group
    // ====================================================================

    [Test]
    procedure TestMigrateGenProdPostingGroups_FromCsv_MatchesExpected()
    var
        BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        TempExpected: Record "Gen. Product Posting Group" temporary;
        Migrator: Codeunit "BC14 GenProd PG Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp GenProdPG";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetGenProdPostingGroups();
        BC14TestHelper.ClearBC14GenProdPostingGroupBuffer();
        BC14TestHelper.ImportBC14GenProdPGData();

        if BC14GenProdPostingGroup.FindSet() then
            repeat
                Migrator.MigrateGenProdPostingGroup(BC14GenProdPostingGroup);
            until BC14GenProdPostingGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/GenProdPG.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedGenProdPostingGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), GenProdPostingGroup.Count(), StrSubstNo(CountMismatchLbl, 'Gen. Product Posting Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(GenProdPostingGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Gen. Product Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, GenProdPostingGroup.Description, Mismatch('Description', 'Gen. Product Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected."Auto Insert Default", GenProdPostingGroup."Auto Insert Default", Mismatch('Auto Insert Default', 'Gen. Product Posting Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // VAT Business Posting Group
    // ====================================================================

    [Test]
    procedure TestMigrateVATBusPostingGroups_FromCsv_MatchesExpected()
    var
        BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        TempExpected: Record "VAT Business Posting Group" temporary;
        Migrator: Codeunit "BC14 VATBus PG Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp VATBusPG";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetVATBusPostingGroups();
        BC14TestHelper.ClearBC14VATBusPostingGroupBuffer();
        BC14TestHelper.ImportBC14VATBusPGData();

        if BC14VATBusPostingGroup.FindSet() then
            repeat
                Migrator.MigrateVATBusPostingGroup(BC14VATBusPostingGroup);
            until BC14VATBusPostingGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/VATBusPG.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedVATBusPostingGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), VATBusPostingGroup.Count(), StrSubstNo(CountMismatchLbl, 'VAT Business Posting Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(VATBusPostingGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'VAT Business Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, VATBusPostingGroup.Description, Mismatch('Description', 'VAT Business Posting Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // VAT Product Posting Group
    // ====================================================================

    [Test]
    procedure TestMigrateVATProdPostingGroups_FromCsv_MatchesExpected()
    var
        BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        TempExpected: Record "VAT Product Posting Group" temporary;
        Migrator: Codeunit "BC14 VATProd PG Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp VATProdPG";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetVATProdPostingGroups();
        BC14TestHelper.ClearBC14VATProdPostingGroupBuffer();
        BC14TestHelper.ImportBC14VATProdPGData();

        if BC14VATProdPostingGroup.FindSet() then
            repeat
                Migrator.MigrateVATProdPostingGroup(BC14VATProdPostingGroup);
            until BC14VATProdPostingGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/VATProdPG.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedVATProdPostingGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), VATProdPostingGroup.Count(), StrSubstNo(CountMismatchLbl, 'VAT Product Posting Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(VATProdPostingGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'VAT Product Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, VATProdPostingGroup.Description, Mismatch('Description', 'VAT Product Posting Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Customer Discount Group
    // ====================================================================

    [Test]
    procedure TestMigrateCustomerDiscountGroups_FromCsv_MatchesExpected()
    var
        BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group";
        CustomerDiscountGroup: Record "Customer Discount Group";
        TempExpected: Record "Customer Discount Group" temporary;
        Migrator: Codeunit "BC14 Cust. Disc. Grp. Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp CustDiscGrp";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetCustomerDiscountGroups();
        BC14TestHelper.ClearBC14CustomerDiscountGroupBuffer();
        BC14TestHelper.ImportBC14CustDiscGrpData();

        if BC14CustomerDiscountGroup.FindSet() then
            repeat
                Migrator.MigrateCustomerDiscountGroup(BC14CustomerDiscountGroup);
            until BC14CustomerDiscountGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/CustDiscGrp.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedCustomerDiscountGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), CustomerDiscountGroup.Count(), StrSubstNo(CountMismatchLbl, 'Customer Discount Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(CustomerDiscountGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Customer Discount Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, CustomerDiscountGroup.Description, Mismatch('Description', 'Customer Discount Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Customer Price Group
    // ====================================================================

    [Test]
    procedure TestMigrateCustomerPriceGroups_FromCsv_MatchesExpected()
    var
        BC14CustomerPriceGroup: Record "BC14 Cust. Price Group";
        CustomerPriceGroup: Record "Customer Price Group";
        TempExpected: Record "Customer Price Group" temporary;
        Migrator: Codeunit "BC14 Cust. Price Grp. Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp CustPriceGrp";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetCustomerPriceGroups();
        BC14TestHelper.ClearBC14CustomerPriceGroupBuffer();
        BC14TestHelper.ImportBC14CustPriceGrpData();

        if BC14CustomerPriceGroup.FindSet() then
            repeat
                Migrator.MigrateCustomerPriceGroup(BC14CustomerPriceGroup);
            until BC14CustomerPriceGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/CustPriceGrp.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedCustomerPriceGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), CustomerPriceGroup.Count(), StrSubstNo(CountMismatchLbl, 'Customer Price Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(CustomerPriceGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Customer Price Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, CustomerPriceGroup.Description, Mismatch('Description', 'Customer Price Group', TempExpected.Code));
            Assert.AreEqual(TempExpected."Allow Invoice Disc.", CustomerPriceGroup."Allow Invoice Disc.", Mismatch('Allow Invoice Disc.', 'Customer Price Group', TempExpected.Code));
            Assert.AreEqual(TempExpected."Allow Line Disc.", CustomerPriceGroup."Allow Line Disc.", Mismatch('Allow Line Disc.', 'Customer Price Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Item Discount Group
    // ====================================================================

    [Test]
    procedure TestMigrateItemDiscountGroups_FromCsv_MatchesExpected()
    var
        BC14ItemDiscountGroup: Record "BC14 Item Discount Group";
        ItemDiscountGroup: Record "Item Discount Group";
        TempExpected: Record "Item Discount Group" temporary;
        Migrator: Codeunit "BC14 Item Disc. Grp. Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp ItemDiscGrp";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetItemDiscountGroups();
        BC14TestHelper.ClearBC14ItemDiscountGroupBuffer();
        BC14TestHelper.ImportBC14ItemDiscGrpData();

        if BC14ItemDiscountGroup.FindSet() then
            repeat
                Migrator.MigrateItemDiscountGroup(BC14ItemDiscountGroup);
            until BC14ItemDiscountGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/ItemDiscGrp.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedItemDiscountGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), ItemDiscountGroup.Count(), StrSubstNo(CountMismatchLbl, 'Item Discount Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(ItemDiscountGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Item Discount Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, ItemDiscountGroup.Description, Mismatch('Description', 'Item Discount Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Item Category
    // ====================================================================

    [Test]
    procedure TestMigrateItemCategories_FromCsv_MatchesExpected()
    var
        BC14ItemCategory: Record "BC14 Item Category";
        ItemCategory: Record "Item Category";
        TempExpected: Record "Item Category" temporary;
        Migrator: Codeunit "BC14 Item Category Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp ItemCategory";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetItemCategories();
        BC14TestHelper.ClearBC14ItemCategoryBuffer();
        BC14TestHelper.ImportBC14ItemCategoryData();

        if BC14ItemCategory.FindSet() then
            repeat
                Migrator.MigrateItemCategory(BC14ItemCategory);
            until BC14ItemCategory.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/ItemCategory.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedItemCategories(TempExpected);

        Assert.AreEqual(TempExpected.Count(), ItemCategory.Count(), StrSubstNo(CountMismatchLbl, 'Item Categories'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(ItemCategory.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Item Category', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, ItemCategory.Description, Mismatch('Description', 'Item Category', TempExpected.Code));
            Assert.AreEqual(TempExpected."Presentation Order", ItemCategory."Presentation Order", Mismatch('Presentation Order', 'Item Category', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Inventory Posting Group
    // ====================================================================

    [Test]
    procedure TestMigrateInventoryPostingGroups_FromCsv_MatchesExpected()
    var
        BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        TempExpected: Record "Inventory Posting Group" temporary;
        Migrator: Codeunit "BC14 Inv. Post. Group Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp InvPostGroup";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetInventoryPostingGroups();
        BC14TestHelper.ClearBC14InventoryPostingGroupBuffer();
        BC14TestHelper.ImportBC14InvPostGroupData();

        if BC14InventoryPostingGroup.FindSet() then
            repeat
                Migrator.MigrateInventoryPostingGroup(BC14InventoryPostingGroup);
            until BC14InventoryPostingGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/InvPostGroup.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedInventoryPostingGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), InventoryPostingGroup.Count(), StrSubstNo(CountMismatchLbl, 'Inventory Posting Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(InventoryPostingGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Inventory Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, InventoryPostingGroup.Description, Mismatch('Description', 'Inventory Posting Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Reminder Terms
    // ====================================================================

    [Test]
    procedure TestMigrateReminderTerms_FromCsv_MatchesExpected()
    var
        BC14ReminderTerms: Record "BC14 Reminder Terms";
        ReminderTerms: Record "Reminder Terms";
        TempExpected: Record "Reminder Terms" temporary;
        Migrator: Codeunit "BC14 Reminder Terms Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp ReminderTerms";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetReminderTerms();
        BC14TestHelper.ClearBC14ReminderTermsBuffer();
        BC14TestHelper.ImportBC14ReminderTermsData();

        if BC14ReminderTerms.FindSet() then
            repeat
                Migrator.MigrateReminderTerms(BC14ReminderTerms);
            until BC14ReminderTerms.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/ReminderTerms.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedReminderTerms(TempExpected);

        Assert.AreEqual(TempExpected.Count(), ReminderTerms.Count(), StrSubstNo(CountMismatchLbl, 'Reminder Terms'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(ReminderTerms.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Reminder Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, ReminderTerms.Description, Mismatch('Description', 'Reminder Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected."Max. No. of Reminders", ReminderTerms."Max. No. of Reminders", Mismatch('Max. No. of Reminders', 'Reminder Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected."Post Interest", ReminderTerms."Post Interest", Mismatch('Post Interest', 'Reminder Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected."Minimum Amount (LCY)", ReminderTerms."Minimum Amount (LCY)", Mismatch('Minimum Amount (LCY)', 'Reminder Terms', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Customer Posting Group
    // ====================================================================

    [Test]
    procedure TestMigrateCustomerPostingGroups_FromCsv_MatchesExpected()
    var
        BC14CustomerPostingGroup: Record "BC14 Customer Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        TempExpected: Record "Customer Posting Group" temporary;
        Migrator: Codeunit "BC14 Cust. Post. Grp. Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp CustPostGrp";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetCustomerPostingGroups();
        BC14TestHelper.ClearBC14CustomerPostingGroupBuffer();
        BC14TestHelper.ImportBC14CustPostGrpData();

        if BC14CustomerPostingGroup.FindSet() then
            repeat
                Migrator.MigrateCustomerPostingGroup(BC14CustomerPostingGroup);
            until BC14CustomerPostingGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/CustPostGrp.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedCustomerPostingGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), CustomerPostingGroup.Count(), StrSubstNo(CountMismatchLbl, 'Customer Posting Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(CustomerPostingGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Customer Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, CustomerPostingGroup.Description, Mismatch('Description', 'Customer Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected."Receivables Account", CustomerPostingGroup."Receivables Account", Mismatch('Receivables Account', 'Customer Posting Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Vendor Posting Group
    // ====================================================================

    [Test]
    procedure TestMigrateVendorPostingGroups_FromCsv_MatchesExpected()
    var
        BC14VendorPostingGroup: Record "BC14 Vendor Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        TempExpected: Record "Vendor Posting Group" temporary;
        Migrator: Codeunit "BC14 Vend. Post. Grp. Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp VendPostGrp";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetVendorPostingGroups();
        BC14TestHelper.ClearBC14VendorPostingGroupBuffer();
        BC14TestHelper.ImportBC14VendPostGrpData();

        if BC14VendorPostingGroup.FindSet() then
            repeat
                Migrator.MigrateVendorPostingGroup(BC14VendorPostingGroup);
            until BC14VendorPostingGroup.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/VendPostGrp.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedVendorPostingGroups(TempExpected);

        Assert.AreEqual(TempExpected.Count(), VendorPostingGroup.Count(), StrSubstNo(CountMismatchLbl, 'Vendor Posting Groups'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(VendorPostingGroup.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Vendor Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, VendorPostingGroup.Description, Mismatch('Description', 'Vendor Posting Group', TempExpected.Code));
            Assert.AreEqual(TempExpected."Payables Account", VendorPostingGroup."Payables Account", Mismatch('Payables Account', 'Vendor Posting Group', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Item Attribute
    // ====================================================================

    [Test]
    procedure TestMigrateItemAttributes_FromCsv_MatchesExpected()
    var
        BC14ItemAttribute: Record "BC14 Item Attribute";
        ItemAttribute: Record "Item Attribute";
        TempExpected: Record "Item Attribute" temporary;
        Migrator: Codeunit "BC14 Item Attribute Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp ItemAttribute";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetItemAttributes();
        BC14TestHelper.ClearBC14ItemAttributeBuffer();
        BC14TestHelper.ImportBC14ItemAttributeData();

        if BC14ItemAttribute.FindSet() then
            repeat
                Migrator.MigrateItemAttribute(BC14ItemAttribute);
            until BC14ItemAttribute.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/ItemAttribute.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedItemAttributes(TempExpected);

        Assert.AreEqual(TempExpected.Count(), ItemAttribute.Count(), StrSubstNo(CountMismatchLbl, 'Item Attributes'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(ItemAttribute.Get(TempExpected.ID), StrSubstNo(RecordNotFoundLbl, 'Item Attribute', Format(TempExpected.ID)));
            Assert.AreEqual(TempExpected.Name, ItemAttribute.Name, Mismatch('Name', 'Item Attribute', Format(TempExpected.ID)));
            Assert.AreEqual(TempExpected.Type, ItemAttribute.Type, Mismatch('Type', 'Item Attribute', Format(TempExpected.ID)));
            Assert.AreEqual(TempExpected.Blocked, ItemAttribute.Blocked, Mismatch('Blocked', 'Item Attribute', Format(TempExpected.ID)));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // No. Series
    // ====================================================================

    [Test]
    procedure TestMigrateNoSeries_FromCsv_MatchesExpected()
    var
        BC14NoSeries: Record "BC14 No. Series";
        NoSeries: Record "No. Series";
        TempExpected: Record "No. Series" temporary;
        Migrator: Codeunit "BC14 No. Series Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp NoSeries";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetNoSeries();
        BC14TestHelper.ClearBC14NoSeriesBuffer();
        BC14TestHelper.ImportBC14NoSeriesData();

        if BC14NoSeries.FindSet() then
            repeat
                Migrator.MigrateNoSeries(BC14NoSeries);
            until BC14NoSeries.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/NoSeries.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedNoSeries(TempExpected);

        Assert.AreEqual(TempExpected.Count(), NoSeries.Count(), StrSubstNo(CountMismatchLbl, 'No. Series'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(NoSeries.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'No. Series', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, NoSeries.Description, Mismatch('Description', 'No. Series', TempExpected.Code));
            Assert.AreEqual(TempExpected."Default Nos.", NoSeries."Default Nos.", Mismatch('Default Nos.', 'No. Series', TempExpected.Code));
            Assert.AreEqual(TempExpected."Manual Nos.", NoSeries."Manual Nos.", Mismatch('Manual Nos.', 'No. Series', TempExpected.Code));
            Assert.AreEqual(TempExpected."Date Order", NoSeries."Date Order", Mismatch('Date Order', 'No. Series', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Dimension
    // ====================================================================

    [Test]
    procedure TestMigrateDimensions_FromCsv_MatchesExpected()
    var
        BC14Dimension: Record "BC14 Dimension";
        Dimension: Record Dimension;
        TempExpected: Record Dimension temporary;
        Migrator: Codeunit "BC14 Dimension Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Dimension";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetDimensions();
        BC14TestHelper.ClearBC14DimensionBuffer();
        BC14TestHelper.ImportBC14DimensionData();

        if BC14Dimension.FindSet() then
            repeat
                Migrator.MigrateDimension(BC14Dimension);
            until BC14Dimension.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/Dimension.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedDimensions(TempExpected);

        Assert.AreEqual(TempExpected.Count(), Dimension.Count(), StrSubstNo(CountMismatchLbl, 'Dimensions'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(Dimension.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Dimension', TempExpected.Code));
            Assert.AreEqual(TempExpected.Name, Dimension.Name, Mismatch('Name', 'Dimension', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, Dimension.Description, Mismatch('Description', 'Dimension', TempExpected.Code));
            Assert.AreEqual(TempExpected.Blocked, Dimension.Blocked, Mismatch('Blocked', 'Dimension', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Payment Terms
    // ====================================================================

    [Test]
    procedure TestMigratePaymentTerms_FromCsv_MatchesExpected()
    var
        BC14PaymentTerms: Record "BC14 Pmt. Terms";
        PaymentTerms: Record "Payment Terms";
        TempExpected: Record "Payment Terms" temporary;
        BC14PaymentTermsMigrator: Codeunit "BC14 Payment Terms Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Payment Terms";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetPaymentTerms();
        BC14TestHelper.ClearBC14PaymentTermsBuffer();
        BC14TestHelper.ImportBC14PaymentTermsData();

        if BC14PaymentTerms.FindSet() then
            repeat
                BC14PaymentTermsMigrator.MigratePaymentTerms(BC14PaymentTerms);
            until BC14PaymentTerms.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/PaymentTerms.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedPaymentTerms(TempExpected);

        Assert.AreEqual(TempExpected.Count(), PaymentTerms.Count(), StrSubstNo(CountMismatchLbl, 'Payment Terms'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(PaymentTerms.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Payment Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected."Due Date Calculation", PaymentTerms."Due Date Calculation", Mismatch('Due Date Calculation', 'Payment Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected."Discount Date Calculation", PaymentTerms."Discount Date Calculation", Mismatch('Discount Date Calculation', 'Payment Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected."Discount %", PaymentTerms."Discount %", Mismatch('Discount %', 'Payment Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, PaymentTerms.Description, Mismatch('Description', 'Payment Terms', TempExpected.Code));
            Assert.AreEqual(TempExpected."Calc. Pmt. Disc. on Cr. Memos", PaymentTerms."Calc. Pmt. Disc. on Cr. Memos", Mismatch('Calc. Pmt. Disc. on Cr. Memos', 'Payment Terms', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Currency
    // ====================================================================

    [Test]
    procedure TestMigrateCurrencies_FromCsv_MatchesExpected()
    var
        BC14Currency: Record "BC14 Currency";
        Currency: Record Currency;
        TempExpected: Record Currency temporary;
        BC14CurrencyMigrator: Codeunit "BC14 Currency Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Currency";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetCurrencies();
        BC14TestHelper.ClearBC14CurrencyBuffer();
        BC14TestHelper.ImportBC14CurrencyData();

        if BC14Currency.FindSet() then
            repeat
                BC14CurrencyMigrator.MigrateCurrency(BC14Currency);
            until BC14Currency.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/Currency.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedCurrencies(TempExpected);

        Assert.AreEqual(TempExpected.Count(), Currency.Count(), StrSubstNo(CountMismatchLbl, 'Currencies'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(Currency.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Currency', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, Currency.Description, Mismatch('Description', 'Currency', TempExpected.Code));
            Assert.AreEqual(TempExpected."Unrealized Gains Acc.", Currency."Unrealized Gains Acc.", Mismatch('Unrealized Gains Acc.', 'Currency', TempExpected.Code));
            Assert.AreEqual(TempExpected."Realized Gains Acc.", Currency."Realized Gains Acc.", Mismatch('Realized Gains Acc.', 'Currency', TempExpected.Code));
            Assert.AreEqual(TempExpected."Unrealized Losses Acc.", Currency."Unrealized Losses Acc.", Mismatch('Unrealized Losses Acc.', 'Currency', TempExpected.Code));
            Assert.AreEqual(TempExpected."Realized Losses Acc.", Currency."Realized Losses Acc.", Mismatch('Realized Losses Acc.', 'Currency', TempExpected.Code));
            Assert.AreEqual(TempExpected.Symbol, Currency.Symbol, Mismatch('Symbol', 'Currency', TempExpected.Code));
            Assert.AreEqual(TempExpected."ISO Code", Currency."ISO Code", Mismatch('ISO Code', 'Currency', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Unit of Measure
    // ====================================================================

    [Test]
    procedure TestMigrateUnitsOfMeasure_FromCsv_MatchesExpected()
    var
        BC14UnitOfMeasure: Record "BC14 Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        TempExpected: Record "Unit of Measure" temporary;
        BC14UnitOfMeasureMigrator: Codeunit "BC14 Unit of Measure Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Unit of Measure";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetUnitsOfMeasure();
        BC14TestHelper.ClearBC14UnitOfMeasureBuffer();
        BC14TestHelper.ImportBC14UnitOfMeasureData();

        if BC14UnitOfMeasure.FindSet() then
            repeat
                BC14UnitOfMeasureMigrator.MigrateUnitOfMeasure(BC14UnitOfMeasure);
            until BC14UnitOfMeasure.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/UnitOfMeasure.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedUnitsOfMeasure(TempExpected);

        Assert.AreEqual(TempExpected.Count(), UnitOfMeasure.Count(), StrSubstNo(CountMismatchLbl, 'Units of Measure'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(UnitOfMeasure.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Unit of Measure', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, UnitOfMeasure.Description, Mismatch('Description', 'Unit of Measure', TempExpected.Code));
            Assert.AreEqual(TempExpected."International Standard Code", UnitOfMeasure."International Standard Code", Mismatch('International Standard Code', 'Unit of Measure', TempExpected.Code));
            Assert.AreEqual(TempExpected.Symbol, UnitOfMeasure.Symbol, Mismatch('Symbol', 'Unit of Measure', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Shipment Method
    // ====================================================================

    [Test]
    procedure TestMigrateShipmentMethods_FromCsv_MatchesExpected()
    var
        BC14ShipmentMethod: Record "BC14 Shipment Method";
        ShipmentMethod: Record "Shipment Method";
        TempExpected: Record "Shipment Method" temporary;
        BC14ShipmentMethodMigrator: Codeunit "BC14 Shipment Method Migrator";
        ExpectedXmlPort: XmlPort "BC14 Exp Shipment Method";
        ExpectedIns: InStream;
    begin
        BC14TestHelper.ClearTargetShipmentMethods();
        BC14TestHelper.ClearBC14ShipmentMethodBuffer();
        BC14TestHelper.ImportBC14ShipmentMethodData();

        if BC14ShipmentMethod.FindSet() then
            repeat
                BC14ShipmentMethodMigrator.MigrateShipmentMethod(BC14ShipmentMethod);
            until BC14ShipmentMethod.Next() = 0;

        BC14TestHelper.GetInputStream('datasets/results/ShipmentMethod.csv', ExpectedIns);
        ExpectedXmlPort.SetSource(ExpectedIns);
        ExpectedXmlPort.Import();
        ExpectedXmlPort.GetExpectedShipmentMethods(TempExpected);

        Assert.AreEqual(TempExpected.Count(), ShipmentMethod.Count(), StrSubstNo(CountMismatchLbl, 'Shipment Methods'));

        TempExpected.FindSet();
        repeat
            Assert.IsTrue(ShipmentMethod.Get(TempExpected.Code), StrSubstNo(RecordNotFoundLbl, 'Shipment Method', TempExpected.Code));
            Assert.AreEqual(TempExpected.Description, ShipmentMethod.Description, Mismatch('Description', 'Shipment Method', TempExpected.Code));
        until TempExpected.Next() = 0;
    end;

    // ====================================================================
    // Helpers
    // ====================================================================

    local procedure Mismatch(FieldName: Text; EntityName: Text; KeyTxt: Text): Text
    begin
        exit(StrSubstNo(FieldMismatchLbl, FieldName, EntityName, KeyTxt));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure IbanConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // The Bank Account IBAN OnValidate trigger raises a confirm when the IBAN
        // does not match the strict checksum/format. The synthetic test IBANs are
        // deliberately not real, so accept the confirm to allow the migration to
        // proceed without changing the source data.
        Reply := true;
    end;
}
