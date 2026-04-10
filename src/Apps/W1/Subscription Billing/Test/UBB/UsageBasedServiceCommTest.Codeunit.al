namespace Microsoft.SubscriptionBilling;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;

codeunit 139895 "Usage Based Service Comm. Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    Access = Internal;

    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesServiceCommitment: Record "Sales Subscription Line";
        ServiceCommitmentPackageLine: Record "Subscription Package Line";
        ServiceCommitment: Record "Subscription Line";
        ServiceCommitmentPackage: Record "Subscription Package";
        ServiceCommitmentTemplate: Record "Sub. Package Line Template";
        ContractTestLibrary: Codeunit "Contract Test Library";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        DiscountCannotBeAssignedErr: Label 'Subscription Package Lines, which are discounts, can only be assigned to Subscription Items.', Locked = true;
        RecurringDiscountCannotBeGrantedErr: Label 'Recurring discounts cannot be granted in conjunction with Usage Based Billing', Locked = true;

    #region Tests

    [Test]
    procedure ExpectErrorForSubPackageLineTemplateWhenMarkingDiscountButUsageBasedBillingIsSet()
    begin
        // [SCENARIO] Discount cannot be set for Subscription Package Line Template when Usage Based Billing is active
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Create Subscription Package Line Template and set Usage Based Billing fields
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        UpdateServiceCommitmentTemplateWithUsageBasedFields(ServiceCommitmentTemplate, Enum::"Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(100, 2));

        // [WHEN] Attempting to mark the template as discount
        // [THEN] Expect error for recurring discount
        asserterror ServiceCommitmentTemplate.Validate(Discount, true);
        Assert.ExpectedError(RecurringDiscountCannotBeGrantedErr);
    end;

    [Test]
    procedure ExpectErrorForSubPackageLineTemplateWhenMarkingDiscountButInvoicingItemIsUsed()
    begin
        // [SCENARIO] Discount cannot be set for Subscription Package Line Template when Invoicing Item is used
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Create Subscription Package Line Template and set Invoicing Item
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Invoicing Item");
        ServiceCommitmentTemplate."Invoicing Item No." := Item."No.";

        // [WHEN] Attempting to mark the template as discount
        // [THEN] Expect error for invoicing item
        asserterror ServiceCommitmentTemplate.Validate(Discount, true);
        Assert.ExpectedError(DiscountCannotBeAssignedErr);
    end;

    [Test]
    procedure ExpectErrorForSubPackageLineTemplateWhenMarkingUsageBasedBillingButDiscountIsSet()
    begin
        // [SCENARIO] Usage Based Billing flag cannot be set when Subscription Package Line Template is marked as discount
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Create Subscription Package Line Template and mark it as Discount
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        ServiceCommitmentTemplate.Validate(Discount, true);

        // [WHEN] Attempting to mark the template as Usage Based Billing
        // [THEN] Expect error from Testfield on Discount field
        asserterror ServiceCommitmentTemplate.Validate("Usage Based Billing", true);
    end;

    [Test]
    procedure ExpectErrorForSubscriptionPackageLineWhenMarkingDiscountButUsageBasedBillingIsSet()
    begin
        // [SCENARIO] Discount cannot be set for Subscription Package Line when Usage Based Billing is active
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Create Subscription Package Line and set Usage Based Billing fields
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        UpdateServiceCommitmentTemplateWithUsageBasedFields(ServiceCommitmentTemplate, Enum::"Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(100, 2));
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommitmentPackageLine);

        // [WHEN] Attempting to mark the Package Line as Discount
        // [THEN] Expect error for recurring discount
        asserterror ServiceCommitmentPackageLine.Validate(Discount, true);
        Assert.ExpectedError(RecurringDiscountCannotBeGrantedErr);
    end;

    [Test]
    procedure ExpectErrorForSubscriptionPackageLineWhenMarkingUsageBasedBillingButDiscountIsSet()
    begin
        // [SCENARIO] Usage Based Billing flag cannot be set when Subscription Package Line is marked as discount
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Create Subscription Package Line and mark it as Discount
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommitmentPackageLine);
        ServiceCommitmentPackageLine.Validate(Discount, true);

        // [WHEN] Attempting to mark the Package Line as Usage Based Billing
        // [THEN] Expect error from Testfield on Discount field
        asserterror ServiceCommitmentPackageLine.Validate("Usage Based Billing", true);
    end;

    [Test]
    procedure ErrorOnInsertUsageBasedFieldsToServiceCommitmentTemplateWhenInvoicingViaSales()
    begin
        Initialize();
        ContractTestLibrary.InitContractsApp();
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        ServiceCommitmentTemplate."Invoicing via" := Enum::"Invoicing Via"::Sales;
        ServiceCommitmentTemplate.Modify(false);
        ServiceCommitmentTemplate."Invoicing via" := Enum::"Invoicing Via"::Sales;
        asserterror ServiceCommitmentTemplate.Validate("Usage Based Billing", true);
        asserterror ServiceCommitmentTemplate.Validate("Usage Based Pricing", Enum::"Usage Based Pricing"::"Usage Quantity");
    end;

    [Test]
    procedure ErrorOnInsertUsageBasedFieldsToServiceCommitmentPackageWhenInvoicingViaSales()
    begin
        Initialize();
        ContractTestLibrary.InitContractsApp();
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommitmentPackageLine);
        ServiceCommitmentPackageLine."Invoicing via" := Enum::"Invoicing Via"::Sales;
        asserterror ServiceCommitmentPackageLine.Validate("Usage Based Billing", true);
        asserterror ServiceCommitmentPackageLine.Validate("Usage Based Pricing", Enum::"Usage Based Pricing"::"Usage Quantity");
    end;

    [Test]
    procedure ErrorOnInsertUsageBasedFieldsToSalesServiceCommitmentWhenInvoicingViaSales()
    begin
        Initialize();
        SetupServiceCommitmentTemplateAndServiceCommitmentPackageWithLine();
        UpdateServiceCommitmentTemplateWithUsageBasedFields(ServiceCommitmentTemplate, Enum::"Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(100, 2));
        ServiceCommitmentPackageLine.Validate(Template);
        Evaluate(ServiceCommitmentPackageLine."Billing Rhythm", '<1M>');
        ServiceCommitmentPackageLine.Modify(false);
        SetupSalesServiceCommitmentAndCreateSalesDocument();

        SalesServiceCommitment.FilterOnSalesLine(SalesLine);
        if SalesServiceCommitment.FindSet() then
            repeat
                SalesServiceCommitment."Invoicing via" := Enum::"Invoicing Via"::Sales;
                asserterror SalesServiceCommitment.Validate("Usage Based Billing", true);
                asserterror SalesServiceCommitment.Validate("Usage Based Pricing", Enum::"Usage Based Pricing"::"Usage Quantity");
            until SalesServiceCommitment.Next() = 0;
    end;

    [Test]
    procedure TestTransferUsageBasedFieldsFromServiceCommitmentTemplateToPackageLine()
    begin
        Initialize();
        ContractTestLibrary.InitContractsApp();
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        UpdateServiceCommitmentTemplateWithUsageBasedFields(ServiceCommitmentTemplate, Enum::"Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(100, 2));
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommitmentPackageLine);
        ServiceCommitmentPackageLine.TestField("Usage Based Billing", ServiceCommitmentTemplate."Usage Based Billing");
        ServiceCommitmentPackageLine.TestField("Usage Based Pricing", ServiceCommitmentTemplate."Usage Based Pricing");
        ServiceCommitmentPackageLine.TestField("Pricing Unit Cost Surcharge %", ServiceCommitmentTemplate."Pricing Unit Cost Surcharge %");
    end;

    [Test]
    procedure TestTransferUsageBasedFieldsFromSalesServiceCommitmentToServiceCommitment()
    begin
        Initialize();
        SetupServiceCommitmentTemplateAndServiceCommitmentPackageWithLine();
        UpdateServiceCommitmentTemplateWithUsageBasedFields(ServiceCommitmentTemplate, Enum::"Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(100, 2));
        ServiceCommitmentPackageLine.Validate(Template);
        Evaluate(ServiceCommitmentPackageLine."Billing Rhythm", '<1M>');
        ServiceCommitmentPackageLine.Modify(false);
        CreateAndPostSalesDocumentWithSalesServiceCommitments();

        ServiceCommitment.FindSet();
        repeat
            ServiceCommitment.TestField("Usage Based Billing", ServiceCommitmentTemplate."Usage Based Billing");
            ServiceCommitment.TestField("Usage Based Pricing", ServiceCommitmentTemplate."Usage Based Pricing");
            ServiceCommitment.TestField("Pricing Unit Cost Surcharge %", ServiceCommitmentTemplate."Pricing Unit Cost Surcharge %");
        until ServiceCommitment.Next() = 0;
    end;

    [Test]
    procedure TestTransferUsageBasedFieldsFromServiceCommitmentPackageToSalesServiceCommitment()
    begin
        Initialize();
        SetupServiceCommitmentTemplateAndServiceCommitmentPackageWithLine();
        UpdateServiceCommitmentTemplateWithUsageBasedFields(ServiceCommitmentTemplate, Enum::"Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(100, 2));
        ServiceCommitmentPackageLine.Validate(Template);
        Evaluate(ServiceCommitmentPackageLine."Billing Rhythm", '<1M>');
        ServiceCommitmentPackageLine.Modify(false);
        SetupSalesServiceCommitmentAndCreateSalesDocument();

        SalesServiceCommitment.FilterOnSalesLine(SalesLine);
        SalesServiceCommitment.FindSet();
        repeat
            SalesServiceCommitment.TestField("Usage Based Billing", ServiceCommitmentPackageLine."Usage Based Billing");
            SalesServiceCommitment.TestField("Usage Based Pricing", ServiceCommitmentPackageLine."Usage Based Pricing");
            SalesServiceCommitment.TestField("Pricing Unit Cost Surcharge %", ServiceCommitmentPackageLine."Pricing Unit Cost Surcharge %");
        until ServiceCommitment.Next() = 0;
    end;

    [Test]
    procedure TestUsageBasedFieldsInServiceCommitmentTemplate()
    begin
        Initialize();
        ContractTestLibrary.InitContractsApp();
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        ServiceCommitmentTemplate."Calculation Base %" := LibraryRandom.RandDecInRange(0, 100, 2);
        Evaluate(ServiceCommitmentTemplate."Billing Base Period", '<12M>');
        ServiceCommitmentTemplate.Modify(false);

        ServiceCommitmentTemplate.Validate("Usage Based Billing", true);
        ServiceCommitmentTemplate.Modify(false);
        ServiceCommitmentTemplate.TestField("Usage Based Pricing", "Usage Based Pricing"::"Usage Quantity");

        ServiceCommitmentTemplate.Validate("Usage Based Billing", false);
        ServiceCommitmentTemplate.Modify(false);
        ServiceCommitmentTemplate.TestField("Usage Based Pricing", "Usage Based Pricing"::None);

        ServiceCommitmentTemplate.Validate("Usage Based Pricing", "Usage Based Pricing"::"Unit Cost Surcharge");
        ServiceCommitmentTemplate.Modify(false);
        ServiceCommitmentTemplate.TestField("Usage Based Billing", true);

        ServiceCommitmentTemplate.Validate("Pricing Unit Cost Surcharge %", Random(100));
        ServiceCommitmentTemplate.Validate("Usage Based Pricing", "Usage Based Pricing"::"Fixed Quantity");
        ServiceCommitmentTemplate.Modify(false);
        ServiceCommitmentTemplate.TestField("Pricing Unit Cost Surcharge %", 0);
    end;

    [Test]
    procedure TestUsageBasedFieldsInServiceCommitmentPackageLine()
    begin
        Initialize();
        SetupServiceCommitmentTemplateAndServiceCommitmentPackageWithLine();
        UpdateServiceCommitmentTemplateWithUsageBasedFields(ServiceCommitmentTemplate, Enum::"Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(100, 2));
        ServiceCommitmentPackageLine.Validate(Template);
        Evaluate(ServiceCommitmentPackageLine."Billing Rhythm", '<1M>');
        ServiceCommitmentPackageLine."Usage Based Pricing" := "Usage Based Pricing"::None;
        ServiceCommitmentPackageLine.Modify(false);

        ServiceCommitmentPackageLine.Validate("Usage Based Billing", true);
        ServiceCommitmentPackageLine.Modify(false);
        ServiceCommitmentPackageLine.TestField("Usage Based Pricing", "Usage Based Pricing"::"Usage Quantity");

        ServiceCommitmentPackageLine.Validate("Usage Based Billing", false);
        ServiceCommitmentPackageLine.Modify(false);
        ServiceCommitmentPackageLine.TestField("Usage Based Pricing", "Usage Based Pricing"::None);

        ServiceCommitmentPackageLine.Validate("Usage Based Pricing", "Usage Based Pricing"::"Unit Cost Surcharge");
        ServiceCommitmentPackageLine.Modify(false);
        ServiceCommitmentPackageLine.TestField("Usage Based Billing", true);

        ServiceCommitmentPackageLine.Validate("Pricing Unit Cost Surcharge %", Random(100));
        ServiceCommitmentPackageLine.Validate("Usage Based Pricing", "Usage Based Pricing"::"Fixed Quantity");
        ServiceCommitmentPackageLine.Modify(false);
        ServiceCommitmentPackageLine.TestField("Pricing Unit Cost Surcharge %", 0);
    end;

    [Test]
    procedure TestUsageBasedFieldsInSalesServiceCommitments()
    begin
        Initialize();
        SetupServiceCommitmentTemplateAndServiceCommitmentPackageWithLine();
        UpdateServiceCommitmentTemplateWithUsageBasedFields(ServiceCommitmentTemplate, Enum::"Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(100, 2));
        ServiceCommitmentPackageLine.Validate(Template);
        Evaluate(ServiceCommitmentPackageLine."Billing Rhythm", '<1M>');
        ServiceCommitmentPackageLine.Modify(false);
        SetupSalesServiceCommitmentAndCreateSalesDocument();

        SalesServiceCommitment.FilterOnSalesLine(SalesLine);
        SalesServiceCommitment.FindSet();
        SalesServiceCommitment."Usage Based Pricing" := "Usage Based Pricing"::None;
        SalesServiceCommitment.Modify(false);

        SalesServiceCommitment.Validate("Usage Based Billing", true);
        SalesServiceCommitment.Modify(false);
        SalesServiceCommitment.TestField("Usage Based Pricing", "Usage Based Pricing"::"Usage Quantity");

        SalesServiceCommitment.Validate("Usage Based Billing", false);
        SalesServiceCommitment.Modify(false);
        SalesServiceCommitment.TestField("Usage Based Pricing", "Usage Based Pricing"::None);

        SalesServiceCommitment.Validate("Usage Based Pricing", "Usage Based Pricing"::"Unit Cost Surcharge");
        SalesServiceCommitment.Modify(false);
        SalesServiceCommitment.TestField("Usage Based Billing", true);

        SalesServiceCommitment.Validate("Pricing Unit Cost Surcharge %", Random(100));
        SalesServiceCommitment.Validate("Usage Based Pricing", "Usage Based Pricing"::"Fixed Quantity");
        SalesServiceCommitment.Modify(false);
        SalesServiceCommitment.TestField("Pricing Unit Cost Surcharge %", 0);
    end;

    #endregion Tests

    #region Procedures

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Usage Based Service Comm. Test");
        ClearAll();
    end;

    local procedure CreateAndPostSalesDocumentWithSalesServiceCommitments()
    begin
        SetupSalesServiceCommitmentAndCreateSalesDocument();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure SetupSalesServiceCommitmentAndCreateSalesDocument()
    begin
        ContractTestLibrary.SetupSalesServiceCommitmentItemAndAssignToServiceCommitmentPackage(Item, Enum::"Item Service Commitment Type"::"Sales with Service Commitment", ServiceCommitmentPackage.Code);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, Item."No.", WorkDate(), LibraryRandom.RandInt(100));
    end;

    local procedure SetupServiceCommitmentTemplateAndServiceCommitmentPackageWithLine()
    begin
        ClearAll();
        ContractTestLibrary.InitContractsApp();
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Invoicing Item");
        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate);
        ServiceCommitmentTemplate."Invoicing Item No." := Item."No.";
        ServiceCommitmentTemplate."Calculation Base %" := LibraryRandom.RandDecInRange(0, 100, 2);
        Evaluate(ServiceCommitmentTemplate."Billing Base Period", '<12M>');
        ServiceCommitmentTemplate.Modify(false);
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(ServiceCommitmentTemplate.Code, ServiceCommitmentPackage, ServiceCommitmentPackageLine);
        UpdateServiceCommitmentPackageLineFields();
    end;

    local procedure UpdateServiceCommitmentPackageLineFields()
    begin
        Evaluate(ServiceCommitmentPackageLine."Billing Rhythm", '<1M>');
        Evaluate(ServiceCommitmentPackageLine."Sub. Line Start Formula", '<CY>');
        Evaluate(ServiceCommitmentPackageLine."Initial Term", '<12M>');
        Evaluate(ServiceCommitmentPackageLine."Extension Term", '<12M>');
        Evaluate(ServiceCommitmentPackageLine."Notice Period", '<1M>');
        ServiceCommitmentPackageLine.Modify(false);
    end;

    procedure UpdateServiceCommitmentTemplateWithUsageBasedFields(var ServiceCommitmentTemplate2: Record "Sub. Package Line Template"; UsageBasedPricing: Enum "Usage Based Pricing"; PricingUnitCostSurchargePercentage: Decimal)
    begin
        ServiceCommitmentTemplate2."Usage Based Billing" := true;
        ServiceCommitmentTemplate2."Usage Based Pricing" := UsageBasedPricing;
        ServiceCommitmentTemplate2."Pricing Unit Cost Surcharge %" := PricingUnitCostSurchargePercentage;
        ServiceCommitmentTemplate2.Modify(false);
    end;

    #endregion Procedures
}
