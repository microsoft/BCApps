// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.PriceList;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;
using Microsoft.Warehouse.Structure;

codeunit 136125 "Service Posting Journals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        IsInitialized: Boolean;
        ExpectedConfirm: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        NumberOfServiceLedgerEntriesErr: Label 'Number of Service Ledger Entries is incorrect';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Posting Journals");
        Clear(LibraryService);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Posting Journals");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInServiceCosts();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Posting Journals");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithLocation()
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // Covers document number CU-5987-1 refer to TFS ID 172599.
        // Test Posted Entries after Posting Service Order with Location.

        // 1. Setup: Create Location, Inventory setup for Location, Service Order with Item, Resource, Cost and G/L Account.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateServiceOrderWithLines(ServiceHeader, Location.Code);
        GetServiceLines(ServiceLine, ServiceHeader."No.");
        CopyServiceLines(ServiceLine, TempServiceLine);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify VAT Entry, G/L Entry, Resource Ledger Entry, Service Invoice Lines, Customer Ledger Entry, Service Ledger Entry
        // and Value Entry after Posting Service Order.
        VerifyVATEntry(ServiceHeader."No.");
        VerifyGLEntry(ServiceHeader."No.");
        VerifyResourceLedgerEntry(TempServiceLine);
        VerifyServiceInvoice(TempServiceLine);
        VerifyCustomerLedgerEntry(ServiceHeader."No.");
        VerifyServiceLedgerEntry(TempServiceLine);
        VerifyValueEntry(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalWithLocationAndBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Covers document number CU-5987-1 refer to TFS ID 172599.
        // Test Bin Content after Posting Item Journal with Location and Bin Code.

        // 1. Setup: Create Location with Bin Code and Create Item.
        Initialize();
        CreateLocationWithBinCode(Bin);
        LibraryInventory.CreateItem(Item);

        // 2. Exercise: Create and Post Item Journal.
        Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
        CreateAndPostItemJournal(Bin, Item."No.", Quantity);

        // 3. Verify: Verify Bin Content.
        VerifyBinContent(Bin, Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithLocationAndBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
        Quantity: Decimal;
    begin
        // Covers document number CU-5987-1 refer to TFS ID 172599.
        // Test Service Ledger Entry after Posting Service Order with Location and Bin Code.

        // 1. Setup: Create Location with Bin Code, Create Item, Create and Post Item Journal, Create Service Order with Type Item and
        // Update Location and Bin Code on Service Line.
        Initialize();
        CreateLocationWithBinCode(Bin);
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
        CreateAndPostItemJournal(Bin, Item."No.", Quantity);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithLocation(ServiceLine, Bin, ServiceItemLine."Line No.", Quantity);

        // 2. Exercise: Post Service Order as Ship and Consume.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify Service Ledger Entry after Posting Service Order.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        VerifyServiceLedgerEntryForBin(
          ServiceLine, ServiceShipmentHeader."No.", ServiceLedgerEntry."Document Type"::Shipment, ServiceLedgerEntry."Entry Type"::Usage);
        VerifyServiceLedgerEntryForBin(
          ServiceLine, ServiceShipmentHeader."No.", ServiceLedgerEntry."Document Type"::Shipment, ServiceLedgerEntry."Entry Type"::Consume);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithJob()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        ItemNo: Code[20];
        ResourceNo: Code[20];
        Quantity: Decimal;
    begin
        // Covers document number CU-5987-1 refer to TFS ID 172599.
        // Test Service Ledger Entry after Posting Service Order with Job.

        // 1. Setup: Create Job, Job Task, Create Service Order with Item and Resource.
        Initialize();
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Job."Bill-to Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ItemNo := LibraryInventory.CreateItemNo();
        CreateServiceLineWithBlankLocation(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateServiceLineWithJob(ServiceLine, JobTask, ServiceItemLine."Line No.", Quantity);

        ResourceNo := LibraryResource.CreateResourceNo();
        CreateServiceLineWithBlankLocation(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        UpdateServiceLineWithJob(ServiceLine, JobTask, ServiceItemLine."Line No.", Quantity);

        // 2. Exercise: Post Service Order as Ship and Consume.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify Service Ledger Entry after Posting Service Order.
        VerifyServiceLedgerEntryForJob(JobTask, ServiceHeader."No.", ItemNo, Quantity);
        VerifyServiceLedgerEntryForJob(JobTask, ServiceHeader."No.", ResourceNo, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithResource()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number CU-5987-1 refer to TFS ID 172599.
        // Test Shipment Line after Posting Service Order with Resource.

        // 1. Setup: Create Service Order with Resource.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithResource(ServiceHeader, ServiceItemLine."Line No.");
        GetServiceLines(ServiceLine, ServiceHeader."No.");
        CopyServiceLines(ServiceLine, TempServiceLine);

        // 2. Exercise: Post Service Order as Ship and Consume.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify Service Shipment Line after Posting Service Order.
        VerifyServiceShipmentLine(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoWithLocationAndBin()
    var
        Bin: Record Bin;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        // Covers document number CU-5987-2 refer to TFS ID 172599.
        // Test Service Ledger Entry after Posting Service Credit Memo with Location and Bin Code.

        // 1. Setup: Create Location, Bin and Service Credit Memo.
        Initialize();
        CreateLocationWithBinCode(Bin);
        CreateServiceCreditMemo(ServiceHeader, ServiceLine, Bin);

        // 2. Exercise: Post Service Credit Memo.
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Verify Service Ledger Entry after Posting Service Credit Memo.
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceCrMemoHeader.FindFirst();
        VerifyServiceLedgerEntryForBin(
          ServiceLine, ServiceCrMemoHeader."No.", ServiceLedgerEntry."Document Type"::"Credit Memo", ServiceLedgerEntry."Entry Type"::Sale);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumeForServiceOrderWithMultipleLines()
    var
        ServiceHeader: Record "Service Header";
        Quantity: Decimal;
        ItemNo: Code[20];
        OldAutomaticCostPosting: Boolean;
    begin
        // Setup: Update Automatic Cost Posting setup. Create two Items. Create and Post Item Journal for Items. Create Service Order with 3 lines.
        Initialize();
        OldAutomaticCostPosting := UpdateAutomaticCostPosting(true);
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := CreateItemWithUnitCost(LibraryRandom.RandDec(10, 2));
        CreateAndPostItemJournalLine(ItemNo, Quantity);
        CreateServiceOrderWithMultipleLines(ServiceHeader, ItemNo, Quantity);

        // Exercise: Post Service Order as Ship and Consume.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // Verify: Verify Service Order was posted successfully and it generated 3 Consume Service Ledger Entries.
        VerifyServiceLedgerEntryNumber("Service Ledger Entry Entry Type"::Consume, ServiceHeader."No.", 3);

        // Tear down.
        UpdateAutomaticCostPosting(OldAutomaticCostPosting);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithJob_Customer_PriceInclVAT()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        Customer: Record Customer;
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        Currency: Record Currency;
        PriceListLine: Record "Price List Line";
        LibraryJob: Codeunit "Library - Job";
        ExpectedUnitPrice: Decimal;
        ExpectedTotalPrice: Decimal;
    begin
        // [FEATURE] [Job] [Sales Price] [Price Including VAT]
        // [SCENARIO 325829] Posted prices does not include VAT in Job Ledger Entry when posting Service Order for customer with enabled "Prices Incl. VAT".
        Initialize();

        // [GIVEN] Job "J" with job task "JT"
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Customer "C" enabled "Prices Including VAT", Item "I" and sales price for "A" and "I" with "Unit Price" = 100 and "Price Incl. VAT" = TRUE (from customer)
        Customer.Get(Job."Bill-to Customer No.");
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::Customer, Customer."No.",
            WorkDate() - 1, '', '', '', 0, LibraryRandom.RandIntInRange(100, 200));
        SalesPrice.TestField("Price Includes VAT", Customer."Prices Including VAT");
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [GIVEN] Service Order "O" for "C" with service line having "Type" = Item, "Item No." = "I", "Qty. to Consume" = 2 and attached "J" with "JT"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Job."Bill-to Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithBlankLocation(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithJob(ServiceLine, JobTask, ServiceItemLine."Line No.", LibraryRandom.RandInt(10));
        ServiceLine.Validate("Job Line Type", ServiceLine."Job Line Type"::"Both Budget and Billable");
        ServiceLine.Modify(true);

        // [GIVEN] "VAT %" = 10% and "Unit Price Incl. VAT" = 100 (from sales price) in service line.
        ServiceLine.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        ServiceLine.Modify(true);
        ServiceLine.TestField("Unit Price", SalesPrice."Unit Price");

        // [WHEN] When post "O"
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] "Unit Price" = ROUND(100 / 1.1) = 90.9 in created Job Ledger Entry
        // [THEN] "Total Price" = ROUND(2  * 100 / 1.1) = 181.8 in created Job Ledger Entry
        Currency.Initialize('');

        ExpectedUnitPrice :=
          Round(SalesPrice."Unit Price" / (1 + ServiceLine."VAT %" / 100), Currency."Unit-Amount Rounding Precision");
        ExpectedTotalPrice := Round(ServiceLine."Qty. to Consume" * ExpectedUnitPrice, Currency."Amount Rounding Precision");

        VerifyPricesOnJobLedgerEntry(Item, ExpectedUnitPrice, ExpectedTotalPrice);
    end;

    local procedure CopyServiceLines(var FromServiceLine: Record "Service Line"; var ToTempServiceLine: Record "Service Line" temporary)
    begin
        if FromServiceLine.FindSet() then
            repeat
                ToTempServiceLine.Init();
                ToTempServiceLine := FromServiceLine;
                ToTempServiceLine.Insert();
            until FromServiceLine.Next() = 0
    end;

    local procedure CreateAndPostItemJournal(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalBatch.SetRange("Template Type", ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch.Next(LibraryRandom.RandInt(ItemJournalBatch.Count));
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", Bin."Location Code");
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalBatch.SetRange("Template Type", ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch.Next(LibraryRandom.RandInt(ItemJournalBatch.Count));
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateLocationWithBinCode(var Bin: Record Bin)
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(
          Bin,
          Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))),
          '',
          '');
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; Bin: Record Bin)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomer());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Location Code", Bin."Location Code");
        ServiceLine.Validate("Bin Code", Bin.Code);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithResource(ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    var
        Resource: Record Resource;
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Lines with Type Resource - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
            ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
            ServiceLine.Modify(true);
            Resource.Next();
        end;
    end;

    local procedure CreateServiceOrderWithLines(var ServiceHeader: Record "Service Header"; LocationCode: Code[10])
    var
        Customer: Record Customer;
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        GLAccount: Record "G/L Account";
        ServiceCost: Record "Service Cost";
        LibraryResource: Codeunit "Library - Resource";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Service Header, Service Item Line, Service Line with Type Item, Resource, Cost and G/L Account.
        LibrarySales.CreateCustomer(Customer);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        LibraryERM.FindGLAccount(GLAccount);
        LibraryService.FindServiceCost(ServiceCost);

        CreateServiceLine(ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), ServiceItemLine."Line No.");
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo(), ServiceItemLine."Line No.");
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, ServiceItemLine."Line No.");
        CreateServiceLine(
          ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceOrderWithMultipleLines(var ServiceHeader: Record "Service Header"; ItemNo: Code[20]; Qty: Decimal)
    var
        Customer: Record Customer;
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceCost: Record "Service Cost";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // Test requires to create 3 Service Lines with Type Item, Cost and Item.
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Item, ItemNo, ServiceItemLine."Line No.", Qty);
        LibraryService.FindServiceCost(ServiceCost);
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, ServiceItemLine."Line No.", Qty);
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Item, ItemNo, ServiceItemLine."Line No.", Qty);
    end;

    local procedure CreateServiceLineWithBlankLocation(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; Type: Enum "Service Document Type"; No: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Location Code", '');
        ServiceLine.Modify();
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceLine.Modify(true);
    end;

    [Normal]
    local procedure ExecuteConfirmHandlerInvoiceES()
    begin
        if Confirm(StrSubstNo(ExpectedConfirm)) then;
    end;

    local procedure CreateItemWithUnitCost(UnitCost: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", UnitCost);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateAndUpdateServiceLine(ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; ServiceItemLineNo: Integer; Qty: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, Qty);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; Quantity: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
    end;

    local procedure UpdateServiceLineWithLocation(var ServiceLine: Record "Service Line"; Bin: Record Bin; ServiceItemLineNo: Integer; Quantity: Decimal)
    begin
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, Quantity);
        ServiceLine.Validate("Location Code", Bin."Location Code");
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Validate("Bin Code", Bin.Code);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateServiceLineWithJob(var ServiceLine: Record "Service Line"; JobTask: Record "Job Task"; ServiceItemLineNo: Integer; Quantity: Decimal)
    begin
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, Quantity);
        ServiceLine.Validate("Job No.", JobTask."Job No.");
        ServiceLine.Validate("Job Task No.", JobTask."Job Task No.");
        ServiceLine.Modify(true);
    end;

    local procedure UpdateAutomaticCostPosting(NewAutomaticCostPosting: Boolean) OldAutomaticCostPosting: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldAutomaticCostPosting := InventorySetup."Automatic Cost Posting";
        InventorySetup.Validate("Automatic Cost Posting", NewAutomaticCostPosting);
        InventorySetup.Modify(true);
    end;

    local procedure GetServiceLines(var ServiceLine: Record "Service Line"; ServiceOrderNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceOrderNo);
        ServiceLine.FindSet();
    end;

    local procedure VerifyBinContent(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", Bin."Location Code");
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.FindFirst();
        BinContent.TestField(Fixed, true);
        BinContent.TestField(Default, true);
        BinContent.TestField("Item No.", ItemNo);
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Quantity);
    end;

    local procedure VerifyCustomerLedgerEntry(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
    end;

    local procedure VerifyGLEntry(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Source Type", GLEntry."Source Type"::Customer);
            GLEntry.TestField("Source No.", ServiceInvoiceHeader."Bill-to Customer No.");
            GLEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyResourceLedgerEntry(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        TempServiceLine.SetRange(Type, TempServiceLine.Type::Resource);
        TempServiceLine.FindFirst();

        ServiceInvoiceHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();

        ResLedgerEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ResLedgerEntry.SetRange("Resource No.", TempServiceLine."No.");
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
        ResLedgerEntry.TestField(Quantity, -TempServiceLine.Quantity);
        ResLedgerEntry.TestField("Order Type", ResLedgerEntry."Order Type"::Service);
        ResLedgerEntry.TestField("Order No.", TempServiceLine."Document No.");
        ResLedgerEntry.TestField("Order Line No.", TempServiceLine."Line No.");
    end;

    local procedure VerifyServiceInvoice(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        TempServiceLine.FindSet();
        ServiceInvoiceHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        repeat
            ServiceInvoiceLine.Get(ServiceInvoiceHeader."No.", TempServiceLine."Line No.");
            ServiceInvoiceLine.TestField(Type, TempServiceLine.Type);
            ServiceInvoiceLine.TestField("No.", TempServiceLine."No.");
            ServiceInvoiceLine.TestField("Line Discount %", TempServiceLine."Line Discount %");
            ServiceInvoiceLine.TestField("Line Discount Amount", TempServiceLine."Line Discount Amount");
            ServiceInvoiceLine.TestField("Inv. Discount Amount", TempServiceLine."Inv. Discount Amount");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        TempServiceLine.FindSet();
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Service Order No.", TempServiceLine."Document No.");
        repeat
            ServiceLedgerEntry.SetRange("Document Line No.", TempServiceLine."Line No.");
            ServiceLedgerEntry.FindFirst();
            ServiceLedgerEntry.TestField("No.", TempServiceLine."No.");
            ServiceLedgerEntry.TestField(Quantity, TempServiceLine.Quantity);
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntryForBin(ServiceLine: Record "Service Line"; DocumentNo: Code[20]; DocumentType: Enum "Service Ledger Entry Document Type"; EntryType: Enum "Service Ledger Entry Entry Type")
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document Type", DocumentType);
        ServiceLedgerEntry.SetRange("Entry Type", EntryType);
        ServiceLedgerEntry.SetRange("Document No.", DocumentNo);
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.TestField("Location Code", ServiceLine."Location Code");
        ServiceLedgerEntry.TestField("Bin Code", ServiceLine."Bin Code");
        ServiceLedgerEntry.TestField("No.", ServiceLine."No.");
        if EntryType = ServiceLedgerEntry."Entry Type"::Consume then
            ServiceLedgerEntry.TestField(Quantity, -ServiceLine.Quantity)
        else
            ServiceLedgerEntry.TestField(Quantity, ServiceLine.Quantity);
    end;

    local procedure VerifyServiceLedgerEntryForJob(JobTask: Record "Job Task"; ServiceOrderNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceOrderNo);
        ServiceLedgerEntry.SetRange("No.", No);
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField("Job No.", JobTask."Job No.");
            ServiceLedgerEntry.TestField("Job Task No.", JobTask."Job Task No.");
            if ServiceLedgerEntry."Entry Type" = ServiceLedgerEntry."Entry Type"::Consume then
                ServiceLedgerEntry.TestField(Quantity, -Quantity)
            else
                ServiceLedgerEntry.TestField(Quantity, Quantity);
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyServiceShipmentLine(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", TempServiceLine."Document No.");
        TempServiceLine.FindSet();
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", TempServiceLine."Line No.");
            ServiceShipmentLine.FindFirst();
            ServiceShipmentLine.TestField("No.", TempServiceLine."No.");
            ServiceShipmentLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceShipmentLine.TestField("Quantity Consumed", TempServiceLine.Quantity);
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyVATEntry(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATEntry: Record "VAT Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        VATEntry.FindSet();
        repeat
            VATEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
            VATEntry.TestField("Bill-to/Pay-to No.", ServiceInvoiceHeader."Bill-to Customer No.");
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyValueEntry(var TempServiceLine: Record "Service Line" temporary)
    var
        ValueEntry: Record "Value Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        TempServiceLine.SetRange(Type, TempServiceLine.Type::Item);
        TempServiceLine.FindFirst();

        ServiceInvoiceHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();

        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Invoice");
        ValueEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ValueEntry.SetRange("Document Line No.", TempServiceLine."Line No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Item No.", TempServiceLine."No.");
        ValueEntry.TestField("Valued Quantity", -TempServiceLine.Quantity);
    end;

    local procedure VerifyServiceLedgerEntryNumber(EntryType: Enum "Service Ledger Entry Entry Type"; ServiceOrderNo: Code[20]; "Count": Integer)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Entry Type", EntryType);
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceOrderNo);
        Assert.AreEqual(Count, ServiceLedgerEntry.Count, NumberOfServiceLedgerEntriesErr);
    end;

    local procedure VerifyPricesOnJobLedgerEntry(Item: Record Item; ExpectedUnitPrice: Decimal; ExpectedTotalPrice: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.SetRange("No.", Item."No.");
        JobLedgerEntry.FindFirst();

        JobLedgerEntry.TestField("Unit Price (LCY)", ExpectedUnitPrice);
        JobLedgerEntry.TestField("Total Price (LCY)", ExpectedTotalPrice);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceESConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := (Question = ExpectedConfirm);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
