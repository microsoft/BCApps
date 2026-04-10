// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;

codeunit 136117 "Service Posting - Undo Ship"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Undo] [Shipment] [Service]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        WarningMsg: Label 'The field Automatic Cost Posting should not be set to Yes if field Use Legacy G/L Entry Locking in General Ledger Setup table is set to No because of possibility of deadlocks.';
        ExpectedMsg: Label 'Expected Cost Posting to G/L has been changed';
        QtyMustBeZeroError: Label '%1 must be zero.';
        ExpectedCostPostingEnableConfirm: Label 'If you enable the Expected Cost Posting to G/L';
        ExpectedCostPostingDisableConfirm: Label 'If you disable the Expected Cost Posting to G/L';
        ServiceShipLineMustNotExist: Label '%1 = %2,%3 = %4 must not exist in %5.';
        ConfirmUndoConsumption: Label 'Do you want to undo consumption of the selected shipment line(s)?';
        ConfirmUndoSelectedShipment: Label 'Do you want to undo the selected shipment line(s)?';
        ConfirmServiceCost: Label 'You must confirm Service Cost';
        SetHandler: Boolean;
        CreateNewLotNo: Boolean;
        NoOfEntriesError: Label 'No of entries for %1 must be %2.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Posting - Undo Ship");
        // Initialize global variable.
        Clear(SetHandler);
        Clear(CreateNewLotNo);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Posting - Undo Ship");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Posting - Undo Ship");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartialShipManual()
    begin
        // Covers document number TC-PP-US-1 - refer to TFS ID 20883.
        // Test that the posted shipment document, all the relevant ledger entries and the service line are updated accordingly on Undo
        // Shipment for the item shipped partially with Auto cost Posting and Expected Cost Posting set to false.

        UndoPartialShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartialShipAutoEx()
    begin
        // Covers document number TC-PP-US-1 - refer to TFS ID 20883.
        // Test that the posted shipment document, all the relevant ledger entries and the service line are updated accordingly on Undo
        // Shipment for the item shipped partially with Auto cost Posting and Expected Cost Posting set to true.

        UndoPartialShip(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartialShipAuto()
    begin
        // Covers document number TC-PP-US-1 - refer to TFS ID 20883.
        // Test that the posted shipment document, all the relevant ledger entries and the service line are updated accordingly on Undo
        // Shipment for the item shipped partially with Auto cost Posting set to true and Expected Cost Posting set to false.

        UndoPartialShip(true, false);
    end;

    local procedure UndoPartialShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // 1. Setup: Create Inventory Setup. Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type
        // as Item, Update Qty to Ship.
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader, ServiceLine);
        UpdatePartialQtyToShip(ServiceLine);

        // 2. Exercise: Post Service Order partially as Ship. Undo Shipment.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // 3. Verify: Quantity Shipped on Service Line is equal to Zero. Item Ledger Entry and Value Entry are created with the Quantity
        // equal to the quantity that was shipped. Verify Service Shipment Line and Service Ledger Entry.
        VerifyEntriesOnPostedShipment(ServiceHeader."No.");
        VerifyQtyOnItemLedgerEntry(ServiceHeader."No.");
        VerifyQtyOnValueEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPartialShipResourceCostGL()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-US-2 - refer to TFS ID 20883.
        // Test that on Undo Shipment line of type Resource, Cost, G/L Account which was shipped partially, the posted shipment
        // document, all the relevant ledger entries and the service line are updated accordingly.

        // 1. Setup: Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource, Cost and
        // G/L Account. Update Qty to Ship.
        CreateServiceOrderResourceCost(ServiceHeader, ServiceLine);
        UpdatePartialQtyToShip(ServiceLine);

        // 2. Exercise: Post Service Order partially as Ship. Undo Shipment.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // 3. Verify: Quantity Shipped on Service Line is equal to Zero. Verify Service Shipment Line and Service Ledger Entry.
        VerifyEntriesOnPostedShipment(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoFullShipManual()
    begin
        // Covers document number TC-PP-US-3 - refer to TFS ID 20883.
        // Test that the posted shipment document, all the relevant ledger entries and the service line are updated accordingly on Undo
        // Shipment for the item shipped fully with Auto cost Posting and Expected Cost Posting set to false.

        UndoFullShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoFullShipAutoEx()
    begin
        // Covers document number TC-PP-US-3 - refer to TFS ID 20883.
        // Test that the posted shipment document, all the relevant ledger entries and the service line are updated accordingly on Undo
        // Shipment for the item shipped fully with Auto cost Posting and Expected Cost Posting set to true.

        UndoFullShip(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoFullShipAuto()
    begin
        // Covers document number TC-PP-US-3 - refer to TFS ID 20883.
        // Test that the posted shipment document, all the relevant ledger entries and the service line are updated accordingly on Undo
        // Shipment for the item shipped fully with Auto cost Posting set to true and Expected Cost Posting set to false.

        UndoFullShip(true, false);
    end;

    local procedure UndoFullShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // 1. Setup: Create Inventory Setup. Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type
        // as Item. Update Quantity.
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader, ServiceLine);
        UpdateQuantity(ServiceLine);

        // 2. Exercise: Post Service Order fully as Ship. Undo Shipment.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // 3. Verify: Quantity Shipped on Service Line is equal Zero. Item Ledger Entry and Value Entry are created with the Quantity equal
        // to the quantity that was shipped. Verify Service Shipment Line and Service Ledger Entry.
        VerifyEntriesOnPostedShipment(ServiceHeader."No.");
        VerifyQtyOnItemLedgerEntry(ServiceHeader."No.");
        VerifyQtyOnValueEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoFullShipResourceCostGL()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-US-4 - refer to TFS ID 20883.
        // Test that on Undo Shipment for the line of type Resource, Cost, G/L Account which was shipped fully, the posted shipment
        // document, all the relevant ledger entries and the service line are updated.

        // 1. Setup: Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource, Cost and
        // G/L Account. Update Quantity.
        CreateServiceOrderResourceCost(ServiceHeader, ServiceLine);
        UpdateQuantity(ServiceLine);

        // 2. Exercise: Post Service Order partially as Ship. Undo Shipment.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // 3. Verify: Quantity Shipped on Service Line is equal to Zero. Verify Service Shipment Line and Service Ledger Entry.
        VerifyEntriesOnPostedShipment(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipAfterInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-US-7 - refer to TFS ID 20883.
        // Test that the application generates an error on undo shipment which was previously invoiced.

        // 1. Setup: Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Post the
        // Service Order partially as Ship.
        CreateServiceOrder(ServiceHeader, ServiceLine);
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Post Service Order partially as Invoice.
        UpdatePartialQtyToInvoice(ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Error is generated on Undo Shipment.
        VerifyErrorOnUndoShipment(ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipWithNothingToShip()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Covers document number TC-PP-US-8 - refer to TFS ID 20883.
        // Test that shipping Service Order with lines some with and other without Qty to Ship does not create lines on Service Shipment
        // Line for the lines that does not have Qty to Ship.

        // 1. Setup: Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as as Item. Update Zero
        // Quantity on Last Line.
        CreateServiceOrder(ServiceHeader, ServiceLine);
        UpdatePartialQtyToShip(ServiceLine);
        UpdateZeroQuantityOnLastLine(ServiceLine);

        // 2. Exercise: Post Service Order partially as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Check that Line for Item without Quantity does not create on Service Shipment Line.
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
        Assert.IsFalse(
          ServiceShipmentLine.FindFirst(),
          StrSubstNo(
            ServiceShipLineMustNotExist, ServiceShipmentLine.FieldCaption("Document No."), ServiceShipmentLine."Document No.",
            ServiceShipmentLine.FieldCaption("Line No."), ServiceShipmentLine."Line No.", ServiceShipmentLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipAfterShipAndInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-US-9 - refer to TFS ID 20883.
        // Test that the application generates an error on undo shipment which was previously shipped and invoiced.

        // 1. Setup: Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Update
        // Quantity.
        CreateServiceOrder(ServiceHeader, ServiceLine);
        UpdateQuantity(ServiceLine);

        // 2. Exercise: Post the Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Error is generated on Undo Shipment which was previously shipped and invoiced.
        VerifyErrorOnUndoShipment(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipAfterShipAndConsume()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-US-10 - refer to TFS ID 20883.
        // Test that the application generates an error on undo shipment which was previously shipped and consumed.

        // 1. Setup: Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Update
        // Qty to Consume.
        CreateServiceOrder(ServiceHeader, ServiceLine);
        UpdateQtyToConsume(ServiceLine);

        // 2. Exercise: Post the Service Order as Ship and Consume.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Error is generated on Undo Shipment which was previously shipped and consumed.
        VerifyErrorOnUndoShipment(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipAfterUndoShip()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-US-11 - refer to TFS ID 20883.
        // Test that the application generates an error on undo the shipment line which was previously undone.

        // 1. Setup: Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item.
        CreateServiceOrder(ServiceHeader, ServiceLine);

        // 2. Exercise: Post Service Order partially as Ship. Undo Shipment.
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // 3. Verify: Error is generated on Undo Shipment after previous undone.
        asserterror UndoShipment(ServiceHeader."No.");
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ShipWithSerialNo()
    begin
        // Test Posted Entries after posting Service Order as Ship with Item having Item Tracking Code for Serial No.

        ShipWithItemTracking(CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)), false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ShipWithSerialAndLotNo()
    begin
        // Test Posted Entries after posting Service Order as Ship with Item having Item Tracking Code for Serial and Lot No.

        ShipWithItemTracking(CreateItemWithItemTrackingCode(CreateItemTrackingCode(true, true)), true);
    end;

    local procedure ShipWithItemTracking(ItemNo: Code[20]; CreateNewLotNoFrom: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ShipmentHeaderNo: Code[20];
    begin
        // 1. Setup: Create Item with Item Tracking Code for Serial No., Purchase Order, assign Item Tracking on Purchase Line and Post it as Receive.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));

        // Assign global variables for page handler.
        SetHandler := true;
        CreateNewLotNo := CreateNewLotNoFrom;
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // 2. Exercise: Create Service Order, select Item Tracking for Service Line and Post it as Ship.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceHeader, PurchaseLine."No.", PurchaseLine.Quantity, ServiceItemLine."Line No.");

        SetHandler := false;  // Assign global variable for page handler.
        OpenServiceLinesPage(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify Service Ledger Entry, Value Entry and Item Ledger Entry.
        ShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        VerifyLedgerEntryAfterPosting(ShipmentHeaderNo, PurchaseLine."No.", PurchaseLine.Quantity);
        VerifyNoOfValueEntry(ShipmentHeaderNo, PurchaseLine.Quantity);
        VerifyNoOfItemLedgerEntry(ShipmentHeaderNo, PurchaseLine."No.", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerForLot,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ShipWithLotNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ShipmentHeaderNo: Code[20];
    begin
        // Test Posted Entries after posting Service Order as Ship with Item having Item Tracking Code for Lot No.

        // 1. Setup: Create Item with Item Tracking Code for Lot No., Purchase Order, assign Lot No. on Purchase Line and Post it as Receive.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithItemTrackingCode(FindItemTrackingCode(true, false)),
          LibraryRandom.RandInt(10));

        SetHandler := true;  // Assign global variable for page handler.
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // 2. Exercise: Create Service Order, select Lot No. for Service Line and Post it as Ship.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceHeader, PurchaseLine."No.", PurchaseLine.Quantity, ServiceItemLine."Line No.");

        SetHandler := false;  // Assign global variable for page handler.
        OpenServiceLinesPage(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify Service Ledger Entry, Value Entry and Item Ledger Entry.
        ShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        VerifyLedgerEntryAfterPosting(ShipmentHeaderNo, PurchaseLine."No.", PurchaseLine.Quantity);

        // Use 1 for Lot No.
        VerifyNoOfValueEntry(ShipmentHeaderNo, 1);
        VerifyNoOfItemLedgerEntry(ShipmentHeaderNo, PurchaseLine."No.", 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,UndoShipmentFromServiceShipmentLinesHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentPostingWithSerialNo()
    begin
        // Test Undo Shipment after posting Service Order as Ship with Item having Item Tracking Code for Serial No.

        UndoShipmentPostingWithItemTracking(CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)), false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerForLot,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,UndoShipmentFromServiceShipmentLinesHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentPostingWithLotNo()
    begin
        // Test Undo Shipment after posting Service Order as Ship with Item having Item Tracking Code for Lot No.

        UndoShipmentPostingWithItemTracking(CreateItemWithItemTrackingCode(FindItemTrackingCode(true, false)), false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,UndoShipmentFromServiceShipmentLinesHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentPostingWithSerialAndLotNo()
    begin
        // Test Undo Shipment after posting Service Order as Ship with Item having Item Tracking Code for Serial and Lot No.

        UndoShipmentPostingWithItemTracking(CreateItemWithItemTrackingCode(CreateItemTrackingCode(true, true)), true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,UndoDocumentConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentWithSerialNoAndExpirationDateForFreeEntryTracking()
    begin
        // Test Undo Shipment With Serial No and Expiration Date for Free Entry Tracking successfully.
        // Serial No. is created by ItemTrackingPageHandler.
        UndoShipmentWithExpirationDateForFreeEntryTracking(CreateItemWithItemTrackingCode(FindItemTrackingCode(false, false)), false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerForLot,ItemTrackingSummaryPageHandler,UndoDocumentConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentWithLotNoAndExpirationDateForFreeEntryTracking()
    begin
        // Test Undo Shipment With Lot No and Expiration Date for Free Entry Tracking successfully.
        // Lot No. is created by ItemTrackingPageHandlerForLot.
        UndoShipmentWithExpirationDateForFreeEntryTracking(CreateItemWithItemTrackingCode(FindItemTrackingCode(false, false)), false);
    end;

    local procedure UndoShipmentWithExpirationDateForFreeEntryTracking(ItemNo: Code[20]; CreateNewLotNoFrom: Boolean)
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        Quantity: Integer;
    begin
        Initialize();
        // Setup: Create and post 2 purchase receipts, order1 without Item Tracking, order2 with Expiration Date and Serial No. / Lot No.
        CreatePurchaseHeader(PurchaseHeader1);
        Quantity := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader1, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, false);

        CreatePurchaseHeader(PurchaseHeader2);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader2, PurchaseLine.Type::Item, ItemNo, Quantity);
        SetHandler := true; // Assign global variables for ItemTrackingPageHandler / ItemTrackingPageHandlerForLot.
        CreateNewLotNo := CreateNewLotNoFrom;
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader2."No.");
        UpdateReservationEntry(PurchaseLine."No.", WorkDate());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, false);

        // Setup: Create and post sales shipment with Expiration Date and Serial No. / Lot No.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SetHandler := false;
        SalesLine.OpenItemTrackingLines();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise: Undo the shipment.
        UndoSalesShipmentLine(DocumentNo, SalesLine."No.");

        // Verify: Undo shipment successfully. Posted Sales Shipment lines are correct.
        VerifyPostedSalesShipmentLine(DocumentNo, ItemNo, Quantity);
    end;

    local procedure UndoSalesShipmentLine(DocumentNo: Code[20]; No: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange("No.", No);
        SalesShipmentLine.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UndoShipmentPostingWithItemTracking(ItemNo: Code[20]; CreateNewLotNoFrom: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        PostedServiceShipment: TestPage "Posted Service Shipment";
    begin
        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line, Post it as Receive, Create Service Order, select Item Tracking for Service Line
        // and Post Service Order as Ship.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);  // 1 is important for test case.

        // Assign global variables for page handler.
        SetHandler := true;
        CreateNewLotNo := CreateNewLotNoFrom;
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceHeader, PurchaseLine."No.", PurchaseLine.Quantity + LibraryRandom.RandInt(10), ServiceItemLine."Line No.");  // Use random for Quantity.
        UpdateQuantityToShipOnServiceLine(ServiceHeader."No.");
        SetHandler := false;  // Assign global variable for page handler.
        OpenServiceLinesPage(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Open Posted Service Shipment page and perform Undo Shipment from it.
        PostedServiceShipment.OpenView();
        PostedServiceShipment.FILTER.SetFilter("No.", FindServiceShipmentHeader(ServiceHeader."No."));
        PostedServiceShipment.ServShipmentItemLines.ServiceShipmentLines.Invoke();

        // 3. Verify: Verify Service Line after Undo Shipment.
        VerifyQtyShippedAfterUndoShip(ServiceHeader."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItemWithItemTrackingCode(ItemCategoryCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemCategoryCode);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemTrackingCode(LotSpecific: Boolean; SNSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Sales Inbound Tracking", LotSpecific);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", LotSpecific);
        ItemTrackingCode.Validate("SN Sales Inbound Tracking", SNSpecific);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", SNSpecific);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.Validate("Man. Warranty Date Entry Reqd.", false);
        ItemTrackingCode.Modify();
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", '');
        PurchaseHeader.Validate("Expected Receipt Date", WorkDate());
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Account No.", GLAccount."No.");
        ServiceCost.Modify(true);
    end;

    local procedure CreateServiceItemLine(ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Item Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        end;
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; No: Code[20]; Quantity: Decimal; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate("Location Code", '');
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineForCost(ServiceHeader: Record "Service Header")
    var
        ServiceCost: Record "Service Cost";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            CreateServiceCost(ServiceCost);
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceLineForItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
            Item.Next();
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceLineForGLAccount(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryService.CreateServiceLine(
              ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceLineForResource(ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Resource: Record Resource;
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryResource.CreateResourceNew(Resource);
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
        // Create a new Service Order - Service Header, Service Item, Service Item Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        CreateServiceItemLine(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
    end;

    local procedure CreateServiceOrderResourceCost(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
        // Create a new Service Order - Service Header, Service Item, Service Item Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        CreateServiceItemLine(ServiceHeader);
        CreateServiceLineForResource(ServiceHeader);
        CreateServiceLineForCost(ServiceHeader);
        CreateServiceLineForGLAccount(ServiceLine, ServiceHeader);
    end;

    local procedure FindItemTrackingCode(LotSpecific: Boolean; SNSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Sales Inbound Tracking", LotSpecific);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", LotSpecific);
        ItemTrackingCode.Validate("SN Sales Inbound Tracking", SNSpecific);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", SNSpecific);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.Validate("Man. Warranty Date Entry Reqd.", false);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; DocumentNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
    end;

    local procedure FindServiceShipmentHeader(OrderNo: Code[20]): Code[20]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        exit(ServiceShipmentHeader."No.");
    end;

    local procedure OpenItemTrackingLinesForPurchaseOrder(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchLines."Item Tracking Lines".Invoke();
    end;

    local procedure OpenServiceLinesPage(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
    end;

    local procedure SetupCostPostingInventory(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // Sometimes this function triggers a message and a confirm dialog
        // This is to make sure the corresponding handlers are always executed
        // (otherwise tests would fail)
        ExecuteUIHandlers();

        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Expected Cost Posting to G/L", ExpectedCostPostingToGL);
        InventorySetup.Modify(true);
    end;

    local procedure UpdatePartialQtyToInvoice(ServiceLine: Record "Service Line")
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document No.");
        repeat
            ServiceLine.Validate("Qty. to Invoice", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartialQtyToShip(ServiceLine: Record "Service Line")
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document No.");
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQtyToConsume(ServiceLine: Record "Service Line")
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document No.");
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQuantity(ServiceLine: Record "Service Line")
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document No.");
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQuantityToShipOnServiceLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentNo);
        ServiceLine.Validate("Qty. to Ship", 1);  // 1 is important for test case.
        ServiceLine.Modify(true);
    end;

    local procedure UndoShipment(ServiceDocumentNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceDocumentNo);
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);
    end;

    local procedure UpdateZeroQuantityOnLastLine(ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindLast();
        ServiceLine.Validate(Quantity, 0);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateReservationEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);
    end;

    [Normal]
    local procedure ExecuteUIHandlers()
    begin
        Message(StrSubstNo(ExpectedMsg));
        if Confirm(StrSubstNo(ExpectedCostPostingEnableConfirm)) then;
    end;

    local procedure VerifyEntriesOnPostedShipment(ServiceHeaderNo: Code[20])
    begin
        VerifyQtyShippedAfterUndoShip(ServiceHeaderNo);
        VerifyQtyOnServiceShipment(ServiceHeaderNo);
        VerifyServiceLedgerEntry(ServiceHeaderNo);
    end;

    local procedure VerifyErrorOnUndoShipment(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        asserterror UndoShipment(OrderNo);
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceShipmentLine.FindFirst();
        Assert.ExpectedTestFieldError(ServiceShipmentLine.FieldCaption("Qty. Shipped Not Invoiced"), Format(ServiceShipmentLine.Quantity));
    end;

    local procedure VerifyLedgerEntryAfterPosting(DocumentNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", DocumentNo);
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.TestField("No.", No);
        ServiceLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyNoOfItemLedgerEntry(DocumentNo: Code[20]; ItemNo: Code[20]; ExpectedValue: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(ExpectedValue, ItemLedgerEntry.Count, StrSubstNo(NoOfEntriesError, ItemLedgerEntry.TableCaption(), ExpectedValue));
    end;

    local procedure VerifyNoOfValueEntry(DocumentNo: Code[20]; ExpectedValue: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Shipment");
        Assert.AreEqual(ExpectedValue, ValueEntry.Count, StrSubstNo(NoOfEntriesError, ValueEntry.TableCaption(), ExpectedValue));
    end;

    local procedure VerifyQtyOnItemLedgerEntry(DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        TotalQuantity: Decimal;
    begin
        // Verify that the value of the field Quantity of the Item Ledger Entry is equal to the value of the field Qty. to Ship of the
        // relevant Service Line.
        FindServiceLine(ServiceLine, DocumentNo);
        repeat
            ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
            ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
            ServiceShipmentLine.FindSet();
            repeat
                ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
                ItemLedgerEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
                ItemLedgerEntry.SetRange("Document Line No.", ServiceShipmentLine."Line No.");
                ItemLedgerEntry.FindSet();
                repeat
                    TotalQuantity += ItemLedgerEntry.Quantity;
                until ItemLedgerEntry.Next() = 0;
            until ServiceShipmentLine.Next() = 0;
            Assert.AreEqual(0, TotalQuantity, StrSubstNo(QtyMustBeZeroError, ItemLedgerEntry.FieldCaption(Quantity)));
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyQtyOnServiceShipment(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        TotalQuantity: Decimal;
    begin
        // Verify that the values of the field Qty. Shipped Not Invoiced of Service Shipment Line are equal to the value of the
        // field Qty. to Ship of the relevant Service Line.
        FindServiceLine(ServiceLine, DocumentNo);
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
            ServiceShipmentLine.FindSet();
            repeat
                TotalQuantity += ServiceShipmentLine."Qty. Shipped Not Invoiced";
            until ServiceShipmentLine.Next() = 0;
            Assert.AreEqual(0, TotalQuantity, StrSubstNo(QtyMustBeZeroError, ServiceShipmentLine.FieldCaption("Qty. Shipped Not Invoiced")));
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyQtyOnValueEntry(DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        TotalQuantity: Decimal;
    begin
        // Verify that the value of the field Valued Quantity of the Value Entry is equal to the value of the field Qty. to Ship of
        // the relevant Service Line.
        FindServiceLine(ServiceLine, DocumentNo);
        repeat
            ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
            ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
            ServiceShipmentLine.FindSet();
            repeat
                ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Shipment");
                ValueEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
                ValueEntry.SetRange("Document Line No.", ServiceShipmentLine."Line No.");
                ValueEntry.FindSet();
                repeat
                    TotalQuantity += ValueEntry."Valued Quantity";
                until ValueEntry.Next() = 0;
            until ServiceShipmentLine.Next() = 0;
            Assert.AreEqual(0, TotalQuantity, StrSubstNo(QtyMustBeZeroError, ValueEntry.FieldCaption("Valued Quantity")));
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyQtyShippedAfterUndoShip(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify that the value of the field Quantity Shipped of the new Service Line is equal to Zero.
        FindServiceLine(ServiceLine, DocumentNo);
        repeat
            ServiceLine.TestField("Quantity Shipped", 0);
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(DocumentNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceLine: Record "Service Line";
    begin
        // Verify that the Service Ledger Entry created corresponds with the relevant Service Line by matching the fields No., Posting Date
        // and Bill-to Customer No.
        FindServiceLine(ServiceLine, DocumentNo);
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", FindServiceShipmentHeader(ServiceLine."Document No."));
        repeat
            ServiceLedgerEntry.SetRange("Document Line No.", ServiceLine."Line No.");
            ServiceLedgerEntry.FindFirst();
            ServiceLedgerEntry.TestField("No.", ServiceLine."No.");
            ServiceLedgerEntry.TestField("Posting Date", ServiceLine."Posting Date");
            ServiceLedgerEntry.TestField("Bill-to Customer No.", ServiceLine."Bill-to Customer No.");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyPostedSalesShipmentLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindSet();
        SalesShipmentLine.TestField(Quantity, Quantity);
        SalesShipmentLine.Next();
        SalesShipmentLine.TestField(Quantity, -Quantity);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(
          (StrPos(Question, ExpectedCostPostingEnableConfirm) = 1) or
          (StrPos(Question, ExpectedCostPostingDisableConfirm) = 1) or
          (StrPos(Question, ConfirmServiceCost) = 1) or
          (StrPos(Question, ConfirmUndoSelectedShipment) = 1) or
          (StrPos(Question, ConfirmUndoConsumption) = 1),
          'Unexpected confirm dialog: ' + Question);
        Reply := true
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
        if StrPos(Msg, WarningMsg) = 1 then
            exit;
        Assert.IsTrue(StrPos(Msg, ExpectedMsg) = 1, 'Unexpected message dialog: ' + Msg)
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UndoShipmentFromServiceShipmentLinesHandler(var PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines")
    begin
        PostedServiceShipmentLines.UndoShipment.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandlerForLot(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        Commit();
        if SetHandler then
            ItemTrackingLines."Assign Lot No.".Invoke()
        else
            ItemTrackingLines."Select Entries".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines.ItemTrackingLines.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        Commit();
        if SetHandler then
            ItemTrackingLines."Assign Serial No.".Invoke()
        else
            ItemTrackingLines."Select Entries".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(CreateNewLotNo);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UndoDocumentConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        // Send Reply = TRUE for Confirmation Message.
        Reply := true;
    end;
}

