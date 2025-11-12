// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;

codeunit 136107 "Service Posting - Shipment"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Shipment] [Service]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        UnknownError: Label 'Unknown error.';
        WarningMsg: Label 'The field Automatic Cost Posting should not be set to Yes if field Use Legacy G/L Entry Locking in General Ledger Setup table is set to No because of possibility of deadlocks.';
        ExpectedMsg: Label 'Expected Cost Posting to G/L has been changed';
        ExpectedCostPostingEnableConfirm: Label 'If you enable the Expected Cost Posting to G/L';
        ExpectedCostPostingDisableConfirm: Label 'If you disable the Expected Cost Posting to G/L';
        WhseShptIsCreatedMsg: Label 'Warehouse Shipment Header has been created.', Locked = true;
        WhseShptIsNotCreatedErr: Label 'There are no warehouse shipment lines created.', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure ShipWithZeroQuantity()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 20882] An error "There is nothing to post" when Service Order is Posted as Ship with "Qty. to Ship" as 0.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item and "Qty. to Ship" as 0.
        Initialize();
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdateQtyToShipZero(ServiceLine);

        // [WHEN] Post the Service Order with Ship Option.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Error is generated as There is Nothing to Post when Service Order is posted as Ship with Qty. to Ship as 0.
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartialShipManual()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated as "Qty. to Ship" for shipping Item partly ("Auto cost Posting" and "Expected Cost Posting" are False).

        PartShipServiceOrder(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartialShipAutoEx()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated as "Qty. to Ship" for shipping Item partly ("Auto cost Posting" and "Expected Cost Posting" are True).

        PartShipServiceOrder(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartialShipAuto()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated as "Qty. to Ship" for shipping Item partly ("Auto cost Posting" is True and "Expected Cost Posting" is False).

        PartShipServiceOrder(true, false);
    end;

    local procedure PartShipServiceOrder(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);

        // 2. Exercise: Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Service Line, Service Shipment, Item Ledger Entry Quantity is updated as Qty To Ship after Posting.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartialShipResourceAndCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated as "Qty. to Ship" for shipping Resource, Cost partly and validating the Quantity.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource and Cost.
        Initialize();
        ExecuteUIHandlers();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        UpdatePartialQtyToShip(ServiceLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);

        // [WHEN] Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Service Line, Posted shipment document are created with correct Qty To Ship after Posting.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FullShipManual()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated as "Qty. to Ship" for shipping Items fully with the Ship option ("Auto cost Posting" and "Expected Cost Posting" are False).

        FullShipServiceOrder(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FullShipAutoEx()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated as "Qty. to Ship" for shipping Items fully with the Ship option ("Auto cost Posting" and "Expected Cost Posting" are True).

        FullShipServiceOrder(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FullShipAuto()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated as "Qty. to Ship" for shipping Items fully with the Ship option ("Auto cost Posting" is True and "Expected Cost Posting" is False).

        FullShipServiceOrder(true, false);
    end;

    local procedure FullShipServiceOrder(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdateQuantity(ServiceLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);

        // 2. Exercise: Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Service Line, Service Shipment, Item Ledger Entry Quantity is updated as Qty To Ship after Posting.
        // Item Ledger Entry is created correctly.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FullShipResourceAndCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated as "Qty. to Ship" for shipping Resources and Costs fully with the Ship option.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line, Update Quantity on Service Line.
        Initialize();
        ExecuteUIHandlers();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        UpdateQuantity(ServiceLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);

        // [WHEN] Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Service Line, Service Shipment is updated with correct Quantity as Qty To Ship after Posting..
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FullShipAndInvoiceManual()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated correctly after shipping Items fully with the Ship and Invoice option ("Auto cost Posting" and "Expected Cost Posting" are False).

        FullShipAndInvoiceServiceOrder(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FullShipAndInvoiceAutoEx()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated correctly after shipping Items fully with the Ship and Invoice option ("Auto cost Posting" and "Expected Cost Posting" are True).

        FullShipAndInvoiceServiceOrder(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FullShipAndInvoiceAuto()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated correctly after shipping Items fully with the Ship and Invoice option ("Auto cost Posting" is True and "Expected Cost Posting" is False).

        FullShipAndInvoiceServiceOrder(true, false);
    end;

    local procedure FullShipAndInvoiceServiceOrder(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdateQuantity(ServiceLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Service Line, Service Shipment, Item Ledger Entry Quantity is updated as Qty To Ship after Posting.
        VerifyQtyOnServShipAndInvoice(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FullShipAndInvoiceResourceCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated correctly after shipping Resources and Costs fully with the Ship and Invoice option.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource and
        // [GIVEN] "Auto cost Posting" and "Expected Cost Posting" are set to False).
        Initialize();
        ExecuteUIHandlers();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        UpdateQuantity(ServiceLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);

        // [WHEN] Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Service Line, Service Shipment Quantity is updated with correct Qty To Ship after Posting.
        VerifyQtyOnServShipAndInvoice(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipTwiceManual()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated correctly after Shipping Items with the Ship option in two steps ("Auto cost Posting" and "Expected Cost Posting" are False)

        PartShipTwiceServiceOrder(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipTwiceAutoEx()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated correctly after Shipping Items with the Ship option in two steps ("Auto cost Posting" and "Expected Cost Posting" are True)

        PartShipTwiceServiceOrder(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipTwiceAuto()
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated correctly after Shipping Items with the Ship option in two steps ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        PartShipTwiceServiceOrder(true, false);
    end;

    local procedure PartShipTwiceServiceOrder(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);

        // 2. Exercise: Post Service Order in Two parts as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Service Line, Service Shipment, Item Ledger Entry Quantity is updated as Qty To Ship after Posting.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartShipTwiceResourceAndCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 20882] "Quantity Shipped" is updated correctly after Ship of Service Order in two parts having Resource and Cost.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource and Cost.
        Initialize();
        ExecuteUIHandlers();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        UpdatePartialQtyToShip(ServiceLine);

        // [WHEN] Post Service Order in Two Parts as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Service Line, Service Shipment Quantity is updated as Qty To Ship after Posting.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceAndInvoiceManual()
    begin
        // [SCENARIO 20882] Shipping Items with the Ship option after posting partially with the Ship and Invoice Option ("Auto cost Posting" and "Expected Cost Posting" are False)

        ShipTwiceAndInvoice(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceAndInvoiceShipAutoEx()
    begin
        // [SCENARIO 20882] Shipping Items with the Ship option after posting partially with the Ship and Invoice Option ("Auto cost Posting" and "Expected Cost Posting" are True)

        ShipTwiceAndInvoice(true, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceAndInvoiceShipAuto()
    begin
        // [SCENARIO 20882] Shipping Items with the Ship option after posting partially with the Ship and Invoice Option ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        ShipTwiceAndInvoice(true, false);
    end;

    local procedure ShipTwiceAndInvoice(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item.

        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);

        // 2. Exercise: Post Service Order in two parts as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Service Line, Service Shipment, Item Ledger Entry Quantity is updated as Qty To Ship after Posting.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShipTwiceAndInvoiceResandCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 20882] Shipping Resources and Costs with Ship option after posting partially with Ship and Invoice option.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource and Cost.
        Initialize();
        ExecuteUIHandlers();
        SetupCostPostingInventory(true, false);
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        UpdatePartialQtyToShip(ServiceLine);

        // [WHEN] Post Service Order in two parts as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Service Line, Service Shipment are updated as Qty To Ship after Posting.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartShipInvoiceAndShipManual()
    begin
        // [SCENARIO 20882] Shipping Items previously partially Shipped and then Invoiced ("Auto cost Posting" and "Expected Cost Posting" are False)

        PartShipInvoiceAndShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipInvoiceAndShipAutoEx()
    begin
        // [SCENARIO 20882] Shipping Items previously partially Shipped and then Invoiced ("Auto cost Posting" and "Expected Cost Posting" are True)

        PartShipInvoiceAndShip(true, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartShipInvoiceAndShipAuto()
    begin
        // [SCENARIO 20882] Shipping Items previously partially Shipped and then Invoiced ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        PartShipInvoiceAndShip(true, false);
    end;

    local procedure PartShipInvoiceAndShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Post the Service Order
        // partially as Ship . Post the Service Order partially as Invoice.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        UpdatePartialQtyToInv(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 2. Exercise: Post Service Order fully as Ship.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line, Item Ledger Entry
        // and Value Entry are created with the Quantity equal to the quantity that was shipped second time.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
        VerifyValueEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartialShipInvoiceResourceCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 20882] Shipping Resources and Costs that were previously partially Shipped and then Invoiced.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource and Cost.
        // Post the Service Order partially as Ship . Post the Service Order partially as Invoice.
        Initialize();
        ExecuteUIHandlers();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        UpdatePartialQtyToInv(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // [WHEN] Post Service Order fully as Ship.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line is created
        // with the Quantity equal to the quantity that was shipped second time.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartShipAndInvoiceShipManual()
    begin
        // [SCENARIO 20882] Shipping Items that were partially posted earlier with the Ship and Invoice Option ("Auto cost Posting" and "Expected Cost Posting" are False)

        PartShipAndInvoiceShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipAndInvoiceShipAutoEx()
    begin
        // [SCENARIO 20882] Shipping Items that were partially posted earlier with the Ship and Invoice Option ("Auto cost Posting" and "Expected Cost Posting" are True)

        PartShipAndInvoiceShip(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipAndInvoiceShipAuto()
    begin
        // [SCENARIO 20882] Shipping Items that were partially posted earlier with the Ship and Invoice Option ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        PartShipAndInvoiceShip(true, false);
    end;

    local procedure PartShipAndInvoiceShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Post the Service Order
        // partially as Ship and Invoice.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartQtyToShipAndInvoice(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 2. Exercise: Post Service Order fully as Ship.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line, Item Ledger Entry
        // and Value Entry are created with the Quantity equal to the quantity that was shipped second time. Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
        VerifyValueEntry(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartShipAndInvoiceResourceCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 20882] Shipping Resources and Costs that were earlier partially posted with the Ship and Invoice Options.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource and Cost.
        // Post the Service Order partially as Ship and Invoice.
        Initialize();
        ExecuteUIHandlers();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        UpdatePartQtyToShipAndInvoice(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Post Service Order fully as Ship.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line is created
        // with the Quantity equal to the quantity that was shipped second time. Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipAndConsumeShipManual()
    begin
        // [SCENARIO 20882] Shipping Items that were partially Shipped and then Consumed ("Auto cost Posting" and "Expected Cost Posting" are False)

        PartShipAndConumeShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipAndConsumeShipAutoEx()
    begin
        // [SCENARIO 20882] Shipping Items that were partially Shipped and then Consumed ("Auto cost Posting" and "Expected Cost Posting" are True)

        PartShipAndConumeShip(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartShipAndConsumeShipAuto()
    begin
        // [SCENARIO 20882] Shipping Items that were partially Shipped and then Consumed ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        PartShipAndConumeShip(true, false);
    end;

    local procedure PartShipAndConumeShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Post the Service Order
        // partially as Ship and Consume.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartQtyToShipAndConume(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Post Service Order fully as Ship.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line, Item Ledger Entry
        // and Value Entry are created with the Quantity equal to the quantity that was shipped second time. Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
        VerifyValueEntry(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartShipAndConsumeResourceCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 20882] Shipping Resources that were partially Shipped and then Consumed.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource.
        // Post the Service Order partially as Ship and Consume.
        Initialize();
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForResource(ServiceLine, ServiceHeader);
        UpdatePartQtyToShipAndConume(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [WHEN] Post Service Order fully as Ship.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line is created
        // with the Quantity equal to the quantity that was shipped second time. Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartShipAndPartShipManual()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Partially Shipping the Items which were partially Shipped before, but reverted by Undo Shipment ("Auto cost Posting" and "Expected Cost Posting" are False)

        UndoPartShipAndPartShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartShipAndPartShipAutoEx()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Partially Shipping the Items which were partially Shipped before, but reverted by Undo Shipment ("Auto cost Posting" and "Expected Cost Posting" are True)

        UndoPartShipAndPartShip(true, true);
    end;

    local procedure UndoPartShipAndPartShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Post the Service Order
        // partially as Ship. Undo Shipment.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        CreateServiceItemLine(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // 2. Exercise: Post Service Order partially as Ship again.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Quantity Shipped on Service Line is equal to the Quantity that was shipped for Service Line. Service Shipment
        // Line, Item Ledger Entry and Value Entry are created with the Quantity equal to the quantity that was shipped second time.
        // Verify Service Ledger Entry.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
        VerifyValueEntry(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartialAndPartShipAuto()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Partially Shipping the Items which were partially Shipped before, but reverted by Undo Shipment ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        UndoPartShipAndPartShip(true, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartUndoShipResourceAndCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Partially Shipping the Resources, Costs, G/L Accounts which were partially Shipped before, but reverted by Undo Shipment.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource, Cost and G/L Account.
        // [GIVEN] Post the Service Order partially as Ship. Undo Shipment.
        Initialize();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        CreateServiceLineForGLAccount(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // [WHEN] Post Service Order partially as Ship again.
        UpdateFullyOnlyQtyToShip(ServiceLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Quantity Shipped on Service Line is equal to the Quantity that was shipped for Service Line. Service Shipment Line is
        // created with the Quantity equal to the quantity that was shipped second time. Verify Service Ledger Entry.
        VerifyUpdatedShipQtyAfterShip(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartShipAndFullShipManual()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Fully Shipping the Items which were partially Shipped before, but reverted by Undo Shipment ("Auto cost Posting" and "Expected Cost Posting" are False)

        UndoPartShipAndFullShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartShipAndFullShipAutoEx()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Fully Shipping the Items which were partially Shipped before, but reverted by Undo Shipment ("Auto cost Posting" and "Expected Cost Posting" are True)

        UndoPartShipAndFullShip(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartShipAndFullShipAuto()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Fully Shipping the Items which were partially Shipped before, but reverted by Undo Shipment ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        UndoPartShipAndFullShip(true, false);
    end;

    local procedure UndoPartShipAndFullShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as TRUE and Expected Cost Posting to G/L as TRUE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Post the Service Order
        // partially as Ship. Undo Shipment.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // 2. Exercise: Post Service Order fully as Ship again.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line, Item Ledger Entry
        // and Value Entry are created with the Quantity equal to the quantity that was shipped second time. Verify existence of G/L Entry.
        // Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
        VerifyValueEntry(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoShipFullResourceAndCost()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Fully Shipping the Resources, Costs, G/L Accounts which were partially Shipped before, but reverted by Undo Shipment.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource, Cost and G/L Account.
        // [GIVEN] Post the Service Order partially as Ship. Undo Shipment.
        Initialize();
        ExecuteUIHandlers();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        CreateServiceLineForGLAccount(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // [WHEN] Post Service Order fully as Ship again.
        UpdateFullyOnlyQtyToShip(ServiceLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line is
        // created with the Quantity equal to the quantity that was shipped second time. Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoFullShipAndShipManual()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Fully Shipping the Items which were fully Shipped before, but reverted by Undo Shipment ("Auto cost Posting" and "Expected Cost Posting" are False)

        UndoFullShipAndShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoFullShipAndShipAutoEx()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Fully Shipping the Items which were fully Shipped before, but reverted by Undo Shipment ("Auto cost Posting" and "Expected Cost Posting" are True)

        UndoFullShipAndShip(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoFullShipAndShipAuto()
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Fully Shipping the Items which were fully Shipped before, but reverted by Undo Shipment ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        UndoFullShipAndShip(true, false);
    end;

    local procedure UndoFullShipAndShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Post the Service Order
        // fully as Ship. Undo Shipment.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdateQuantity(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // 2. Exercise: Post Service Order fully as Ship again.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment
        // Line, Item Ledger Entry and Value Entry are created with the Quantity equal to the quantity that was shipped second time.
        // Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
        VerifyValueEntry(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoShipResourceCostGL()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 20882] Fully Shipping the Resources, Costs, G/L Accounts which were fully Shipped before, but reverted by Undo Shipment.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource, Cost and G/L Account.
        // [GIVEN] Post the Service Order fully as Ship. Undo Shipment.
        Initialize();
        ExecuteUIHandlers();
        CreateServiceOrderResAndCost(ServiceHeader, ServiceLine);
        CreateServiceLineForGLAccount(ServiceLine, ServiceHeader);
        UpdateQuantity(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // [WHEN] Post Service Order fully as Ship again.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line is
        // created with the Quantity equal to the quantity that was shipped second time. Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartConsumeFullShipManual()
    begin
        // [FEATURE] [Undo Consumption]
        // [SCENARIO 20882] Partially Shipping the Items which were Consumed before, but reverted by Undo Consumption ("Auto cost Posting" and "Expected Cost Posting" are False)

        UndoPartConsumeFullyShip(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartConsumeFullShipAutoEx()
    begin
        // [FEATURE] [Undo Consumption]
        // [SCENARIO 20882] Partially Shipping the Items which were Consumed before, but reverted by Undo Consumption ("Auto cost Posting" and "Expected Cost Posting" are True)

        UndoPartConsumeFullyShip(true, true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartConsumeFullShipAuto()
    begin
        // [FEATURE] [Undo Consumption]
        // [SCENARIO 20882] Partially Shipping the Items which were Consumed before, but reverted by Undo Consumption ("Auto cost Posting" is True and "Expected Cost Posting" is False)

        UndoPartConsumeFullyShip(true, false)
    end;

    local procedure UndoPartConsumeFullyShip(AutomaticCostPosting: Boolean; ExpectedCostPostingToGL: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // 1. Setup: Setup Automatic Cost Posting as FALSE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item. Post the Service Order
        // partially as Ship and Consume. Undo Consumption.
        Initialize();
        SetupCostPostingInventory(AutomaticCostPosting, ExpectedCostPostingToGL);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToConsume(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        UndoConsumption(ServiceHeader."No.");

        // 2. Exercise: Post Service Order fully as Ship.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment
        // Line, Item Ledger Entry and Value Entry are created with the Quantity equal to the quantity that was shipped.
        // Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyQtyOnItemLedgerEntry(TempServiceLine);
        VerifyValueEntry(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumeResourceCostAuto()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [FEATURE] [Undo Consumption]
        // [SCENARIO 20882] Partially Shipping the Resources which were partially Shipped and Consumed before, but reverted by Undo Consumption.

        // [GIVEN] Setup Automatic Cost Posting as TRUE and Expected Cost Posting to G/L as FALSE on Inventory Setup.
        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Resource.
        // [GIVEN] Post the Service Order partially as Ship and Consume. Undo consumption.
        Initialize();
        SetupCostPostingInventory(true, false);
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForResource(ServiceLine, ServiceHeader);

        UpdatePartialQtyToConsume(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        UndoConsumption(ServiceHeader."No.");

        // [WHEN] Post Service Order fully as Ship.
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Quantity Shipped on Service Line is equal to the Quantity of Service Line. Service Shipment Line is created with the
        // Quantity equal to the quantity that was shipped. Verify Service Ledger Entry.
        VerifyQuantityAfterFullShipmnt(TempServiceLine);
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
        VerifyServiceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyShipOrderWithItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 172912] Service Shipment Line after Posting Service Order Partially as Ship with Item.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item.
        Initialize();
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);
        GetServiceLines(ServiceLine, ServiceHeader."No.");
        CopyServiceLines(TempServiceLine, ServiceLine);

        // [WHEN] Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Verify Quantity on Service Shipment Line is updated as Qty To Ship on Service Line.
        VerifyQtyOnServiceShipmentLine(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyInvoiceOrderWithItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 172912] Service Invoice Line after Posting Service Order Partially as Invoice with Item.

        // [GIVEN] Create Service Order - Service Header, Service Item, Service Item Line, Service Line with Type as Item.
        // [GIVEN] Post the Service Order partially as Ship.
        Initialize();
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdatePartialQtyToShip(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [WHEN] Post the Service Order partially as Invoice.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        UpdatePartialQtyToInv(ServiceLine);
        GetServiceLines(ServiceLine, ServiceHeader."No.");
        CopyServiceLines(TempServiceLine, ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // [THEN] Verify Quantity on Service Invoice Line is updated as Qty To Invoice on Service Line.
        VerifyServiceInvoiceLine(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithBinCode()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [FEATURE] [Bin Content]
        // [SCENARIO 235027] Bin Content after Posting Item Journal Line and Service Order Posting as Ship & Consume with Item and Bin.

        // [GIVEN] Create New Location, Create New Bin, Create New Item, Create Item Journal Line, Post Item Journal.
        // Create Service Order.
        Initialize();
        CreateLocationWithBinMandatory(Location);
        LibraryWarehouse.CreateBin(
          Bin,
          Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))),
          '',
          '');
        LibraryInventory.CreateItem(Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        CreateItemJournalLineWithBin(ItemJournalLine, ItemJournalBatch, Bin, Item."No.");
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
        CreateServiceOrderWithBinCode(ServiceHeader, Bin, Item."No.", ItemJournalLine.Quantity);
        GetServiceLines(ServiceLine, ServiceHeader."No.");
        CopyServiceLines(TempServiceLine, ServiceLine);

        // [WHEN] Post Service Order with Ship & Consume.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] Verify Bin Content.
        VerifyBinContent(TempServiceLine, ItemJournalLine.Quantity - TempServiceLine."Qty. to Consume");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UndoConsumptionWithBinCode()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Bin Content] [Undo Consumption]
        // [SCENARIO 235027] Bin Content, Service Shipment Line and Warehouse Entry after Posting Item Journal Line and Service Order Posting as Ship & Consume and Undo Consumption with Item and Bin.

        // [GIVEN] Create New Location, Create New Bin, Create New Item, Create Item Journal Line, Post Item Journal.
        // [GIVEN] Create Service Order, Post Service Order with Ship & Consume.
        Initialize();
        CreateLocationWithBinMandatory(Location);
        LibraryWarehouse.CreateBin(
          Bin,
          Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))),
          '',
          '');
        LibraryInventory.CreateItem(Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        CreateItemJournalLineWithBin(ItemJournalLine, ItemJournalBatch, Bin, Item."No.");
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
        CreateServiceOrderWithBinCode(ServiceHeader, Bin, Item."No.", ItemJournalLine.Quantity);
        GetServiceLines(ServiceLine, ServiceHeader."No.");
        CopyServiceLines(TempServiceLine, ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [WHEN] Undo Consumption.
        UndoConsumption(ServiceHeader."No.");

        // [THEN] Verify Bin Content, Service Shipment Line and Warehouse Entry.
        VerifyBinContent(TempServiceLine, TempServiceLine.Quantity);
        VerifyServiceShipmentLine(TempServiceLine);
        VerifyWarehouseEntry(TempServiceLine, WarehouseEntry."Entry Type"::"Positive Adjmt.", 1); // 1 for Sign Factor
        VerifyWarehouseEntry(TempServiceLine, WarehouseEntry."Entry Type"::"Negative Adjmt.", -1); // -1 for Sign Factor
        VerifyItemLedgerAndValueEntriesAfterUndoConsumption(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntryWithShipAndConsume()
    var
        ServiceHeader: Record "Service Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warranty]
        // [SCENARIO 305893] Quantity copied to Warranty Ledger Entry when Service Order Posted with Ship and Consume.

        // [GIVEN]
        Initialize();

        // [WHEN] Create and Post Service Order with Ship And Consume.
        Quantity := CreateAndPostServiceOrderWithWarranty(ServiceHeader);

        // [THEN] Verify that the line exist with Quantity on Warranty Ledger Entry after Consumption.
        VerifyWarrantyLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntryWithUndoConsumption()
    var
        ServiceHeader: Record "Service Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warranty] [Undo Consumption]
        // [SCENARIO 305893] the Quantity is updated on Warranty Ledger Entry after UndoConsumption.

        // [GIVEN] Create and Post Service Order with Ship And Consume.
        Initialize();
        Quantity := CreateAndPostServiceOrderWithWarranty(ServiceHeader);

        // [WHEN] Undo Consumption.
        UndoConsumption(ServiceHeader."No.");

        // [THEN] Verify that the line exist with Negative Quantity on Warranty Ledger Entry after doing Undo Consumption.
        VerifyWarrantyLedgerEntry(ServiceHeader."No.", ServiceHeader."Customer No.", -1 * Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePostBufferTemporary()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServicePostingShipment: Codeunit "Service Posting - Shipment";
    begin
        // [SCENARIO 379210] Invoice Post Buffer table must be temporary when posting service documents

        Initialize();
        BindSubscription(ServicePostingShipment);

        // [GIVEN] Service order with one line
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdateQuantity(ServiceLine);

        // [WHEN] Service Order is being posted
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posting engine uses Invoice Post Buffer table as temporary
        // Verification done inside the VerifyInvPostBufferTemporary
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoMultilineConsumptionWithBinCode()
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        Item: array[3] of Record Item;
        Bin: array[3] of Record Bin;
        Qty: array[3] of Decimal;
        ServiceItemLineNo: Integer;
        i: Integer;
    begin
        // [FEATURE] [Bin Content] [Undo Consumption]
        // [SCENARIO 379933] Undo Consumption works for mulitiline Serice Order with Bin content
        Initialize();

        // [GIVEN] Create New Location with Bin mandatory
        CreateLocationWithBinMandatory(Location);

        // [GIVEN] Create 3 new Bins, 3 new Items, make 3 positive adjustments for Items to be used in service order
        CreateBinsAndItems(Location.Code, Bin, Item);
        MakePosAdjForItemsWithBins(Bin, Item, Qty);

        // [GIVEN] Create Service Order with Service Item
        ServiceItemLineNo := CreateServiceHeaderWithServiceItemLine(ServiceHeader, Location.Code);
        // [GIVEN] Create 3 service lines with new Items and Bins
        for i := 1 to ArrayLen(Bin) do
            CreateServiceLineForItemWithBin(ServiceHeader, ServiceItemLineNo, Bin[i], Item[i]."No.", Qty[i]);

        // [GIVEN] Post Service Order with Ship & Consume.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [WHEN] Undo Consumption.
        UndoConsumption(ServiceHeader."No.");

        // [THEN] Verify that 3 Service Shipment Lines for undo consumption have been created
        VerifyServiceShipmentLinesAfterUndoConsumption(Item, Bin, Qty);
    end;

    [Test]
    [HandlerFunctions('CreateWhseShpt_MessageHandler,WarehouseShipmentPageHandler')]
    [Scope('OnPrem')]
    procedure WhseShptFromServiceOrderWithGreenLocationAndBlankQtyToConsume()
    var
        ServiceHeader: Record "Service Header";
        DummyWarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Warehouse]
        // [SCENARIO 380057] Warehouse Shipment is created for Service Order with Green location, item and zero "Qty. to Consume"
        Initialize();

        // [GIVEN] Service Order with item on Green location ("Require Shipment" = TRUE), "Qty. to Consume" = 0
        CreateServiceOrderWithGreenLocationAndQtyToConsume(ServiceHeader, 0);
        // [GIVEN] Perform "Release to Ship" action
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [WHEN] Perform "Create Whse. Shipment" action
        LibraryVariableStorage.Enqueue(StrSubstNo('%1 %2', 1, WhseShptIsCreatedMsg));
        CreateWhseShipmentFromServiceHeader(ServiceHeader);
        // CreateWhseShpt_MessageHandler

        // [THEN] Warehouse shipment has been created
        // WarehouseShipmentPageHandler
        DummyWarehouseShipmentLine.SetRange("Location Code", ServiceHeader."Location Code");
        Assert.RecordIsNotEmpty(DummyWarehouseShipmentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoWhseShptFromServiceOrderWithGreenLocationAndQtyToConsume()
    var
        ServiceHeader: Record "Service Header";
        DummyWarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Warehouse]
        // [SCENARIO 380057] Warehouse Shipment is not created for Service Order with Green location, item and "Qty. to Consume"
        Initialize();

        // [GIVEN] Service Order with item on Green location ("Require Shipment" = TRUE), "Qty. to Consume" <> 0
        CreateServiceOrderWithGreenLocationAndQtyToConsume(ServiceHeader, LibraryRandom.RandInt(10));
        // [GIVEN] Perform "Release to Ship" action
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [WHEN] Perform "Create Whse. Shipment" action
        LibraryVariableStorage.Enqueue(StrSubstNo('%1 %2', 0, WhseShptIsCreatedMsg));
        asserterror CreateWhseShipmentFromServiceHeader(ServiceHeader);

        // [THEN] Warehouse shipment is not created
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(WhseShptIsNotCreatedErr);

        DummyWarehouseShipmentLine.SetRange("Location Code", ServiceHeader."Location Code");
        Assert.RecordIsEmpty(DummyWarehouseShipmentLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReversedLedgerEntriesOnUndoShipmentArePostedWithOriginalPostingDate()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [FEATURE] [Undo Shipment] [Service Shipment]
        // [SCENARIO 211697] Undoing shipment should create item ledger entries and resource ledger entries with the same posting date as on the original service shipment line.
        Initialize();

        // [GIVEN] Service Order with posting date = WORKDATE.
        CreateServiceOrder(ServiceHeader);

        // [GIVEN] Service lines with item and resource.
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        CreateServiceLineForResource(ServiceLine, ServiceHeader);

        // [GIVEN] The service lines are set to be partially shipped.
        UpdatePartialQtyToShip(ServiceLine);

        // [GIVEN] Posting Date on all service lines is set to "D" > WORKDATE.
        UpdatePostingDateOnServiceLines(ServiceLine, LibraryRandom.RandDateFrom(ServiceHeader."Posting Date", 30));
        SaveServiceLineInTempTable(TempServiceLine, ServiceLine);

        // [GIVEN] The service lines are posted with Ship option.
        LibraryService.PostServiceOrderWithPassedLines(ServiceHeader, TempServiceLine, true, false, false);

        // [WHEN] Undo Shipment.
        LibraryService.UndoShipmentLinesByServiceOrderNo(TempServiceLine."Document No.");

        // [THEN] Posting Date on reversed item and resource ledger entries is equal to "D".
        VerifyItemEntriesAfterUndoShipment(TempServiceLine."Document No.");
        VerifyResourceEntriesAfterUndoShipment(TempServiceLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountryRegionItemLedgerEntryPostServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        CountryRegion: Record "Country/Region";
        ItemLedgerDocType: Enum "Item Ledger Document Type";
    begin
        // [SCENARIO 378446] Country/Region Code on Item Ledger Entry when post Service Order with Ship-to Country/Region Code different from Country/Region Code.
        Initialize();

        // [GIVEN] Service Order with Ship-to Country/Region Code = 'R' which is not equal to Country/Region Code.
        CreateServiceOrder(ServiceHeader);
        LibraryERM.CreateCountryRegion(CountryRegion);
        UpdateCountryRegionOnServiceHeader(ServiceHeader, CountryRegion.Code);
        LibraryERM.CreateCountryRegion(CountryRegion);
        UpdateShipToCountryRegionOnServiceHeader(ServiceHeader, CountryRegion.Code);

        // [GIVEN] Service Line with Item.
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdateQuantity(ServiceLine);

        // [WHEN] Post Service Order as Invoice and Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Item Ledger Entry is created, it has Country/Region Code = 'R'.
        VerifyCountryRegionCodeOnItemLedgerEntry(ServiceHeader."No.", ItemLedgerDocType::"Service Shipment", CountryRegion.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountryRegionItemLedgerEntryPostServiceOrderBlankShipToCntrRgnCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        CountryRegion: Record "Country/Region";
        ItemLedgerDocType: Enum "Item Ledger Document Type";
    begin
        // [SCENARIO 378446] Country/Region Code on Item Ledger Entry when post Service Order with blank Ship-to Country/Region Code and nonblank Country/Region Code.
        Initialize();

        // [GIVEN] Service Order with blank Ship-to Country/Region Code and nonblank Country/Region Code = 'C'.
        CreateServiceOrder(ServiceHeader);
        LibraryERM.CreateCountryRegion(CountryRegion);
        UpdateCountryRegionOnServiceHeader(ServiceHeader, CountryRegion.Code);
        UpdateShipToCountryRegionOnServiceHeader(ServiceHeader, '');

        // [GIVEN] Service Line with Item.
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdateQuantity(ServiceLine);

        // [WHEN] Post Service Order as Invoice and Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Item Ledger Entry is created, it has Country/Region Code = 'C'.
        VerifyCountryRegionCodeOnItemLedgerEntry(ServiceHeader."No.", ItemLedgerDocType::"Service Shipment", CountryRegion.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountryRegionItemLedgerEntryPostServiceOrderBlankCntrRgnCodes()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemLedgerDocType: Enum "Item Ledger Document Type";
    begin
        // [SCENARIO 378446] Country/Region Code on Item Ledger Entry when post Service Order with blank Ship-to Country/Region Code and blank Country/Region Code.
        Initialize();

        // [GIVEN] Service Order with blank Ship-to Country/Region Code and blank Country/Region Code.
        CreateServiceOrder(ServiceHeader);
        UpdateCountryRegionOnServiceHeader(ServiceHeader, '');
        UpdateShipToCountryRegionOnServiceHeader(ServiceHeader, '');

        // [GIVEN] Service Line with Item.
        CreateServiceLineForItem(ServiceLine, ServiceHeader);
        UpdateQuantity(ServiceLine);

        // [WHEN] Post Service Order as Invoice and Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Item Ledger Entry is created, it has blank Country/Region Code.
        VerifyCountryRegionCodeOnItemLedgerEntry(ServiceHeader."No.", ItemLedgerDocType::"Service Shipment", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountryRegionItemLedgerEntryPostServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
        CountryRegion: Record "Country/Region";
        ItemLedgerDocType: Enum "Item Ledger Document Type";
        CountryRegionCode: Code[10];
    begin
        // [SCENARIO 378446] Country/Region Code on Item Ledger Entry when post Service Credit Memo with Ship-to Country/Region Code different from Country/Region Code.
        Initialize();

        // [GIVEN] Service Credit Memo with Ship-to Country/Region Code = 'R' which is not equal to Country/Region Code = 'C'.
        CreateServiceCreditMemo(ServiceHeader);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegionCode := CountryRegion.Code;
        UpdateCountryRegionOnServiceHeader(ServiceHeader, CountryRegionCode);
        LibraryERM.CreateCountryRegion(CountryRegion);
        UpdateShipToCountryRegionOnServiceHeader(ServiceHeader, CountryRegion.Code);

        // [WHEN] Post Service Credit Memo as Invoice and Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Item Ledger Entry is created, it has Country/Region Code = 'C'.
        VerifyCountryRegionCodeOnItemLedgerEntry(ServiceHeader."No.", ItemLedgerDocType::"Service Credit Memo", CountryRegionCode);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Posting - Shipment");
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Posting - Shipment");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Posting - Shipment");
    end;

    local procedure CopyServiceLines(var ServiceLineOld: Record "Service Line"; var ServiceLine: Record "Service Line")
    begin
        repeat
            ServiceLineOld.Init();
            ServiceLineOld := ServiceLine;
            ServiceLineOld.Insert();
        until ServiceLine.Next() = 0
    end;

    local procedure CreateBinsAndItems(LocationCode: Code[10]; var Bin: array[3] of Record Bin; var Item: array[3] of Record Item)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Bin) do begin
            LibraryWarehouse.CreateBin(
              Bin[i],
              LocationCode,
              CopyStr(
                LibraryUtility.GenerateRandomCode(Bin[i].FieldNo(Code), DATABASE::Bin),
                1,
                LibraryUtility.GetFieldLength(DATABASE::Bin, Bin[i].FieldNo(Code))),
              '',
              '');
            LibraryInventory.CreateItem(Item[i]);
        end;
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header")
    begin
        // Create a new Service Order - Service Header, Service Item, Service Item Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        CreateServiceItemLine(ServiceHeader);
    end;

    local procedure CreateServiceOrderResAndCost(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
        // Create a new Service Order - Service Header, Service Item, Service Item Line.
        CreateServiceOrder(ServiceHeader);
        CreateServiceLineForResource(ServiceLine, ServiceHeader);
        CreateServiceLineForCost(ServiceLine, ServiceHeader);
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceItemLine(ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        end;
    end;

    local procedure CreateServiceHeaderWithServiceItemLine(var ServiceHeader: Record "Service Header"; LocationCode: Code[10]): Integer
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        UpdateLocationOnServiceHeader(ServiceHeader, LocationCode);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        exit(ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceLineForCost(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceCost: Record "Service Cost";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        LibraryService.FindServiceCost(ServiceCost);
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
            ServiceCost.Next();
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

    local procedure CreateServiceLineForItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceLineForResource(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceLineForItemWithBin(ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer; Bin: Record Bin; ItemNo: Code[20]; var Quantity: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateItemBinAndQuantity(ServiceLine, Bin, ServiceItemLineNo, Quantity);
        Quantity := ServiceLine."Qty. to Consume";
    end;

    local procedure CreateLocationWithBinMandatory(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
    end;

    local procedure CreateItemJournalLineWithBin(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; Bin: Record Bin; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Validate("Location Code", Bin."Location Code");
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateServiceOrderWithBinCode(var ServiceHeader: Record "Service Header"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        UpdateLocationOnServiceHeader(ServiceHeader, Bin."Location Code");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateItemBinAndQuantity(ServiceLine, Bin, ServiceItemLine."Line No.", Quantity);
    end;

    local procedure CreateServiceOrderWithGreenLocationAndQtyToConsume(var ServiceHeader: Record "Service Header"; QtyToConsume: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        UpdateLocationOnServiceHeader(ServiceHeader, Location.Code);

        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        CreateServiceLine(
          ServiceHeader, ServiceLine, LibraryInventory.CreateItemNo(), ServiceItem."No.",
          QtyToConsume + LibraryRandom.RandInt(10), QtyToConsume);
    end;

    local procedure CreateAndPostServiceOrderWithWarranty(var ServiceHeader: Record "Service Header") Quantity: Decimal
    var
        Item: Record Item;
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
    begin
        CreateServiceItemWithWarrantyStartingDate(ServiceItem);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateServiceLine(ServiceHeader, ServiceLine, Item."No.", ServiceItemLine."Service Item No.", Quantity, Quantity);  // Qt. to consume should be equal to Quantity.
        CreateServiceLine(ServiceHeader, ServiceLine, Item."No.", ServiceItemLine."Service Item No.", Quantity, 0);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        exit(Quantity);
    end;

    local procedure CreateServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ItemNo: Code[20]; ServiceItemNo: Code[20]; Quantity: Decimal; QuantityToConsume: Decimal)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Consume", QuantityToConsume);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceItemWithWarrantyStartingDate(var ServiceItem: Record "Service Item")
    begin
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        ServiceItem.Validate("Warranty Starting Date (Parts)", WorkDate());
        ServiceItem.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateWhseShipmentFromServiceHeader(ServiceHeader: Record "Service Header")
    var
        ServGetSourceDocOutbound: Codeunit "Serv. Get Source Doc. Outbound";
    begin
        ServGetSourceDocOutbound.CreateFromServiceOrder(ServiceHeader);
    end;

    local procedure GetServiceLines(var ServiceLine: Record "Service Line"; DocumentNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
    end;

    local procedure MakePosAdjForItemsWithBins(var Bin: array[3] of Record Bin; var Item: array[3] of Record Item; var Qty: array[3] of Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        i: Integer;
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        for i := 1 to ArrayLen(Bin) do begin
            CreateItemJournalLineWithBin(ItemJournalLine, ItemJournalBatch, Bin[i], Item[i]."No.");
            Qty[i] := ItemJournalLine.Quantity;
        end;

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure SaveServiceLineInTempTable(var TempServiceLine: Record "Service Line" temporary; ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
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

    local procedure UndoShipment(ServiceDocumentNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceDocumentNo);
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);
    end;

    local procedure UndoConsumption(ServiceDocumentNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceDocumentNo);
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);
    end;

    local procedure UpdatePartialQtyToInv(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Qty. to Invoice", ServiceLine."Quantity Shipped" * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartQtyToShipAndConume(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartQtyToShipAndInvoice(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Validate("Qty. to Invoice", ServiceLine."Qty. to Ship");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateFullyOnlyQtyToShip(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQuantity(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQtyToShipZero(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
            ServiceLine.Validate("Qty. to Ship", 0);  // Value 0 is important for the test case.
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartialQtyToShip(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartialQtyToConsume(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateLocationOnServiceHeader(var ServiceHeader: Record "Service Header"; LocationCode: Code[10])
    begin
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateItemBinAndQuantity(var ServiceLine: Record "Service Line"; Bin: Record Bin; ServiceItemLineNo: Integer; Quantity: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate("Bin Code", Bin.Code);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Ship", Quantity * LibraryUtility.GenerateRandomFraction());
        ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship");
        ServiceLine.Modify(true);
    end;

    local procedure UpdatePostingDateOnServiceLines(var ServiceLine: Record "Service Line"; NewPostingDate: Date)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Posting Date", NewPostingDate);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateShipToCountryRegionOnServiceHeader(var ServiceHeader: Record "Service Header"; CountryRegionCode: Code[10])
    begin
        ServiceHeader.Validate("Ship-to Country/Region Code", CountryRegionCode);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateCountryRegionOnServiceHeader(var ServiceHeader: Record "Service Header"; CountryRegionCode: Code[10])
    begin
        ServiceHeader.Validate("Country/Region Code", CountryRegionCode);
        ServiceHeader.Modify(true);
    end;

    local procedure VerifyBinContent(ServiceLine: Record "Service Line"; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", ServiceLine."Location Code");
        BinContent.SetRange("Bin Code", ServiceLine."Bin Code");
        BinContent.FindFirst();
        BinContent.TestField("Item No.", ServiceLine."No.");
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Quantity);
    end;

    local procedure VerifyServiceInvoiceLine(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        repeat
            ServiceInvoiceLine.SetRange("Service Item No.", TempServiceLine."Service Item No.");
            ServiceInvoiceLine.FindFirst();
            ServiceInvoiceLine.TestField("No.", TempServiceLine."No.");
            ServiceInvoiceLine.TestField(Quantity, TempServiceLine."Qty. to Invoice");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyUpdatedShipQtyAfterShip(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify that the value of the field Quantity Shipped of the new Service Line is equal to the value of the field
        // Qty. to Ship of the relevant old Service Line.
        TempServiceLine.FindSet();
        repeat
            ServiceLine.Get(TempServiceLine."Document Type", TempServiceLine."Document No.", TempServiceLine."Line No.");
            ServiceLine.TestField("Quantity Shipped", TempServiceLine."Qty. to Ship" + TempServiceLine."Quantity Shipped");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyQtyOnServShipAndInvoice(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Verify that the value of the field Quantity Invoiced of the Service Shipment Line is equal to the value of the field Qty. to
        // Invoice of the relevant Service Line.
        TempServiceLine.FindSet();
        ServiceShipmentLine.SetRange("Order No.", TempServiceLine."Document No.");
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", TempServiceLine."Line No.");
            ServiceShipmentLine.FindFirst();
            ServiceShipmentLine.TestField("Quantity Invoiced", TempServiceLine."Qty. to Invoice");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyQuantityAfterFullShipmnt(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify that the Qty. to Ship is 0 and the value of the field Quantity Shipped in Service Line is equal to the value of the field
        // Quantity of the Service Line.
        TempServiceLine.FindSet();
        repeat
            ServiceLine.Get(TempServiceLine."Document Type", TempServiceLine."Document No.", TempServiceLine."Line No.");
            ServiceLine.TestField("Quantity Shipped", ServiceLine.Quantity);
            ServiceLine.TestField("Qty. to Ship", 0);
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyQtyOnServiceShipmentLine(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Verify that the values of the fields Qty. Shipped Not Invoiced and Quantity of Service Shipment Line are equal to the value of
        // the field Qty. to Ship of the relevant Service Line.
        TempServiceLine.FindSet();
        ServiceShipmentLine.SetRange("Order No.", TempServiceLine."Document No.");
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", TempServiceLine."Line No.");
            ServiceShipmentLine.FindLast();  // Find the Shipment Line for the second shipment.
            ServiceShipmentLine.TestField("Qty. Shipped Not Invoiced", TempServiceLine."Qty. to Ship");
            ServiceShipmentLine.TestField(Quantity, TempServiceLine."Qty. to Ship");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyQtyOnItemLedgerEntry(var TempServiceLine: Record "Service Line" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify that the value of the field Quantity of the Item Ledger Entry is equal to the value of the field Qty. to Ship of the
        // relevant Service Line.
        TempServiceLine.FindSet();
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", TempServiceLine."Document No.");
        repeat
            ItemLedgerEntry.SetRange("Document Line No.", TempServiceLine."Line No.");
            ItemLedgerEntry.FindLast();  // Find the Item Ledger Entry for the second shipment.
            ItemLedgerEntry.TestField(Quantity, -TempServiceLine."Qty. to Ship (Base)");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyCountryRegionCodeOnItemLedgerEntry(OrderNo: Code[20]; DocumentType: Enum "Item Ledger Document Type"; CountryRegionCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", OrderNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Country/Region Code", CountryRegionCode);
    end;

    local procedure VerifyValueEntry(var TempServiceLine: Record "Service Line" temporary)
    var
        ValueEntry: Record "Value Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Verify that the value ofthe field Valued Quantity of the Value Entry is equal to the value of the field Qty. to Ship of
        // the relevant Service Line.
        TempServiceLine.FindSet();
        ServiceShipmentHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceShipmentHeader.FindLast();  // Find the second shipment.
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Service Shipment");
        ValueEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        repeat
            ValueEntry.SetRange("Document Line No.", TempServiceLine."Line No.");
            ValueEntry.FindFirst();
            ValueEntry.TestField("Valued Quantity", -TempServiceLine."Qty. to Ship (Base)");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Verify that the Service Ledger Entry created corresponds with the relevant Service Line by matching the fields No., Posting Date
        // and Bill-to Customer No.
        TempServiceLine.FindSet();
        ServiceShipmentHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceShipmentHeader.FindLast();  // Find the second shipment.
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        repeat
            ServiceLedgerEntry.SetRange("Document Line No.", TempServiceLine."Line No.");
            ServiceLedgerEntry.FindFirst();
            ServiceLedgerEntry.TestField("No.", TempServiceLine."No.");
            ServiceLedgerEntry.TestField("Posting Date", TempServiceLine."Posting Date");
            ServiceLedgerEntry.TestField("Bill-to Customer No.", TempServiceLine."Bill-to Customer No.");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceShipmentLine(ServiceLine: Record "Service Line")
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentLine.FindLast();
        ServiceShipmentLine.TestField("Location Code", ServiceLine."Location Code");
        ServiceShipmentLine.TestField("Bin Code", ServiceLine."Bin Code");
        ServiceShipmentLine.TestField(Quantity, -ServiceLine."Qty. to Consume");
    end;

    local procedure VerifyWarehouseEntry(ServiceLine: Record "Service Line"; EntryType: Option; SignFactor: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Serv. Order");
        WarehouseEntry.SetRange("Source No.", ServiceLine."Document No.");
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Location Code", ServiceLine."Location Code");
        WarehouseEntry.TestField("Bin Code", ServiceLine."Bin Code");
        WarehouseEntry.TestField("Item No.", ServiceLine."No.");
        WarehouseEntry.TestField(Quantity, ServiceLine."Qty. to Consume" * SignFactor);
        WarehouseEntry.TestField("Qty. (Base)", ServiceLine."Qty. to Consume" * SignFactor);
    end;

    local procedure VerifyItemLedgerAndValueEntriesAfterUndoConsumption(var TempServiceLineBeforePosting: Record "Service Line" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RelatedItemLedgerEntry: Record "Item Ledger Entry";
        Tolerance: Decimal;
    begin
        // Verify that the value of the field Quantity of the Item Ledger Entry is equal to the value of the field Qty. to Ship of the
        // relevant Service Line.
        Tolerance := 0.000005;
        TempServiceLineBeforePosting.SetRange(Type, TempServiceLineBeforePosting.Type::Item);
        TempServiceLineBeforePosting.FindSet();
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", TempServiceLineBeforePosting."Document No.");
        ItemLedgerEntry.SetRange(Correction, false);
        repeat
            ItemLedgerEntry.SetRange("Order Line No.", TempServiceLineBeforePosting."Line No.");
            ItemLedgerEntry.FindLast();  // Find the Item Ledger Entry for the second action.
            Assert.AreNearlyEqual(
              ItemLedgerEntry.Quantity, -TempServiceLineBeforePosting."Qty. to Consume", Tolerance,
              'Quantity and Quantity Consumed are nearly equal');
            Assert.AreNearlyEqual(
              ItemLedgerEntry."Invoiced Quantity", -TempServiceLineBeforePosting."Qty. to Consume", Tolerance,
              'Quantity Consumed and Invoiced Quantity are nearly equal');
            RelatedItemLedgerEntry.SetRange("Applies-to Entry", ItemLedgerEntry."Applies-to Entry");
            RelatedItemLedgerEntry.FindFirst();
            ItemLedgerEntry.TestField("Cost Amount (Actual)", -RelatedItemLedgerEntry."Cost Amount (Actual)");
            ItemLedgerEntry.TestField("Sales Amount (Actual)", 0);
            VerifyValueEntryAfterUndoConsumption(ItemLedgerEntry);
        until TempServiceLineBeforePosting.Next() = 0;
    end;

    local procedure VerifyValueEntryAfterUndoConsumption(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
    begin
        // Verify that the value ofthe field Valued Quantity of the Value Entry is equal to the value of the field Qty. to Ship of
        // the relevant Service Line.
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.FindLast();
        ValueEntry.TestField("Valued Quantity", ItemLedgerEntry.Quantity);
        ValueEntry.TestField("Item Ledger Entry Type", ItemLedgerEntry."Entry Type");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", ItemLedgerEntry."Cost Amount (Actual)");
    end;

    local procedure VerifyWarrantyLedgerEntry(ServiceOrderNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal)
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        WarrantyLedgerEntry.SetRange("Service Order No.", ServiceOrderNo);
        WarrantyLedgerEntry.SetRange("Customer No.", CustomerNo);
        WarrantyLedgerEntry.SetRange(Quantity, Quantity);
        WarrantyLedgerEntry.SetRange(Open, false);
        WarrantyLedgerEntry.FindFirst();
    end;

    local procedure VerifyServiceShipmentLinesAfterUndoConsumption(Item: array[3] of Record Item; Bin: array[3] of Record Bin; Qty: array[3] of Decimal)
    var
        DummyServiceShipmentLine: Record "Service Shipment Line";
        i: Integer;
    begin
        for i := 1 to ArrayLen(Bin) do begin
            DummyServiceShipmentLine.SetRange("No.", Item[i]."No.");
            DummyServiceShipmentLine.SetRange("Bin Code", Bin[i].Code);
            DummyServiceShipmentLine.SetRange(Quantity, -Qty[i]);
            Assert.RecordIsNotEmpty(DummyServiceShipmentLine);
        end;
    end;

    local procedure VerifyItemEntriesAfterUndoShipment(ServiceOrderNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceOrderNo);
        ServiceShipmentLine.SetRange(Type, ServiceShipmentLine.Type::Item);
        ServiceShipmentLine.FindFirst();
        ItemLedgerEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Posting Date", ServiceShipmentLine."Posting Date");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyResourceEntriesAfterUndoShipment(ServiceOrderNo: Code[20])
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceOrderNo);
        ServiceShipmentLine.SetRange(Type, ServiceShipmentLine.Type::Resource);
        ServiceShipmentLine.FindFirst();
        ResLedgerEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
        ResLedgerEntry.FindSet();
        repeat
            ResLedgerEntry.TestField("Posting Date", ServiceShipmentLine."Posting Date");
        until ResLedgerEntry.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(
            (StrPos(Question, ExpectedCostPostingEnableConfirm) = 1) or
            (StrPos(Question, ExpectedCostPostingDisableConfirm) = 1) or
            (StrPos(Question, 'You must confirm Service Cost') = 1) or
            (StrPos(Question, 'Do you want to undo the selected shipment line(s)?') = 1) or
            (StrPos(Question, 'Do you want to undo consumption of the selected shipment line(s)?') = 1),
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CreateWhseShpt_MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    local procedure ExecuteUIHandlers()
    begin
        Message(StrSubstNo(ExpectedMsg));
        if Confirm(StrSubstNo(ExpectedCostPostingEnableConfirm)) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure WarehouseShipmentPageHandler(var WarehouseShipment: TestPage "Warehouse Shipment")
    begin
        WarehouseShipment.Close();
    end;
}

