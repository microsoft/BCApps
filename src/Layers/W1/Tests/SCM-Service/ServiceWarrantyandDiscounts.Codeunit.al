// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;

codeunit 136120 "Service Warranty and Discounts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Contract Discount] [Service]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        isInitialized: Boolean;
        ServiceContractConfirmation: Label 'Do you want to create the contract using a contract template?';
        ServiceOrderMustNotExist: Label 'The %1 must not exist. Identification fields and values:%2=''%3'',%4=''%5''';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Warranty and Discounts");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Warranty and Discounts");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Warranty and Discounts");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure NoWarrantyAndContractDiscount()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-RSM-D-1 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created and discounts are registered correctly on the posted service invoice when the
        // service order is posted with discounts and the Exclude Warranty and the Exclude Contract Discount fields are not selected.

        WarrantyContractDiscount(false, false, ServiceLine."Line Discount Type"::"Warranty Disc.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure WarrantyWOContractDiscount()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-RSM-D-2 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created and discounts are registered correctly on the posted service invoice when the
        // service order is posted with discounts and the Exclude Warranty is selected and the Exclude Contract Discount field is not
        // selected.

        WarrantyContractDiscount(true, false, ServiceLine."Line Discount Type"::"Contract Disc.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure WarrantyAndContractDiscount()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-RSM-D-3 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created and discounts are registered correctly on the posted service invoice when the
        // service order is posted with discounts and the Exclude Warranty and the Exclude Contract Discount fields are selected.

        WarrantyContractDiscount(true, true, ServiceLine."Line Discount Type"::"Line Disc.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure ContractDiscountWOWarranty()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-RSM-D-4 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created and discounts are registered correctly on the posted service invoice when the
        // service order is posted with discounts and the Exclude Warranty is not selected and the Exclude Contract Discount field
        // is selected.

        WarrantyContractDiscount(false, true, ServiceLine."Line Discount Type"::"Warranty Disc.");
    end;

    local procedure WarrantyContractDiscount(ExcludeWarranty: Boolean; ExcludeContractDiscount: Boolean; LineDiscountType: Enum "Service Line Discount Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        Resource: Record Resource;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        TempServiceLine: Record "Service Line" temporary;
        LibraryUtility: Codeunit "Library - Utility";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // 1. Setup: Create Resource. Create Resource Group, Assign it to the Resource.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        AssignResourceGroupToResource(Resource);

        // 2. Exercise: Create Item, Create Service Item. Create a new Contract with Contract/Service Discounts, Sign the Contract.
        // Create Service Order. Update Exclude Warranty and Exclude Contract Discount fields as per parameter.
        // Update Service Line and post the Service Order as Ship and Invoice.
        CreateItem(Item, Customer."No.", LibraryUtility.GenerateRandomFraction());
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.", LibraryUtility.GenerateRandomFraction());

        CreateServiceContract(ServiceContractHeader, ServiceItem);
        CreateDiscountServiceContract(
          ServiceContractHeader, ServiceItem."Service Item Group Code", Resource."Resource Group No.",
          LibraryUtility.GenerateRandomFraction());
        SignServContractDoc.SignContract(ServiceContractHeader);

        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceContractHeader."Contract No.", Resource."No.");
        UpdateWarrantyServiceLine(ServiceHeader."No.", ExcludeWarranty, ExcludeContractDiscount);
        UpdateAndPostServiceLine(TempServiceLine, LineDiscountType, ServiceHeader."No.");

        // 3. Verify: The Service Order is deleted. Check Service Shipment. Check Service Ledger Entry, Customer Ledger Entries,
        // Detailed Customer Ledger Entries, Resource Leger Entry, VAT Entry and GL entries are created correctly for the posted Invoice.
        VerifyServiceOrderPost(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure ContractDiscountGreatest()
    var
        Customer: Record Customer;
        Item: Record Item;
        Resource: Record Resource;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        SignServContractDoc: Codeunit SignServContractDoc;
        LibraryUtility: Codeunit "Library - Utility";
        LineDiscountPercentage: Decimal;
    begin
        // Covers document number TC-RSM-D-5 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created correctly when the service order is posted with discounts, of which the
        // Contract Discount has the greatest value. Verify that discounts are correctly registered on the posted service invoice.

        // 1. Setup: Create Resource. Create Resource Group, Assign it to the Resource.
        // Set Contract Discount Greatest.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        AssignResourceGroupToResource(Resource);
        LineDiscountPercentage := LibraryUtility.GenerateRandomFraction();

        // 2. Exercise: Create Item, Create Service Item. Create a new Contract with Contract/Service Discounts,
        // Sign the Contract. Create Service Order. Update Service Line and post the Service Order as Ship and Invoice.
        CreateItem(Item, Customer."No.", LineDiscountPercentage);
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.", LineDiscountPercentage);

        CreateServiceContract(ServiceContractHeader, ServiceItem);

        // Use Random because value is not important.
        CreateDiscountServiceContract(
          ServiceContractHeader, ServiceItem."Service Item Group Code", Resource."Resource Group No.",
          LineDiscountPercentage + LibraryRandom.RandInt(10));
        SignServContractDoc.SignContract(ServiceContractHeader);

        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceContractHeader."Contract No.", Resource."No.");
        UpdateAndPostServiceLine(TempServiceLine, ServiceLine."Line Discount Type"::"Contract Disc.", ServiceHeader."No.");

        // 3. Verify: The Service Order is deleted. Check Service Shipment. Check Service Ledger Entry, Customer Ledger Entries,
        // Detailed Customer Ledger Entries, Resource Leger Entry, VAT Entry and GL entries are created correctly for the posted Invoice.
        VerifyServiceOrderPost(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure ItemLineDiscountGreatest()
    var
        Customer: Record Customer;
        Item: Record Item;
        Resource: Record Resource;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LibraryUtility: Codeunit "Library - Utility";
        SignServContractDoc: Codeunit SignServContractDoc;
        ContractDiscountPercentage: Decimal;
    begin
        // Covers document number TC-RSM-D-6 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created correctly when the service order is posted with discounts, of which the
        // Line Discount has the greatest value. Verify that discounts are correctly registered on the posted service invoice.

        // 1. Setup: Create Resource. Create Resource Group, Assign it to the Resource.
        // Set Line Discount Greatest.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        AssignResourceGroupToResource(Resource);
        ContractDiscountPercentage := LibraryUtility.GenerateRandomFraction();

        // 2. Exercise: Create Item, Create Service Item. Create a new Contract with Contract/Service Discounts,
        // Sign the Contract. Create Service Order. Update Service Line and post the Service Order as Ship and Invoice.

        // Use Random because value is not important.
        CreateItem(Item, Customer."No.", ContractDiscountPercentage + LibraryRandom.RandInt(10));
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.", ContractDiscountPercentage);

        CreateServiceContract(ServiceContractHeader, ServiceItem);
        CreateDiscountServiceContract(
          ServiceContractHeader, ServiceItem."Service Item Group Code", Resource."Resource Group No.", ContractDiscountPercentage);
        SignServContractDoc.SignContract(ServiceContractHeader);

        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceContractHeader."Contract No.", Resource."No.");
        UpdateAndPostServiceLine(TempServiceLine, ServiceLine."Line Discount Type"::"Line Disc.", ServiceHeader."No.");

        // 3. Verify: The Service Order is deleted. Check Service Shipment. Check Service Ledger Entry, Customer Ledger Entries,
        // Detailed Customer Ledger Entries, Resource Leger Entry, VAT Entry and GL entries are created correctly for the posted Invoice.
        VerifyServiceOrderPost(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure WarrantyDiscountGreatest()
    var
        Customer: Record Customer;
        Item: Record Item;
        Resource: Record Resource;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LibraryUtility: Codeunit "Library - Utility";
        SignServContractDoc: Codeunit SignServContractDoc;
        LineDiscountPercentage: Decimal;
    begin
        // Covers document number TC-RSM-D-7 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created correctly when the service order is posted with discounts, of which the
        // Warranty Discount has the greatest value. Verify that discounts are correctly registered on the posted service invoice.

        // 1. Setup: Create Resource. Create Resource Group, Assign it to the Resource.
        // Set Warranty Discount Greatest.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        AssignResourceGroupToResource(Resource);
        LineDiscountPercentage := LibraryUtility.GenerateRandomFraction();

        // 2. Exercise: Create Item, Create Service Item. Create a new Contract with Contract/Service Discounts,
        // Sign the Contract. Create Service Order. Update Service Line and post the Service Order as Ship and Invoice.
        CreateItem(Item, Customer."No.", LineDiscountPercentage);

        // Use Random because value is not important.
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.", LineDiscountPercentage + LibraryRandom.RandInt(10));

        CreateServiceContract(ServiceContractHeader, ServiceItem);
        CreateDiscountServiceContract(
          ServiceContractHeader, ServiceItem."Service Item Group Code", Resource."Resource Group No.", LineDiscountPercentage);
        SignServContractDoc.SignContract(ServiceContractHeader);

        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceContractHeader."Contract No.", Resource."No.");
        UpdateAndPostServiceLine(TempServiceLine, ServiceLine."Line Discount Type"::"Warranty Disc.", ServiceHeader."No.");

        // 3. Verify: The Service Order is deleted. Check Service Shipment. Check Service Ledger Entry, Customer Ledger Entries,
        // Detailed Customer Ledger Entries, Resource Leger Entry, VAT Entry and GL entries are created correctly for the posted Invoice.
        VerifyServiceOrderPost(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure LineDiscountGreatestManual()
    var
        Customer: Record Customer;
        Item: Record Item;
        Resource: Record Resource;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LibraryUtility: Codeunit "Library - Utility";
        SignServContractDoc: Codeunit SignServContractDoc;
        LineDiscountPercentage: Decimal;
        ContractDiscountPercentage: Decimal;
    begin
        // Covers document number TC-RSM-D-8 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created correctly when the service order is posted with discounts, of which the
        // Line Discount has the greatest value with manual modification on Line Discount field.
        // Verify that the discounts are correctly registered on the posted service invoice.

        // 1. Setup: Create Resource. Create Resource Group, Assign it to the Resource.
        // Set Line Discount Greatest.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        AssignResourceGroupToResource(Resource);
        ContractDiscountPercentage := LibraryUtility.GenerateRandomFraction();
        LineDiscountPercentage := ContractDiscountPercentage + LibraryRandom.RandInt(10);  // Use Random for Discounts because value is not important.

        // 2. Exercise: Create Item, Create Service Item. Create a new Contract with Contract/Service Discounts, Sign the Contract.
        // Create Service Order.Update Service Line with manual Line Discount and post the Service Order as Ship and Invoice.
        CreateItem(Item, Customer."No.", LineDiscountPercentage);
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.", ContractDiscountPercentage);

        CreateServiceContract(ServiceContractHeader, ServiceItem);
        CreateDiscountServiceContract(
          ServiceContractHeader, ServiceItem."Service Item Group Code", Resource."Resource Group No.", LineDiscountPercentage);
        SignServContractDoc.SignContract(ServiceContractHeader);

        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceContractHeader."Contract No.", Resource."No.");
        UpdateServiceLine(ServiceHeader."No.", ServiceLine."Line Discount Type"::"Line Disc.");
        LineDiscountPercentage += LibraryRandom.RandInt(10);
        UpdateManualLineDiscount(ServiceHeader."No.", LineDiscountPercentage);

        GetServiceLines(ServiceLine, ServiceHeader."No.");
        CopyServiceLines(ServiceLine, TempServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Manual discount on Posted Invoice. The Service Order is deleted. Check Service Shipment.
        // Check Service Ledger Entry, Customer Ledger Entries, Detailed Customer Ledger Entries, Resource Leger Entry,
        // VAT Entry and GL entries are created correctly for the posted Invoice.
        VerifyManualLineDiscount(ServiceHeader."No.", LineDiscountPercentage);
        VerifyServiceOrderPost(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceItemReplacementHandler')]
    [Scope('OnPrem')]
    procedure WarrantyDiscountGreatestManual()
    var
        Customer: Record Customer;
        Item: Record Item;
        Resource: Record Resource;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        LibraryUtility: Codeunit "Library - Utility";
        SignServContractDoc: Codeunit SignServContractDoc;
        WarrantyDiscount: Decimal;
        LineDiscountPercentage: Decimal;
    begin
        // Covers document number TC-RSM-D-9 - refer to TFS ID 20925.
        // Test that the relevant ledger entries are created correctly when the service order is posted with discounts, of which the
        // Warranty Discount has the greatest value with manual modification on Line Discount field.
        // Verify that the discounts are correctly registered on the posted service invoice.

        // 1. Setup: Create Resource. Create Resource Group, Assign it to the Resource.
        // Set Warranty Discount Greatest.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        AssignResourceGroupToResource(Resource);
        LineDiscountPercentage := LibraryUtility.GenerateRandomFraction();
        WarrantyDiscount := LineDiscountPercentage + LibraryRandom.RandInt(10);  // Use Random for Discounts because value is not important.

        // 2. Exercise: Create Item, Create Service Item. Create a new Contract with Contract/Service Discounts, Sign the Contract.
        // Create Service Order.Update Service Line with manual Line Discount and post the Service Order as Ship and Invoice.
        CreateItem(Item, Customer."No.", LineDiscountPercentage);
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.", WarrantyDiscount);

        CreateServiceContract(ServiceContractHeader, ServiceItem);
        CreateDiscountServiceContract(
          ServiceContractHeader, ServiceItem."Service Item Group Code", Resource."Resource Group No.", LineDiscountPercentage);
        SignServContractDoc.SignContract(ServiceContractHeader);

        CreateServiceOrder(ServiceHeader, ServiceItem, ServiceContractHeader."Contract No.", Resource."No.");
        UpdateServiceLine(ServiceHeader."No.", ServiceLine."Line Discount Type"::"Warranty Disc.");
        WarrantyDiscount += LibraryRandom.RandInt(10);
        UpdateManualLineDiscount(ServiceHeader."No.", WarrantyDiscount);

        GetServiceLines(ServiceLine, ServiceHeader."No.");
        CopyServiceLines(ServiceLine, TempServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Manual discount on Posted Invoice. The Service Order is deleted. Check Service Shipment.
        // Check Service Ledger Entry, Customer Ledger Entries, Detailed Customer Ledger Entries, Resource Leger Entry,
        // VAT Entry and GL entries are created correctly for the posted Invoice.
        VerifyManualLineDiscount(ServiceHeader."No.", WarrantyDiscount);
        VerifyServiceOrderPost(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestContractChangeStatusOpenWhenChangeServiceDiscount()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceItem: Record "Service Item";
        ContractServiceDiscount: array[2] of Record "Contract/Service Discount";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        SignServContractDoc: Codeunit SignServContractDoc;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Service Contract]
        // [SCENARIO 293249] Service Discount can be created or changed only when Service Contract "Change Status" is Open.
        Initialize();

        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        CreateServiceContract(ServiceContractHeader, ServiceItem);

        CreateModifyServiceDiscount(ServiceContractHeader, ContractServiceDiscount[1], ServiceItem."Service Item Group Code");

        SignServContractDoc.SignContract(ServiceContractHeader);
        LockOpenServContract.LockServContract(ServiceContractHeader);
        Commit();

        asserterror LibraryService.CreateContractServiceDiscount(
            ContractServiceDiscount[2], ServiceContractHeader,
            ContractServiceDiscount[2].Type::"Service Item Group", ServiceItem."Service Item Group Code");

        Assert.ExpectedTestFieldError(ServiceContractHeader.FieldCaption("Change Status"), Format(ServiceContractHeader."Change Status"::Open));

        ContractServiceDiscount[1].Validate("Discount %", LibraryRandom.RandDec(10, 2));
        asserterror ContractServiceDiscount[1].Modify(true);
        Assert.ExpectedTestFieldError(ServiceContractHeader.FieldCaption("Change Status"), Format(ServiceContractHeader."Change Status"::Open));

        asserterror ContractServiceDiscount[1].Delete(true);
        Assert.ExpectedTestFieldError(ServiceContractHeader.FieldCaption("Change Status"), Format(ServiceContractHeader."Change Status"::Open));

        ServiceContractHeader.Find();
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ContractServiceDiscount[1].Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ServiceLineDiscountIsUpdatedOnValidateServiceItemLine()
    var
        Customer: Record Customer;
        ItemOnServiceItemLine: Record Item;
        ItemOnServiceLine: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Warranty] [Service Line]
        // [SCENARIO 424215] "Line Discount %" on service line is updated when you set "Warranty %" on service item and validate Service Item No. on service item line.
        Initialize();

        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Items "A", "B".
        CreateItem(ItemOnServiceItemLine, Customer."No.", 0);
        CreateItem(ItemOnServiceLine, Customer."No.", 0);

        // [GIVEN] Service item for item "A", "Warranty %" = 0 so far.
        CreateServiceItem(ServiceItem, Customer."No.", ItemOnServiceItemLine."No.", 0);

        // [GIVEN] Service order, create service line with item "B".
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Item, ItemOnServiceLine."No.");

        // [GIVEN] Set "Warranty %" = 100 on the service item.
        ServiceItem.Validate("Warranty % (Parts)", 100);
        ServiceItem.Modify(true);

        // [WHEN] Revalidate Service Item No. on the service item line.
        ServiceItemLine.Validate("Service Item No.", ServiceItem."No.");

        // [THEN] "Line Discount %" is updated to 100 on the service line.
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("No.", ItemOnServiceLine."No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Line Discount %", 100);
    end;

    local procedure AssignResourceGroupToResource(var Resource: Record Resource)
    var
        ResourceGroup: Record "Resource Group";
    begin
        // Create Resource Group, Resource and assign Resource Group to the Resource.
        LibraryResource.CreateResourceGroup(ResourceGroup);
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Resource Group No.", ResourceGroup."No.");
        Resource.Modify(true);
    end;

    local procedure CalculateTotalAmountOnInvoice(OrderNo: Code[20]) TotalAmount: Decimal
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindSet();
        repeat
            TotalAmount += ServiceInvoiceLine."Amount Including VAT";
        until ServiceInvoiceLine.Next() = 0;
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

    local procedure CreateDiscountServiceContract(ServiceContractHeader: Record "Service Contract Header"; ServiceItemGroupCode: Code[20]; ResourceGroupNo: Code[20]; ContractDiscountPercentage: Decimal)
    var
        ContractServiceDiscount: Record "Contract/Service Discount";
        ServiceCost: Record "Service Cost";
    begin
        DiscountServiceContract(
          ServiceContractHeader, ContractServiceDiscount.Type::"Service Item Group", ServiceItemGroupCode,
          ContractDiscountPercentage);
        DiscountServiceContract(
          ServiceContractHeader, ContractServiceDiscount.Type::"Resource Group", ResourceGroupNo, ContractDiscountPercentage);
        ServiceCost.FindFirst();
        DiscountServiceContract(
          ServiceContractHeader, ContractServiceDiscount.Type::Cost, ServiceCost.Code, ContractDiscountPercentage);
    end;

    local procedure CreateItem(var Item: Record Item; CustomerNo: Code[20]; LineDiscount: Decimal)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));  // Use Random because value is not important.
        Item.Modify(true);
        UpdateItemDiscount(Item, CustomerNo, LineDiscount);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; ServiceItem: Record "Service Item")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Create Service Contract, Define Service Discounts. Sign the Contract.
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10) * 2);  // Multiplying by 2 as minimum value should be 2.
        ServiceContractLine.Modify(true);

        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20]; WarrantyDiscountPercentage: Decimal)
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        // Create Service Item and Define the Warranty Discounts.
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItem.Validate("Warranty % (Parts)", WarrantyDiscountPercentage);
        ServiceItem.Validate("Warranty % (Labor)", WarrantyDiscountPercentage + 1);
        ServiceItem.Validate("Warranty Starting Date (Labor)", WorkDate());
        ServiceItem.Validate("Warranty Starting Date (Parts)", WorkDate());
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item"; ContractNo: Code[20]; ResourceNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Create Service Order with Contract No.- Service Header, Service Item Line, Service Line of Type Item and Resource.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        ServiceHeader.Validate("Contract No.", ContractNo);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Item, ServiceItem."Item No.");
        CreateServiceLine(ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
    end;

    local procedure CreateModifyServiceDiscount(ServiceContractHeader: Record "Service Contract Header"; var ContractServiceDiscount: Record "Contract/Service Discount"; ServiceItemGroupCode: Code[10])
    begin
        LibraryService.CreateContractServiceDiscount(
            ContractServiceDiscount, ServiceContractHeader,
            ContractServiceDiscount.Type::"Service Item Group", ServiceItemGroupCode);

        ContractServiceDiscount.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ContractServiceDiscount.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ContractServiceDiscount.FindFirst();
        ContractServiceDiscount.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        ContractServiceDiscount.Modify(true);
    end;

    local procedure DiscountServiceContract(ServiceContractHeader: Record "Service Contract Header"; Type: Enum "Service Contract Discount Type"; No: Code[20]; ContractDiscountPercentage: Decimal)
    var
        ContractServiceDiscount: Record "Contract/Service Discount";
    begin
        LibraryService.CreateContractServiceDiscount(ContractServiceDiscount, ServiceContractHeader, Type, No);
        ContractServiceDiscount.Validate("Discount %", ContractDiscountPercentage);
        ContractServiceDiscount.Modify(true);
    end;

    local procedure GetServiceLines(var ServiceLine: Record "Service Line"; OrderNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", OrderNo);
        ServiceLine.FindSet();
    end;

    local procedure UpdateAndPostServiceLine(var TempServiceLine: Record "Service Line" temporary; LineDiscountType: Enum "Service Line Discount Type"; OrderNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Update Service Line. Save the Service Lines in temporary table and post the Service Order as Ship and Invoice.
        UpdateServiceLine(OrderNo, LineDiscountType);
        GetServiceLines(ServiceLine, OrderNo);
        CopyServiceLines(ServiceLine, TempServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, OrderNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure UpdateItemDiscount(var Item: Record Item; CustomerNo: Code[20]; LineDiscountPercentage: Decimal)
    var
        SalesLineDiscount: Record "Sales Line Discount";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer, CustomerNo, WorkDate(), '',
          '', Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        SalesLineDiscount.Validate("Line Discount %", LineDiscountPercentage);
        SalesLineDiscount.Modify(true);
    end;

    local procedure UpdateManualLineDiscount(OrderNo: Code[20]; LineDiscountPercentage: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLines(ServiceLine, OrderNo);
        repeat
            ServiceLine.Validate("Line Discount %", LineDiscountPercentage);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateServiceLine(OrderNo: Code[20]; LineDiscountType: Enum "Service Line Discount Type")
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLines(ServiceLine, OrderNo);
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
            ServiceLine.Validate("No.", ServiceLine."No.");
            ServiceLine.Validate("Line Discount Type", LineDiscountType);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateWarrantyServiceLine(OrderNo: Code[20]; ExcludeWarranty: Boolean; ExcludeContractDiscount: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLines(ServiceLine, OrderNo);
        repeat
            ServiceLine.Validate("Exclude Warranty", ExcludeWarranty);
            ServiceLine.Validate("Exclude Contract Discount", ExcludeContractDiscount);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyDetailedCustLedgerEntry(DocumentNo: Code[20]; TotalAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Invoice);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, TotalAmount);
    end;

    local procedure VerifyGLEntry(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Source Type", GLEntry."Source Type"::Customer);
            GLEntry.TestField("Source No.", ServiceInvoiceHeader."Bill-to Customer No.");
            GLEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyManualLineDiscount(OrderNo: Code[20]; LineDiscountPercentage: Decimal)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindSet();
        repeat
            ServiceInvoiceLine.TestField("Line Discount %", LineDiscountPercentage);
        until ServiceInvoiceLine.Next() = 0;
    end;

    local procedure VerifyResourceEntryInvoice(OrderNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Resource);
        ServiceInvoiceLine.FindFirst();
        ResLedgerEntry.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Quantity, -ServiceInvoiceLine.Quantity);
        ResLedgerEntry.TestField("Order Type", ResLedgerEntry."Order Type"::Service);
        ResLedgerEntry.TestField("Order No.", ServiceInvoiceHeader."Order No.");
        ResLedgerEntry.TestField("Order Line No.", ServiceInvoiceLine."Line No.");
    end;

    local procedure VerifyServiceInvoice(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        // Verify that the values of the fields Type and No. of Service Invoice Line are equal to the value of the
        // field Type and No. of the relevant Service Line.
        TempServiceLine.FindSet();
        ServiceInvoiceHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        repeat
            ServiceInvoiceLine.Get(ServiceInvoiceHeader."No.", TempServiceLine."Line No.");
            ServiceInvoiceLine.TestField(Type, TempServiceLine.Type);
            ServiceInvoiceLine.TestField("No.", TempServiceLine."No.");
            ServiceInvoiceLine.TestField("Line Discount %", TempServiceLine."Line Discount %");
            ServiceInvoiceLine.TestField("Warranty Disc. %", TempServiceLine."Warranty Disc. %");
            ServiceInvoiceLine.TestField("Contract Disc. %", TempServiceLine."Contract Disc. %");
            ServiceInvoiceLine.TestField("Line Discount Type", TempServiceLine."Line Discount Type");
            ServiceInvoiceLine.TestField("Line Discount Amount", TempServiceLine."Line Discount Amount");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Invoice);
        ServiceLedgerEntry.SetRange("Document No.", DocumentNo);
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField("Customer No.", CustomerNo);
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyServiceOrderPost(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
    begin
        Assert.IsFalse(
          ServiceHeader.Get(ServiceHeader."Document Type"::Order, TempServiceLine."Document No."),
          StrSubstNo(
            ServiceOrderMustNotExist, ServiceHeader.TableCaption(), ServiceHeader.FieldCaption("Document Type"),
            ServiceHeader."Document Type"::Order, ServiceHeader.FieldCaption("No."), TempServiceLine."Document No."));

        VerifyServiceInvoice(TempServiceLine);
        VerifyServiceShipment(TempServiceLine);
        VerifyResourceEntryInvoice(TempServiceLine."Document No.");
        VerifyGLEntry(TempServiceLine."Document No.");

        ServiceInvoiceHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        VerifyServiceLedgerEntry(ServiceInvoiceHeader."No.", TempServiceLine."Customer No.");
        VerifyCustomerLedgerEntry(ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Posting Date");
        VerifyDetailedCustLedgerEntry(ServiceInvoiceHeader."No.", CalculateTotalAmountOnInvoice(TempServiceLine."Document No."));
        VerifyVATEntry(ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Posting Date");
    end;

    local procedure VerifyServiceShipment(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Verify that the values of the fields Type and No. of Service Shipment Line are equal to the value of the
        // field Type and No. of the relevant Service Line.
        TempServiceLine.FindSet();
        ServiceShipmentLine.SetRange("Order No.", TempServiceLine."Document No.");
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", TempServiceLine."Line No.");
            ServiceShipmentLine.FindFirst();
            ServiceShipmentLine.TestField(Type, TempServiceLine.Type);
            ServiceShipmentLine.TestField("No.", TempServiceLine."No.");
            ServiceShipmentLine.TestField("Line Discount %", TempServiceLine."Line Discount %");
            ServiceShipmentLine.TestField("Line Discount Type", TempServiceLine."Line Discount Type");
            ServiceShipmentLine.TestField("Warranty Disc. %", TempServiceLine."Warranty Disc. %");
            ServiceShipmentLine.TestField("Contract Disc. %", TempServiceLine."Contract Disc. %");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Posting Date", PostingDate);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageTest: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ServiceContractConfirmation);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemReplacementHandler(var ServiceItemReplacement: Page "Service Item Replacement"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;
}

