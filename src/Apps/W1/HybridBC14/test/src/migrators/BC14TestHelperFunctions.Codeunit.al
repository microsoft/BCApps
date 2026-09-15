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
/// Shared helpers for CSV-driven BC14 migrator tests. Mirrors the pattern used by
/// the HybridSL test suite: CSV files under .resources/datasets/{input,results}
/// are loaded into buffer / target tables via XmlPorts.
/// </summary>
codeunit 148911 "BC14 Test Helper Functions"
{
    procedure GetInputStream(ResourcePath: Text; var ResInstream: InStream)
    begin
        NavApp.GetResource(ResourcePath, ResInstream);
    end;

    // --- Cleanup helpers -------------------------------------------------

    procedure ClearBC14CustomerBuffer()
    var
        BC14Customer: Record "BC14 Customer";
    begin
        BC14Customer.DeleteAll();
    end;

    procedure ClearTargetCustomers()
    var
        Customer: Record Customer;
    begin
        Customer.DeleteAll();
    end;

    procedure ClearBC14VendorBuffer()
    var
        BC14Vendor: Record "BC14 Vendor";
    begin
        BC14Vendor.DeleteAll();
    end;

    procedure ClearTargetVendors()
    var
        Vendor: Record Vendor;
    begin
        Vendor.DeleteAll();
    end;

    procedure ClearBC14ItemBuffer()
    var
        BC14Item: Record "BC14 Item";
    begin
        BC14Item.DeleteAll();
    end;

    procedure ClearTargetItems()
    var
        Item: Record Item;
    begin
        Item.DeleteAll();
    end;

    procedure ClearBC14GLAccountBuffer()
    var
        BC14GLAccount: Record "BC14 G/L Account";
    begin
        BC14GLAccount.DeleteAll();
    end;

    procedure ClearTargetGLAccounts()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.DeleteAll();
    end;

    procedure ClearBC14CustomerBankAccountBuffer()
    var
        BC14CustomerBankAccount: Record "BC14 Customer Bank Account";
    begin
        BC14CustomerBankAccount.DeleteAll();
    end;

    procedure ClearTargetCustomerBankAccounts()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.DeleteAll();
    end;

    procedure ClearBC14VendorBankAccountBuffer()
    var
        BC14VendorBankAccount: Record "BC14 Vendor Bank Account";
    begin
        BC14VendorBankAccount.DeleteAll();
    end;

    procedure ClearTargetVendorBankAccounts()
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.DeleteAll();
    end;

    procedure ClearBC14ShipToAddressBuffer()
    var
        BC14ShipToAddress: Record "BC14 Ship-to Address";
    begin
        BC14ShipToAddress.DeleteAll();
    end;

    procedure ClearTargetShipToAddresses()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        ShipToAddress.DeleteAll();
    end;

    procedure ClearBC14BOMComponentBuffer()
    var
        BC14BOMComponent: Record "BC14 BOM Component";
    begin
        BC14BOMComponent.DeleteAll();
    end;

    procedure ClearTargetBOMComponents()
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.DeleteAll();
    end;

    procedure ClearBC14CountryRegionBuffer()
    var
        BC14CountryRegion: Record "BC14 Country/Region";
    begin
        BC14CountryRegion.DeleteAll();
    end;

    procedure ClearTargetCountryRegions()
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.DeleteAll();
    end;

    procedure ClearBC14LanguageBuffer()
    var
        BC14Language: Record "BC14 Language";
    begin
        BC14Language.DeleteAll();
    end;

    procedure ClearTargetLanguages()
    var
        Language: Record Language;
    begin
        Language.DeleteAll();
    end;

    procedure ClearBC14TerritoryBuffer()
    var
        BC14Territory: Record "BC14 Territory";
    begin
        BC14Territory.DeleteAll();
    end;

    procedure ClearTargetTerritories()
    var
        Territory: Record Territory;
    begin
        Territory.DeleteAll();
    end;

    procedure ClearBC14SourceCodeBuffer()
    var
        BC14SourceCode: Record "BC14 Source Code";
    begin
        BC14SourceCode.DeleteAll();
    end;

    procedure ClearTargetSourceCodes()
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.DeleteAll();
    end;

    procedure ClearBC14ReasonCodeBuffer()
    var
        BC14ReasonCode: Record "BC14 Reason Code";
    begin
        BC14ReasonCode.DeleteAll();
    end;

    procedure ClearTargetReasonCodes()
    var
        ReasonCode: Record "Reason Code";
    begin
        ReasonCode.DeleteAll();
    end;

    procedure ClearBC14PostCodeBuffer()
    var
        BC14PostCode: Record "BC14 Post Code";
    begin
        BC14PostCode.DeleteAll();
    end;

    procedure ClearTargetPostCodes()
    var
        PostCode: Record "Post Code";
    begin
        PostCode.DeleteAll();
    end;

    procedure ClearBC14TariffNumberBuffer()
    var
        BC14TariffNumber: Record "BC14 Tariff Number";
    begin
        BC14TariffNumber.DeleteAll();
    end;

    procedure ClearTargetTariffNumbers()
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.DeleteAll();
    end;

    procedure ClearBC14PaymentMethodBuffer()
    var
        BC14PaymentMethod: Record "BC14 Payment Method";
    begin
        BC14PaymentMethod.DeleteAll();
    end;

    procedure ClearTargetPaymentMethods()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.DeleteAll();
    end;

    procedure ClearBC14GenBusPostingGroupBuffer()
    var
        BC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group";
    begin
        BC14GenBusPostingGroup.DeleteAll();
    end;

    procedure ClearTargetGenBusPostingGroups()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        GenBusPostingGroup.DeleteAll();
    end;

    procedure ClearBC14GenProdPostingGroupBuffer()
    var
        BC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group";
    begin
        BC14GenProdPostingGroup.DeleteAll();
    end;

    procedure ClearTargetGenProdPostingGroups()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProdPostingGroup.DeleteAll();
    end;

    procedure ClearBC14VATBusPostingGroupBuffer()
    var
        BC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group";
    begin
        BC14VATBusPostingGroup.DeleteAll();
    end;

    procedure ClearTargetVATBusPostingGroups()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusPostingGroup.DeleteAll();
    end;

    procedure ClearBC14VATProdPostingGroupBuffer()
    var
        BC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group";
    begin
        BC14VATProdPostingGroup.DeleteAll();
    end;

    procedure ClearTargetVATProdPostingGroups()
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProdPostingGroup.DeleteAll();
    end;

    procedure ClearBC14CustomerDiscountGroupBuffer()
    var
        BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group";
    begin
        BC14CustomerDiscountGroup.DeleteAll();
    end;

    procedure ClearTargetCustomerDiscountGroups()
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        CustomerDiscountGroup.DeleteAll();
    end;

    procedure ClearBC14CustomerPriceGroupBuffer()
    var
        BC14CustomerPriceGroup: Record "BC14 Cust. Price Group";
    begin
        BC14CustomerPriceGroup.DeleteAll();
    end;

    procedure ClearTargetCustomerPriceGroups()
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        CustomerPriceGroup.DeleteAll();
    end;

    procedure ClearBC14ItemDiscountGroupBuffer()
    var
        BC14ItemDiscountGroup: Record "BC14 Item Discount Group";
    begin
        BC14ItemDiscountGroup.DeleteAll();
    end;

    procedure ClearTargetItemDiscountGroups()
    var
        ItemDiscountGroup: Record "Item Discount Group";
    begin
        ItemDiscountGroup.DeleteAll();
    end;

    procedure ClearBC14ItemCategoryBuffer()
    var
        BC14ItemCategory: Record "BC14 Item Category";
    begin
        BC14ItemCategory.DeleteAll();
    end;

    procedure ClearTargetItemCategories()
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.DeleteAll();
    end;

    procedure ClearBC14InventoryPostingGroupBuffer()
    var
        BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group";
    begin
        BC14InventoryPostingGroup.DeleteAll();
    end;

    procedure ClearTargetInventoryPostingGroups()
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        InventoryPostingGroup.DeleteAll();
    end;

    procedure ClearBC14ReminderTermsBuffer()
    var
        BC14ReminderTerms: Record "BC14 Reminder Terms";
    begin
        BC14ReminderTerms.DeleteAll();
    end;

    procedure ClearTargetReminderTerms()
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.DeleteAll();
    end;

    procedure ClearBC14CustomerPostingGroupBuffer()
    var
        BC14CustomerPostingGroup: Record "BC14 Customer Posting Group";
    begin
        BC14CustomerPostingGroup.DeleteAll();
    end;

    procedure ClearTargetCustomerPostingGroups()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.DeleteAll();
    end;

    procedure ClearBC14VendorPostingGroupBuffer()
    var
        BC14VendorPostingGroup: Record "BC14 Vendor Posting Group";
    begin
        BC14VendorPostingGroup.DeleteAll();
    end;

    procedure ClearTargetVendorPostingGroups()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.DeleteAll();
    end;

    procedure ClearBC14ItemAttributeBuffer()
    var
        BC14ItemAttribute: Record "BC14 Item Attribute";
    begin
        BC14ItemAttribute.DeleteAll();
    end;

    procedure ClearTargetItemAttributes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.DeleteAll();
    end;

    procedure ClearBC14NoSeriesBuffer()
    var
        BC14NoSeries: Record "BC14 No. Series";
    begin
        BC14NoSeries.DeleteAll();
    end;

    procedure ClearTargetNoSeries()
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.DeleteAll();
    end;

    procedure ClearBC14DimensionBuffer()
    var
        BC14Dimension: Record "BC14 Dimension";
    begin
        BC14Dimension.DeleteAll();
    end;

    procedure ClearTargetDimensions()
    var
        Dimension: Record Dimension;
    begin
        Dimension.DeleteAll();
    end;

    procedure ClearBC14PaymentTermsBuffer()
    var
        BC14PaymentTerms: Record "BC14 Pmt. Terms";
    begin
        BC14PaymentTerms.DeleteAll();
    end;

    procedure ClearTargetPaymentTerms()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.DeleteAll();
    end;

    procedure ClearBC14CurrencyBuffer()
    var
        BC14Currency: Record "BC14 Currency";
    begin
        BC14Currency.DeleteAll();
    end;

    procedure ClearTargetCurrencies()
    var
        Currency: Record Currency;
    begin
        Currency.DeleteAll();
    end;

    procedure ClearBC14UnitOfMeasureBuffer()
    var
        BC14UnitOfMeasure: Record "BC14 Unit of Measure";
    begin
        BC14UnitOfMeasure.DeleteAll();
    end;

    procedure ClearTargetUnitsOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.DeleteAll();
    end;

    procedure ClearBC14ShipmentMethodBuffer()
    var
        BC14ShipmentMethod: Record "BC14 Shipment Method";
    begin
        BC14ShipmentMethod.DeleteAll();
    end;

    procedure ClearTargetShipmentMethods()
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.DeleteAll();
    end;

    // --- Import helpers --------------------------------------------------

    procedure ImportBC14CustomerData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14Customer.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Customer Data", Ins);
    end;

    procedure ImportBC14VendorData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14Vendor.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Vendor Data", Ins);
    end;

    procedure ImportBC14ItemData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14Item.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Item Data", Ins);
    end;

    procedure ImportBC14GLAccountData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14GLAccount.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 GL Account Data", Ins);
    end;

    procedure ImportBC14CustomerBankAccountData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14CustomerBankAccount.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Customer Bank Acct Data", Ins);
    end;

    procedure ImportBC14VendorBankAccountData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14VendorBankAccount.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Vendor Bank Acct Data", Ins);
    end;

    procedure ImportBC14ShipToAddressData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14ShipToAddress.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Ship-to Address Data", Ins);
    end;

    procedure ImportBC14BOMComponentData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14BOMComponent.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 BOM Component Data", Ins);
    end;

    procedure ImportBC14CountryRegionData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14CountryRegion.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Country/Region Data", Ins);
    end;

    procedure ImportBC14LanguageData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14Language.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Language Data", Ins);
    end;

    procedure ImportBC14TerritoryData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14Territory.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Territory Data", Ins);
    end;

    procedure ImportBC14SourceCodeData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14SourceCode.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Source Code Data", Ins);
    end;

    procedure ImportBC14ReasonCodeData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14ReasonCode.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Reason Code Data", Ins);
    end;

    procedure ImportBC14TariffNumberData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14TariffNumber.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Tariff Number Data", Ins);
    end;

    procedure ImportBC14PaymentMethodData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14PaymentMethod.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Payment Method Data", Ins);
    end;

    procedure ImportBC14GenBusPGData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14GenBusPG.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 GenBusPG Data", Ins);
    end;

    procedure ImportBC14GenProdPGData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14GenProdPG.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 GenProdPG Data", Ins);
    end;

    procedure ImportBC14VATBusPGData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14VATBusPG.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 VATBusPG Data", Ins);
    end;

    procedure ImportBC14VATProdPGData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14VATProdPG.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 VATProdPG Data", Ins);
    end;

    procedure ImportBC14CustDiscGrpData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14CustDiscGrp.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 CustDiscGrp Data", Ins);
    end;

    procedure ImportBC14CustPriceGrpData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14CustPriceGrp.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 CustPriceGrp Data", Ins);
    end;

    procedure ImportBC14ItemDiscGrpData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14ItemDiscGrp.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 ItemDiscGrp Data", Ins);
    end;

    procedure ImportBC14ItemCategoryData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14ItemCategory.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 ItemCategory Data", Ins);
    end;

    procedure ImportBC14InvPostGroupData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14InvPostGroup.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 InvPostGroup Data", Ins);
    end;

    procedure ImportBC14ReminderTermsData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14ReminderTerms.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 ReminderTerms Data", Ins);
    end;

    procedure ImportBC14CustPostGrpData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14CustPostGrp.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 CustPostGrp Data", Ins);
    end;

    procedure ImportBC14VendPostGrpData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14VendPostGrp.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 VendPostGrp Data", Ins);
    end;

    procedure ImportBC14ItemAttributeData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14ItemAttribute.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 ItemAttribute Data", Ins);
    end;

    procedure ImportBC14NoSeriesData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14NoSeries.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 NoSeries Data", Ins);
    end;

    procedure ImportBC14DimensionData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14Dimension.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Dimension Data", Ins);
    end;

    procedure ImportBC14PaymentTermsData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14PaymentTerms.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Payment Terms Data", Ins);
    end;

    procedure ImportBC14CurrencyData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14Currency.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Currency Data", Ins);
    end;

    procedure ImportBC14UnitOfMeasureData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14UnitOfMeasure.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Unit of Measure Data", Ins);
    end;

    procedure ImportBC14ShipmentMethodData()
    var
        Ins: InStream;
    begin
        GetInputStream('datasets/input/BC14ShipmentMethod.csv', Ins);
        Xmlport.Import(Xmlport::"BC14 Shipment Method Data", Ins);
    end;

    // --- Test reference-data setup helpers ------------------------------
    // These helpers seed minimal lookup data required by migrators that
    // call Validate() (which triggers TableRelation checks).

    /// <summary>
    /// Clears General Ledger Setup "LCY Code" so the Customer / Vendor migrators'
    /// ResolveCurrencyCode() does not blank source currency codes that happen to
    /// match this server's LCY.
    /// </summary>
    procedure ClearGLSetupLCYCode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup.Init();
            GeneralLedgerSetup.Insert();
        end;
        GeneralLedgerSetup."LCY Code" := '';
        GeneralLedgerSetup.Modify();
    end;

    /// <summary>
    /// Seeds the Gen. Product Posting Groups referenced by the Item test data
    /// (RETAIL, SERVICES, DIGITAL) so the Item migrator's Validate() call succeeds.
    /// </summary>
    procedure SeedGenProdPostingGroupsForItemTests()
    begin
        EnsureGenProdPostingGroup('RETAIL');
        EnsureGenProdPostingGroup('SERVICES');
        EnsureGenProdPostingGroup('DIGITAL');
    end;

    local procedure EnsureGenProdPostingGroup(GroupCode: Code[20])
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        if GenProdPostingGroup.Get(GroupCode) then
            exit;
        GenProdPostingGroup.Init();
        GenProdPostingGroup.Code := GroupCode;
        GenProdPostingGroup.Insert();
    end;

    /// <summary>
    /// Seeds the Inventory Posting Groups referenced by the Item test data (RESALE).
    /// </summary>
    procedure SeedInventoryPostingGroupsForItemTests()
    begin
        EnsureInventoryPostingGroup('RESALE');
    end;

    local procedure EnsureInventoryPostingGroup(GroupCode: Code[20])
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        if InventoryPostingGroup.Get(GroupCode) then
            exit;
        InventoryPostingGroup.Init();
        InventoryPostingGroup.Code := GroupCode;
        InventoryPostingGroup.Insert();
    end;

    /// <summary>
    /// Seeds the Units of Measure referenced by the BOM Component test data (HOUR).
    /// </summary>
    procedure SeedUnitsOfMeasureForBOMTests()
    begin
        EnsureUnitOfMeasure('HOUR');
    end;

    local procedure EnsureUnitOfMeasure(UomCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(UomCode) then
            exit;
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := UomCode;
        UnitOfMeasure.Insert();
    end;

    /// <summary>
    /// Seeds parent and component Items referenced by the BOM Component test data.
    /// The BOM Component migrator validates BOM Component."No." against the Item table.
    /// </summary>
    procedure SeedItemsForBOMTests()
    begin
        EnsureItem('I00001');
        EnsureItem('I00002');
        EnsureItem('I00003');
        EnsureItem('I00006');
        EnsureItem('I00008');
    end;

    local procedure EnsureItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit;
        Item.Init();
        Item."No." := ItemNo;
        Item.Insert();
    end;

    /// <summary>
    /// Seeds Currency records referenced by the Bank Account test data
    /// (USD, EUR, GBP, CAD). The Bank Account migrators use TransferFields and do
    /// not blank LCY-matching codes, so the Currency record must exist for the
    /// TableRelation to resolve.
    /// </summary>
    procedure SeedCurrenciesForBankAccountTests()
    begin
        EnsureCurrency('USD');
        EnsureCurrency('EUR');
        EnsureCurrency('GBP');
        EnsureCurrency('CAD');
    end;

    /// <summary>
    /// Seeds Country/Region records referenced by the Ship-to Address test data
    /// (US, GB, DE, CH). The Ship-to Address migrator validates Country/Region
    /// Code on TransferFields, so the record must exist for the TableRelation
    /// to resolve.
    /// </summary>
    procedure SeedCountriesForShipToAddressTests()
    begin
        EnsureCountryRegion('US');
        EnsureCountryRegion('GB');
        EnsureCountryRegion('DE');
        EnsureCountryRegion('CH');
    end;

    local procedure EnsureCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if Currency.Get(CurrencyCode) then
            exit;
        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency.Insert();
    end;

    local procedure EnsureCountryRegion(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryCode) then
            exit;
        CountryRegion.Init();
        CountryRegion.Code := CountryCode;
        CountryRegion.Insert();
    end;
}
