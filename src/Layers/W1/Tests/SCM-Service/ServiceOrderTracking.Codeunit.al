// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using System.TestLibraries.Utilities;

codeunit 136129 "Service Order Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Tracking] [Service]
        IsInitialized := false;
    end;

    var
        ServiceLine: Record "Service Line";
        PurchaseLine: Record "Purchase Line";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        WrongDocumentError: Label '''Document No is incorrect in Order Tracking: %1 does not contain %2\''.';
        RollBack: Label 'ROLLBACK.';
        LocationCodeB: Code[10];
        TrackingAction: Option "None",AssignSerialNo,AssignLotNo,SelectEntries,EnterValues,VerifyValues;
        ExpectedError: Label 'The built-in action = OK is not found on the page.';
        SelectedQuantityError: Label '''You cannot select more than %1 units.''';
        Quantity: Decimal;
        LotNo: Code[50];
        SerialNo: Code[50];
        NegativeSelectedQuantityError: Label '''The value must be greater than or equal to 0. Value: %1.''';
        MissingTrackingLinesErr: Label 'There are missing Item Tracking Lines in Posted Service Invoice.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Order Tracking");
        // Clear Globals between Test Cases
        Clear(ServiceLine);
        Clear(PurchaseLine);
        Clear(TrackingAction);
        Quantity := 0;
        Clear(LotNo);
        Clear(SerialNo);
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Order Tracking");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Order Tracking");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ServiceOrderTrackingPage')]
    [Scope('OnPrem')]
    procedure ServiceLineTracking()
    var
        Item: Record Item;
    begin
        Initialize();
        // Test Order Tracking Entries from Service Line with Item having Order Tracking Policy Tracking Only.
        // Variation: Tracking Only, Location Equal, Service Order
        ServiceOrderWithTracking(LocationA(), Item."Order Tracking Policy"::"Tracking Only");

        // 2. Exercise: Run Order Tracking page from Service Line.
        ServiceLine.ShowTracking(); // Page Handler ServiceOrderTrackingPage

        // 3. Verification will happen through the Test Page for Order Tracking,
        // The global ServiceLine and PurchaseLine is used for verification.

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PurchaseOrderTrackingPage')]
    [Scope('OnPrem')]
    procedure PurchaseLineTracking()
    var
        Item: Record Item;
        PurchaseOrderSubform: Page "Purchase Order Subform";
    begin
        Initialize();
        // Test Order Tracking Entries from Purchase Line with Item having Order Tracking Policy Tracking Only.
        // Variation: Tracking Only, Location Equal, Purchase Order
        ServiceOrderWithTracking(LocationA(), Item."Order Tracking Policy"::"Tracking Only");

        // 2. Exercise: Run Order Tracking page from Purchase Line.
        PurchaseOrderSubform.SetRecord(PurchaseLine);
        PurchaseOrderSubform.ShowTracking(); // Page Handler PurchaseOrderTrackingPage

        // 3. Verification will happen through the Test Page for Order Tracking,
        // The global ServiceLine and PurchaseLine is used for verification.

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NoTrackingPage')]
    [Scope('OnPrem')]
    procedure ServiceLineTrackingWithNone()
    var
        Item: Record Item;
    begin
        Initialize();
        // Test Order Tracking Entries from Service Line with Item having Order Tracking Policy None.
        // Variation: Tracking None, Location Equal, Service Order
        ServiceOrderWithTracking(LocationA(), Item."Order Tracking Policy"::None);

        // 2. Exercise: Run Order Tracking page from Service Line.
        ServiceLine.ShowTracking(); // Page Handler NoTrackingPage

        // 3. Verification will happen through the Test Page for Order Tracking,
        // The global ServiceLine and PurchaseLine is used for verification.

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NoTrackingPage')]
    [Scope('OnPrem')]
    procedure ServiceLineTrackingLocation()
    var
        Item: Record Item;
    begin
        Initialize();
        // Verify that two orders with different locations cannot be used for Order Tracking
        // Variation: Tracking Only, Location Different, Service Order
        ServiceOrderWithTracking(LocationB(), Item."Order Tracking Policy"::"Tracking Only");

        // 2. Exercise: Run Order Tracking page from Service Line.
        ServiceLine.ShowTracking(); // Page Handler NoTrackingPage

        // 3. Verification will happen through the Test Page for Order Tracking,
        // The global ServiceLine and PurchaseLine is used for verification.

        TearDown();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmMessageHandler,SerialNoItemTrackingListPageHandler,ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure SerialNoOnServiceLineToReserve()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Check Serial No. suggested at the time of Reservation.

        // 1. Setup: Create Purchase Order and Service Order, assign Item Tracking and post Purchase Order as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignSerialNo;  // Assign global variable for page handler.
        CreateAndPostPurchaseDocument(PurchaseLine, false, true);  // LotSpecific as False and SNSpecific as True.
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.");
        SerialNo := ItemLedgerEntry."Serial No.";  // Assign global variable for page handler.

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 2. Exercise.
        ServiceLine.ShowReservation();  // Open Reservation to Invoke page handler.

        // 3. Verify: Verification of Serial No. is done in SerialNoItemTrackingListPageHandler page handler.
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", 1);  // Value 1 is taken because only one Serial No. is selected here.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnServiceLineWithItemTracking()
    begin
        // Check Error on the created Service Line with Item Tracking.

        // 1. Setup: Create Purchase Order, Service Order and assign Item Tracking.
        Initialize();
        TrackingAction := TrackingAction::AssignSerialNo;  // Assign global variable for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, false, true);  // LotSpecific as False and SNSpecific as True.

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.

        // 2. Exercise.
        asserterror ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Error.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmMessageHandler,ItemTrackingSummaryPageHandler,LotNoItemTrackingListPageHandler,ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure LotNoOnServiceLineToReserve()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Check Lot No suggested at the time of Reservation.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and Post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignLotNo;  // Assign global variable for page handler.
        CreateAndPostPurchaseDocument(PurchaseLine, true, false);  // LotSpecific as True and SNSpecific as False.
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.");
        LotNo := ItemLedgerEntry."Lot No.";  // Assign global variable for page handler.

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 2. Exercise.
        ServiceLine.ShowReservation();  // Open Reservation to Invoke page handler.

        // 3. Verify: Verification of Lot No. is done in LotNoItemTrackingListPageHandler page handler.
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,VerifyItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingSelectEntriesOnServiceLine()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check values on Item Tracking Summary page.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignLotNo;  // Assign global variable for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, true, false);  // LotSpecific as True and SNSpecific as False.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Quantity := PurchaseLine.Quantity;  // Assign global variable for page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.

        // 2. Exercise: Open Service Lines page.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verification done in VerifyItemTrackingSummaryPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,SetSelectedQuantityOnItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorForSelectEntriesOnServiceLine()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check error for Selected Quantity on created Service Line with Item Tracking.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignLotNo;  // Assign global variable for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, true, false);  // LotSpecific as True and SNSpecific as False.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Quantity := PurchaseLine.Quantity;  // Assign global variable for page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.

        // 2. Exercise.
        asserterror ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify error.
        Assert.ExpectedError(StrSubstNo(SelectedQuantityError, Quantity));
    end;

    [Test]
    [HandlerFunctions('VerifyItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingWithAssignLotNoOnServiceLine()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check values on the Item Tracking Lines page for Assign Lot No.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignLotNo;  // Assign global variable for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, true, false);  // LotSpecific as True and SNSpecific as False.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Quantity := PurchaseLine.Quantity;  // Assign global variable for page handler.

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verification done in 'VerifyItemTrackingLinesPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('VerifyItemTrackingLinesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingWithAssignSerialNoOnServiceLine()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check values on the Item Tracking Lines page for Assign Serial No.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignSerialNo;  // Assign global variables for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, false, true);  // LotSpecific as False and SNSpecific as True.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Quantity := PurchaseLine.Quantity;  // Assign global variables for page handler.

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.

        // 2. Exercise.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verification done in 'VerifyItemTrackingLinesPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('VerifyItemTrackingLinesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithItemTrackingAssignSerialNo()
    var
        ServiceHeader: Record "Service Header";
        PurchaseHeader: Record "Purchase Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Check posting of Service Order as Ship and verify the shipment.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignSerialNo;  // Assign global variable for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, false, true);  // LotSpecific as FALSE and SNSpecific as TRUE.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Quantity := PurchaseLine.Quantity;  // Assign global variable for page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify.
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentLine.SetRange("No.", ServiceLine."No.");
        ServiceShipmentLine.FindFirst();
        ServiceShipmentLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastNoUsedInServiceOrder()
    var
        NoSeriesLine: Record "No. Series Line";
        ServiceHeader: Record "Service Header";
        NoSeries: Codeunit "No. Series";
    begin
        // Check Last No. Used In No. Series for Service Invoice when Item created with Item Tracking Code.

        // Setup: Create and Update Service Line with Item with Item Tracking Code.
        Initialize();
        FindNoSeriesLine(NoSeriesLine);
        CreateAndUpdateServiceLine(
          ServiceLine, CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)), LibraryRandom.RandInt(10));
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // Exercise: Post Service Order. Will allocate and save a document no.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Last No. Used in No. Series of Service Invoice.
        ServiceHeader.Find();
        FindNoSeriesLine(NoSeriesLine);
        Assert.AreEqual(NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), ServiceHeader."Posting No.", 'Wrong last used invoice number.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LastNoUsedInPostedServiceInvoice()
    var
        ItemJournalLine: Record "Item Journal Line";
        NoSeriesLine: Record "No. Series Line";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        NoSeries: Codeunit "No. Series";
        TrackingActionForSerialNo: Option "None",AssignSerialNo,AssignLotNo,SelectEntries,EnterValues,VerifyValues;
    begin
        // Check Last No. Used In No. Series for Posted Service Invoice when Item created with Item Tracking Code.

        // Setup: Create and Post Item Journal by assigning Serial No. and Select Serial No. to Service Line.
        Initialize();
        CreateAndPostItemJournalLine(ItemJournalLine, CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)));
        CreateAndUpdateServiceLine(ServiceLine, ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        LibraryVariableStorage.Enqueue(TrackingActionForSerialNo::SelectEntries);
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking Assign And Select Page Handler.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // 2. Exercise: Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Last No. Used in No. Series of Posted Service Invoice.
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        FindNoSeriesLine(NoSeriesLine);
        Assert.AreEqual(NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"), ServiceInvoiceHeader."No.", 'Wrong last used invoice number.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,VerifyInformationItemTrackingSummaryPageHandlerForLotNo')]
    [Scope('OnPrem')]
    procedure InformationFeildsOnItemTrackingSummaryPageWithAssignLotNo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Information Field values on Item Tracking Summary page with Assign Lot No. on Service Order.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignLotNo;  // Assign global variable for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, true, false);  // LotSpecific as True and SNSpecific as False.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Quantity := PurchaseLine.Quantity;  // Assign global variables for page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.

        // 2. Exercise: Open Service Lines page.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verification done in 'VerifyInformationItemTrackingSummaryPageHandlerForLotNo' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,VerifyInformationItemTrackingSummaryPageHandlerForSerialNo')]
    [Scope('OnPrem')]
    procedure InformationFeildsOnItemTrackingSummaryPageWithAssignSerialNo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Information Field values on Item Tracking Summary page with Assign Serial No. on Service Order.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignSerialNo;  // Assign global variable for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, false, true);  // LotSpecific as True and SNSpecific as False.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Quantity := PurchaseLine.Quantity;  // Assign global variables for page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.

        // 2. Exercise: Open Service Lines page.
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verification done in 'VerifyInformationItemTrackingSummaryPageHandlerForSerialNo' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,NegativeSelectedQuantityOnItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeValueInSelectedQuantityOnItemTrackingSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Error while negative values is taken in the Selected Quantity field on Item Tracking Summary page with Assign Lot No. on Service Order.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and post it as Receive.
        Initialize();
        TrackingAction := TrackingAction::AssignLotNo;  // Assign global variable for page handler.
        CreatePurchaseOrderWithItemTracking(PurchaseLine, true, false);  // LotSpecific as True and SNSpecific as False.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Quantity := PurchaseLine.Quantity;  // Assign global variables for page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.

        // 2. Exercise: Open Service Lines page.
        asserterror ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify error.
        Assert.ExpectedError(StrSubstNo(NegativeSelectedQuantityError, -Quantity));
    end;

    [Test]
    [HandlerFunctions('VerifyItemTrackingLinesPageHandler,QuantityToCreatePageHandler,PostedItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingEntriesOnPostedServiceInvoice()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ItemNo: Code[20];
        Quantity: Integer;
    begin
        // [FEATURE] [Item Tracking] [Value Entry Relation]
        // [SCENARIO 380073] Item Tracking Entries reviewed from Posted Service Invoice, should show Item Tracking that was set on Service Item Line before posting.
        Initialize();

        // [GIVEN] Serial Nos. tracked Item.
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemNo := CreateItemWithItemTrackingCode(ItemTrackingCode.Code);

        // [GIVEN] Service Item Line with Item and Quantity = "N".
        Quantity := LibraryRandom.RandInt(10);
        CreateServiceHeaderWithSerialNoTrackedLine(ServiceHeader, ItemNo, Quantity);

        // [WHEN] Post Service Order with "Ship and Invoice" option.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] There are "N" Item Tracking Entries for Service Posted Invoice.
        // Verification is done in PostedItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);
        ServiceInvoiceLine.SetRange("No.", ItemNo);
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.ShowItemTrackingLines();
    end;

    local procedure ServiceOrderWithTracking(ServiceLocation: Code[10]; TrackingPolicy: Enum "Order Tracking Policy")
    var
        Item: Record Item;
    begin
        CreateItemWithTrackingPolicy(Item, TrackingPolicy);
        CreatePurchaseLine(PurchaseLine, FindVendor(), Item."No.");
        CreateServiceOrder(ServiceLine, PurchaseLine, ServiceLocation);
        Commit();
    end;

    local procedure AssignSerialNumberInItemJournal(ItemJournalLineBatchName: Code[10])
    var
        ItemJournal: TestPage "Item Journal";
        AssignSerialNoInItemJournal: Option "None",AssignSerialNo,AssignLotNo,SelectEntries,EnterValues,VerifyValues;
    begin
        Commit();  // Commit is used to avoid Test failure.
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalLineBatchName);
        LibraryVariableStorage.Enqueue(AssignSerialNoInItemJournal::AssignSerialNo);
        ItemJournal.ItemTrackingLines.Invoke();
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateItemWithTrackingPolicy(var Item: Record Item; OrderTrackingPolicy: Enum "Order Tracking Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          LibraryRandom.RandIntInRange(2, 10));
        ItemJournalLine.Validate(
          "Document No.",
          CopyStr(LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), DATABASE::"Item Journal Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Journal Line", ItemJournalLine.FieldNo("Document No."))));
        ItemJournalLine.Modify(true);
        AssignSerialNumberInItemJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateServiceOrder(var ServiceLine: Record "Service Line"; PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, PurchaseLine."No.");
        UpdateServiceLine(ServiceLine, LocationCode, PurchaseLine.Quantity);
    end;

    local procedure CreateItemWithItemTrackingCode(ItemTrackingCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrderWithItemTracking(var PurchaseLine: Record "Purchase Line"; LotSpecific: Boolean; SNSpecific: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, FindVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithItemTrackingCode(FindItemTrackingCode(LotSpecific, SNSpecific)),
          LibraryRandom.RandInt(10));
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateAndUpdateServiceLine(var ServiceLine: Record "Service Line"; No: Code[20]; PurchaseLineQuantity: Decimal)
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, PurchaseLineQuantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceHeaderWithSerialNoTrackedLine(var ServiceHeader: Record "Service Header"; ItemNo: Code[20]; Quantity: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        CreateAndUpdateServiceLine(ServiceLine, ItemNo, Quantity);
        TrackingAction := TrackingAction::AssignSerialNo;
        ServiceLine.OpenItemTrackingLines();
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; LotSpecific: Boolean; SNSpecific: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithItemTracking(PurchaseLine, LotSpecific, SNSpecific);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure FindItemTrackingCode(LotSpecific: Boolean; SNSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("Lot Sales Inbound Tracking", LotSpecific);
        ItemTrackingCode.SetRange("Lot Sales Outbound Tracking", LotSpecific);
        ItemTrackingCode.SetRange("SN Sales Inbound Tracking", SNSpecific);
        ItemTrackingCode.SetRange("SN Sales Outbound Tracking", SNSpecific);
        ItemTrackingCode.SetRange("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindNoSeriesLine(var NoSeriesLine: Record "No. Series Line")
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        NoSeriesLine.SetRange("Series Code", ServiceMgtSetup."Posted Service Invoice Nos.");
        NoSeriesLine.FindFirst();
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; LocationCode: Code[10]; Quantity: Decimal)
    begin
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate(Quantity, Quantity * LibraryUtility.GenerateRandomFraction());
        ServiceLine.Validate("Needed by Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        ServiceLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderTrackingPage(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(0); // Untracked Quantity
        OrderTracking."Item No.".AssertEquals(ServiceLine."No.");
        OrderTracking."Total Quantity".AssertEquals(ServiceLine.Quantity); // Quantity on the Line
        OrderTracking.Quantity.AssertEquals(-ServiceLine.Quantity);
        VerifyDocumentNo(OrderTracking.Name.Value, PurchaseLine."Document No."); // Purchase Order xxxx
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderTrackingPage(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(PurchaseLine.Quantity - ServiceLine.Quantity); // Untracked Quantity
        OrderTracking."Item No.".AssertEquals(ServiceLine."No.");
        OrderTracking."Total Quantity".AssertEquals(PurchaseLine.Quantity); // Quantity on the Line
        OrderTracking.Quantity.AssertEquals(ServiceLine.Quantity);
        VerifyDocumentNo(OrderTracking.Name.Value, ServiceLine."Document No."); // Service xxxx
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoTrackingPage(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(ServiceLine.Quantity); // Untracked Quantity
        OrderTracking."Total Quantity".AssertEquals(ServiceLine.Quantity); // Quantity on the Line
    end;

    local procedure VerifyDocumentNo(Name: Text[30]; DocumentNo: Text[30])
    begin
        Assert.IsTrue(StrPos(Name, DocumentNo) > 0, StrSubstNo(WrongDocumentError, Name, DocumentNo));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure Teardown()
    begin
        asserterror Error(RollBack);
    end;

    local procedure FindVendor(): Code[20]
    begin
        exit(LibraryPurchase.CreateVendorNo());
    end;

    local procedure LocationA(): Code[10]
    begin
        exit('');
    end;

    local procedure LocationB(): Code[10]
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        if LocationCodeB = '' then begin
            LibraryWarehouse.CreateLocation(Location);
            LocationCodeB := Location.Code;
        end;
        exit(LocationCodeB);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        Commit();
        case TrackingAction of
            TrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingAction::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotNoItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList."Lot No.".AssertEquals(LotNo);
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SerialNoItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.FILTER.SetFilter("Serial No.", SerialNo);
        ItemTrackingList.First();
        ItemTrackingList."Serial No.".AssertEquals(SerialNo);
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary."Total Quantity".AssertEquals(Quantity);
        ItemTrackingSummary."Total Requested Quantity".AssertEquals(0);
        ItemTrackingSummary."Total Available Quantity".AssertEquals(Quantity);
        ItemTrackingSummary."Selected Quantity".AssertEquals(Quantity);
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetSelectedQuantityOnItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary."Selected Quantity".SetValue(Quantity + 1);  // Added 1 to take the value more than Quantity.
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case TrackingAction of
            TrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingAction::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingAction::VerifyValues:
                begin
                    ItemTrackingLines.Quantity_ItemTracking.AssertEquals(Quantity);
                    ItemTrackingLines."Quantity (Base)".AssertEquals(Quantity);
                    ItemTrackingLines."Qty. to Invoice (Base)".AssertEquals(Quantity);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyInformationItemTrackingSummaryPageHandlerForSerialNo(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary."Selected Quantity".SetValue(0);  // Added 0 because every line contains 1 Quantity with serial No. and here lesser value needed than Quantity.
        ItemTrackingSummary.MaxQuantity1.AssertEquals(Quantity);
        ItemTrackingSummary.Selected1.AssertEquals(Quantity - 1);  // (Quantity - 1) taken here as Selected Quantityfield value.
        ItemTrackingSummary.Undefined1.AssertEquals(Quantity - (Quantity - 1));  // (Quantity - 1) taken here as Selected1 field value.
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyInformationItemTrackingSummaryPageHandlerForLotNo(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary."Selected Quantity".SetValue(Quantity - 1);  // Added 1 to take the value Less than Quantity.
        ItemTrackingSummary.MaxQuantity1.AssertEquals(Quantity);
        ItemTrackingSummary.Selected1.AssertEquals(Quantity - 1);  // (Quantity - 1) taken here as Selected Quantityfield value.
        ItemTrackingSummary.Undefined1.AssertEquals(Quantity - (Quantity - 1));  // (Quantity - 1) taken here as Selected1 field value.
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NegativeSelectedQuantityOnItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary."Selected Quantity".SetValue(-Quantity);  // Taken negative value because value is important.
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingForAssignAndSelectPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        AssignValueForTracking: Variant;
        AssignedValue: Option "None",AssignSerialNo,AssignLotNo,SelectEntries,EnterValues,VerifyValues;
    begin
        LibraryVariableStorage.Dequeue(AssignValueForTracking);
        AssignedValue := AssignValueForTracking;  // Assign TrackingActionOfEntries2(Variant) to TrackingActionOfEntries(Option).
        case AssignedValue of
            AssignedValue::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            AssignedValue::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    var
        NumberOfLines: Integer;
    begin
        NumberOfLines := LibraryVariableStorage.DequeueInteger();

        PostedItemTrackingLines.First();
        repeat
            NumberOfLines -= 1;
        until not PostedItemTrackingLines.Next();

        Assert.AreEqual(0, NumberOfLines, MissingTrackingLinesErr);
    end;
}

