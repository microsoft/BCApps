namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.IO;
using System.TestLibraries.Utilities;

#pragma warning disable AA0210
codeunit 148153 "Usage Based Billing Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        BillingLine: Record "Billing Line";
        BillingTemplate: Record "Billing Template";
        Currency: Record Currency;
        Customer: Record Customer;
        CustomerContract: Record "Customer Subscription Contract";
        CustomerContractLine: Record "Cust. Sub. Contract Line";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        GenericImportSettings: Record "Generic Import Settings";
        Item: Record Item;
        ItemServCommitmentPackage: Record "Item Subscription Package";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCrMemoHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SubscriptionPackageLine: Record "Subscription Package Line";
        SubscriptionLine: Record "Subscription Line";
        SubscriptionPackage: Record "Subscription Package";
        SubPackageLineTemplate: Record "Sub. Package Line Template";
        SubscriptionHeader: Record "Subscription Header";
        UsageDataBlob: Record "Usage Data Blob";
        UsageDataCustomer: Record "Usage Data Supp. Customer";
        UsageDataImport: Record "Usage Data Import";
        UsageDataSubscription: Record "Usage Data Supp. Subscription";
        UsageDataSupplier: Record "Usage Data Supplier";
        UsageDataSupplierReference: Record "Usage Data Supplier Reference";
        Vendor: Record Vendor;
        VendorContract: Record "Vendor Subscription Contract";
        VendorContractLine: Record "Vend. Sub. Contract Line";
        Assert: Codeunit Assert;
        ContractTestLibrary: Codeunit "Contract Test Library";
        CorrectPostedPurchaseInvoice: Codeunit "Correct Posted Purch. Invoice";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        UsageBasedBTestLibrary: Codeunit "Usage Based B. Test Library";
        UsageBasedDocTypeConverter: Codeunit "Usage Based Doc. Type Conv.";
        RRef: RecordRef;
        IsInitialized: Boolean;
        LimitUsageBasedBillingPeriodToFirstMonth: Boolean;
        PostDocument: Boolean;
        CreditedQtyExceedsSubscribedQtyErr: Label 'The usage data for Subscription %1 adds up to a quantity of %2, which credits more than the quantity of %3 that is currently subscribed.', Locked = true;
        CorrectedDocumentNo: Code[20];
        i: Integer;
        j: Integer;
        ColumnSeparator: Option " ",Tab,Semicolon,Comma,Space,Custom;
        FileEncoding: Option "MS-DOS","UTF-8","UTF-16",WINDOWS;
        FileType: Option Xml,"Variable Text","Fixed Text",Json;
        BillingLineAmountMismatchLbl: Label 'Billing Line Amount should be equal to the total Usage Data Billing Amount.', Locked = true;
        BillingLineNotLinkedToUsageDataLbl: Label 'Usage Data Billing should be linked to the Billing Line it was billed in.', Locked = true;
        BillingLineStartDateLbl: Label 'Billing Line should start at the earliest Charge Start Date.', Locked = true;
        BillingLineStretchedEndDateLbl: Label 'Billing Line should be stretched to the Charge End Date of the crossing usage entry.', Locked = true;
        BillingLineRhythmEndDateLbl: Label 'Billing Line should end at the billing rhythm period end.', Locked = true;
        FirstBillingLineEndDateLbl: Label 'First Billing Line should end at the first rhythm period end.', Locked = true;
        FirstBillingLineStartDateLbl: Label 'First Billing Line should start at the first Charge Start Date.', Locked = true;
        NextBillingDateLbl: Label 'Next Billing Date should follow the stretched billing period.', Locked = true;
        SecondBillingLineEndDateLbl: Label 'Second Billing Line should end at the second rhythm period end.', Locked = true;
        SecondBillingLineStartDateLbl: Label 'Second Billing Line should start at the second rhythm period start.', Locked = true;

    #region Tests

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure ApplyServiceCommitmentDiscountInContractInvoice()
    var
        UsageDataBilling: Record "Usage Data Billing";
        DiscountPct: Decimal;
    begin
        // [SCENARIO] Check that discount from Subscription Line is applied in the invoice and usage data is updated accordingly

        // [GIVEN] Create Subscription Item
        Initialize();
        CreateSubscriptionItemWithPrices(LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Setup Subscription with Subscription Lines and usage quantity
        SetupServiceDataForProcessing(Enum::"Usage Based Pricing"::"Usage Quantity", "Calculation Base Type"::"Item Price", Enum::"Invoicing Via"::Contract,
                                       '1Y', '1Y', '1Y', "Service Partner"::Customer, 100, Item."No.");

        // [GIVEN] Add discount to Subscription Line
        DiscountPct := LibraryRandom.RandDec(99, 2);
        SubscriptionLine.Reset();
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.FindSet();
        repeat
            SubscriptionLine.Validate("Discount %", DiscountPct);
            SubscriptionLine.Modify(false);
        until SubscriptionLine.Next() = 0;

        // [WHEN] Create and process simple usage data
        ProcessUsageDataWithSimpleGenericImport(WorkDate(), WorkDate(), WorkDate(), CalcDate('<CM>', WorkDate()), 1);

        // [WHEN] Create contract invoice from usage data - discount should be applied
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [THEN] Expect that discount is not applied in the Usage data, but in the invoice
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        UsageDataBilling.FindFirst();

        BillingLine.FilterBillingLineOnContractLine(UsageDataBilling.Partner, UsageDataBilling."Subscription Contract No.", UsageDataBilling."Subscription Contract Line No.");
        BillingLine.FindSet();
        repeat
            BillingLine.TestField("Discount %", DiscountPct);
        until BillingLine.Next() = 0;

        // [THEN] Test that prices Subscription Line is not updated
        CheckIfServiceCommitmentRemains(UsageDataBilling);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocsContractPageHandler,ConfirmHandler')]
    procedure CheckIfCreditMemoIsCreatedWhenDiscountInServiceCommitmentIs100Percent()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        //[SCENARIO]: Create service object with two service commitments; One has discount 100%, and the other one is marked as discount; Test that credit memo is created on recurring billing

        ClearAll();
        ContractTestLibrary.InitContractsApp();

        //[GIVEN]: Create service commitment Item
        CreateSubscriptionItemWithPrices(LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));

        //[GIVEN]: Setup service object with service commitments and usage quantity
        ContractTestLibrary.CreateServiceCommitmentTemplate(SubPackageLineTemplate);
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(SubPackageLineTemplate.Code, SubscriptionPackage, SubscriptionPackageLine);
        ContractTestLibrary.UpdateServiceCommitmentPackageLine(SubscriptionPackageLine, '1M', 100, '1M', '1M', "Service Partner"::Customer, '');
        SubscriptionPackageLine."Usage Based Billing" := true;
        SubscriptionPackageLine."Usage Based Pricing" := "Usage Based Pricing"::"Usage Quantity";
        SubscriptionPackageLine."Calculation Base Type" := "Calculation Base Type"::"Item Price";
        SubscriptionPackageLine.Modify();
        ContractTestLibrary.CreateServiceCommitmentPackageLine(SubscriptionPackageLine."Subscription Package Code", SubscriptionPackageLine.Template, SubscriptionPackageLine,
                                                                 '1M', '1M', "Service Partner"::Customer);
        SubscriptionPackageLine.Discount := true;
        SubscriptionPackageLine."Calculation Base Type" := "Calculation Base Type"::"Item Price";
        SubscriptionPackageLine.Modify(true);
        ContractTestLibrary.AssignItemToServiceCommitmentPackage(Item, SubscriptionPackage.Code);
        ItemServCommitmentPackage.Get(Item."No.", SubscriptionPackage.Code);
        ItemServCommitmentPackage.Standard := true;
        ItemServCommitmentPackage.Modify(false);

        LibrarySales.CreateCustomer(Customer);
        ContractTestLibrary.CreateServiceObjectForItem(SubscriptionHeader, Item."No.");
        SubscriptionHeader.InsertServiceCommitmentsFromStandardServCommPackages(WorkDate());
        SubscriptionHeader."End-User Customer No." := Customer."No.";
        SubscriptionHeader.Validate(Quantity, 1); //mock service object quantity to avoid issues with rounding
        SubscriptionHeader.Modify(false);
        CreateCustomerContractAndAssignServiceCommitments();

        //[GIVEN]: Add discount to service commitment
        SubscriptionLine.Reset();
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.findset();
        repeat
            if SubscriptionLine.Discount = false then
                SubscriptionLine.Validate("Discount Amount", SubscriptionLine.Amount) //Rounding issue; Make sure that the Discount amount is equal to Service Amount
            else
                SubscriptionLine.Validate(Price, LibraryRandom.RandDec(1000, 2));
            SubscriptionLine.Modify();
        until SubscriptionLine.Next() = 0;

        //[WHEN]: Create and process simple usage data
        ProcessUsageDataWithSimpleGenericImport(WorkDate(), WorkDate(), WorkDate(), CalcDate('<CM>', WorkDate()), 1);

        //[WHEN]: Create contract invoice discounts should be applied - therefore credit memo should be created
        ContractTestLibrary.CreateRecurringBillingTemplate(BillingTemplate, '', '', CustomerContract.GetView(), Enum::"Service Partner"::Customer);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);
        BillingLine.SetRange("Billing Template Code", BillingTemplate.Code);
        BillingLine.SetRange(Partner, BillingTemplate.Partner);
        Codeunit.Run(Codeunit::"Create Billing Documents", BillingLine);

        //[THEN]: Test that credit memo is created
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::"Credit Memo");
        Assert.RecordIsNotEmpty(UsageDataBilling);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ClosingUsageDataImportPreventsProcessing()
    begin
        // [SCENARIO] A closed Usage Data Import is not processed any more

        // [GIVEN] Usage Data Billing created for an import
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));

        // [WHEN] The import is closed
        UsageDataImport.SetRecFilter();
        UsageDataImport.CloseUsageDataImports(UsageDataImport);

        // [THEN] The import is marked as Closed
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Closed);

        // [THEN] Processing the import is rejected
        UsageDataImport.SetRecFilter();
        asserterror UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        Assert.ExpectedError(UsageDataImport.FieldCaption("Processing Status"));
    end;

    [Test]
    procedure CostAmountDeliveredWithoutUnitCostIsNotProratedAgain()
    var
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A supplier that delivers only a Cost Amount states the cost of the charge period itself. The Unit
        // Cost derived from it is already an amount for the charge period and must not be prorated to it a second time.

        // [GIVEN] A yearly Subscription priced by a unit cost surcharge of 10 %
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);

        // [GIVEN] Usage data for October to December with a quantity of 3000, a Cost Amount of 1000 and no Unit Cost.
        // The Unit Cost derived from it is rounded to 0.33333, which no longer multiplies back to the delivered amount.
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 3000, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 0, 1000, '');

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged the delivered Cost Amount
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(1000, VendorUsageDataBilling."Cost Amount", 'A Cost Amount delivered for the charge period must be charged to the vendor unchanged.');
    end;

    [Test]
    procedure CostAmountDeliveredWithoutUnitCostKeepsItsSign()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        VendorPriceBeforeProcessing: Decimal;
    begin
        // [SCENARIO] A Cost Amount the supplier delivers keeps its sign, also when it does not match the sign of the
        // quantity. Such a negative cost cannot be taken over as the Price of the vendor Subscription Line, which must
        // not be negative, and must not stop the processing either.

        // [GIVEN] A yearly Subscription priced by a unit cost surcharge of 10 %
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorPriceBeforeProcessing := VendorSubscriptionLine.Price;

        // [GIVEN] Usage data for October to December with a quantity of 1, a Cost Amount of -50 and no Unit Cost
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 1, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 0, -50, '');

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The usage data billing is processed without an error
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        // [THEN] The vendor is charged the delivered Cost Amount with its sign
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(-50, VendorUsageDataBilling."Cost Amount", 'A delivered Cost Amount must keep its sign.');

        // [THEN] The vendor Subscription Line does not take over a negative Price
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(VendorPriceBeforeProcessing, VendorSubscriptionLine.Price, 'A negative cost must not change the Price of the vendor Subscription Line.');
    end;

    [Test]
    procedure CostAmountDeliveredWithUnitCostIsKeptForVendorSubscriptionLine()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A supplier that delivers a Cost Amount states what it charges for the charge period, even when it
        // also delivers a Unit Cost. The vendor is charged that Cost Amount, not one recalculated from the Unit Cost,
        // and the vendor Price is derived from that Cost Amount.

        // [GIVEN] A yearly Subscription with a customer and a vendor Subscription Line, both usage based
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [GIVEN] Usage data for October to December with a quantity of 5, a Unit Cost of 10 and a Cost Amount of 45
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 5, 0, "Usage Based Pricing"::"Usage Quantity", 10, 45, '');

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged the delivered Cost Amount
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(45, VendorUsageDataBilling."Cost Amount", 'A Cost Amount delivered by the supplier must be charged to the vendor unchanged.');

        // [THEN] The vendor Subscription Line costs that Cost Amount per year: 45 / 5 units * 365 / 92 days = 35.70652.
        // The ratio of days has no exact decimal representation, so the Price is compared to five decimals.
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreNearlyEqual(35.70652, VendorSubscriptionLine.Price, 0.00001, 'The vendor Price must be derived from the delivered Cost Amount per Billing Base Period.');
    end;

    [Test]
    procedure CreditAtOlderUnitCostDoesNotRepriceVendorSubscriptionLine()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A credit refers to what was charged before and does not state a new price. A credit at the Unit
        // Cost before a price raise must leave the raised cost on the vendor Subscription Line.

        // [GIVEN] A yearly Subscription with a quantity of 10, billed from usage data for the whole year at a supplier
        // Unit Cost of 1200
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [GIVEN] Usage data crediting October to December at the former supplier Unit Cost of 1000
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Usage Quantity", 1000, 0, '');

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Subscription Line keeps its Price of 1200
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(1200, VendorSubscriptionLine.Price, 'A credit must not change the Price of the vendor Subscription Line.');
    end;

    [Test]
    procedure CreditCoveredBySubscribedQuantityIsProcessedWithoutError()
    begin
        // [SCENARIO] Crediting a quantity that is covered by the quantity currently subscribed is legitimate and must
        // neither be reported nor stop the processing. The Subscription keeps the quantity it is subscribed with.

        // [GIVEN] A yearly Subscription with a quantity of 10, billed from usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        // [WHEN] Usage data crediting the full subscribed quantity is processed
        ProcessYearlyUsageDataImport(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10);

        // [THEN] The usage data billing is processed without an error
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        // [THEN] The Subscription keeps its quantity - a credit does not state a new subscribed quantity
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(10, SubscriptionHeader.Quantity, 'The credit must not change the quantity of the Subscription.');
    end;

    [Test]
    procedure CreditDeliveredWithCostAmountIsKeptForVendorSubscriptionLine()
    var
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A supplier that credits the cancelled months with a Cost Amount has already prorated the credit to
        // the charge period. The vendor is credited that Cost Amount and not one prorated a second time.

        // [GIVEN] A yearly Subscription with a quantity of 10, billed from usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        // [WHEN] Usage data crediting October to December with a Unit Cost of 1200 and a Cost Amount of -3000 is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, -3000, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is credited the delivered Cost Amount
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(-3000, VendorUsageDataBilling."Cost Amount", 'A credit delivered as Cost Amount must be credited to the vendor unchanged.');
    end;

    [Test]
    procedure CreditDoesNotChangeUnitCostOfCustomerSubscriptionLine()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A credit does not state a new cost. The customer Subscription Line keeps the Unit Cost it took over
        // from the delivery, also when the supplier credits at another Unit Cost.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose customer Subscription Line took over the supplier
        // Unit Cost of 365 per year from usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(365, CustomerSubscriptionLine."Unit Cost", 'The customer Subscription Line must take over the supplier Unit Cost of the delivery.');

        // [WHEN] Usage data crediting all 10 for October to December at a supplier Unit Cost of 1200 per year is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The usage data is processed without an error and the customer Subscription Line keeps its Unit Cost
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(365, CustomerSubscriptionLine."Unit Cost", 'A credit must not change the Unit Cost of the customer Subscription Line.');
    end;

    [Test]
    procedure CreditExceedingSubscribedQuantityAfterDeliveryInSameImportIsReported()
    var
        UsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        ExpectedReason: Text;
    begin
        // [SCENARIO] A delivery in an earlier charge period of an import does not cover a credit of a later charge period
        // that exceeds the subscribed quantity, because each charge period is billed on its own.

        // [GIVEN] A yearly Subscription with a quantity of 10, billed from usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        // [GIVEN] One import with usage data delivering 10 for October and crediting 15 for November
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 10, 2026), 10);
        AddUsageDataBillingForChargePeriod(DMY2Date(1, 11, 2026), DMY2Date(30, 11, 2026), -15);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] All usage data billing of the import reports that the credit of November exceeds the subscribed quantity
        ExpectedReason := StrSubstNo(CreditedQtyExceedsSubscribedQtyErr, SubscriptionHeader."No.", -15, 10);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        Assert.RecordCount(UsageDataBilling, 4);
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField("Processing Status", "Processing Status"::Error);
            Assert.AreEqual(ExpectedReason, UsageDataBilling.GetReason(), 'The usage data billing must state that the credit of November exceeds the subscribed quantity.');
        until UsageDataBilling.Next() = 0;
    end;

    [Test]
    procedure CreditExceedingSubscribedQuantityInEarlierChargePeriodIsReported()
    var
        UsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        ExpectedReason: Text;
    begin
        // [SCENARIO] Each charge period of an import is billed on its own. A credit of one charge period that exceeds
        // the subscribed quantity must be reported also when a later charge period of the same import delivers a
        // quantity again.

        // [GIVEN] A yearly Subscription with a quantity of 10, billed from usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        // [GIVEN] One import with usage data crediting 15 for October and delivering 10 for November
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 10, 2026), -15);
        AddUsageDataBillingForChargePeriod(DMY2Date(1, 11, 2026), DMY2Date(30, 11, 2026), 10);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] All usage data billing of the import reports that the credit of October exceeds the subscribed quantity
        ExpectedReason := StrSubstNo(CreditedQtyExceedsSubscribedQtyErr, SubscriptionHeader."No.", -15, 10);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        Assert.RecordCount(UsageDataBilling, 4);
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField("Processing Status", "Processing Status"::Error);
            Assert.AreEqual(ExpectedReason, UsageDataBilling.GetReason(), 'The usage data billing must state that the credit of October exceeds the subscribed quantity.');
        until UsageDataBilling.Next() = 0;

        // [THEN] The Subscription keeps its quantity
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(10, SubscriptionHeader.Quantity, 'A credit exceeding the subscribed quantity must not change the quantity of the Subscription.');
    end;

    [Test]
    procedure CreditExceedingSubscribedQuantityIsReported()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Crediting more than the quantity currently subscribed is not covered by what was delivered. It is
        // reported on the usage data billing lines of the Subscription, as the module reports other faulty lines, and
        // the processing of the import is not aborted.

        // [GIVEN] A yearly Subscription with a quantity of 10, billed from usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine.Modify(false);

        // [WHEN] Usage data crediting 15 of the 10 subscribed is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -15);
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] Both usage data billing lines report the credit, and the Subscription and its lines are unchanged
        AssertCreditExceedingSubscribedQuantityIsReported(-15, 10, VendorSubscriptionLine.Price);
    end;

    [Test]
    procedure CreditExceedingSubscribedQuantityIsReportedForRebilling()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Once the first delivery is invoiced, a credit for the same charge end date is rebilling, and the
        // subscribed quantity is added back to the delivered quantity. That correction is our own bookkeeping and
        // must not turn a credit that exceeds the subscription into one that looks covered.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose usage data for the whole year is invoiced
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);
        MarkUsageDataBillingMetadataAsInvoiced();
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine.Modify(false);

        // [WHEN] Usage data crediting 15 of the 10 subscribed is processed as rebilling
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -15);
        AssertUsageDataBillingIsRebilling();
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The credit is reported on the delivered quantity, not on the rebilling-corrected one
        AssertCreditExceedingSubscribedQuantityIsReported(-15, 10, VendorSubscriptionLine.Price);
    end;

    [Test]
    procedure CreditExceedingSubscribedQuantityOnOneSubscriptionLineDoesNotStopTheOther()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] The credit is checked per Subscription Line. A Subscription Line whose credit exceeds the
        // subscribed quantity is reported, while the other usage data billing of the import is processed.

        // [GIVEN] A yearly Subscription with a quantity of 10, billed from usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        // [GIVEN] Usage data that credits 15 to the customer Subscription Line and 5 to the vendor Subscription Line
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -15);
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.FindFirst();
        VendorUsageDataBilling.Quantity := -5;
        VendorUsageDataBilling.Modify(false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] Only the customer usage data billing reports the credit; the vendor usage data billing is processed
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.FindFirst();
        CustomerUsageDataBilling.TestField("Processing Status", "Processing Status"::Error);
        VendorUsageDataBilling.Get(VendorUsageDataBilling."Entry No.");
        VendorUsageDataBilling.TestField("Processing Status", "Processing Status"::Ok);
    end;

    [Test]
    procedure CreditForQuarterIsCreditedThreeTwelfthsForMonthlyVendorBillingRhythm()
    var
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] The supplier states its Unit Cost per Billing Base Period. A vendor Subscription Line priced per
        // year and billed monthly is credited three twelfths of the supplier Unit Cost for a credit of three months,
        // not the whole Unit Cost.

        // [GIVEN] A Subscription with a quantity of 10, whose vendor Subscription Line is priced per year and billed
        // monthly, billed from usage data for the whole year at a supplier Unit Cost of 1200 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        SetBillingRhythmOnSubscriptionLine("Service Partner"::Vendor, '<1M>');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [GIVEN] Usage data crediting the quantity of 10 for October to December at the same supplier Unit Cost
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        SetBillingRhythmOnSubscriptionLine("Service Partner"::Vendor, '<1M>');

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is credited three twelfths of the supplier Unit Cost for each unit: -(1200 * 3 / 12 * 10)
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(-3000, VendorUsageDataBilling."Cost Amount", 'The Cost Amount credited to the vendor Subscription Line must cover the three Billing Rhythms of the charge period.');
    end;

    [Test]
    procedure CreditForSupplierChargePeriodIsProratedForVendorSubscriptionLine()
    var
        VendorUsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] A Subscription billed yearly in advance is cancelled after nine months. The supplier delivers usage
        // data for the remaining three months with a negative quantity. The Subscription Line of the vendor must be
        // credited for those three months only, not for the whole year.

        // [GIVEN] A yearly Subscription with a customer and a vendor Subscription Line, both usage based, and a
        // supplier Unit Cost of 365 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [GIVEN] Usage data for the whole year has been imported and processed
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        // [WHEN] Usage data crediting the last three months is processed
        ProcessYearlyUsageDataImport(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10);

        // [THEN] Only the supplier charge period is credited on the vendor side: 92 of 365 days, 92 per unit
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(-920, VendorUsageDataBilling."Cost Amount", 'The Cost Amount credited to the vendor Subscription Line does not cover the supplier charge period.');
    end;

    [Test]
    procedure CustomerCostAmountDeliveredBySupplierIsKept()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A supplier that delivers a Cost Amount has already calculated the cost of the charge period. The
        // customer usage data keeps that Cost Amount, like the vendor usage data.

        // [GIVEN] A yearly Subscription with a quantity of 10 and a customer and a vendor Subscription Line
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [WHEN] Usage data for October to December with a Unit Cost of 365 and a Cost Amount of 1000 is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 365, 1000, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer usage data keeps the delivered Cost Amount, not the 920 that the Unit Cost amounts to for 92 of 365 days
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(1000, CustomerUsageDataBilling."Cost Amount", 'A delivered Cost Amount must be kept for the customer usage data.');
    end;

    [Test]
    procedure CustomerCostAmountFromUnitCostCoversChargePeriod()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] The Amount of customer usage data covers the charge period. Its Cost Amount must cover the same
        // period, so that the sales document shows the cost that belongs to the amount it charges.

        // [GIVEN] A yearly Subscription with a quantity of 10 and a customer and a vendor Subscription Line, and a
        // supplier Unit Cost of 365 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [WHEN] Usage data covering only October to December is processed
        ProcessYearlyUsageDataImport(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10);

        // [THEN] The customer usage data costs the supplier Unit Cost for 92 of 365 days: 92 per unit, not the 3650 of the whole year
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(920, CustomerUsageDataBilling."Cost Amount", 'The Cost Amount of the customer usage data does not cover the charge period.');
    end;

    [Test]
    procedure CustomerCostAmountFromUnitCostCoversChargePeriodWhenUnitPriceIsFromImport()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A supplier that delivers the Unit Price leaves the price of the customer usage data as imported.
        // The Cost Amount is still calculated for the charge period from the supplier Unit Cost.

        // [GIVEN] Usage data for October to December with a supplier Unit Cost of 365 per year, from a supplier that
        // delivers the Unit Price
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10);
        UsageDataSupplier."Unit Price from Import" := true;
        UsageDataSupplier.Modify(false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer usage data costs the supplier Unit Cost for 92 of 365 days: 92 per unit
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(920, CustomerUsageDataBilling."Cost Amount", 'The Cost Amount of the customer usage data does not cover the charge period.');
    end;

    [Test]
    procedure CustomerCostAmountOfCreditCoversChargePeriod()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A credit for part of a Billing Base Period credits the customer the price of the charge period. The
        // Cost Amount of the customer usage data is credited for the same period, with the sign of the credited quantity.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose usage data for the whole year is processed
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        // [WHEN] Usage data crediting all 10 for October to December at a supplier Unit Cost of 1200 per year is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer usage data is credited the cost of 92 of 365 days: -(1200 * 92 / 365 * 10) = -3024.66,
        // not the -12000 of the whole year
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(-3024.66, CustomerUsageDataBilling."Cost Amount", 'The Cost Amount credited on the customer usage data does not cover the charge period.');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure CustomerCurrencyMismatchErrorWhenNotAllowed()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
        ContractType: Record "Subscription Contract Type";
        CustomerCurrencyMismatchErr: Label 'Customer Subscription Contract %1 uses Currency Code %2, while the usage data contains amounts in %3. Please update the currency in the contract or move the Subscription line to a contract with this currency before reprocessing the usage data import.', Locked = true;
    begin
        // [SCENARIO] When customer contract currency differs from usage data and "Allow Diff. Curr. in Usage Data" is false, error status is set

        // [GIVEN] Setup usage data and service objects
        Initialize();
        SetupUsageDataForProcessingToGenericImport(WorkDate(), CalcDate('<CM>', WorkDate()), WorkDate(), CalcDate('<CM>', WorkDate()), LibraryRandom.RandDec(10, 2), true);
        SetupDataExchangeDefinition();
        SetupServiceObjectAndContracts(WorkDate());

        // [GIVEN] Create contract type that does not allow different customer currencies
        ContractTestLibrary.CreateContractType(ContractType);
        ContractType."Allow Diff. Curr. in Cust. UD" := false;
        ContractType.Modify(false);

        // [GIVEN] Set customer contract to use a different currency than the import data
        CustomerContract."Contract Type" := ContractType.Code;
        CustomerContract.Modify(false);

        // [GIVEN] Connect and process imported lines, create Usage Data Billing
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, "Usage Based Pricing"::"Usage Quantity");
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);

        // [WHEN] Create Usage Data Billing (customer currency check happens here)
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");

        // [THEN] Customer billing records should have error status due to currency mismatch
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Partner, "Service Partner"::Customer);
        UsageDataBilling.FindFirst();
        UsageDataBilling.TestField("Processing Status", Enum::"Processing Status"::Error);
        Assert.AreEqual(
            StrSubstNo(CustomerCurrencyMismatchErr, CustomerContract."No.", CustomerContract."Currency Code", UsageDataBilling."Currency Code"),
            UsageDataBilling.GetReason(),
            'Error reason should match customer currency mismatch message');
    end;

    [Test]
    procedure CustomerSubscriptionLineUnitCostIsComparedPerBillingBasePeriod()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] The supplier Unit Cost per Billing Base Period is compared with the Unit Cost of the customer
        // Subscription Line, not with what that Unit Cost amounts to for the shorter charge period.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose customer Subscription Line has a Unit Cost of
        // 1448.09783 per year. For 92 of 365 days that amounts to 365, the Unit Cost the supplier states per year.
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        CustomerSubscriptionLine."Unit Cost" := 1448.09783;
        CustomerSubscriptionLine.Modify(false);

        // [WHEN] Usage data for October to December with a supplier Unit Cost of 365 per year is processed
        ProcessYearlyUsageDataImport(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10);

        // [THEN] The customer Subscription Line takes over the supplier Unit Cost per year
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(365, CustomerSubscriptionLine."Unit Cost", 'The supplier Unit Cost must be compared with the Unit Cost of the customer Subscription Line per Billing Base Period.');
    end;

    [Test]
    procedure CustomerSubscriptionLineUnitCostIsDerivedFromDeliveredCostAmountPerBillingBasePeriod()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Both the Price and the Unit Cost of a Subscription Line are stated per Billing Base Period. A Cost
        // Amount that the supplier delivers for part of a year reaches the customer Subscription Line as the cost per
        // unit and year, on the same basis as the Price that "Unit Cost Surcharge" derives from it.

        // [GIVEN] A yearly Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);

        // [WHEN] Usage data for October to December with a delivered Cost Amount of 1000 is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 365, 1000, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer Subscription Line costs the Cost Amount per unit and year: 1000 / (10 * 92 / 365) = 396.74,
        // not the 100 per unit of the charge period
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreNearlyEqual(396.74, CustomerSubscriptionLine."Unit Cost", 0.01, 'The customer Subscription Line must take over the delivered cost per Billing Base Period.');

        // [THEN] Its Price is the surcharge on that Unit Cost: 396.74 * 1.1 = 436.41
        Assert.AreNearlyEqual(436.41, CustomerSubscriptionLine.Price, 0.01, 'The Price of the customer Subscription Line must be the surcharge on its Unit Cost.');
    end;

    [Test]
    procedure CustomerSubscriptionLineUnitCostIsStoredPerBillingBasePeriod()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Both the Price and the Unit Cost of a Subscription Line are stated per Billing Base Period. When usage
        // data for part of a year brings a new supplier Unit Cost, the customer Subscription Line takes over the Unit
        // Cost itself, not the cost of the shorter charge period.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose customer Subscription Line has a Unit Cost of 365 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        CustomerSubscriptionLine."Unit Cost" := 365;
        CustomerSubscriptionLine.Modify(false);

        // [WHEN] Usage data for October to December with a supplier Unit Cost of 1200 per year is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer Subscription Line costs 1200 per year, not the 302.47 that one unit costs for October to December
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(1200, CustomerSubscriptionLine."Unit Cost", 'The customer Subscription Line must take over the supplier Unit Cost per Billing Base Period.');
    end;

    [Test]
    procedure CustomerSubscriptionLineUnitCostIsSupplierUnitCostForWholeBillingBasePeriod()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Usage data covering a whole Billing Base Period passes the supplier Unit Cost on to the customer
        // Subscription Line unchanged.

        // [GIVEN] A yearly Subscription with a quantity of 10 and a customer and a vendor Subscription Line
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [WHEN] Usage data for the whole year with a supplier Unit Cost of 1200 per year is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer Subscription Line costs the supplier Unit Cost
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(1200, CustomerSubscriptionLine."Unit Cost", 'The customer Subscription Line must take over the supplier Unit Cost of a whole Billing Base Period unchanged.');
    end;

    [Test]
    procedure CustomerSubscriptionLineUnitCostIsSupplierUnitCostForWholeBillingBasePeriodWithUnitCostSurcharge()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] With "Unit Cost Surcharge", usage data covering a whole Billing Base Period passes the cost per unit
        // of a delivered Cost Amount on to the customer Subscription Line unchanged.

        // [GIVEN] A yearly Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);

        // [WHEN] Usage data for the whole year with a delivered Cost Amount of 12000 is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 1200, 12000, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer Subscription Line costs the delivered Cost Amount per unit, 12000 / 10, and its Price is
        // the surcharge on it
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(1200, CustomerSubscriptionLine."Unit Cost", 'The customer Subscription Line must take over the delivered cost per unit of a whole Billing Base Period unchanged.');
        Assert.AreEqual(1320, CustomerSubscriptionLine.Price, 'The Price of the customer Subscription Line must be the surcharge on its Unit Cost.');
    end;

    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    [Test]
    procedure DeleteUsageDataBillingLineWhenRelatedPurchCrMemoLineIsDeleted()
    var
        PurchCrMemoHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Creating a corrective purchase credit memo for a contract with two usage-based service commitments, deleting one line, and posting the memo should only create a new usage data billing line for the credited line.
        // [GIVEN] A vendor contract with two usage-based service commitments, both invoiced
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
        PostPurchaseDocuments();
        PurchInvHeader.FindLast();
        CorrectPostedPurchaseInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchCrMemoHeader);

        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchCrMemoHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchCrMemoHeader."No.");
        SalesLine.SetRange(Type, "Sales Line Type"::Item);
        PurchaseLine.FindFirst();

        // Delete the first line (simulate user action)
        PurchaseLine.Delete(true);

        // [THEN] Only the credited line should have a new usage data billing line
        // Check usage data billing lines for the contract
        UsageDataBilling.Reset();
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::"Credit Memo");
        UsageDataBilling.SetRange("Document No.", PurchCrMemoHeader."No.");
        UsageDataBilling.SetRange("Document Line No.", PurchaseLine."Line No.");
        Assert.RecordIsEmpty(UsageDataBilling);
    end;

    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    [Test]
    procedure DeleteUsageDataBillingLineWhenRelatedSalesCrMemoLineIsDeleted()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Creating a corrective credit memo for a contract with two usage-based service commitments, deleting one line, and posting the memo should only create a new usage data billing line for the credited line.
        // [GIVEN] A customer contract with two usage-based service commitments, both invoiced
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer, UsageDataBilling."Document Type"::"Posted Invoice");
        UsageDataBilling.FindFirst();

        SalesInvoiceHeader.Get(UsageDataBilling."Document No.");
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesCrMemoHeader);

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Sales Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesLine.SetRange(Type, "Sales Line Type"::Item);
        SalesLine.FindFirst();

        // Delete the first line (simulate user action)
        SalesLine.Delete(true);

        // [THEN] Only the credited line should have a new usage data billing line
        // Check usage data billing lines for the contract
        UsageDataBilling.Reset();
        UsageDataBilling.SetRange("Document Type", UsageDataBilling."Document Type"::"Credit Memo");
        UsageDataBilling.SetRange("Document No.", SalesCrMemoHeader."No.");
        UsageDataBilling.SetRange("Document Line No.", SalesLine."Line No.");
        Assert.RecordIsEmpty(UsageDataBilling);
    end;

    [Test]
    procedure DeliveryAndCreditCancellingOutInOneImportPausesSubscription()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        PriceBeforeProcessing: Decimal;
        UnitCostBeforeProcessing: Decimal;
    begin
        // [SCENARIO] A delivery and its credit in the same file add up to a quantity of zero. That must not divide by
        // zero. A usage quantity of zero pauses the billing of the Subscription, as any other usage data of quantity
        // zero does, and the Subscription Line keeps its amounts.

        // [GIVEN] A yearly Subscription with a quantity of 10, billed from usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        PriceBeforeProcessing := VendorSubscriptionLine.Price;
        UnitCostBeforeProcessing := VendorSubscriptionLine."Unit Cost";

        // [WHEN] One import delivers 10 and credits 10 for the same charge period
        ProcessYearlyUsageDataImportWithTwoLines(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, -10);

        // [THEN] The usage data billing is processed without an error
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        // [THEN] The Subscription has a quantity of zero and the Subscription Line keeps its amounts
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(0, SubscriptionHeader.Quantity, 'A delivery and its credit cancelling out must set the quantity of the Subscription to zero.');
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(PriceBeforeProcessing, VendorSubscriptionLine.Price, 'A delivery and its credit cancelling out must not change the Price of the Subscription Line.');
        Assert.AreEqual(UnitCostBeforeProcessing, VendorSubscriptionLine."Unit Cost", 'A delivery and its credit cancelling out must not change the Unit Cost of the Subscription Line.');
    end;

    [Test]
    procedure DeriveAmountFromUnitPriceWhenPriceFromImport()
    var
        LocalUsageDataSupplier: Record "Usage Data Supplier";
        UsageDataBilling: Record "Usage Data Billing";
        TestQuantity: Decimal;
        TestUnitPrice: Decimal;
    begin
        // [SCENARIO] When "Unit Price from Import" is enabled and import provides UnitPrice but not Amount, CalculateAmounts derives Amount

        // [GIVEN] A usage data billing record for a customer partner with quantity
        Initialize();
        TestQuantity := LibraryRandom.RandDec(10, 2);
        TestUnitPrice := LibraryRandom.RandDec(100, 2);
        UsageBasedBTestLibrary.CreateUsageDataSupplier(LocalUsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, true, Enum::"Vendor Invoice Per"::Import);

        UsageDataBilling.Init();
        UsageDataBilling.Partner := "Service Partner"::Customer;
        UsageDataBilling.Quantity := TestQuantity;
        UsageDataBilling."Charge End Date" := WorkDate();
        UsageDataBilling.Insert(true);

        // [WHEN] CalculateAmounts is called with UnitPrice but no Amount
        UsageDataBilling.CalculateAmounts(LocalUsageDataSupplier, '', 0, 0, TestUnitPrice, 0);

        // [THEN] Amount is derived from UnitPrice * Quantity, rounded to currency precision
        Assert.AreEqual(Round(TestUnitPrice * TestQuantity, Currency."Amount Rounding Precision"), UsageDataBilling.Amount, 'Amount should be calculated from UnitPrice * Quantity');
        Assert.AreEqual(Round(TestUnitPrice, Currency."Unit-Amount Rounding Precision"), UsageDataBilling."Unit Price", 'Unit Price should be preserved');
    end;

    [Test]
    procedure DeriveUnitPriceFromAmountWhenPriceFromImport()
    var
        LocalUsageDataSupplier: Record "Usage Data Supplier";
        UsageDataBilling: Record "Usage Data Billing";
        TestAmount: Decimal;
        TestQuantity: Decimal;
    begin
        // [SCENARIO] When "Unit Price from Import" is enabled and import provides Amount but not UnitPrice, CalculateAmounts derives UnitPrice

        // [GIVEN] A usage data billing record for a customer partner with quantity
        Initialize();
        TestQuantity := LibraryRandom.RandDec(10, 2);
        TestAmount := LibraryRandom.RandDec(100, 2);
        UsageBasedBTestLibrary.CreateUsageDataSupplier(LocalUsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, true, Enum::"Vendor Invoice Per"::Import);

        UsageDataBilling.Init();
        UsageDataBilling.Partner := "Service Partner"::Customer;
        UsageDataBilling.Quantity := TestQuantity;
        UsageDataBilling."Charge End Date" := WorkDate();
        UsageDataBilling.Insert(true);

        // [WHEN] CalculateAmounts is called with Amount but no UnitPrice
        UsageDataBilling.CalculateAmounts(LocalUsageDataSupplier, '', 0, 0, 0, TestAmount);

        // [THEN] UnitPrice is derived from Amount / Quantity, rounded to currency precision
        Assert.AreEqual(Round(TestAmount / TestQuantity, Currency."Unit-Amount Rounding Precision"), UsageDataBilling."Unit Price", 'Unit Price should be calculated from Amount / Quantity');
        Assert.AreEqual(Round(TestAmount, Currency."Amount Rounding Precision"), UsageDataBilling.Amount, 'Amount should be preserved');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure EnsureUsageDataBillingContainsSubscriptionAndProduct()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Ensure that Usage Data Billing contains Subscription Line Entry No and Product details after processing usage data import

        // [GIVEN] Create Usage data and process it
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Unit Cost Surcharge", LibraryRandom.RandDec(10, 2));

        // [WHEN] Process Usage Data Import
        PostDocument := false;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [THEN] Test that Subscription Line Entry No and Product details are populated in Usage Data Billing
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField("Subscription Line Entry No.");
            SubscriptionLine.Get(UsageDataBilling."Subscription Line Entry No.");
            UsageDataBilling.TestField("Subscription Line Description", SubscriptionLine.Description);
            UsageDataBilling.TestField("Product ID", UsageDataGenericImport."Product ID");
            UsageDataBilling.TestField("Product Name", UsageDataGenericImport."Product Name");
        until UsageDataBilling.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ErrorUsageDataBillingIsNotRecalculatedOnProcessing()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Usage Data Billing marked with Error (currency mismatch) is skipped when processing the Usage Data Billing

        // [GIVEN] Usage Data Billing created for contracts that do not allow a different currency in the usage data
        Initialize();
        CreateUsageDataBillingWithCurrencyMismatch("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));

        // [GIVEN] All created Usage Data Billing lines have Error status and no prices calculated
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        Assert.RecordIsNotEmpty(UsageDataBilling);
        UsageDataBilling.SetFilter("Processing Status", '<>%1', Enum::"Processing Status"::Error);
        Assert.RecordIsEmpty(UsageDataBilling);

        // [WHEN] Process Usage Data Billing
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [THEN] The lines keep the Error status and the prices are not calculated
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField("Processing Status", Enum::"Processing Status"::Error);
            UsageDataBilling.TestField("Unit Price", 0);
            UsageDataBilling.TestField(Amount, 0);
        until UsageDataBilling.Next() = 0;

        // [THEN] The Usage Data Import is in Error as well
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Error);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ErrorUsageDataBillingDoesNotUpdateSubscription()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        ExpectedQuantity: Decimal;
        ExpectedPrice: Decimal;
        ExpectedUnitCost: Decimal;
    begin
        // [SCENARIO] Usage Data Billing marked with Error (currency mismatch) does not update the Subscription and its Subscription Lines

        // [GIVEN] Usage Data Billing created for contracts that do not allow a different currency in the usage data
        Initialize();
        CreateUsageDataBillingWithCurrencyMismatch("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));

        SubscriptionHeader.Get(SubscriptionHeader."No.");
        ExpectedQuantity := SubscriptionHeader.Quantity;
        FindCustomerSubscriptionLine(CustomerSubscriptionLine, SubscriptionHeader."No.");
        ExpectedPrice := CustomerSubscriptionLine.Price;
        ExpectedUnitCost := CustomerSubscriptionLine."Unit Cost";

        // [WHEN] Process Usage Data Billing
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [THEN] Neither the Subscription quantity nor the prices in the Subscription Line are updated
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        SubscriptionHeader.TestField(Quantity, ExpectedQuantity);
        CustomerSubscriptionLine.Get(CustomerSubscriptionLine."Entry No.");
        CustomerSubscriptionLine.TestField(Price, ExpectedPrice);
        CustomerSubscriptionLine.TestField("Unit Cost", ExpectedUnitCost);
    end;

    [Test]
    procedure ExistForContractLineDependsOnUsageDataForContractLine()
    var
        CustomerContractLine1: Record "Cust. Sub. Contract Line";
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataExist: Boolean;
    begin
        // [SCENARIO] Action Usage Data should be disabled if there is no Usage Data for Contract Line and should be enabled if there is Usage Data for Contract Line

        // [GIVEN] Create Customer Subscription Contract with line
        Initialize();
        UsageBasedBTestLibrary.MockCustomerContractLine(CustomerContractLine1);

        // [WHEN] Contract line is selected
        UsageDataExist := UsageDataBilling.ExistForContractLine("Service Partner"::Customer, CustomerContractLine1."Subscription Contract No.", CustomerContractLine1."Line No.");

        // [THEN] Action Usage Data should be disabled
        Assert.IsFalse(UsageDataExist, 'Usage Data Action should be disabled');

        // [WHEN] Usage Data is created and Contract line is selected
        UsageBasedBTestLibrary.MockCustomerContractLine(CustomerContractLine1);
        UsageBasedBTestLibrary.MockUsageDataBillingForContractLine(UsageDataBilling, "Service Partner"::Customer, CustomerContractLine1."Subscription Contract No.", CustomerContractLine1."Line No.");
        UsageDataExist := UsageDataBilling.ExistForContractLine("Service Partner"::Customer, CustomerContractLine1."Subscription Contract No.", CustomerContractLine1."Line No.");

        // [THEN] Action Usage Data should be enabled
        Assert.IsTrue(UsageDataExist, 'Usage Data Action should be enabled');
    end;

    [Test]
    procedure ExistForDocumentsDependsOnUsageDataForDocument()
    var
        Item1: Record Item;
        SalesHeader1: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataExist: Boolean;
    begin
        // [SCENARIO] Action Usage Data should be disabled if there is no Usage Data for Document line and should be enabled if there is Usage Data for Document Line

        // [GIVEN] Create Sales Invoice
        Initialize();
        LibraryInventory.CreateNonInventoryTypeItem(Item1);
        LibrarySales.CreateSalesHeader(SalesHeader1, SalesHeader1."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader1, SalesLine1.Type::Item, Item1."No.", LibraryRandom.RandInt(100));

        // [WHEN] Sales line is selected
        UsageDataExist := UsageDataBilling.ExistForSalesDocuments(SalesLine1."Document Type", SalesLine1."Document No.", SalesLine1."Line No.");

        // [THEN] Action Usage Data should be disabled
        Assert.IsFalse(UsageDataExist, 'Usage Data Action should be disabled');

        // [WHEN] Usage Data is created and Sales line is selected
        UsageBasedBTestLibrary.MockUsageDataBillingForDocuments(UsageDataBilling, SalesLine1."Document Type", SalesLine1."Document No.", SalesLine1."Line No.");
        UsageDataExist := UsageDataBilling.ExistForSalesDocuments(SalesLine1."Document Type", SalesLine1."Document No.", SalesLine1."Line No.");

        // [THEN] Action Usage Data should be enabled
        Assert.IsTrue(UsageDataExist, 'Usage Data Action should be enabled');
    end;

    [Test]
    procedure ExistForRecurringBillingDependsOnBillingUsageData()
    var
        BillingLine1: Record "Billing Line";
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataExist: Boolean;
    begin
        // [SCENARIO] Action Usage Data should be disabled if there is no Usage Data for Billing Line and should be enabled if there is Usage Data for Billing Line

        // [GIVEN] Create Billing Line
        Initialize();
        UsageBasedBTestLibrary.MockBillingLine(BillingLine1);

        // [WHEN] Billing line is selected
        UsageDataExist := UsageDataBilling.ExistForRecurringBilling(BillingLine1."Subscription Header No.", BillingLine1."Subscription Line Entry No.", BillingLine1."Document Type", BillingLine1."Document No.");

        // [THEN] Action Usage Data should be disabled
        Assert.IsFalse(UsageDataExist, 'Usage Data Action should be disabled');

        // [WHEN] Usage Data is created and Billing line is selected
        UsageBasedBTestLibrary.MockBillingLineWithServObjectNo(BillingLine1);
        UsageBasedBTestLibrary.CreateSalesInvoiceAndAssignToBillingLine(BillingLine1);
        UsageBasedBTestLibrary.MockUsageDataForBillingLine(UsageDataBilling, BillingLine1);
        UsageDataExist := UsageDataBilling.ExistForRecurringBilling(BillingLine1."Subscription Header No.", BillingLine1."Subscription Line Entry No.", BillingLine1."Document Type", BillingLine1."Document No.");

        // [THEN] Action Usage Data should be enabled
        Assert.IsTrue(UsageDataExist, 'Usage Data Action should be enabled');
    end;

    [Test]
    procedure ExistForServiceCommitmentsDependsOnServiceCommitmentUsageData()
    var
        SubscriptionLine2: Record "Subscription Line";
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataExist: Boolean;
    begin
        // [SCENARIO] Action Usage Data should be disabled if there is no Usage Data for Subscription Line Line and should be enabled if there is Usage Data for Subscription Line Line

        // [GIVEN] Create Subscription Line
        Initialize();
        UsageBasedBTestLibrary.MockServiceCommitmentLine(SubscriptionLine2);

        // [WHEN] Subscription Line line is selected
        UsageDataExist := UsageDataBilling.ExistForServiceCommitments(SubscriptionLine2.Partner, SubscriptionLine2."Subscription Header No.", SubscriptionLine2."Entry No.");

        // [THEN] Action Usage Data should be disabled
        Assert.IsFalse(UsageDataExist, 'Usage Data Action should be disabled');

        // [WHEN] Usage data is created and Subscription Line line is selected
        UsageBasedBTestLibrary.MockUsageDataBillingForServiceCommitmentLine(UsageDataBilling, SubscriptionLine2.Partner, SubscriptionLine2."Subscription Header No.", SubscriptionLine2."Entry No.");
        UsageDataExist := UsageDataBilling.ExistForServiceCommitments(SubscriptionLine2.Partner, SubscriptionLine2."Subscription Header No.", SubscriptionLine2."Entry No.");

        // [THEN] Action Usage Data should be enabled
        Assert.IsTrue(UsageDataExist, 'Usage Data Action should be enabled');
    end;

    [Test]
    procedure ExpectErrorIfGenericSettingIsNotLinkedToDataExchangeDefinition()
    begin
        // [SCENARIO] Error is expected when generic import setting is not linked to a data exchange definition
        // [GIVEN] Usage data for generic import and an unlinked data exchange definition
        Initialize();
        SetupUsageDataForProcessingToGenericImport();
        SetupDataExchangeDefinition();
        UsageDataImport."Processing Step" := Enum::"Processing Step"::"Create Imported Lines";
        UsageDataImport.Modify(false);

        // [WHEN] Running import and process usage data
        // [THEN] Error is raised because generic setting is not linked
        asserterror Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorIfServiceCommitmentIsNotAssignedToContract()
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Error is expected when creating usage data billing if subscription lines are not fully assigned to contracts
        // [GIVEN] Service object with subscription lines where only customer contract is assigned (vendor contract missing)
        Initialize();
        SetupUsageDataForProcessingToGenericImport(WorkDate(), WorkDate(), WorkDate(), WorkDate(), 1, false);
        SetupDataExchangeDefinition();
        ContractTestLibrary.CreateCustomer(Customer);
        CreateSubscriptionItemWithPrices(1, 1);
        SetupItemWithMultipleServiceCommitmentPackages();
        ContractTestLibrary.CreateServiceObjectForItem(SubscriptionHeader, Item."No.");
        SubscriptionHeader.InsertServiceCommitmentsFromStandardServCommPackages(WorkDate());
        SubscriptionHeader."End-User Customer No." := Customer."No.";
        SubscriptionHeader.Modify(false);
        CreateCustomerContractAndAssignServiceCommitments();
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);

        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, "Usage Based Pricing"::"Usage Quantity", '1D', '1D');
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);
        UsageDataImport.SetRecFilter();

        // [WHEN] Creating usage data billing
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");

        // [THEN] Processing status is Error because not all subscription lines are assigned to contracts
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Error);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorOnDeleteCustomerContractLine()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Error is expected when trying to delete a customer contract line that has usage data billing
        // [GIVEN] Usage data billing linked to a customer contract line
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataBilling.SetRange(Partner, "Service Partner"::Customer);
        UsageDataBilling.FindFirst();
        CustomerContractLine.Get(UsageDataBilling."Subscription Contract No.", UsageDataBilling."Subscription Contract Line No.");

        // [WHEN] Deleting the customer contract line
        // [THEN] Error is raised
        asserterror CustomerContractLine.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure ExpectErrorOnDeleteUsageDataImportIfDocumentIsCreated()
    begin
        // [SCENARIO] Error is expected when deleting usage data import after documents have been created
        // [GIVEN] Usage data import with processed billing and created customer contract invoices
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [WHEN] Deleting the usage data import or its billing lines
        // [THEN] Error is raised
        asserterror UsageDataImport.Delete(true);
        asserterror UsageDataImport.DeleteUsageDataBillingLines();
    end;

    [Test]
    procedure ExpectErrorWhenDataExchangeDefinitionIsNotGenericImportForGenericImportSettings()
    var
        DataExchDefType: Enum "Data Exchange Definition Type";
        ListOfOrdinals: List of [Integer];
    begin
        // [SCENARIO] Error for validating Data Exchange Definition for types different than Generic Import
        // [GIVEN] A usage data supplier with generic import settings
        Initialize();
        UsageBasedBTestLibrary.CreateUsageDataSupplier(UsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, true, Enum::"Vendor Invoice Per"::Import);
        UsageBasedBTestLibrary.CreateGenericImportSettings(GenericImportSettings, UsageDataSupplier."No.", true, true);

        ListOfOrdinals := "Data Exchange Definition Type".Ordinals();
        // [WHEN] Validating data exchange definition for each type
        // [THEN] Only "Generic Import" type succeeds; all others raise an error
        foreach i in ListOfOrdinals do begin
            DataExchDefType := "Data Exchange Definition Type".FromInteger(i);
            UsageBasedBTestLibrary.CreateDataExchDefinition(DataExchDef, FileType::"Variable Text", DataExchDefType, FileEncoding::"UTF-8", ColumnSeparator::Semicolon, '', 1);
            if DataExchDefType = "Data Exchange Definition Type"::"Generic Import" then
                GenericImportSettings.Validate("Data Exchange Definition", DataExchDef.Code)
            else
                asserterror GenericImportSettings.Validate("Data Exchange Definition", DataExchDef.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenServiceCommitmentStartDateIsNotValid()
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Error is expected when subscription line start date does not match usage data
        // [GIVEN] Usage data imported on WorkDate and service object created with start date before WorkDate
        Initialize();
        SetupUsageDataForProcessingToGenericImport();
        SetupDataExchangeDefinition();
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");

        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();

        SetupServiceObjectAndContracts(CalcDate('<-1D>', WorkDate())); // Usage data generic import is created on WorkDate

        // [WHEN] Processing imported lines with mismatched start date
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // [THEN] Processing status is Error due to invalid start date
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        UsageDataGenericImport.TestField("Processing Status", Enum::"Processing Status"::Error);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectNoInvoicesCreateIfUsageDataImportProcessingStatusIsError()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] When usage data import has error processing status
        // expect no invoices to be created

        // [GIVEN] Create usage data and set processing status to error manually
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", WorkDate(), WorkDate(), WorkDate(), WorkDate(), LibraryRandom.RandDec(10, 2));
        PostDocument := false;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.Validate("Processing Status", Enum::"Processing Status"::Error);
        UsageDataImport.Modify(false);

        // [WHEN] Try to create Customer Subscription Contract invoices; Error should be caught and no usage data lines should be taken into contract invoice
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [THEN] Test if Processing Status Error is set in Usage Data Import and that no invoice has been created and assigned in Usage Data Billing
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Error);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer, UsageDataBilling."Document Type"::Invoice);
        Assert.RecordIsEmpty(UsageDataBilling);
    end;

    [Test]
    procedure FixedQuantityVendorCostIsChargedForDeliveredQuantity()
    var
        VendorUsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] With "Fixed Quantity" the vendor is charged what the supplier delivered, not the quantity the
        // Subscription is subscribed with.

        // [GIVEN] A yearly Subscription with a quantity of 10 and a supplier Unit Cost of 365 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [WHEN] Usage data delivering a quantity of 4 for the whole year is processed with "Fixed Quantity"
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 4, "Usage Based Pricing"::"Fixed Quantity");

        // [THEN] The vendor is charged the delivered quantity: 365 * 4
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(1460, VendorUsageDataBilling."Cost Amount", 'The vendor Cost Amount must be calculated from the delivered quantity.');
    end;

    [Test]
    procedure ForeignCurrencyUnitCostIsConvertedAndProratedForVendorSubscriptionLine()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        ImportCurrencyCode: Code[10];
    begin
        // [SCENARIO] A supplier Unit Cost delivered in a currency other than the currency of the contract is converted
        // to the contract currency first, and then prorated to the charge period like any other Unit Cost.

        // [GIVEN] A yearly Subscription in local currency whose vendor Subscription Line costs 300 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine.Modify(false);

        // [GIVEN] A currency of which 1 unit is worth 2 in local currency
        ImportCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(DMY2Date(1, 1, 2026), 0.5, 0.5);

        // [WHEN] Usage data for October to December with a Unit Cost of 365 per year in that currency is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 365, 0, ImportCurrencyCode);
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged the converted Unit Cost of 730 per year for 92 of 365 days: 184 per unit
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.FindFirst();
        VendorUsageDataBilling.TestField("Currency Code", '');
        VendorUsageDataBilling.TestField("Unit Cost", 730);
        VendorUsageDataBilling.TestField("Cost Amount", 1840);

        // [THEN] The vendor Subscription Line takes over the converted Unit Cost per Billing Base Period
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(730, VendorSubscriptionLine.Price, 'The vendor Subscription Line must take over the converted supplier Unit Cost per Billing Base Period.');
    end;

    [Test]
    procedure IsUsageDataBillingFoundReturnsLineWithUsageBasedPricingAboveUnitCostSurcharge()
    var
        SubscriptionLine2: Record "Subscription Line";
        UsageDataBillingExtendedValue: Record "Usage Data Billing";
        UsageDataBillingNoneValue: Record "Usage Data Billing";
        FilteredUsageDataBilling: Record "Usage Data Billing";
        BillingFromDate: Date;
        BillingToDate: Date;
    begin
        // [SCENARIO] SetUsageDataBillingFilters uses an open-ended (>=) filter on "Usage Base Pricing", so a Usage Data Billing line carrying a value above the shipped "Unit Cost Surcharge" (added through a test-only enum extension) is still returned by IsUsageDataBillingFound

        // [GIVEN] A Subscription Line
        Initialize();
        ContractTestLibrary.InitContractsApp();
        UsageBasedBTestLibrary.MockServiceCommitmentLine(SubscriptionLine2);
        BillingFromDate := WorkDate();
        BillingToDate := WorkDate();

        // [GIVEN] A Usage Data Billing line for that Subscription Line, Document Type None, within the billing period, with a "Usage Base Pricing" value above "Unit Cost Surcharge" (ordinal 100 from the test enum extension)
        UsageBasedBTestLibrary.MockUsageDataBillingForServiceCommitmentLine(UsageDataBillingExtendedValue, SubscriptionLine2.Partner, SubscriptionLine2."Subscription Header No.", SubscriptionLine2."Entry No.");
        UsageDataBillingExtendedValue."Document Type" := UsageDataBillingExtendedValue."Document Type"::None;
        UsageDataBillingExtendedValue."Charge Start Date" := BillingFromDate;
        UsageDataBillingExtendedValue."Charge End Date" := BillingToDate;
        UsageDataBillingExtendedValue."Usage Base Pricing" := Enum::"Usage Based Pricing"::"Test Above Unit Cost Surcharge";
        UsageDataBillingExtendedValue.Modify(false);

        // [GIVEN] A second Usage Data Billing line for the same Subscription Line but with "Usage Base Pricing" = None (below the filter boundary)
        UsageBasedBTestLibrary.MockUsageDataBillingForServiceCommitmentLine(UsageDataBillingNoneValue, SubscriptionLine2.Partner, SubscriptionLine2."Subscription Header No.", SubscriptionLine2."Entry No.");
        UsageDataBillingNoneValue."Document Type" := UsageDataBillingNoneValue."Document Type"::None;
        UsageDataBillingNoneValue."Charge Start Date" := BillingFromDate;
        UsageDataBillingNoneValue."Charge End Date" := BillingToDate;
        UsageDataBillingNoneValue."Usage Base Pricing" := Enum::"Usage Based Pricing"::None;
        UsageDataBillingNoneValue.Modify(false);

        // [WHEN] Checking whether the Subscription Line finds Usage Data Billing to invoice
        // [THEN] The line carrying the extended value is found (open-ended >= filter)
        Assert.IsTrue(SubscriptionLine2.IsUsageDataBillingFound(FilteredUsageDataBilling, BillingFromDate, BillingToDate), 'Usage Data Billing with a "Usage Base Pricing" value above "Unit Cost Surcharge" should be found by the open-ended filter.');

        // [THEN] Exactly the extended-value line is returned, the "None"-valued line is filtered out
        Assert.RecordCount(FilteredUsageDataBilling, 1);
        FilteredUsageDataBilling.FindFirst();
        FilteredUsageDataBilling.TestField("Usage Base Pricing", Enum::"Usage Based Pricing"::"Test Above Unit Cost Surcharge");
    end;

    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    [Test]
    procedure PostingCreditMemoWithoutAppliesToDocNoDoesNotDuplicateUsageDataBilling()
    var
        UsageDataBilling: Record "Usage Data Billing";
        InitialBillingCount: Integer;
    begin
        // [SCENARIO] Posting a usage-based credit memo without "Applies-to Doc. No." must not create additional usage data billing records (PDD-821)
        // [GIVEN] A customer contract with usage-based service commitments, invoiced and with a corrective credit memo
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer, UsageDataBilling."Document Type"::"Posted Invoice");
        UsageDataBilling.FindFirst();

        // [GIVEN] Create a corrective credit memo and clear "Applies-to Doc. No." to simulate a standalone credit memo
        SalesInvoiceHeader.Get(UsageDataBilling."Document No.");
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesCrMemoHeader);
        SalesCrMemoHeader.Validate("Applies-to Doc. No.", '');
        SalesCrMemoHeader.Modify(true);

        // [WHEN] Count billing records before posting and then post the credit memo
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        InitialBillingCount := UsageDataBilling.Count();
        LibrarySales.PostSalesDocument(SalesCrMemoHeader, true, true);

        // [THEN] No additional usage data billing records should be created (no duplication)
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        Assert.AreEqual(InitialBillingCount, UsageDataBilling.Count(), 'Posting a credit memo without Applies-to Doc. No. must not create additional usage data billing records.');
        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo("Service Partner"::Customer, Enum::"Usage Based Billing Doc. Type"::None, '');
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        Assert.RecordIsEmpty(UsageDataBilling);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ProcessingStatusIsResetToOkWhenNoErrorsRemain()
    var
        StaleErrorLbl: Label 'Error from an earlier processing step.', Locked = true;
    begin
        // [SCENARIO] A stale Error on the Usage Data Import is cleared when Process Usage Data Billing finds no errors

        // [GIVEN] Usage Data Billing without errors
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));

        // [GIVEN] The import carries an Error and a reason from an earlier processing step
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.SetErrorReason(StaleErrorLbl);
        UsageDataImport.Modify(false);

        // [WHEN] Process Usage Data Billing
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [THEN] The import is Ok again and the stale reason is gone
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Ok);
        UsageDataImport.TestField("Reason (Preview)", '');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ProcessingStatusIsSetToOkAfterSuccessfulProcessing()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Usage Data Billing lines that are processed without an error get Processing Status = Ok

        // [GIVEN] Usage Data Billing created for contracts that allow the usage data currency
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));

        // [GIVEN] The lines are not processed yet
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetFilter("Processing Status", '<>%1', Enum::"Processing Status"::None);
        Assert.RecordIsEmpty(UsageDataBilling);

        // [WHEN] Process Usage Data Billing
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [THEN] Every line is marked as Ok and the import stays Ok
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField("Processing Status", Enum::"Processing Status"::Ok);
        until UsageDataBilling.Next() = 0;

        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Ok);
    end;

    [Test]
    procedure ProcessingUsageDataBillingTwiceKeepsTheSameCost()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        CostAmountAfterFirstRun: Decimal;
        CustomerCostAmountAfterFirstRun: Decimal;
    begin
        // [SCENARIO] Processing the usage data billing of an import a second time - which the user can do at any time
        // before the documents are created - must arrive at the same cost, not scale the already scaled cost again.

        // [GIVEN] Usage data covering only part of a billing period has been processed
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10);

        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        CostAmountAfterFirstRun := VendorUsageDataBilling."Cost Amount";
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums("Cost Amount");
        CustomerCostAmountAfterFirstRun := CustomerUsageDataBilling."Cost Amount";
        Assert.AreEqual(920, CustomerCostAmountAfterFirstRun, 'The Cost Amount of the customer usage data does not cover the charge period.');

        // [WHEN] The same import is processed again
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Cost Amount is unchanged
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(CostAmountAfterFirstRun, VendorUsageDataBilling."Cost Amount",
            'Processing the usage data billing again must not change the Cost Amount of the vendor Subscription Line.');

        // [THEN] The customer Cost Amount is unchanged
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(CustomerCostAmountAfterFirstRun, CustomerUsageDataBilling."Cost Amount",
            'Processing the usage data billing again must not change the Cost Amount of the customer usage data.');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ProcessUsageDataBillingWithZeroQuantitySucceeds()
    begin
        // [SCENARIO] Processing usage data billing with quantity 0 succeeds without error
        // [GIVEN] Usage data billing with zero quantity and zero service object quantity
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", WorkDate(), WorkDate(), WorkDate(), WorkDate(), 0);
        SubscriptionHeader.Quantity := 0;
        SubscriptionHeader.Modify(false);

        // [WHEN] Processing usage data billing
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [THEN] Processing should not result in error
        UsageDataImport.Get(UsageDataImport."Entry No.");
        Assert.AreNotEqual(Enum::"Processing Status"::Error, UsageDataImport."Processing Status", 'Processing of usage data billing with quantity 0 should not result in error.');
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocumentForBillingDatePageHandler,MessageHandler')]
    procedure PurchaseCreditMemoForCancelledMonthsCreditsSupplierChargePeriod()
    var
        PurchaseCrMemoLine: Record "Purchase Line";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A Subscription billed yearly in advance is cancelled after nine months. The supplier credits the
        // remaining three months with usage data that states its yearly Unit Cost. The purchase credit memo created
        // from the vendor Subscription Contract credits those three months only, not the whole year.

        // [GIVEN] A yearly Subscription with a quantity of 10 and a customer and a vendor Subscription Line, both usage based
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [GIVEN] Usage data for the whole year at a supplier Unit Cost of 1200 is processed, and the purchase invoice
        // created from the vendor Subscription Contract is posted
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);
        LibraryVariableStorage.Enqueue(DMY2Date(31, 12, 2026));
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
        ResetPurchasePostingNoSeriesDateUsage();
        PostPurchaseDocuments();

        // [GIVEN] Usage data crediting October to December with a quantity of -10 at the supplier Unit Cost of 1200
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [GIVEN] The usage data is processed without an error
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        // [WHEN] The billing documents are created from the vendor Subscription Contract
        LibraryVariableStorage.Enqueue(DMY2Date(31, 12, 2026));
        UsageDataImport.SetRecFilter();
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);

        // [THEN] A purchase credit memo is created for the usage data
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.FindFirst();
        VendorUsageDataBilling.TestField("Document Type", "Usage Based Billing Doc. Type"::"Credit Memo");
        PurchaseCrMemoLine.Get("Purchase Document Type"::"Credit Memo", VendorUsageDataBilling."Document No.", VendorUsageDataBilling."Document Line No.");

        // [THEN] The credit memo credits the supplier charge period: 92 of 365 days of 1200 for a quantity of 10,
        // 1200 * 92 / 365 * 10 = 3024.66, and not the 12000 of the whole year
        Assert.AreEqual(3024.66, PurchaseCrMemoLine."Line Amount", 'The purchase credit memo must credit the supplier charge period only.');
        PurchaseCrMemoLine.TestField("Recurring Billing from", DMY2Date(1, 10, 2026));
        PurchaseCrMemoLine.TestField("Recurring Billing to", DMY2Date(31, 12, 2026));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure RebillingCreditIsCorrectedOnceForSubscriptionWithCustomerAndVendorLine()
    var
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A credit after the delivery was invoiced is rebilling: the subscribed quantity is corrected by the
        // credited quantity. A Subscription with a customer and a vendor Subscription Line must be corrected once,
        // not once per Subscription Line.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose usage data for the whole year is invoiced
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);
        MarkUsageDataBillingMetadataAsInvoiced();

        // [WHEN] Usage data crediting 4 for October to December is processed as rebilling
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -4);
        AssertUsageDataBillingIsRebilling();
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The usage data billing is processed without an error and the Subscription has a quantity of 10 - 4
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(6, SubscriptionHeader.Quantity, 'The rebilling credit must correct the quantity of the Subscription once.');
    end;

    [Test]
    procedure RebillingCreditIsCorrectedOnceWhenProcessedAgain()
    var
        UsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        ProcessUsageDataBillingAgain: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Processing the usage data billing of an import again must not correct the quantity of the
        // Subscription by the rebilling credit a second time.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose usage data for the whole year is invoiced
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);
        MarkUsageDataBillingMetadataAsInvoiced();

        // [GIVEN] Usage data crediting 4 for October to December is processed as rebilling, which leaves a quantity of 6
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -4);
        AssertUsageDataBillingIsRebilling();
        ProcessUsageDataBilling.Run(UsageDataImport);
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(6, SubscriptionHeader.Quantity, 'The rebilling credit must correct the quantity of the Subscription.');

        // [WHEN] The usage data billing of the import is processed again
        ProcessUsageDataBillingAgain.Run(UsageDataImport);

        // [THEN] The usage data billing stays processed without an error and the Subscription keeps a quantity of 6
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetFilter("Processing Status", '<>%1', "Processing Status"::Ok);
        Assert.RecordIsEmpty(UsageDataBilling);
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(6, SubscriptionHeader.Quantity, 'Processing the rebilling credit again must not correct the quantity of the Subscription again.');
    end;

    [Test]
    procedure RebillingCreditOfWholeQuantityPausesSubscription()
    var
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A rebilling credit of the whole subscribed quantity leaves a quantity of zero, which pauses the
        // billing of the Subscription. Neither of its two Subscription Lines may report the credit as exceeding it.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose usage data for the whole year is invoiced
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);
        MarkUsageDataBillingMetadataAsInvoiced();

        // [WHEN] Usage data crediting all 10 for October to December is processed as rebilling
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10);
        AssertUsageDataBillingIsRebilling();
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The usage data billing is processed without an error and the Subscription has a quantity of zero
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(0, SubscriptionHeader.Quantity, 'A rebilling credit of the whole quantity must set the quantity of the Subscription to zero.');
    end;

    [Test]
    procedure RebillingCreditOfWholeQuantityStaysValidWhenProcessedAgain()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        UsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        ProcessUsageDataBillingAgain: Codeunit "Process Usage Data Billing";
        CostAmountBeforeProcessingAgain: Decimal;
        VendorPriceBeforeProcessingAgain: Decimal;
    begin
        // [SCENARIO] A rebilling credit of the whole subscribed quantity is accepted and sets the quantity of the
        // Subscription to zero. Processing the usage data billing of the import again must keep the accepted credit
        // valid instead of checking it against the quantity it has already reduced.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose usage data for the whole year is invoiced
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);
        MarkUsageDataBillingMetadataAsInvoiced();

        // [GIVEN] Usage data crediting all 10 for October to December is processed as rebilling
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10);
        AssertUsageDataBillingIsRebilling();
        ProcessUsageDataBilling.Run(UsageDataImport);
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorPriceBeforeProcessingAgain := VendorSubscriptionLine.Price;
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.CalcSums("Cost Amount");
        CostAmountBeforeProcessingAgain := UsageDataBilling."Cost Amount";

        // [WHEN] The usage data billing of the import is processed again
        ProcessUsageDataBillingAgain.Run(UsageDataImport);

        // [THEN] The usage data billing stays processed without an error
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetFilter("Processing Status", '<>%1', "Processing Status"::Ok);
        Assert.RecordIsEmpty(UsageDataBilling);

        // [THEN] Nothing is applied a second time: the Subscription keeps a quantity of zero, and the cost of the usage data
        // and the Price of the vendor Subscription Line are unchanged
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(0, SubscriptionHeader.Quantity, 'Processing the rebilling credit again must keep the quantity of the Subscription at zero.');
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(CostAmountBeforeProcessingAgain, UsageDataBilling."Cost Amount", 'Processing the usage data billing again must not change its cost.');
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(VendorPriceBeforeProcessingAgain, VendorSubscriptionLine.Price, 'Processing the rebilling credit again must not change the Price of the vendor Subscription Line.');
    end;

    [Test]
    procedure RejectedCreditDoesNotExtendBillingPeriodOfAcceptedUsageData()
    var
        VendorSubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] The billing period of a usage based Subscription Line follows the charge periods of its usage data.
        // A rejected credit for a later charge period must not extend the billing period of the accepted usage data.

        // [GIVEN] A yearly Subscription with a quantity of 10, with accepted usage data for January to September and a
        // rejected credit of 15 for October to December
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(30, 9, 2026), 10);
        ProcessRejectedCredit(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -15);

        // [WHEN] A billing proposal is created for the vendor Subscription Contract
        CreateBillingProposalForVendorContract(DMY2Date(31, 12, 2026), 0D);

        // [THEN] The vendor Subscription Line is billed for January to September only
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        BillingLine.Reset();
        BillingLine.SetRange("Subscription Line Entry No.", VendorSubscriptionLine."Entry No.");
        Assert.RecordCount(BillingLine, 1);
        BillingLine.FindFirst();
        BillingLine.TestField("Billing from", DMY2Date(1, 1, 2026));
        BillingLine.TestField("Billing to", DMY2Date(30, 9, 2026));
    end;

    [Test]
    procedure RejectedCreditIsLeftOutOfBillingOfAcceptedUsageData()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        UsageDataBilling: Record "Usage Data Billing";
        RejectedUsageDataImportEntryNo: Integer;
    begin
        // [SCENARIO] A rejected credit within the billing period of accepted usage data must not reduce what is billed
        // for the accepted usage data, and it must not be linked to the billing line.

        // [GIVEN] A yearly Subscription with a quantity of 10, with accepted usage data for the whole year and a rejected
        // credit of 15 for October to December
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);
        ProcessRejectedCredit(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -15);
        RejectedUsageDataImportEntryNo := UsageDataImport."Entry No.";

        // [WHEN] A billing proposal is created for the vendor Subscription Contract
        CreateBillingProposalForVendorContract(DMY2Date(31, 12, 2026), 0D);

        // [THEN] The vendor Subscription Line is billed the cost of the accepted usage data only: 365 * 10 = 3650,
        // and not 3650 - 15 * 92 = 2270
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        BillingLine.Reset();
        BillingLine.SetRange("Subscription Line Entry No.", VendorSubscriptionLine."Entry No.");
        Assert.RecordCount(BillingLine, 1);
        BillingLine.FindFirst();
        Assert.AreEqual(3650, BillingLine.Amount, 'A rejected credit must not reduce the billing of the accepted usage data.');

        // [THEN] The rejected usage data billing is not linked to the billing line
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, RejectedUsageDataImportEntryNo);
        UsageDataBilling.SetFilter("Billing Line Entry No.", '<>%1', 0);
        Assert.RecordIsEmpty(UsageDataBilling);
    end;

    [Test]
    procedure RejectedCreditIsNotBilledByContractBilling()
    var
        VendorSubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] A credit that exceeds the subscribed quantity is rejected with an error on its usage data billing.
        // Contract billing must leave the rejected usage data billing out, so that no credit is billed for it.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose usage data crediting 15 for October to December is rejected
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessRejectedCredit(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -15);

        // [WHEN] A billing proposal is created for the vendor Subscription Contract, also when it is billed up to a given date
        CreateBillingProposalForVendorContract(DMY2Date(31, 12, 2026), 0D);
        CreateBillingProposalForVendorContract(DMY2Date(31, 12, 2026), DMY2Date(31, 12, 2026));

        // [THEN] The vendor Subscription Line gets no billing line for the rejected credit
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        BillingLine.Reset();
        BillingLine.SetRange("Subscription Line Entry No.", VendorSubscriptionLine."Entry No.");
        Assert.RecordIsEmpty(BillingLine);
    end;

    [Test]
    procedure RejectedCreditCrossingBillingRhythmDoesNotExtendNextBillingToDate()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        BillingProposal: Codeunit "Billing Proposal";
    begin
        // [SCENARIO] Usage data whose charge period starts in a billing period and ends after it extends that billing period.
        // A rejected credit must not do so, because it is not billed.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose usage data crediting 15 for October 2026 to March 2027 is rejected
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        ProcessRejectedCredit(DMY2Date(1, 10, 2026), DMY2Date(31, 3, 2027), -15);

        // [WHEN] The billing to date of the yearly vendor Subscription Line is calculated for the year 2026
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);

        // [THEN] The billing to date is the end of the Billing Rhythm and not the end of the rejected credit
        Assert.AreEqual(DMY2Date(31, 12, 2026), BillingProposal.CalculateNextBillingToDateForServiceCommitment(VendorSubscriptionLine, DMY2Date(1, 1, 2026)), 'A rejected credit must not extend the billing period.');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ReopeningUsageDataImportRestoresProcessingStatus()
    begin
        // [SCENARIO] Reopening a closed Usage Data Import restores the status from the imported lines and the usage data billing

        // [GIVEN] A processed and closed Usage Data Import
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.SetRecFilter();
        UsageDataImport.CloseUsageDataImports(UsageDataImport);
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Closed);

        // [WHEN] The import is reopened
        UsageDataImport.SetRecFilter();
        UsageDataImport.ReopenUsageDataImports(UsageDataImport);

        // [THEN] The status is Ok again, because no usage data billing line is in error
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Ok);

        // [THEN] The import can be processed again
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", Enum::"Processing Status"::Ok);
    end;

    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    [Test]
    procedure ResetUsageDataBillingWhenRelatedSalesInvoiceLineIsDeleted()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] When sales invoice with usage data is created if a line is deleted related usage data billing should be reset
        // [GIVEN] A customer contract with usage-based service commitments and a sales invoice created from usage data
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := false;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer, UsageDataBilling."Document Type"::"Invoice");
        UsageDataBilling.FindFirst();

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Sales Document Type"::Invoice);
        SalesLine.SetRange("Document No.", UsageDataBilling."Document No.");
        SalesLine.SetRange(Type, "Sales Line Type"::Item);
        SalesLine.FindFirst();

        // [WHEN] Delete the first line (simulate user action)
        SalesLine.Delete(true);

        // [THEN] Check that invoice data is removed from usage data billing
        UsageDataBilling.Reset();
        UsageDataBilling.Get(UsageDataBilling."Entry No.");
        UsageDataBilling.TestField("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.TestField("Document No.", '');
        UsageDataBilling.TestField("Document Line No.", 0);
        UsageDataBilling.TestField("Billing Line Entry No.", 0);
    end;

    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    [Test]
    procedure ResetUsageDataBillingWhenRelatedPurchLineIsDeleted()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] When purchase invoice with usage data is created if a line is deleted related usage data billing should be reset
        // [GIVEN] A vendor contract with usage-based service commitments and a purchase invoice created from usage data
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor, UsageDataBilling."Document Type"::Invoice);
        UsageDataBilling.FindFirst();

        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, UsageDataBilling."Document No.");

        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, "Sales Line Type"::Item);
        PurchaseLine.FindFirst();

        // [WHEN] Delete the first line (simulate user action)
        PurchaseLine.Delete(true);

        // [THEN] Check that invoice data is removed from usage data billing
        UsageDataBilling.Reset();
        UsageDataBilling.Get(UsageDataBilling."Entry No.");
        UsageDataBilling.TestField("Document Type", UsageDataBilling."Document Type"::None);
        UsageDataBilling.TestField("Document No.", '');
        UsageDataBilling.TestField("Document Line No.", 0);
        UsageDataBilling.TestField("Billing Line Entry No.", 0);
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocumentForBillingDatePageHandler,MessageHandler')]
    procedure SalesCreditMemoForCancelledMonthsCreditsSupplierChargePeriod()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        SalesCrMemoLine: Record "Sales Line";
        CustomerUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A Subscription billed yearly in advance is cancelled after nine months. The supplier credits the
        // remaining three months with usage data. The sales credit memo created from the customer Subscription
        // Contract credits the customer the price of those three months only, not the whole year.

        // [GIVEN] A yearly Subscription with a quantity of 10 and a customer and a vendor Subscription Line, both usage
        // based, with a customer Price of 1460 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        FindCustomerSubscriptionLine(CustomerSubscriptionLine, SubscriptionHeader."No.");
        CustomerSubscriptionLine.Validate("Calculation Base Amount", 1460);
        CustomerSubscriptionLine.Modify(false);

        // [GIVEN] Usage data for the whole year is processed, and the sales invoice created from the customer
        // Subscription Contract is posted
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);
        LibraryVariableStorage.Enqueue(DMY2Date(31, 12, 2026));
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
        FindCustomerUsageDataBilling(CustomerUsageDataBilling, UsageDataImport."Entry No.");
        SalesHeader.Get("Sales Document Type"::Invoice, CustomerUsageDataBilling."Document No.");
        ResetSalesPostingNoSeriesDateUsage();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Usage data crediting October to December with a quantity of -10
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [GIVEN] The usage data is processed without an error
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        // [WHEN] The billing documents are created from the customer Subscription Contract
        LibraryVariableStorage.Enqueue(DMY2Date(31, 12, 2026));
        UsageDataImport.SetRecFilter();
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [THEN] A sales credit memo is created for the usage data
        CustomerUsageDataBilling.Reset();
        FindCustomerUsageDataBilling(CustomerUsageDataBilling, UsageDataImport."Entry No.");
        CustomerUsageDataBilling.TestField("Document Type", "Usage Based Billing Doc. Type"::"Credit Memo");
        SalesCrMemoLine.Get("Sales Document Type"::"Credit Memo", CustomerUsageDataBilling."Document No.", CustomerUsageDataBilling."Document Line No.");

        // [THEN] The credit memo credits the charge period: 92 of 365 days of 1460 for a quantity of 10,
        // 1460 * 92 / 365 * 10 = 3680, and not the 14600 of the whole year
        Assert.AreEqual(3680, SalesCrMemoLine."Line Amount", 'The sales credit memo must credit the charge period only.');

        // [THEN] The cost on the credit memo covers the same period: 92 of 365 days of the supplier Unit Cost of 1200,
        // 1200 * 92 / 365 = 302.466 per unit, and not the 1200 of the whole year
        Assert.AreEqual(302.466, SalesCrMemoLine."Unit Cost (LCY)", 'The cost on the sales credit memo must cover the charge period only.');
        SalesCrMemoLine.TestField("Recurring Billing from", DMY2Date(1, 10, 2026));
        SalesCrMemoLine.TestField("Recurring Billing to", DMY2Date(31, 12, 2026));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SupplierChargePeriodIsHonouredForUnitCostSurcharge()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        CustomerUsageDataBilling: Record "Usage Data Billing";
        VendorUsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] The supplier states its Unit Cost per Billing Base Period for every pricing option, so the
        // vendor cost of a charge period of three months must be prorated for "Unit Cost Surcharge" as well. The
        // customer is charged the surcharge on that vendor cost of the charge period, so that the margin is kept.

        // [GIVEN] A yearly Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %, whose vendor
        // Subscription Line costs 300 per year, and a supplier Unit Cost of 365 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine.Modify(false);

        // [WHEN] Usage data covering only the last three months is processed
        ProcessYearlyUsageDataImport(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, "Usage Based Pricing"::"Unit Cost Surcharge");

        // [THEN] The vendor is charged the supplier cost for those three months only: 92 of 365 days, 92 per unit
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(920, VendorUsageDataBilling."Cost Amount", 'The vendor Cost Amount does not cover the supplier charge period for Unit Cost Surcharge.');

        // [THEN] The customer is charged the surcharge on the vendor cost of the charge period: 920 * 1.1, and the
        // customer usage data costs what the vendor is charged for the charge period
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums(Amount, "Cost Amount");
        Assert.AreEqual(1012, CustomerUsageDataBilling.Amount, 'The customer must be charged the surcharge on the vendor cost of the charge period.');
        Assert.AreEqual(920, CustomerUsageDataBilling."Cost Amount", 'The Cost Amount of the customer usage data does not cover the charge period for Unit Cost Surcharge.');

        // [THEN] The customer Unit Price is that Amount per unit: 1012 / 10
        CustomerUsageDataBilling.FindFirst();
        Assert.AreEqual(101.2, CustomerUsageDataBilling."Unit Price", 'The customer Unit Price must be the Amount per unit.');

        // [THEN] The vendor Subscription Line takes over the supplier Unit Cost per Billing Base Period
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(365, VendorSubscriptionLine.Price, 'The vendor Subscription Line must take over the supplier Unit Cost per Billing Base Period.');
    end;

    [Test]
    procedure SupplierCostAmountForWholeYearIsKeptForMonthlyVendorBillingRhythm()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A vendor Subscription Line billed monthly receives usage data for a whole year with a Cost Amount
        // delivered by the supplier. That Cost Amount already covers the charge period and must not be multiplied by the
        // number of Billing Rhythms in it.

        // [GIVEN] A Subscription with a quantity of 10, whose vendor Subscription Line is priced per year and billed monthly
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 12000, '');
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Evaluate(VendorSubscriptionLine."Billing Rhythm", '<1M>');
        VendorSubscriptionLine.Modify(false);

        // [WHEN] Usage data for the whole year with a Unit Cost of 1200 and a Cost Amount of 12000 is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged the delivered Cost Amount of 12000
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(12000, VendorUsageDataBilling."Cost Amount", 'A delivered Cost Amount must not be multiplied for a vendor Subscription Line billed monthly.');

        // [THEN] The vendor Subscription Line costs the delivered Cost Amount per unit and year: 12000 / 10
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(1200, VendorSubscriptionLine.Price, 'The vendor Price must be the delivered Cost Amount per unit and Billing Base Period.');
    end;

    [Test]
    procedure SupplierUnitCostForWholeYearIsNotMultipliedForMonthlyVendorBillingRhythm()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A vendor Subscription Line priced per year and billed monthly receives usage data for a whole year
        // with a supplier Unit Cost only. The Unit Cost is stated per Billing Base Period, so the twelve Billing Rhythms
        // of the year add up to the Unit Cost once for each unit.

        // [GIVEN] A Subscription with a quantity of 10, whose vendor Subscription Line is priced per year and billed monthly
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Evaluate(VendorSubscriptionLine."Billing Rhythm", '<1M>');
        VendorSubscriptionLine.Modify(false);

        // [WHEN] Usage data for the whole year with a supplier Unit Cost of 1200 per year is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged the supplier Unit Cost for each unit: 1200 * 10
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(12000, VendorUsageDataBilling."Cost Amount", 'A supplier Unit Cost must not be multiplied for a vendor Subscription Line billed monthly.');
    end;

    [Test]
    procedure SupplierUnitCostIsChargedUnchangedForWholeBillingPeriod()
    var
        VendorUsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Usage data covering a whole Billing Base Period is charged at the Unit Cost delivered by the supplier.

        // [GIVEN] A yearly Subscription with a customer and a vendor Subscription Line, both usage based, and a
        // supplier Unit Cost of 365 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [WHEN] Usage data for the whole year is imported and processed
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10);

        // [THEN] The vendor is charged the supplier Unit Cost for each unit: 365 * 10
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(3650, VendorUsageDataBilling."Cost Amount", 'The supplier Unit Cost must be charged unchanged when the usage data covers a whole billing period.');
    end;

    [Test]
    procedure SupplierUnitCostIsStoredPerBillingBasePeriodOnVendorSubscriptionLine()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Both the Price of a Subscription Line and the supplier Unit Cost are stated per Billing Base
        // Period. When usage data for part of a year brings a new supplier Unit Cost, the vendor is charged the share of
        // the charge period, and the vendor Subscription Line takes over the Unit Cost itself, not that share.

        // [GIVEN] A Subscription with a quantity of 10, whose vendor Subscription Line costs 600 per year and is billed monthly
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Validate("Calculation Base Amount", 600);
        Evaluate(VendorSubscriptionLine."Billing Rhythm", '<1M>');
        VendorSubscriptionLine.Modify(false);

        // [WHEN] Usage data for October to December with a supplier Unit Cost of 1200 per year is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged three twelfths of the supplier Unit Cost for each unit: 1200 * 3 / 12 * 10
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(3000, VendorUsageDataBilling."Cost Amount", 'The vendor must be charged the supplier Unit Cost for the three Billing Rhythms of the charge period.');

        // [THEN] The vendor Subscription Line costs 1200 per year, not the 300 charged for October to December
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(1200, VendorSubscriptionLine.Price, 'The vendor Subscription Line must take over the supplier Unit Cost per Billing Base Period.');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler,StrMenuHandlerClearBillingProposal')]
    procedure TestBillingLineInUsageDataNoWhenBillingProposalIsCreated()
    var
        UsageDataBilling: Record "Usage Data Billing";
        BillingProposal: Codeunit "Billing Proposal";
    begin
        //[SCENARIO] Create recurring billing for simple customer contract; Check if Usage Data Billing Line No. has billing line no

        Initialize();
        //[GIVEN]: Setup Usage Data Import and process it
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        //[WHEN]: Create recurring billing proposal for customer contract
        CreateBillingProposalForSimpleCustomerContract();

        //[THEN]: Check if Usage Data Billing Line No. has billing line no
        BillingLine.Reset();
        BillingLine.SetRange(Partner, BillingLine.Partner::Customer);
        BillingLine.FindFirst();
        UsageDataBilling.Reset();
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Partner, UsageDataBilling.Partner::Customer);
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField("Billing Line Entry No.", BillingLine."Entry No.");
        until UsageDataBilling.Next() = 0;

        LibraryVariableStorage.Enqueue(2); //StrMenuHandlerClearBillingProposal
        BillingProposal.DeleteBillingProposal(BillingTemplate.Code);
        UsageDataBilling.Get(UsageDataBilling."Entry No.");
        UsageDataBilling.TestField("Billing Line Entry No.", 0);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestCreateContractInvoiceForMultipleCustomerContracts()
    begin
        // [SCENARIO] Contract invoices can be created for multiple customer contracts from a single usage data import
        // [GIVEN] Usage data billing for multiple customer contracts
        Initialize();
        for i := 1 to 2 do // create usage data for 3 different contracts
            CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));

        // [WHEN] Processing usage data and creating customer contract invoices
        UsageDataImport.Reset();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.Reset();

        // [THEN] Customer contract invoices are created successfully
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    procedure TestCreateContractInvoiceForMultipleVendorContracts()
    begin
        // [SCENARIO] Contract invoices can be created for multiple vendor contracts from a single usage data import
        // [GIVEN] Usage data billing for multiple vendor contracts
        Initialize();
        for i := 1 to 2 do // create usage data for 3 different contracts
            CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));

        // [WHEN] Processing usage data and creating vendor contract invoices
        UsageDataImport.Reset();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.Reset();

        // [THEN] Vendor contract invoices are created successfully
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestCreateContractInvoiceFromUsageDataImport()
    begin
        // [SCENARIO] Contract invoice can be created from usage data import for each usage-based pricing type
        // [GIVEN] Usage data billing for a given pricing type
        // [WHEN] Processing usage data billing and creating customer contract invoices
        // [THEN] Sales documents are created successfully
        CreateContractInvoiceFromUsageDataImportForPricingType("Usage Based Pricing"::"Usage Quantity");
        CreateContractInvoiceFromUsageDataImportForPricingType("Usage Based Pricing"::"Fixed Quantity");
        CreateContractInvoiceFromUsageDataImportForPricingType("Usage Based Pricing"::"Unit Cost Surcharge");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExchangeRateSelectionModalPageHandler')]
    procedure TestCreateContractInvoiceWithUsageBasedServiceCommitmentsWithUsageData()
    begin
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Usage data billing for a contract
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2)); // MessageHandler, ExchangeRateSelectionModalPageHandler
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [WHEN] Creating a billing proposal
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);

        // [THEN] A Billing Line should be created for Usage Based Subscription Lines with usage data
        BillingLine.Reset();
        Assert.AreEqual(false, BillingLine.IsEmpty, 'A new Billing Line should be created for Usage Based Service Commitments with usage data when creating an invoice from the contract');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestCreateInvoicesForMoreThanOneContractPerImportViaRecurringBilling()
    var
        CustomerContract2: Record "Customer Subscription Contract";
        ServiceObject2: Record "Subscription Header";
        UsageDataBilling: Record "Usage Data Billing";
        QuantityOfServiceCommitments: Integer;
    begin
        // [SCENARIO] Billing lines are created for usage-based subscription lines across multiple contracts when invoicing via Recurring Billing
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Two customer contracts each with a service object assigned
        ContractTestLibrary.CreateCustomer(Customer);
        ContractTestLibrary.CreateCustomerContract(CustomerContract, Customer."No.");
        ContractTestLibrary.CreateCustomerContract(CustomerContract2, Customer."No.");
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, '');
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract, SubscriptionHeader, false); // ExchangeRateSelectionModalPageHandler,MessageHandler
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract2, ServiceObject2, false); // ExchangeRateSelectionModalPageHandler,MessageHandler

        // [GIVEN] Subscription lines are marked as usage-based with usage data billing records
        SubscriptionLine.SetFilter("Subscription Header No.", '%1|%2', SubscriptionHeader."No.", ServiceObject2."No.");
        SubscriptionLine.ModifyAll("Usage Based Billing", true, "Usage Based Pricing", Enum::"Usage Based Pricing"::"Fixed Quantity");
        QuantityOfServiceCommitments := SubscriptionLine.Count();
        SubscriptionLine.FindSet();
        repeat
            CreateUsageDataBillingDummyDataFromSubscriptionLine(UsageDataBilling, UsageDataImport."Entry No.", SubscriptionLine);
        until SubscriptionLine.Next() = 0;

        // [WHEN] Creating a billing proposal via Recurring Billing
        ContractTestLibrary.CreateRecurringBillingTemplate(BillingTemplate, '<CM>', '', '', Enum::"Service Partner"::Customer);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);

        // [THEN] A billing line is created for each usage-based subscription line
        BillingLine.Reset();
        Assert.AreEqual(QuantityOfServiceCommitments, BillingLine.Count(), 'A new Billing Line should be created for each Usage Based Service Commitment and Contract with usage data when creating an invoice via "Usage Data Imports"');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure TestCreateInvoicesForMoreThanOneContractPerImportViaUsageDataImports()
    var
        CustomerContract2: Record "Customer Subscription Contract";
        ServiceObject2: Record "Subscription Header";
        UsageDataBilling: Record "Usage Data Billing";
        QuantityOfServiceCommitments: Integer;
    begin
        // [SCENARIO] Billing lines are created for usage-based subscription lines across multiple contracts when invoicing via Usage Data Imports
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Two customer contracts each with a service object assigned
        ContractTestLibrary.CreateCustomer(Customer);
        ContractTestLibrary.CreateCustomerContract(CustomerContract, Customer."No.");
        ContractTestLibrary.CreateCustomerContract(CustomerContract2, Customer."No.");
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, '');
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract, SubscriptionHeader, false); // ExchangeRateSelectionModalPageHandler,MessageHandler
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract2, ServiceObject2, false); // ExchangeRateSelectionModalPageHandler,MessageHandler

        // [GIVEN] Subscription lines are marked as usage-based with usage data billing records
        SubscriptionLine.SetFilter("Subscription Header No.", '%1|%2', SubscriptionHeader."No.", ServiceObject2."No.");
        SubscriptionLine.ModifyAll("Usage Based Billing", true, "Usage Based Pricing", Enum::"Usage Based Pricing"::"Fixed Quantity");
        QuantityOfServiceCommitments := SubscriptionLine.Count();
        SubscriptionLine.FindSet();
        repeat
            CreateUsageDataBillingDummyDataFromSubscriptionLine(UsageDataBilling, UsageDataImport."Entry No.", SubscriptionLine);
        until SubscriptionLine.Next() = 0;

        // [WHEN] Creating contract invoices via Usage Data Imports
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport); // CreateCustomerBillingDocumentPageHandler

        // [THEN] A billing line is created for each usage-based subscription line
        BillingLine.Reset();
        Assert.AreEqual(QuantityOfServiceCommitments, BillingLine.Count(), 'A new Billing Line should be created for each Usage Based Service Commitment and Contract with usage data when creating an invoice via "Usage Data Imports"');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure UsageDataBillingRecordsMustMatchGenericImportAfterCreation()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
        ExpectedSubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] After creating usage data billing, the resulting billing records must reflect
        // exactly the values from the generic import (amounts, dates, currency) and be linked
        // to the correct subscription line and customer contract.
        // [GIVEN] Usage data has been processed for fixed quantity pricing
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));

        // [WHEN] Usage data billing creation step completes
        UsageDataImport.FindLast();

        // [THEN] Import processing status is Ok
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        // [THEN] The customer billing record, its source generic import line, and the linked
        // subscription line are fetched and verified to be consistent with each other
        FindCustomerUsageDataBilling(UsageDataBilling, UsageDataImport."Entry No.");
        FindCustomerSubscriptionLine(ExpectedSubscriptionLine, SubscriptionHeader."No.");
        FindUsageDataGenericImport(UsageDataGenericImport, UsageDataImport."Entry No.");
        AssertUsageDataBillingMatchesImport(UsageDataGenericImport, UsageDataBilling, ExpectedSubscriptionLine);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestCreateUsageDataBillingDocumentsWhenBillingRequiredInBillingProposal()
    begin
        // [SCENARIO] Usage data billing documents can be created even when billing proposal requires update
        // [GIVEN] Usage data billing with a billing proposal and modified subscription line discount
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := false;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        CreateBillingProposalForSimpleCustomerContract();
        SubscriptionLine.Get(BillingLine."Subscription Line Entry No.");
        SubscriptionLine.Validate("Discount %", LibraryRandom.RandDec(50, 2));
        SubscriptionLine.Modify(true);

        // [WHEN] Collecting customer contracts and creating invoices
        // [THEN] No error occurs despite billing proposal requiring update
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
    end;

    [Test]
    procedure TestCreateUsageDataGenericImport()
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Usage data generic import records are created from an imported file
        // [GIVEN] Setup data and data exchange definition for processing an imported file
        Initialize();
        SetupUsageDataForProcessingToGenericImport();
        SetupDataExchangeDefinition();
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);

        // [WHEN] Creating imported lines
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");

        // [THEN] Usage data generic import record is created with None processing status
        Commit();
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        UsageDataGenericImport.TestField("Processing Status", Enum::"Processing Status"::None);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    procedure TestCreateVendorContractInvoiceFromUsageDataImport()
    begin
        // [SCENARIO] Vendor contract invoice can be created from usage data import
        // [GIVEN] Usage data billing for usage quantity pricing
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := false;

        // [WHEN] Processing usage data billing and creating vendor contract invoices
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);

        // [THEN] Purchase documents are created
        CheckIfPurchaseDocumentsHaveBeenCreated();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure TestDailySubscriptionWithDailyUsageData()
    begin
        // [SCENARIO] Daily subscription line with daily usage data creates correct billing
        TestSubscriptionWithUsageData('1D', WorkDate(), CalcDate('<CM>', WorkDate()), 2, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure TestDailySubscriptionWithMonthlyUsageData()
    begin
        // [SCENARIO] Daily subscription line with monthly usage data creates correct billing
        TestSubscriptionWithUsageData('1D', CalcDate('<CM>', WorkDate()), CalcDate('<CM>', WorkDate()), 2, false);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestDeleteUsageDataBilling()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Deleting usage data billing lines removes all related records and resets processing status
        // [GIVEN] Usage data billing records for fixed quantity pricing
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));

        // [WHEN] Deleting usage data billing lines
        UsageDataImport.DeleteUsageDataBillingLines();
        Commit(); // retain data after asserterror

        // [THEN] All usage data billing and generic import records are removed, processing status is reset
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        Assert.RecordIsEmpty(UsageDataBilling);
        Clear(UsageDataGenericImport);
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        Assert.RecordIsEmpty(UsageDataGenericImport);

        UsageDataImport.TestField("Processing Status", "Processing Status"::None);
        UsageDataImport.TestField("Processing Step", "Processing Step"::None);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestIfLastUsedNoRemainsInSalesOrderNos()
    var
        NoSeriesLine: Record "No. Series Line";
        LastUsedNo: Code[20];
    begin
        // [SCENARIO] Processing usage data billing does not consume sales order numbers
        // [GIVEN] The last used number from the sales order number series
        Initialize();
        SalesSetup.Get();
        NoSeriesLine.SetRange("Series Code", SalesSetup."Order Nos.");
        NoSeriesLine.FindLast();
        LastUsedNo := NoSeriesLine."Last No. Used";

        // [WHEN] Processing usage data billing
        CreateUsageDataBilling("Usage Based Pricing"::"Usage Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataSupplier."Unit Price from Import" := false;
        UsageDataSupplier.Modify(false);
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [THEN] Sales order number series remains unchanged
        NoSeriesLine.SetRange("Series Code", SalesSetup."Order Nos.");
        NoSeriesLine.FindLast();
        Assert.AreEqual(LastUsedNo, NoSeriesLine."Last No. Used", 'No Series changed after GetSalesPrice()');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestIfRelatedDataIsDeletedOnDeleteUsageDataImport()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Deleting a usage data import removes all related blobs, generic imports, and billing records
        // [GIVEN] Multiple usage data imports with billing records
        Initialize();
        j := LibraryRandom.RandIntInRange(2, 10);
        for i := 1 to j do
            CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));

        // [WHEN] Deleting each usage data import
        // [THEN] All related data (blobs, generic imports, billing) is removed
        UsageDataImport.Reset();
        UsageDataImport.FindSet();
        repeat
            UsageDataImport.Delete(true);
            // Commit before asserterror to keep data
            Commit();

            UsageDataBlob.Reset();
            UsageDataBlob.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
            Assert.RecordIsEmpty(UsageDataBlob);

            UsageDataGenericImport.Reset();
            UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
            Assert.RecordIsEmpty(UsageDataGenericImport);

            FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
            Assert.RecordIsEmpty(UsageDataBilling);
        until UsageDataImport.Next() = 0;
    end;

    [Test]
    procedure TestImportFileToUsageDataBlob()
    begin
        // [SCENARIO] Usage data file can be imported to a usage data blob
        // [GIVEN] Usage data setup for generic import processing
        Initialize();
        SetupUsageDataForProcessingToGenericImport();

        // [THEN] Usage data blob is created with correct import status and data
        UsageDataBlob.TestField("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataBlob.TestField("Import Status", Enum::"Processing Status"::Ok);
        UsageDataBlob.TestField(Data);
        UsageDataBlob.TestField("Data Hash Value");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure TestMonthlySubscriptionWithDailyUsageData()
    begin
        // [SCENARIO] Monthly subscription line with daily usage data creates correct billing
        TestSubscriptionWithUsageData('1M', WorkDate(), CalcDate('<CM>', WorkDate()), 2, false);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestOnlyProcessDataWithinBillingPeriod()
    var
        BillingDate1: Date;
        BillingDate2: Date;
        TestBillingDate: Date;
    begin
        // [SCENARIO] Only usage data within the billing period is processed; gaps between periods are skipped
        // [GIVEN] Two usage data imports for non-consecutive billing periods
        Initialize();
        BillingDate1 := WorkDate();
        TestBillingDate := CalcDate('<1M>', WorkDate());
        BillingDate2 := CalcDate('<2M>', WorkDate());
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", BillingDate1, CalcDate('<CM>', BillingDate1), BillingDate1, CalcDate('<CM>', BillingDate1), LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", BillingDate2, CalcDate('<CM>', BillingDate2), BillingDate2, CalcDate('<CM>', BillingDate2), LibraryRandom.RandDec(10, 2));
        PostDocument := false;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [THEN] The month between the two billing periods is not billed
        // Expect that month between BillingDate1 and BillingDate2 is skipped
        BillingLine.Reset();
        BillingLine.SetRange(Partner, "Service Partner"::Customer);
        BillingLine.SetRange("Subscription Line Start Date", CalcDate('<CM>', TestBillingDate));
        Assert.RecordIsEmpty(BillingLine);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestPriceCalculationInUsageBasedBasedOnDay()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        RoundingPrecision: Decimal;
    begin
        // [SCENARIO] Price calculation in usage-based billing with daily billing period uses subscription line price
        // [GIVEN] Service object with daily usage-based subscription lines and a single day of usage data
        Initialize();
        SetupUsageDataForProcessingToGenericImport(WorkDate(), WorkDate(), WorkDate(), WorkDate(), 1, false);
        SetupDataExchangeDefinition();
        ContractTestLibrary.CreateCustomer(Customer);
        CreateSubscriptionItemWithPrices(1, 1);
        SetupItemWithMultipleServiceCommitmentPackages();
        ContractTestLibrary.CreateServiceObjectForItem(SubscriptionHeader, Item."No.");
        SubscriptionHeader.InsertServiceCommitmentsFromStandardServCommPackages(WorkDate());
        SubscriptionHeader."End-User Customer No." := Customer."No.";
        SubscriptionHeader.Modify(false);
        CreateCustomerContractAndAssignServiceCommitments();
        CreateVendorContractAndAssignServiceCommitments();
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);

        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, "Usage Based Pricing"::"Usage Quantity", '1D', '1D');
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [THEN] Unit price in usage data billing matches the subscription line price
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.FindFirst();
        ProcessUsageDataBilling.SetRoundingPrecision(RoundingPrecision, UsageDataBilling."Unit Price", Currency);
        Assert.AreEqual(Round(SubscriptionLine.Price, RoundingPrecision), UsageDataBilling."Unit Price", 'Amount was not calculated properly in Usage data.');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestProcessImportedLinesWithZeroQuantity()
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Usage data with quantity 0 can be processed without error during "Process Imported Lines"
        Initialize();

        // [GIVEN] Usage data generic import with Quantity = 0
        SetupUsageDataForProcessingToGenericImport(WorkDate(), CalcDate('<CM>', WorkDate()), WorkDate(), CalcDate('<CM>', WorkDate()), 0);
        SetupDataExchangeDefinition();
        SetupServiceObjectAndContracts(WorkDate());
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);

        // [WHEN] Create and Process Imported Lines
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // [THEN] No error occurs - processing status should not be error due to zero quantity
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, "Usage Based Pricing"::"Usage Quantity");
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);

        // [THEN] Verify the processing was successful
        UsageDataGenericImport.FindFirst();
        Assert.AreEqual(Enum::"Processing Status"::Ok, UsageDataGenericImport."Processing Status", 'Processing of usage data with quantity 0 should succeed.');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestProcessUsageDataBilling()
    begin
        // [SCENARIO] Usage data billing can be processed to update subscription and subscription lines
        // [GIVEN] Usage data billing for fixed quantity pricing
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));

        // [WHEN] Processing usage data billing
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        // [THEN] Subscription and subscription lines are updated
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestProcessUsageDataBillingWithDiscount100()
    begin
        // [SCENARIO] Setup simple Customer Subscription Contract with Subscription Line marked as Usage based billing
        // Add 100% discount in Subscription Line
        // Processing of Usage data should proceed without an error

        // [GIVEN]: Setup Usage based Subscription Line and assign it to customer; Add Discount of 100% to the Subscription Lines
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));

        SubscriptionLine.Reset();
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.FindSet();
        repeat
            SubscriptionLine.Validate("Discount %", 100);
            SubscriptionLine.Modify(true);
        until SubscriptionLine.Next() = 0;

        // [WHEN] Expect no error to happen on processing usage data billing
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [THEN] Test if Processing Status Ok is set in Usage Data Import
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
    end;

    [Test]
    procedure TestProcessUsageDataBillingWithFixedQuantityAndPartialPeriods()
    var
        UsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        CalculatedAmount: Decimal;
        ExpectedResult: Decimal;
        RoundingPrecision: Decimal;
    begin
        // [SCENARIO] Fixed quantity pricing with partial billing periods calculates prorated amounts correctly
        // [GIVEN] A subscription line with monthly billing starting at the beginning of the month
        Initialize();
        CreateSubscriptionItemWithPrices(LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        SetupServiceDataForProcessing(Enum::"Usage Based Pricing"::"Fixed Quantity", "Calculation Base Type"::"Item Price", Enum::"Invoicing Via"::Contract,
                                       '1M', '1M', '1M', "Service Partner"::Customer, 100, Item."No.");

        SubscriptionLine.Reset();
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.SetRange(Partner, "Service Partner"::Customer);
        SubscriptionLine.FindFirst();

        SubscriptionLine.Validate("Subscription Line Start Date", CalcDate('<-CM>', WorkDate()));
        SubscriptionLine.Modify(false);
        ExpectedResult := SubscriptionLine.UnitPriceForPeriod(CalcDate('<-CM>', WorkDate()), WorkDate()) * SubscriptionHeader.Quantity;

        // [WHEN] Processing usage data with fixed quantity for a partial period
        ProcessUsageDataWithSimpleGenericImport(CalcDate('<-CM>', WorkDate()), WorkDate(), CalcDate('<-CM>', WorkDate()), WorkDate(), SubscriptionHeader.Quantity, "Usage Based Pricing"::"Fixed Quantity");

        // [THEN] The calculated amount matches the expected prorated amount
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        UsageDataBilling.CalcSums(Amount);
        CalculatedAmount := UsageDataBilling.Amount;
        Assert.RecordIsNotEmpty(UsageDataBilling);

        ProcessUsageDataBilling.SetRoundingPrecision(RoundingPrecision, CalculatedAmount, Currency);
        Assert.AreEqual(Round(ExpectedResult, RoundingPrecision), CalculatedAmount, 'Amount was not calculated properly in Usage data.');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestProcessUsageDataGenericImport()
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Processing usage data generic import creates supplier references for subscription, customer, and product
        // [GIVEN] Usage data imported and service object with contracts
        Initialize();
        SetupUsageDataForProcessingToGenericImport();
        SetupDataExchangeDefinition();
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();

        // [WHEN] Processing imported lines with service object and contracts set up
        SetupServiceObjectAndContracts(WorkDate());
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // [THEN] Supplier references for subscription, customer, subscription, and product are created
        CheckIfUsageDataSubscriptionIsCreated(UsageDataGenericImport);
        CheckIfUsageDataCustomerIsCreated(UsageDataGenericImport."Customer ID");
        CheckIfCustomerSupplierReferencesAreIsCreated(UsageDataGenericImport."Customer ID");
        CheckIfSubscriptionSupplierReferencesAreIsCreated(UsageDataGenericImport."Supp. Subscription ID");
        CheckIfProductSupplierReferencesAreIsCreated(UsageDataGenericImport."Product ID");
    end;

    [Test]
    procedure TestProratedAmountForDailyPrices()
    var
        BillingBasePeriod: DateFormula;
        ChargeEndDate: Date;
        ChargeStartDate: Date;
        BaseAmount: Decimal;
        ExpectedResult: Decimal;
        Result: Decimal;
    begin
        // [SCENARIO] Prorated amount for daily prices equals the base amount for a single day
        // [GIVEN] A subscription line with daily billing period and a one-day charge period
        Initialize();
        BaseAmount := 100;
        Evaluate(BillingBasePeriod, '1D');
        ChargeStartDate := CalcDate('<-CY>', WorkDate());
        ChargeEndDate := ChargeStartDate;
        MockServiceCommitment(SubscriptionLine, BillingBasePeriod, BillingBasePeriod, BaseAmount);

        // [WHEN] Calculating unit price for the period
        Result := SubscriptionLine.UnitPriceForPeriod(ChargeStartDate, ChargeEndDate);

        // [THEN] Result equals the base amount
        ExpectedResult := BaseAmount;
        Assert.AreEqual(Result, ExpectedResult, 'Amount was not calculated properly');
    end;

    [Test]
    procedure TestProratedAmountForMonthlyPrices()
    var
        BillingBasePeriod: DateFormula;
        ChargeEndDate: Date;
        ChargeStartDate: Date;
        BaseAmount: Decimal;
        ExpectedResult: Decimal;
        Result: Decimal;
    begin
        // [SCENARIO] Prorated amount for monthly prices scales correctly for full-year and partial-month periods
        // [GIVEN] A subscription line with monthly billing
        Initialize();
        BaseAmount := 100;
        Evaluate(BillingBasePeriod, '1M');

        // [WHEN] Calculating unit price for a full year
        ChargeStartDate := CalcDate('<-CY>', WorkDate());
        ChargeEndDate := CalcDate('<CY>', ChargeStartDate);
        MockServiceCommitment(SubscriptionLine, BillingBasePeriod, BillingBasePeriod, BaseAmount);
        Result := SubscriptionLine.UnitPriceForPeriod(ChargeStartDate, ChargeEndDate);

        // [THEN] Result equals 12 times the monthly base amount
        ExpectedResult := BaseAmount * 12;
        Assert.AreEqual(Result, ExpectedResult, 'Amount was not calculated properly');

        // [WHEN] Calculating unit price for a single month period
        ChargeStartDate := CalcDate('<15D>', ChargeStartDate);
        ChargeEndDate := CalcDate('<1M>', ChargeStartDate);
        MockServiceCommitment(SubscriptionLine, BillingBasePeriod, BillingBasePeriod, BaseAmount);
        Result := SubscriptionLine.UnitPriceForPeriod(ChargeStartDate, ChargeEndDate - 1);

        // [THEN] Result equals the monthly base amount
        Assert.AreEqual(Result, BaseAmount, 'Amount was not calculated properly');
    end;

    [Test]
    procedure TestProratedAmountForMonthlyPriceWithDailyUsageData()
    var
        BillingBasePeriod: DateFormula;
        ChargeEndDate: Date;
        ChargeStartDate: Date;
        BaseAmount: Decimal;
        ExpectedResult: Decimal;
        Result: Decimal;
        NoOfDaysInMonth1: Integer;
    begin
        // [SCENARIO] Prorated amount for monthly price with daily usage data is calculated by dividing the monthly price by days in month
        // [GIVEN] A subscription line with monthly billing and a single day charge period
        Initialize();
        BaseAmount := 100;
        Evaluate(BillingBasePeriod, '1M');
        ChargeStartDate := CalcDate('<-CY>', WorkDate());
        ChargeEndDate := ChargeStartDate;
        MockServiceCommitment(SubscriptionLine, BillingBasePeriod, BillingBasePeriod, BaseAmount);

        // [WHEN] Calculating unit price for a single day
        Result := SubscriptionLine.UnitPriceForPeriod(ChargeStartDate, ChargeEndDate);

        // [THEN] Result equals the monthly amount divided by the number of days in the month
        NoOfDaysInMonth1 := CalcDate('<CM>', ChargeEndDate) - ChargeStartDate + 1;
        ExpectedResult := BaseAmount * 1 / NoOfDaysInMonth1;

        Assert.AreEqual(Result, ExpectedResult, 'Amount was not calculated properly');
    end;

    [Test]
    procedure TestProratedAmountForYearlyPrices()
    var
        BillingBasePeriod: DateFormula;
        ChargeEndDate: Date;
        ChargeStartDate: Date;
        BaseAmount: Decimal;
        ExpectedResult: Decimal;
        Result: Decimal;
    begin
        // [SCENARIO] Prorated amount for yearly prices returns the full amount for a full year and prorates for partial periods
        // [GIVEN] A subscription line with yearly billing (12M and 1Y formats)
        Initialize();
        BaseAmount := 100;
        Evaluate(BillingBasePeriod, '12M');
        ChargeStartDate := CalcDate('<-CY>', WorkDate());
        ChargeEndDate := CalcDate('<CY>', ChargeStartDate);
        MockServiceCommitment(SubscriptionLine, BillingBasePeriod, BillingBasePeriod, BaseAmount);

        // [WHEN] Calculating unit price for a full year with 12M period
        Result := SubscriptionLine.UnitPriceForPeriod(ChargeStartDate, ChargeEndDate);

        // [THEN] Result equals the yearly base amount
        ExpectedResult := BaseAmount;
        Assert.AreEqual(ExpectedResult, Result, 'Amount was not calculated properly');

        // [WHEN] Calculating unit price for a full year with 1Y period
        Evaluate(BillingBasePeriod, '1Y');
        MockServiceCommitment(SubscriptionLine, BillingBasePeriod, BillingBasePeriod, BaseAmount);
        Result := SubscriptionLine.UnitPriceForPeriod(ChargeStartDate, ChargeEndDate);

        // [THEN] Result equals the yearly base amount
        Assert.AreEqual(ExpectedResult, Result, 'Amount was not calculated properly');

        // [WHEN] Calculating unit price for a single day with amount set to number of days in year
        BaseAmount := ChargeEndDate - ChargeStartDate + 1; // Set the Amount to number of days
        ChargeEndDate := ChargeStartDate;
        MockServiceCommitment(SubscriptionLine, BillingBasePeriod, BillingBasePeriod, BaseAmount);
        Result := SubscriptionLine.UnitPriceForPeriod(ChargeStartDate, ChargeEndDate);

        // [THEN] Result equals 1 (daily price)
        Assert.AreEqual(1, Result, 'Amount was not calculated properly');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExchangeRateSelectionModalPageHandler')]
    procedure TestSkipUsageBasedServiceCommitmentsWithoutUsageData()
    begin
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Setup simple Customer Subscription Contract with Subscription Line marked as Usage based billing
        // Try to create a billing proposal with Billing To Date (crucial)
        ContractTestLibrary.CreateMultipleServiceObjectsWithItemSetup(Customer, SubscriptionHeader, Item, 2);
        ContractTestLibrary.UpdateItemUnitCostAndPrice(Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2), false);

        ContractTestLibrary.CreateServiceCommitmentTemplateSetup(SubPackageLineTemplate, '<12M>', Enum::"Invoicing Via"::Contract);
        ContractTestLibrary.CreateServiceCommPackageAndAssignItemToServiceCommitmentSetup(SubPackageLineTemplate.Code, SubscriptionPackage, SubscriptionPackageLine, Item, '<12M>');
        SubscriptionPackageLine."Usage Based Billing" := true;
        SubscriptionPackageLine.Modify(false);
        ContractTestLibrary.InsertServiceCommitmentFromServiceCommPackageSetup(SubscriptionPackage, SubscriptionHeader);
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, SubscriptionHeader, Customer."No.");
        CustomerContract.SetRange("No.", CustomerContract."No.");
        CreateRecurringBillingTemplateSetupForCustomerContract('<2M-CM>', '<8M+CM>', CustomerContract.GetView());

        // [WHEN] Creating a billing proposal
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);

        // [THEN] No Billing Line should be created for Usage Based Subscription Lines without usage data
        BillingLine.Reset();
        Assert.AreEqual(true, BillingLine.IsEmpty, 'No Billing Line should be created for Usage Based Service Commitments without usage data');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure TestUsageDataBillingInvoiceQuantityWithZeroQuantityEntry()
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
        NonZeroQuantity: Decimal;
        CustomerId: Text[80];
        SubscriptionId: Text[80];
    begin
        // [SCENARIO] When usage data billing has entries with both non-zero and zero quantities (paused subscription),
        // the sales invoice line should use the last non-zero quantity
        Initialize();
        CreateSubscriptionItemWithPrices(LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Setup service data with Usage Quantity pricing
        SetupServiceDataForProcessing(Enum::"Usage Based Pricing"::"Usage Quantity", "Calculation Base Type"::"Item Price", Enum::"Invoicing Via"::Contract,
                                       '1M', '1M', '1Y', "Service Partner"::Customer, 100, Item."No.");

        // [GIVEN] Setup usage data for processing with non-zero quantity for first period
        NonZeroQuantity := LibraryRandom.RandIntInRange(1, 10);
        CustomerId := CopyStr(LibraryRandom.RandText(80), 1, 80);
        SubscriptionId := CopyStr(LibraryRandom.RandText(80), 1, 80);
        UsageBasedBTestLibrary.CreateUsageDataSupplier(UsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, true, Enum::"Vendor Invoice Per"::Import);
        UsageBasedBTestLibrary.CreateGenericImportSettings(GenericImportSettings, UsageDataSupplier."No.", true, true);
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, UsageDataSupplier."No.");
        RRef.GetTable(UsageDataGenericImport);
        UsageDataBlob.InsertFromUsageDataImport(UsageDataImport);
        UsageBasedBTestLibrary.CreateUsageDataCSVFileBasedOnRecordAndImportToUsageDataBlob(
             UsageDataBlob, RRef, CustomerId, SubscriptionId,
             SubscriptionHeader."No.", SubscriptionLine."Entry No.",
             WorkDate(), CalcDate('<CM>', WorkDate()), WorkDate(), CalcDate('<CM>', WorkDate()), NonZeroQuantity);

        // [GIVEN] Create a second CSV blob file with quantity 0 for a second period (paused period)
        UsageDataBlob.InsertFromUsageDataImport(UsageDataImport);
        UsageBasedBTestLibrary.CreateUsageDataCSVFileBasedOnRecordAndImportToUsageDataBlob(
             UsageDataBlob, RRef, CustomerId, SubscriptionId,
             SubscriptionHeader."No.", SubscriptionLine."Entry No.",
             CalcDate('<CM+1D>', WorkDate()), CalcDate('<CM+1M>', WorkDate()),
             CalcDate('<CM+1D>', WorkDate()), CalcDate('<CM+1M>', WorkDate()), 0);

        // [WHEN] Import and process CSV files into usage data generic import records
        SetupDataExchangeDefinition();
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // [WHEN] Link imported usage data to service commitments via supplier references
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        repeat
            PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, "Usage Based Pricing"::"Usage Quantity");
        until UsageDataGenericImport.Next() = 0;
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);

        // [WHEN] Create usage data billing records and generate contract invoices
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        PostDocument := false;
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [THEN] Sales line should have the non-zero quantity from the first usage data billing entry
        BillingLine.Reset();
        BillingLine.SetFilter("Document No.", '<>%1', '');
        BillingLine.FindFirst();
        SalesHeader.Get(Enum::"Sales Document Type"::Invoice, BillingLine."Document No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, "Sales Line Type"::Item);
        SalesLine.FindFirst();
        Assert.AreEqual(NonZeroQuantity, SalesLine.Quantity, 'Sales Line quantity should use the last non-zero usage data billing quantity.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure TestUsageDataImportWithMultipleUsageDataGenericImports()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
        BillingPeriodStartDate: Date;
        SubscriptionStartDate: Date;
        SubscriptionID: Text;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO] Verify that usage data import with multiple usage data generic imports creates correct billing and invoices

        // [GIVEN] Initialize the contracts and usage-based billing applications
        Initialize();
        ContractTestLibrary.InitContractsApp();

        // [GIVEN] Create a Subscription Item
        CreateSubscriptionItemWithPrices(LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Setup Subscription with Subscription Lines and usage quantity
        SetupServiceDataForProcessing(Enum::"Usage Based Pricing"::"Usage Quantity", Enum::"Calculation Base Type"::"Item Price", Enum::"Invoicing Via"::Contract,
                                       '1M', '1M', '1M', "Service Partner"::Customer, 100, Item."No.");

        // [WHEN] Create and process simple usage data
        UsageBasedBTestLibrary.CreateUsageDataSupplier(UsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, false, Enum::"Vendor Invoice Per"::Import);
        UsageBasedBTestLibrary.CreateGenericImportSettings(GenericImportSettings, UsageDataSupplier."No.", true, true);
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, UsageDataSupplier."No.");
        BillingPeriodStartDate := CalcDate('<-CM>', WorkDate());
        SubscriptionStartDate := CalcDate('<-CM>', WorkDate());
        SubscriptionID := LibraryRandom.RandText(80);
        for i := 1 to LibraryRandom.RandInt(10) do begin
            UsageBasedBTestLibrary.CreateSimpleUsageDataGenericImport(UsageDataGenericImport, UsageDataImport."Entry No.", SubscriptionHeader."No.", Customer."No.", Item."Unit Cost",
             BillingPeriodStartDate, CalcDate('<CM>', BillingPeriodStartDate), SubscriptionStartDate, CalcDate('<CM>', SubscriptionStartDate), LibraryRandom.RandInt(10));

            UsageDataGenericImport."Supp. Subscription ID" := CopyStr(SubscriptionID, 1, MaxStrLen(UsageDataGenericImport."Supp. Subscription ID"));
            UsageDataGenericImport.Modify();
            BillingPeriodStartDate := CalcDate('<1M>', BillingPeriodStartDate);
            SubscriptionStartDate := CalcDate('<1M>', SubscriptionStartDate);
        end;
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // [WHEN] Prepare Subscription Line and usage data generic import for usage billing
        UsageDataGenericImport.Reset();
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        repeat
            PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, Enum::"Usage Based Pricing"::"Usage Quantity", '1M', '1M', Calcdate('<-CM>', WorkDate()));
        until UsageDataGenericImport.Next() = 0;
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);

        // [WHEN] Process usage data import to create and process usage data billing
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");

        // [WHEN] Create contract invoice from usage data
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [THEN] Verify that Line Amount in the Invoice equals the sum of all Usage Billing Data Amounts
        UsageDataBilling.Reset();
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Partner, "Service Partner"::Customer);
        UsageDataBilling.CalcSums(Amount);
        ExpectedAmount := UsageDataBilling.Amount;
        UsageDataBilling.FindLast();

        SalesLine.SetRange("Document Type", "Sales Document Type"::Invoice);
        SalesLine.SetRange("Document No.", UsageDataBilling."Document No.");
        SalesLine.SetRange("Line No.", UsageDataBilling."Document Line No.");
        SalesLine.FindFirst();
        Assert.AreEqual(ExpectedAmount, SalesLine.Amount, 'Line Amount in the Invoice should be equal to the sum of all Usage Billing Data Amounts');
        Assert.AreEqual(UsageDataBilling.Quantity, SalesLine.Quantity, 'Quantity in the Invoice should be equal to the Quantity of Last Usage Billing Data');

        // [THEN] Verify that each Billing line corresponds to each Usage Data Billing
        BillingLine.Reset();
        BillingLine.SetRange("Document No.", UsageDataBilling."Document No.");
        BillingLine.FindFirst();
        repeat
            UsageDataBilling.SetRange("Document No.", BillingLine."Document No.");
            UsageDataBilling.SetRange("Charge Start Date", BillingLine."Billing from");
            UsageDataBilling.SetRange("Charge End Date", BillingLine."Billing to");
            UsageDataBilling.FindFirst();
            Assert.AreEqual(BillingLine.Amount, UsageDataBilling.Amount, 'Billing Line Amount should be equal to Usage Data Billing Amount');
            Assert.AreEqual(BillingLine."Service Object Quantity", UsageDataBilling.Quantity, 'Billing Line Quantity should be equal to Usage Data Billing Quantity');
        until BillingLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterDeletePurchaseCreditMemo()
    var
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        UsageDataBilling: Record "Usage Data Billing";
    begin
        //[SCENARIO]: Check that usage data billing is deleted after deleting purchase credit memo
        Initialize();
        PurchaseInvoiceHeader.DeleteAll(false);
        //[GIVEN] Usage Data import with Usage Data Billing
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        //[GIVEN] Create sales invoice from Usage Data Import
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
        PostPurchaseDocuments();
        PurchaseInvoiceHeader.FindLast();

        //[GIVEN] Create sales credit memo from sales invoice
        CorrectPostedPurchaseInvoice.CreateCreditMemoCopyDocument(PurchaseInvoiceHeader, PurchaseHeader);

        //[GIVEN] Usage Data Billing for sales credit memo
        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo("Service Partner"::Vendor, Enum::"Usage Based Billing Doc. Type"::"Credit Memo", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(UsageDataBilling);

        //[WHEN] Delete Purchase Credit Memo
        PurchaseHeader.Delete(true);

        //[THEN] Usage Data billing is deleted
        asserterror UsageDataBilling.Get(UsageDataBilling."Entry No.");
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterDeletePurchaseInvoice()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Deleting a purchase invoice resets usage data billing to no document
        // [GIVEN] Usage data billing with a created vendor contract invoice
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.MarkPurchaseHeaderFromUsageDataBilling(UsageDataBilling, PurchaseHeader);
        PurchaseHeader.FindSet();

        // [WHEN] Deleting the purchase invoice
        PurchaseHeader.Delete(true);

        // [THEN] Usage data billing is reset to no document
        TestIfRelatedUsageDataBillingIsUpdated("Service Partner"::Vendor, Enum::"Usage Based Billing Doc. Type"::None, '', false, 0);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterDeletePurchInvHeader()
    var
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO] Deleting a posted purchase invoice header resets usage data billing
        // [GIVEN] A posted purchase invoice from usage data billing
        Initialize();
        PurchaseInvoiceHeader.DeleteAll(false);

        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
        PostPurchaseDocuments();

        PurchaseInvoiceHeader.FindLast();
        PurchaseInvoiceHeader."No. Printed" := 1;
        PurchaseInvoiceHeader.Modify(false);

        PurchSetup.Get();
        PurchSetup."Allow Document Deletion Before" := CalcDate('<1D>', WorkDate());
        PurchSetup.Modify(false);

        // [WHEN] Deleting the posted purchase invoice header
        PurchaseInvoiceHeader.Delete(true);

        // [THEN] Usage data billing is reset to no document
        TestIfRelatedUsageDataBillingIsUpdated("Service Partner"::Vendor, Enum::"Usage Based Billing Doc. Type"::None, '', false, 0);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterDeleteSalesCreditMemo()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        //[SCENARIO]: Check that usage data billing is deleted after deleting sales credit memo
        Initialize();

        //[GIVEN] Usage Data Import with Usage Data Billing
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        //[GIVEN] Create sales invoice from Usage Data Import
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer, UsageDataBilling."Document Type"::"Posted Invoice");
        UsageDataBilling.FindFirst();
        SalesInvoiceHeader.Get(UsageDataBilling."Document No.");

        //[GIVEN] Create sales credit memo from sales invoice
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesCrMemoHeader);

        //[GIVEN] Usage Data Billing for sales credit memo
        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo("Service Partner"::Customer, Enum::"Usage Based Billing Doc. Type"::"Credit Memo", SalesCrMemoHeader."No.");
        UsageDataBilling.FindFirst();

        //[WHEN] Delete sales credit memo
        SalesCrMemoHeader.Delete(true);

        //[THEN] Usage Data Billing is deleted
        asserterror UsageDataBilling.Get(UsageDataBilling."Entry No.");
    end;


    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterDeleteSalesInvoice()
    begin
        // [SCENARIO] Deleting a sales invoice resets usage data billing to no document
        // [GIVEN] Usage data billing with created customer contract invoices
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := false;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [WHEN] Deleting each sales invoice
        // [THEN] Usage data billing is reset to no document
        BillingLine.FindSet();
        repeat
            SalesHeader.Get(Enum::"Sales Document Type"::Invoice, BillingLine."Document No.");
            SalesHeader.Delete(true);
            TestIfRelatedUsageDataBillingIsUpdated("Service Partner"::Customer, Enum::"Usage Based Billing Doc. Type"::None, '', false, 0);
        until BillingLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterDeleteSalesInvoiceHeader()
    begin
        // [SCENARIO] Deleting a posted sales invoice header resets usage data billing
        // [GIVEN] A posted sales invoice from usage data billing
        Initialize();
        SalesInvoiceHeader.DeleteAll(false);
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
        SalesInvoiceHeader.FindLast();
        SalesInvoiceHeader."No. Printed" := 1;
        SalesInvoiceHeader.Modify(false);

        SalesSetup.Get();
        SalesSetup."Allow Document Deletion Before" := CalcDate('<1D>', WorkDate());
        SalesSetup.Modify(false);

        // [WHEN] Deleting the posted sales invoice header
        SalesInvoiceHeader.Delete(true);

        // [THEN] Usage data billing is reset to no document
        TestIfRelatedUsageDataBillingIsUpdated("Service Partner"::Customer, Enum::"Usage Based Billing Doc. Type"::None, '', false, 0);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterInsertPurchaseCreditMemo()
    var
        UsageDataBilling: Record "Usage Data Billing";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO] Creating a purchase credit memo from a posted invoice creates additional usage data billing records
        // [GIVEN] A posted purchase invoice from usage data billing
        Initialize();
        PurchaseInvoiceHeader.DeleteAll(false);

        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
        PostPurchaseDocuments();
        PurchaseInvoiceHeader.FindLast();

        // [WHEN] Creating a credit memo from the posted purchase invoice
        CorrectPostedPurchaseInvoice.CreateCreditMemoCopyDocument(PurchaseInvoiceHeader, PurchaseHeader);

        // [THEN] Additional usage data billing record is created for the credit memo
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        Assert.RecordCount(UsageDataBilling, 2);

        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo(Enum::"Service Partner"::Vendor, Enum::"Usage Based Billing Doc. Type"::"Credit Memo", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(UsageDataBilling);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterInsertSalesCreditMemo()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Creating a sales credit memo from a posted invoice creates additional usage data billing records
        // [GIVEN] A posted sales invoice from usage data billing
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer, UsageDataBilling."Document Type"::"Posted Invoice");
        UsageDataBilling.FindFirst();
        SalesInvoiceHeader.Get(UsageDataBilling."Document No.");

        // [WHEN] Creating a credit memo from the posted sales invoice
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesCrMemoHeader);

        // [THEN] Additional usage data billing record is created for the credit memo
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        Assert.RecordCount(UsageDataBilling, 2);

        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo(Enum::"Service Partner"::Customer, Enum::"Usage Based Billing Doc. Type"::"Credit Memo", SalesCrMemoHeader."No.");
        Assert.RecordIsNotEmpty(UsageDataBilling);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterPostPurchaseCreditMemo()
    var
        UsageDataBilling: Record "Usage Data Billing";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO] Posting a purchase credit memo creates additional usage data billing records for the posted credit memo and a reset entry
        // [GIVEN] A posted purchase invoice and a credit memo created from it
        Initialize();
        PurchaseInvoiceHeader.DeleteAll(false);

        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);
        PostPurchaseDocuments();
        PurchaseInvoiceHeader.FindLast();
        CorrectPostedPurchaseInvoice.CreateCreditMemoCopyDocument(PurchaseInvoiceHeader, PurchaseHeader);
        PurchaseHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify(false);

        // [WHEN] Posting the purchase credit memo
        CorrectedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Three usage data billing records exist: posted invoice, posted credit memo, and reset entry
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        Assert.RecordCount(UsageDataBilling, 3);

        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo(Enum::"Service Partner"::Vendor, Enum::"Usage Based Billing Doc. Type"::"Posted Credit Memo", CorrectedDocumentNo);
        Assert.RecordIsNotEmpty(UsageDataBilling);

        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo(Enum::"Service Partner"::Vendor, Enum::"Usage Based Billing Doc. Type"::None, '');
        Assert.RecordIsNotEmpty(UsageDataBilling);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateVendorBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterPostPurchaseHeader()
    var
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO] Posting a purchase invoice updates usage data billing to reference the posted document
        // [GIVEN] Usage data billing with a created vendor contract invoice
        Initialize();
        PurchaseInvoiceHeader.DeleteAll(false);
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectVendorContractsAndCreateInvoices(UsageDataImport);

        // [WHEN] Posting the purchase invoice
        PostPurchaseDocuments();

        // [THEN] Usage data billing references the posted purchase invoice
        PurchaseInvoiceHeader.FindLast();
        TestIfRelatedUsageDataBillingIsUpdated("Service Partner"::Vendor, Enum::"Usage Based Billing Doc. Type"::"Posted Invoice", PurchaseInvoiceHeader."No.", true, 0);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterPostSalesCreditMemo()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] Posting a sales credit memo creates additional usage data billing records for the posted credit memo and a reset entry
        // [GIVEN] A posted sales invoice from usage data billing
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer, UsageDataBilling."Document Type"::"Posted Invoice");
        UsageDataBilling.FindFirst();

        SalesInvoiceHeader.Get(UsageDataBilling."Document No.");
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesCrMemoHeader);

        // [WHEN] Posting the sales credit memo
        CorrectedDocumentNo := LibrarySales.PostSalesDocument(SalesCrMemoHeader, true, true);

        // [THEN] Three usage data billing records exist: posted invoice, posted credit memo, and reset entry
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        Assert.RecordCount(UsageDataBilling, 3);

        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo(Enum::"Service Partner"::Customer, Enum::"Usage Based Billing Doc. Type"::"Posted Credit Memo", CorrectedDocumentNo);
        Assert.RecordIsNotEmpty(UsageDataBilling);

        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo(Enum::"Service Partner"::Customer, Enum::"Usage Based Billing Doc. Type"::None, '');
        Assert.RecordIsNotEmpty(UsageDataBilling);
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    procedure TestUpdateUsageBasedAfterPostSalesHeader()
    begin
        // [SCENARIO] Posting a sales invoice updates usage data billing to reference the posted document
        // [GIVEN] Usage data billing with a created customer contract invoice
        Initialize();
        SalesInvoiceHeader.DeleteAll(false);
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));
        PostDocument := true;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        // [THEN] Usage data billing references the posted sales invoice
        SalesInvoiceHeader.FindLast();
        TestIfRelatedUsageDataBillingIsUpdated("Service Partner"::Customer, "Usage Based Billing Doc. Type"::"Posted Invoice", SalesInvoiceHeader."No.", true, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure TestYearlySubscriptionWithDailyUsageData()
    begin
        // [SCENARIO] Yearly subscription line with daily usage data creates correct billing
        // Unit price set to number of days in the period to avoid rounding issues (Daily price = 1)
        TestSubscriptionWithUsageData('1Y', WorkDate(), WorkDate(), CalcDate('<1Y>', WorkDate()) - WorkDate(), true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure TestYearlySubscriptionWithMonthlyUsageData()
    begin
        // [SCENARIO] Yearly subscription line with monthly usage data creates correct billing
        // Unit price set to number of days in the period to avoid rounding issues (Daily price = 1)
        TestSubscriptionWithUsageData('1Y', CalcDate('<CM>', WorkDate()), CalcDate('<CM>', WorkDate()), CalcDate('<1Y>', WorkDate()) - WorkDate(), true);
    end;

    [Test]
    procedure UnitAmountForChargePeriodAddsDaysBeyondWholeBillingRhythms()
    var
        ChargePeriodAmount: Decimal;
    begin
        // [SCENARIO] Usage data covering one Billing Rhythm and some days of the next is charged the unit amount of the
        // whole Billing Rhythm and the share of the days in the following one.

        // [GIVEN] A Subscription Line priced per year and billed monthly
        Initialize();
        MockServiceCommitment(SubscriptionLine, '1Y', '1M');

        // [WHEN] The supplier Unit Cost of 372 per year, 31 per month, is passed on for usage data covering February 1
        // to March 15, 2026
        ChargePeriodAmount := SubscriptionLine.UnitAmountForChargePeriod(372, DMY2Date(1, 2, 2026), DMY2Date(15, 3, 2026));

        // [THEN] February and 15 of the 31 days of March are passed on: 31 + 31 * 15 / 31
        Assert.AreEqual(46, ChargePeriodAmount, 'The days beyond the whole Billing Rhythms must be charged the share of their Billing Rhythm.');
    end;

    [Test]
    procedure UnitAmountForChargePeriodChargesWholeBillingRhythmsOfLongerBillingBasePeriod()
    var
        ChargePeriodAmount: Decimal;
    begin
        // [SCENARIO] The supplier states its Unit Cost per Billing Base Period of the Subscription Line. Usage data
        // covering some Billing Rhythms of a longer Billing Base Period is charged their share of that Unit Cost.

        // [GIVEN] A Subscription Line priced per year and billed monthly
        Initialize();
        MockServiceCommitment(SubscriptionLine, '1Y', '1M');

        // [WHEN] The supplier Unit Cost of 1200 per year is passed on for usage data covering October to December
        ChargePeriodAmount := SubscriptionLine.UnitAmountForChargePeriod(1200, DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026));

        // [THEN] Three twelfths of the supplier Unit Cost are passed on
        Assert.AreEqual(300, ChargePeriodAmount, 'Three months of a Subscription Line priced per year must be charged three twelfths of the Unit Cost.');
    end;

    [Test]
    procedure UnitAmountForChargePeriodIsMultipliedForBillingRhythmLongerThanBillingBasePeriod()
    var
        ChargePeriodAmount: Decimal;
    begin
        // [SCENARIO] The supplier states its Unit Cost per Billing Base Period of the Subscription Line. Usage data
        // covering a Billing Rhythm of several Billing Base Periods is charged that Unit Cost for each of them.

        // [GIVEN] A Subscription Line priced per month and billed yearly
        Initialize();
        MockServiceCommitment(SubscriptionLine, '1M', '1Y');

        // [WHEN] The supplier Unit Cost of 100 per month is passed on for usage data covering the year 2026
        ChargePeriodAmount := SubscriptionLine.UnitAmountForChargePeriod(100, DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026));

        // [THEN] The supplier Unit Cost is passed on for each of the twelve months
        Assert.AreEqual(1200, ChargePeriodAmount, 'A year of a Subscription Line priced per month must be charged the Unit Cost twelve times.');
    end;

    [Test]
    procedure UnitAmountForChargePeriodIsMultipliedForChargePeriodLongerThanBillingBasePeriod()
    var
        ChargePeriodAmount: Decimal;
    begin
        // [SCENARIO] Usage data covering more than one Billing Base Period is charged the supplier Unit Cost for each
        // of them, like the Price of the Subscription Line.

        // [GIVEN] A Subscription Line priced and billed yearly
        Initialize();
        MockServiceCommitment(SubscriptionLine, '1Y', '1Y');

        // [WHEN] The supplier Unit Cost of 1200 per year is passed on for usage data covering the years 2026 and 2027
        ChargePeriodAmount := SubscriptionLine.UnitAmountForChargePeriod(1200, DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2027));

        // [THEN] The supplier Unit Cost is passed on twice
        Assert.AreEqual(2400, ChargePeriodAmount, 'Two years of a Subscription Line priced per year must be charged the Unit Cost twice.');
    end;

    [Test]
    procedure UnitAmountForChargePeriodKeepsUnitAmountForOneBillingBasePeriod()
    var
        ChargePeriodAmount: Decimal;
    begin
        // [SCENARIO] Usage data covering exactly one Billing Base Period is charged the supplier Unit Cost unchanged,
        // also when the Billing Rhythm is shorter.

        // [GIVEN] A Subscription Line priced per year and billed monthly
        Initialize();
        MockServiceCommitment(SubscriptionLine, '1Y', '1M');

        // [WHEN] The supplier Unit Cost of 1200 per year is passed on for usage data covering the year 2026
        ChargePeriodAmount := SubscriptionLine.UnitAmountForChargePeriod(1200, DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026));

        // [THEN] The supplier Unit Cost is passed on unchanged
        Assert.AreEqual(1200, ChargePeriodAmount, 'Usage data covering one Billing Base Period must keep the Unit Cost delivered by the supplier.');
    end;

    [Test]
    procedure UnitAmountForChargePeriodProratesChargePeriodShorterThanBillingBasePeriodByDays()
    var
        ChargePeriodAmount: Decimal;
    begin
        // [SCENARIO] Usage data covering only part of a yearly Billing Base Period, which is also the Billing Rhythm, is
        // charged the share of the days it covers.

        // [GIVEN] A Subscription Line priced and billed yearly
        Initialize();
        MockServiceCommitment(SubscriptionLine, '1Y', '1Y');

        // [WHEN] The supplier Unit Cost of 365 per year is passed on for usage data covering October to December
        ChargePeriodAmount := SubscriptionLine.UnitAmountForChargePeriod(365, DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026));

        // [THEN] 92 of 365 days are passed on
        Assert.AreEqual(92, ChargePeriodAmount, 'Usage data covering part of the Billing Base Period must be charged the share of its days.');
    end;

    [Test]
    procedure UnitAmountForChargePeriodUsesBillingBasePeriodForMonthOfQuarterlyBillingRhythm()
    var
        ChargePeriodAmount: Decimal;
    begin
        // [SCENARIO] Like Price and Unit Cost of the Subscription Line, the supplier Unit Cost is charged in steps of
        // the shorter of Billing Base Period and Billing Rhythm, so that a whole month is charged a whole month's amount.

        // [GIVEN] A Subscription Line priced per month and billed quarterly
        Initialize();
        MockServiceCommitment(SubscriptionLine, '1M', '3M');

        // [WHEN] The supplier Unit Cost of 100 per month is passed on for usage data covering February 2026
        ChargePeriodAmount := SubscriptionLine.UnitAmountForChargePeriod(100, DMY2Date(1, 2, 2026), DMY2Date(28, 2, 2026));

        // [THEN] The supplier Unit Cost is passed on unchanged
        Assert.AreEqual(100, ChargePeriodAmount, 'A whole month of a quarterly Billing Rhythm priced per month must be charged the Unit Cost.');
    end;

    [Test]
    procedure UnitAmountForChargePeriodUsesBillingBasePeriodForMonthOfYearlyBillingRhythm()
    var
        ChargePeriodAmount: Decimal;
    begin
        // [SCENARIO] Like Price and Unit Cost of the Subscription Line, the supplier Unit Cost is charged in steps of
        // the shorter of Billing Base Period and Billing Rhythm, so that a whole month is charged a whole month's amount.

        // [GIVEN] A Subscription Line priced per month and billed yearly
        Initialize();
        MockServiceCommitment(SubscriptionLine, '1M', '12M');

        // [WHEN] The supplier Unit Cost of 100 per month is passed on for usage data covering February 2026
        ChargePeriodAmount := SubscriptionLine.UnitAmountForChargePeriod(100, DMY2Date(1, 2, 2026), DMY2Date(28, 2, 2026));

        // [THEN] The supplier Unit Cost is passed on unchanged
        Assert.AreEqual(100, ChargePeriodAmount, 'A whole month of a yearly Billing Rhythm priced per month must be charged the Unit Cost.');
    end;

    [Test]
    procedure UnitCostSurchargeCreditCreditsCustomerAndKeepsPriceOfCustomerSubscriptionLine()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        CustomerUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        CustomerPriceBeforeCredit: Decimal;
    begin
        // [SCENARIO] A credit priced by "Unit Cost Surcharge" credits the customer the surcharge on the vendor cost of the
        // charge period, with the sign of the credited quantity. It does not state a new price for the customer.

        // [GIVEN] A yearly Subscription with a quantity of 10, priced by a unit cost surcharge of 10 % and billed from
        // usage data for the whole year at a supplier Unit Cost of 365 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, "Usage Based Pricing"::"Unit Cost Surcharge");
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        CustomerPriceBeforeCredit := CustomerSubscriptionLine.Price;

        // [GIVEN] Usage data crediting all 10 for October to December
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Unit Cost Surcharge");

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer is credited the surcharge on the vendor cost of 92 of 365 days: -(920 * 1.1)
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums(Amount);
        Assert.AreEqual(-1012, CustomerUsageDataBilling.Amount, 'The customer must be credited the surcharge on the vendor cost of the charge period.');

        // [THEN] The customer Unit Price stays positive, as for a credit priced by "Usage Quantity": 1012 / 10
        CustomerUsageDataBilling.FindFirst();
        Assert.AreEqual(101.2, CustomerUsageDataBilling."Unit Price", 'The customer Unit Price of a credit must not carry the sign of the quantity.');

        // [THEN] The customer Subscription Line keeps its Price
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(CustomerPriceBeforeCredit, CustomerSubscriptionLine.Price, 'A credit must not change the Price of the customer Subscription Line.');
    end;

    [Test]
    procedure UnitCostSurchargeCreditKeepsPriceOfVendorSubscriptionLine()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        VendorPriceBeforeCredit: Decimal;
    begin
        // [SCENARIO] A credit priced by "Unit Cost Surcharge" credits the vendor the supplier cost of the charge period.
        // It does not state a new price: it must be processed without an error - a negative Price cannot be stored on a
        // Subscription Line - and leave the vendor Price unchanged.

        // [GIVEN] A yearly Subscription with a quantity of 10, priced by a unit cost surcharge of 10 % and billed from
        // usage data for the whole year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, "Usage Based Pricing"::"Unit Cost Surcharge");
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorPriceBeforeCredit := VendorSubscriptionLine.Price;

        // [GIVEN] Usage data crediting all 10 for October to December at a supplier Unit Cost of 730 per year
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), -10, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 730, 0, '');

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The usage data billing is processed without an error
        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);

        // [THEN] The vendor is credited 92 of 365 days: 184 per unit
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(-1840, VendorUsageDataBilling."Cost Amount", 'The vendor must be credited the supplier cost of the charge period.');

        // [THEN] The vendor Subscription Line keeps its Price
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(VendorPriceBeforeCredit, VendorSubscriptionLine.Price, 'A credit must not change the Price of the vendor Subscription Line.');
    end;

    [Test]
    procedure UnitCostSurchargeCustomerPriceIsImportedPriceWhenUnitPriceIsFromImport()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        CustomerUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A supplier that delivers the Unit Price states the sales price. With "Unit Cost Surcharge" the
        // customer Subscription Line takes over the imported price, not a surcharge calculated on the supplier Unit Cost.

        // [GIVEN] A Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %, with usage data for the
        // whole year at a supplier Unit Cost of 365, from a supplier that delivers the Unit Price
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 365, 0, '');
        UsageDataSupplier."Unit Price from Import" := true;
        UsageDataSupplier.Modify(false);

        // [GIVEN] The imported sales price is 500 per unit, 5000 for the quantity of 10
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.FindFirst();
        CustomerUsageDataBilling."Unit Price" := 500;
        CustomerUsageDataBilling.Amount := 5000;
        CustomerUsageDataBilling.Modify(false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer usage data keeps the imported amount
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums(Amount);
        Assert.AreEqual(5000, CustomerUsageDataBilling.Amount, 'The customer usage data must keep the imported amount.');

        // [THEN] The customer Subscription Line takes over the imported price of 500, not 365 * 1.1 = 401.50
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(500, CustomerSubscriptionLine.Price, 'The customer Subscription Line must take over the imported price.');
    end;

    [Test]
    procedure UnitCostSurchargeCustomerPriceIsKeptWhenUsageDataCreditsQuantityOnBalance()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        UsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A delivery for the whole year and a larger credit for a part of the year still cover Billing Base
        // Periods on balance, but they add up to a negative quantity. With "Unit Cost Surcharge" such usage data is a
        // credit and does not state a new price for the customer.

        // [GIVEN] A yearly Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %, whose customer
        // Subscription Line costs 300 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        CustomerSubscriptionLine.Price := 300;
        CustomerSubscriptionLine.Modify(false);

        // [GIVEN] Usage data delivering 10 for the whole year at a Cost Amount of 3650, and crediting 12 for October to
        // December at a Cost Amount of -1104, the same cost of 1 per day
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, -12, "Usage Based Pricing"::"Unit Cost Surcharge", 365, 3650, '');
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Quantity, -12);
        UsageDataBilling.ModifyAll("Charge Start Date", DMY2Date(1, 10, 2026), false);
        UsageDataBilling.ModifyAll("Cost Amount", -1104, false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer Subscription Line keeps its Price
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(300, CustomerSubscriptionLine.Price, 'Usage data crediting a quantity on balance must not change the customer Price.');
    end;

    [Test]
    procedure UnitCostSurchargeCustomerPriceIsStoredPerBillingBasePeriod()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        CustomerUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Both the Price of a Subscription Line and the supplier Unit Cost are stated per Billing Base
        // Period. With "Unit Cost Surcharge" the customer Subscription Line must take over the surcharge on the supplier
        // Unit Cost per Billing Base Period, not on the cost of the shorter charge period.

        // [GIVEN] A Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %, whose customer
        // Subscription Line costs 300 per year and is billed monthly
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 1200, 0, '');
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        CustomerSubscriptionLine.Price := 300;
        Evaluate(CustomerSubscriptionLine."Billing Rhythm", '<1M>');
        CustomerSubscriptionLine.Modify(false);

        // [WHEN] Usage data for October to December with a supplier Unit Cost of 1200 per year is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer is charged the surcharge on the supplier Unit Cost of the three months of its Subscription
        // Line: 1200 * 3 / 12 * 1.1 * 10
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums(Amount);
        Assert.AreEqual(3300, CustomerUsageDataBilling.Amount, 'The customer must be charged the surcharge on the supplier Unit Cost of the charge period.');

        // [THEN] The customer Subscription Line costs 1200 * 1.1 = 1320 per year, not the 330 charged for October to December
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(1320, CustomerSubscriptionLine.Price, 'The customer Subscription Line must take over the surcharge on the supplier Unit Cost per Billing Base Period.');
    end;

    [Test]
    procedure UnitCostSurchargeCustomerSubscriptionLineIsNotChangedWhenSupplierUnitCostIsUnchanged()
    var
        CustomerSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        CalculationBaseAmountBeforeProcessing: Decimal;
    begin
        // [SCENARIO] With "Unit Cost Surcharge" the customer Price per Billing Base Period is compared with the Price of
        // the Subscription Line, not with the amount of the shorter charge period, so that an unchanged supplier Unit
        // Cost leaves the customer Subscription Line as it is.

        // [GIVEN] A yearly Subscription priced by a unit cost surcharge of 10 %, whose customer Subscription Line already
        // costs the surcharge on the supplier Unit Cost: 365 * 1.1 = 401.5 per year. Its Calculation Base Amount does not
        // match that Price, so that a recalculation of the line would show.
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        CustomerSubscriptionLine.Price := 401.5;
        CustomerSubscriptionLine."Calculation Base Amount" := 1000;
        CustomerSubscriptionLine.Modify(false);
        CalculationBaseAmountBeforeProcessing := CustomerSubscriptionLine."Calculation Base Amount";

        // [WHEN] Usage data for October to December with a supplier Unit Cost of 365 per year is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Unit Cost Surcharge");
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer Subscription Line is not recalculated
        GetSubscriptionLineForPartner(CustomerSubscriptionLine, "Service Partner"::Customer);
        Assert.AreEqual(401.5, CustomerSubscriptionLine.Price, 'An unchanged supplier Unit Cost must keep the Price of the customer Subscription Line.');
        Assert.AreEqual(CalculationBaseAmountBeforeProcessing, CustomerSubscriptionLine."Calculation Base Amount", 'An unchanged supplier Unit Cost must not recalculate the customer Subscription Line.');
    end;

    [Test]
    procedure UnitCostSurchargeIsPutOnDeliveredCostAmountForCustomer()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A supplier that delivers a Cost Amount has already calculated the cost of the charge period. With
        // "Unit Cost Surcharge" the customer is charged the surcharge on that Cost Amount, not on a cost derived from the
        // supplier Unit Cost.

        // [GIVEN] A yearly Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);

        // [WHEN] Usage data for October to December with a Unit Cost of 365 and a Cost Amount of 1000 is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 365, 1000, '');
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged the delivered Cost Amount
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(1000, VendorUsageDataBilling."Cost Amount", 'The vendor must be charged the delivered Cost Amount.');

        // [THEN] The customer is charged the surcharge on the delivered Cost Amount: 1000 * 1.1
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums(Amount);
        Assert.AreEqual(1100, CustomerUsageDataBilling.Amount, 'The customer must be charged the surcharge on the delivered Cost Amount.');
    end;

    [Test]
    procedure UnitCostSurchargeIsPutOnSupplierUnitCostOfChargePeriodForMonthlyBillingRhythm()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] The supplier states its Unit Cost per Billing Base Period. For Subscription Lines priced per year
        // and billed monthly, usage data for three months costs three twelfths of the supplier Unit Cost, and with
        // "Unit Cost Surcharge" the customer is charged the surcharge on that cost.

        // [GIVEN] A Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %, whose customer and
        // vendor Subscription Lines are priced per year and billed monthly
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Unit Cost Surcharge", 1200, 0, '');
        SetBillingRhythmOnSubscriptionLine("Service Partner"::Customer, '<1M>');
        SetBillingRhythmOnSubscriptionLine("Service Partner"::Vendor, '<1M>');

        // [WHEN] Usage data for October to December with a supplier Unit Cost of 1200 per year is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged three twelfths of the supplier Unit Cost for each unit: 1200 * 3 / 12 * 10
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(3000, VendorUsageDataBilling."Cost Amount", 'The vendor must be charged the supplier Unit Cost for the three Billing Rhythms of the charge period.');

        // [THEN] The customer is charged the surcharge on that cost: 3000 * 1.1
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.CalcSums(Amount);
        Assert.AreEqual(3300, CustomerUsageDataBilling.Amount, 'The customer must be charged the surcharge on the vendor cost of the charge period.');
    end;

    [Test]
    procedure UnitCostSurchargeVendorPriceIsCalculatedFromDeliveredQuantity()
    var
        VendorSubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO] With "Unit Cost Surcharge" the Subscription keeps its quantity, while the supplier may deliver a
        // different one. The vendor Price is calculated from the delivered quantity, not from the subscribed one.

        // [GIVEN] A yearly Subscription with a quantity of 10, priced by a unit cost surcharge of 10 %, whose vendor
        // Subscription Line costs 300 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        SetPricingUnitCostSurchargeOnSubscriptionLines(10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine.Modify(false);

        // [WHEN] Usage data delivering a quantity of 4 for the whole year with a supplier Unit Cost of 365 is processed
        ProcessYearlyUsageDataImport(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 4, "Usage Based Pricing"::"Unit Cost Surcharge");

        // [THEN] The vendor Subscription Line costs the supplier Unit Cost
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(365, VendorSubscriptionLine.Price, 'The vendor Price must be calculated from the delivered quantity.');
    end;

    [Test]
    procedure UnknownUsageBasedPricingKeepsImportedCostForCustomerUsageData()
    var
        CustomerUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] "Usage Based Pricing" is extensible. Customer usage data that is priced by an option of an extension
        // keeps the imported Cost Amount, because only the extension knows what the cost of that option covers.

        // [GIVEN] Usage data for October to December with a supplier Unit Cost of 365 per year, from a supplier that
        // delivers the Unit Price, so that no pricing option has to price the customer usage data
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10);
        UsageDataSupplier."Unit Price from Import" := true;
        UsageDataSupplier.Modify(false);

        // [GIVEN] The customer usage data billing is priced by an option that no extension handles. The customer
        // Subscription Line keeps a known option, so that the processing of the Subscription Line completes.
        FilterUsageDataBillingOnUsageDataImport(CustomerUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        CustomerUsageDataBilling.FindFirst();
        CustomerUsageDataBilling."Usage Base Pricing" := Enum::"Usage Based Pricing"::"Test Above Unit Cost Surcharge";
        CustomerUsageDataBilling.Modify(false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The customer usage data keeps the imported Cost Amount: 365 * 10, not the cost of the charge period
        CustomerUsageDataBilling.Get(CustomerUsageDataBilling."Entry No.");
        Assert.AreEqual(3650, CustomerUsageDataBilling."Cost Amount", 'An unknown pricing option must keep the imported Cost Amount of the customer usage data.');
    end;

    [Test]
    procedure UnknownUsageBasedPricingKeepsImportedCostForVendorSubscriptionLine()
    var
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] "Usage Based Pricing" is extensible. An extension that adds a pricing option and handles the events
        // that existed before vendor usage data was priced does not know the vendor pricing event. Pricing the vendor
        // usage data must therefore keep the imported Cost Amount instead of failing.

        // [GIVEN] Usage data for October to December with a supplier Unit Cost of 365 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10);

        // [GIVEN] The vendor usage data billing is priced by an option that no extension handles. The vendor Subscription
        // Line keeps a known option, so that the processing of the Subscription Line completes and nothing is rolled back.
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Vendor);
        VendorUsageDataBilling.FindFirst();
        VendorUsageDataBilling."Usage Base Pricing" := Enum::"Usage Based Pricing"::"Test Above Unit Cost Surcharge";
        VendorUsageDataBilling.Modify(false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor keeps the imported Cost Amount: 365 * 10, not the cost prorated to the charge period
        VendorUsageDataBilling.Get(VendorUsageDataBilling."Entry No.");
        Assert.AreEqual(3650, VendorUsageDataBilling."Cost Amount", 'An unknown pricing option must keep the imported Cost Amount.');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure UpdatingServiceObjectAvailabilityDuringProcessing()
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
        ItemReference: Record "Item Reference";
    begin
        // [SCENARIO]: The Subscription Availability should be properly updated after processing imported lines
        // When there is no available Subscription to be connected to the imported line status should be "Not Available"
        // When there is available Subscription to be connected to the imported line status should be "Available"
        // When a Subscription is connected to the imported line status should be "Connected"

        // [GIVEN]: Setup Generic Connector and import lines from a file
        Initialize();
        SetupUsageDataForProcessingToGenericImport();
        ContractTestLibrary.CreateVendor(Vendor);
        UsageDataSupplier.Validate("Vendor No.", Vendor."No.");
        UsageDataSupplier.Modify(false);
        SetupDataExchangeDefinition();
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);
        SetupServiceObjectAndContracts(WorkDate());
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");

        // [WHEN]: process imported lines
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // [THEN]: Test if Subscription Availability is set to "Not Available"
        ValidateUsageDataGenericImportAvailability(UsageDataImport."Entry No.", "Service Object Availability"::"Not Available", '');

        // [WHEN]: insert an item reference to a usage data supplier reference
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        UsageDataSubscription.FindForSupplierReference(UsageDataImport."Supplier No.", UsageDataGenericImport."Supp. Subscription ID");
        UsageDataSupplierReference.FindSupplierReference(UsageDataImport."Supplier No.", UsageDataSubscription."Product ID", Enum::"Usage Data Reference Type"::Product);
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", "Item Reference Type"::Vendor, UsageDataSupplier."Vendor No.");
        ItemReference."Supplier Ref. Entry No." := UsageDataSupplierReference."Entry No.";
        ItemReference.Modify(false);
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // [THEN]: Test if Subscription Availability is set to "Available"
        ValidateUsageDataGenericImportAvailability(UsageDataImport."Entry No.", "Service Object Availability"::Available, '');

        // [WHEN]: insert an subscription reference is set for Subscription Line
        UsageDataSupplierReference.FindSupplierReference(UsageDataImport."Supplier No.", UsageDataGenericImport."Supp. Subscription ID", Enum::"Usage Data Reference Type"::Subscription);
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.SetRange(Partner, Enum::"Service Partner"::Vendor);
        SubscriptionLine.FindFirst();
        SubscriptionLine."Supplier Reference Entry No." := UsageDataSupplierReference."Entry No.";
        SubscriptionLine.Modify(false);
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // [THEN]: Test if Subscription Availability is set to "Connected"
        ValidateUsageDataGenericImportAvailability(UsageDataImport."Entry No.", "Service Object Availability"::Connected, SubscriptionHeader."No.");
    end;

    [Test]
    procedure UpgradeKeepsCostAmountDeliveredBySupplierForProcessing()
    var
        UsageDataBilling: Record "Usage Data Billing";
        VendorUsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        UpgradeSubscriptionBilling: Codeunit "Upgrade Subscription Billing";
        DeliveredUsageDataImportEntryNo: Integer;
        DerivedUsageDataImportEntryNo: Integer;
    begin
        // [SCENARIO] A supplier that delivers a Cost Amount only gets a Unit Cost derived from it, so that the Cost Amount
        // of usage data billing created before the upgrade is the Unit Cost times the Quantity as well. The upgrade must
        // not state that this Cost Amount is derived from the Unit Cost, and processing it afterwards keeps the Cost
        // Amount the supplier delivered.

        // [GIVEN] A yearly Subscription with a quantity of 10
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);

        // [GIVEN] Usage data for October to December whose supplier delivered a Cost Amount of 1000 and no Unit Cost,
        // stored as before the upgrade, with a Unit Cost of 100 derived from the Cost Amount
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 0, 1000, '');
        DeliveredUsageDataImportEntryNo := UsageDataImport."Entry No.";
        ResetCostAmountFromUnitCost(DeliveredUsageDataImportEntryNo);
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, DeliveredUsageDataImportEntryNo, "Service Partner"::Vendor);
        VendorUsageDataBilling.FindFirst();
        VendorUsageDataBilling.TestField("Unit Cost", 100);
        VendorUsageDataBilling.TestField("Cost Amount", 1000);

        // [GIVEN] Usage data for October to December whose supplier delivered a Unit Cost of 365 and no Cost Amount,
        // stored as before the upgrade, with a Cost Amount of 3650 derived from the Unit Cost
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 365, 0, '');
        DerivedUsageDataImportEntryNo := UsageDataImport."Entry No.";
        ResetCostAmountFromUnitCost(DerivedUsageDataImportEntryNo);

        // [WHEN] The upgrade sets "Cost Amount from Unit Cost" on the existing usage data billing
        UpgradeSubscriptionBilling.SetCostAmountFromUnitCostInUsageDataBilling();

        // [THEN] Only the usage data billing whose supplier delivered no Cost Amount is stated to be derived from the Unit Cost
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, DeliveredUsageDataImportEntryNo);
        UsageDataBilling.SetRange("Cost Amount from Unit Cost", true);
        Assert.RecordIsEmpty(UsageDataBilling);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, DerivedUsageDataImportEntryNo);
        Assert.RecordCount(UsageDataBilling, 2);
        UsageDataBilling.SetRange("Cost Amount from Unit Cost", false);
        Assert.RecordIsEmpty(UsageDataBilling);

        // [WHEN] The usage data billing with the delivered Cost Amount is processed
        UsageDataImport.Get(DeliveredUsageDataImportEntryNo);
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor is charged the delivered Cost Amount of 1000, not 100 for 92 of 365 days times 10 = 252.05
        FilterUsageDataBillingOnUsageDataImport(VendorUsageDataBilling, DeliveredUsageDataImportEntryNo, "Service Partner"::Vendor);
        VendorUsageDataBilling.CalcSums("Cost Amount");
        Assert.AreEqual(1000, VendorUsageDataBilling."Cost Amount", 'A Cost Amount delivered by the supplier must be kept after the upgrade.');
    end;

    [Test]
    procedure UpgradeMarksCostAmountOfUninvoicedUsageDataBillingAsDerivedFromUnitCost()
    var
        ClosedImportUsageDataBilling: Record "Usage Data Billing";
        CreditUsageDataBilling: Record "Usage Data Billing";
        DeliveredUsageDataBilling: Record "Usage Data Billing";
        DeliveredWithUnitCostUsageDataBilling: Record "Usage Data Billing";
        DerivedUsageDataBilling: Record "Usage Data Billing";
        DisagreeingUsageDataBilling: Record "Usage Data Billing";
        InvoicedUsageDataBilling: Record "Usage Data Billing";
        NoImportUsageDataBilling: Record "Usage Data Billing";
        NotImportedUsageDataBilling: Record "Usage Data Billing";
        ZeroQuantityUsageDataBilling: Record "Usage Data Billing";
        ZeroUnitCostUsageDataBilling: Record "Usage Data Billing";
        UpgradeSubscriptionBilling: Codeunit "Upgrade Subscription Billing";
        ClosedUsageDataImportEntryNo: Integer;
        FailedUsageDataImportEntryNo: Integer;
        OpenUsageDataImportEntryNo: Integer;
    begin
        // [SCENARIO] Usage data billing created before the upgrade does not state whether its Cost Amount was derived
        // from the Unit Cost. The upgrade states it for usage data billing that can still be processed - it is not yet invoiced
        // and its usage data import is not closed - and whose imported line delivered a Unit Cost but no Cost Amount, so that
        // processing it calculates the cost for the charge period.
        Initialize();

        // [GIVEN] Two usage data imports that are not closed, one of them with an error, and a closed usage data import
        OpenUsageDataImportEntryNo := MockUsageDataImport(Enum::"Processing Status"::None);
        FailedUsageDataImportEntryNo := MockUsageDataImport(Enum::"Processing Status"::Error);
        ClosedUsageDataImportEntryNo := MockUsageDataImport(Enum::"Processing Status"::Closed);
        // [GIVEN] Usage data billing of the imports that are not closed that is not invoiced, imported with a Unit Cost and
        // without a Cost Amount: a delivery and a credit
        MockUsageDataBillingWithCost(DerivedUsageDataBilling, OpenUsageDataImportEntryNo, '', 10, 1200, 12000);
        MockUsageDataGenericImport(DerivedUsageDataBilling, 1200, 0);
        MockUsageDataBillingWithCost(CreditUsageDataBilling, FailedUsageDataImportEntryNo, '', -10, 1200, -12000);
        MockUsageDataGenericImport(CreditUsageDataBilling, 1200, 0);
        // [GIVEN] Usage data billing that is not invoiced, imported with a Cost Amount: without a Unit Cost, so that its Unit
        // Cost of 100 is derived from the Cost Amount of 1000, and with a Unit Cost
        MockUsageDataBillingWithCost(DeliveredUsageDataBilling, OpenUsageDataImportEntryNo, '', 10, 100, 1000);
        MockUsageDataGenericImport(DeliveredUsageDataBilling, 0, 1000);
        MockUsageDataBillingWithCost(DeliveredWithUnitCostUsageDataBilling, OpenUsageDataImportEntryNo, '', 10, 1200, 3024.66);
        MockUsageDataGenericImport(DeliveredWithUnitCostUsageDataBilling, 1200, 3024.66);
        // [GIVEN] Usage data billing that is not invoiced, with a Cost Amount of Unit Cost times Quantity, without an imported
        // line, and with two imported lines of which only one delivered a Cost Amount
        MockUsageDataBillingWithCost(NotImportedUsageDataBilling, OpenUsageDataImportEntryNo, '', 10, 1200, 12000);
        MockUsageDataBillingWithCost(DisagreeingUsageDataBilling, OpenUsageDataImportEntryNo, '', 10, 1200, 12000);
        MockUsageDataGenericImport(DisagreeingUsageDataBilling, 1200, 0);
        MockUsageDataGenericImport(DisagreeingUsageDataBilling, 1200, 12000);
        // [GIVEN] Invoiced usage data billing, imported with a Unit Cost and without a Cost Amount
        MockUsageDataBillingWithCost(InvoicedUsageDataBilling, OpenUsageDataImportEntryNo, LibraryUtility.GenerateGUID(), 10, 1200, 12000);
        MockUsageDataGenericImport(InvoicedUsageDataBilling, 1200, 0);
        // [GIVEN] Usage data billing that is not invoiced, without a Quantity or without a Unit Cost
        MockUsageDataBillingWithCost(ZeroQuantityUsageDataBilling, OpenUsageDataImportEntryNo, '', 0, 1200, 0);
        MockUsageDataGenericImport(ZeroQuantityUsageDataBilling, 1200, 0);
        MockUsageDataBillingWithCost(ZeroUnitCostUsageDataBilling, OpenUsageDataImportEntryNo, '', 10, 0, 0);
        MockUsageDataGenericImport(ZeroUnitCostUsageDataBilling, 0, 0);
        // [GIVEN] Usage data billing that is not invoiced, imported with a Unit Cost and without a Cost Amount, of the closed
        // usage data import and without a usage data import
        MockUsageDataBillingWithCost(ClosedImportUsageDataBilling, ClosedUsageDataImportEntryNo, '', 10, 1200, 12000);
        MockUsageDataGenericImport(ClosedImportUsageDataBilling, 1200, 0);
        MockUsageDataBillingWithCost(NoImportUsageDataBilling, 0, '', 10, 1200, 12000);
        MockUsageDataGenericImport(NoImportUsageDataBilling, 1200, 0);

        // [WHEN] The upgrade sets "Cost Amount from Unit Cost" on the existing usage data billing
        UpgradeSubscriptionBilling.SetCostAmountFromUnitCostInUsageDataBilling();

        // [THEN] The Cost Amount of an imported line without a Cost Amount is stated to be derived from the Unit Cost
        DerivedUsageDataBilling.Get(DerivedUsageDataBilling."Entry No.");
        Assert.IsTrue(DerivedUsageDataBilling."Cost Amount from Unit Cost", 'A Cost Amount the supplier did not deliver must be stated to be derived from the Unit Cost.');
        CreditUsageDataBilling.Get(CreditUsageDataBilling."Entry No.");
        Assert.IsTrue(CreditUsageDataBilling."Cost Amount from Unit Cost", 'A credited Cost Amount the supplier did not deliver must be stated to be derived from the Unit Cost.');

        // [THEN] A Cost Amount the supplier delivered is kept as delivered, also when it is the Unit Cost times the Quantity
        DeliveredUsageDataBilling.Get(DeliveredUsageDataBilling."Entry No.");
        Assert.IsFalse(DeliveredUsageDataBilling."Cost Amount from Unit Cost", 'A Cost Amount the supplier delivered without a Unit Cost must be kept as delivered.');
        DeliveredWithUnitCostUsageDataBilling.Get(DeliveredWithUnitCostUsageDataBilling."Entry No.");
        Assert.IsFalse(DeliveredWithUnitCostUsageDataBilling."Cost Amount from Unit Cost", 'A Cost Amount the supplier delivered with a Unit Cost must be kept as delivered.');

        // [THEN] A Cost Amount whose imported line is missing or ambiguous is kept as it is
        NotImportedUsageDataBilling.Get(NotImportedUsageDataBilling."Entry No.");
        Assert.IsFalse(NotImportedUsageDataBilling."Cost Amount from Unit Cost", 'Usage data billing without an imported line must not be changed.');
        DisagreeingUsageDataBilling.Get(DisagreeingUsageDataBilling."Entry No.");
        Assert.IsFalse(DisagreeingUsageDataBilling."Cost Amount from Unit Cost", 'Usage data billing whose imported lines disagree must not be changed.');

        // [THEN] Invoiced usage data billing is not changed
        InvoicedUsageDataBilling.Get(InvoicedUsageDataBilling."Entry No.");
        Assert.IsFalse(InvoicedUsageDataBilling."Cost Amount from Unit Cost", 'Invoiced usage data billing must not be changed.');

        // [THEN] Usage data billing without a Quantity or without a Unit Cost is not changed
        ZeroQuantityUsageDataBilling.Get(ZeroQuantityUsageDataBilling."Entry No.");
        Assert.IsFalse(ZeroQuantityUsageDataBilling."Cost Amount from Unit Cost", 'Usage data billing without a Quantity must not be changed.');
        ZeroUnitCostUsageDataBilling.Get(ZeroUnitCostUsageDataBilling."Entry No.");
        Assert.IsFalse(ZeroUnitCostUsageDataBilling."Cost Amount from Unit Cost", 'Usage data billing without a Unit Cost must not be changed.');

        // [THEN] Usage data billing that is not processed again is not changed
        ClosedImportUsageDataBilling.Get(ClosedImportUsageDataBilling."Entry No.");
        Assert.IsFalse(ClosedImportUsageDataBilling."Cost Amount from Unit Cost", 'Usage data billing of a closed usage data import must not be changed.');
        NoImportUsageDataBilling.Get(NoImportUsageDataBilling."Entry No.");
        Assert.IsFalse(NoImportUsageDataBilling."Cost Amount from Unit Cost", 'Usage data billing without a usage data import must not be changed.');
    end;

    [Test]
    procedure UT_ValidateBillingLineNoRelation()
    var
        BillingLines: array[4] of Record "Billing Line";
        BillingLinesArchive: array[4] of Record "Billing Line Archive";
        UsageDataBillings: array[4, 2] of Record "Usage Data Billing";
    begin
        // [SCENARIO] Validate Billing Line No. table relation in Usage Data Billings

        // [GIVEN] Create Billing Lines and Billing Lines Archive, Create Usage Data from Billing Lines and Billing Lines Archive
        Initialize();
        MockBillingLine(BillingLines[1], "Service Partner"::Customer, "Rec. Billing Document Type"::Invoice);
        MockBillingLine(BillingLines[2], "Service Partner"::Customer, "Rec. Billing Document Type"::"Credit Memo");
        MockBillingLine(BillingLines[3], "Service Partner"::Vendor, "Rec. Billing Document Type"::Invoice);
        MockBillingLine(BillingLines[4], "Service Partner"::Vendor, "Rec. Billing Document Type"::"Credit Memo");
        MockBillingLineArchive(BillingLinesArchive[1], "Service Partner"::Customer, "Rec. Billing Document Type"::Invoice);
        MockBillingLineArchive(BillingLinesArchive[2], "Service Partner"::Customer, "Rec. Billing Document Type"::"Credit Memo");
        MockBillingLineArchive(BillingLinesArchive[3], "Service Partner"::Vendor, "Rec. Billing Document Type"::Invoice);
        MockBillingLineArchive(BillingLinesArchive[4], "Service Partner"::Vendor, "Rec. Billing Document Type"::"Credit Memo");

        for i := 1 to ArrayLen(BillingLines) do begin
            MockUsageData(UsageDataBillings[i, 1], BillingLines[i].Partner, ConvertDocumentType(BillingLines[i]."Document Type"), BillingLines[i]."Document No.");

            if i mod 2 = 1 then
                MockUsageData(UsageDataBillings[i, 2], BillingLinesArchive[i].Partner, "Usage Based Billing Doc. Type"::"Posted Invoice", BillingLinesArchive[i]."Document No.")
            else
                MockUsageData(UsageDataBillings[i, 2], BillingLinesArchive[i].Partner, "Usage Based Billing Doc. Type"::"Posted Credit Memo", BillingLinesArchive[i]."Document No.");
        end;

        // [WHEN] Validate Billing Line No. in Usage Data Billings
        for i := 1 to ArrayLen(BillingLines) do begin
            UsageDataBillings[i, 1].Validate("Billing Line Entry No.", BillingLines[i]."Entry No.");
            UsageDataBillings[i, 2].Validate("Billing Line Entry No.", BillingLinesArchive[i]."Entry No.");
        end;

        // [THEN] Billing Line No. has been validated
        for i := 1 to ArrayLen(BillingLines) do begin
            Assert.AreEqual(BillingLines[i]."Entry No.", UsageDataBillings[i, 1]."Billing Line Entry No.", 'Billig Line No. has not been validated');
            Assert.AreEqual(BillingLinesArchive[i]."Entry No.", UsageDataBillings[i, 2]."Billing Line Entry No.", 'Billig Line No. has not been validated');
        end;
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure VendorCurrencyMismatchErrorWhenNotAllowed()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
        ContractType: Record "Subscription Contract Type";
        VendorCurrencyMismatchErr: Label 'Vendor Subscription Contract %1 uses Currency Code %2, while the usage data contains amounts in %3. Please update the currency in the contract or move the Subscription line to a contract with this currency before reprocessing the usage data import.', Locked = true;
    begin
        // [SCENARIO] When vendor contract currency differs from usage data and "Allow Diff. Curr. in Usage Data" is false, error status is set

        // [GIVEN] Setup usage data and service objects
        Initialize();
        SetupUsageDataForProcessingToGenericImport(WorkDate(), CalcDate('<CM>', WorkDate()), WorkDate(), CalcDate('<CM>', WorkDate()), LibraryRandom.RandDec(10, 2), true);
        SetupDataExchangeDefinition();
        SetupServiceObjectAndContracts(WorkDate());

        // [GIVEN] Create contract type that does not allow different vendor currencies
        ContractTestLibrary.CreateContractType(ContractType);
        ContractType."Allow Diff. Curr. in Vend. UD" := false;
        ContractType.Modify(false);

        // [GIVEN] Set vendor contract to use a different currency than the import data
        VendorContract."Contract Type" := ContractType.Code;
        VendorContract.Modify(false);

        // [GIVEN] Connect and process imported lines
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, "Usage Based Pricing"::"Usage Quantity");
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);

        // [WHEN] Create Usage Data Billing (currency check happens here)
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");

        // [THEN] Vendor billing records should have error status due to currency mismatch
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Partner, "Service Partner"::Vendor);
        UsageDataBilling.FindFirst();
        UsageDataBilling.TestField("Processing Status", Enum::"Processing Status"::Error);
        Assert.AreEqual(
            StrSubstNo(VendorCurrencyMismatchErr, VendorContract."No.", VendorContract."Currency Code", ''),
            UsageDataBilling.GetReason(),
            'Error reason should match vendor currency mismatch message');
    end;

    [Test]
    procedure VendorPriceForUsageWithAndWithoutDeliveredCostAmountIsDerivedFromCostAmounts()
    var
        UsageDataBilling: Record "Usage Data Billing";
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] When only some usage data lines of a Subscription Line bring a Cost Amount, the supplier Unit Cost
        // cannot be taken over directly. The vendor Price is then derived from the Cost Amounts of all lines, per
        // Billing Base Period they cover.

        // [GIVEN] A yearly Subscription whose vendor Subscription Line costs 300 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine.Modify(false);

        // [GIVEN] Usage data for 10 seats for the whole year with a delivered Cost Amount of 3000, and for 5 seats from
        // July with a supplier Unit Cost of 365 per year only
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 5, "Usage Based Pricing"::"Usage Quantity");
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Quantity, 5);
        UsageDataBilling.ModifyAll("Charge Start Date", DMY2Date(1, 7, 2026), false);
        UsageDataBilling.SetRange(Quantity, 10);
        UsageDataBilling.SetRange(Partner, "Service Partner"::Vendor);
        UsageDataBilling.FindFirst();
        UsageDataBilling."Cost Amount" := 3000;
        UsageDataBilling."Cost Amount from Unit Cost" := false;
        UsageDataBilling.Modify(false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Subscription Line costs (3000 + 920) / (10 + 5 * 184 / 365) = 313.08534 per year.
        // The ratio of days has no exact decimal representation, so the Price is compared to five decimals.
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreNearlyEqual(313.08534, VendorSubscriptionLine.Price, 0.00001, 'The vendor Price must be derived from the Cost Amounts of all usage data lines.');
    end;

    [Test]
    procedure VendorPriceIsKeptWhenUsageDataCreditsBillingBasePeriodsOnBalance()
    var
        UsageDataBilling: Record "Usage Data Billing";
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A delivery for a part of the year and a larger credit for the whole year add up to a positive
        // quantity, but on balance they credit Billing Base Periods. Such usage data does not state a new price.

        // [GIVEN] A yearly Subscription whose vendor Subscription Line costs 300 per year. The Calculation Base Amount
        // matches, because the changed quantity of the Subscription recalculates the line from it.
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine."Calculation Base Amount" := 300;
        VendorSubscriptionLine.Modify(false);

        // [GIVEN] Usage data delivering 10 for October to December at a Cost Amount of 920, and crediting 8 for the whole
        // year at a Cost Amount of -2920
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, -8, "Usage Based Pricing"::"Usage Quantity", 365, 920, '');
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Quantity, 10);
        UsageDataBilling.ModifyAll("Charge Start Date", DMY2Date(1, 10, 2026), false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Subscription Line keeps its Price
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(300, VendorSubscriptionLine.Price, 'Usage data crediting Billing Base Periods on balance must not change the vendor Price.');
    end;

    [Test]
    procedure VendorPriceIsKeptWhenUsageDataCreditsQuantityOnBalance()
    var
        UsageDataBilling: Record "Usage Data Billing";
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A delivery for the whole year and a larger credit for a part of the year still cover Billing Base
        // Periods on balance, but they add up to a negative quantity. Such usage data is a credit and does not state a
        // new price.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose vendor Subscription Line costs 300 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine.Modify(false);

        // [GIVEN] Usage data delivering 10 for the whole year at a Cost Amount of 3650, and crediting 12 for October to
        // December at a Cost Amount of -1104, the same cost of 1 per day
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, -12, "Usage Based Pricing"::"Usage Quantity", 365, 3650, '');
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Quantity, -12);
        UsageDataBilling.ModifyAll("Charge Start Date", DMY2Date(1, 10, 2026), false);
        UsageDataBilling.ModifyAll("Cost Amount", -1104, false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Subscription Line keeps its Price
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(300, VendorSubscriptionLine.Price, 'Usage data crediting a quantity on balance must not change the vendor Price.');
    end;

    [Test]
    procedure VendorPriceIsKeptWhenUsageDataCreditsQuantityToZero()
    var
        UsageDataBilling: Record "Usage Data Billing";
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] A delivery for the whole year and a credit of the same quantity for a part of the year add up to a
        // quantity of zero, although they still cover Billing Base Periods on balance. Usage data without a quantity on
        // balance does not state a new price either.

        // [GIVEN] A yearly Subscription with a quantity of 10, whose vendor Subscription Line costs 300 per year. The Price
        // is set through the Calculation Base Amount, because the quantity of zero recalculates the Subscription Lines
        // from it.
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Validate("Calculation Base Amount", 300);
        VendorSubscriptionLine.Modify(false);

        // [GIVEN] Usage data delivering 10 for the whole year at a Cost Amount of 3650, and crediting 10 for October to
        // December at a Cost Amount of -920, the same cost of 1 per day
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, -10, "Usage Based Pricing"::"Usage Quantity", 365, 3650, '');
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Quantity, -10);
        UsageDataBilling.ModifyAll("Charge Start Date", DMY2Date(1, 10, 2026), false);
        UsageDataBilling.ModifyAll("Cost Amount", -920, false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Subscription Line keeps its Price
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(300, VendorSubscriptionLine.Price, 'Usage data crediting the whole quantity on balance must not change the vendor Price.');
    end;

    [Test]
    procedure VendorPriceIsSupplierUnitCostForMonthlyVendorBillingRhythm()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] The supplier states its Unit Cost per Billing Base Period, like the Price of a Subscription Line.
        // A vendor Subscription Line priced per year and billed monthly takes the supplier Unit Cost over as it is,
        // not multiplied by the twelve Billing Rhythms of the year.

        // [GIVEN] A Subscription with a quantity of 10, whose vendor Subscription Line costs 300 per year and is billed monthly
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Validate("Calculation Base Amount", 300);
        VendorSubscriptionLine.Modify(false);
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 0, "Usage Based Pricing"::"Usage Quantity", 1200, 0, '');
        SetBillingRhythmOnSubscriptionLine("Service Partner"::Vendor, '<1M>');

        // [WHEN] Usage data for the whole year with a supplier Unit Cost of 1200 per year is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Subscription Line costs the supplier Unit Cost of 1200 per year
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(1200, VendorSubscriptionLine.Price, 'The vendor Price must be the supplier Unit Cost per Billing Base Period.');
    end;

    [Test]
    procedure VendorPriceIsSupplierUnitCostForUsageWithDifferentChargeStartDates()
    var
        UsageDataBilling: Record "Usage Data Billing";
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        // [SCENARIO] Usage data lines that end on the same day but start on different days cover charge periods of
        // different length. The vendor Price per Billing Base Period must not depend on which of them is looked at.

        // [GIVEN] A yearly Subscription whose vendor Subscription Line costs 300 per year
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 300;
        VendorSubscriptionLine.Modify(false);

        // [GIVEN] Usage data for 10 seats for the whole year and 5 seats from July, at a supplier Unit Cost of 365 per year
        CreateYearlyUsageDataBilling(DMY2Date(1, 1, 2026), DMY2Date(31, 12, 2026), 10, 5, "Usage Based Pricing"::"Usage Quantity");
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.SetRange(Quantity, 5);
        UsageDataBilling.ModifyAll("Charge Start Date", DMY2Date(1, 7, 2026), false);

        // [WHEN] The usage data billing is processed
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Subscription Line costs the supplier Unit Cost of 365 per year
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(365, VendorSubscriptionLine.Price, 'The vendor Price must be the supplier Unit Cost per Billing Base Period.');
    end;

    [Test]
    procedure VendorSubscriptionLineIsNotChangedWhenSupplierUnitCostIsUnchanged()
    var
        VendorSubscriptionLine: Record "Subscription Line";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        CalculationBaseAmountBeforeProcessing: Decimal;
    begin
        // [SCENARIO] The vendor Price per Billing Base Period is compared with the Price of the Subscription Line, not
        // with the amount of the shorter charge period, so that an unchanged supplier Unit Cost leaves the line as it is.

        // [GIVEN] A yearly Subscription whose vendor Subscription Line already costs the supplier Unit Cost of 365 per year.
        // Its Calculation Base Amount does not match that Price, so that a recalculation of the line would show.
        Initialize();
        SetupYearlySubscriptionWithCustomerAndVendorLine(DMY2Date(1, 1, 2026), 10);
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        VendorSubscriptionLine.Price := 365;
        VendorSubscriptionLine."Calculation Base Amount" := 1000;
        VendorSubscriptionLine.Modify(false);
        CalculationBaseAmountBeforeProcessing := VendorSubscriptionLine."Calculation Base Amount";

        // [WHEN] Usage data for October to December with a supplier Unit Cost of 365 per year is processed
        CreateYearlyUsageDataBilling(DMY2Date(1, 10, 2026), DMY2Date(31, 12, 2026), 10);
        ProcessUsageDataBilling.Run(UsageDataImport);

        // [THEN] The vendor Subscription Line is not recalculated
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(365, VendorSubscriptionLine.Price, 'An unchanged supplier Unit Cost must keep the Price of the vendor Subscription Line.');
        Assert.AreEqual(CalculationBaseAmountBeforeProcessing, VendorSubscriptionLine."Calculation Base Amount", 'An unchanged supplier Unit Cost must not recalculate the vendor Subscription Line.');
    end;

    [Test]
    [HandlerFunctions('UsageDataBillingsModalPageHandler')]
    procedure VerifyFilteringOfUsageDataBilling()
    var
        BillingLines: array[2] of Record "Billing Line";
        UsageDataBillings: array[2] of Record "Usage Data Billing";
    begin
        // [SCENARIO] Verify filtering of Usage Data Billings when a Document No. is either assigned or not to the lines

        // [GIVEN] Create 2 Billing Lines and Usage Data Billings
        Initialize();
        UsageBasedBTestLibrary.MockBillingLineWithServObjectNo(BillingLines[1]);
        UsageBasedBTestLibrary.MockBillingLine(BillingLines[2]);
        BillingLines[2]."Subscription Header No." := BillingLines[1]."Subscription Header No.";
        BillingLines[2]."Subscription Line Entry No." := BillingLines[1]."Subscription Line Entry No.";
        UsageBasedBTestLibrary.CreateSalesInvoiceAndAssignToBillingLine(BillingLines[1]);
        UsageBasedBTestLibrary.MockUsageDataForBillingLine(UsageDataBillings[1], BillingLines[1]);
        UsageBasedBTestLibrary.MockUsageDataForBillingLine(UsageDataBillings[2], BillingLines[2]);

        // [WHEN] Billing line with assigned Document No. is selected
        UsageDataBillings[1].ShowForRecurringBilling(BillingLines[1]."Subscription Header No.", BillingLines[1]."Subscription Line Entry No.", BillingLines[1]."Document Type", BillingLines[1]."Document No."); // UsageDataBillingsModalPageHandler

        // [THEN] Usage Data Billing is filtered and only one record is visible
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Usage Data Billing is not found, but should be.');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Usage Data Billing is found, but should not be');

        // [WHEN] Billing line without Document No. is selected
        UsageDataBillings[2].ShowForRecurringBilling(BillingLines[2]."Subscription Header No.", BillingLines[2]."Subscription Line Entry No.", BillingLines[2]."Document Type", BillingLines[2]."Document No."); // UsageDataBillingsModalPageHandler

        // [THEN] Usage Data Billing is filtered and only one record is visible
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Usage Data Billing is not found, but should be.');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Usage Data Billing is found, but should not be');
    end;

    #endregion Tests

    #region Procedures

    local procedure AssertUsageDataBillingMatchesImport(UsageDataGenericImport: Record "Usage Data Generic Import"; var UsageDataBilling: Record "Usage Data Billing"; ExpectedSubscriptionLine: Record "Subscription Line")
    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        BillingCurrency: Record Currency;
        ExpectedUnitCost: Decimal;
        ExpectedCostAmount: Decimal;
        ExpectedUnitPrice: Decimal;
        ExpectedAmount: Decimal;
    begin
        // Verify structural/date fields are copied from the generic import
        UsageDataBilling.TestField("Usage Data Import Entry No.", UsageDataGenericImport."Usage Data Import Entry No.");
        UsageDataBilling.TestField("Subscription Header No.", UsageDataGenericImport."Subscription Header No.");
        UsageDataBilling.TestField("Charge Start Date", UsageDataGenericImport."Billing Period Start Date");
        UsageDataBilling.TestField("Charge End Date", UsageDataGenericImport."Billing Period End Date");
        UsageDataBilling.TestField(Quantity, UsageDataGenericImport.Quantity);

        // Verify amount fields, accounting for currency conversion and rounding
        ExpectedUnitCost := UsageDataGenericImport.Cost;
        ExpectedCostAmount := UsageDataGenericImport."Cost Amount";
        ExpectedUnitPrice := UsageDataGenericImport.Price;
        ExpectedAmount := UsageDataGenericImport.Amount;

        if UsageDataBilling."Currency Code" <> '' then
            BillingCurrency.Get(UsageDataBilling."Currency Code")
        else
            BillingCurrency.InitRoundingPrecision();

        if UsageDataBilling."Currency Code" <> UsageDataGenericImport.Currency then begin
            ExpectedUnitCost := CurrencyExchRate.ExchangeAmtFCYToFCY(UsageDataBilling."Charge End Date", UsageDataGenericImport.Currency, UsageDataBilling."Currency Code", ExpectedUnitCost);
            ExpectedCostAmount := CurrencyExchRate.ExchangeAmtFCYToFCY(UsageDataBilling."Charge End Date", UsageDataGenericImport.Currency, UsageDataBilling."Currency Code", ExpectedCostAmount);
            ExpectedUnitPrice := CurrencyExchRate.ExchangeAmtFCYToFCY(UsageDataBilling."Charge End Date", UsageDataGenericImport.Currency, UsageDataBilling."Currency Code", ExpectedUnitPrice);
            ExpectedAmount := CurrencyExchRate.ExchangeAmtFCYToFCY(UsageDataBilling."Charge End Date", UsageDataGenericImport.Currency, UsageDataBilling."Currency Code", ExpectedAmount);
        end;
        UsageDataBilling.TestField("Unit Cost", Round(ExpectedUnitCost, BillingCurrency."Unit-Amount Rounding Precision"));
        UsageDataBilling.TestField("Cost Amount", Round(ExpectedCostAmount, BillingCurrency."Amount Rounding Precision"));
        UsageDataBilling.TestField("Unit Price", Round(ExpectedUnitPrice, BillingCurrency."Unit-Amount Rounding Precision"));
        UsageDataBilling.TestField(Amount, Round(ExpectedAmount, BillingCurrency."Amount Rounding Precision"));

        // Verify the billing record is linked to the correct subscription line and contract
        UsageDataBilling.TestField("Subscription Header No.", ExpectedSubscriptionLine."Subscription Header No.");
        UsageDataBilling.TestField(Partner, ExpectedSubscriptionLine.Partner);
        UsageDataBilling.TestField("Subscription Contract No.", ExpectedSubscriptionLine."Subscription Contract No.");
        UsageDataBilling.TestField("Subscription Contract Line No.", ExpectedSubscriptionLine."Subscription Contract Line No.");
        UsageDataBilling.TestField("Subscription Line Entry No.", ExpectedSubscriptionLine."Entry No.");
        UsageDataBilling.TestField("Usage Base Pricing", ExpectedSubscriptionLine."Usage Based Pricing");
        UsageDataBilling.TestField("Pricing Unit Cost Surcharge %", ExpectedSubscriptionLine."Pricing Unit Cost Surcharge %");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure UsageEntryCrossingBillingRhythmIsBilledInOneBillingLine()
    var
        CustomerBillingLine: Record "Billing Line";
        CrossingChargeEndDate: Date;
        PeriodStartDate: Date;
    begin
        // [AI Test]
        // [SCENARIO 648576] A usage entry that starts inside the billing rhythm but ends after it is billed within a single billing line

        // [GIVEN] Three usage entries where the last one crosses the monthly rhythm boundary
        Initialize();

        // [WHEN] The usage data is processed and the customer invoice is created
        SetupUsageDataWithEntryCrossingBillingRhythm(PeriodStartDate, CrossingChargeEndDate);

        // [THEN] One billing line covers the whole usage period, stretched to the charge end date of the crossing entry
        FilterCustomerBillingLinesOnSubscription(CustomerBillingLine);
        Assert.RecordCount(CustomerBillingLine, 1);
        CustomerBillingLine.FindFirst();
        Assert.AreEqual(PeriodStartDate, CustomerBillingLine."Billing from", BillingLineStartDateLbl);
        Assert.AreEqual(CrossingChargeEndDate, CustomerBillingLine."Billing to", BillingLineStretchedEndDateLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure BillingLineAmountMatchesUsageDataWhenEntryCrossesPeriod()
    var
        CustomerBillingLine: Record "Billing Line";
        UsageDataBilling: Record "Usage Data Billing";
        CrossingChargeEndDate: Date;
        PeriodStartDate: Date;
    begin
        // [AI Test]
        // [SCENARIO 648576] No usage amount is lost when a usage entry crosses the billing rhythm boundary

        // [GIVEN] Three usage entries where the last one crosses the monthly rhythm boundary
        Initialize();

        // [WHEN] The usage data is processed and the customer invoice is created
        SetupUsageDataWithEntryCrossingBillingRhythm(PeriodStartDate, CrossingChargeEndDate);

        // [THEN] The billing lines add up to the total of the usage data billing
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        UsageDataBilling.CalcSums(Amount);
        FilterCustomerBillingLinesOnSubscription(CustomerBillingLine);
        CustomerBillingLine.CalcSums(Amount);
        Assert.AreEqual(
            Round(UsageDataBilling.Amount, Currency."Amount Rounding Precision"),
            Round(CustomerBillingLine.Amount, Currency."Amount Rounding Precision"),
            BillingLineAmountMismatchLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure AllUsageDataEntriesLinkToSameBillingLineWhenEntryCrossesPeriod()
    var
        CustomerBillingLine: Record "Billing Line";
        UsageDataBilling: Record "Usage Data Billing";
        CrossingChargeEndDate: Date;
        PeriodStartDate: Date;
        BillingLineEntryNo: Integer;
    begin
        // [AI Test]
        // [SCENARIO 648576] Every usage entry is linked to the billing line it was billed in, also when it crosses the rhythm boundary

        // [GIVEN] Three usage entries where the last one crosses the monthly rhythm boundary
        Initialize();

        // [WHEN] The usage data is processed and the customer invoice is created
        SetupUsageDataWithEntryCrossingBillingRhythm(PeriodStartDate, CrossingChargeEndDate);

        // [THEN] All usage data billing entries point to the single billing line
        FilterCustomerBillingLinesOnSubscription(CustomerBillingLine);
        CustomerBillingLine.FindFirst();
        BillingLineEntryNo := CustomerBillingLine."Entry No.";

        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        UsageDataBilling.FindSet();
        repeat
            Assert.AreEqual(BillingLineEntryNo, UsageDataBilling."Billing Line Entry No.", BillingLineNotLinkedToUsageDataLbl);
        until UsageDataBilling.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure UsageEntryInsideBillingRhythmKeepsRhythmBillingToDate()
    var
        CustomerBillingLine: Record "Billing Line";
        PeriodStartDate: Date;
        SupplierSubscriptionID: Text;
    begin
        // [AI Test]
        // [SCENARIO 648576] The billing period is not stretched when all usage entries end inside the billing rhythm

        // [GIVEN] Three usage entries that all end within the first monthly rhythm period
        Initialize();
        SetupUsageBasedCustomerContractForMonthlyRhythm(PeriodStartDate, SupplierSubscriptionID);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate, PeriodStartDate + 17);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate + 11, PeriodStartDate + 17);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate + 18, CalcDate('<CM>', PeriodStartDate));

        // [WHEN] The usage data is processed and the customer invoice is created
        ProcessUsageDataAndCreateCustomerInvoice();

        // [THEN] One billing line ends at the rhythm period end
        FilterCustomerBillingLinesOnSubscription(CustomerBillingLine);
        Assert.RecordCount(CustomerBillingLine, 1);
        CustomerBillingLine.FindFirst();
        Assert.AreEqual(PeriodStartDate, CustomerBillingLine."Billing from", BillingLineStartDateLbl);
        Assert.AreEqual(CalcDate('<CM>', PeriodStartDate), CustomerBillingLine."Billing to", BillingLineRhythmEndDateLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure RhythmAlignedUsageEntriesCreateOneBillingLinePerPeriod()
    var
        CustomerBillingLine: Record "Billing Line";
        PeriodStartDate: Date;
        SecondPeriodStartDate: Date;
        SupplierSubscriptionID: Text;
    begin
        // [AI Test]
        // [SCENARIO 648576] Usage entries aligned to the billing rhythm are still billed in one billing line per period

        // [GIVEN] Two usage entries, each covering exactly one monthly rhythm period
        Initialize();
        SetupUsageBasedCustomerContractForMonthlyRhythm(PeriodStartDate, SupplierSubscriptionID);
        SecondPeriodStartDate := CalcDate('<1M>', PeriodStartDate);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate, CalcDate('<CM>', PeriodStartDate));
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, SecondPeriodStartDate, CalcDate('<CM>', SecondPeriodStartDate));

        // [WHEN] The usage data is processed and the customer invoice is created
        ProcessUsageDataAndCreateCustomerInvoice();

        // [THEN] Two billing lines are created with unchanged rhythm periods
        FilterCustomerBillingLinesOnSubscription(CustomerBillingLine);
        Assert.RecordCount(CustomerBillingLine, 2);
        CustomerBillingLine.FindFirst();
        Assert.AreEqual(PeriodStartDate, CustomerBillingLine."Billing from", FirstBillingLineStartDateLbl);
        Assert.AreEqual(CalcDate('<CM>', PeriodStartDate), CustomerBillingLine."Billing to", FirstBillingLineEndDateLbl);
        CustomerBillingLine.FindLast();
        Assert.AreEqual(SecondPeriodStartDate, CustomerBillingLine."Billing from", SecondBillingLineStartDateLbl);
        Assert.AreEqual(CalcDate('<CM>', SecondPeriodStartDate), CustomerBillingLine."Billing to", SecondBillingLineEndDateLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure UsageBasedBillingPeriodCanBeLimitedBySubscriber()
    var
        CustomerBillingLine: Record "Billing Line";
        PeriodStartDate: Date;
        SecondPeriodStartDate: Date;
        SupplierSubscriptionID: Text;
    begin
        // [SCENARIO] A subscriber can change the billing period derived from the open usage data of a usage-based Subscription Line

        // [GIVEN] Two usage entries, each covering one monthly rhythm period
        Initialize();
        SetupUsageBasedCustomerContractForMonthlyRhythm(PeriodStartDate, SupplierSubscriptionID);
        SecondPeriodStartDate := CalcDate('<1M>', PeriodStartDate);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate, CalcDate('<CM>', PeriodStartDate));
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, SecondPeriodStartDate, CalcDate('<CM>', SecondPeriodStartDate));

        // [GIVEN] A subscriber that limits the billing period to the month of its start
        LimitUsageBasedBillingPeriodToFirstMonth := true;

        // [WHEN] The usage data is processed and the customer invoice is created
        BindSubscription(this);
        ProcessUsageDataAndCreateCustomerInvoice();
        UnbindSubscription(this);

        // [THEN] Only one billing line is created, covering the first month
        FilterCustomerBillingLinesOnSubscription(CustomerBillingLine);
        Assert.RecordCount(CustomerBillingLine, 1);
        CustomerBillingLine.FindFirst();
        Assert.AreEqual(PeriodStartDate, CustomerBillingLine."Billing from", FirstBillingLineStartDateLbl);
        Assert.AreEqual(CalcDate('<CM>', PeriodStartDate), CustomerBillingLine."Billing to", FirstBillingLineEndDateLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure NoOverlappingBillingLineCreatedAfterStretchedBillingPeriod()
    var
        CustomerBillingLine: Record "Billing Line";
        CustomerSubscriptionLine: Record "Subscription Line";
        CrossingChargeEndDate: Date;
        PeriodStartDate: Date;
    begin
        // [AI Test]
        // [SCENARIO 648576] The period following a stretched billing period starts after it instead of at the rhythm boundary

        // [GIVEN] Three usage entries where the last one crosses the monthly rhythm boundary
        Initialize();

        // [WHEN] The usage data is processed and the customer invoice is created
        SetupUsageDataWithEntryCrossingBillingRhythm(PeriodStartDate, CrossingChargeEndDate);

        // [THEN] No billing line starts at the rhythm boundary that the stretched billing line covers
        FilterCustomerBillingLinesOnSubscription(CustomerBillingLine);
        CustomerBillingLine.SetRange("Billing from", CalcDate('<CM>', PeriodStartDate) + 1);
        Assert.RecordIsEmpty(CustomerBillingLine);

        // [THEN] The Subscription Line continues after the stretched billing period
        FindCustomerSubscriptionLine(CustomerSubscriptionLine, SubscriptionHeader."No.");
        Assert.AreEqual(CrossingChargeEndDate + 1, CustomerSubscriptionLine."Next Billing Date", NextBillingDateLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerBillingDocumentPageHandler')]
    procedure ChainedCrossingUsageEntriesAreBilledInOneBillingLine()
    var
        CustomerBillingLine: Record "Billing Line";
        UsageDataBilling: Record "Usage Data Billing";
        PeriodStartDate: Date;
        FirstCrossingChargeEndDate: Date;
        SecondCrossingChargeEndDate: Date;
        SupplierSubscriptionID: Text;
    begin
        // [AI Test]
        // [SCENARIO 648576] Multiple chained crossing usage entries extend the billing line to cover all chained entries in a single billing line

        // [GIVEN] Three usage entries where each subsequent entry starts before the previous one ends but extends past its end date
        Initialize();
        SetupUsageBasedCustomerContractForMonthlyRhythm(PeriodStartDate, SupplierSubscriptionID);
        FirstCrossingChargeEndDate := CalcDate('<1M>', PeriodStartDate) + 10;
        SecondCrossingChargeEndDate := CalcDate('<2M>', PeriodStartDate) + 10;
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate, PeriodStartDate + 17);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate + 18, FirstCrossingChargeEndDate);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, FirstCrossingChargeEndDate - 5, SecondCrossingChargeEndDate);

        // [WHEN] The usage data is processed and the customer invoice is created
        ProcessUsageDataAndCreateCustomerInvoice();

        // [THEN] One billing line covers the whole chained usage period, stretched to the second crossing entry's charge end date
        FilterCustomerBillingLinesOnSubscription(CustomerBillingLine);
        Assert.RecordCount(CustomerBillingLine, 1);
        CustomerBillingLine.FindFirst();
        Assert.AreEqual(PeriodStartDate, CustomerBillingLine."Billing from", BillingLineStartDateLbl);
        Assert.AreEqual(SecondCrossingChargeEndDate, CustomerBillingLine."Billing to", BillingLineStretchedEndDateLbl);

        // [THEN] Total amount matches
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        UsageDataBilling.CalcSums(Amount);
        CustomerBillingLine.CalcSums(Amount);
        Assert.AreEqual(
            Round(UsageDataBilling.Amount, Currency."Amount Rounding Precision"),
            Round(CustomerBillingLine.Amount, Currency."Amount Rounding Precision"),
            BillingLineAmountMismatchLbl);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Usage Based Billing Test");
        ResetAll();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Usage Based Billing Test");
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        ContractTestLibrary.InitSourceCodeSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Usage Based Billing Test");
    end;

    local procedure ResetAll()
    begin
        ClearAll();
        Currency.InitRoundingPrecision();
        UsageBasedBTestLibrary.DeleteAllUsageBasedRecords();
        BillingLine.Reset();
        BillingLine.DeleteAll(false);
    end;

    local procedure AssertCreditExceedingSubscribedQuantityIsReported(CreditedQuantity: Decimal; SubscribedQuantity: Decimal; VendorPriceBeforeCredit: Decimal)
    var
        VendorSubscriptionLine: Record "Subscription Line";
        UsageDataBilling: Record "Usage Data Billing";
        ExpectedReason: Text;
    begin
        ExpectedReason := StrSubstNo(CreditedQtyExceedsSubscribedQtyErr, SubscriptionHeader."No.", CreditedQuantity, SubscribedQuantity);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        Assert.RecordCount(UsageDataBilling, 2);
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField("Processing Status", "Processing Status"::Error);
            Assert.AreEqual(ExpectedReason, UsageDataBilling.GetReason(), 'The usage data billing must state that the credit exceeds the subscribed quantity.');
        until UsageDataBilling.Next() = 0;

        UsageDataImport.Get(UsageDataImport."Entry No.");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Error);
        SubscriptionHeader.Get(SubscriptionHeader."No.");
        Assert.AreEqual(SubscribedQuantity, SubscriptionHeader.Quantity, 'A credit exceeding the subscribed quantity must not change the quantity of the Subscription.');
        GetSubscriptionLineForPartner(VendorSubscriptionLine, "Service Partner"::Vendor);
        Assert.AreEqual(VendorPriceBeforeCredit, VendorSubscriptionLine.Price, 'A credit exceeding the subscribed quantity must not change the Price of the Subscription Line.');
    end;

    local procedure AssertUsageDataBillingIsRebilling()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        Assert.RecordCount(UsageDataBilling, 2);
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField(Rebilling, true);
        until UsageDataBilling.Next() = 0;
    end;

    local procedure CheckIfCustomerSupplierReferencesAreIsCreated(CustomerID: Text[80])
    begin
        UsageDataSupplierReference.FilterUsageDataSupplierReference(UsageDataImport."Supplier No.", CustomerID, Enum::"Usage Data Reference Type"::Customer);
        UsageDataSupplierReference.FindFirst();
    end;

    local procedure CheckIfProductSupplierReferencesAreIsCreated(ProductID: Text[80])
    begin
        UsageDataSupplierReference.FilterUsageDataSupplierReference(UsageDataImport."Supplier No.", ProductID, Enum::"Usage Data Reference Type"::Product);
        UsageDataSupplierReference.FindFirst();
    end;

    local procedure CheckIfPurchaseDocumentsHaveBeenCreated()
    begin
        if BillingLine.FindSet() then
            repeat
                BillingLine.TestField("Document Type", Enum::"Rec. Billing Document Type"::Invoice);
                BillingLine.TestField("Document No.");
                SubscriptionLine.Get(BillingLine."Subscription Line Entry No.");
                SubscriptionLine.TestField("Usage Based Billing");
                SubscriptionLine.TestField("Supplier Reference Entry No.");

                PurchaseHeader.Get(Enum::"Purchase Document Type"::Invoice, BillingLine."Document No.");
                PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                PurchaseLine.SetFilter("Recurring Billing from", '>=%1', BillingLine."Billing from");
                PurchaseLine.SetFilter("Recurring Billing to", '<=%1', BillingLine."Billing to");
                Assert.RecordCount(PurchaseLine, 1);
                TestIfRelatedUsageDataBillingIsUpdated("Service Partner"::Vendor, UsageBasedDocTypeConverter.ConvertPurchaseDocTypeToUsageBasedBillingDocType(PurchaseHeader."Document Type"), PurchaseHeader."No.", true, BillingLine."Entry No.");
                PurchaseLine.FindFirst();
                TestIfInvoicesMatchesUsageData("Service Partner"::Vendor, PurchaseLine."Line Amount", PurchaseLine."Document No.");
            until BillingLine.Next() = 0;
    end;

    local procedure CheckIfSalesDocumentsHaveBeenCreated()
    begin
        BillingLine.FindSet();
        repeat
            BillingLine.TestField("Document Type", Enum::"Rec. Billing Document Type"::Invoice);
            BillingLine.TestField("Document No.");
            SubscriptionLine.Get(BillingLine."Subscription Line Entry No.");
            SubscriptionLine.TestField("Usage Based Billing");
            SubscriptionLine.TestField("Supplier Reference Entry No.");

            SalesHeader.Get(Enum::"Sales Document Type"::Invoice, BillingLine."Document No.");
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetFilter("Recurring Billing from", '>=%1', BillingLine."Billing from");
            SalesLine.SetFilter("Recurring Billing to", '<=%1', BillingLine."Billing to");
            Assert.RecordCount(SalesLine, 1);
            TestIfRelatedUsageDataBillingIsUpdated("Service Partner"::Customer, UsageBasedDocTypeConverter.ConvertSalesDocTypeToUsageBasedBillingDocType(SalesHeader."Document Type"), SalesHeader."No.", true, BillingLine."Entry No.");
            SalesLine.FindFirst();
            TestIfInvoicesMatchesUsageData("Service Partner"::Customer, SalesLine."Line Amount", SalesLine."Document No.");
        until BillingLine.Next() = 0;
    end;

    local procedure CheckIfServiceCommitmentRemains(UsageDataBilling: Record "Usage Data Billing")
    begin
        SubscriptionLine.Reset();
        SubscriptionLine.SetRange("Subscription Header No.", UsageDataBilling."Subscription Header No.");
        SubscriptionLine.SetRange("Entry No.", UsageDataBilling."Subscription Line Entry No.");
        SubscriptionLine.FindSet();
        repeat
            if SubscriptionLine.Partner = "Service Partner"::Customer then
                SubscriptionLine.TestField(Price, Item."Unit Price")
            else
                SubscriptionLine.TestField(Price, Item."Unit Cost");
        until SubscriptionLine.Next() = 0;
    end;

    local procedure CheckIfSubscriptionSupplierReferencesAreIsCreated(SuppSubscriptionID: Text[80])
    begin
        UsageDataSupplierReference.FilterUsageDataSupplierReference(UsageDataImport."Supplier No.", SuppSubscriptionID, Enum::"Usage Data Reference Type"::Subscription);
        UsageDataSupplierReference.FindFirst();
    end;

    local procedure CheckIfUsageDataCustomerIsCreated(CustomerID: Text[80])
    begin
        UsageDataCustomer.SetRange("Supplier No.", UsageDataImport."Supplier No.");
        UsageDataCustomer.SetRange("Supplier Reference", CustomerID);
        UsageDataCustomer.FindFirst();
    end;

    local procedure CheckIfUsageDataSubscriptionIsCreated(UsageDataGenericImport: Record "Usage Data Generic Import")
    begin
        UsageDataSubscription.FindForSupplierReference(UsageDataImport."Supplier No.", UsageDataGenericImport."Supp. Subscription ID");
        UsageDataSubscription.TestField("Customer ID", UsageDataGenericImport."Customer ID");
        UsageDataSubscription.TestField("Product ID", UsageDataGenericImport."Product ID");
        UsageDataSubscription.TestField("Product Name", UsageDataGenericImport."Product Name");
        UsageDataSubscription.TestField("Unit Type", UsageDataGenericImport.Unit);
        UsageDataSubscription.TestField(Quantity, UsageDataGenericImport.Quantity);
        UsageDataSubscription.TestField("Start Date", UsageDataGenericImport."Supp. Subscription Start Date");
        UsageDataSubscription.TestField("End Date", UsageDataGenericImport."Supp. Subscription End Date");
    end;

    local procedure ConvertDocumentType(DocumentType: Enum "Rec. Billing Document Type"): Enum "Usage Based Billing Doc. Type"
    begin
        UsageBasedDocTypeConverter.ConvertRecurringBillingDocTypeToUsageBasedBillingDocType(DocumentType);
    end;

    local procedure CreateBillingProposalForSimpleCustomerContract()
    begin
        ContractTestLibrary.InitContractsApp();
        CustomerContract.SetRange("No.", CustomerContract."No.");
        ContractTestLibrary.CreateRecurringBillingTemplate(BillingTemplate, '<2M-CM>', '<8M+CM>', CustomerContract.GetView(), Enum::"Service Partner"::Customer);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);
        BillingLine.Reset();
        BillingLine.SetRange("Billing Template Code", BillingTemplate.Code);
        BillingLine.FindLast();
    end;

    local procedure CreateBillingProposalForVendorContract(BillingDate: Date; BillingToDate: Date)
    var
        BillingProposal: Codeunit "Billing Proposal";
    begin
        ContractTestLibrary.InitContractsApp();
        VendorContract.SetRange("No.", VendorContract."No.");
        ContractTestLibrary.CreateRecurringBillingTemplate(BillingTemplate, '', '', VendorContract.GetView(), Enum::"Service Partner"::Vendor);
        BillingProposal.CreateBillingProposal(BillingTemplate.Code, BillingDate, BillingToDate);
    end;

    local procedure CreateContractInvoicesAndTestProcessedUsageData()
    var
        UsageDataBilling: Record "Usage Data Billing";
        ExpectedInvoiceAmount: Decimal;
    begin
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        UsageDataBilling.CalcSums(Amount);
        ExpectedInvoiceAmount := UsageDataBilling.Amount;
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        UsageDataBilling.FindFirst();

        CheckIfServiceCommitmentRemains(UsageDataBilling);

        BillingLine.FilterBillingLineOnContractLine(UsageDataBilling.Partner, UsageDataBilling."Subscription Contract No.", UsageDataBilling."Subscription Contract Line No.");
        BillingLine.CalcSums(Amount);
        Assert.AreEqual(Round(BillingLine.Amount, Currency."Unit-Amount Rounding Precision"), ExpectedInvoiceAmount, 'Billing lines where not created properly');
    end;

    local procedure CreateContractInvoiceFromUsageDataImportForPricingType(UsageBasedPricing: Enum "Usage Based Pricing")
    begin
        Initialize();
        CreateUsageDataBilling(UsageBasedPricing, LibraryRandom.RandDec(10, 2));
        PostDocument := false;
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
        CheckIfSalesDocumentsHaveBeenCreated();
    end;

    local procedure CreateCustomerContractAndAssignServiceCommitments()
    var
        ContractType: Record "Subscription Contract Type";
        TempSubscriptionLine: Record "Subscription Line" temporary;
    begin
        ContractTestLibrary.CreateCustomerContract(CustomerContract, Customer."No.");
        ContractTestLibrary.CreateContractTypeAllowingDiffCurrency(ContractType);
        CustomerContract."Contract Type" := ContractType.Code;
        CustomerContract.Modify(false);
        ContractTestLibrary.FillTempServiceCommitment(TempSubscriptionLine, SubscriptionHeader, CustomerContract);
        CustomerContract.CreateCustomerContractLinesFromServiceCommitments(TempSubscriptionLine);
        CustomerContractLine.SetRange("Subscription Contract No.", CustomerContract."No.");
        CustomerContractLine.FindLast();
        ContractTestLibrary.SetGeneralPostingSetup(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", false, Enum::"Service Partner"::Customer);
    end;

    local procedure CreateRecurringBillingTemplateSetupForCustomerContract(DateFormula1Txt: Text; DateFormula2Txt: Text; FilterText: Text)
    begin
        ContractTestLibrary.CreateRecurringBillingTemplate(BillingTemplate, DateFormula1Txt, DateFormula2Txt, FilterText, Enum::"Service Partner"::Customer);
    end;

    local procedure CreateSubscriptionItemWithPrices(UnitPrice: Decimal; UnitCost: Decimal)
    begin
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        Item."Unit Price" := UnitPrice;
        Item."Unit Cost" := UnitCost;
        Item.Modify(false);
    end;

    local procedure CreateServiceObjectWithServiceCommitments(CustomerNo: Code[20]; ServiceAndCalculationStartDate: Date)
    begin
        CreateSubscriptionItemWithPrices(LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        SetupItemWithMultipleServiceCommitmentPackages();
        ContractTestLibrary.CreateServiceObjectForItem(SubscriptionHeader, Item."No.");
        SubscriptionHeader.InsertServiceCommitmentsFromStandardServCommPackages(ServiceAndCalculationStartDate);
        SubscriptionHeader."End-User Customer No." := CustomerNo;
        SubscriptionHeader.Modify(false);
    end;

    local procedure CreateUsageDataBilling(UsageBasedPricing: Enum "Usage Based Pricing"; Quantity: Decimal)
    begin
        CreateUsageDataBilling(UsageBasedPricing, WorkDate(), CalcDate('<CM>', WorkDate()), WorkDate(), CalcDate('<CM>', WorkDate()), Quantity);
    end;

    local procedure CreateUsageDataBilling(UsageBasedPricing: Enum "Usage Based Pricing"; BillingPeriodStartingDate: Date; BillingPeriodEndingDate: Date; SubscriptionStartingDate: Date; SubscriptionEndingDate: Date; Quantity: Decimal)
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        SetupUsageDataForProcessingToGenericImport(BillingPeriodStartingDate, BillingPeriodEndingDate, SubscriptionStartingDate, SubscriptionEndingDate, Quantity);
        SetupDataExchangeDefinition();
        SetupServiceObjectAndContracts(SubscriptionStartingDate);
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        // Error is expected because Usage data subscription is created in this step - linking with Subscription Line is second step
        // Therefore Processing needs to be performed twice - refer to AB2070
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, UsageBasedPricing);
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
    end;

    local procedure CreateUsageDataBillingWithCurrencyMismatch(UsageBasedPricing: Enum "Usage Based Pricing"; Quantity: Decimal)
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // Usage data is imported without a currency code, while the contracts use the currency of the Customer/Vendor
        SetupUsageDataForProcessingToGenericImport(WorkDate(), CalcDate('<CM>', WorkDate()), WorkDate(), CalcDate('<CM>', WorkDate()), Quantity, false);
        SetupDataExchangeDefinition();
        SetupServiceObjectAndContracts(WorkDate());
        DisallowDifferentCurrencyInUsageDataForContracts();
        UsageBasedBTestLibrary.ConnectDataExchDefinitionToUsageDataGenericSettings(DataExchDef.Code, GenericImportSettings);
        ProcessUsageDataImport(Enum::"Processing Step"::"Create Imported Lines");
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, UsageBasedPricing);
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);
        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
    end;

    local procedure DisallowDifferentCurrencyInUsageDataForContracts()
    var
        ContractType: Record "Subscription Contract Type";
    begin
        ContractType.Get(CustomerContract."Contract Type");
        ContractType."Allow Diff. Curr. in Cust. UD" := false;
        ContractType.Modify(false);

        ContractType.Get(VendorContract."Contract Type");
        ContractType."Allow Diff. Curr. in Vend. UD" := false;
        ContractType.Modify(false);
    end;

    local procedure CreateUsageDataBillingDummyDataFromSubscriptionLine(var NewUsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; SourceSubscriptionLine: Record "Subscription Line")
    begin
        SourceSubscriptionLine.SetAutoCalcFields(Quantity);
        NewUsageDataBilling."Entry No." := 0;
        NewUsageDataBilling."Usage Data Import Entry No." := UsageDataImportEntryNo;
        NewUsageDataBilling.Partner := SourceSubscriptionLine.Partner;
        NewUsageDataBilling."Subscription Header No." := SourceSubscriptionLine."Subscription Header No.";
        NewUsageDataBilling."Subscription Line Entry No." := SourceSubscriptionLine."Entry No.";
        NewUsageDataBilling."Subscription Contract No." := SourceSubscriptionLine."Subscription Contract No.";
        NewUsageDataBilling."Subscription Contract Line No." := SourceSubscriptionLine."Subscription Contract Line No.";
        NewUsageDataBilling.Quantity := SourceSubscriptionLine.Quantity;
        NewUsageDataBilling."Charge Start Date" := WorkDate();
        NewUsageDataBilling."Charge End Date" := CalcDate('<CM>', WorkDate());
        NewUsageDataBilling.Insert(true);
    end;

    local procedure CreateVendorContractAndAssignServiceCommitments()
    begin
        ContractTestLibrary.CreateVendor(Vendor);
        CreateVendorContractForVendorAndAssignServiceCommitments();
    end;

    local procedure CreateVendorContractForVendorAndAssignServiceCommitments()
    var
        ContractType: Record "Subscription Contract Type";
        TempSubscriptionLine: Record "Subscription Line" temporary;
    begin
        ContractTestLibrary.CreateVendorContract(VendorContract, Vendor."No.");
        ContractTestLibrary.CreateContractTypeAllowingDiffCurrency(ContractType);
        VendorContract."Contract Type" := ContractType.Code;
        VendorContract.Modify(false);
        ContractTestLibrary.FillTempServiceCommitmentForVendor(TempSubscriptionLine, SubscriptionHeader, VendorContract);
        VendorContract.CreateVendorContractLinesFromServiceCommitments(TempSubscriptionLine);
        VendorContractLine.SetRange("Subscription Contract No.", VendorContract."No.");
        VendorContractLine.FindLast();
        ContractTestLibrary.SetGeneralPostingSetup(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", false, Enum::"Service Partner"::Vendor);
    end;

    local procedure CreateYearlyUsageDataBilling(ChargeStartDate: Date; ChargeEndDate: Date; Quantity: Decimal)
    begin
        CreateYearlyUsageDataBilling(ChargeStartDate, ChargeEndDate, Quantity, 0, "Usage Based Pricing"::"Usage Quantity");
    end;

    local procedure CreateYearlyUsageDataBilling(ChargeStartDate: Date; ChargeEndDate: Date; Quantity: Decimal; SecondQuantity: Decimal; UsageBasedPricing: Enum "Usage Based Pricing")
    begin
        CreateYearlyUsageDataBilling(ChargeStartDate, ChargeEndDate, Quantity, SecondQuantity, UsageBasedPricing, Item."Unit Cost", 0, '');
    end;

    local procedure CreateYearlyUsageDataBilling(ChargeStartDate: Date; ChargeEndDate: Date; Quantity: Decimal; SecondQuantity: Decimal; UsageBasedPricing: Enum "Usage Based Pricing"; DeliveredUnitCost: Decimal; DeliveredCostAmount: Decimal; ImportCurrencyCode: Code[10])
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
        SecondUsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // Unless a test delivers a Cost Amount, the supplier delivers its Unit Cost only, so that the Cost Amount is derived from it.
        UsageDataImport.Reset();
        UsageBasedBTestLibrary.CreateUsageDataSupplier(UsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, false, Enum::"Vendor Invoice Per"::Import);
        UsageBasedBTestLibrary.CreateGenericImportSettings(GenericImportSettings, UsageDataSupplier."No.", true, true);
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, UsageDataSupplier."No.");
        UsageBasedBTestLibrary.CreateSimpleUsageDataGenericImport(UsageDataGenericImport, UsageDataImport."Entry No.", SubscriptionHeader."No.", Customer."No.", DeliveredUnitCost, ChargeStartDate, ChargeEndDate, ChargeStartDate, ChargeEndDate, Quantity);
        UsageDataGenericImport."Cost Amount" := DeliveredCostAmount;
        UsageDataGenericImport.Currency := ImportCurrencyCode;
        UsageDataGenericImport.Modify(false);
        if SecondQuantity <> 0 then begin
            // A second line in the same file for the same subscription and the same charge period - the supplier
            // reference has to stay identical, so the first line is copied instead of created from scratch.
            SecondUsageDataGenericImport := UsageDataGenericImport;
            SecondUsageDataGenericImport."Entry No." := 0;
            SecondUsageDataGenericImport.Quantity := SecondQuantity;
            if DeliveredCostAmount <> 0 then
                SecondUsageDataGenericImport."Cost Amount" := SecondUsageDataGenericImport.Cost * SecondQuantity;
            SecondUsageDataGenericImport.Insert(false);
        end;
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, UsageBasedPricing, '1Y', '1Y');
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);

        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
        if GetUsageDataBillingCount(UsageDataImport."Entry No.") = 0 then begin
            // The first pass only links the Subscription to the supplier reference and leaves the imported line in
            // status Error, which makes "Create Usage Data Billing" skip it. Processing the imported lines once more
            // brings the line to status Ok.
            UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Imported Lines");
            UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
        end;
        UsageDataImport."Processing Step" := Enum::"Processing Step"::"Process Usage Data Billing";
        UsageDataImport.Modify(false);
    end;

    local procedure FilterUsageDataBillingOnUsageDataImport(var UsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer)
    begin
        UsageDataBilling.Reset();
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImportEntryNo);
    end;

    local procedure FilterUsageDataBillingOnUsageDataImport(var UsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; ServicePartner: Enum "Service Partner")
    begin
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImportEntryNo);
        UsageDataBilling.SetRange(Partner, ServicePartner);
    end;

    local procedure FilterUsageDataBillingOnUsageDataImport(var UsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; ServicePartner: Enum "Service Partner"; UsageBasedBillingDocType: Enum "Usage Based Billing Doc. Type")
    begin
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImportEntryNo, ServicePartner);
        UsageDataBilling.SetRange("Document Type", UsageBasedBillingDocType);
    end;

    local procedure FindCustomerSubscriptionLine(var FoundSubscriptionLine: Record "Subscription Line"; SubscriptionHeaderNo: Code[20])
    begin
        FoundSubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeaderNo);
        FoundSubscriptionLine.SetRange(Partner, "Service Partner"::Customer);
        FoundSubscriptionLine.FindFirst();
    end;

    local procedure FindCustomerUsageDataBilling(var UsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer)
    begin
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImportEntryNo);
        UsageDataBilling.SetRange(Partner, "Service Partner"::Customer);
        UsageDataBilling.FindFirst();
    end;

    local procedure FindUsageDataGenericImport(var UsageDataGenericImport: Record "Usage Data Generic Import"; UsageDataImportEntryNo: Integer)
    begin
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImportEntryNo);
        UsageDataGenericImport.FindFirst();
    end;

    local procedure GetBillingEntryNo(BillingDocumentType: Enum "Rec. Billing Document Type"; ServicePartner: Enum "Service Partner"; DocumentNo: Code[20]; ContractNo: Code[20]; ContractLineNo: Integer): Integer
    begin
        BillingLine.FilterBillingLineOnContractLine(ServicePartner, ContractNo, ContractLineNo);
        BillingLine.SetRange("Document Type", BillingDocumentType);
        BillingLine.SetRange("Document No.", DocumentNo);
        if BillingLine.FindLast() then
            exit(BillingLine."Entry No.")
        else
            exit(0);
    end;

    local procedure GetSubscriptionLineForPartner(var PartnerSubscriptionLine: Record "Subscription Line"; ServicePartner: Enum "Service Partner")
    begin
        PartnerSubscriptionLine.Reset();
        PartnerSubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        PartnerSubscriptionLine.SetRange(Partner, ServicePartner);
        PartnerSubscriptionLine.FindFirst();
    end;

    local procedure GetUsageDataBillingCount(UsageDataImportEntryNo: Integer): Integer
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataBilling.Reset();
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImportEntryNo);
        exit(UsageDataBilling.Count());
    end;

    local procedure MarkUsageDataBillingMetadataAsInvoiced()
    var
        UsageDataBillingMetadata: Record "Usage Data Billing Metadata";
    begin
        UsageDataBillingMetadata.SetRange("Subscription No.", SubscriptionHeader."No.");
        UsageDataBillingMetadata.FindSet();
        repeat
            UsageDataBillingMetadata.Invoiced := true;
            UsageDataBillingMetadata.Modify(false);
        until UsageDataBillingMetadata.Next() = 0;
    end;

    local procedure MockBillingLine(var NewBillingLine: Record "Billing Line"; Partner: Enum "Service Partner"; DocumentType: Enum "Rec. Billing Document Type")
    begin
        NewBillingLine.Init();
        NewBillingLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewBillingLine."User ID"));
        NewBillingLine."Entry No." := 0;
        NewBillingLine.Partner := Partner;
        NewBillingLine."Document Type" := DocumentType;
        NewBillingLine."Document No." := CopyStr(LibraryRandom.RandText(MaxStrLen(Item.Description)), 1, 20);
        NewBillingLine.Insert(false);
    end;

    local procedure MockBillingLineArchive(var NewBillingLineArchive: Record "Billing Line Archive"; Partner: Enum "Service Partner"; DocumentType: Enum "Rec. Billing Document Type")
    begin
        NewBillingLineArchive.Init();
        NewBillingLineArchive.Partner := Partner;
        NewBillingLineArchive."Document Type" := DocumentType;
        NewBillingLineArchive."Document No." := CopyStr(LibraryRandom.RandText(MaxStrLen(Item.Description)), 1, 20);
        NewBillingLineArchive.Insert(false);
    end;

    local procedure MockServiceCommitment(var ServiceCommitment2: Record "Subscription Line"; BillingBasePeriod: DateFormula; BillingRhythm: DateFormula; Price: Decimal)
    begin
        ServiceCommitment2.Init();
        ServiceCommitment2."Billing Base Period" := BillingBasePeriod;
        ServiceCommitment2."Billing Rhythm" := BillingRhythm;
        ServiceCommitment2.Price := Price;
    end;

    local procedure MockServiceCommitment(var ServiceCommitment2: Record "Subscription Line"; BillingBasePeriod: Text; BillingRhythm: Text)
    var
        BillingBasePeriodFormula: DateFormula;
        BillingRhythmFormula: DateFormula;
    begin
        Evaluate(BillingBasePeriodFormula, BillingBasePeriod);
        Evaluate(BillingRhythmFormula, BillingRhythm);
        MockServiceCommitment(ServiceCommitment2, BillingBasePeriodFormula, BillingRhythmFormula, 0);
    end;

    local procedure MockUsageData(var NewUsageDataBilling: Record "Usage Data Billing"; Partner: Enum "Service Partner"; DocumentType: Enum "Usage Based Billing Doc. Type"; DocumentNo: Code[20])
    begin
        NewUsageDataBilling.Init();
        NewUsageDataBilling.Partner := Partner;
        NewUsageDataBilling."Document Type" := DocumentType;
        NewUsageDataBilling."Document No." := DocumentNo;
        NewUsageDataBilling.Insert(false);
    end;

    local procedure MockUsageDataBillingWithCost(var NewUsageDataBilling: Record "Usage Data Billing"; UsageDataImportEntryNo: Integer; DocumentNo: Code[20]; Quantity: Decimal; UnitCost: Decimal; CostAmount: Decimal)
    var
        DocumentType: Enum "Usage Based Billing Doc. Type";
    begin
        // The usage data billing is inserted as it was stored before "Cost Amount from Unit Cost" existed.
        DocumentType := DocumentType::None;
        if DocumentNo <> '' then
            DocumentType := DocumentType::Invoice;
        MockUsageData(NewUsageDataBilling, "Service Partner"::Vendor, DocumentType, DocumentNo);
        NewUsageDataBilling."Usage Data Import Entry No." := UsageDataImportEntryNo;
        // Each usage data billing has its own Subscription, so that it matches its own imported line only.
        NewUsageDataBilling."Subscription Header No." := LibraryUtility.GenerateGUID();
        NewUsageDataBilling.Quantity := Quantity;
        NewUsageDataBilling."Unit Cost" := UnitCost;
        NewUsageDataBilling."Cost Amount" := CostAmount;
        NewUsageDataBilling.Modify(false);
    end;

    local procedure MockUsageDataGenericImport(UsageDataBilling: Record "Usage Data Billing"; Cost: Decimal; CostAmount: Decimal)
    var
        NewUsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // The imported line holds the values the usage data billing was created from.
        NewUsageDataGenericImport.Init();
        NewUsageDataGenericImport."Entry No." := 0;
        NewUsageDataGenericImport."Usage Data Import Entry No." := UsageDataBilling."Usage Data Import Entry No.";
        NewUsageDataGenericImport."Subscription Header No." := UsageDataBilling."Subscription Header No.";
        NewUsageDataGenericImport."Product ID" := UsageDataBilling."Product ID";
        NewUsageDataGenericImport."Product Name" := UsageDataBilling."Product Name";
        NewUsageDataGenericImport."Billing Period Start Date" := UsageDataBilling."Charge Start Date";
        NewUsageDataGenericImport."Billing Period End Date" := UsageDataBilling."Charge End Date";
        NewUsageDataGenericImport.Quantity := UsageDataBilling.Quantity;
        NewUsageDataGenericImport.Cost := Cost;
        NewUsageDataGenericImport."Cost Amount" := CostAmount;
        NewUsageDataGenericImport.Insert(false);
    end;

    local procedure MockUsageDataImport(ProcessingStatus: Enum "Processing Status"): Integer
    var
        NewUsageDataImport: Record "Usage Data Import";
    begin
        NewUsageDataImport.Init();
        NewUsageDataImport."Entry No." := 0;
        NewUsageDataImport."Processing Status" := ProcessingStatus;
        NewUsageDataImport.Insert(false);
        exit(NewUsageDataImport."Entry No.");
    end;

    local procedure PostPurchaseDocuments()
    var

        UsageDataBilling: Record "Usage Data Billing";
    begin
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.MarkPurchaseHeaderFromUsageDataBilling(UsageDataBilling, PurchaseHeader);
        PurchaseHeader.FindSet();
        repeat
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
            PurchaseHeader.Modify(false);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        until PurchaseHeader.Next() = 0;
    end;

    local procedure PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport: Record "Usage Data Generic Import"; UsageBasedPricing: Enum "Usage Based Pricing")
    begin
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, UsageBasedPricing, '', '');
    end;

    local procedure PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport: Record "Usage Data Generic Import"; UsageBasedPricing: Enum "Usage Based Pricing"; BillingBasePeriod: Text; BillingRhythm: Text)
    begin
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, UsageBasedPricing, BillingBasePeriod, BillingRhythm, 0D);
    end;

    local procedure PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport: Record "Usage Data Generic Import"; UsageBasedPricing: Enum "Usage Based Pricing"; BillingBasePeriod: Text; BillingRhythm: Text; ServiceStartDate: Date)
    begin
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.FindSet();
        repeat
            SubscriptionLine."Usage Based Pricing" := UsageBasedPricing;
            if ServiceStartDate <> 0D then
                SubscriptionLine."Subscription Line Start Date" := CalcDate('<-CM>', WorkDate());
            if BillingBasePeriod <> '' then
                Evaluate(SubscriptionLine."Billing Base Period", BillingBasePeriod);
            if BillingRhythm <> '' then
                Evaluate(SubscriptionLine."Billing Rhythm", BillingRhythm);
            UsageDataSupplierReference.FilterUsageDataSupplierReference(UsageDataImport."Supplier No.", UsageDataGenericImport."Supp. Subscription ID", Enum::"Usage Data Reference Type"::Subscription);
            if UsageDataSupplierReference.FindFirst() then
                SubscriptionLine."Supplier Reference Entry No." := UsageDataSupplierReference."Entry No.";
            SubscriptionLine.Modify(false);
            UsageDataGenericImport."Subscription Header No." := SubscriptionHeader."No.";
            UsageDataGenericImport.Modify(false);
        until SubscriptionLine.Next() = 0;
    end;

    local procedure ProcessRejectedCredit(ChargeStartDate: Date; ChargeEndDate: Date; CreditedQuantity: Decimal)
    var
        UsageDataBilling: Record "Usage Data Billing";
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
    begin
        CreateYearlyUsageDataBilling(ChargeStartDate, ChargeEndDate, CreditedQuantity);
        ProcessUsageDataBilling.Run(UsageDataImport);
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        Assert.RecordIsNotEmpty(UsageDataBilling);
        UsageDataBilling.SetFilter("Processing Status", '<>%1', "Processing Status"::Error);
        Assert.RecordIsEmpty(UsageDataBilling);
    end;

    local procedure ProcessUsageDataImport(ProcessingStep: Enum "Processing Step")
    begin
        UsageDataImport."Processing Step" := ProcessingStep;
        UsageDataImport.Modify(false);
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);
    end;

    local procedure ProcessUsageDataWithSimpleGenericImport(BillingPeriodStartDate: Date; BillingPeriodEndDate: Date; SubscriptionStartDate: Date; SubscriptionEndDate: Date; Quantity: Decimal)
    begin
        ProcessUsageDataWithSimpleGenericImport(BillingPeriodStartDate, BillingPeriodEndDate, SubscriptionStartDate, SubscriptionEndDate, Quantity, "Usage Based Pricing"::"Usage Quantity");
    end;

    local procedure ProcessUsageDataWithSimpleGenericImport(BillingPeriodStartDate: Date; BillingPeriodEndDate: Date; SubscriptionStartDate: Date; SubscriptionEndDate: Date; Quantity: Decimal; UsageBasedPricing: Enum "Usage Based Pricing")
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        UsageBasedBTestLibrary.CreateUsageDataSupplier(UsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, false, Enum::"Vendor Invoice Per"::Import);
        UsageBasedBTestLibrary.CreateGenericImportSettings(GenericImportSettings, UsageDataSupplier."No.", true, true);
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, UsageDataSupplier."No.");
        UsageBasedBTestLibrary.CreateSimpleUsageDataGenericImport(UsageDataGenericImport, UsageDataImport."Entry No.", SubscriptionHeader."No.", Customer."No.", Item."Unit Cost", BillingPeriodStartDate, BillingPeriodEndDate, SubscriptionStartDate, SubscriptionEndDate, Quantity);
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, UsageBasedPricing);
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);

        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
    end;

    local procedure ProcessYearlyUsageDataImport(ChargeStartDate: Date; ChargeEndDate: Date; Quantity: Decimal)
    begin
        ProcessYearlyUsageDataImport(ChargeStartDate, ChargeEndDate, Quantity, "Usage Based Pricing"::"Usage Quantity");
    end;

    local procedure ProcessYearlyUsageDataImport(ChargeStartDate: Date; ChargeEndDate: Date; Quantity: Decimal; UsageBasedPricing: Enum "Usage Based Pricing")
    var
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        UsageDataImportEntryNo: Integer;
    begin
        CreateYearlyUsageDataBilling(ChargeStartDate, ChargeEndDate, Quantity, 0, UsageBasedPricing);
        UsageDataImportEntryNo := UsageDataImport."Entry No.";
        ProcessUsageDataBilling.Run(UsageDataImport);
        UsageDataImport.Reset();
        UsageDataImport.Get(UsageDataImportEntryNo);
    end;

    local procedure ProcessYearlyUsageDataImportWithTwoLines(ChargeStartDate: Date; ChargeEndDate: Date; Quantity: Decimal; SecondQuantity: Decimal)
    var
        ProcessUsageDataBilling: Codeunit "Process Usage Data Billing";
        UsageDataImportEntryNo: Integer;
    begin
        CreateYearlyUsageDataBilling(ChargeStartDate, ChargeEndDate, Quantity, SecondQuantity, "Usage Based Pricing"::"Usage Quantity");
        UsageDataImportEntryNo := UsageDataImport."Entry No.";
        ProcessUsageDataBilling.Run(UsageDataImport);
        UsageDataImport.Reset();
        UsageDataImport.Get(UsageDataImportEntryNo);
    end;

    local procedure ResetCostAmountFromUnitCost(UsageDataImportEntryNo: Integer)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // The usage data billing is stored as it was before "Cost Amount from Unit Cost" existed.
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImportEntryNo);
        UsageDataBilling.ModifyAll("Cost Amount from Unit Cost", false, false);
    end;

    local procedure ResetPurchasePostingNoSeriesDateUsage()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        // Some localizations require the posting number series to be used in date order.
        PurchSetup.Get();
        NoSeriesLine.SetFilter("Series Code", '%1|%2', PurchSetup."Posted Receipt Nos.", PurchSetup."Posted Invoice Nos.");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    local procedure ResetSalesPostingNoSeriesDateUsage()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        // Some localizations require the posting number series to be used in date order.
        SalesSetup.Get();
        NoSeriesLine.SetFilter("Series Code", '%1|%2', SalesSetup."Posted Shipment Nos.", SalesSetup."Posted Invoice Nos.");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    local procedure SetupUsageBasedCustomerContractForMonthlyRhythm(var PeriodStartDate: Date; var SupplierSubscriptionID: Text)
    begin
        ContractTestLibrary.InitContractsApp();
        CreateSubscriptionItemWithPrices(LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        SetupServiceDataForProcessing(Enum::"Usage Based Pricing"::"Usage Quantity", Enum::"Calculation Base Type"::"Item Price", Enum::"Invoicing Via"::Contract,
                                       '1M', '1M', '1M', "Service Partner"::Customer, 100, Item."No.");
        UsageBasedBTestLibrary.CreateUsageDataSupplier(UsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, false, Enum::"Vendor Invoice Per"::Import);
        UsageBasedBTestLibrary.CreateGenericImportSettings(GenericImportSettings, UsageDataSupplier."No.", true, true);
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, UsageDataSupplier."No.");
        PeriodStartDate := CalcDate('<-CM>', WorkDate());
        SupplierSubscriptionID := LibraryRandom.RandText(80);
    end;

    local procedure SetupUsageDataWithEntryCrossingBillingRhythm(var PeriodStartDate: Date; var CrossingChargeEndDate: Date)
    var
        SupplierSubscriptionID: Text;
    begin
        SetupUsageBasedCustomerContractForMonthlyRhythm(PeriodStartDate, SupplierSubscriptionID);
        // The third entry starts in the first rhythm period and ends in the second one
        CrossingChargeEndDate := CalcDate('<1M>', PeriodStartDate) + 17;
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate, PeriodStartDate + 17);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate + 11, PeriodStartDate + 17);
        AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID, PeriodStartDate + 18, CrossingChargeEndDate);
        ProcessUsageDataAndCreateCustomerInvoice();
    end;

    local procedure AddUsageDataBillingForChargePeriod(ChargeStartDate: Date; ChargeEndDate: Date; NewQuantity: Decimal)
    var
        TempUsageDataBilling: Record "Usage Data Billing" temporary;
        NewUsageDataBilling: Record "Usage Data Billing";
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // The usage data billing of the import is copied, as if the supplier had delivered another charge period in the same file.
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.");
        UsageDataBilling.FindSet();
        repeat
            TempUsageDataBilling := UsageDataBilling;
            TempUsageDataBilling.Insert(false);
        until UsageDataBilling.Next() = 0;
        TempUsageDataBilling.FindSet();
        repeat
            NewUsageDataBilling := TempUsageDataBilling;
            NewUsageDataBilling."Entry No." := 0;
            NewUsageDataBilling."Charge Start Date" := ChargeStartDate;
            NewUsageDataBilling."Charge End Date" := ChargeEndDate;
            NewUsageDataBilling.UpdateChargedPeriod();
            NewUsageDataBilling.Quantity := NewQuantity;
            NewUsageDataBilling."Cost Amount" := NewUsageDataBilling."Unit Cost" * NewQuantity;
            NewUsageDataBilling.Insert(false);
        until TempUsageDataBilling.Next() = 0;
    end;

    local procedure AddUsageDataGenericImportForChargePeriod(SupplierSubscriptionID: Text; ChargeStartDate: Date; ChargeEndDate: Date)
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        UsageBasedBTestLibrary.CreateSimpleUsageDataGenericImport(
            UsageDataGenericImport, UsageDataImport."Entry No.", SubscriptionHeader."No.", Customer."No.", Item."Unit Cost",
            ChargeStartDate, ChargeEndDate, ChargeStartDate, ChargeEndDate, LibraryRandom.RandInt(10));
        UsageDataGenericImport."Supp. Subscription ID" := CopyStr(SupplierSubscriptionID, 1, MaxStrLen(UsageDataGenericImport."Supp. Subscription ID"));
        UsageDataGenericImport.Modify(false);
    end;

    local procedure ProcessUsageDataAndCreateCustomerInvoice()
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        ProcessUsageDataImport(Enum::"Processing Step"::"Process Imported Lines");

        UsageDataGenericImport.Reset();
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindSet();
        repeat
            PrepareServiceCommitmentAndUsageDataGenericImportForUsageBilling(UsageDataGenericImport, Enum::"Usage Based Pricing"::"Usage Quantity", '1M', '1M', CalcDate('<-CM>', WorkDate()));
        until UsageDataGenericImport.Next() = 0;
        Codeunit.Run(Codeunit::"Import And Process Usage Data", UsageDataImport);

        UsageDataImport.SetRecFilter();
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Create Usage Data Billing");
        UsageDataImport.ProcessUsageDataImport(UsageDataImport, Enum::"Processing Step"::"Process Usage Data Billing");
        PostDocument := false;
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);
    end;

    local procedure FilterCustomerBillingLinesOnSubscription(var CustomerBillingLine: Record "Billing Line")
    begin
        CustomerBillingLine.Reset();
        CustomerBillingLine.SetCurrentKey("Subscription Header No.", "Subscription Line Entry No.", "Billing to");
        CustomerBillingLine.SetRange(Partner, "Service Partner"::Customer);
        CustomerBillingLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
    end;

    local procedure SetBillingRhythmOnSubscriptionLine(ServicePartner: Enum "Service Partner"; BillingRhythm: Text)
    var
        PartnerSubscriptionLine: Record "Subscription Line";
    begin
        // Creating usage data billing sets Billing Base Period and Billing Rhythm of all Subscription Lines to one year,
        // so a different Billing Rhythm has to be set again after each import.
        GetSubscriptionLineForPartner(PartnerSubscriptionLine, ServicePartner);
        Evaluate(PartnerSubscriptionLine."Billing Rhythm", BillingRhythm);
        PartnerSubscriptionLine.Modify(false);
    end;

    local procedure SetPricingUnitCostSurchargeOnSubscriptionLines(SurchargePct: Decimal)
    begin
        SubscriptionLine.Reset();
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.FindSet();
        repeat
            SubscriptionLine."Pricing Unit Cost Surcharge %" := SurchargePct;
            SubscriptionLine.Modify(false);
        until SubscriptionLine.Next() = 0;
    end;

    local procedure SetupDataExchangeDefinition()
    begin
        UsageBasedBTestLibrary.CreateDataExchDefinition(DataExchDef, FileType::"Variable Text", Enum::"Data Exchange Definition Type"::"Generic Import", FileEncoding::"UTF-8", ColumnSeparator::Semicolon, '', 1);
        UsageBasedBTestLibrary.CreateDataExchDefinitionLine(DataExchLineDef, DataExchDef.Code, RRef);
        UsageBasedBTestLibrary.CreateDataExchColumnDefinition(DataExchColumnDef, DataExchDef.Code, DataExchLineDef.Code, RRef);
        UsageBasedBTestLibrary.CreateDataExchangeMapping(DataExchMapping, DataExchDef.Code, DataExchLineDef.Code, RRef);
        UsageBasedBTestLibrary.CreateDataExchangeFieldMapping(DataExchFieldMapping, DataExchDef.Code, DataExchLineDef.Code, RRef);
    end;

    local procedure SetupItemWithMultipleServiceCommitmentPackages()
    begin
        // Billing rhythm should be the same as in Usage data billing which is in the "Usage Based B. Test Library" set to 1D always (WorkDate()) Ref: CreateOutStreamData
        ContractTestLibrary.CreateServiceCommitmentTemplate(SubPackageLineTemplate);
        Evaluate(SubPackageLineTemplate."Billing Base Period", '1M');
        SubPackageLineTemplate."Calculation Base %" := LibraryRandom.RandDec(100, 2);
        SubPackageLineTemplate."Invoicing via" := Enum::"Invoicing Via"::Contract;
        SubPackageLineTemplate."Calculation Base Type" := "Calculation Base Type"::"Item Price";
        SubPackageLineTemplate."Usage Based Billing" := true;
        SubPackageLineTemplate.Modify(false);
        // Standard Subscription Package with two Subscription Package Lines
        // 1. for Customer
        // 2. for Vendor
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(SubPackageLineTemplate.Code, SubscriptionPackage, SubscriptionPackageLine);
        SubscriptionPackageLine.Partner := Enum::"Service Partner"::Customer;
        Evaluate(SubscriptionPackageLine."Extension Term", '<1Y>');
        Evaluate(SubscriptionPackageLine."Notice Period", '<1M>');
        Evaluate(SubscriptionPackageLine."Initial Term", '<1Y>');
        Evaluate(SubscriptionPackageLine."Billing Rhythm", '<1M>');
        SubscriptionPackageLine.Modify(false);

        ContractTestLibrary.CreateServiceCommitmentPackageLine(SubscriptionPackage.Code, SubPackageLineTemplate.Code, SubscriptionPackageLine);
        SubscriptionPackageLine.Partner := Enum::"Service Partner"::Vendor;
        Evaluate(SubscriptionPackageLine."Extension Term", '<1Y>');
        Evaluate(SubscriptionPackageLine."Notice Period", '<1M>');
        Evaluate(SubscriptionPackageLine."Initial Term", '<1Y>');
        Evaluate(SubscriptionPackageLine."Billing Rhythm", '<1M>');
        SubscriptionPackageLine.Modify(false);
        ContractTestLibrary.AssignItemToServiceCommitmentPackage(Item, SubscriptionPackage.Code);
        ItemServCommitmentPackage.Get(Item."No.", SubscriptionPackage.Code);
        ItemServCommitmentPackage.Standard := true;
        ItemServCommitmentPackage.Modify(false);

        // Additional Subscription Package
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(SubPackageLineTemplate.Code, SubscriptionPackage, SubscriptionPackageLine);
        SubscriptionPackageLine.Partner := Enum::"Service Partner"::Customer;
        Evaluate(SubscriptionPackageLine."Extension Term", '<1Y>');
        Evaluate(SubscriptionPackageLine."Notice Period", '<1M>');
        Evaluate(SubscriptionPackageLine."Initial Term", '<1Y>');
        Evaluate(SubscriptionPackageLine."Billing Rhythm", '<1M>');
        SubscriptionPackageLine.Modify(false);
        ContractTestLibrary.AssignItemToServiceCommitmentPackage(Item, SubscriptionPackage.Code);
    end;

    local procedure SetupServiceDataForProcessing(UsageBasedPricing: Enum "Usage Based Pricing"; CalculationBaseType: Enum "Calculation Base Type";
                                                                         InvoicingVia: Enum "Invoicing Via";
                                                                         BillingBasePeriod: Text;
                                                                         BillingRhythm: Text;
                                                                         ExtensionTerm: Text;
                                                                         ServicePartner: Enum "Service Partner";
                                                                         CalculationBase: Decimal;
                                                                         ItemNo: Code[20])
    begin
        ContractTestLibrary.CreateServiceCommitmentTemplate(SubPackageLineTemplate);
        SubPackageLineTemplate."Usage Based Billing" := true;
        SubPackageLineTemplate."Usage Based Pricing" := UsageBasedPricing;
        Evaluate(SubPackageLineTemplate."Billing Base Period", '1M');
        SubPackageLineTemplate."Calculation Base %" := LibraryRandom.RandDec(100, 2);
        SubPackageLineTemplate."Invoicing via" := InvoicingVia;
        SubPackageLineTemplate."Calculation Base Type" := CalculationBaseType;
        SubPackageLineTemplate.Modify(false);
        ContractTestLibrary.CreateServiceCommitmentPackageWithLine(SubPackageLineTemplate.Code, SubscriptionPackage, SubscriptionPackageLine);
        ContractTestLibrary.UpdateServiceCommitmentPackageLine(SubscriptionPackageLine, BillingBasePeriod, CalculationBase, BillingRhythm, ExtensionTerm, ServicePartner, '');
        ContractTestLibrary.AssignItemToServiceCommitmentPackage(Item, SubscriptionPackage.Code);
        ItemServCommitmentPackage.Get(ItemNo, SubscriptionPackage.Code);
        ItemServCommitmentPackage.Standard := true;
        ItemServCommitmentPackage.Modify(false);

        LibrarySales.CreateCustomer(Customer);
        ContractTestLibrary.CreateServiceObjectForItem(SubscriptionHeader, ItemNo);
        SubscriptionHeader.InsertServiceCommitmentsFromStandardServCommPackages(WorkDate());
        SubscriptionHeader."End-User Customer No." := Customer."No.";
        SubscriptionHeader.Modify(false);
        CreateCustomerContractAndAssignServiceCommitments();
    end;

    local procedure SetupServiceObjectAndContracts(ServiceAndCalculationStartDate: Date)
    begin
        ContractTestLibrary.CreateCustomer(Customer);
        CreateServiceObjectWithServiceCommitments(Customer."No.", ServiceAndCalculationStartDate);
        CreateCustomerContractAndAssignServiceCommitments();
        CreateVendorContractAndAssignServiceCommitments();
    end;

    local procedure SetupUsageDataForProcessingToGenericImport()
    begin
        SetupUsageDataForProcessingToGenericImport(WorkDate(), WorkDate(), WorkDate(), WorkDate(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure SetupUsageDataForProcessingToGenericImport(BillingPeriodStartingDate: Date; BillingPeriodEndingDate: Date; SubscriptionStartingDate: Date; SubscriptionEndingDate: Date; Quantity: Decimal)
    begin
        SetupUsageDataForProcessingToGenericImport(BillingPeriodStartingDate, BillingPeriodEndingDate, SubscriptionStartingDate, SubscriptionEndingDate, Quantity, true);
    end;

    local procedure SetupUsageDataForProcessingToGenericImport(BillingPeriodStartingDate: Date; BillingPeriodEndingDate: Date; SubscriptionStartingDate: Date; SubscriptionEndingDate: Date; Quantity: Decimal; UnitPriceFromImport: Boolean)
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        UsageBasedBTestLibrary.CreateUsageDataSupplier(UsageDataSupplier, Enum::"Usage Data Supplier Type"::Generic, UnitPriceFromImport, Enum::"Vendor Invoice Per"::Import);
        UsageBasedBTestLibrary.CreateGenericImportSettings(GenericImportSettings, UsageDataSupplier."No.", true, true);
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, UsageDataSupplier."No.");
        RRef.GetTable(UsageDataGenericImport);
        UsageDataBlob.InsertFromUsageDataImport(UsageDataImport);
        UsageBasedBTestLibrary.CreateUsageDataCSVFileBasedOnRecordAndImportToUsageDataBlob(
                    UsageDataBlob,
                    RRef,
                    CopyStr(LibraryRandom.RandText(80), 1, 80),
                    CopyStr(LibraryRandom.RandText(80), 1, 80),
                    SubscriptionHeader."No.",
                    SubscriptionLine."Entry No.",
                    BillingPeriodStartingDate,
                    BillingPeriodEndingDate,
                    SubscriptionStartingDate,
                    SubscriptionEndingDate,
                    Quantity);
    end;

    local procedure SetupYearlySubscriptionWithCustomerAndVendorLine(SubscriptionStartDate: Date; SubscriptionQuantity: Decimal)
    begin
        // Both partners are in local currency, so that the imported cost reaches the usage data billing unconverted.
        // The supplier Unit Cost of 365 per year is 1 per day, which keeps the expected amounts of a charge period exact.
        ContractTestLibrary.CreateCustomerInLCY(Customer);
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        Item."Unit Price" := LibraryRandom.RandDec(1000, 2);
        Item."Unit Cost" := 365;
        Item.Modify(false);
        SetupItemWithMultipleServiceCommitmentPackages();
        ContractTestLibrary.CreateServiceObjectForItem(SubscriptionHeader, Item."No.");
        // Both fields are assigned rather than validated: no Subscription Line exists yet, and validating either of
        // them runs RecalculateServiceCommitments - "End-User Customer No." reaches it through "Bill-to Customer No."
        // - which asks for confirmation and cannot be answered from a fixture.
        SubscriptionHeader.Quantity := SubscriptionQuantity;
        SubscriptionHeader."End-User Customer No." := Customer."No.";
        SubscriptionHeader.Modify(false);
        SubscriptionHeader.InsertServiceCommitmentsFromStandardServCommPackages(SubscriptionStartDate);

        // The usage data is only accepted for a Subscription Line that already runs when the charge period starts.
        // A Calculation Base % of 100 keeps a Price that is passed through the Calculation Base Amount exact.
        SubscriptionLine.Reset();
        SubscriptionLine.SetRange("Subscription Header No.", SubscriptionHeader."No.");
        SubscriptionLine.FindSet();
        repeat
            SubscriptionLine.Validate("Subscription Line Start Date", SubscriptionStartDate);
            SubscriptionLine.Validate("Calculation Base %", 100);
            SubscriptionLine.Modify(false);
        until SubscriptionLine.Next() = 0;

        CreateCustomerContractAndAssignServiceCommitments();
        ContractTestLibrary.CreateVendorInLCY(Vendor);
        CreateVendorContractForVendorAndAssignServiceCommitments();
    end;

    local procedure TestIfInvoicesMatchesUsageData(ServicePartner: Enum "Service Partner"; InvoiceAmount: Decimal; DocumentNo: Code[20])
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataBilling.Reset();
        UsageDataBilling.FilterOnDocumentTypeAndDocumentNo(ServicePartner, Enum::"Usage Based Billing Doc. Type"::"Invoice", DocumentNo);
        UsageDataBilling.CalcSums(Amount, "Cost Amount");
        case ServicePartner of
            ServicePartner::Customer:
                Assert.AreEqual(UsageDataBilling.Amount, InvoiceAmount, 'The Sales Invoice lines were not created properly.');
            ServicePartner::Vendor:
                Assert.AreEqual(UsageDataBilling."Cost Amount", InvoiceAmount, 'The Purchase Invoice lines were not created properly.');
        end;
    end;

    local procedure TestIfRelatedUsageDataBillingIsUpdated(ServicePartner: Enum "Service Partner"; UsageBasedBillingDocType: Enum "Usage Based Billing Doc. Type"; DocumentNo: Code[20]; TestNotEmptyDocLineNo: Boolean; BillingLineNo: Integer)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", ServicePartner);
        UsageDataBilling.FindSet();
        repeat
            UsageDataBilling.TestField("Document Type", UsageBasedBillingDocType);
            UsageDataBilling.TestField("Document No.", DocumentNo);
            if BillingLineNo <> 0 then
                UsageDataBilling.TestField("Billing Line Entry No.", GetBillingEntryNo(BillingLine."Document Type", BillingLine.Partner, DocumentNo, UsageDataBilling."Subscription Contract No.",
                                                              UsageDataBilling."Subscription Contract Line No."));
            // Billing Line No. is always last line no. for Contract No. and Contract Line No.
            if TestNotEmptyDocLineNo then
                UsageDataBilling.TestField("Document Line No.")
            else
                UsageDataBilling.TestField("Document Line No.", 0);
        until UsageDataBilling.Next() = 0
    end;

    local procedure TestSubscriptionWithUsageData(BillingPeriod: Text; BillingEndDate: Date; SubscriptionEndDate: Date; UnitPrice: Decimal; ValidateUnitPrice: Boolean)
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        Initialize();
        CreateSubscriptionItemWithPrices(UnitPrice, 1);

        SetupServiceDataForProcessing(Enum::"Usage Based Pricing"::"Usage Quantity", "Calculation Base Type"::"Item Price", Enum::"Invoicing Via"::Contract,
                                       BillingPeriod, BillingPeriod, '1Y', "Service Partner"::Customer, 100, Item."No.");

        ProcessUsageDataWithSimpleGenericImport(WorkDate(), BillingEndDate, WorkDate(), SubscriptionEndDate, 1);

        if ValidateUnitPrice then begin
            UsageDataBilling.Reset();
            UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
            UsageDataBilling.SetRange(Partner, "Service Partner"::Customer);
            if UsageDataBilling.FindSet() then
                repeat
                    UsageDataBilling.TestField("Unit Price", UsageDataBilling."Charged Period (Days)");
                until UsageDataBilling.Next() = 0;
        end;

        CreateContractInvoicesAndTestProcessedUsageData();
    end;

    local procedure ValidateUsageDataGenericImportAvailability(UsageDataImportEntryNo: Integer; ExpectedServiceObjectAvailability: Enum "Service Object Availability"; ExpectedServiceObjectNo: Code[20])
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImportEntryNo);
        UsageDataGenericImport.FindFirst();
        Assert.AreEqual(ExpectedServiceObjectAvailability, UsageDataGenericImport."Service Object Availability", 'Service Object Availability is not set to expected value in Usage Data Generic Import.');
        Assert.AreEqual(ExpectedServiceObjectNo, UsageDataGenericImport."Subscription Header No.", 'Service Object No. is not set to expected value in Usage Data Generic Import.');
    end;

    #endregion Procedures

    #region Handlers

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure CreateCustomerBillingDocsContractPageHandler(var CreateCustomerBillingDocs: TestPage "Create Customer Billing Docs")
    begin
        CreateCustomerBillingDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CreateCustomerBillingDocumentForBillingDatePageHandler(var CreateCustomerBillingDocument: TestPage "Create Usage B. Cust. B. Docs")
    begin
        CreateCustomerBillingDocument.BillingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CreateCustomerBillingDocument.PostDocument.SetValue(false);
        CreateCustomerBillingDocument.OK().Invoke()
    end;

    [ModalPageHandler]
    procedure CreateCustomerBillingDocumentPageHandler(var CreateCustomerBillingDocument: TestPage "Create Usage B. Cust. B. Docs")
    begin
        CreateCustomerBillingDocument.BillingDate.SetValue(WorkDate());
        CreateCustomerBillingDocument.PostDocument.SetValue(PostDocument);
        CreateCustomerBillingDocument.OK().Invoke()
    end;

    [ModalPageHandler]
    procedure CreateVendorBillingDocumentForBillingDatePageHandler(var CreateVendorBillingDocument: TestPage "Create Usage B. Vend. B. Docs")
    begin
        CreateVendorBillingDocument.BillingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CreateVendorBillingDocument.OK().Invoke()
    end;

    [ModalPageHandler]
    procedure CreateVendorBillingDocumentPageHandler(var CreateVendorBillingDocument: TestPage "Create Usage B. Vend. B. Docs")
    begin
        CreateVendorBillingDocument.BillingDate.SetValue(WorkDate());
        CreateVendorBillingDocument.OK().Invoke()
    end;

    [ModalPageHandler]
    procedure ExchangeRateSelectionModalPageHandler(var ExchangeRateSelectionPage: TestPage "Exchange Rate Selection")
    begin
        ExchangeRateSelectionPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [StrMenuHandler]
    procedure StrMenuHandlerClearBillingProposal(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    procedure UsageDataBillingsModalPageHandler(var UsageDataBillings: TestPage "Usage Data Billings")
    begin
        LibraryVariableStorage.Enqueue(UsageDataBillings.First());
        LibraryVariableStorage.Enqueue(UsageDataBillings.Next());
    end;

    #endregion Handlers

    #region Subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Billing Proposal", OnAfterCalculateBillingPeriodForUsageBasedSubscriptionLine, '', false, false)]
    local procedure LimitBillingPeriodOnAfterCalculateBillingPeriodForUsageBasedSubscriptionLine(var BillingPeriodStart: Date; var BillingPeriodEnd: Date)
    begin
        if not LimitUsageBasedBillingPeriodToFirstMonth then
            exit;
        if CalcDate('<CM>', BillingPeriodStart) < BillingPeriodEnd then
            BillingPeriodEnd := CalcDate('<CM>', BillingPeriodStart);
    end;

    #endregion Subscribers
}
#pragma warning restore AA0210
