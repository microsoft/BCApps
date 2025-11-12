// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using System.TestLibraries.Utilities;

codeunit 136135 "Service Order Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [Service] [UI]
        IsInitialized := false;
    end;

    var
        ServiceLine2: Record "Service Line";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        IsInitialized: Boolean;
        ItemNo2: Code[20];
        GlobalItemNo: Code[20];
        ExtendedText2: Text[50];
        Comment: Text[80];
        CopyComponentsFrom: Option "None","Item BOM","Old Service Item","Old Service Item w/o Serial No.";
        Replacement: Option "Temporary",Permanent;
        CombineShipmentMsg: Label 'The shipments are now combined';
        CombineShipmentErr: Label 'Incorrect Service Invoice Line Type';
        PostedServiceShipmentCaption: Label 'Posted Service Shipment';
        NothingToCombineShipmentMsg: Label 'There is nothing to combine.';
        NoOfLinesError: Label 'Total No. of lines must be %1 in %2.';
        ExtendedTextError: Label 'Extended Text must be %1.';
        ExistanceError: Label '%1 for %2 %3: %4 must not exist.';
        ExpectedDate: Date;
        GlobalQuantity: Decimal;
        LocationChangedMsg: Label 'Item %1 with serial number %2 is stored on location %3. The Location Code field on the service line will be updated.', Comment = '%1 = Item No., %2 = Item serial No., %3 = Location code';
        NotExistingSalesDocNoValueErr: Label 'The field Sales/Serv. Shpt. Document No. of table Service Item contains a value (%1) that cannot be found in the related table (Sales Shipment Line).';
        NotExistingServDocNoValueErr: Label 'The field Sales/Serv. Shpt. Document No. of table Service Item contains a value (%1) that cannot be found in the related table (Service Shipment Line).';
        NotExistingSalesLineNoValueErr: Label 'The field Sales/Serv. Shpt. Line No. of table Service Item contains a value (%1) that cannot be found in the related table (Sales Shipment Line).';
        NotExistingServLineNoValueErr: Label 'The field Sales/Serv. Shpt. Line No. of table Service Item contains a value (%1) that cannot be found in the related table (Service Shipment Line).';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Order Management");
        Clear(ExpectedDate);
        GlobalItemNo := '';
        GlobalQuantity := 0;
        InitVariables();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Order Management");

        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryTemplates.EnableTemplatesFeature();

        LibraryERMCountryData.UpdateAccountInServiceCosts();
        LibraryService.SetupServiceMgtNoSeries();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Order Management");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemJournalWithItemTracking()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
    begin
        // Test Item Ledger Entry after Posting Item Journal with Serial No.

        // 1. Setup: Create Item with Item Tracking code and create Item Journal Line for the Item.
        Initialize();
        CreateItemJournalLine(ItemJournalLine, CreateItemWithItemTrackingCode());

        // 2. Exercise: Assign Serial No. on Item Journal Line and post it.
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalLine."Journal Batch Name");
        ItemJournal.ItemTrackingLines.Invoke();
        ItemJournal.Post.Invoke();

        // 3. Verify: Verify No. of Item Ledger Entry is the Quantity on Item Journal Line.
        VerifyItemLedgerEntry(ItemJournalLine."Item No.", ItemJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateListHandler')]
    [Scope('OnPrem')]
    procedure CustomerCreationFromOrder()
    var
        Customer: Record Customer;
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
    begin
        // Test Customer Creation from Service Order.

        // 1. Setup: Create Service Order with Name, Address, City and Post Code.
        Initialize();
        ServiceOrderNo := CreateHeaderWithNameAndAddress();

        // 2. Exercise: Create Customer from Service Order.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder."Create Customer".Invoke();

        // 3. Verify: Verify Customer created from Service Order.
        Customer.Get(ServiceOrder."Customer No.".Value);
        Customer.TestField(Name, ServiceOrder.Name.Value);
        Customer.TestField(Address, ServiceOrder.Address.Value);
        Customer.TestField(City, ServiceOrder.City.Value);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateListHandler')]
    [Scope('OnPrem')]
    procedure S463463_CustomerCreationFromOrderWithNoSeries()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
        DoCleanCustomerTemplateNoSeries: Boolean;
    begin
        // [FEATURE] [Service Order] [Create Customer] [Customer Template]
        // [SCENARIO 463463] Test Customer Creation from Service Order using Customer Tempalte with No. Series.
        Initialize();

        // [GIVEN] Update No. Series to Customer Template.
        CustomerTempl.FindFirst();
        if CustomerTempl."No. Series" = '' then begin
            LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
            LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
            CustomerTempl.Validate("No. Series", NoSeries.Code);
            CustomerTempl.Modify(true);
            DoCleanCustomerTemplateNoSeries := true;
        end;

        // [GIVEN] Create Service Order with Name, Address, City and Post Code.
        ServiceOrderNo := CreateHeaderWithNameAndAddress();

        // [WHEN] Create Customer from Service Order.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder."Create Customer".Invoke();

        // [THEN] Verify Customer created from Service Order.
        Customer.Get(ServiceOrder."Customer No.".Value);
        Customer.TestField(Name, ServiceOrder.Name.Value);
        Customer.TestField(Address, ServiceOrder.Address.Value);
        Customer.TestField(City, ServiceOrder.City.Value);

        // [THEN] Verify Customer "No. Series" was created using Customer Template "No. Series".
        Customer.TestField("No. Series", CustomerTempl."No. Series");

        // Cleanup
        if DoCleanCustomerTemplateNoSeries then begin
            CustomerTempl.Validate("No. Series", '');
            CustomerTempl.Modify(true);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemCreationFromOrder()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceOrderNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // Test Service Item Creation from Service Order.

        // 1. Setup: Create Service Header.
        Initialize();
        LibraryInventory.CreateItem(Item);
        ServiceOrderNo := LibraryService.CreateServiceOrderHeaderUsingPage();

        // 2. Exercise: Create Service Item Line with Item and Create Service Item from it.
        ServiceItemNo := CreateServiceItemLineWithItem(ServiceOrderNo, Item."No.");

        // 3. Verify: Verify Service Item created from Service Order.
        ServiceItem.Get(ServiceItemNo);
        ServiceItem.TestField("Item No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('StartingFeePageHandler')]
    [Scope('OnPrem')]
    procedure StartingFeeOnServiceWorksheet()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceCost: Record "Service Cost";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
        ServiceOrderStartingFee: Code[10];
    begin
        // Test Service Line after running Insert Starting Fee function on Service Item Worksheet.

        // 1. Setup: Create Service Cost, update Service Order Starting Fee on Service Management Setup, Customer, Service Item,
        // Service Header and Service Item Line.
        Initialize();
        CreateServiceCost(ServiceCost, '');
        ServiceOrderStartingFee := UpdateServiceOrderStartingFee(ServiceCost.Code);
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceOrderNo := CreateServiceOrder(ServiceItem);

        // 2. Exercise: Open Service Item worksheet and run insert Starting Fee function.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();

        // 3. Verify: Verify Service Line for Type Cost.
        VerifyCostOnServiceLine(ServiceLine2, ServiceCost);

        // 4. Teardown: Rollback Service Order Starting Fee on Service Management Setup to default value.
        UpdateServiceOrderStartingFee(ServiceOrderStartingFee);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToCustomerWhenReenteringSameCustomerNo()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 542320] Bill-to customer should stay the same when re-entering the same Customer No.
        Initialize();

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Create Ship-to Address for Customer "C" and assigne as default "Ship-to Address"        
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" = '' then begin
            ShipToAddress.Validate("Shipment Method Code", CreateShipmentMethod());
            ShipToAddress.Modify(true);
        end;

        // [GIVEN] Set "C_SA" as default "Ship-to Address" for Customer "C".
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [GIVEN] Create Service Order
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.TestField("Bill-to Customer No.", CustomerBillTo."No.");
        ServiceHeader.TestField("Ship-to Code", ShipToAddress.Code);

        // [WHEN] reenter the same Customer No.
        ServiceHeader.Validate("Customer No.", Customer."No.");

        // [THEN] Bill-to customer should stay the same
        ServiceHeader.TestField("Bill-to Customer No.", CustomerBillTo."No.");
        ServiceHeader.TestField("Ship-to Code", ShipToAddress.Code);
    end;

    [Test]
    [HandlerFunctions('TravelFeePageHandler')]
    [Scope('OnPrem')]
    procedure TravelFeeOnServiceWorksheet()
    var
        ServiceCost: Record "Service Cost";
        ServiceZone: Record "Service Zone";
        ServiceItem: Record "Service Item";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
        ServiceOrderStartingFee: Code[10];
    begin
        // Test Service Line after running Insert Travel Fee function on Service Item Worksheet.

        // 1. Setup: Create Service Zone, Service Cost, update Service Order Starting Fee on Service Management Setup, Customer,
        // Service Item, Service Header and Service Item Line.
        Initialize();
        LibraryService.CreateServiceZone(ServiceZone);
        CreateServiceCost(ServiceCost, ServiceZone.Code);
        ServiceOrderStartingFee := UpdateServiceOrderStartingFee(ServiceCost.Code);
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomerWithZoneCode(ServiceZone.Code));
        ServiceOrderNo := CreateServiceOrder(ServiceItem);

        // 2. Exercise: Open Service Item worksheet and run insert Travel Fee function.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();

        // 3. Verify: Verify Service Line for Type Cost.
        VerifyCostOnServiceLine(ServiceLine2, ServiceCost);

        // 4. Teardown: Rollback Service Order Starting Fee on Service Management Setup to default value.
        UpdateServiceOrderStartingFee(ServiceOrderStartingFee);
    end;

    [Test]
    [HandlerFunctions('ExtendedTextPageHandler')]
    [Scope('OnPrem')]
    procedure ExtendedTextOnServiceWorksheet()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ExtendedTextHeader: Record "Extended Text Header";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
        ExtendedText: Text[50];
    begin
        // Test Service Line after running Insert Extended Text function on Service Item Worksheet.

        // 1. Setup: Create Item with Extended Text, Service Item, Service Header and Service Item Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateExtendedTextForItem(ExtendedTextHeader, Item."No.");
        ExtendedText := CreateExtendedTextLine(ExtendedTextHeader);
        ItemNo2 := Item."No.";  // Assign global variable for page handler.
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        ServiceOrderNo := CreateServiceOrder(ServiceItem);

        // 2. Exercise: Open Service Item worksheet, create line for Item and run insert Extended Text function.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();

        // 3. Verify: Verify Extended Text on Service Item worksheet.
        Assert.AreEqual(ExtendedText, ExtendedText2, StrSubstNo(ExtendedTextError, ExtendedText));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ReplacementWorksheetHandler,ItemReplacementPageHandler,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure ItemReplacementWithOldItem()
    var
        ServiceItem: Record "Service Item";
    begin
        // Test Service Item and Service Item Components after posting Service Order with Old Service Item selection as Copy Components
        // from on Service Item Replacement page.

        ReplacementWithServiceItem(
          CopyComponentsFrom::"Old Service Item", Replacement::"Temporary", ServiceItem.Status::"Temporarily Installed");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ReplacementWorksheetHandler,ItemReplacementPageHandler,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure ItemReplacementWithPermanent()
    var
        ServiceItem: Record "Service Item";
    begin
        // Test Service Item and Service Item Components after posting Service Order with Old Service Item w/o Serial No. selection as
        // Copy Components from on Service Item Replacement page.

        ReplacementWithServiceItem(
          CopyComponentsFrom::"Old Service Item w/o Serial No.", Replacement::Permanent, ServiceItem.Status::Installed);
    end;

    local procedure ReplacementWithServiceItem(CopyComponentsFrom2: Option; Replacement2: Option; Status: Enum "Service Item Status")
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // 1. Setup: Update Stockout Warning to False on Sales & Receivables Setup, create Item, Service Header, Service Item Line
        // with Item, create Service Item from it and Service Item Component.
        Initialize();
        SalesReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        LibraryInventory.CreateItem(Item);
        ServiceOrderNo := LibraryService.CreateServiceOrderHeaderUsingPage();

        // Assign global variables for page handlers.
        ItemNo2 := Item."No.";
        CopyComponentsFrom := CopyComponentsFrom2;
        Replacement := Replacement2;

        ServiceItemNo := CreateServiceItemLineWithItem(ServiceOrderNo, Item."No.");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItemComponent(ServiceItemComponent, ServiceItemNo, ServiceItemComponent.Type::Item, Item."No.");

        // 2. Exercise: Open Service Item worksheet, select Copy Components as per parameter on Service Item Replacement page and
        // post the Order.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
        ServiceOrder.Post.Invoke();

        // 3. Verify: Verify created Service Item and its components.
        FindServiceItem(ServiceItem, ServiceOrderNo);
        ServiceItem.TestField("Serial No.", ItemNo2);
        ServiceItem.TestField(Status, Status);

        VerifyServiceItemComponent(ServiceItem."No.", ServiceItemComponent."No.", ServiceItemComponent.Type);

        // 4. Teardown: Rollback Stockout Warning to default value on Sales & Receivables Setup.
        LibrarySales.SetStockoutWarning(SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ReplacementWorksheetHandler,ItemReplacementPageHandler,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure ItemReplacementWithItemBOM()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
        ServiceItemNo: Code[20];
        QuantityPer: Integer;
    begin
        // Test Service Item and Service Item Components after posting Service Order with Item BOM selection as Copy Components
        // from on Service Item Replacement page.

        // 1. Setup: Update Stockout Warning to False on Sales & Receivables Setup, create Item, BOM Component, Service Header, Service
        // Item Line with Item, create Service Item from it and Service Item Component.
        Initialize();
        SalesReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        LibraryInventory.CreateItem(Item);
        QuantityPer := CreateBOMComponent(Item."No.");
        ServiceOrderNo := LibraryService.CreateServiceOrderHeaderUsingPage();

        // Assign global variables for page handlers.
        ItemNo2 := Item."No.";
        CopyComponentsFrom := CopyComponentsFrom::"Item BOM";
        Replacement := Replacement::"Temporary";

        ServiceItemNo := CreateServiceItemLineWithItem(ServiceOrderNo, Item."No.");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItemComponent(ServiceItemComponent, ServiceItemNo, ServiceItemComponent.Type::Item, Item."No.");

        // 2. Exercise: Open Service Item worksheet, select Copy Components as Item BOM on Service Item Replacement page and post the
        // Order.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
        ServiceOrder.Post.Invoke();

        // 3. Verify: Verify created Service Item and its components.
        FindServiceItem(ServiceItem, ServiceOrderNo);
        ServiceItem.TestField("Serial No.", ItemNo2);
        ServiceItem.TestField(Status, ServiceItem.Status::"Temporarily Installed");

        ServiceItemComponent.SetRange("Parent Service Item No.", ServiceItem."No.");
        Assert.AreEqual(
          QuantityPer, ServiceItemComponent.Count, StrSubstNo(NoOfLinesError, QuantityPer, ServiceItemComponent.TableCaption()));

        // 4. Teardown: Rollback Stockout Warning to default value on Sales & Receivables Setup.
        LibrarySales.SetStockoutWarning(SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLineDeletion()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
    begin
        // Test Service Item Line on Service Order after deletion of Service Item Line.

        // 1. Setup: Create Service Item, Service Header and Service Item Line.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        ServiceOrderNo := CreateServiceOrder(ServiceItem);

        // 2. Exercise: Delete Service Item Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceOrderNo);
        ServiceItemLine.FindFirst();
        ServiceItemLine.Delete(true);

        // 3. Verify: Verify Service Item Line deleted from Service Order.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        Assert.AreEqual(
          '', ServiceOrder.ServItemLines.ServiceItemNo.Value,
          StrSubstNo(
            ExistanceError, ServiceItemLine.TableCaption(), ServiceItem.TableCaption(), ServiceItem.FieldCaption("No."), ServiceItem."No."));
    end;

    [Test]
    [HandlerFunctions('ServiceLinePageHandler,CommentSheetPageHandler,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithComment()
    var
        ServiceItem: Record "Service Item";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
    begin
        // Test Comment on Service Shipment Header after posting Service Order with comment.

        // 1. Setup: Update Stockout Warning to False on Sales & Receivables Setup, create Service Item, Service Header and Service Item
        // Line.
        Initialize();
        SalesReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        ServiceOrderNo := CreateServiceOrder(ServiceItem);

        // 2. Exercise: Create Comment for Service Order, open Service Item worksheet, create Line for Type Item and post the Order.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder."Co&mments".Invoke();
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
        ServiceOrder.Post.Invoke();

        // 3. Verify: Verify Comment on Service Shipment Header.
        VerifyCommentOnShipmentHeader(ServiceOrderNo, Comment);

        // 4. Teardown: Rollback Stockout Warning to default value on Sales & Receivables Setup.
        LibrarySales.SetStockoutWarning(SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [HandlerFunctions('ServiceLinePageHandler,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure PostedEntryOnNavigatePage()
    var
        ServiceItem: Record "Service Item";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
    begin
        // Test Posted Service Shipment on Navigate page created after posting Service Order.

        // 1. Setup: Update Stockout Warning to False on Sales & Receivables Setup, create Service Item, Service Header and Service Item
        // Line.
        Initialize();
        SalesReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        ServiceOrderNo := CreateServiceOrder(ServiceItem);

        // 2. Exercise: Open Service Item worksheet, create Line for Type Item and post the Order.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
        ServiceOrder.Post.Invoke();

        // 3. Verify: Verify Posted Service Shipment line on Navigate page.
        VerifyPostedShipmentEntry(ServiceOrderNo);

        // 4. Teardown: Rollback Stockout Warning to default value on Sales & Receivables Setup.
        LibrarySales.SetStockoutWarning(SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [HandlerFunctions('AvailableToPromisePageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPromiseOnServiceOrderPromising()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Check that Dates have no effect on the Order Promising page.

        // 1. Setup: Create Item, Service Order with Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateServiceLine(ServiceLine, Item."No.", '', LibraryRandom.RandInt(100));  // Blank value taken for Location Code.

        // 2. Exercise.
        ServiceLine.ShowOrderPromisingLine();
        ExpectedDate := ServiceLine."Needed by Date";  // Assign in global variable.

        // 3. Verify: Verify that date are same as in Service line. Verification done in 'AvailableToPromisePageHandler'
    end;

    [Test]
    [HandlerFunctions('CapableToPromisePageHandler')]
    [Scope('OnPrem')]
    procedure CapableToPromiseOnServiceOrderPromising()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Check that Dates on Order Promising page.

        // 1. Setup: Create Item, Service Order with Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateServiceLine(ServiceLine, Item."No.", '', LibraryRandom.RandInt(100));  // Blank value taken for Location Code.
        ExpectedDate := ServiceLine."Planned Delivery Date";  // Assign in global variable.

        // 2. Exercise.
        ServiceLine.ShowOrderPromisingLine();

        // 3. Verify: Verify that date are same as in Service line. Verification done in 'CapableToPromisePageHandler'.
    end;

    [Test]
    [HandlerFunctions('AcceptPageHandler')]
    [Scope('OnPrem')]
    procedure AcceptOnServiceOrderPromising()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Check that Dates are same on the Order Promising page as in Service Line's Needed by Date.

        // 1. Setup: Create Item, Service Order with Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateServiceLine(ServiceLine, Item."No.", '', LibraryRandom.RandInt(100));  // Blank value taken for Location Code.

        // 2. Exercise.
        ServiceLine.ShowOrderPromisingLine();
        ExpectedDate := ServiceLine."Needed by Date";  // Assign in global variable.

        // 3. Verify: Verify that date are same as in Service line. Verification done in 'AcceptPageHandler'.
    end;

    [Test]
    [HandlerFunctions('AvailableToPromisePageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPromiseOnServiceOrderPromisingWithPurchaseOrder()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // Check that Dates on the Order Promising page for Available To Promise with lesser Quantity on Job Service Line than Purchase Order.

        // 1. Setup: Create Item, Service Order with Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Location.FindFirst();
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        CreateServiceLine(
          ServiceLine, Item."No.", Location.Code, LibraryRandom.RandInt(100));
        ExpectedDate := PurchaseLine."Expected Receipt Date";  // Assign in global variable.

        // 2. Exercise.
        ServiceLine.ShowOrderPromisingLine();

        // 3. Verify: Verifyt dates on the Order Promising page. Verification done in 'AvailableToPromisePageHandler'
    end;

    [Test]
    [HandlerFunctions('AcceptPageHandler')]
    [Scope('OnPrem')]
    procedure AcceptOnServiceOrderPromisingWithPurchaseOrder()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // Check that Dates on the Order Promising page for Accept with lesser Quantity on Service Line than Purchase Order.

        // 1. Setup: Create Item, Service Order with Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Location.FindFirst();
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        CreateServiceLine(ServiceLine, Item."No.", Location.Code, LibraryRandom.RandInt(100));

        // 2. Exercise.
        ServiceLine.ShowOrderPromisingLine();
        ExpectedDate := PurchaseLine."Expected Receipt Date";  // Assign in global variable.

        // 3. Verify: Verify dates on the Order Promising page. Verification done in 'AcceptPageHandler'.
    end;

    [Test]
    [HandlerFunctions('AvailableToPromisePageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPromiseOnServiceOrderPromisingWithSupply()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // Check that Dates on the Order Promising page for Available To Promise with greater Quantity on Service Line than Purchase Order.

        // 1. Setup: Create Item, Service Order with Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Location.FindFirst();
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Quantity validated here because Purchase Line need lesser Quantity than Service Line.
        PurchaseLine.Modify(true);
        CreateServiceLine(ServiceLine, Item."No.", Location.Code, LibraryRandom.RandInt(100));

        // 2. Exercise.
        ServiceLine.ShowOrderPromisingLine();
        ExpectedDate := PurchaseLine."Expected Receipt Date";  // Assign in global variable.

        // 3. Verify: Verify dates on the Order Promising page. Verification done in 'AvailableToPromisePageHandler'
    end;

    [Test]
    [HandlerFunctions('AcceptPageHandler')]
    [Scope('OnPrem')]
    procedure AcceptOnServiceOrderPromisingWithSupply()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // Check that Dates on the Order Promising page for Accept with greater Quantity on Service Line than Purchase Order.

        // 1. Setup: Create Item, Service Order with Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Location.FindFirst();
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Quantity validated here because Purchase Line need lesser Quantity than Service Line.
        PurchaseLine.Modify(true);
        CreateServiceLine(ServiceLine, Item."No.", Location.Code, LibraryRandom.RandInt(100));

        // 2. Exercise.
        ServiceLine.ShowOrderPromisingLine();
        ExpectedDate := PurchaseLine."Expected Receipt Date";  // Assign in global variable.

        // 3. Verify: Verify that dates on the Order Promising page. Verification done in 'AcceptPageHandler'.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingUsingServiceOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify that there should not be Order Tracking Line with error.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::"Tracking & Action Msg."),
          LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        CreateServiceLine(ServiceLine, PurchaseLine."No.", '', PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        GlobalQuantity := ServiceLine.Quantity;
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Exercise.
        ServiceLine.ShowTracking();

        // Verify: Verification done in 'MessageHandler' and 'OrderTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationUsingServiceOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Reservation using Item with Order Tracking Policy as Tracking Only.

        // Setup: Create and Receive Purchase Order, CreateService Order.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::"Tracking Only"), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        CreateServiceLine(ServiceLine, PurchaseLine."No.", '', PurchaseLine.Quantity);
        GlobalQuantity := ServiceLine.Quantity;
        GlobalItemNo := ServiceLine."No.";
        Commit();
        // Exercise.
        ServiceLine.ShowReservation();

        // Verify: Verification done in 'ReservationPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemReplacementPageHandler2,MessageVerificationHandler')]
    [Scope('OnPrem')]
    procedure ChangeSerialNoInServiceLineItemOnAnotherLocation()
    var
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        Location: array[2] of Record Location;
        SerialNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Location]
        // [SCENARIO 380644] Location code should be updated in service line when selecting a serial no of an item stored on location different than the location of service line
        Initialize();

        // [GIVEN] Item "I" tracked by serial no with a linked service item "S"
        // [GIVEN] Item "I" is in stock on two locations. Item with serial no. "SN1" - on location "L1", "SN2" - on location "L2"
        // [GIVEN] Service order for service item "S" on location "L1"
        CreateServiceOrderWithTrackedReplacementComponentOnTwoLocations(ServiceLine, Location);

        ServiceItem.Get(ServiceLine."Service Item No.");
        SerialNo := GetSerialNoFromPostedEntry(ServiceItem."Item No.", Location[2].Code);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(StrSubstNo(LocationChangedMsg, ServiceItem."Item No.", SerialNo, Location[2].Code));

        // [WHEN] Setup replacement in the service order. Select serial no. "S2"
        SetItemNoInServiceLine(ServiceLine, ServiceItem."Item No.");

        // [THEN] Mesage "Location will be updated" is shown
        // [THEN] Location code in service line is "L2"
        ServiceLine.TestField("Location Code", Location[2].Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemReplacementPageHandler2')]
    [Scope('OnPrem')]
    procedure ChangeSerialNoInServiceLineItemOnSameLocation()
    var
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        Location: array[2] of Record Location;
        SerialNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Location]
        // [SCENARIO 380644] Location code should not be updated in service line when selecting a serial no of an item stored on the same location as the location of service line
        Initialize();

        // [GIVEN] Item "I" tracked by serial no with a linked service item "S"
        // [GIVEN] Item "I" is in stock on two locations. Item with serial no. "SN1" - on location "L1", "SN2" - on location "L2"
        // [GIVEN] Service order for service item "S" on location "L1"
        CreateServiceOrderWithTrackedReplacementComponentOnTwoLocations(ServiceLine, Location);

        ServiceItem.Get(ServiceLine."Service Item No.");
        SerialNo := GetSerialNoFromPostedEntry(ServiceItem."Item No.", Location[1].Code);
        LibraryVariableStorage.Enqueue(SerialNo);

        // [WHEN] Setup replacement in the service order. Select serial no. "S2"
        SetItemNoInServiceLine(ServiceLine, ServiceItem."Item No.");

        // [THEN] No mesage is shown
        // [THEN] Location code in service line is "L1"
        ServiceLine.TestField("Location Code", Location[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesServShptDocumentNoRelationSalesPositiveUT()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266214] ServiceItem."Sales/Serv. Shpt. Document No." has table relation to SalesShipmentLine."Document No."
        Initialize();

        CreateSalesShipmentLine(SalesShipmentLine);

        ServiceItem.Init();
        ServiceItem.Validate("Shipment Type", ServiceItem."Shipment Type"::Sales);
        ServiceItem.Validate("Sales/Serv. Shpt. Document No.", SalesShipmentLine."Document No.");
        ServiceItem.TestField("Sales/Serv. Shpt. Document No.", SalesShipmentLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesServShptDocumentNoRelationSalesNegativeUT()
    var
        ServiceItem: Record "Service Item";
        DocNo: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266214] Error appears when validate value ServiceItem."Sales/Serv. Shpt. Document No." not found in Sales Shipment Line
        Initialize();

        ServiceItem.Init();
        ServiceItem.Validate("Shipment Type", ServiceItem."Shipment Type"::Sales);
        DocNo := LibraryUtility.GenerateGUID();
        asserterror ServiceItem.Validate("Sales/Serv. Shpt. Document No.", DocNo);
        Assert.ExpectedError(StrSubstNo(NotExistingSalesDocNoValueErr, DocNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesServShptDocumentNoRelationServicePositiveUT()
    var
        ServiceItem: Record "Service Item";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266214] ServiceItem."Sales/Serv. Shpt. Document No." has table relation to ServiceShipmentLine."Document No."
        Initialize();

        CreateServiceShipmentLine(ServiceShipmentLine);

        ServiceItem.Init();
        ServiceItem.Validate("Shipment Type", ServiceItem."Shipment Type"::Service);
        ServiceItem.Validate("Sales/Serv. Shpt. Document No.", ServiceShipmentLine."Document No.");
        ServiceItem.TestField("Sales/Serv. Shpt. Document No.", ServiceShipmentLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesServShptDocumentNoRelationServiceNegativeUT()
    var
        ServiceItem: Record "Service Item";
        DocNo: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266214] Error appears when validate value ServiceItem."Sales/Serv. Shpt. Document No." not found in Service Shipment Line
        Initialize();

        ServiceItem.Init();
        ServiceItem.Validate("Shipment Type", ServiceItem."Shipment Type"::Service);
        DocNo := LibraryUtility.GenerateGUID();
        asserterror ServiceItem.Validate("Sales/Serv. Shpt. Document No.", DocNo);
        Assert.ExpectedError(StrSubstNo(NotExistingServDocNoValueErr, DocNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesServShptLineNoRelationSalesPositiveUT()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266214] ServiceItem."Sales/Serv. Shpt. Line No." has table relation to SalesShipmentLine."Line No."
        Initialize();

        CreateSalesShipmentLine(SalesShipmentLine);

        ServiceItem.Init();
        ServiceItem.Validate("Shipment Type", ServiceItem."Shipment Type"::Sales);
        ServiceItem.Validate("Sales/Serv. Shpt. Document No.", SalesShipmentLine."Document No.");
        ServiceItem.Validate("Sales/Serv. Shpt. Line No.", SalesShipmentLine."Line No.");
        ServiceItem.TestField("Sales/Serv. Shpt. Line No.", SalesShipmentLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesServShptLineNoRelationSalesNegativeUT()
    var
        ServiceItem: Record "Service Item";
        LineNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266214] Error appears when validate value ServiceItem."Sales/Serv. Shpt. Line No." not found in Sales Shipment Line
        Initialize();

        ServiceItem.Init();
        ServiceItem.Validate("Shipment Type", ServiceItem."Shipment Type"::Sales);
        LineNo := LibraryRandom.RandInt(1000);
        asserterror ServiceItem.Validate("Sales/Serv. Shpt. Line No.", LineNo);
        Assert.ExpectedError(StrSubstNo(NotExistingSalesLineNoValueErr, LineNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesServShptLineNoRelationServicePositiveUT()
    var
        ServiceItem: Record "Service Item";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266214] ServiceItem."Sales/Serv. Shpt. Line No." has table relation to ServiceShipmentLine."Line No."
        Initialize();

        CreateServiceShipmentLine(ServiceShipmentLine);

        ServiceItem.Init();
        ServiceItem.Validate("Shipment Type", ServiceItem."Shipment Type"::Service);
        ServiceItem.Validate("Sales/Serv. Shpt. Document No.", ServiceShipmentLine."Document No.");
        ServiceItem.Validate("Sales/Serv. Shpt. Line No.", ServiceShipmentLine."Line No.");
        ServiceItem.TestField("Sales/Serv. Shpt. Line No.", ServiceShipmentLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesServShptLineNoRelationServiceNegativeUT()
    var
        ServiceItem: Record "Service Item";
        LineNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266214] Error appears when validate value ServiceItem."Sales/Serv. Shpt. Line No." not found in Service Shipment Line
        Initialize();

        ServiceItem.Init();
        ServiceItem.Validate("Shipment Type", ServiceItem."Shipment Type"::Service);
        LineNo := LibraryRandom.RandInt(1000);
        asserterror ServiceItem.Validate("Sales/Serv. Shpt. Line No.", LineNo);
        Assert.ExpectedError(StrSubstNo(NotExistingServLineNoValueErr, LineNo));
    end;

    [Test]
    [HandlerFunctions('StartingFeePageHandler')]
    procedure VerifyUnitPriceOnServiceWorksheetLineWithServiceCostAndNewPricingExperience()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceCost: Record "Service Cost";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceOrderNo: Code[20];
        ServiceOrderStartingFee: Code[10];
    begin
        // [SCENARIO 484108] Verify Unit Price on Service Worksheet Line with Service Cost and New Pricing Experience
        Initialize();

        // [GIVEN] Enable New Sales Pricing Experience
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Create Service Cost with Unit Price
        CreateServiceCost(ServiceCost, '');
        ServiceCost.Validate("Default Unit Price", LibraryRandom.RandDec(10, 2));
        ServiceCost.Modify(true);

        // [GIVEN] Set Service Cost on Service Management Setup
        ServiceOrderStartingFee := UpdateServiceOrderStartingFee(ServiceCost.Code);

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");

        // [GIVEN] Create Service Order
        ServiceOrderNo := CreateServiceOrder(ServiceItem);

        // [WHEN] Open Service Item worksheet and run insert Starting Fee function.
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();

        // [THEN] Verify Unit Price on Service Worksheet Line
        ServiceLine.SetRange("Document No.", ServiceOrderNo);
        ServiceLine.FindFirst();
        ServiceLine.TestField("Unit Price", ServiceCost."Default Unit Price");

        // Rollback Service Order Starting Fee on Service Management Setup to default value.
        UpdateServiceOrderStartingFee(ServiceOrderStartingFee);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerCombineShipment')]
    [Scope('OnPrem')]
    procedure CombineSingleServiceShipmentWithCustomerCombineShipment()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        Quantities: List of [Decimal];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Combine Shipments] [Description Service Line]
        // [SCENARIO 363166] Creating single Service Shipments with Customer which has set Combine Shipments to "true"
        Initialize();

        // [GIVEN] Create new Customer with Combine Shipments = true
        CreateCustomerWithCombineShipments(Customer);

        // [GIVEN] Create new Item
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Create single Service Order
        CreateServiceOrderForCustomerAndDoShipment(ServiceHeader, Customer, Quantities, ItemNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [WHEN] Combine Shipment with "Post Invoices" and "Copy Text Lines" = true
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler.
        RunCombineShipments(Customer."No.", false, true, false, true);

        // [THEN] Verify Posted Service Invoice contains single lines with correct data
        VerifyPostedServiceInvoice(Quantities, ItemNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerCombineShipment')]
    [Scope('OnPrem')]
    procedure CombineMultipleServiceShipmentsWithCustomerCombineShipment()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        Quantities: List of [Decimal];
        ItemNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Combine Shipments] [Description Service Line]
        // [SCENARIO 363166] Creating multiple Service Shipments with Customer which has set Combine Shipments to "true"
        Initialize();

        // [GIVEN] Create new Customer with Combine Shipments = true
        CreateCustomerWithCombineShipments(Customer);

        // [GIVEN] Create new Item
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Create multiple Service Orders
        for i := 1 to LibraryRandom.RandIntInRange(3, 8) do begin
            CreateServiceOrderForCustomerAndDoShipment(ServiceHeader, Customer, Quantities, ItemNo);
            LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        end;

        // [WHEN] Combine Shipment with "Post Invoices" and "Copy Text Lines" = true
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler.
        RunCombineShipments(Customer."No.", false, true, false, true);

        // [THEN] Verify Posted Service Invoice contains three to eight lines with correct data
        VerifyPostedServiceInvoice(Quantities, ItemNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerCombineShipment')]
    [Scope('OnPrem')]
    procedure CombineSingleServiceShipment()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        Quantities: List of [Decimal];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Combine Shipments] [Description Service Line]
        // [SCENARIO 363166] Creating single Service Shipments with Customer which has set Combine Shipments to "false" and on Service Order Combine Shipments to "true"
        Initialize();

        // [GIVEN] Create new Customer with Combine Shipments = false
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create new Item
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Create single Service Order
        CreateServiceOrderForCustomerAndDoShipment(ServiceHeader, Customer, Quantities, ItemNo);
        ServiceHeader.Validate("Combine Shipments", true);
        ServiceHeader.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [WHEN] Combine Shipment with "Post Invoices" and "Copy Text Lines" = true
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler.
        RunCombineShipments(Customer."No.", false, true, false, true);

        // [THEN] Verify Posted Service Invoice contains single lines with correct data
        VerifyPostedServiceInvoice(Quantities, ItemNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerCombineShipment')]
    [Scope('OnPrem')]
    procedure CombineMultipleServiceShipments()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        Quantities: List of [Decimal];
        ItemNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Combine Shipments] [Description Service Line]
        // [SCENARIO 363166] Creating multiple Service Shipments with Customer which has set Combine Shipments to "false" and on Service Order Combine Shipments to "true"
        Initialize();

        // [GIVEN] Create new Customer with Combine Shipments = false
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create new Item
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Create multiple Service Orders
        for i := 1 to LibraryRandom.RandIntInRange(3, 8) do begin
            CreateServiceOrderForCustomerAndDoShipment(ServiceHeader, Customer, Quantities, ItemNo);
            ServiceHeader.Validate("Combine Shipments", true);
            ServiceHeader.Modify(true);
            LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        end;

        // [WHEN] Combine Shipment with "Post Invoices" and "Copy Text Lines" = true
        LibraryVariableStorage.Enqueue(CombineShipmentMsg);  // Enqueue for MessageHandler.
        RunCombineShipments(Customer."No.", false, true, false, true);

        // [THEN] Verify Posted Service Invoice contains three to eight lines with correct data
        VerifyPostedServiceInvoice(Quantities, ItemNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerCombineShipment')]
    [Scope('OnPrem')]
    procedure CombineMultipleServiceShipmentWithoutSetCombineShipment()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        Quantities: List of [Decimal];
        ItemNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Combine Shipments] [Description Service Line]
        // [SCENARIO 363166] Creating single Service Shipment with Customer which has set Combine Shipments to "false" and on Service Order Combine Shipments to "false"
        Initialize();

        // [GIVEN] Create new Customer with Combine Shipments = false
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create new Item
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Create multiple Service Orders
        for i := 1 to LibraryRandom.RandIntInRange(2, 4) do begin
            CreateServiceOrderForCustomerAndDoShipment(ServiceHeader, Customer, Quantities, ItemNo);
            LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        end;

        // [WHEN] Combine Shipment with "Post Invoices" and "Copy Text Lines" = true
        // [THEN] Verify Combine Shipments finished with message "There is nothing to combine."
        LibraryVariableStorage.Enqueue(NothingToCombineShipmentMsg);  // Enqueue for MessageHandler.
        RunCombineShipments(Customer."No.", false, true, false, true);
    end;

    local procedure CreateBOMComponent(ItemNo: Code[20]): Integer
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ItemNo, BOMComponent.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '');
        exit(BOMComponent."Quantity per");
    end;

    local procedure CreateCustomer(): Code[20]
    begin
        exit(LibrarySales.CreateCustomerNo());
    end;

    local procedure CreateCustomerWithZoneCode(ServiceZoneCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Service Zone Code", ServiceZoneCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateExtendedTextForItem(var ExtendedTextHeader: Record "Extended Text Header"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        ExtendedTextHeader.Validate("Starting Date", WorkDate());
        ExtendedTextHeader.Validate("All Language Codes", true);
        ExtendedTextHeader.Modify(true);
    end;

    local procedure CreateExtendedTextLine(ExtendedTextHeader: Record "Extended Text Header"): Text[50]
    var
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, Format(ExtendedTextLine."Table Name") + Format(ExtendedTextLine."Line No."));
        ExtendedTextLine.Modify(true);
        exit(ExtendedTextLine.Text);
    end;

    local procedure CreateHeaderWithNameAndAddress() ServiceOrderNo: Code[20]
    var
        PostCode: Record "Post Code";
        LibraryERM: Codeunit "Library - ERM";
        ServiceOrder: TestPage "Service Order";
    begin
        LibraryERM.CreatePostCode(PostCode);
        ServiceOrder.OpenNew();
        ServiceOrder.Name.Activate();
        ServiceOrder.Name.SetValue(ServiceOrder."No.".Value);
        ServiceOrder.Address.SetValue(ServiceOrder."No.".Value + PostCode.City);
        ServiceOrder.City.SetValue(PostCode.City);
        ServiceOrder."Post Code".SetValue(PostCode.Code);
        ServiceOrderNo := ServiceOrder."No.".Value();
        ServiceOrder.OK().Invoke();
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          ItemNo, LibraryRandom.RandInt(10));  // Use integer random value for Quantity for Item Tracking.

        // Validate Document No. as combination of Journal Batch Name and Line No.
        ItemJournalLine.Validate("Document No.", ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."));
        ItemJournalLine.Modify(true);
        Commit();
    end;

    local procedure CreateItemWithItemTrackingCode(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", FindItemTrackingCode());
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItem(CostingMethod: Enum "Costing Method"; OrderTrackingPolicy: Enum "Order Tracking Policy"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));  // Using Random value for Unit Price.
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost"; ServiceZoneCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Cost Type", ServiceCost."Cost Type"::Travel);
        ServiceCost.Validate("Account No.", GLAccount."No.");
        ServiceCost.Validate("Service Zone Code", ServiceZoneCode);

        // Use random for Default Quantity.
        ServiceCost.Validate("Default Quantity", LibraryRandom.RandDec(10, 2));
        ServiceCost.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, LibraryService.CreateServiceOrderHeaderUsingPage());
        ServiceHeader.Validate("Customer No.", CustomerNo);
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item")
    begin
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
        ServiceItem.Validate("Item No.", CreateItemWithItemTrackingCode());
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceItemLineWithItem(No: Code[20]; ItemNo: Code[20]): Code[20]
    var
        ServiceOrder: TestPage "Service Order";
    begin
        OpenServiceOrder(ServiceOrder, No);
        ServiceOrder."Customer No.".SetValue(CreateCustomer());
        ServiceOrder.ServItemLines.New();
        ServiceOrder.ServItemLines."Item No.".SetValue(ItemNo);
        ServiceOrder.ServItemLines."Create Service Item".Invoke();
        exit(ServiceOrder.ServItemLines.ServiceItemNo.Value);
    end;

    local procedure CreateServiceOrder(ServiceItem: Record "Service Item") ServiceOrderNo: Code[20]
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrderNo := LibraryService.CreateServiceOrderHeaderUsingPage();
        OpenServiceOrder(ServiceOrder, ServiceOrderNo);
        ServiceOrder."Customer No.".SetValue(ServiceItem."Customer No.");
        ServiceOrder.ServItemLines.ServiceItemNo.SetValue(ServiceItem."No.");
        ServiceOrder.ServItemLines.New();
        ServiceOrder.OK().Invoke();
    end;

    local procedure CreateServiceOrderWithTrackedReplacementComponentOnTwoLocations(var ServiceLine: Record "Service Line"; var Location: array[2] of Record Location)
    var
        ServiceItem: Record "Service Item";
    begin
        CreateServiceItem(ServiceItem);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        PostItemJnlPurchaseOnLocation(ServiceItem."Item No.", Location[1].Code, 1);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        PostItemJnlPurchaseOnLocation(ServiceItem."Item No.", Location[2].Code, 1);

        CreateServiceOrderWithServiceItemLine(ServiceLine, ServiceItem, Location[1].Code);
    end;

    local procedure CreateServiceOrderWithServiceItemLine(var ServiceLine: Record "Service Line"; ServiceItem: Record "Service Item"; LocationCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", LocationCode);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        InsertServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.", ServiceItem."No.");
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]): Integer
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        exit(ServiceItemLine."Line No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(100) + 100);  // Needed greater Quantity than Service Line and used random for Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Used Random to calculate the Expected Receipt Date.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; No: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.", No, Quantity);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLineNo: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        ServiceItemLineNo := CreateServiceDocument(ServiceHeader, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, Quantity);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Needed by Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Used Random to calculate the Needed by Date.
        ServiceLine.Modify(true);
    end;

    local procedure CreateSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.Init();
        SalesShipmentHeader."No." := LibraryUtility.GenerateGUID();
        SalesShipmentHeader.Insert();

        SalesShipmentLine.Init();
        SalesShipmentLine."Document No." := SalesShipmentHeader."No.";
        SalesShipmentLine."Line No." := 1;
        SalesShipmentLine.Insert();
    end;

    local procedure CreateServiceShipmentLine(var ServiceShipmentLine: Record "Service Shipment Line")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.Init();
        ServiceShipmentHeader."No." := LibraryUtility.GenerateGUID();
        ServiceShipmentHeader.Insert();

        ServiceShipmentLine.Init();
        ServiceShipmentLine."Document No." := ServiceShipmentHeader."No.";
        ServiceShipmentLine."Line No." := 1;
        ServiceShipmentLine.Insert();
    end;

    local procedure FindItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("SN Specific Tracking", true);
        ItemTrackingCode.SetRange("SN Sales Inbound Tracking", true);
        ItemTrackingCode.SetRange("SN Sales Outbound Tracking", true);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindServiceItem(var ServiceItem: Record "Service Item"; OrderNo: Code[20])
    begin
        ServiceItem.SetRange("Shipment Type", ServiceItem."Shipment Type"::Service);
        ServiceItem.SetRange("Sales/Serv. Shpt. Document No.", FindServiceShipmentHeader(OrderNo));
        ServiceItem.FindFirst();
    end;

    local procedure FindServiceShipmentHeader(OrderNo: Code[20]): Code[20]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        exit(ServiceShipmentHeader."No.");
    end;

    local procedure GetSerialNoFromPostedEntry(ItemNo: Code[20]; LocationCode: Code[10]): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindFirst();

        exit(ItemLedgerEntry."Serial No.");
    end;

    local procedure InitVariables()
    begin
        // Clear all global variables.
        ItemNo2 := '';
        ExtendedText2 := '';
        Comment := '';
        Clear(CopyComponentsFrom);
        Clear(Replacement);
        Clear(ServiceLine2);
    end;

    local procedure InsertServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; ServiceItemNo: Code[20])
    begin
        ServiceLine.Init();
        ServiceLine.Validate("Document Type", DocumentType);
        ServiceLine.Validate("Document No.", DocumentNo);
        ServiceLine.Validate("Line No.", LibraryUtility.GetNewRecNo(ServiceLine, ServiceLine.FieldNo("Line No.")));
        ServiceLine.Insert();
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
    end;

    local procedure OpenServiceOrder(var ServiceOrder: TestPage "Service Order"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Order));
        ServiceOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure PostItemJnlPurchaseOnLocation(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetItemNoInServiceLine(var ServiceLine: Record "Service Line"; ItemNo: Code[20])
    begin
        ServiceLine.Validate(Type, ServiceLine.Type::Item);
        ServiceLine.Validate("No.", ItemNo);
    end;

    local procedure UpdateLineFromItemWorksheet(ServiceItemWorksheet: TestPage "Service Item Worksheet")
    begin
        ServiceLine2.Validate("Document Type", ServiceLine2."Document Type"::Order);
        Evaluate(ServiceLine2.Type, ServiceItemWorksheet.ServInvLines.Type.Value);
        ServiceLine2.Validate("Document No.", ServiceItemWorksheet."Document No.".Value);
        ServiceLine2.Validate("No.", ServiceItemWorksheet.ServInvLines."No.".Value);
        Evaluate(ServiceLine2.Quantity, ServiceItemWorksheet.ServInvLines.Quantity.Value);
    end;

    local procedure UpdateServiceOrderStartingFee(ServiceOrderStartingFee: Code[10]) OldServiceOrderStartingFee: Code[10]
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        OldServiceOrderStartingFee := ServiceMgtSetup."Service Order Starting Fee";
        ServiceMgtSetup.Validate("Service Order Starting Fee", ServiceOrderStartingFee);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; Quantity: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure VerifyCommentOnShipmentHeader(OrderNo: Code[20]; Comment2: Text[80])
    var
        ServiceCommentLine: Record "Service Comment Line";
        ServiceCommentSheet: TestPage "Service Comment Sheet";
    begin
        ServiceCommentSheet.OpenView();
        ServiceCommentSheet.FILTER.SetFilter("Table Name", Format(ServiceCommentLine."Table Name"::"Service Shipment Header"));
        ServiceCommentSheet.FILTER.SetFilter("No.", FindServiceShipmentHeader(OrderNo));
        ServiceCommentSheet.Comment.AssertEquals(Comment2);
    end;

    local procedure VerifyCostOnServiceLine(ServiceLine: Record "Service Line"; ServiceCost: Record "Service Cost")
    begin
        ServiceLine.TestField(Type, ServiceLine.Type::Cost);
        ServiceLine.TestField("No.", ServiceCost.Code);
        ServiceLine.TestField(Description, ServiceCost.Description);
        ServiceLine.TestField("Unit of Measure Code", ServiceCost."Unit of Measure Code");
        ServiceLine.TestField(Quantity, ServiceCost."Default Quantity");
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; NoOfLines: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetFilter("Serial No.", '<>''''');
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        Assert.AreEqual(NoOfLines, ItemLedgerEntry.Count, StrSubstNo(NoOfLinesError, NoOfLines, ItemLedgerEntry.TableCaption()));

        // 1 is used as Quantity per Serial No. is 1.
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.TestField(Quantity, 1);
            ItemLedgerEntry.TestField("Invoiced Quantity", 1);
            ItemLedgerEntry.TestField("Remaining Quantity", 1);
            ItemLedgerEntry.TestField("Sales Amount (Actual)", 0);
            ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyPostedShipmentEntry(OrderNo: Code[20])
    var
        Navigate: TestPage Navigate;
    begin
        Navigate.OpenEdit();
        Navigate.DocNoFilter.SetValue(FindServiceShipmentHeader(OrderNo));
        Navigate.Find.Invoke();
        Navigate."Table Name".AssertEquals(PostedServiceShipmentCaption);
        Navigate."No. of Records".AssertEquals(1);
    end;

    local procedure VerifyServiceItemComponent(ParentServiceItemNo: Code[20]; No: Code[20]; Type: Enum "Service Item Component Type")
    var
        ServiceItemComponent: Record "Service Item Component";
    begin
        ServiceItemComponent.SetRange("Parent Service Item No.", ParentServiceItemNo);
        ServiceItemComponent.FindFirst();
        ServiceItemComponent.TestField(Type, Type);
        ServiceItemComponent.TestField("No.", No);
    end;

    local procedure CreateCustomerWithBillToCustomer(var Customer: Record Customer; var CustomerBillTo: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer.Modify();
        LibrarySales.CreateCustomer(CustomerBillTo);
        CustomerBillTo.Name := LibraryUtility.GenerateGUID();
        CustomerBillTo.Modify();
        Customer.Validate("Bill-to Customer No.", CustomerBillTo."No.");
        Customer.Modify(true);
    end;

    local procedure CreateShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), Database::"Shipment Method");
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure RunCombineShipments(CustomerNoFilter: Text; CalcInvDisc: Boolean; PostInvoices: Boolean; OnlyStdPmtTerms: Boolean; CopyTextLines: Boolean)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetFilter("Customer No.", CustomerNoFilter);
        ServiceShipmentHeader.SetFilter("Customer No.", CustomerNoFilter);
        LibraryService.CombineShipments(
          ServiceHeader, ServiceShipmentHeader, WorkDate(), WorkDate(), CalcInvDisc, PostInvoices, OnlyStdPmtTerms, CopyTextLines);
    end;

    local procedure UpdateServiceLineWithRandomQtyAndPrice(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer)
    begin
        UpdateServiceLine(
          ServiceLine, ServiceItemLineNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; Quantity: Decimal; UnitPrice: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerWithCombineShipments(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Service Shipments", true);
        Customer.Modify(true);
    end;

    local procedure CreateServiceOrderForCustomerAndDoShipment(var ServiceHeader: Record "Service Header"; var Customer: Record Customer; var Quantities: List of [Decimal]; var ItemNo: Code[20])
    var

        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");
        Quantities.Add(ServiceLine.Quantity);
    end;

    local procedure VerifyPostedServiceInvoice(var Quantities: List of [Decimal]; var ItemNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        i: Integer;
    begin
        ServiceInvoiceLine.SetRange("No.", ItemNo);
        for i := 1 to Quantities.Count() do begin
            ServiceInvoiceLine.SetRange(Quantity, Quantities.Get(i));
            ServiceInvoiceLine.FindFirst();
            Assert.AreEqual(ServiceInvoiceLine.Type::Item, ServiceInvoiceLine.Type, CombineShipmentErr);
        end;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CommentSheetPageHandler(var ServiceCommentSheet: TestPage "Service Comment Sheet")
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceCommentSheet.Comment.SetValue(
          CopyStr(
            LibraryUtility.GenerateRandomCode(ServiceCommentLine.FieldNo(Comment), DATABASE::"Service Comment Line"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Service Comment Line", ServiceCommentLine.FieldNo(Comment))));
        Comment := ServiceCommentSheet.Comment.Value();  // Assign global variable for verification.
        ServiceCommentSheet.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateListHandler(var CustomerTemplateList: testPage "Select Customer Templ. List")
    begin
        CustomerTemplateList.First();
        CustomerTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExtendedTextPageHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    begin
        ServiceItemWorksheet.ServInvLines.Type.SetValue(ServiceLine2.Type::Item);
        ServiceItemWorksheet.ServInvLines."No.".SetValue(ItemNo2);
        ServiceItemWorksheet.ServInvLines."Insert Ext. Texts".Invoke();
        ServiceItemWorksheet.ServInvLines.Last();

        // Assign global variable for verification.
        ExtendedText2 := ServiceItemWorksheet.ServInvLines.Description.Value();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageVerificationHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerCombineShipment(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemReplacementPageHandler(var ServiceItemReplacement: TestPage "Service Item Replacement")
    begin
        ServiceItemReplacement.NewSerialNo.SetValue(ItemNo2);
        ServiceItemReplacement.CopyComponents.SetValue(CopyComponentsFrom);
        ServiceItemReplacement.Replacement.SetValue(Replacement);
        ServiceItemReplacement.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemReplacementPageHandler2(var ServiceItemReplacement: TestPage "Service Item Replacement")
    begin
        ServiceItemReplacement.NewSerialNo.SetValue(LibraryVariableStorage.DequeueText());
        ServiceItemReplacement.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReplacementWorksheetHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    begin
        ServiceItemWorksheet.ServInvLines.Type.SetValue(ServiceLine2.Type::Item);
        ServiceItemWorksheet.ServInvLines."No.".SetValue(ItemNo2);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinePageHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    var
        Item: Record Item;
    begin
        ServiceItemWorksheet.ServInvLines.Type.SetValue(ServiceLine2.Type::Item);
        ServiceItemWorksheet.ServInvLines."No.".SetValue(LibraryInventory.CreateItem(Item));

        // Integer value is required for assigning Serial No.
        ServiceItemWorksheet.ServInvLines.Quantity.SetValue(LibraryRandom.RandInt(10));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StartingFeePageHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    begin
        ServiceItemWorksheet.ServInvLines."Insert Starting Fee".Invoke();

        // Assign global variable for verification.
        UpdateLineFromItemWorksheet(ServiceItemWorksheet);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;  // 1 for post as ship.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TravelFeePageHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    begin
        ServiceItemWorksheet.ServInvLines."Insert Travel Fee".Invoke();

        // Assign global variable for verification.
        UpdateLineFromItemWorksheet(ServiceItemWorksheet);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableToPromisePageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.AvailableToPromise.Invoke();
        OrderPromisingLines."Planned Delivery Date".AssertEquals(ExpectedDate);
        OrderPromisingLines."Earliest Shipment Date".AssertEquals(ExpectedDate);
        OrderPromisingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CapableToPromisePageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();
        OrderPromisingLines."Original Shipment Date".AssertEquals(ExpectedDate);
        OrderPromisingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AcceptPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines."Planned Delivery Date".AssertEquals(ExpectedDate);
        OrderPromisingLines.AcceptButton.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(GlobalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.ItemNo.AssertEquals(GlobalItemNo);
        Reservation."Total Quantity".AssertEquals(GlobalQuantity);
        Reservation.TotalAvailableQuantity.AssertEquals(GlobalQuantity);
    end;
}

