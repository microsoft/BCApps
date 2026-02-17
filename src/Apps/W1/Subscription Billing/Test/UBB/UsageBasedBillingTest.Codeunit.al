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
        PostDocument: Boolean;
        CorrectedDocumentNo: Code[20];
        i: Integer;
        j: Integer;
        ColumnSeparator: Option " ",Tab,Semicolon,Comma,Space,Custom;
        FileEncoding: Option "MS-DOS","UTF-8","UTF-16",WINDOWS;
        FileType: Option Xml,"Variable Text","Fixed Text",Json;

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
        ResetAll();
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
        ResetAll();
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

    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,CreateCustomerBillingDocumentPageHandler,MessageHandler')]
    [Test]
    procedure ResetUsageDataBillingWhenRelatedSalesInvoiceLineIsDeleted()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        // [SCENARIO] When sales invoice with usage data is created if a line is deleted related usage data billing should be reset
        // [GIVEN] A customer contract with usage-based service commitments and a sales invoice created from usage data
        ResetAll();
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
        ResetAll();
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
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler,StrMenuHandlerClearBillingProposal')]
    procedure TestBillingLineInUsageDataNoWhenBillingProposalIsCreated()
    var
        UsageDataBilling: Record "Usage Data Billing";
        BillingProposal: Codeunit "Billing Proposal";
    begin
        //[SCENARIO] Create recurring billing for simple customer contract; Check if Usage Data Billing Line No. has billing line no

        ResetAll();
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
        TestSubscribers: Codeunit "Usage Based B. Test Subscr.";
        QuantityOfServiceCommitments: Integer;
    begin
        Initialize();
        ContractTestLibrary.InitContractsApp();
        // [GIVEN] Multiple Contracts with Usage based Subscription Lines and Usage Data Billing
        ContractTestLibrary.CreateCustomer(Customer);
        ContractTestLibrary.CreateCustomerContract(CustomerContract, Customer."No.");
        ContractTestLibrary.CreateCustomerContract(CustomerContract2, Customer."No.");
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, '');

        TestSubscribers.SetTestContext('TestCreateInvoicesForMoreThanOneContractPerImport');
        BindSubscription(TestSubscribers);
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract, SubscriptionHeader, false); // ExchangeRateSelectionModalPageHandler,MessageHandler
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract2, ServiceObject2, false); // ExchangeRateSelectionModalPageHandler,MessageHandler
        UnbindSubscription(TestSubscribers);

        SubscriptionLine.SetFilter("Subscription Header No.", '%1|%2', SubscriptionHeader."No.", ServiceObject2."No.");
        QuantityOfServiceCommitments := SubscriptionLine.Count();
        SubscriptionLine.FindSet();
        repeat
            CreateUsageDataBillingDummyDataFromSubscriptionLine(UsageDataBilling, UsageDataImport."Entry No.", SubscriptionLine);
        until SubscriptionLine.Next() = 0;

        // [WHEN] Creating a billing proposal via Contract or "Recurring Billing"
        ContractTestLibrary.CreateRecurringBillingTemplate(BillingTemplate, '<CM>', '', '', Enum::"Service Partner"::Customer);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);

        // [THEN] A new Billing Line should be created for each Usage Based Subscription Line and Contract with usage data when creating an invoice via "Usage Data Imports"
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
        TestSubscribers: Codeunit "Usage Based B. Test Subscr.";
        QuantityOfServiceCommitments: Integer;
    begin
        Initialize();
        ContractTestLibrary.InitContractsApp();
        // [GIVEN] Multiple Contracts with Usage based Subscription Lines and Usage Data Billing
        ContractTestLibrary.CreateCustomer(Customer);
        ContractTestLibrary.CreateCustomerContract(CustomerContract, Customer."No.");
        ContractTestLibrary.CreateCustomerContract(CustomerContract2, Customer."No.");
        UsageBasedBTestLibrary.CreateUsageDataImport(UsageDataImport, '');

        TestSubscribers.SetTestContext('TestCreateInvoicesForMoreThanOneContractPerImport');
        BindSubscription(TestSubscribers);
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract, SubscriptionHeader, false); // ExchangeRateSelectionModalPageHandler,MessageHandler
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract2, ServiceObject2, false); // ExchangeRateSelectionModalPageHandler,MessageHandler
        UnbindSubscription(TestSubscribers);

        SubscriptionLine.SetFilter("Subscription Header No.", '%1|%2', SubscriptionHeader."No.", ServiceObject2."No.");
        QuantityOfServiceCommitments := SubscriptionLine.Count();
        SubscriptionLine.FindSet();
        repeat
            CreateUsageDataBillingDummyDataFromSubscriptionLine(UsageDataBilling, UsageDataImport."Entry No.", SubscriptionLine);
        until SubscriptionLine.Next() = 0;

        // [WHEN] Creating a billing proposal via "Usage Data Imports" (CollectCustomerContractsAndCreateInvoices)
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport); // CreateCustomerBillingDocumentPageHandler

        // [THEN] A Billing Line should be created for Usage Based Subscription Lines with usage data
        BillingLine.Reset();
        Assert.AreEqual(QuantityOfServiceCommitments, BillingLine.Count(), 'A new Billing Line should be created for each Usage Based Service Commitment and Contract with usage data when creating an invoice via "Usage Data Imports"');
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestCreateUsageDataBilling()
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        // [SCENARIO] Usage data billing records are created correctly from generic import
        // [GIVEN] Usage data for fixed quantity pricing
        Initialize();
        CreateUsageDataBilling("Usage Based Pricing"::"Fixed Quantity", LibraryRandom.RandDec(10, 2));

        // [THEN] Usage data import has Ok status and billing records match the generic import
        UsageDataImport.FindLast();
        UsageDataImport.TestField("Processing Status", "Processing Status"::Ok);
        UsageDataBilling.FindLast();
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.FindFirst();
        TestUsageDataBilling(UsageDataGenericImport, UsageDataBilling);
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
        Currency.InitRoundingPrecision();
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
        ResetAll();
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
        ResetAll();

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
        Currency.InitRoundingPrecision();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        ContractTestLibrary.InitSourceCodeSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Usage Based Billing Test");
    end;

    local procedure ResetAll()
    begin
        ClearAll();
        UsageBasedBTestLibrary.DeleteAllUsageBasedRecords();
        BillingLine.Reset();
        BillingLine.DeleteAll(false);
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

    local procedure CreateContractInvoicesAndTestProcessedUsageData()
    var
        UsageDataBilling: Record "Usage Data Billing";
        ExpectedInvoiceAmount: Decimal;
    begin
        FilterUsageDataBillingOnUsageDataImport(UsageDataBilling, UsageDataImport."Entry No.", "Service Partner"::Customer);
        UsageDataBilling.CalcSums(Amount);
        ExpectedInvoiceAmount := UsageDataBilling.Amount;
        UsageDataImport.CollectCustomerContractsAndCreateInvoices(UsageDataImport);

        Currency.InitRoundingPrecision();
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
        TempSubscriptionLine: Record "Subscription Line" temporary;
    begin
        ContractTestLibrary.CreateCustomerContract(CustomerContract, Customer."No.");
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
    var
        TempSubscriptionLine: Record "Subscription Line" temporary;
    begin
        ContractTestLibrary.CreateVendor(Vendor);
        ContractTestLibrary.CreateVendorContract(VendorContract, Vendor."No.");
        ContractTestLibrary.FillTempServiceCommitmentForVendor(TempSubscriptionLine, SubscriptionHeader, VendorContract);
        VendorContract.CreateVendorContractLinesFromServiceCommitments(TempSubscriptionLine);
        VendorContractLine.SetRange("Subscription Contract No.", VendorContract."No.");
        VendorContractLine.FindLast();
        ContractTestLibrary.SetGeneralPostingSetup(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", false, Enum::"Service Partner"::Vendor);
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

    local procedure MockUsageData(var NewUsageDataBilling: Record "Usage Data Billing"; Partner: Enum "Service Partner"; DocumentType: Enum "Usage Based Billing Doc. Type"; DocumentNo: Code[20])
    begin
        NewUsageDataBilling.Init();
        NewUsageDataBilling.Partner := Partner;
        NewUsageDataBilling."Document Type" := DocumentType;
        NewUsageDataBilling."Document No." := DocumentNo;
        NewUsageDataBilling.Insert(false);
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

    local procedure TestUsageDataBilling(UsageDataGenericImport: Record "Usage Data Generic Import"; var UsageDataBilling: Record "Usage Data Billing")
    begin
        UsageDataBilling.TestField("Usage Data Import Entry No.", UsageDataGenericImport."Usage Data Import Entry No.");
        UsageDataBilling.TestField("Subscription Header No.", UsageDataGenericImport."Subscription Header No.");
        UsageDataBilling.TestField("Charge Start Date", UsageDataGenericImport."Billing Period Start Date");
        UsageDataBilling.TestField("Charge End Date", UsageDataGenericImport."Billing Period End Date");
        UsageDataBilling.TestField("Unit Cost", UsageDataGenericImport.Cost);
        UsageDataBilling.TestField(Quantity, UsageDataGenericImport.Quantity);
        UsageDataBilling.TestField("Cost Amount", UsageDataGenericImport."Cost Amount");
        UsageDataBilling.TestField(Amount, 0);
        UsageDataBilling.TestField("Unit Price", 0);
        UsageDataBilling.TestField("Currency Code", UsageDataGenericImport.Currency);
        UsageDataBilling.TestField("Subscription Header No.", SubscriptionLine."Subscription Header No.");
        UsageDataBilling.TestField(Partner, SubscriptionLine.Partner);
        UsageDataBilling.TestField("Subscription Contract No.", SubscriptionLine."Subscription Contract No.");
        UsageDataBilling.TestField("Subscription Contract Line No.", SubscriptionLine."Subscription Contract Line No.");
        UsageDataBilling.TestField("Subscription Header No.", SubscriptionLine."Subscription Header No.");
        UsageDataBilling.TestField("Subscription Line Entry No.", SubscriptionLine."Entry No.");
        UsageDataBilling.TestField("Usage Base Pricing", SubscriptionLine."Usage Based Pricing");
        UsageDataBilling.TestField("Pricing Unit Cost Surcharge %", SubscriptionLine."Pricing Unit Cost Surcharge %");
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
    procedure CreateCustomerBillingDocumentPageHandler(var CreateCustomerBillingDocument: TestPage "Create Usage B. Cust. B. Docs")
    begin
        CreateCustomerBillingDocument.BillingDate.SetValue(WorkDate());
        CreateCustomerBillingDocument.PostDocument.SetValue(PostDocument);
        CreateCustomerBillingDocument.OK().Invoke()
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
}
#pragma warning restore AA0210
