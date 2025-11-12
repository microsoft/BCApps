// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.CRM.Team;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Document;
using Microsoft.Service.Item;

codeunit 136115 "Service Quote"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Quote] [Service]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        CustomerBlockedAllErr: Label 'You cannot create this type of document when Customer %1 is blocked with type All', Comment = '%1 = customer code';
        CustomerPrivacyBlockedErr: Label 'You cannot create this type of document when Customer %1 is blocked for privacy.', Comment = '%1 = customer code';
        SalespersonPrivacyBlockedErr: Label 'You cannot create this document because Salesperson %1 is blocked due to privacy.', Comment = '%1 = salesperson code';

    [Test]
    [HandlerFunctions('StringMenuHandlerOptionThree')]
    [Scope('OnPrem')]
    procedure SparePartActionOnServiceLines()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemNo: Code[20];
    begin
        // Covers document number TC01104 - refer to TFS ID 21647.
        // Test Spare Part Action on Service Line.

        // 1. Setup: Create a new Service Item with a random Customer and new Service Item Component of Type as Item. Create
        // Service Quote for the Service Item - Service Header and Service Item Line.
        Initialize();
        ItemNo := CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Create a Service Line for the Service Item with an Item that is different from the Item selected as component.
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ItemNo, ServiceItem."No.");

        // 3. Verify: Check Spare Part Action on Service Line as Blank.
        ServiceLine.TestField("Spare Part Action", ServiceLine."Spare Part Action"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceQuoteReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceQuote: Report "Service Quote";
        FilePath: Text[1024];
    begin
        // Covers document number TC01105 - refer to TFS ID 21647.
        // Test generation of Service Quote report.

        // 1. Setup: Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header,
        // Service Item Line and Service Line with Random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);

        // 2. Exercise: Save Service Quote Report as XML and XLSX in local Temp folder.
        Clear(ServiceQuote);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        ServiceQuote.SetTableView(ServiceHeader);
        FilePath := TemporaryPath + Format(ServiceHeader."Document Type") + ServiceHeader."No." + '.xlsx';
        ServiceQuote.SaveAsExcel(FilePath);

        // 3. Verify: Verify that saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeCustomerOnServiceQuote()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC01106 - refer to TFS ID 21647.
        // Test changing of the Customer No. on Service Quote.

        // 1. Setup: Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header,
        // Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);

        // 2. Exercise: Change the Customer No of the Service Quote.
        LibrarySales.CreateCustomer(Customer);
        ServiceHeader.Validate("Customer No.", Customer."No.");
        ServiceHeader.Modify(true);

        // 3. Verify: Check that the Customer No. on Service Quote was updated.
        ServiceHeader.TestField("Customer No.", Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeServiceOrderFromQuote()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC01107 - refer to TFS ID 21647.
        // Test creation of Service Order from Service Quote.

        // 1. Setup: Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header,
        // Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);

        // 2. Exercise: Convert Service Quote to Service Order.
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // 3. Verify: Check that the Service Quote is converted to Service Order.
        FindServOrderByQuoteNo(ServiceHeader, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeServiceOrderFromQuoteCustomerBlockedAll()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
    begin
        // Covers document number TC01107 - refer to TFS ID 21647.
        // Test creation of Service Order from Service Quote.

        // 1. Setup: Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header,
        // Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);
        Customer.Get(ServiceHeader."Customer No.");
        Customer.Validate(Blocked, Customer.Blocked::All);
        Customer.Modify();

        // 2. Exercise: Convert Service Quote to Service Order.  Error should be thrown.
        asserterror LibraryService.CreateOrderFromQuote(ServiceHeader);
        Assert.AreEqual(StrSubstNo(CustomerBlockedAllErr, Customer."No."), GetLastErrorText, 'Error message was incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeServiceOrderFromQuoteCustomerPrivacyBlocked()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
    begin
        // Covers document number TC01107 - refer to TFS ID 21647.
        // Test creation of Service Order from Service Quote.

        // 1. Setup: Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header,
        // Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);
        Customer.Get(ServiceHeader."Customer No.");
        Customer.Validate("Privacy Blocked", true);
        Customer.Modify();

        // 2. Exercise: Convert Service Quote to Service Order.  Error should be thrown.
        asserterror LibraryService.CreateOrderFromQuote(ServiceHeader);
        Assert.AreEqual(StrSubstNo(CustomerPrivacyBlockedErr, Customer."No."), GetLastErrorText, 'Error message was incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeServiceOrderFromQuoteSalespersonPrivacyBlocked()
    var
        ServiceHeader: Record "Service Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // Covers document number TC01107 - refer to TFS ID 21647.
        // Test creation of Service Order from Service Quote.

        // 1. Setup: Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header,
        // Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        ServiceHeader."Salesperson Code" := SalespersonPurchaser.Code;
        ServiceHeader.Modify();
        SalespersonPurchaser.Validate("Privacy Blocked", true);
        SalespersonPurchaser.Modify();

        // 2. Exercise: Convert Service Quote to Service Order.  Error should be thrown.
        asserterror LibraryService.CreateOrderFromQuote(ServiceHeader);
        Assert.AreEqual(
          StrSubstNo(SalespersonPrivacyBlockedErr, SalespersonPurchaser.Code), GetLastErrorText, 'Error message was incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: Report "Service Order";
        FilePath: Text[1024];
    begin
        // Covers document number TC01108 - refer to TFS ID 21647.
        // Test generation of Service Order report.

        // 1. Setup: Create a new Service Item with a random Customer. Create a Service Order for the Service Item - Service Header,
        // Service Item Line and Service Line with Random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        // 2. Exercise: Save Service Order Report as XML and XLSX in local Temp folder.
        Clear(ServiceOrder);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        ServiceOrder.SetTableView(ServiceHeader);
        FilePath := TemporaryPath + Format(ServiceHeader."Document Type") + ServiceHeader."No." + '.xlsx';
        ServiceOrder.SaveAsExcel(FilePath);

        // 3. Verify: Verify that saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DiscountOnServiceQuote()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        ServiceLines: TestPage "Service Lines";
    begin
        // Test Unit Price on Service Quote after running Calculate Invoice Discount.

        // 1. Setup: Create Customer with Customer Invoice Discount, Service Header with Document Type as Quote and Service Line with
        // Type as Item.
        Initialize();
        CreateCustomerWithDiscount(CustInvoiceDisc);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, CustInvoiceDisc.Code);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, LibraryInventory.CreateItemNo(), '');
        InputUnitPriceInServiceLine(ServiceLine, CustInvoiceDisc."Minimum Amount");

        // 2. Exercise: Run Calculate Invoice Discount.
        Clear(ServiceLines);
        ServiceLines.OpenView();
        ServiceLines.FILTER.SetFilter("Document Type", Format(ServiceLine."Document Type"));
        ServiceLines.FILTER.SetFilter("Document No.", ServiceLine."Document No.");
        ServiceLines.First();
        ServiceLines."Calculate Invoice Discount".Invoke();

        // 3. Verify: Verify Unit Price on Service Quote.
        VerifyUnitPrice(ServiceLine, CustInvoiceDisc."Service Charge");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderLineWithPostingDateEqualWorkDate()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 378534] Service Line of Service Order which was made from Servive Quote is equal Work Date

        Initialize();
        // [GIVEN] Service Quote with "Posting Date" = "01.01". Work Date = "10.01"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        ServiceHeader.Validate("Posting Date", ServiceHeader."Posting Date" + 1);
        ServiceHeader.Modify(true);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, LibraryInventory.CreateItemNo(), '');

        // [WHEN] Make Service Order from Service Quote
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] "Posting Date" of Service Order is "10.01"
        VerifyServiceLinePostingDate(ServiceHeader."No.", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeInServiceQuote()
    var
        Location: Record Location;
        ServiceHeaderQuote: Record "Service Header";
        ServiceHeaderOrder: Record "Service Header";
        ServiceQuote: TestPage "Service Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 228188] Location Code is shown on Service Quote page and is copied to Service Order.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Service quote.
        LibraryService.CreateServiceHeader(
          ServiceHeaderQuote, ServiceHeaderQuote."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [GIVEN] Location Code is set to "L" on service quote page.
        ServiceQuote.OpenEdit();
        ServiceQuote.GotoRecord(ServiceHeaderQuote);
        ServiceQuote."Location Code".SetValue(Location.Code);
        ServiceQuote.Close();

        // [WHEN] Create service order from the service quote.
        ServiceHeaderQuote.Find();
        LibraryService.CreateOrderFromQuote(ServiceHeaderQuote);

        // [THEN] Location Code = "L" on the new service order.
        FindServOrderByQuoteNo(ServiceHeaderOrder, ServiceHeaderQuote."No.");
        ServiceHeaderOrder.TestField("Location Code", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Service Header of type "Quote"
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Quote;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Service Quote' is returned
        Assert.AreEqual('Service Quote', ServiceHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Quote");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Quote");

        LibraryService.SetupServiceMgtNoSeries();
        LibrarySales.SetStockoutWarning(false);
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        isInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Quote");
    end;

    local procedure CreateCustomerWithDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc.")
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibrarySales.CreateCustomer(Customer);

        // Use Random for Minimum Amount and Service Charge.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', LibraryRandom.RandDec(100, 2));
        CustInvoiceDisc.Validate("Service Charge", LibraryRandom.RandDec(100, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; Type: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, Type, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, LibraryInventory.CreateItemNo(), ServiceItem."No.");
    end;

    local procedure CreateServiceItemWithComponent(var ServiceItem: Record "Service Item"): Code[20]
    var
        Item: Record Item;
        ServiceItemComponent: Record "Service Item Component";
    begin
        // Create a new Service Item with random Service Item Components.
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceItemComponent(ServiceItemComponent, ServiceItem."No.", ServiceItemComponent.Type::Item, Item."No.");
        Item.Next();
        exit(Item."No.");
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemNo: Code[20]; ServiceItemNo: Code[20])
    begin
        // Create Service Line with random value for Quantity.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);
    end;

    local procedure InputUnitPriceInServiceLine(var ServiceLine: Record "Service Line"; UnitPrice: Decimal)
    begin
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure FindServOrderByQuoteNo(var ServiceHeader: Record "Service Header"; QuoteNo: Code[20])
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Quote No.", QuoteNo);
        ServiceHeader.FindFirst();
    end;

    local procedure VerifyUnitPrice(ServiceLine: Record "Service Line"; UnitPrice: Decimal)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::"G/L Account");
        ServiceLine.FindFirst();
        ServiceLine.TestField(Quantity, 1);  // Use 1 as it's required for test case.
        ServiceLine.TestField("Unit Price", UnitPrice);
    end;

    local procedure VerifyServiceLinePostingDate(QuoteNo: Code[20]; ExpectedPostingDate: Date)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        FindServOrderByQuoteNo(ServiceHeader, QuoteNo);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Posting Date", ExpectedPostingDate);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandlerOptionThree(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the third option of the string menu.
        Choice := 3;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

