// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

codeunit 136146 "Service Item Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Tracking] [Service]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        isInitialized: Boolean;
        AvailabilityMessage: Label 'There are availability warnings on one or more lines.';
        CorrectionMessage: Label 'The corrections cannot be saved as excess quantity has been defined.';
        ErrorMustBeSame: Label 'Error must be same.';
        AvailabilitySerialNo: Boolean;
        ItemNo: Code[20];
        LotNo: Code[50];
        No: Code[20];
        ServiceItemNo: Code[20];
        SaleLCY: Decimal;
        OriginalQuantity: Decimal;
        ItemTrackingAction: Option SelectEntries,AssignSerialNo,AssignLotNo,AssignLotManually,AvailabilitySerialNo,AvailabilityLotNo,LookupLotNo,CreateCustomizedSerialNo,AdjustQtyToHandle;
        ActualMessage: Text[1024];
        GlobalCheckExpirationDate: Boolean;
        GlobalExpirationDate: Date;
        ExpirationDate: Date;
        PartialConsumeError: Label '%1 in the item tracking assigned to the document line for item %2 is currently %3. It must be %4.\\Check the assignment for serial number %5, lot number %6, package number %7.', Comment = '%1:Value1,%2:Value2,%3:Value3,%4:Value4,%5:Value5,%6:Value6,%7:Value7';
        NumberOfLineEqualError: Label 'Number of Lines must be same.';
        ValidationError: Label 'Caption does not match.';
        SkilledResourceCaption: Label 'View - Skilled Resource List - %1 %2', Comment = '%1:Value1,%2:Value2';
        QuoteCaption: Label 'View - Service Quotes - %1';
        OrderCaption: Label 'View - Service Orders - %1';
        InvoicesCaption: Label 'View - Service Invoices - %1';
        CreditMemosCaption: Label 'View - Service Credit Memos - %1';
        PostedServiceShipmentsCaption: Label 'View - Posted Service Shipments';
        PostedServiceInvoicesCaption: Label 'View - Posted Service Invoices';
        PostedServiceCreditMemosCaption: Label 'View - Posted Service Credit Memos';
        CustomizedSN: Code[50];
        GlobalQty: Decimal;
        NoBinFoundWithItemErr: Label 'No bin could be found holding the purchased item %1.', Comment = '%1 = Code, describing an item number.';
        ItemTrackingQtyErr: Label 'The Quantity of Item Tracking is not correct.';
        OpenDocumentTrackingErr: Label 'You cannot change "Item Tracking Code" because there is at least one open document that includes this item with specified tracking: Source Type = %1, Document No. = %2.';

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabileWithItemTracking()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify Item is available, when create a Purchase Order for an Item with Item Tracking and Post as Receive.

        // 1. Setup: Create Item with Reserve Optional and Lot No Series attached, Create a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::AssignLotNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ItemTrackingAction := ItemTrackingAction::SelectEntries;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Availability of Lot No on Item Tracking Page. Verification done on ItemTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithItemTracking()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Item is available, when create a Purchase Order for an Item with Item Tracking and Post as Receive and Service Order Post Successfully.

        // 1. Setup: Create Item with Reserve Optional and Lot No Series attached, Create a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::AssignLotNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Service Order Post without error for Item with Item Tracking.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceWithItemTracking()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Item is available, when create a Purchase Order for an Item with Item Tracking and Post as Receive and Service Order Post Successfully.

        // 1. Setup: Create Item with Reserve Optional and Lot No Series attached, Create a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::AssignLotNo);
        CreateShipToAddressAndUpdateServiceInvoiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Service Order Post without error for Item with Item Tracking.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ItemTrackingNumberTypedManuallyWrongLotNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify warning message if manually type wrong Lot No.

        // 1. Setup: Create Item with Reserve Optional and Lot No Series attached, Create a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::AssignLotNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ItemTrackingAction := ItemTrackingAction::AssignLotManually;
        LotNo := ServiceLine."Customer No.";  // Value not important, assign Customer No. as LotNo.

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Availability Warning Message for Lot Number.
        Assert.IsTrue(StrPos(ActualMessage, AvailabilityMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ItemTrackingNumberTypedManuallyOverQuantity()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify warning message if manually type more than actual Quantity.

        // 1. Setup: Create Item with Reserve Optional and Lot No Series attached, Create a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::AssignLotNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ItemTrackingAction := ItemTrackingAction::AssignLotManually;
        LotNo := FindLotNoFromItemLedgerEntry();
        OriginalQuantity := OriginalQuantity + LibraryRandom.RandInt(10);  // Using Random value to excess Original Quantity.

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify corrections warning message for excess quantity has been defined.
        Assert.IsTrue(StrPos(ActualMessage, CorrectionMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ItemTrackingNumberTypedManuallyAndSelectEntries()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify warning message if Change Quantity Assign Item Tracking No. Both Manually and via Select Entries.

        // 1. Setup: Create Item with Reserve Optional and Serial No Series attached, Create a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingOnPurchaseAndServiceOrder(ServiceLine, 0);  // Taken 0 because value is important.
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify corrections warning message for excess quantity has been defined.
        Assert.IsTrue(StrPos(ActualMessage, CorrectionMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TypedLessQuantityAndUseSelectEntriesForRemainingQuantity()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify warning message if Less Quantity Assign Item Tracking No. both Manually and via Select Entries.

        // 1. Setup: Create Item with Reserve Optional and Serial No Series attached, Create a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingOnPurchaseAndServiceOrder(ServiceLine, 0);  // Taken 0 because value is important.
        OriginalQuantity := OriginalQuantity / 2;
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify corrections warning message for less Quantity has been defined.
        Assert.IsTrue(StrPos(ActualMessage, CorrectionMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure SerialNoAfterPostingServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Serial No. after posting the Service Order.

        // 1. Setup: Create Purchase and Service Order with Item Tracking.
        Initialize();
        AssignItemTrackingOnPurchaseAndServiceOrder(ServiceLine, 0);  // Taken 0 because value is important.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryVariableStorage.Enqueue(FindSerialNoFromItemLedgerEntry());  // Enqueue Serial No.

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verification is done in 'PostedItemTrackingLinesHandler' page handler.
        OpenServiceShipmentLinesFromPostedServiceShipment(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WarningForSerialNoWithChangedQuantity()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify warning message when Change the Quantity and Assign Serial No.

        // 1. Setup: Create Item with Serial No., create and post a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, ItemTrackingAction::AssignSerialNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify corrections warning message for excess quantity.
        Assert.IsTrue(StrPos(ActualMessage, CorrectionMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WarningWithChangedSerialNo()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify warning message when Assigning wrong Serial No.

        // 1. Setup: Create Item with Serial No., create and post a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, ItemTrackingAction::AssignSerialNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;
        LibraryVariableStorage.Enqueue(ServiceLine."Customer No.");  // Value not important, Enqueue Customer No. as Serial No.

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Availability Warning Message for Serial No.
        Assert.IsTrue(StrPos(ActualMessage, AvailabilityMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingActionsPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WarningForOverQuantityUsingSelectEntries()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify warning message for excess Quantity with Assign Serial No. using Select Entries on Item Tracking Line.

        // 1. Setup: Create Purchase and Service Order with Item Tracking.
        Initialize();
        AssignItemTrackingOnPurchaseAndServiceOrder(ServiceLine, 0);  // Taken 0 because value is important.
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify corrections warning message for excess quantity.
        Assert.IsTrue(StrPos(ActualMessage, CorrectionMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LotNoLookupOnItemTrackingPage()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify values on Item Tracking Summary page after Lookup on Lot No. field on Item Tracking page.

        // 1. Setup: Create Item with Lot No., Create and Receive a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::LookupLotNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        LotNo := FindLotNoFromItemLedgerEntry();  // Assign Lot No. to global variable.

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify values on Item Tracking Summary page after Lookup on field Lot No on Item Tracking Page. Verification done on 'ItemTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AvailabilityWarningAfterLotNoLookupOnItemTrackingPage()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify Availability Warning Message on Item Tracking page.

        // 1. Setup: Create Item with Lot No., Create and Receive a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::AssignLotNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Availability Warning Message for Lot No.
        Assert.IsTrue(StrPos(ActualMessage, AvailabilityMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingValuesAfterLotNoLookup()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify values on Item Tracking Lines page after Lookup on Lot No. field and closing Item Tracking Summary page.

        // 1. Setup: Create Item with Lot No., Create and Receive a Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::LookupLotNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        LotNo := FindLotNoFromItemLedgerEntry();  // Assign Lot No. to global variable.

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify values on Item Tracking Lines page after Lookup on field Lot No. and closing Item Tracking Summary page. Verification done on 'ItemTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithItemTrackingAvailability()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify Availability Serial No. field must be No on the Item Tracking Lines page after creating a Service Order with Serial No.

        // 1. Setup: Create Item with Serial No., create Service Order and Assign Serial No.
        Initialize();
        ItemNo := CreateItemWithSerialAndLotNo('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, false);  // Assign Item No. to global variable and blank value is taken for Lot No.
        OriginalQuantity := 1 + LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;
        AvailabilitySerialNo := false;  // Assign to global variable.

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Availability Serial No. field must be No on the Item Tracking Lines page. Verification done in the 'ItemTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithItemTrackingAvailabilityWarning()
    var
        ServiceLine: Record "Service Line";
    begin
        // Verify warning message after Assign Serial No.

        // 1. Setup: Create Item with Serial No., create Service Order with Item Tracking.
        Initialize();
        ItemNo := CreateItemWithSerialAndLotNo('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, false);  // Assign Item No. to global variable and blank value is taken for Lot No.
        OriginalQuantity := 1 + LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ItemTrackingAction := ItemTrackingAction::AssignSerialNo;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Availability Warning Message Serial No.
        Assert.IsTrue(StrPos(ActualMessage, AvailabilityMessage) > 0, ErrorMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithItemTrackingAvailability()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Check posting of Service Order with Item Tracking Serial No. without error.

        // 1. Setup: Create Item with Serial No., create Service Order with Item Tracking.
        Initialize();
        AssignItemTrackingAndPostPurchaseOrder('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, ItemTrackingAction::AssignSerialNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Service Order Post without error with Item Tracking.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithSerialNoOnWhiteLocation()
    var
        LocationType: Option White,Yellow,Orange;
    begin
        // Verify Serial No. after posting the Service Order on a white location with expiration date set to FALSE
        PostOrUndoServiceOrderWithItemTrackingOnLocation(false, true, false, WorkDate(), false, LocationType::White);
    end;

    [Test]
    [HandlerFunctions('EnterCustomizedSNHandler,ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceWithSerialNoOnWhiteLocation()
    var
        LocationType: Option White,Yellow,Orange;
    begin
        // Verify Serial No. on whse entries after posting a service invoice to White location
        PostServiceInvoiceWithItemTrackingOnLocation(false, true, false, WorkDate(), false, LocationType::White);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithSerialNoAndExpirationdateOnWhiteLocation()
    var
        LocationType: Option White,Yellow,Orange;
    begin
        // Verify Serial No. after posting the Service Order on a white location with manual expiration date set to TRUE.
        PostOrUndoServiceOrderWithItemTrackingOnLocation(false, true, true, WorkDate() + 20, false, LocationType::White);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithSerialNoAndExpiredItemOnWhiteLocation()
    var
        LocationType: Option White,Yellow,Orange;
    begin
        // Verify Serial No. after posting the Service Order on a white location with manual expiration date set to True.
        PostOrUndoServiceOrderWithItemTrackingOnLocation(false, true, true, WorkDate(), false, LocationType::White);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandlerForUndoShipment,PostedItemTrackingLinesForUndoShipment,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoServiceOrderWithSerialNoOnWhiteLocation()
    var
        LocationType: Option White,Yellow,Orange;
    begin
        // Undo Service Order with item tracking entries, Serial No tracking and No manual expiration date entry
        PostOrUndoServiceOrderWithItemTrackingOnLocation(false, true, false, WorkDate(), true, LocationType::White);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithSerialNoOnYellowLocation()
    var
        LocationType: Option White,Yellow,Orange;
    begin
        // Verify Serial No. after posting the Service Order on a white location with expiration date set to FALSE
        PostOrUndoServiceOrderWithItemTrackingOnLocation(false, true, false, WorkDate(), false, LocationType::Yellow);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandlerForUndoShipment,PostedItemTrackingLinesForUndoShipment,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UndoServiceOrderWithSerialNoOnYellowLocation()
    var
        LocationType: Option White,Yellow,Orange;
    begin
        // Undo Service Order with item tracking entries, Serial No tracking and No manual expiration date entry
        PostOrUndoServiceOrderWithItemTrackingOnLocation(false, true, false, WorkDate(), true, LocationType::Yellow);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,ExpirationDateOnPostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ExpirationDateAfterPostingServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Expiration Date after posting the Service Order.

        // 1. Setup: Create Item with Item Tracking and Expiration Calculation, create and post Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingOnPurchaseAndServiceOrder(ServiceLine, 0);  // Taken 0 because value is important.
        FindPurchaseItemLedgerEntry(ItemLedgerEntry);
        ExpirationDate := ItemLedgerEntry."Expiration Date";  // Assign Expiration Date to global variable.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verification is done in 'ExpirationDateOnPostedItemTrackingLinesHandler' page handler.
        OpenServiceShipmentLinesFromPostedServiceShipment(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ExpirationDateOnItemLedgerEntry()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Expiration Date on Item Ledger Entry after posting the Purchase Order.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create and post Purchase Order with Item Tracking and Item with Expiration Calculation.
        AssignItemTrackingAndPostPurchaseOrder('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, ItemTrackingAction::AssignSerialNo);
        Item.Get(ItemNo);
        ExpirationDate := CalcDate(Item."Expiration Calculation", WorkDate());

        // 3. Verify: Verify Expiration Date on Item Ledger Entry.
        FindPurchaseItemLedgerEntry(ItemLedgerEntry);
        ItemLedgerEntry.TestField("Expiration Date", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,ExpirationDateOnPostedItemTrackingLinesHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ExpirationDateUsingUndoShipmentOnShppedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Expiration Date after Undo Shipment on Posted Service Shipment.

        // 1. Setup: Create Item with Item Tracking and Expiration Calculation, create and post Purchase Order, Service Order.
        Initialize();
        AssignItemTrackingOnPurchaseAndServiceOrder(ServiceLine, 0);  // Taken 0 because value is important.
        FindPurchaseItemLedgerEntry(ItemLedgerEntry);
        ExpirationDate := ItemLedgerEntry."Expiration Date";  // Assign Expiration Date to global variable.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Undo Shipment on Posted Service Shipment.
        UndoShipment(ServiceHeader."No.");

        // 3. Verify: Verification is done for Expiration Date after Undo Shipment on Posted Service Shipment in 'ExpirationDateOnPostedItemTrackingLinesHandler' page handler.
        OpenServiceShipmentLinesFromPostedServiceShipment(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionErrorOnServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TrackingSpecification: Record "Tracking Specification";
    begin
        // Verify error on Service Order while consuming Service Order with Partial Qty. to Consume.

        // 1. Setup: Create Item with Item Tracking and Expiration Calculation, create and post Purchase Order, create Service Order.
        Initialize();
        AssignItemTrackingOnPurchaseAndServiceOrder(ServiceLine, 0);  // Taken 0 because value is important.
        UpdateQuantityToConsume(ServiceLine, ServiceLine."Qty. to Ship" / 2);  // Partially consume.
        FindPurchaseItemLedgerEntry(ItemLedgerEntry);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Consume Service Order.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify error message while Qty. to Consume is less than Qty. to Handle (Base) defined on Item Tracking Lines.
        Assert.ExpectedError(
          StrSubstNo(
            PartialConsumeError, TrackingSpecification.FieldCaption("Qty. to Handle (Base)"), ItemLedgerEntry."Item No.",
            ServiceLine.Quantity, ServiceLine."Qty. to Consume", ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.", ItemLedgerEntry."Package No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,ExpirationDateOnPostedItemTrackingLinesHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ExpirationDateUsingUndoConsumptionOnConsumedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // Verify Expiration Date after Undo Consumption on Posted Service Shipment.

        // 1. Setup: Create Item with Item Tracking and Expiration Calculation, create and post Purchase Order, Service Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(5);  // Random value is taken to calculate lesser Qty. to Consume. than Quantity.
        AssignItemTrackingOnPurchaseAndServiceOrder(ServiceLine, Quantity);  // Taken 1 because greater Quantity is needed.
        UpdateQuantityToConsume(ServiceLine, ServiceLine."Qty. to Ship" - Quantity);  // Taken lesser Qty. to Consume because value is important.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        FindPurchaseItemLedgerEntry(ItemLedgerEntry);
        ExpirationDate := ItemLedgerEntry."Expiration Date";  // Assign Expiration Date to global variable.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Undo Shipment on Posted Service Shipment.
        UndoConsumption(ServiceHeader."No.");

        // Verify: Verify Expiration Date after Undo Consumption on Posted Service Shipment.
        OpenServiceShipmentLinesFromPostedServiceShipment(ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressOnCustomerDetailsFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrders: TestPage "Service Orders";
        ShipToAddressList: TestPage "Ship-to Address List";
    begin
        // Verify Ship To Address page value from Service Order's Customer Details FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrdersPage(ServiceOrders, ServiceLine."Document No.");
        ShipToAddressList.Trap();

        // 2. Exercise: Open Ship To Address List page using Service Order page.
        ServiceOrders.Control1900316107."Ship-to Address".Invoke();

        // 3. Verify.
        ShipToAddressList.Name.AssertEquals(ServiceLine."Customer No.")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineListFromCustomerStatisticsFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrders: TestPage "Service Orders";
        ServiceLineList: TestPage "Service Line List";
    begin
        // Verify Service Line List page value opened from Customer Statistics FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrdersPage(ServiceOrders, ServiceLine."Document No.");
        ServiceLineList.Trap();

        // 2. Exercise: Open Service Line List page using Service Order page.
        ServiceOrders.Control1902018507."Outstanding Serv. Orders (LCY)".Drilldown();

        // 3. Verify.
        ServiceLineList."Document No.".AssertEquals(ServiceLine."Document No.");
        ServiceLineList."No.".AssertEquals(ServiceLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableCreditFromCustomerDetailsFactBoxServiceOrder()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrders: TestPage "Service Orders";
        AvailableCredit: TestPage "Available Credit";
    begin
        // Verify Available Credit page value opened from Service Order's Customer Details FactBox.

        // 1. Setup: Create and post Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        OpenServiceOrdersPage(ServiceOrders, ServiceLine."Document No.");
        AvailableCredit.Trap();

        // 2. Exercise: Open Available Credit page using Service Order page.
        ServiceOrders.Control1900316107.AvailableCreditLCY.Drilldown();

        // 3. Verify.
        AvailableCredit."Serv Shipped Not Invoiced(LCY)".AssertEquals(ServiceLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemOnServiceItemLineFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceItemCard: TestPage "Service Item Card";
    begin
        // Verify Service Item Card page value opened from Service Order's Service Item Line FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        ServiceItemCard.Trap();

        // 2. Exercise: Open Service Item Card page using Service Order page.
        ServiceOrder.Control1906530507."Service Item No.".Drilldown();

        // 3. Verify.
        ServiceItemCard."No.".AssertEquals(ServiceLine."Service Item No.");
        ServiceItemCard."Customer No.".AssertEquals(ServiceLine."Customer No.");
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLcyOnCustomerStatisticsFactBoxServiceOrder()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrders: TestPage "Service Orders";
        Amount: Decimal;
    begin
        // Verify Customer Ledger Entries page value opened from Service Order's Customer Statistics FactBox.

        // 1. Setup: Create and post Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        ServiceLine.Validate("Qty. to Invoice", ServiceLine.Quantity - 1);  // Needed lesser Qty. to Ivoice than Quantity.
        ServiceLine.Modify(true);

        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        Amount := ServiceLine."Unit Price" * ServiceLine."Quantity Invoiced";  // Assigned to global variable.
        SaleLCY := Amount - (Amount * ServiceLine."Line Discount %" / 100);
        OpenServiceOrdersPage(ServiceOrders, ServiceLine."Document No.");
        Assert.AreEqual(
          SaleLCY, ServiceOrders.Control1902018507."Sales (LCY)".AsDecimal(), 'Total Sales LCY matches service line amount');

        // 2. Exercise: Open Customer Ledger Entries page using Service Order page.
        No := ServiceHeader."Bill-to Customer No.";
        ServiceOrders.Control1902018507."Sales (LCY)".Drilldown();

        // 3. Verify: Correct filter is set in the CustomerLedger Entries page. This is done in the 'CustomerLedgerEntriesPageHandler' handler
    end;

    [Test]
    [HandlerFunctions('ServiceItemComponentListPageHandler')]
    [Scope('OnPrem')]
    procedure ComponentListOnServiceItemLineFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // Verify Component List page value opened from Service Order's Service Item Line Detail pane.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        No := ServiceLine."No.";  // Assinged to global variable.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");

        // 2. Exercise: Open Component List page using Service Order page.
        ServiceOrder.Control1906530507.ComponentList.Drilldown();

        // 3. Verify: Verify Component List page value, done in ServiceItemComponentListPageHandler page handler.
    end;

    [Test]
    [HandlerFunctions('SkilledResourceListPageHandler')]
    [Scope('OnPrem')]
    procedure SkilledResourceOnServiceItemLineFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // Verify caption after opening Skilled Resource List page from Service Order's Service Item Line Detail pane.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        ServiceItemNo := ServiceLine."Service Item No.";  // Assinged to global variable.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");

        // 2. Exercise: Open Skilled Resource List page using Service Order page.
        ServiceOrder.Control1906530507.SkilledResources.Drilldown();

        // 3. Verify: Verify Skilled Resources List page caption done in SkilledResourceListPageHandler page handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerOnServiceHistSellToFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerCard: TestPage "Customer Card";
    begin
        // Verify Customer Card page value opened through Service Order's Service Hist. Sell-to FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        CustomerCard.Trap();

        // 2. Exercise: Open Customer Card page using Service Order page.
        ServiceOrder.Control1907829707."No.".Drilldown();

        // 3. Verify.
        CustomerCard."No.".AssertEquals(ServiceLine."Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderOnServiceHistSellToFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceOrders: TestPage "Service Orders";
    begin
        // Verify caption of Service Orders page opened through Service Order's Service Hist. Sell-to FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        ServiceOrders.Trap();

        // 2. Exercise: Open Service Orders page using Service Order page.
        ServiceOrder.Control1907829707.NoOfOrdersTile.Drilldown();

        // 3. Verify: Verify Service Orders page caption.
        Assert.ExpectedMessage(StrSubstNo(OrderCaption, ServiceLine."Customer No."), ServiceOrders.Caption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteOnServiceHistSellToFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceQuotes: TestPage "Service Quotes";
    begin
        // Verify caption of Service Quotes page opened through Service Order's Service Hist. Sell-to FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        ServiceQuotes.Trap();

        // 2. Exercise: Open Service Quotes page using Service Order page.
        ServiceOrder.Control1907829707.NoOfQuotesTile.Drilldown();

        // 3. Verify: Verify Service Quotes page caption.
        Assert.ExpectedMessage(StrSubstNo(QuoteCaption, ServiceLine."Customer No."), ServiceQuotes.Caption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceOnServiceHistSellToFactBoxServiceOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceInvoices: TestPage "Service Invoices";
    begin
        // Verify caption of Service Invoices page opened through Service Order's Service Hist. Sell-to FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        ServiceInvoices.Trap();

        // 2. Exercise: Open Service Invoices page using Service Order page.
        ServiceOrder.Control1907829707.NoOfInvoicesTile.Drilldown();

        // 3. Verify: Verify Service Inoices page caption.
        Assert.ExpectedMessage(StrSubstNo(InvoicesCaption, ServiceLine."Customer No."), ServiceInvoices.Caption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemosOnServiceHistSellToFactBox()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceCreditMemos: TestPage "Service Credit Memos";
    begin
        // Verify caption of Service Credit Memos page opened through Service Order's Service Hist. Sell-to FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        ServiceCreditMemos.Trap();

        // 2. Exercise: Open Service Credit Memo page using Service Order page.
        ServiceOrder.Control1907829707.NoOfCreditMemosTile.Drilldown();

        // 3. Verify: Verify Service Credit Memos page caption.
        Assert.ExpectedMessage(StrSubstNo(CreditMemosCaption, ServiceLine."Customer No."), ServiceCreditMemos.Caption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentsOnServiceHistSellToFactBox()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        PostedServiceShipments: TestPage "Posted Service Shipments";
    begin
        // Verify caption of Posted Service Shipments page opened through Service Order's Service Hist. Sell-to FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        PostedServiceShipments.Trap();

        // 2. Exercise: Open Posted Service Shipment page using Service Order page.
        ServiceOrder.Control1907829707.NoOfPostedShipmentsTile.Drilldown();

        // 3. Verify: Verify for Posted Service Shipments page caption.
        Assert.AreEqual(StrSubstNo(PostedServiceShipmentsCaption), PostedServiceShipments.Caption, ValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoicesOnServiceHistSellToFactBox()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        PostedServiceInvoices: TestPage "Posted Service Invoices";
    begin
        // Verify caption of Posted Service Invoices page opened through Service Order's Service Hist. Sell-to FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        PostedServiceInvoices.Trap();

        // 2. Exercise: Open Posted Service Invoices page using Service Order page.
        ServiceOrder.Control1907829707.NoOfPostedInvoicesTile.Drilldown();

        // 3. Verify: Verify Posted Service Invoices page caption.
        Assert.AreEqual(StrSubstNo(PostedServiceInvoicesCaption), PostedServiceInvoices.Caption, ValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemosOnServiceHistSellToFactBox()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
    begin
        // Verify caption of Posted Service Credit Memos page opened through Service Order's Service Hist. Sell-to FactBox.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, FindItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        OpenServiceOrderPage(ServiceOrder, ServiceLine."Document No.");
        PostedServiceCreditMemos.Trap();

        // 2. Exercise: Open Posted Service Credit Memos page using Service Order page.
        ServiceOrder.Control1907829707.NoOfPostedCreditMemosTile.Drilldown();

        // 3. Verify: Verify Posted Service Credit Memos page caption.
        Assert.AreEqual(StrSubstNo(PostedServiceCreditMemosCaption), PostedServiceCreditMemos.Caption, ValidationError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAndVerifyItemTrackingQtyPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanInReqWkshForServiceItemWksh()
    var
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        // Verify Item Tracking Quantity on the Service Item Worksheet after calculating plan in Requisition Worksheet.
        // 1. Setup: Create Item with Maximum Qty. and Serial No Series attached, Create a Purchase Order, Service Order.
        Initialize();

        // Use Random value for Quantity - less than the inventory.
        OriginalQuantity := LibraryRandom.RandInt(10); // Using Random Integer value. Assign it to Global Variable.
        AssignItemTrackingOnServiceOrderWithItem(Item, ServiceLine, LibraryRandom.RandInt(OriginalQuantity));

        // 2. Exercise: Calculate Plan for Requisition Worksheet.
        CalculatePlanForReqWksh(Item);

        LibraryVariableStorage.Enqueue(true); // Enqueue for ItemTrackingAndVerifyItemTrackingQtyPageHandler.
        LibraryVariableStorage.Enqueue(ServiceLine.Quantity); // Enqueue Value for ItemTrackingAndVerifyItemTrackingQtyPageHandler.

        // 3. Verify: Verify the Item Tracking Quantity on Service Item Worksheet in ItemTrackingAndVerifyItemTrackingQtyPageHandler.
        ServiceLine.OpenItemTrackingLines();
    end;

    [HandlerFunctions('ItemTrackingSummaryPageHandler')]
    local procedure PostServiceInvoiceWithItemTrackingOnLocation(LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; ManualExpirationDate: Boolean; ExpirationDate: Date; UndoShipment: Boolean; LocationType: Option White,Yellow,Orange)
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseEntry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LibraryService: Codeunit "Library - Service";
        LocationCode: Code[10];
        Quantity: Integer;
        StopLoop: Boolean;
        LastItemLedgerEntryNo: Integer;
    begin
        // Verify warehouse entries after posting the Service Invoice
        // 1. Setup: Create Item with Item Tracking, Create and post Purchase Order, Service Order.
        Initialize();

        case LocationType of
            LocationType::White:
                CreateFullWarehouseLocation(Location);
            LocationType::Yellow:
                LibraryService.CreateDefaultYellowLocation(Location);
        end;

        LocationCode := Location.Code;
        Quantity := LibraryRandom.RandInt(100);
        GlobalQty := Quantity;
        CreateItemTrackingCode(LotSpecificTracking, SerialNoSpecificTracking, ManualExpirationDate, ManualExpirationDate);
        ItemLedgerEntry.FindLast();
        LastItemLedgerEntryNo := ItemLedgerEntry."Entry No.";
        AssignItemTrackingAndPostPurchaseOrderOnWhiteLocation(
          '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingAction::AssignSerialNo, LocationCode, Quantity, ManualExpirationDate,
          ExpirationDate);
        ItemLedgerEntry.Get(LastItemLedgerEntryNo + 1);
        CustomizedSN := ItemLedgerEntry."Serial No.";
        CreateShipToAddressAndUpdateServiceInvoiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceLine.Validate("Location Code", LocationCode);
        // Find the bin code:
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Zone Code", 'PICK');
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindSet();
        repeat
            BinContent.CalcFields(Quantity);
            if BinContent.Quantity > 0 then
                StopLoop := true
            else
                StopLoop := BinContent.Next() = 0;
        until StopLoop;
        Assert.IsTrue(BinContent.Quantity > 0, StrSubstNo(NoBinFoundWithItemErr, ItemNo));
        ServiceLine.Validate("Bin Code", BinContent."Bin Code");
        if BinContent.Quantity < ServiceLine.Quantity then begin
            GlobalQty := BinContent.Quantity;
            ServiceLine.Validate(Quantity, GlobalQty);
        end;
        ServiceLine.Modify(true);
        ItemTrackingAction := ItemTrackingAction::CreateCustomizedSerialNo;
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // EXECUTE: Post the service invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. VERIFY: Verify Warehouse Entries
        GetWarehouseEntries(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.");
        VerifyWarehouseEntry(
          ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.", LotSpecificTracking, SerialNoSpecificTracking,
          ManualExpirationDate, ExpirationDate, UndoShipment);
    end;

    local procedure PostOrUndoServiceOrderWithItemTrackingOnLocation(LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; ManualExpirationDate: Boolean; ExpirationDate: Date; UndoShipment: Boolean; LocationType: Option White,Yellow,Orange)
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        // Verify Serial No. after posting the Service Order.

        // 1. Setup: Create Item with Item Tracking, Create and post Purchase Order, Service Order.
        Initialize();

        case LocationType of
            LocationType::White:
                CreateFullWarehouseLocation(Location);
            LocationType::Yellow:
                LibraryService.CreateDefaultYellowLocation(Location);
        end;

        LocationCode := Location.Code;
        Quantity := LibraryRandom.RandInt(100);
        CreateItemTrackingCode(LotSpecificTracking, SerialNoSpecificTracking, ManualExpirationDate, ManualExpirationDate);
        AssignItemTrackingAndPostPurchaseOrderOnWhiteLocation(
          '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingAction::AssignSerialNo, LocationCode, Quantity, ManualExpirationDate,
          ExpirationDate);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Modify(true);
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
        LibraryVariableStorage.Enqueue(FindSerialNoFromItemLedgerEntry()); // Enqueue Serial No.

        // EXECUTE: Create Pick, Register Pick and post Warehouse shipment with ship option, Invoice Service order partialy.
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        if UndoShipment then
            LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceHeader."No.");

        // 3. VERIFY: Verification is done in 'PostedItemTrackingLinesHandler' page handler.
        GlobalCheckExpirationDate := ManualExpirationDate;
        GlobalExpirationDate := ExpirationDate;
        PostedServiceShipment.OpenView();
        PostedServiceShipment.FILTER.SetFilter("Order No.", ServiceHeader."No.");

        PostedServiceShipment.ServShipmentItemLines.ServiceShipmentLines.Invoke();
        FindServiceLinesByHeaderNo(ServiceLine, ServiceHeader);
        VerifyItemLedgerEntryOnPost(
          ServiceLine, LotSpecificTracking, SerialNoSpecificTracking, ManualExpirationDate, ExpirationDate, UndoShipment);
        if LocationType = LocationType::Yellow then begin
            VerifyNoWarehouseEntriesCreated(ServiceLine);
            exit;
        end;
        if false = UndoShipment then begin
            GetWarehouseEntries(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.");
            VerifyWarehouseEntry(
              ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Negative Adjmt.", LotSpecificTracking, SerialNoSpecificTracking,
              ManualExpirationDate, ExpirationDate, UndoShipment);
        end else begin
            GetWarehouseEntries(ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.");
            VerifyWarehouseEntry(
              ServiceLine, WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", LotSpecificTracking, SerialNoSpecificTracking,
              ManualExpirationDate, ExpirationDate, UndoShipment);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingCodeValidationErrorWhenOpenDocExists()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        RecRef: RecordRef;
    begin
        // Verify error message when validate Item Tracking Code in case of open document with tracking exists
        Initialize();
        AssignItemTracking(PurchaseHeader, LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, ItemTrackingAction::AssignLotNo, true);

        Item.Get(ItemNo);
        asserterror Item.Validate("Item Tracking Code", '');

        RecRef.Open(DATABASE::"Purchase Line");
        Assert.ExpectedError(StrSubstNo(OpenDocumentTrackingErr, RecRef.Caption, PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure VerifySerialNoAfterPosingServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        // [SCENARIO 361035] Verify Serial No. in Posted Item Tracking page after posting of Service Invoice
        Initialize();

        // [GIVEN] Create Item with Serial No. Series, post Purchase Order
        AssignItemTrackingAndPostPurchaseOrder('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, ItemTrackingAction::AssignSerialNo);

        // [GIVEN] Create Service Invoice
        CreateShipToAddressAndUpdateServiceInvoiceLine(ServiceLine, ItemNo, OriginalQuantity);

        // [GIVEN] Assign Serial No. to Service Line
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking in "ItemTrackingPageHandler"

        // [WHEN] Post Service Invoice
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Serial No. is shown on Posted Item Tracking Lines
        LibraryVariableStorage.Enqueue(FindSerialNoFromItemLedgerEntry());  // Enqueue Serial No.
        FindServiceInvoiceLine(ServiceInvoiceLine, ItemNo);
        ServiceInvoiceLine.ShowItemTrackingLines(); // Verify Serial No. in "PostedItemTrackingLinesHandler"
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceQuoteServiceItemLineDetailsFactBox()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceQuote: TestPage "Service Quote";
        NoOfComponents: Integer;
        NoOfTroubleShooting: Integer;
    begin
        // [FEATURE] [Service Quote] [UI]
        // [SCENARIO 123585] Service Item Line Details FactBox shows Service Item No., No. of Components and Troubleshooting in Service Quote
        Initialize();
        // [GIVEN] Service Item X with 2 components, 3 Troubleshooting.
        CreateServiceItemWithComponents(ServiceItem, NoOfComponents, NoOfTroubleShooting, LibrarySales.CreateCustomerNo());
        // [GIVEN] Service Quote for Item X
        CreateServiceDocumentWithLine(
          ServiceHeader, ServiceHeader."Document Type"::Quote,
          ServiceItem."Customer No.", ServiceItem."No.");
        // [WHEN] Service Quote Page is opened
        ServiceQuote.OpenView();
        ServiceQuote.GotoRecord(ServiceHeader);
        // [THEN] Service Item Line Details in Service Quote Page shows Item X, 2 components, 3 Troubleshooting
        VerifyServiceItemLineDetailsFactBox(ServiceQuote, ServiceItem."No.", NoOfComponents, NoOfTroubleShooting);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceLineRowID1()
    var
        DummyServiceInvoiceLine: Record "Service Invoice Line";
    begin
        // [FEATURE] [UT] [Invoice]
        // [SCENARIO 217459] TAB 5993 "Service Invoice Line".RowID1() returns string with "5993" table id value
        Assert.ExpectedMessage(Format(DATABASE::"Service Invoice Line"), DummyServiceInvoiceLine.RowID1());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoLineRowID1()
    var
        DummyServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        // [FEATURE] [UT] [Credit Memo]
        // [SCENARIO 217459] TAB 5995 "Service Cr.Memo Line".RowID1() returns string with "5995" table id value
        Assert.ExpectedMessage(Format(DATABASE::"Service Cr.Memo Line"), DummyServiceCrMemoLine.RowID1());
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PartiallyPostingWhseShipmentForServiceLineWithItemTracking()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        BinContent: Record "Bin Content";
        ItemNo: array[2] of Code[20];
        Quantity: Integer;
        i: Integer;
    begin
        // [FEATURE] [Warehouse Shipment]
        // [SCENARIO 224086] Remaining quantity in bin becomes equal to 1 when there were N pcs in the bin and warehouse shipment for N - 1 pcs is posted for service line with item tracking and registered pick.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Lot-tracked item "IL" and serial no.-tracked item "IS". Lot and Serial No. warehouse tracking is enabled.
        CreateFullWarehouseLocation(Location);
        ItemNo[1] := CreateItemWithSerialAndLotNo(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, true); // lot tracked item
        ItemNo[2] := CreateItemWithSerialAndLotNo('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, true); // serial no. tracked item

        // [GIVEN] Purchase Order with two item lines and quantity "Q".
        // [GIVEN] Lot "L" is assigned to the line with item "IL", serial nos. "S1".."SQ" are assigned to the line with item "IS".
        // [GIVEN] Whse. Receipt is posted, Put-away is registered.
        CreatePurchaseOrderForLocation(PurchaseHeader, PurchaseLine, Location.Code, ItemNo[1], Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignLotNo);
        PurchaseLine.OpenItemTrackingLines();
        CreatePurchaseLineWithLocationCode(PurchaseLine, PurchaseHeader, ItemNo[2], Location.Code, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Service Order with two service lines with items "IL" and "IS" and assigned tracking.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        for i := 1 to ArrayLen(ItemNo) do begin
            LibraryVariableStorage.Enqueue(ItemTrackingAction::SelectEntries);
            CreateServiceLineWithItemTracking(ServiceHeader, ServiceItemLine, ItemNo[i], Location.Code, Quantity);
        end;

        // [GIVEN] Warehouse shipment for the service order.
        // [GIVEN] Registered warehouse pick.
        ServiceHeader.Find();
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        CreateWarehouseShipmentFromServiceHeader(ServiceHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Qty. to Ship is reduced by 1 pc on both lines in the warehouse shipment.
        // [GIVEN] Qty. to Handle on item tracking for each "IL" and "IS" line is reduced by 1 pc.
        for i := 1 to ArrayLen(ItemNo) do begin
            FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader."No.", ItemNo[i]);
            WarehouseShipmentLine.Validate("Qty. to Ship", WarehouseShipmentLine."Qty. to Ship" - 1);
            WarehouseShipmentLine.Modify(true);
            LibraryVariableStorage.Enqueue(ItemTrackingAction::AdjustQtyToHandle);
            LibraryVariableStorage.Enqueue(-1);
            WarehouseShipmentLine.OpenItemTrackingLines();
        end;

        // [WHEN] Post the warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] 1 pc of each "IL" and "IS" items remains in warehouse.
        for i := 1 to 2 do begin
            BinContent.SetRange("Item No.", ItemNo[i]);
            BinContent.FindFirst();
            Assert.RecordCount(BinContent, 1);
            BinContent.CalcFields(Quantity);
            BinContent.TestField(Quantity, 1);
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemTrackingIsManagedByWhse()
    var
        Location: Record Location;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 224086] Function "ItemTrkgIsManagedByWhse" in codeunit 6500 returns TRUE if whse. shipment line exists for service line with tracked item and location with enabled pick.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        ItemNo := CreateItemWithSerialAndLotNo(LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, true);

        WarehouseShipmentLine.Init();
        WarehouseShipmentLine."No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentLine."Line No." := LibraryUtility.GetNewRecNo(WarehouseShipmentLine, WarehouseShipmentLine.FieldNo("Line No."));
        WarehouseShipmentLine."Source Type" := DATABASE::"Service Line";
        WarehouseShipmentLine."Source No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentLine.Insert();

        Assert.IsTrue(
          ItemTrackingMgt.ItemTrkgIsManagedByWhse(
            WarehouseShipmentLine."Source Type", WarehouseShipmentLine."Source Subtype", WarehouseShipmentLine."Source No.", 0, WarehouseShipmentLine."Source Line No.", Location.Code, ItemNo),
          'Item tracking on service line is not managed by warehouse.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Item Tracking");
        ClearGlobalVariables();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Item Tracking");

        LibraryService.SetupServiceMgtNoSeries();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Item Tracking");
    end;

    local procedure ClearGlobalVariables()
    begin
        ItemNo := '';
        OriginalQuantity := 0;
        AvailabilitySerialNo := false;
        GlobalCheckExpirationDate := false;
        ExpirationDate := 0D;
        No := '';
        ServiceItemNo := '';
        SaleLCY := 0;
    end;

    local procedure AssignItemTrackingAndPostPurchaseOrder(LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; ItemTrackingAction2: Option)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        AssignItemTracking(PurchaseHeader, LotNos, SerialNos, LotSpecificTracking, SerialNoSpecificTracking, ItemTrackingAction2, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure AssignItemTracking(var PurchaseHeader: Record "Purchase Header"; LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; ItemTrackingAction2: Option; ModifyTrackingCode: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        ItemNo := CreateItemWithSerialAndLotNo(LotNos, SerialNos, LotSpecificTracking, SerialNoSpecificTracking, true);  // Assign Item No. to global variable and blank value is taken for Serial No.
        if ModifyTrackingCode then
            ModifyItemTrackingCode(ItemNo);
        OriginalQuantity := 2 * LibraryRandom.RandInt(10);  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        CreatePurchaseOrder(PurchaseHeader);
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        ItemTrackingAction := ItemTrackingAction2;
        PurchaseLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
    end;

    local procedure AssignItemTrackingAndPostPurchaseOrderWithMaxQtyItem(var Item: Record Item; LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; ItemTrackingAction2: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Update the Reordering Policy on Item Card.
        ItemNo := CreateItemWithSerialAndLotNo(LotNos, SerialNos, LotSpecificTracking, SerialNoSpecificTracking, false);
        Item.Get(ItemNo);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Maximum Inventory", LibraryRandom.RandInt(10));
        Item.Modify(true);
        CreatePurchaseOrder(PurchaseHeader);
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        ItemTrackingAction := ItemTrackingAction2;
        LibraryVariableStorage.Enqueue(false); // Enqueue for ItemTrackingAndVerifyItemTrackingQtyPageHandler.
        PurchaseLine.OpenItemTrackingLines(); // Assign Item Tracking on page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure AssignItemTrackingAndPostPurchaseOrderOnWhiteLocation(LotNos: Code[20]; SerialNos: Code[20]; ItemTrackingAction2: Option; LocationCode: Code[10]; Quantity: Integer; SetExpirationDate: Boolean; ExpirationDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        ItemNo := CreateItemWithSerialAndLotNoForItemTrackingCode(LotNos, SerialNos, false, true, false); // Assign Item No. to global variable and blank value is taken for Serial No.
        OriginalQuantity := Quantity;  // Random Integer value greater than 1 required for test. Assign it to Global Variable.
        CreatePurchaseOrderForLocation(PurchaseHeader, PurchaseLine, LocationCode, ItemNo, Quantity);
        ItemTrackingAction := ItemTrackingAction2;
        PurchaseLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
        if SetExpirationDate then
            UpdateReservationEntry(PurchaseLine."No.", ExpirationDate);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure AssignItemTrackingOnPurchaseAndServiceOrder(var ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        AssignItemTrackingAndPostPurchaseOrder('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, ItemTrackingAction::AssignSerialNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, ItemNo, OriginalQuantity + Quantity);
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
    end;

    local procedure AssignItemTrackingOnServiceOrderWithItem(var Item: Record Item; var ServiceLine: Record "Service Line"; Quantity: Integer)
    begin
        AssignItemTrackingAndPostPurchaseOrderWithMaxQtyItem(Item, '',
          LibraryUtility.GetGlobalNoSeriesCode(), false, true, ItemTrackingAction::AssignSerialNo);
        CreateShipToAddressAndUpdateServiceLine(ServiceLine, Item."No.", Quantity);
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        ItemTrackingAction := ItemTrackingAction::SelectEntries;
        LibraryVariableStorage.Enqueue(false); // Enqueue for ItemTrackingAndVerifyItemTrackingQtyPageHandler.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
    end;

    local procedure CreateItemWithSerialAndLotNo(LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; CreateNewItemTrackingCode: Boolean): Code[20]
    begin
        exit(
          CreateItemWithSerialAndLotNoForItemTrackingCode(
            LotNos, SerialNos, LotSpecificTracking, SerialNoSpecificTracking, CreateNewItemTrackingCode));
    end;

    local procedure CreateItemWithSerialAndLotNoForItemTrackingCode(LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; CreateNewItemTrackingCode: Boolean): Code[20]
    var
        Item: Record Item;
        ExpirationCalculation: DateFormula;
        ItemTrackingCode: Code[10];
    begin
        Evaluate(ExpirationCalculation, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        LibraryInventory.CreateItem(Item);
        if CreateNewItemTrackingCode then
            ItemTrackingCode := CreateItemTrackingCode(LotSpecificTracking, SerialNoSpecificTracking, false, true)
        else begin
            ItemTrackingCode := FindItemTrackingCode(LotSpecificTracking, SerialNoSpecificTracking);
            EnsureTrackingCodeUsesExpirationDate(ItemTrackingCode);
        end;
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Serial Nos.", SerialNos);
        Item.Validate("Lot Nos.", LotNos);
        Item.Validate("Expiration Calculation", ExpirationCalculation);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, OriginalQuantity);
    end;

    local procedure CreatePurchaseLineWithLocationCode(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; CustomerNo: Code[20]; ItemNumber: Code[20]; DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceItemComponent: Record "Service Item Component";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNumber);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemComponent(ServiceItemComponent, ServiceItem."No.", "Service Item Component Type"::Item, ServiceLine."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceDocumentWithLine(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; ServiceItemNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
    end;

    local procedure CreateServiceItemWithComponents(var ServiceItem: Record "Service Item"; var NoOfComponents: Integer; var NoOfTroubleShooting: Integer; CustomerNo: Code[20])
    var
        I: Integer;
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);

        NoOfComponents := LibraryRandom.RandInt(10);
        for I := 1 to NoOfComponents do
            CreateServiceItemComponent(ServiceItem."No.", CustomerNo);

        NoOfTroubleShooting := LibraryRandom.RandInt(10);
        for I := 1 to NoOfTroubleShooting do
            CreateServiceItemTroubleshooting(ServiceItem."No.");
    end;

    local procedure CreateServiceItemComponent(ServiceItemNo: Code[20]; CustomerNo: Code[20])
    var
        ServiceItemForComponent: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
    begin
        LibraryService.CreateServiceItem(ServiceItemForComponent, CustomerNo);
        LibraryService.CreateServiceItemComponent(
          ServiceItemComponent, ServiceItemNo,
          ServiceItemComponent.Type::"Service Item", ServiceItemForComponent."No.");
    end;

    local procedure CreateServiceItemTroubleshooting(ServiceItemNo: Code[20])
    var
        TroubleshootingHeader: Record "Troubleshooting Header";
        TroubleshootingLine: Record "Troubleshooting Line";
        TroubleshootingSetup: Record "Troubleshooting Setup";
    begin
        LibraryService.CreateTroubleshootingHeader(TroubleshootingHeader);
        LibraryService.CreateTroubleshootingLine(TroubleshootingLine, TroubleshootingHeader."No.");
        LibraryService.CreateTroubleshootingSetup(
          TroubleshootingSetup, TroubleshootingSetup.Type::"Service Item",
          ServiceItemNo, TroubleshootingHeader."No.");
    end;

    local procedure CreateServiceLineWithItemTracking(ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ServiceItemComponent: Record "Service Item Component";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceItemComponent(ServiceItemComponent, ServiceItemLine."Service Item No.", "Service Item Component Type"::Item, ItemNo);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, Qty);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
        ServiceLine.OpenItemTrackingLines();
    end;

    local procedure CreateShipToAddressAndUpdateServiceLine(var ServiceLine: Record "Service Line"; ItemNumber: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        CreateServiceDocument(ServiceLine, Customer."No.", ItemNumber, ServiceLine."Document Type"::Order);
        UpdateServiceLineQuantity(ServiceLine, Quantity);
    end;

    local procedure CreateShipToAddressAndUpdateServiceInvoiceLine(var ServiceLine: Record "Service Line"; ItemNumber: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        CreateServiceDocument(ServiceLine, Customer."No.", ItemNumber, ServiceLine."Document Type"::Invoice);
        UpdateServiceLineQuantity(ServiceLine, Quantity);
    end;

    local procedure CreateWarehouseShipmentFromServiceHeader(ServiceHeader: Record "Service Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
    end;

    local procedure CreateFullWarehouseLocation(var Location: Record Location)
    begin
        LibraryService.CreateFullWarehouseLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreatePurchaseOrderForLocation(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        // Create Purchase Order with One Item Line. Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithLocationCode(PurchaseLine, PurchaseHeader, ItemNo, LocationCode, Quantity);
    end;

    local procedure CreateAndPostWhseReceiptFromPO(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateItemTrackingCode(LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; ManualExpirationDateEntry: Boolean; UseExpirationDates: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SerialNoSpecificTracking, LotSpecificTracking);
        ItemTrackingCode.Validate("Use Expiration Dates", UseExpirationDates);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManualExpirationDateEntry);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotSpecificTracking);
        ItemTrackingCode.Validate("SN Warehouse Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure EnsureTrackingCodeUsesExpirationDate(ItemTrackingCode: Code[10])
    var
        ItemTrackingCodeRec: Record "Item Tracking Code";
    begin
        ItemTrackingCodeRec.Get(ItemTrackingCode);
        if not ItemTrackingCodeRec."Use Expiration Dates" then begin
            ItemTrackingCodeRec.Validate("Use Expiration Dates", true);
            ItemTrackingCodeRec.Modify();
        end;
    end;

    local procedure ModifyItemTrackingCode(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(ItemNo);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("Lot Specific Tracking", false);
        ItemTrackingCode.Validate("SN Specific Tracking", false);
        ItemTrackingCode.Modify(true);
    end;

    local procedure FindPurchaseItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindLast();
    end;

    local procedure FindItem(): Code[20]
    begin
        exit(LibraryInventory.CreateItemNo());
    end;

    local procedure FindItemTrackingCode(LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.SetRange("Lot Specific Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("Lot Sales Inbound Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("Lot Sales Outbound Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("SN Specific Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.SetRange("SN Sales Inbound Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.SetRange("SN Sales Outbound Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindLotNoFromItemLedgerEntry(): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindPurchaseItemLedgerEntry(ItemLedgerEntry);
        exit(ItemLedgerEntry."Lot No.");
    end;

    local procedure FindSerialNoFromItemLedgerEntry(): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindPurchaseItemLedgerEntry(ItemLedgerEntry);
        exit(ItemLedgerEntry."Serial No.");
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindWarehouseActivityNo(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"): Code[20]
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
        exit(WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentNo: Code[20]; ItemNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentNo);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindServiceInvoiceLine(var ServiceInvoiceLine: Record "Service Invoice Line"; ItemNo: Code[20])
    begin
        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Item);
        ServiceInvoiceLine.SetRange("No.", ItemNo);
        ServiceInvoiceLine.FindFirst();
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("No.", FindWarehouseActivityNo(SourceNo, Type));
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure OpenServiceShipmentLinesFromPostedServiceShipment(OrderNo: Code[20])
    var
        PostedServiceShipment: TestPage "Posted Service Shipment";
    begin
        PostedServiceShipment.OpenEdit();
        PostedServiceShipment.FILTER.SetFilter("Order No.", OrderNo);
        PostedServiceShipment.ServShipmentItemLines.ServiceShipmentLines.Invoke();
    end;

    local procedure OpenServiceOrdersPage(var ServiceOrders: TestPage "Service Orders"; DocumentNo: Code[20])
    begin
        ServiceOrders.OpenView();
        ServiceOrders.FILTER.SetFilter("No.", DocumentNo);
    end;

    local procedure OpenServiceOrderPage(var ServiceOrder: TestPage "Service Order"; DocumentNo: Code[20])
    begin
        ServiceOrder.OpenView();
        ServiceOrder.FILTER.SetFilter("No.", DocumentNo);
    end;

    local procedure UpdateServiceLineQuantity(var ServiceLine: Record "Service Line"; Quantity: Decimal)
    begin
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateReservationEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);
    end;

    local procedure UndoShipment(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);
    end;

    local procedure UndoConsumption(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);
    end;

    local procedure UpdateQuantityToConsume(var ServiceLine: Record "Service Line"; QtyToConsume: Decimal)
    begin
        ServiceLine.Validate("Qty. to Consume", QtyToConsume);
        ServiceLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        ActualMessage := Question;  // Store Confirm message to verify Confirm string in Tests.
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingActionsPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case ItemTrackingAction of
            ItemTrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        Commit();
        case ItemTrackingAction of
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingAction::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingAction::SelectEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.AvailabilityLotNo.AssertEquals(true);
                end;
            ItemTrackingAction::AssignLotManually:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines.Quantity_ItemTracking.SetValue(OriginalQuantity);
                    ItemTrackingLines."Quantity (Base)".SetValue(OriginalQuantity);
                end;
            ItemTrackingAction::AvailabilityLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    ItemTrackingLines.AvailabilityLotNo.AssertEquals(true);
                end;
            ItemTrackingAction::AvailabilitySerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    ItemTrackingLines.AvailabilitySerialNo.AssertEquals(AvailabilitySerialNo);
                end;
            ItemTrackingAction::LookupLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    ItemTrackingLines."Lot No.".Lookup();
                    ItemTrackingLines."Quantity (Base)".AssertEquals(OriginalQuantity);
                    ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(OriginalQuantity);
                end;
            ItemTrackingAction::CreateCustomizedSerialNo:
                ItemTrackingLines.CreateCustomizedSN.Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAndVerifyItemTrackingQtyPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Verify: Variant;
        ExpectedItemTrackingQty: Variant;
        VerifyAction: Boolean;
    begin
        LibraryVariableStorage.Dequeue(Verify);
        VerifyAction := Verify;
        if not VerifyAction then
            case ItemTrackingAction of
                ItemTrackingAction::SelectEntries:
                    ItemTrackingLines."Select Entries".Invoke();
                ItemTrackingAction::AssignSerialNo:
                    ItemTrackingLines."Assign Serial No.".Invoke();
            end
        else begin
            LibraryVariableStorage.Dequeue(ExpectedItemTrackingQty);
            Assert.AreEqual(Format(ExpectedItemTrackingQty), ItemTrackingLines.Quantity_ItemTracking.Value, ItemTrackingQtyErr);
        end;
        ItemTrackingLines.OK().Invoke();
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        QtyToHandle: Decimal;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingAction::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingAction::AdjustQtyToHandle:
                begin
                    ItemTrackingLines.First();
                    Evaluate(QtyToHandle, ItemTrackingLines."Qty. to Handle (Base)".Value);
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(QtyToHandle + LibraryVariableStorage.DequeueDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.QtyToCreate.SetValue(OriginalQuantity);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines."Serial No.".AssertEquals(LibraryVariableStorage.DequeueText());
        if GlobalCheckExpirationDate then
            PostedItemTrackingLines."Expiration Date".AssertEquals(GlobalExpirationDate);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentLinesHandler(var PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines")
    begin
        PostedServiceShipmentLines.ItemTrackingEntries.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesForUndoShipment(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines."Serial No.".AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsTrue(PostedItemTrackingLines.Quantity.AsInteger() < 0, 'Verify that undo entries are positive');
        if GlobalCheckExpirationDate then
            PostedItemTrackingLines."Expiration Date".AssertEquals(GlobalExpirationDate);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentLinesHandlerForUndoShipment(var PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines")
    begin
        PostedServiceShipmentLines.FILTER.SetFilter(Quantity, '<0');
        Assert.IsTrue(PostedServiceShipmentLines.Quantity.AsInteger() < 0, 'Verify that undo shipment entries are positive');
        PostedServiceShipmentLines.ItemTrackingEntries.Invoke();
    end;

    local procedure CalculatePlanForReqWksh(Item: Record Item)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        StartDate: Date;
        EndDate: Date;
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        StartDate := CalcDate('<-CM>', WorkDate());
        EndDate := CalcDate('<CM>', WorkDate());
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, StartDate, EndDate);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    local procedure VerifyItemLedgerEntryOnPost(var ServiceLine: Record "Service Line"; LotSpecific: Boolean; SerialNoSpecific: Boolean; CheckExpirationDate: Boolean; ExpirationDate: Date; UndoShipment: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        AggregatedQuantity: Integer;
        Sign: Integer;
    begin
        // Verify that the value of the field Quantity of the Item Ledger Entry is equal to the value of the field Qty. to Ship of the
        // relevant Service Line.
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Service);
        ItemLedgerEntry.SetRange("Order No.", ServiceLine."Document No.");
        if UndoShipment then begin
            ItemLedgerEntry.SetFilter(Quantity, '>0');
            Sign := 1;
        end else
            Sign := -1;
        repeat
            ItemLedgerEntry.SetRange("Order Line No.", ServiceLine."Line No.");
            ItemLedgerEntry.FindSet();
            AggregatedQuantity := 0;
            repeat
                ItemLedgerEntry.TestField("Item No.", ServiceLine."No.");
                if CheckExpirationDate and UndoShipment then
                    ItemLedgerEntry.TestField("Expiration Date", ExpirationDate);
                if SerialNoSpecific then begin
                    AggregatedQuantity := AggregatedQuantity + ItemLedgerEntry.Quantity;
                    ItemLedgerEntry.TestField(Quantity, Sign);
                    Assert.AreNotEqual('', ItemLedgerEntry."Serial No.", 'Verify that Serial number in ILE is not empty');
                end;
                if LotSpecific then
                    Assert.AreNotEqual('', ItemLedgerEntry."Lot No.", 'Verify that Lot number in ILE is not empty');

            until ItemLedgerEntry.Next() = 0;
            Assert.AreEqual(
              Sign * ServiceLine.Quantity, AggregatedQuantity, 'Verify the sum of ILE quantities matches the quantity shipped');
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceItemLineDetailsFactBox(ServiceQuote: TestPage "Service Quote"; ServiceItemNo: Code[20]; NoOfComponents: Integer; NoOfTroubleShooting: Integer)
    begin
        ServiceQuote.Control1906530507."Service Item No.".AssertEquals(ServiceItemNo);
        ServiceQuote.Control1906530507.ComponentList.AssertEquals(NoOfComponents);
        ServiceQuote.Control1906530507.Troubleshooting.AssertEquals(NoOfTroubleShooting);
    end;

    local procedure FindServiceLinesByHeaderNo(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure GetWarehouseEntries(var ServiceLine: Record "Service Line"; var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option)
    begin
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Serv. Order");
        WarehouseEntry.SetRange("Source No.", ServiceLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", ServiceLine."Line No.");
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.FindSet();
    end;

    local procedure VerifyWarehouseEntry(var ServiceLine: Record "Service Line"; var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; LotSpecific: Boolean; SerialNoSpecific: Boolean; CheckExpirationDate: Boolean; ExpirationDate: Date; UndoShipment: Boolean)
    var
        AggregatedQuantity: Integer;
        Sign: Integer;
    begin
        AggregatedQuantity := 0;
        if UndoShipment then
            Sign := 1
        else
            Sign := -1;

        repeat
            WarehouseEntry.TestField("Location Code", ServiceLine."Location Code");
            WarehouseEntry.TestField("Item No.", ServiceLine."No.");
            WarehouseEntry.TestField("Entry Type", EntryType);
            if CheckExpirationDate then
                WarehouseEntry.TestField("Expiration Date", ExpirationDate);
            if SerialNoSpecific then begin
                AggregatedQuantity := AggregatedQuantity + WarehouseEntry.Quantity;
                WarehouseEntry.TestField(Quantity, Sign);
                Assert.AreNotEqual('', WarehouseEntry."Serial No.", 'Verify that Serial number in warehouse entry is not empty');
            end;
            if LotSpecific then
                Assert.AreNotEqual('', WarehouseEntry."Lot No.", 'Verify that Lot number in warehouse entry is not empty');

        until WarehouseEntry.Next() = 0;
        Assert.AreEqual(
          Sign * ServiceLine.Quantity, AggregatedQuantity, 'Verify the sum of Warehouse entry quantities matches the quantity shipped');
    end;

    local procedure VerifyNoWarehouseEntriesCreated(var ServiceLine: Record "Service Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Serv. Order");
        WarehouseEntry.SetRange("Source No.", ServiceLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", ServiceLine."Line No.");
        Assert.AreEqual(false, WarehouseEntry.Find(), 'No Ware house entries are created');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExpirationDateOnPostedItemTrackingLinesHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    var
        LineCount: Integer;
    begin
        PostedItemTrackingLines.First();
        repeat
            PostedItemTrackingLines."Expiration Date".AssertEquals(ExpirationDate);
            LineCount += 1;
        until not PostedItemTrackingLines.Next();
        Assert.AreEqual(OriginalQuantity, LineCount, NumberOfLineEqualError);  // Verify Number of line Tracking Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SkilledResourceListPageHandler(var SkilledResourceList: TestPage "Skilled Resource List")
    begin
        Assert.AreEqual(StrSubstNo(SkilledResourceCaption, ServiceItemNo, ServiceItemNo), SkilledResourceList.Caption, ValidationError);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemComponentListPageHandler(var ServiceItemComponentList: TestPage "Service Item Component List")
    begin
        ServiceItemComponentList."No.".AssertEquals(No);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        Assert.AreEqual(No, CustomerLedgerEntries.FILTER.GetFilter("Customer No."), 'Customer No. is set correctly');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterCustomizedSNHandler(var EnterCustomizedSN: TestPage "Enter Customized SN")
    begin
        EnterCustomizedSN.CustomizedSN.SetValue(CustomizedSN);
        EnterCustomizedSN.Increment.SetValue(1);
        EnterCustomizedSN.QtyToCreate.SetValue(GlobalQty);
        EnterCustomizedSN.OK().Invoke();
    end;
}

