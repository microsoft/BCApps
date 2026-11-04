// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 139614 "Shpfy Alternative VAT Test"
{
    Access = Internal;
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        CurrentShop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        ScenarioGenProdPostingGroups: List of [Code[20]];
        ScenarioVATProdPostingGroups: List of [Code[20]];
        ExpectedAltGenBusPostingGroup: Boolean;
        ExpectedAltVATBusPostingGroup: Boolean;
        ExpectedAltVATRegistration: Boolean;
        ExpectedGenBusPostingGroup: Code[20];
        ExpectedVATBusPostingGroup: Code[20];
        ExpectedVATCountry: Code[10];
        ExpectedVATRegistrationNo: Text[20];
        IsInitialized: Boolean;
        ManualVATPromptShown: Boolean;

    [Test]
    [HandlerFunctions('FulfillmentOrdersHttpHandler')]
    procedure B2BInvoice_UsesBillToAlternativeForFinalDestination()
    var
        BillToCustomer: Record Customer;
        InterimShipToAddress: Record "Ship-to Address";
        OrderHeader: Record "Shpfy Order Header";
        SellToCustomer: Record Customer;
        Shop: Record "Shpfy Shop";
        VATCustomer: Record Customer;
        DestinationCountry: Code[10];
    begin
        // [Scenario #1] The selected bill-to customer and final ship-to country determine the VAT alternative.
        this.Initialize();

        // [Given] A B2B order has distinct customer and destination countries and a bill-to VAT alternative.
        this.CreateScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, true, true, true, false);

        // [When] The order is processed through the report entry point.
        this.ProcessOrderByReportEntryPoint(OrderHeader);

        // [Then] The invoice uses the bill-to alternative for the final destination.
        this.VerifyScenario(OrderHeader, SellToCustomer, BillToCustomer, true, true);
    end;

    [Test]
    [HandlerFunctions('FulfillmentOrdersHttpHandler,ManualVATConfirmPageHandler,RecreateSalesLinesConfirmHandler')]
    procedure ManualShipToCountry_UsesStandardConfirmationAfterOrderImport()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        BillToCustomer: Record Customer;
        CountryCustomerTemplate: Record "Customer Templ.";
        InterimShipToAddress: Record "Ship-to Address";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        SellToCustomer: Record Customer;
        Shop: Record "Shpfy Shop";
        VATCustomer: Record Customer;
        DestinationCountry: Code[10];
        ManualCountry: Code[10];
    begin
        // [Scenario #2] Manual country validation remains interactive after Shopify order creation.
        this.Initialize();

        // [Given] An imported order has an alternative VAT registration for a later manual destination.
        this.CreateManualVATScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, CountryCustomerTemplate, ManualCountry);

        // [When] The order is created and its ship-to country is subsequently changed manually.
        this.ProcessOrderThenManuallyChangeShipToCountry(SalesHeader, OrderHeader, ManualCountry, CountryCustomerTemplate, VATCustomer);

        // [Then] Standard confirmation appears and the manual destination alternative is applied.
        this.VerifyManualVATScenario(SalesHeader, AltCustVATReg, VATCustomer, ManualCountry);
    end;

    [Test]
    [HandlerFunctions('FulfillmentOrdersHttpHandler')]
    procedure AutoCreate_UsesOnlyEligibleCountryCustomerTemplate()
    var
        BillToCustomer: Record Customer;
        CountryCustomerTemplate: Record "Customer Templ.";
        OrderHeader: Record "Shpfy Order Header";
        SellToCustomer: Record Customer;
        VATCustomer: Record Customer;
        DestinationCountry: Code[10];
    begin
        // [Scenario #3] An enabled B2C preference creates an alternative from the destination country customer template.
        this.Initialize();

        // [Given] B2C auto-create is enabled and the country template supplies only a VAT business posting group.
        this.CreateAutoCreateCustomerTemplateScenario(OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry, CountryCustomerTemplate);

        // [When] The B2C order is processed.
        this.ProcessOrderManually(OrderHeader);

        // [Then] The alternative has blank registration and general posting group and the template VAT posting group.
        this.VerifyAutoCreatedCustomerTemplateScenario(OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry, CountryCustomerTemplate);
    end;

    [Test]
    [HandlerFunctions('FulfillmentOrdersHttpHandler')]
    procedure AutoCreate_B2B_UsesCompanyPreference()
    var
        BillToCustomer: Record Customer;
        CountryCustomerTemplate: Record "Customer Templ.";
        OrderHeader: Record "Shpfy Order Header";
        SellToCustomer: Record Customer;
        Shop: Record "Shpfy Shop";
        VATCustomer: Record Customer;
        DestinationCountry: Code[10];
    begin
        // [Scenario #4] B2B auto-creation follows the company preference, not the customer preference.
        this.Initialize();

        // [Given] A B2B order has an eligible country template and only company auto-create is enabled.
        this.CreateB2BAutoCreateScenario(Shop, OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry, CountryCustomerTemplate, true);

        // [When] The B2B order is processed.
        this.ProcessOrderManually(OrderHeader);

        // [Then] The document uses the template groups and the destination alternative is created.
        this.VerifyB2BAutoCreateUsesCompanyPreference(OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry, CountryCustomerTemplate);
    end;

    [Test]
    [HandlerFunctions('FulfillmentOrdersHttpHandler')]
    procedure AutoCreate_B2B_DoesNotUseCustomerPreference()
    var
        BillToCustomer: Record Customer;
        CountryCustomerTemplate: Record "Customer Templ.";
        OrderHeader: Record "Shpfy Order Header";
        SellToCustomer: Record Customer;
        Shop: Record "Shpfy Shop";
        VATCustomer: Record Customer;
        DestinationCountry: Code[10];
    begin
        // [Scenario #5] B2B auto-creation does not use the customer preference.
        this.Initialize();

        // [Given] A B2B order has an eligible destination-country template, but only customer auto-create is enabled.
        this.CreateB2BAutoCreateScenario(Shop, OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry, CountryCustomerTemplate, false);

        // [When] The B2B order is processed.
        this.ProcessOrderManually(OrderHeader);

        // [Then] No alternative is created and the document retains the VAT customer's baseline setup.
        this.VerifyB2BAutoCreateDoesNotUseCustomerPreference(OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry);
    end;

    [Test]
    [HandlerFunctions('FulfillmentOrdersHttpHandler')]
    procedure AutoCreate_PreservesExistingAlternative()
    var
        AltCustVATRegBefore: Record "Alt. Cust. VAT Reg.";
        BillToCustomer: Record Customer;
        CountryCustomerTemplate: Record "Customer Templ.";
        InterimShipToAddress: Record "Ship-to Address";
        OrderHeader: Record "Shpfy Order Header";
        SellToCustomer: Record Customer;
        Shop: Record "Shpfy Shop";
        VATCustomer: Record Customer;
        DestinationCountry: Code[10];
    begin
        // [Scenario #6] Existing alternative VAT setup is not overwritten by auto-create.
        this.Initialize();

        // [Given] Auto-create is enabled and an existing alternative differs from the country template.
        this.CreateExistingAlternativeScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, CountryCustomerTemplate, AltCustVATRegBefore);

        // [When] The order is processed.
        this.ProcessOrderManually(OrderHeader);

        // [Then] The existing alternative registration and posting groups remain unchanged.
        this.VerifyExistingAlternativeScenario(OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry, AltCustVATRegBefore, CountryCustomerTemplate);
    end;

    [Test]
    [HandlerFunctions('FulfillmentOrdersHttpHandler')]
    procedure RefundCreditMemo_UsesCurrentVATSetup()
    var
        BillToCustomer: Record Customer;
        PostedInvoice: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SellToCustomer: Record Customer;
        RefundId: BigInteger;
    begin
        // [Scenario #7] A refund credit memo uses the current alternative VAT setup.
        this.Initialize();

        // [Given] A refund refers to a posted invoice whose alternative VAT setup has since changed.
        RefundId := this.CreateCurrentSetupRefundScenario(PostedInvoice, SellToCustomer, BillToCustomer);

        // [When] The refund is processed as a credit memo.
        SalesHeader := this.CreateRefundCreditMemo(RefundId);

        // [Then] The credit memo uses current VAT values and the posted invoice remains unchanged.
        this.VerifyCurrentSetupRefund(SalesHeader, PostedInvoice, SellToCustomer, BillToCustomer);
    end;

    [Test]
    [HandlerFunctions('FulfillmentOrdersHttpHandler')]
    procedure AutoCreate_GenOnlyTemplate_PreservesCustomerVATGroup()
    var
        BillToCustomer: Record Customer;
        CountryCustomerTemplate: Record "Customer Templ.";
        OrderHeader: Record "Shpfy Order Header";
        SellToCustomer: Record Customer;
        VATCustomer: Record Customer;
        DestinationCountry: Code[10];
    begin
        // [Scenario #8] A general-only template must not copy its general posting group's default VAT group into the alternative.
        this.Initialize();

        // [Given] B2C auto-create uses a general-only template whose general group has a default VAT group.
        this.CreateGenOnlyAutoCreateScenario(OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry, CountryCustomerTemplate);

        // [When] The B2C order is processed.
        this.ProcessOrderManually(OrderHeader);

        // [Then] The alternative retains a blank VAT group and the document retains the customer's baseline VAT group.
        this.VerifyGenOnlyAutoCreateScenario(OrderHeader, SellToCustomer, BillToCustomer, VATCustomer, DestinationCountry, CountryCustomerTemplate);
    end;

    local procedure CreateGenOnlyAutoCreateScenario(var OrderHeader: Record "Shpfy Order Header"; var SellToCustomer: Record Customer; var BillToCustomer: Record Customer; var VATCustomer: Record Customer; var DestinationCountry: Code[10]; var CountryCustomerTemplate: Record "Customer Templ.")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        InterimShipToAddress: Record "Ship-to Address";
        Shop: Record "Shpfy Shop";
        DefaultVATGroupMissingErr: Label 'The general-only test template must have a blank VAT group and its general posting group must have a nonblank default VAT group.';
    begin
        this.CreateScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, false, false, false, true);
        CountryCustomerTemplate := this.EnableCustomerAutoCreate(Shop, DestinationCountry, VATCustomer, true, false);
        GenBusinessPostingGroup.Get(CountryCustomerTemplate."Gen. Bus. Posting Group");
        this.LibraryAssert.AreEqual('', CountryCustomerTemplate."VAT Bus. Posting Group", DefaultVATGroupMissingErr);
        this.LibraryAssert.AreNotEqual('', GenBusinessPostingGroup."Def. VAT Bus. Posting Group", DefaultVATGroupMissingErr);
        this.SetExpectedVATValues(DestinationCountry, VATCustomer."VAT Registration No.", CountryCustomerTemplate."Gen. Bus. Posting Group", VATCustomer."VAT Bus. Posting Group", false, true, false);
    end;

    local procedure VerifyGenOnlyAutoCreateScenario(OrderHeader: Record "Shpfy Order Header"; SellToCustomer: Record Customer; BillToCustomer: Record Customer; VATCustomer: Record Customer; DestinationCountry: Code[10]; CountryCustomerTemplate: Record "Customer Templ.")
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        AlternativeVATSetupErr: Label 'The general-only template must create an alternative with only its general business posting group.';
    begin
        this.VerifyScenario(OrderHeader, SellToCustomer, BillToCustomer, false, false);
        this.LibraryAssert.IsTrue(this.AlternativeVATRegistrationExists(AltCustVATReg, VATCustomer."No.", DestinationCountry), AlternativeVATSetupErr);
        this.LibraryAssert.AreEqual('', AltCustVATReg."VAT Registration No.", AlternativeVATSetupErr);
        this.LibraryAssert.AreEqual(CountryCustomerTemplate."Gen. Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AlternativeVATSetupErr);
        this.LibraryAssert.AreEqual('', AltCustVATReg."VAT Bus. Posting Group", AlternativeVATSetupErr);
    end;

    local procedure CreateExistingAlternativeScenario(var Shop: Record "Shpfy Shop"; var OrderHeader: Record "Shpfy Order Header"; var VATCustomer: Record Customer; var SellToCustomer: Record Customer; var BillToCustomer: Record Customer; var DestinationCountry: Code[10]; var InterimShipToAddress: Record "Ship-to Address"; var CountryCustomerTemplate: Record "Customer Templ."; var AltCustVATRegBefore: Record "Alt. Cust. VAT Reg.")
    begin
        this.CreateScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, false, false, false, false);
        CountryCustomerTemplate := this.EnableCustomerAutoCreate(Shop, DestinationCountry, VATCustomer, true, true);
        this.GetAlternativeVATRegistration(AltCustVATRegBefore, VATCustomer."No.", DestinationCountry);
    end;

    local procedure VerifyExistingAlternativeScenario(OrderHeader: Record "Shpfy Order Header"; SellToCustomer: Record Customer; BillToCustomer: Record Customer; VATCustomer: Record Customer; DestinationCountry: Code[10]; AltCustVATRegBefore: Record "Alt. Cust. VAT Reg."; CountryCustomerTemplate: Record "Customer Templ.")
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        AlternativeVATSetupChangedErr: Label 'Automatic creation must not update an existing alternative VAT registration.';
    begin
        this.VerifyScenario(OrderHeader, SellToCustomer, BillToCustomer, false, false);
        this.GetAlternativeVATRegistration(AltCustVATReg, VATCustomer."No.", DestinationCountry);
        this.LibraryAssert.AreEqual(AltCustVATRegBefore."VAT Registration No.", AltCustVATReg."VAT Registration No.", AlternativeVATSetupChangedErr);
        this.LibraryAssert.AreEqual(AltCustVATRegBefore."Gen. Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AlternativeVATSetupChangedErr);
        this.LibraryAssert.AreEqual(AltCustVATRegBefore."VAT Bus. Posting Group", AltCustVATReg."VAT Bus. Posting Group", AlternativeVATSetupChangedErr);
        this.LibraryAssert.AreNotEqual(AltCustVATReg."Gen. Bus. Posting Group", CountryCustomerTemplate."Gen. Bus. Posting Group", AlternativeVATSetupChangedErr);
    end;

    local procedure CreateManualVATScenario(var Shop: Record "Shpfy Shop"; var OrderHeader: Record "Shpfy Order Header"; var VATCustomer: Record Customer; var SellToCustomer: Record Customer; var BillToCustomer: Record Customer; var DestinationCountry: Code[10]; var InterimShipToAddress: Record "Ship-to Address"; var CountryCustomerTemplate: Record "Customer Templ."; var ManualCountry: Code[10])
    var
        DefaultPreferencesErr: Label 'Alternative VAT preferences must default off and remain independent.';
    begin
        this.CreateScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, false, false, false, true);
        this.LibraryAssert.IsFalse(Shop."Auto Create Alt. VAT Reg. Cust", DefaultPreferencesErr);
        this.LibraryAssert.IsFalse(Shop."Auto Create Alt. VAT Reg. Co.", DefaultPreferencesErr);
        CountryCustomerTemplate := this.EnableCustomerAutoCreate(Shop, DestinationCountry, VATCustomer, true, true);
        Shop.Get(Shop.Code);
        this.LibraryAssert.IsFalse(Shop."Auto Create Alt. VAT Reg. Co.", DefaultPreferencesErr);
        ManualCountry := this.CreateCountryRegion(VATCustomer."No.");
        this.CreateAlternativeWithValues(VATCustomer, ManualCountry, 'MANUAL-VAT', true, true);
    end;

    local procedure ProcessOrderThenManuallyChangeShipToCountry(var SalesHeader: Record "Sales Header"; OrderHeader: Record "Shpfy Order Header"; ManualCountry: Code[10]; CountryCustomerTemplate: Record "Customer Templ."; VATCustomer: Record Customer)
    var
        ManualVATPromptUnexpectedErr: Label 'The VAT confirmation prompt must not appear during Shopify-driven document creation.';
        SalesDocumentNotFoundErr: Label 'Sales document not created/found for the Shopify order.';
    begin
        this.SetExpectedVATValues(CopyStr(OrderHeader."Ship-to Country/Region Code", 1, MaxStrLen(this.ExpectedVATCountry)), VATCustomer."VAT Registration No.", CountryCustomerTemplate."Gen. Bus. Posting Group", CountryCustomerTemplate."VAT Bus. Posting Group", false, true, true);
        this.ManualVATPromptShown := false;
        this.ProcessOrderManually(OrderHeader);
        this.LibraryAssert.IsFalse(this.ManualVATPromptShown, ManualVATPromptUnexpectedErr);
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        this.LibraryAssert.IsTrue(SalesHeader.FindFirst(), SalesDocumentNotFoundErr);
        this.LibrarySales.ReopenSalesDocument(SalesHeader);
        // The standard confirmation page is shown only outside a write transaction, as in an interactive user session.
        Commit();
        SalesHeader.Validate("Ship-to Country/Region Code", ManualCountry);
        SalesHeader.Modify(true);
    end;

    local procedure VerifyManualVATScenario(SalesHeader: Record "Sales Header"; AltCustVATReg: Record "Alt. Cust. VAT Reg."; VATCustomer: Record Customer; ManualCountry: Code[10])
    var
        ManualValidationPromptMissingErr: Label 'Manual country validation after Shopify processing must retain standard interactive behavior.';
        ManualVATSetupErr: Label 'Manual country validation must apply the selected destination alternative.';
    begin
        this.LibraryAssert.IsTrue(this.ManualVATPromptShown, ManualValidationPromptMissingErr);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        this.LibraryAssert.AreEqual(ManualCountry, SalesHeader."VAT Country/Region Code", ManualVATSetupErr);
        this.LibraryAssert.AreEqual('MANUAL-VAT', SalesHeader."VAT Registration No.", ManualVATSetupErr);
        this.LibraryAssert.IsTrue(SalesHeader."Alt. VAT Registration No.", ManualVATSetupErr);
        this.GetAlternativeVATRegistration(AltCustVATReg, VATCustomer."No.", ManualCountry);
        this.LibraryAssert.AreEqual('MANUAL-VAT', AltCustVATReg."VAT Registration No.", ManualVATSetupErr);
    end;

    local procedure CreateB2BAutoCreateScenario(var Shop: Record "Shpfy Shop"; var OrderHeader: Record "Shpfy Order Header"; var SellToCustomer: Record Customer; var BillToCustomer: Record Customer; var VATCustomer: Record Customer; var DestinationCountry: Code[10]; var CountryCustomerTemplate: Record "Customer Templ."; EnableCompanyAutoCreate: Boolean)
    var
        InterimShipToAddress: Record "Ship-to Address";
        CountryTemplateInvalidErr: Label 'The test country template must contain both posting groups.';
    begin
        this.CreateScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, true, false, false, true);
        CountryCustomerTemplate := this.CreateCountryCustomerTemplate(Shop, DestinationCountry, VATCustomer, true, true);
        Shop."Auto Create Alt. VAT Reg. Cust" := not EnableCompanyAutoCreate;
        Shop."Auto Create Alt. VAT Reg. Co." := EnableCompanyAutoCreate;
        Shop.Modify();
        this.LibraryAssert.IsTrue(CountryCustomerTemplate."Gen. Bus. Posting Group" <> '', CountryTemplateInvalidErr);
        this.LibraryAssert.IsTrue(CountryCustomerTemplate."VAT Bus. Posting Group" <> '', CountryTemplateInvalidErr);
        if EnableCompanyAutoCreate then
            this.SetExpectedVATValues(DestinationCountry, VATCustomer."VAT Registration No.", CountryCustomerTemplate."Gen. Bus. Posting Group", CountryCustomerTemplate."VAT Bus. Posting Group", false, true, true)
        else
            this.SetExpectedVATSetup(VATCustomer, DestinationCountry, false);
    end;

    local procedure VerifyB2BAutoCreateUsesCompanyPreference(OrderHeader: Record "Shpfy Order Header"; SellToCustomer: Record Customer; BillToCustomer: Record Customer; VATCustomer: Record Customer; DestinationCountry: Code[10]; CountryCustomerTemplate: Record "Customer Templ.")
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        AlternativeVATSetupMissingErr: Label 'The company auto-create preference should create the destination alternative VAT registration.';
    begin
        this.VerifyScenario(OrderHeader, SellToCustomer, BillToCustomer, false, true);
        this.LibraryAssert.IsTrue(this.AlternativeVATRegistrationExists(AltCustVATReg, VATCustomer."No.", DestinationCountry), AlternativeVATSetupMissingErr);
        this.LibraryAssert.AreEqual(CountryCustomerTemplate."Gen. Bus. Posting Group", AltCustVATReg."Gen. Bus. Posting Group", AlternativeVATSetupMissingErr);
        this.LibraryAssert.AreEqual(CountryCustomerTemplate."VAT Bus. Posting Group", AltCustVATReg."VAT Bus. Posting Group", AlternativeVATSetupMissingErr);
    end;

    local procedure VerifyB2BAutoCreateDoesNotUseCustomerPreference(OrderHeader: Record "Shpfy Order Header"; SellToCustomer: Record Customer; BillToCustomer: Record Customer; VATCustomer: Record Customer; DestinationCountry: Code[10])
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        AlternativeVATSetupUnexpectedErr: Label 'The customer auto-create preference must not create an alternative for a B2B order.';
    begin
        this.VerifyScenario(OrderHeader, SellToCustomer, BillToCustomer, false, true);
        this.LibraryAssert.IsFalse(this.AlternativeVATRegistrationExists(AltCustVATReg, VATCustomer."No.", DestinationCountry), AlternativeVATSetupUnexpectedErr);
    end;

    local procedure CreateAutoCreateCustomerTemplateScenario(var OrderHeader: Record "Shpfy Order Header"; var SellToCustomer: Record Customer; var BillToCustomer: Record Customer; var VATCustomer: Record Customer; var DestinationCountry: Code[10]; var CountryCustomerTemplate: Record "Customer Templ.")
    var
        InterimShipToAddress: Record "Ship-to Address";
        Shop: Record "Shpfy Shop";
        CountryTemplateSourceErr: Label 'The country-specific customer template must remain distinct from the shop customer template.';
    begin
        this.CreateScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, false, false, false, true);
        CountryCustomerTemplate := this.CreateCountryCustomerTemplate(Shop, DestinationCountry, VATCustomer, false, true);
        Shop."Auto Create Alt. VAT Reg. Cust" := true;
        Shop."Auto Create Alt. VAT Reg. Co." := false;
        Shop.Modify();
        this.LibraryAssert.AreNotEqual(Shop."Customer Templ. Code", CountryCustomerTemplate.Code, CountryTemplateSourceErr);

        this.SetExpectedVATValues(DestinationCountry, VATCustomer."VAT Registration No.", VATCustomer."Gen. Bus. Posting Group", CountryCustomerTemplate."VAT Bus. Posting Group", false, false, true);
    end;

    local procedure VerifyAutoCreatedCustomerTemplateScenario(OrderHeader: Record "Shpfy Order Header"; SellToCustomer: Record Customer; BillToCustomer: Record Customer; VATCustomer: Record Customer; DestinationCountry: Code[10]; CountryCustomerTemplate: Record "Customer Templ.")
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        AlternativeVATSetupMissingErr: Label 'The eligible country customer template should create the expected alternative VAT registration.';
    begin
        this.VerifyScenario(OrderHeader, SellToCustomer, BillToCustomer, false, false);
        this.LibraryAssert.IsTrue(this.AlternativeVATRegistrationExists(AltCustVATReg, VATCustomer."No.", DestinationCountry), AlternativeVATSetupMissingErr);
        this.LibraryAssert.AreEqual('', AltCustVATReg."VAT Registration No.", AlternativeVATSetupMissingErr);
        this.LibraryAssert.AreEqual('', AltCustVATReg."Gen. Bus. Posting Group", AlternativeVATSetupMissingErr);
        this.LibraryAssert.AreEqual(CountryCustomerTemplate."VAT Bus. Posting Group", AltCustVATReg."VAT Bus. Posting Group", AlternativeVATSetupMissingErr);
    end;

    local procedure CreateScenario(var Shop: Record "Shpfy Shop"; var OrderHeader: Record "Shpfy Order Header"; var VATCustomer: Record Customer; var SellToCustomer: Record Customer; var BillToCustomer: Record Customer; var DestinationCountry: Code[10]; var InterimShipToAddress: Record "Ship-to Address"; IsB2B: Boolean; UseBillToVATCustomer: Boolean; CreateInvoice: Boolean; NoFinalAlternative: Boolean)
    var
        DummyCustomer: Record Customer;
        ImportOrder: Codeunit "Shpfy Import Order";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        BillToCountry: Code[10];
        InterimCountry: Code[10];
        InterimShipToCode: Code[10];
        SellToCountry: Code[10];
    begin
        Shop := this.InitializeShop();
        Shop."Create Invoices From Orders" := CreateInvoice;
        Shop.Modify();
        DummyCustomer := InitializeTest.GetDummyCustomer();
        SellToCustomer := this.CreateCustomerWithBaseline(DummyCustomer, Shop."VAT Country/Region Code", 'SELLTO-BASE');
        BillToCustomer := this.CreateCustomerWithBaseline(DummyCustomer, Shop."VAT Country/Region Code", 'BILLTO-BASE');
        SellToCountry := this.CreateCountryRegion(SellToCustomer."No.");
        SellToCustomer.Validate("Country/Region Code", SellToCountry);
        SellToCustomer.Modify();
        BillToCountry := this.CreateCountryRegion(BillToCustomer."No.");
        BillToCustomer.Validate("Country/Region Code", BillToCountry);
        BillToCustomer.Modify();
        VATCustomer := SellToCustomer;
        if UseBillToVATCustomer then
            VATCustomer := BillToCustomer;
        DestinationCountry := this.CreateCountryRegion(VATCustomer."No.");

        if NoFinalAlternative then begin
            InterimCountry := this.CreateCountryRegion(VATCustomer."No.");
            InterimShipToCode := CopyStr('INT' + this.LibraryRandom.RandText(5), 1, MaxStrLen(InterimShipToAddress.Code));
            this.CreateShipToAddress(InterimShipToAddress, VATCustomer."No.", InterimShipToCode, InterimCountry);
            VATCustomer."Ship-to Code" := InterimShipToCode;
            VATCustomer.Modify();
            SellToCustomer.Get(SellToCustomer."No.");
            BillToCustomer.Get(BillToCustomer."No.");
            this.CreateAlternativeWithValues(VATCustomer, InterimCountry, 'INTERIM-VAT', true, true);
        end else
            this.CreateAlternative(VATCustomer, DestinationCountry);

        this.SetVATCustomerPreference(UseBillToVATCustomer);
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, IsB2B);
        this.CollectScenarioItemPostingGroups(OrderHeader);
        this.EnsureVATPostingSetupForBusinessGroup(Shop, VATCustomer."VAT Bus. Posting Group");
        this.EnsureGeneralPostingSetupForBusinessGroup(Shop, VATCustomer."Gen. Bus. Posting Group");
        OrderHeader."Sell-to Customer No." := SellToCustomer."No.";
        OrderHeader."Bill-to Customer No." := BillToCustomer."No.";
        OrderHeader."Ship-to Country/Region Code" := DestinationCountry;
        if IsB2B then
            OrderHeader.B2B := true;
        if CreateInvoice then
            OrderHeader."Fulfillment Status" := OrderHeader."Fulfillment Status"::Fulfilled;
        OrderHeader.Modify();

        this.SetExpectedVATSetup(VATCustomer, DestinationCountry, not NoFinalAlternative);
    end;

    local procedure SetExpectedVATSetup(VATCustomer: Record Customer; DestinationCountry: Code[10]; HasAlternative: Boolean)
    begin
        if HasAlternative then
            this.SetExpectedVATValues(DestinationCountry, CopyStr('ALT-' + VATCustomer."No.", 1, MaxStrLen(this.ExpectedVATRegistrationNo)), VATCustomer."Gen. Bus. Posting Group", VATCustomer."VAT Bus. Posting Group", true, true, true)
        else
            this.SetExpectedVATValues(VATCustomer."Country/Region Code", VATCustomer."VAT Registration No.", VATCustomer."Gen. Bus. Posting Group", VATCustomer."VAT Bus. Posting Group", false, false, false)
    end;

    local procedure SetExpectedVATValues(VATCountry: Code[10]; VATRegistrationNo: Text[20]; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; AltVATRegistration: Boolean; AltGenBusPostingGroup: Boolean; AltVATBusPostingGroup: Boolean)
    begin
        this.ExpectedVATCountry := VATCountry;
        this.ExpectedVATRegistrationNo := VATRegistrationNo;
        this.ExpectedGenBusPostingGroup := GenBusPostingGroup;
        this.ExpectedVATBusPostingGroup := VATBusPostingGroup;
        this.ExpectedAltVATRegistration := AltVATRegistration;
        this.ExpectedAltGenBusPostingGroup := AltGenBusPostingGroup;
        this.ExpectedAltVATBusPostingGroup := AltVATBusPostingGroup;
    end;

    local procedure EnableCustomerAutoCreate(var Shop: Record "Shpfy Shop"; DestinationCountry: Code[10]; VATCustomer: Record Customer; SetGenBusPostingGroup: Boolean; SetVATBusPostingGroup: Boolean) CountryCustomerTemplate: Record "Customer Templ."
    begin
        CountryCustomerTemplate := this.CreateCountryCustomerTemplate(Shop, DestinationCountry, VATCustomer, SetGenBusPostingGroup, SetVATBusPostingGroup);
        Shop."Auto Create Alt. VAT Reg. Cust" := true;
        Shop.Modify();
    end;

    local procedure ProcessOrderManually(OrderHeader: Record "Shpfy Order Header")
    var
        ProcessOrders: Codeunit "Shpfy Process Orders";
        ProcessingErrorErr: Label 'Shopify order processing failed: %1', Comment = '%1 = error stored on the Shopify order';
    begin
        Commit(); // ProcessShopifyOrder uses Codeunit.Run with a return value, which requires no open write transaction.
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.Get(OrderHeader."Shopify Order Id");
        this.LibraryAssert.IsFalse(OrderHeader."Has Error", StrSubstNo(ProcessingErrorErr, OrderHeader."Error Message"));
    end;

    local procedure ProcessOrderByReportEntryPoint(OrderHeader: Record "Shpfy Order Header")
    var
        ProcessOrder: Codeunit "Shpfy Process Order";
        OrderProcessingFailedErr: Label 'Shopify order processing failed: %1', Comment = '%1 = error returned while processing the Shopify order';
    begin
        Commit(); // Codeunit.Run with a return value requires no open write transaction.
        if not ProcessOrder.Run(OrderHeader) then
            Error(OrderProcessingFailedErr, GetLastErrorText());
    end;

    local procedure VerifyScenario(OrderHeader: Record "Shpfy Order Header"; SellToCustomer: Record Customer; BillToCustomer: Record Customer; CreateInvoice: Boolean; IsB2B: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        B2BOrderErr: Label 'The test scenario must retain its expected B2B classification.';
        DocumentTypeErr: Label 'The Shopify order should create the expected sales document type.';
        ExpectedDocumentType: Enum "Sales Document Type";
        ManualValidationLbl: Label 'The created document must not retain suppressed validation dialogs for later manual edits.';
        OrderNotCreatedErr: Label 'The Shopify order should create a sales document.';
        SalesLineNotCreatedErr: Label 'The Shopify order should create at least one sales line.';
    begin
        if CreateInvoice then
            ExpectedDocumentType := ExpectedDocumentType::Invoice
        else
            ExpectedDocumentType := ExpectedDocumentType::Order;

        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        this.LibraryAssert.IsTrue(SalesHeader.FindFirst(), OrderNotCreatedErr);
        this.LibraryAssert.AreEqual(ExpectedDocumentType, SalesHeader."Document Type", DocumentTypeErr);
        this.LibraryAssert.AreEqual(IsB2B, OrderHeader.B2B, B2BOrderErr);
        this.LibraryAssert.IsFalse(SalesHeader.GetHideValidationDialog(), ManualValidationLbl);
        this.VerifyExpectedVATSetup(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        this.LibraryAssert.IsFalse(SalesLine.IsEmpty(), SalesLineNotCreatedErr);
        this.VerifyCustomerUnchanged(SellToCustomer);
        this.VerifyCustomerUnchanged(BillToCustomer);
    end;

    local procedure VerifyCustomerUnchanged(CustomerBefore: Record Customer)
    var
        CustomerAfter: Record Customer;
        CustomerUnchangedErr: Label 'Shopify order processing must not update VAT or address values on the customer.';
    begin
        CustomerAfter.Get(CustomerBefore."No.");
        this.LibraryAssert.AreEqual(CustomerBefore."Country/Region Code", CustomerAfter."Country/Region Code", CustomerUnchangedErr);
        this.LibraryAssert.AreEqual(CustomerBefore."VAT Registration No.", CustomerAfter."VAT Registration No.", CustomerUnchangedErr);
        this.LibraryAssert.AreEqual(CustomerBefore."Gen. Bus. Posting Group", CustomerAfter."Gen. Bus. Posting Group", CustomerUnchangedErr);
        this.LibraryAssert.AreEqual(CustomerBefore."VAT Bus. Posting Group", CustomerAfter."VAT Bus. Posting Group", CustomerUnchangedErr);
        this.LibraryAssert.AreEqual(CustomerBefore."Ship-to Code", CustomerAfter."Ship-to Code", CustomerUnchangedErr);
    end;

    local procedure VerifyHistoricalInvoiceUnchanged(InvoiceBefore: Record "Sales Invoice Header")
    var
        InvoiceAfter: Record "Sales Invoice Header";
        HistoricalInvoiceUnchangedLbl: Label 'Shopify order processing must not update a previously posted sales invoice.';
    begin
        InvoiceAfter.Get(InvoiceBefore."No.");
        this.LibraryAssert.AreEqual(InvoiceBefore."VAT Country/Region Code", InvoiceAfter."VAT Country/Region Code", HistoricalInvoiceUnchangedLbl);
        this.LibraryAssert.AreEqual(InvoiceBefore."VAT Registration No.", InvoiceAfter."VAT Registration No.", HistoricalInvoiceUnchangedLbl);
        this.LibraryAssert.AreEqual(InvoiceBefore."Gen. Bus. Posting Group", InvoiceAfter."Gen. Bus. Posting Group", HistoricalInvoiceUnchangedLbl);
        this.LibraryAssert.AreEqual(InvoiceBefore."VAT Bus. Posting Group", InvoiceAfter."VAT Bus. Posting Group", HistoricalInvoiceUnchangedLbl);
    end;

    local procedure CreateCurrentSetupRefundScenario(var PostedInvoice: Record "Sales Invoice Header"; var SellToCustomer: Record Customer; var BillToCustomer: Record Customer) RefundId: BigInteger
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        CountryCustomerTemplate: Record "Customer Templ.";
        InterimShipToAddress: Record "Ship-to Address";
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        SalesHeader: Record "Sales Header";
        Shop: Record "Shpfy Shop";
        VATCustomer: Record Customer;
        OrderRefundsHelper: Codeunit "Shpfy Order Refunds Helper";
        DestinationCountry: Code[10];
        OrderNotCreatedErr: Label 'The Shopify order should create a sales document.';
        PostedInvoiceNo: Code[20];
    begin
        this.CreateScenario(Shop, OrderHeader, VATCustomer, SellToCustomer, BillToCustomer, DestinationCountry, InterimShipToAddress, false, false, true, false);
        this.ProcessOrderManually(OrderHeader);
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        this.LibraryAssert.IsTrue(SalesHeader.FindFirst(), OrderNotCreatedErr);
        this.EnsureInventoryPostingSetupForSalesDocument(SalesHeader);
        PostedInvoiceNo := this.LibrarySales.PostSalesDocument(SalesHeader, false, true);
        PostedInvoice.Get(PostedInvoiceNo);

        CountryCustomerTemplate := this.CreateCountryCustomerTemplate(Shop, DestinationCountry, VATCustomer, true, true);
        this.GetAlternativeVATRegistration(AltCustVATReg, VATCustomer."No.", DestinationCountry);
        AltCustVATReg.Validate("VAT Registration No.", CopyStr('CURRENT-' + VATCustomer."No.", 1, MaxStrLen(AltCustVATReg."VAT Registration No.")));
        AltCustVATReg.Validate("Gen. Bus. Posting Group", CountryCustomerTemplate."Gen. Bus. Posting Group");
        AltCustVATReg.Validate("VAT Bus. Posting Group", CountryCustomerTemplate."VAT Bus. Posting Group");
        AltCustVATReg.Modify(true);
        Shop."Process Returns As" := "Sales Document Type"::"Credit Memo";
        Shop.Modify(false);
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        OrderLine.FindFirst();
        RefundId := OrderRefundsHelper.CreateRefundHeader(OrderHeader."Shopify Order Id", 0, 156.38, Shop.Code);
        OrderRefundsHelper.CreateRefundLine(RefundId, OrderLine."Line Id", "Shpfy Restock Type"::Return);

        this.SetExpectedVATValues(DestinationCountry, AltCustVATReg."VAT Registration No.", AltCustVATReg."Gen. Bus. Posting Group", AltCustVATReg."VAT Bus. Posting Group", true, true, true);
    end;

    local procedure CreateRefundCreditMemo(RefundId: BigInteger): Record "Sales Header"
    var
        ErrorInfo: ErrorInfo;
        RefundDocumentNotCreatedErr: Label 'The Shopify refund should be eligible for sales document creation.';
        ReturnRefundProcess: Interface "Shpfy IReturnRefund Process";
    begin
        ReturnRefundProcess := Enum::"Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo";
        this.LibraryAssert.IsTrue(ReturnRefundProcess.CanCreateSalesDocumentFor(Enum::"Shpfy Source Document Type"::Refund, RefundId, ErrorInfo), RefundDocumentNotCreatedErr);
        exit(ReturnRefundProcess.CreateSalesDocument(Enum::"Shpfy Source Document Type"::Refund, RefundId));
    end;

    local procedure VerifyCurrentSetupRefund(SalesHeader: Record "Sales Header"; PostedInvoice: Record "Sales Invoice Header"; SellToCustomer: Record Customer; BillToCustomer: Record Customer)
    var
        DocumentTypeErr: Label 'The Shopify refund should create a credit memo.';
    begin
        this.LibraryAssert.AreEqual("Sales Document Type"::"Credit Memo", SalesHeader."Document Type", DocumentTypeErr);
        this.VerifyExpectedVATSetup(SalesHeader);
        this.VerifyCustomerUnchanged(SellToCustomer);
        this.VerifyCustomerUnchanged(BillToCustomer);
        this.VerifyHistoricalInvoiceUnchanged(PostedInvoice);
    end;

    local procedure CreateCountryCustomerTemplate(Shop: Record "Shpfy Shop"; CountryRegionCode: Code[10]; VATCustomer: Record Customer; SetGenBusPostingGroup: Boolean; SetVATBusPostingGroup: Boolean) CountryCustomerTemplate: Record "Customer Templ."
    var
        CountrySetup: Record "Shpfy Customer Template";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        SourceCustomerTemplate: Record "Customer Templ.";
        SourceShop: Record "Shpfy Shop";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        LibraryTemplates: Codeunit "Library - Templates";
        GenBusPostingGroup: Code[20];
        VATBusPostingGroup: Code[20];
    begin
        // Use another shop's template only as a source of valid test posting-group records.
        SourceShop := InitializeTest.CreateShop();
        SourceCustomerTemplate.Get(SourceShop."Customer Templ. Code");
        VATBusPostingGroup := VATCustomer."VAT Bus. Posting Group";
        if SetVATBusPostingGroup then begin
            this.LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
            VATBusPostingGroup := VATBusinessPostingGroup.Code;
        end;
        GenBusPostingGroup := VATCustomer."Gen. Bus. Posting Group";
        if SetGenBusPostingGroup then begin
            this.LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
            GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", VATBusPostingGroup);
            GenBusinessPostingGroup.Modify(true);
            GenBusPostingGroup := GenBusinessPostingGroup.Code;
        end;

        LibraryTemplates.CreateCustomerTemplate(CountryCustomerTemplate);
        CountryCustomerTemplate.Validate("Customer Posting Group", SourceCustomerTemplate."Customer Posting Group");
        if SetGenBusPostingGroup then
            CountryCustomerTemplate.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        if SetVATBusPostingGroup then
            CountryCustomerTemplate.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        CountryCustomerTemplate.Modify(true);

        this.EnsureGeneralPostingSetupForBusinessGroup(Shop, GenBusPostingGroup);
        this.EnsureVATPostingSetupForBusinessGroup(Shop, VATBusPostingGroup);

        CountrySetup.Init();
        CountrySetup."Shop Code" := Shop.Code;
        CountrySetup."Country/Region Code" := CountryRegionCode;
        CountrySetup."Customer Templ. Code" := CountryCustomerTemplate.Code;
        CountrySetup.Insert();
    end;

    local procedure VerifyExpectedVATSetup(SalesHeader: Record "Sales Header")
    var
        VATSetupErr: Label 'The document must contain the expected VAT setup.';
    begin
        this.LibraryAssert.AreEqual(this.ExpectedVATCountry, SalesHeader."VAT Country/Region Code", VATSetupErr);
        this.LibraryAssert.AreEqual(this.ExpectedVATRegistrationNo, SalesHeader."VAT Registration No.", VATSetupErr);
        this.LibraryAssert.AreEqual(this.ExpectedGenBusPostingGroup, SalesHeader."Gen. Bus. Posting Group", VATSetupErr);
        this.LibraryAssert.AreEqual(this.ExpectedVATBusPostingGroup, SalesHeader."VAT Bus. Posting Group", VATSetupErr);
        this.LibraryAssert.AreEqual(this.ExpectedAltVATRegistration, SalesHeader."Alt. VAT Registration No.", VATSetupErr);
        this.LibraryAssert.AreEqual(this.ExpectedAltGenBusPostingGroup, SalesHeader."Alt. Gen. Bus Posting Group", VATSetupErr);
        this.LibraryAssert.AreEqual(this.ExpectedAltVATBusPostingGroup, SalesHeader."Alt. VAT Bus Posting Group", VATSetupErr);
    end;

    local procedure InitializeShop() Shop: Record "Shpfy Shop"
    var
        DummyCustomer: Record Customer;
        RegisteredStoreNew: Record "Shpfy Registered Store New";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        AccessToken: SecretText;
    begin
        Clear(this.ScenarioGenProdPostingGroups);
        Clear(this.ScenarioVATProdPostingGroups);
        Shop := InitializeTest.CreateShop();
        DummyCustomer := InitializeTest.GetDummyCustomer();
        this.DisablePostingSetupNotification();
        this.EnsureCustomerPostingGroup(DummyCustomer."Customer Posting Group");
        this.EnsureGeneralPostingSetupForBusinessGroup(Shop, DummyCustomer."Gen. Bus. Posting Group");
        this.EnsureVATPostingSetupForBusinessGroup(Shop, Shop."VAT Bus. Posting Group");
        this.EnsureVATPostingSetupForBusinessGroup(Shop, DummyCustomer."VAT Bus. Posting Group");
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        Shop."Fulfillment Service Activated" := true;
        Shop.Modify();
        CurrentShop := Shop;
        AccessToken := this.LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        RegisteredStoreNew.Get(Shop.GetStoreName());
        RegisteredStoreNew."Requested Scope" := AuthenticationMgt.GetScope();
        RegisteredStoreNew."Actual Scope" := AuthenticationMgt.GetScope();
        RegisteredStoreNew.Modify(false);
    end;

    local procedure CreateCustomerWithBaseline(DummyCustomer: Record Customer; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]) Customer: Record Customer
    begin
        this.LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CountryRegionCode;
        Customer."VAT Registration No." := VATRegistrationNo;
        Customer."Customer Posting Group" := DummyCustomer."Customer Posting Group";
        Customer."Gen. Bus. Posting Group" := DummyCustomer."Gen. Bus. Posting Group";
        Customer."VAT Bus. Posting Group" := DummyCustomer."VAT Bus. Posting Group";
        Customer.Modify();
    end;

    local procedure CreateAlternative(VATCustomer: Record Customer; CountryRegionCode: Code[10])
    begin
        this.CreateAlternativeWithValues(VATCustomer, CountryRegionCode, CopyStr('ALT-' + VATCustomer."No.", 1, 20), true, true);
    end;

    local procedure CreateAlternativeWithValues(VATCustomer: Record Customer; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]; SetGenBusPostingGroup: Boolean; SetVATBusPostingGroup: Boolean)
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
    begin
        AltCustVATReg."Customer No." := VATCustomer."No.";
        AltCustVATReg."VAT Country/Region Code" := CountryRegionCode;
        AltCustVATReg."VAT Registration No." := VATRegistrationNo;
        if SetGenBusPostingGroup then
            AltCustVATReg."Gen. Bus. Posting Group" := VATCustomer."Gen. Bus. Posting Group";
        if SetVATBusPostingGroup then
            AltCustVATReg."VAT Bus. Posting Group" := VATCustomer."VAT Bus. Posting Group";
        AltCustVATReg.Insert(true);
    end;

    local procedure CreateShipToAddress(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20]; ShipToCode: Code[10]; CountryRegionCode: Code[10])
    begin
        ShipToAddress.Init();
        ShipToAddress."Customer No." := CustomerNo;
        ShipToAddress.Code := ShipToCode;
        ShipToAddress.Name := 'Interim VAT destination';
        ShipToAddress."Country/Region Code" := CountryRegionCode;
        ShipToAddress.Insert();
    end;

    local procedure CreateCountryRegion(CustomerNo: Code[20]) CountryRegionCode: Code[10]
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        CountryRegion: Record "Country/Region";
    begin
        repeat
            CountryRegionCode := CopyStr('VAT' + this.LibraryRandom.RandText(5), 1, MaxStrLen(CountryRegion.Code));
        until (not CountryRegion.Get(CountryRegionCode)) and
            (not this.AlternativeVATRegistrationExists(AltCustVATReg, CustomerNo, CountryRegionCode));

        CountryRegion.Init();
        CountryRegion.Code := CountryRegionCode;
        CountryRegion.Name := CountryRegionCode;
        CountryRegion.Insert();
    end;

    local procedure AlternativeVATRegistrationExists(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustomerNo: Code[20]; CountryRegionCode: Code[10]): Boolean
    var
        AltCustVATRegFacade: Codeunit "Alt. Cust. VAT. Reg. Facade";
    begin
        AltCustVATReg.Reset();
        exit(AltCustVATRegFacade.GetAlternativeCustVATReg(AltCustVATReg, CustomerNo, CountryRegionCode));
    end;

    local procedure GetAlternativeVATRegistration(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustomerNo: Code[20]; CountryRegionCode: Code[10])
    var
        AlternativeVATSetupMissingErr: Label 'The expected alternative VAT registration is missing.';
    begin
        if not this.AlternativeVATRegistrationExists(AltCustVATReg, CustomerNo, CountryRegionCode) then
            Error(AlternativeVATSetupMissingErr);
    end;

    local procedure EnsureInventoryPostingSetupForSalesDocument(SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                Item.Get(SalesLine."No.");
                this.EnsureInventoryPostingSetupForLocation(SalesLine."Location Code", Item."Inventory Posting Group");
            until SalesLine.Next() = 0;
    end;

    local procedure EnsureInventoryPostingSetupForLocation(LocationCode: Code[10]; InventoryPostingGroup: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if not InventoryPostingSetup.Get(LocationCode, InventoryPostingGroup) then
            this.LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, LocationCode, InventoryPostingGroup);

        if InventoryPostingSetup."Inventory Account" = '' then
            InventoryPostingSetup.Validate("Inventory Account", this.LibraryERM.CreateGLAccountNo());
        if InventoryPostingSetup."Inventory Account (Interim)" = '' then
            InventoryPostingSetup.Validate("Inventory Account (Interim)", this.LibraryERM.CreateGLAccountNo());
        InventoryPostingSetup.Modify(true);
    end;

    local procedure EnsureCustomerPostingGroup(CustomerPostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        MissingCustomerPostingGroupErr: Label 'Customer Posting Group ''%1'' does not exist. Create it in the test setup before processing the Shopify order.', Comment = '%1 = Customer posting group code';
    begin
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            Error(MissingCustomerPostingGroupErr, CustomerPostingGroupCode);

        if CustomerPostingGroup."Receivables Account" <> '' then
            exit;

        CustomerPostingGroup.Validate("Receivables Account", this.LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Modify(true);
    end;

    local procedure EnsureGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then
            this.LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProdPostingGroup);

        if GeneralPostingSetup."Sales Account" = '' then
            GeneralPostingSetup.Validate("Sales Account", this.LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."COGS Account" = '' then
            GeneralPostingSetup.Validate("COGS Account", this.LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Inventory Adjmt. Account" = '' then
            GeneralPostingSetup.Validate("Inventory Adjmt. Account", this.LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CollectScenarioItemPostingGroups(OrderHeader: Record "Shpfy Order Header")
    var
        Item: Record Item;
        OrderLine: Record "Shpfy Order Line";
        Variant: Record "Shpfy Variant";
    begin
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                if not (OrderLine.Tip or OrderLine."Gift Card") then begin
                    if OrderLine."Item No." <> '' then
                        Item.Get(OrderLine."Item No.")
                    else begin
                        Variant.Get(OrderLine."Shopify Variant Id");
                        Item.GetBySystemId(Variant."Item SystemId");
                    end;
                    if not this.ScenarioGenProdPostingGroups.Contains(Item."Gen. Prod. Posting Group") then
                        this.ScenarioGenProdPostingGroups.Add(Item."Gen. Prod. Posting Group");
                    if not this.ScenarioVATProdPostingGroups.Contains(Item."VAT Prod. Posting Group") then
                        this.ScenarioVATProdPostingGroups.Add(Item."VAT Prod. Posting Group");
                end;
            until OrderLine.Next() = 0;
    end;

    local procedure EnsureGeneralPostingSetupForBusinessGroup(Shop: Record "Shpfy Shop"; GenBusPostingGroup: Code[20])
    var
        ItemTemplate: Record "Item Templ.";
        RefundAccount: Record "G/L Account";
        GenProdPostingGroup: Code[20];
    begin
        ItemTemplate.Get(Shop."Item Templ. Code");
        this.EnsureGeneralPostingSetup(GenBusPostingGroup, ItemTemplate."Gen. Prod. Posting Group");
        RefundAccount.Get(Shop."Refund Account");
        this.EnsureGeneralPostingSetup(GenBusPostingGroup, RefundAccount."Gen. Prod. Posting Group");
        foreach GenProdPostingGroup in this.ScenarioGenProdPostingGroups do
            this.EnsureGeneralPostingSetup(GenBusPostingGroup, GenProdPostingGroup);
    end;

    local procedure EnsureVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        TmpltVATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then begin
            // Reuse the product group's existing VAT rate when available so created documents keep realistic amounts.
            TmpltVATPostingSetup.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
            TmpltVATPostingSetup.SetFilter("VAT Calculation Type", '<>%1', TmpltVATPostingSetup."VAT Calculation Type"::"Sales Tax");
            if TmpltVATPostingSetup.FindFirst() then
                VATPostingSetup := TmpltVATPostingSetup
            else begin
                VATPostingSetup.Init();
                VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
                VATPostingSetup."VAT Identifier" := CopyStr(VATProdPostingGroup, 1, MaxStrLen(VATPostingSetup."VAT Identifier"));
            end;
            VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
            VATPostingSetup."VAT Prod. Posting Group" := VATProdPostingGroup;
            VATPostingSetup.Insert();
        end;

        if (VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Sales Tax") and
           (VATPostingSetup."Sales VAT Account" = '')
        then begin
            VATPostingSetup.Validate("Sales VAT Account", this.LibraryERM.CreateGLAccountNo());
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure DisablePostingSetupNotification()
    var
        MyNotifications: Record "My Notifications";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        // Missing G/L account notifications come from shared test posting setups and are unrelated to the VAT prompts asserted here.
        if MyNotifications.Get(UserId(), PostingSetupManagement.GetPostingSetupNotificationID()) then begin
            MyNotifications.Enabled := false;
            MyNotifications.Modify();
            exit;
        end;

        MyNotifications.InsertDefault(PostingSetupManagement.GetPostingSetupNotificationID(), '', '', false);
    end;

    local procedure EnsureVATPostingSetupForBusinessGroup(Shop: Record "Shpfy Shop"; VATBusPostingGroup: Code[20])
    var
        ItemTemplate: Record "Item Templ.";
        RefundAccount: Record "G/L Account";
        VATProdPostingGroup: Code[20];
    begin
        ItemTemplate.Get(Shop."Item Templ. Code");
        this.EnsureVATPostingSetup(VATBusPostingGroup, ItemTemplate."VAT Prod. Posting Group");
        RefundAccount.Get(Shop."Refund Account");
        this.EnsureVATPostingSetup(VATBusPostingGroup, RefundAccount."VAT Prod. Posting Group");
        foreach VATProdPostingGroup in this.ScenarioVATProdPostingGroups do
            this.EnsureVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup);
    end;

    local procedure SetVATCustomerPreference(UseBillToVATCustomer: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if UseBillToVATCustomer then
            GeneralLedgerSetup."Bill-to/Sell-to VAT Calc." := GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No."
        else
            GeneralLedgerSetup."Bill-to/Sell-to VAT Calc." := GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.";
        GeneralLedgerSetup.Modify();
    end;

    [ModalPageHandler]
    procedure ManualVATConfirmPageHandler(var ConfirmAltCustVATReg: TestPage "Confirm Alt. Cust. VAT Reg.")
    begin
        this.ManualVATPromptShown := true;
        ConfirmAltCustVATReg.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure RecreateSalesLinesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [HttpClientHandler]
    internal procedure FulfillmentOrdersHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, this.CurrentShop."Shopify URL") then
            exit(true);

        Response.Content.WriteFrom('{"data":{}}');
        exit(false);
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy Alternative VAT Test");
        ClearLastError();
        this.ManualVATPromptShown := false;
        if this.IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy Alternative VAT Test");
        this.IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy Alternative VAT Test");
    end;
}
