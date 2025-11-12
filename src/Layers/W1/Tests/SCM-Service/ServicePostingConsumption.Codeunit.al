// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;
using System.Utilities;

codeunit 136109 "Service Posting - Consumption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Consumption] [Service]
        IsInitialized := false;
    end;

    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        UnknownError: Label 'Unexpected Error';
        OrderDoesNotExist: Label 'You cannot undo consumption because the original service order %1 is already closed.';
        DeleteError: Label 'Service Header must not exist.';
        ServiceShipmentLineError: Label 'Service Shipment Line: %1.';
        CreateLotNo: Boolean;
        Quantity: Decimal;
        TrackingAction: Option AssignSerialNo,AssignLotNo,SelectEntries,EnterValues;
        ConsumeQuantityError: Label 'You cannot consume more than 1 units.';
        NoOfEntriesError: Label 'No of entries for %1 must be %2.';
        FieldError: Label '%1 must be equal  %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostingWithoutQuantity()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC-PP-C-1 - refer to TFS ID 20886.
        // Test error occurs on Posting Service Order without Quantity.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateQtyToShipOnServiceLine(ServiceLine, ServiceItemLine."Line No.", LibraryRandom.RandInt(10), 0);  // Use 0 for Boundary Value Testing.

        // 3. Verify: Verify that Service Order shows Error "Nothing to Post" on Posting as Ship and Consume.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostingPartially()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-C-4, TC-PP-C-6 - refer to TFS ID 20886.
        // Test Posted Entries after Posting Service Order as Ship and Consume.
        Initialize();

        // 1. Setup: Create Service Order.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);

        // 2. Exercise: Post Service Order as Ship and Consume Partially.
        UpdatePartialQtyOnServiceLines(ServiceItemLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify the Values of Service Line, Service Shipment Line, Item Ledger Entry, Resource Ledger Entry and Value Entry
        // with Values of Service Line.
        VerifyServiceLine(TempServiceLine, ServiceItemLine);
        VerifyPostedEntry(TempServiceLine);
        VerifyItemEntries(TempServiceLine);
        VerifyResourceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // [SCENARIO 380306] Test consumption on Service Line with Type Cost.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceCost(ServiceCost);
        CreateServiceHeader(ServiceHeader);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, LibraryRandom.RandInt(10));
        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Verify: Verify that Service Order doesn't show any Error on putting a value in "Qty. to Consume" field
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);
        Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Consume", UnknownError);

        // 4. Excercise: ship and consume
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 5. verify GL entries
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");

        // 5. verify GL entries, service ledger entries and shipment entries.
        VerifyGLEntryIsEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
        VerifyPostedEntry(TempServiceLineBeforePosting);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostAsShipAndConsumeHandler,ErrorMessagesPageHandler')]
    procedure CheckInventoryAdjmAccountMissingWhenPostingConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemForConsumption: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryAdjmtAccount: Code[20];
    begin
        // [SCENARIO 469181] if ship and consume ServiceOrder, it should throw error if GeneralPostingSetup."Inventory Adjmt. Account" is missing

        Initialize();

        // [GIVEN] Consumption item
        LibraryInventory.CreateItem(ItemForConsumption);

        // [GIVEN] Created Service Order with Service Item Line and Service Line
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemForConsumption."No.", LibraryRandom.RandInt(10));
        ServiceLine."Service Item Line No." := ServiceItemLine."Line No.";
        ServiceLine.Modify();

        // [GIVEN] "General Posting Setup" is without "Inventory Adjmt. Account" set
        GeneralPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");
        InventoryAdjmtAccount := GeneralPostingSetup."Inventory Adjmt. Account";
        GeneralPostingSetup."Inventory Adjmt. Account" := '';
        GeneralPostingSetup.Modify();

        // [GIVEN] Service Line "Qty. to Consume" is set
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity);
        Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Consume", UnknownError);

        // [WHEN],  try to post Service Order (same like from page)
        ServiceHeader.SendToPost(Codeunit::"Service-Post (Yes/No)");

        //[THEN] System should not post anything
        CheckServiceOrderIsNotPosted(ServiceHeader);

        //return setup to an original state
        GeneralPostingSetup."Inventory Adjmt. Account" := InventoryAdjmtAccount;
        GeneralPostingSetup.Modify();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesPageHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        //Inventory Adjmt. Account is missing in General Posting Setup Gen. Bus. Posting Group: DOMESTIC, Gen. Prod. Posting Group: MISC.
    end;

    local procedure CheckServiceOrderIsNotPosted(ServiceHeader: Record "Service Header")
    var
        ServiceHeader2: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceHeader2.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        Assert.IsTrue(ServiceShipmentHeader.IsEmpty, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostConsumptionWithLineDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // [SCENARIO 380306] Test consumption on Service Line with Type Cost with a line discount %.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceCost(ServiceCost);
        CreateServiceHeader(ServiceHeader);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, LibraryRandom.RandInt(10));
        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Verify: Verify that Service Order doesn't show any Error on putting a value in "Qty. to Consume" field
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity);
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);

        Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Consume", UnknownError);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 4. Excercise: ship and consume
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 5. verify GL entries
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");

        // 5. verify GL entries, service ledger entries and shipment entries.
        VerifyGLEntryIsEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
        VerifyPostedEntry(TempServiceLineBeforePosting);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostConsumptionWithNonLCY()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // [SCENARIO 380306] Test consumption on Service Line with Type Cost with non LCY.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceCost(ServiceCost);
        CreateServiceOrderWithCurrency(ServiceHeader);
        CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, LibraryRandom.RandInt(10));
        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Verify: Verify that Service Order doesn't show any Error on putting a value in "Qty. to Consume" field
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity);
        Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Consume", UnknownError);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 4. Excercise: ship and consume
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 5. verify GL entries
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");

        // 5. verify GL entries, service ledger entries and shipment entries.
        VerifyGLEntryIsEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
        VerifyPostedEntry(TempServiceLineBeforePosting);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostConsumptionWithLineDiscountNonLCY()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // [SCENARIO 380306] Test consumption on Service Line with Type Cost with non LCY with line discount %.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceCost(ServiceCost);
        CreateServiceOrderWithCurrency(ServiceHeader);
        CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, LibraryRandom.RandInt(10));
        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Verify: Verify that Service Order doesn't show any Error on putting a value in "Qty. to Consume" field
        UpdateServiceLineInsertTemp(TempServiceLineBeforePosting, ServiceLine);

        // 4. Excercise: ship and consume
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 5. verify GL entries
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");

        // 5. verify GL entries, service ledger entries and shipment entries.
        VerifyGLEntryIsEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
        VerifyPostedEntry(TempServiceLineBeforePosting);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // [SCENARIO 380306] Test consumption on Service Line with Type G/L Account.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceOrderWithServiceLine(
          ServiceHeader, ServiceLine, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Verify: Verify that Service Order "Qty. to Consume" field can take values.
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity);
        Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Consume", UnknownError);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 4. Excercise: ship and consume
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 5. verify GL entries
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        VerifyGLEntryIsEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
        VerifyPostedEntry(TempServiceLineBeforePosting);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountConsumptionWithLineDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // [SCENARIO 380306] Test consumption on Service Line with Type G/L Account and line discount.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
          LibraryRandom.RandIntInRange(10, 20));
        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Verify: Verify that Service Order "Qty. to Consume" field can take values.
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity);
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);
        Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Consume", UnknownError);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 4. Excercise: ship and consume
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 5. verify GL entries
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        VerifyGLEntryIsEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
        VerifyPostedEntry(TempServiceLineBeforePosting);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountConsumptionWithNonLCY()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // [SCENARIO 380306] Test consumption on Service Line with Type G/L Account with Non LCY.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceOrderWithCurrency(ServiceHeader);
        CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
          LibraryRandom.RandIntInRange(10, 20));
        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Verify: Verify that Service Order "Qty. to Consume" field can take values.
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity);
        Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Consume", UnknownError);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 4. Excercise: ship and consume
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 5. verify GL entries
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        VerifyGLEntryIsEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
        VerifyPostedEntry(TempServiceLineBeforePosting);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountConsumptionWithLineDiscountNonLCY()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // [SCENARIO 380306] Test consumption on Service Line with Type G/L Account with Non LCY with line discount %.
        // 1. Setup: Create Service Order add lines, qty to consume and line discount.
        Initialize();

        CreateServiceOrderWithCurrency(ServiceHeader);
        CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
          LibraryRandom.RandIntInRange(10, 20));
        CheckGeneralPostingSetupExists(ServiceLine);

        UpdateServiceLineInsertTemp(TempServiceLineBeforePosting, ServiceLine);

        // 2. Exercise: Ship and consume the order
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. verify entries
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        VerifyGLEntryIsEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
        VerifyPostedEntry(TempServiceLineBeforePosting);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderPostingFully()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-C-3, TC-PP-C-14 - refer to TFS ID 20886.
        // Test Posted Entries after Posting Service Order as Ship and Consume Fully.
        Initialize();

        // 1. Setup: Create Service Order.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);

        // 2. Exercise: Post Service Order as Ship and Consume Fully.
        UpdateFullQtyOnServiceLines(ServiceItemLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify the Service Order deleted and Values of Service Shipment Line, Item Ledger Entry, Resource Ledger Entry and
        // Value Entry Table with Values of Service Line.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), DeleteError);
        VerifyPostedEntry(TempServiceLine);
        VerifyItemEntries(TempServiceLine);
        VerifyResourceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostingPartiallyTwice()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
        TempServiceLine2: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-C-25, TC-PP-C-26 - refer to TFS ID 20886.
        // Test Posted Entries after Posting Service Order as Ship and Consume Twice.
        Initialize();

        // 1. Setup: Create Service Order, Post Service Order Partially as Ship and Consume.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        UpdatePartialQtyOnServiceLines(ServiceItemLine);

        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Post Service Order Partially again as Ship and Consume.
        UpdateConsumedQtyOnServiceLine(ServiceItemLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        SaveServiceLineInTempTable(TempServiceLine2, ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify the Quantity Consumed on Service Line and Item Ledger Entry, Value Entry Table with values of Service Line.
        VerifyUpdatedValueConsumedQty(TempServiceLine, TempServiceLine2, ServiceItemLine);
        VerifyItemEntries(TempServiceLine2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostingAfterInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
        TempServiceLine2: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-C-40 - refer to TFS ID 20886.
        // Test Posted Entries after Posting Service Order as Ship and Consume after Posting Ship and Invoice.
        Initialize();

        // 1. Setup: Create Service Order, Post Service Order Partially as Ship and Consume.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        UpdatePartialQtyToInvoice(ServiceItemLine);

        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 2. Exercise: Post Service Order Partially again as Ship and Consume.
        UpdateConsumedQtyOnServiceLine(ServiceItemLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");

        SaveServiceLineInTempTable(TempServiceLine2, ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify the Quantity Consumed, Quantity Invoiced on Service Line and Service Shipment Line, Item Ledger Entry, Value
        // Entry Table with values of Service Line.
        VerifyUpdatedValueConsumedQty(TempServiceLine, TempServiceLine2, ServiceItemLine);
        VerifyPostedEntry(TempServiceLine2);
        VerifyItemEntries(TempServiceLine2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostPartially()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [FEATURE] [Undo Consumption] [Service Shipment]
        // [SCENARIO 205882] Undoing consumption should create service shipment line, item ledger entry and resource ledger entry with opposite quantity and same posting date as on the original service shipment line, item entry and resource entry.
        Initialize();

        // [GIVEN] Service Order with posting date = WORKDATE.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);

        // [GIVEN] Service lines are set to be partially consumed.
        UpdatePartialQtyOnServiceLines(ServiceItemLine);

        // [GIVEN] Posting Date on the service lines are set to "D" > WORKDATE.
        UpdatePostingDateOnServiceLines(ServiceItemLine, LibraryRandom.RandDateFrom(ServiceHeader."Posting Date", 30));
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);

        // [GIVEN] The service lines are posted with Ship and Consume option.
        LibraryService.PostServiceOrderWithPassedLines(ServiceHeader, TempServiceLine, true, true, false);

        // [WHEN] Undo consumption.
        LibraryService.UndoConsumptionLinesByServiceOrderNo(ServiceItemLine."Document No.");

        // [THEN] Reversed Service Shipment Lines are created.
        VerifyUndoConsumptionEntries(TempServiceLine);

        // [THEN] Shipped and consumed quantity on Service lines in the Service Order are equal to 0.
        VerifyServiceLineAfterUndo(TempServiceLine);

        // [THEN] Posting Date on reversed item ledger entries is equal to "D".
        VerifyItemEntriesAfterUndo(TempServiceLine."Document No.");

        // [THEN] Posting Date on reversed resource ledger entries is equal to "D".
        VerifyResourceEntriesAfterUndo(TempServiceLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostAsShip()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        Quantity: Decimal;
    begin
        // Covers document number TC-PP-UC-05 - refer to TFS ID 20886.
        // Test error occurs on undo Consumption after Posting Service Order as Ship.
        Initialize();

        // 1. Setup: Create Service Order.
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
        UpdateQtyToInvoice(ServiceLine, ServiceItemLine."Line No.", Quantity, Quantity);

        // 2. Exercise: Post Service Order as Ship Partially.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify that Service Shipment Line shows Error "Nothing to Undo" on Undo Consumption.
        ServiceShipmentLine.SetRange("Order No.", ServiceItemLine."Document No.");
        ServiceShipmentLine.FindFirst();
        asserterror CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);
        Assert.ExpectedTestFieldError(ServiceShipmentLine.FieldCaption("Quantity Consumed"), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostFully()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        Quantity: Decimal;
    begin
        // Covers document number TC-PP-UC-07 - refer to TFS ID 20886.
        // Test error occurs on undo Consumption after Posting Service Order as Ship and Consume Fully.

        // 1. Setup: Create Service Order.
        Initialize();
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
        UpdateQtyToShipOnServiceLine(ServiceLine, ServiceItemLine."Line No.", Quantity, Quantity);

        // 2. Exercise: Post Service Order as Ship and Consume Fully.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify that Service Shipment Line shows Error "Order Not exist" on Undo Consumption.
        ServiceShipmentLine.SetRange("Order No.", ServiceItemLine."Document No.");
        ServiceShipmentLine.FindFirst();
        asserterror CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);
        Assert.AreEqual(StrSubstNo(OrderDoesNotExist, ServiceShipmentLine."Order No."), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPartLinewise()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-UC-08 - refer to TFS ID 20886.
        // Test undo Consumption after Posting Service Order as Ship and Consume from Service Line.

        // 1. Setup: Create Service Order.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);

        UpdatePartialQtyOnServiceLines(ServiceItemLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);

        // 2. Exercise: Post Service Order as Ship and Consume Partially for each Service Line Individual, Undo Consumption.
        PostServiceOrderLineByLine(ServiceHeader);
        LibraryService.UndoConsumptionLinesByServiceOrderNo(ServiceItemLine."Document No.");

        // 3. Verify: Verify the Quantity, Quantity Consumed on Service Shipment Line and Quantity Consumed on Service Line as well.
        VerifyUndoConsumptionEntries(TempServiceLine);
        VerifyServiceLineAfterUndo(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ConsumeAfterUndoConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-C-45, TC-PP-C-48 - refer to TFS ID 20886.
        // Test Posted Entries after Posting Service Order as Ship and Consume after undo Consumption.
        Initialize();

        // 1. Setup: Create Service Order, Post Service Order as Ship and Consume Partially.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);

        UpdatePartialQtyOnServiceLines(ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Post Service Order as Ship and Consume Partially, Undo Consumption.
        LibraryService.UndoConsumptionLinesByServiceOrderNo(ServiceItemLine."Document No.");
        UpdateFullQtyToConsume(ServiceItemLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify the Service Order deleted and Values of Service Shipment Line, Item Ledger Entry, Resource Ledger Entry and
        // Value Entry Table with Values of Service Line.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), DeleteError);
        VerifyPostedEntry(TempServiceLine);
        VerifyItemEntries(TempServiceLine);
        VerifyResourceLedgerEntry(TempServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostingPartiallyAutomatic()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-C-4, TC-PP-C-6 - refer to TFS ID 20886.
        // Test Posted Entries after Posting Service Order as Ship and Consume with "Automatic Cost Posting" and "Expected Cost Posted to
        // G/L" fields as True on Inventory Setup.
        Initialize();

        // 1. Setup: Create Service Order, Set "Automatic Cost Posting" and "Expected Cost Posted to G/L" fields as True on Inventory Setup.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        InventorySetupCostPosting();

        // 2. Exercise: Post Service Order as Ship and Consume Partially.
        UpdatePartialQtyOnServiceLines(ServiceItemLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify the Values of Service Line, Service Shipment Line, Item Ledger Entry, Resource Ledger Entry and Value Entry
        // with Values of Service Line.
        VerifyServiceLine(TempServiceLine, ServiceItemLine);
        VerifyPostedEntry(TempServiceLine);
        VerifyItemEntries(TempServiceLine);
        VerifyResourceLedgerEntry(TempServiceLine);
        VerifyGLEntry(ServiceItemLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPostingFullyAutomatic()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-C-14 - refer to TFS ID 20886.
        // Test Posted Entries after Posting Service Order as Ship and Consume Fully with "Automatic Cost Posting" and "Expected Cost
        // Posted to G/L" fields as True on Inventory Setup.
        Initialize();

        // 1. Setup: Create Service Order, Set "Automatic Cost Posting" and "Expected Cost Posted to G/L" fields as True on Inventory Setup.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        InventorySetupCostPosting();

        // 2. Exercise: Post Service Order as Ship and Consume Fully.
        UpdateFullQtyOnServiceLines(ServiceItemLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify the Service Order deleted and Values of Service Shipment Line, Item Ledger Entry, Resource Ledger Entry and
        // Value Entry Table with Values of Service Line.
        Assert.IsFalse(ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No."), DeleteError);
        VerifyPostedEntry(TempServiceLine);
        VerifyItemEntries(TempServiceLine);
        VerifyResourceLedgerEntry(TempServiceLine);
        VerifyGLEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionWithAutomatic()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // Covers document number TC-PP-UC-10 - refer to TFS ID 20886.
        // Test undo Consumption after Posting Service Order as Ship and Consume with "Automatic Cost Posting" and "Expected Cost Posted to
        // G/L" fields as True on Inventory Setup.
        Initialize();

        // 1. Setup: Create Service Order, Set "Automatic Cost Posting" and "Expected Cost Posted to G/L" fields as True on Inventory Setup.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        InventorySetupCostPosting();

        UpdatePartialQtyOnServiceLines(ServiceItemLine);
        SaveServiceLineInTempTable(TempServiceLine, ServiceItemLine);

        // 2. Exercise: Post Service Order as Ship and Consume Partially, Undo Consumption.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        LibraryService.UndoConsumptionLinesByServiceOrderNo(ServiceItemLine."Document No.");

        // 3. Verify: Verify the Quantity, Quantity Consumed on Service Shipment Line and Quantity Consumed on Service Line as well.
        VerifyUndoConsumptionEntries(TempServiceLine);
        VerifyServiceLineAfterUndo(TempServiceLine);
        VerifyGLEntry(TempServiceLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('UpdateQuantityPageHandler,PostAsShipAndConsumeHandler,ConfirmMessageHandler,PostedShipmentLineHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionSingleLine()
    begin
        // Test undo consumption for the Service Order consumed Quantity.

        UndoConsumptionServiceOrder();
    end;

    [Test]
    [HandlerFunctions('UpdateItemResourceHandler,ConfirmMessageHandler,ShipmentMultipleLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionMultipleLines()
    begin
        // Test undo consumption for the Service Order with multiple Service Lines.

        UndoConsumptionServiceOrder();
    end;

    local procedure UndoConsumptionServiceOrder()
    var
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        No: Code[20];
        ServiceShipmentHeaderNo: Code[20];
        Quantity: Decimal;
        InvoicedQuantity: Decimal;
        ExpectedCost: Decimal;
        ActualCost: Decimal;
        ExpectedCostACY: Decimal;
        ActualCostACY: Decimal;
    begin
        // 1. Setup: Create a Service Order.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.CreateCustomer(Customer);
        No := LibraryService.CreateServiceOrderHeaderUsingPage();
        CreateServiceItemLine(No, Customer."No.");
        OpenServiceLine(No);

        // 2. Exercise: Undo Consumption of the Service Order consumed Quantity.
        PostedServiceShipment.OpenView();
        PostedServiceShipment.FILTER.SetFilter("Order No.", No);
        ServiceShipmentHeaderNo := PostedServiceShipment."No.".Value();
        PostedServiceShipment.ServShipmentItemLines.ServiceShipmentLines.Invoke();

        // 3. Verify: Verify the undone Qty Consumed through the handler.
        // VERIFY: All ledger entries generated after undo matchup
        ItemLedgerEntry.SetRange("Document No.", ServiceShipmentHeaderNo);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.FindSet();

        Quantity := 0;
        InvoicedQuantity := 0;
        ExpectedCost := 0;
        ActualCost := 0;
        repeat
            Quantity += ItemLedgerEntry.Quantity;
            InvoicedQuantity += ItemLedgerEntry."Invoiced Quantity";

            ItemLedgerEntry.CalcFields("Cost Amount (Expected)");
            ExpectedCost += ItemLedgerEntry."Cost Amount (Expected)";

            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            ActualCost += ItemLedgerEntry."Cost Amount (Actual)";

            ItemLedgerEntry.CalcFields("Cost Amount (Expected) (ACY)");
            ExpectedCostACY += ItemLedgerEntry."Cost Amount (Expected) (ACY)";

            ItemLedgerEntry.CalcFields("Cost Amount (Actual) (ACY)");
            ActualCostACY += ItemLedgerEntry."Cost Amount (Actual) (ACY)";

        until ItemLedgerEntry.Next() = 0;

        Assert.AreEqual(0, Quantity, ItemLedgerEntry.FieldCaption(Quantity));
        Assert.AreEqual(0, InvoicedQuantity, ItemLedgerEntry.FieldCaption("Invoiced Quantity"));
        Assert.AreEqual(0, ExpectedCost, ItemLedgerEntry.FieldCaption("Cost Amount (Expected)"));
        Assert.AreEqual(0, ExpectedCostACY, ItemLedgerEntry.FieldCaption("Cost Amount (Expected) (ACY)"));
        Assert.AreEqual(0, ActualCost, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"));
        Assert.AreEqual(0, ActualCostACY, ItemLedgerEntry.FieldCaption("Cost Amount (Actual) (ACY)"));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,MessageHandler,ConfirmMessageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionSerialNumber()
    var
        ItemJournalLine: Record "Item Journal Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ItemJournal: TestPage "Item Journal";
        ServiceOrder: TestPage "Service Order";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test undo consumption in the Service Order for Item with Serial No.

        // 1. Setup: Create Item, assign Serial No. on Item Journal Line and post it with Item Journal.
        // Create a Service Order and post it as Ship and Consume.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItemJournalLine(ItemJournalLine, CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)));

        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalLine."Journal Batch Name");
        TrackingAction := TrackingAction::AssignSerialNo;  // Setting tracking action to execute Assign Serial No. Action on Item Tracking Lines Page.
        ItemJournal.ItemTrackingLines.Invoke();
        ItemJournal.Post.Invoke();
        LibraryUtility.GenerateGUID();  // Hack to fix problem with Generate GUID.
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        CreateServiceLine(ServiceHeader, ServiceItem."No.", ItemJournalLine."Item No.", ItemJournalLine.Quantity, ItemJournalLine.Quantity);
        TrackingAction := TrackingAction::SelectEntries;  // Setting tracking action to execute Select Entries Action on Item Tracking Lines Page.
        ServiceOrderPageOpenEdit(ServiceOrder, ServiceHeader."No.");
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);  // Post the Service Order as Ship and Consume.

        // 2. Exercise: Undo Consumption of the Quantity on Item Journal through posting the Service Credit Memo for it.
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceItem."Customer No.");
        CreateServiceLine(ServiceHeader, ServiceItem."No.", ItemJournalLine."Item No.", ItemJournalLine.Quantity, 0);  // Using Qty To Consume as 0.

        TrackingAction := TrackingAction::AssignSerialNo;  // Setting tracking action to execute Assign Serial No. Action on Item Tracking Lines Page.
        AssignSerialNumberToCreditMemo(ServiceCreditMemo, ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Verify that the Service Ledger Entry is created for the Service Credit Memo.
        VerifyCreditMemoServiceLedger(ServiceHeader."No.", ItemJournalLine.Quantity, ServiceItem."Customer No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoGLAccountConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // Undo Quantity to Consume on Service Line with Type G/L Account.
        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceOrderWithServiceLine(
          ServiceHeader, ServiceLine, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Excercise: ship and consume and undo
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity - 2);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        LibraryService.UndoConsumptionLinesByServiceDocNo(ServiceShipmentHeaderNo);

        // 5. verify GL entries are not created by undo (TFS 202716)
        VerifyGLAndVATEntriesForDocumentAreEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoGLAccountConsumptionWithMultipleShipments()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceShipmentHeaderNo: Code[20];
    begin
        // Undo Quantity to Consume on Service Line with multiple shipments.
        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceOrderWithServiceLine(
          ServiceHeader, ServiceLine, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Excercise: ship and consume twice and undo once
        UpdatePriceAndQtyToConsume(ServiceLine, LibraryRandom.RandInt(ServiceLine.Quantity - 2));
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        FindServiceLinesByHeaderNo(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Qty. to Consume", 1);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        LibraryService.UndoConsumptionLinesByServiceDocNo(ServiceShipmentHeaderNo);

        // 5. verify GL entries are not created, service ledger entries, shipment and service lines are created after undo
        VerifyGLAndVATEntriesForDocumentAreEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
        FindServiceLinesByHeaderNo(ServiceLine, ServiceHeader);

        ServiceLine.TestField("Quantity Consumed", 1);
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindLast();
        ServiceShipmentHeaderNo := ServiceShipmentHeader."No.";

        ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeaderNo);
        ServiceShipmentLine.FindLast();
        ServiceShipmentLine.TestField("Quantity Consumed", 1);
        ServiceShipmentLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoGLAccountConsumptionNonLCY()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // Undo Quantity to Consume on Service Line with Type G/L Account with non lcy customer.
        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceOrderWithCurrency(ServiceHeader);
        CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(10, 20));
        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Excercise: ship and consume and undo
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity - 2);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        LibraryService.UndoConsumptionLinesByServiceDocNo(ServiceShipmentHeaderNo);

        // 5. verify GL entries are not created by undo
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
        VerifyGLAndVATEntriesForDocumentAreEmpty(ServiceShipmentHeaderNo);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoGLAccountConsumptionWithLineDiscountNonLCY()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // Undo Quantity to Consume on Service Line with Type G/L Account with non lcy customer.
        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceOrderWithCurrency(ServiceHeader);
        CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(10, 20));
        CheckGeneralPostingSetupExists(ServiceLine);

        // 3. Excercise: ship and consume and undo
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity - 2);
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);

        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        LibraryService.UndoConsumptionLinesByServiceDocNo(ServiceShipmentHeaderNo);

        // 5. verify GL entries are not created by undo
        VerifyGLAndVATEntriesForDocumentAreEmpty(ServiceShipmentHeaderNo);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoCostConsumption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // Test undo consumption on Service Line with Type Cost.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceCost(ServiceCost);
        CreateServiceOrderWithServiceLine(ServiceHeader, ServiceLine, ServiceLine.Type::Cost, ServiceCost.Code);
        CheckGeneralPostingSetupExists(ServiceLine);

        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity - 1);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 3. Excercise: ship and consume and undo
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        LibraryService.UndoConsumptionLinesByServiceDocNo(ServiceShipmentHeaderNo);

        // 5. verify GL entries are not created, service ledger entries and shipment entries are created
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
        VerifyGLAndVATEntriesForDocumentAreEmpty(ServiceShipmentHeaderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoCostConsumptionWithMultipleShipments()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceShipmentHeaderNo: Code[20];
    begin
        // Test undo consumption on Service Line with Type Cost with mulitple shipments.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceCost(ServiceCost);
        CreateServiceOrderWithServiceLine(ServiceHeader, ServiceLine, ServiceLine.Type::Cost, ServiceCost.Code);
        CheckGeneralPostingSetupExists(ServiceLine);

        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity - 2);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 3. Excercise: ship and consume and undo
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        FindServiceLinesByHeaderNo(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Qty. to Consume", 1);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        LibraryService.UndoConsumptionLinesByServiceDocNo(ServiceShipmentHeaderNo);

        // 5. verify GL entries are not created, service ledger entries and shipment entries are created.
        VerifyGLAndVATEntriesForDocumentAreEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);

        FindServiceLinesByHeaderNo(ServiceLine, ServiceHeader);

        ServiceLine.TestField("Quantity Consumed", 1);
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindLast();
        ServiceShipmentHeaderNo := ServiceShipmentHeader."No.";

        ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeaderNo);
        ServiceShipmentLine.FindLast();
        ServiceShipmentLine.TestField("Quantity Consumed", 1);
        ServiceShipmentLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoCostConsumptionNonLCY()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // Test undo consumption on Service Line with Type Cost on a non lcy order.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceCost(ServiceCost);
        CreateServiceOrderWithCurrency(ServiceHeader);
        CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, LibraryRandom.RandIntInRange(10, 20));
        CheckGeneralPostingSetupExists(ServiceLine);

        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity - 1);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 3. Excercise: ship and consume and undo
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        LibraryService.UndoConsumptionLinesByServiceDocNo(ServiceShipmentHeaderNo);

        // 5. verify GL entries are not created, service ledger entries and shipment entries are created.
        VerifyGLAndVATEntriesForDocumentAreEmpty(ServiceShipmentHeaderNo);
        VerifyServiceLedgerEntriesAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoCostConsumptionWithLineDiscountNonLCY()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        TempServiceLineBeforePosting: Record "Service Line" temporary;
        ServiceShipmentHeaderNo: Code[20];
    begin
        // Test undo consumption on Service Line with Type Cost on a non lcy order.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Order.
        CreateServiceCost(ServiceCost);
        CreateServiceOrderWithCurrency(ServiceHeader);
        CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, LibraryRandom.RandIntInRange(10, 20));
        CheckGeneralPostingSetupExists(ServiceLine);

        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity - 1);
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);

        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);

        // 3. Excercise: ship and consume and undo
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        LibraryService.UndoConsumptionLinesByServiceDocNo(ServiceShipmentHeaderNo);

        // 4. verify GL entries are not created, service ledger entries and shipment entries are created.
        VerifyGLAndVATEntriesForDocumentAreEmpty(ServiceShipmentHeaderNo);
        VerifyServiceShipmentLineAfterConsumption(TempServiceLineBeforePosting, ServiceShipmentHeaderNo, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumeMoreThanAvailableQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Test error occurs on updating Qty. to Consume on Service Line greater than available Quantity after posting Service Order as Ship.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line, Post it as Receive, Create Service Order, select Item Tracking for Service Line
        // and Post Service Order as Ship.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader);

        // Use random for Quantity.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)),
          LibraryRandom.RandInt(10));

        TrackingAction := TrackingAction::AssignSerialNo;  // Assign global variable for page handler.
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithoutLocation(ServiceLine, ServiceHeader, PurchaseLine."No.");
        UpdateQtyToInvoice(ServiceLine, ServiceItemLine."Line No.", PurchaseLine.Quantity + 1, PurchaseLine.Quantity);  // 1 is important for test case.

        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.
        OpenServiceLine(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 2. Exercise: Update Qty. to Consume on Service Line greater than available Quantity.
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        asserterror
          ServiceLine.Validate(
            "Qty. to Consume",
            ServiceLine.Quantity - ServiceLine."Quantity Shipped" + LibraryRandom.RandInt(10));

        // 3. Verify: Verify error occurs "You cannot consume more than".
        Assert.ExpectedError(ConsumeQuantityError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumeWithSerialNo()
    begin
        // Test Posted Entries after posting Service Order as Ship and Consume with Item having Item Tracking Code for Serial No.

        ConsumeWithItemTracking(CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)), false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumeWithSerialAndLotNo()
    begin
        // Test Posted Entries after posting Service Order as Ship and Consume with Item having Item Tracking Code for Serial and Lot No.

        ConsumeWithItemTracking(CreateItemWithItemTrackingCode(CreateItemTrackingCode(true, true)), true);
    end;

    local procedure ConsumeWithItemTracking(ItemNo: Code[20]; CreateNewLotNo: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ShipmentHeaderNo: Code[20];
    begin
        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and Post it as Receive.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Use random for Quantity.

        // Assign global variables for page handler.
        TrackingAction := TrackingAction::AssignSerialNo;
        CreateLotNo := CreateNewLotNo;
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // 2. Exercise: Create Service Order, select Item Tracking for Service Line and Post it as Ship and Consume.
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithoutLocation(ServiceLine, ServiceHeader, PurchaseLine."No.");
        UpdateQtyToShipOnServiceLine(ServiceLine, ServiceItemLine."Line No.", PurchaseLine.Quantity, PurchaseLine.Quantity);

        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.
        OpenServiceLine(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify Service Ledger Entry, Value Entry and Item Ledger Entry.
        ShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        VerifyLedgerEntryAfterPosting(ShipmentHeaderNo, PurchaseLine."No.", PurchaseLine.Quantity);
        VerifyNoOfValueEntry(ShipmentHeaderNo, PurchaseLine.Quantity);
        VerifyNoOfItemLedgerEntry(ShipmentHeaderNo, PurchaseLine."No.", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumeWithLotNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ShipmentHeaderNo: Code[20];
    begin
        // Test Posted Entries after posting Service Order as Ship and Consume with Item having Item Tracking Code for Lot No.

        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and Post it as Receive.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader);

        // Use random for Quantity.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithItemTrackingCode(FindItemTrackingCode(true, false)),
          LibraryRandom.RandInt(10));

        TrackingAction := TrackingAction::AssignLotNo;  // Assign global variable for page handler.
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // 2. Exercise: Create Service Order, select Item Tracking for Service Line and Post it as Ship and Consume.
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithoutLocation(ServiceLine, ServiceHeader, PurchaseLine."No.");
        UpdateQtyToShipOnServiceLine(ServiceLine, ServiceItemLine."Line No.", PurchaseLine.Quantity, PurchaseLine.Quantity);

        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.
        OpenServiceLine(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify Service Ledger Entry, Value Entry and Item Ledger Entry.
        ShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        VerifyLedgerEntryAfterPosting(ShipmentHeaderNo, PurchaseLine."No.", PurchaseLine.Quantity);

        // Use 1 for Lot No.
        VerifyNoOfValueEntry(ShipmentHeaderNo, 1);
        VerifyNoOfItemLedgerEntry(ShipmentHeaderNo, PurchaseLine."No.", 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnShipmentWithSerialNo()
    begin
        // Test Item Tracking Entry on Posted Service Shipment after Posting Service Order with Item having Item Tracking Code for Serial No.

        ItemTrackingOnShipment(CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)), TrackingAction::AssignSerialNo, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnShipmentWithLotNo()
    begin
        // Test Item Tracking Entry on Posted Service Shipment after Posting Service Order with Item having Item Tracking Code for Lot No.

        ItemTrackingOnShipment(CreateItemWithItemTrackingCode(FindItemTrackingCode(true, false)), TrackingAction::AssignLotNo, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,PostedServiceShipmentLinesHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnShipmentWithSerialAndLotNo()
    begin
        // Test Item Tracking Entry on Posted Service Shipment after Posting Service Order with Item having Item Tracking Code for Serial and Lot No.

        ItemTrackingOnShipment(CreateItemWithItemTrackingCode(CreateItemTrackingCode(true, true)), TrackingAction::AssignSerialNo, true);
    end;

    local procedure ItemTrackingOnShipment(ItemNo: Code[20]; TrackingActionFrom: Option; CreateNewLotNo: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        PostedServiceShipment: TestPage "Posted Service Shipment";
    begin
        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line and Post it as Receive.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);  // 1 is important for test case.

        // Assign global variables for page handler.
        TrackingAction := TrackingActionFrom;
        CreateLotNo := CreateNewLotNo;
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Find Item Ledger Entry for page handler.
        ItemLedgerEntry.SetRange("Item No.", PurchaseLine."No.");
        ItemLedgerEntry.FindFirst();

        // 2. Exercise: Create Service Order, select Item Tracking for Service Line, Post it as Ship and Consume.
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithoutLocation(ServiceLine, ServiceHeader, PurchaseLine."No.");
        UpdateQtyToShipOnServiceLine(ServiceLine, ServiceItemLine."Line No.", PurchaseLine.Quantity, PurchaseLine.Quantity);

        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.
        OpenServiceLine(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 3. Verify: Verify Item tracking Entry on Posted Service Shipment performed on Posted Item Tracking Lines handler.
        PostedServiceShipment.OpenView();
        PostedServiceShipment.FILTER.SetFilter("No.", FindServiceShipmentHeader(ServiceHeader."No."));
        PostedServiceShipment.ServShipmentItemLines.ServiceShipmentLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostingWithSerialNo()
    begin
        // Test Undo Consumption after posting Service Order as Ship and Consume with Item having Item Tracking Code for Serial No.

        UndoConsumptionPostingWithItemTracking(
          CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)), TrackingAction::AssignSerialNo, false, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostingWithSerialNoWithoutCrMemo()
    begin
        // Test Undo Consumption after posting Service Order as Ship and Consume with Item having Item Tracking Code for Serial No.

        UndoConsumptionPostingWithItemTracking(
          CreateItemWithItemTrackingCode(FindItemTrackingCode(false, true)), TrackingAction::AssignSerialNo, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostingWithLotNo()
    begin
        // Test Undo Consumption after posting Service Order as Ship and Consume with Item having Item Tracking Code for Lot No.

        UndoConsumptionPostingWithItemTracking(
          CreateItemWithItemTrackingCode(FindItemTrackingCode(true, false)), TrackingAction::AssignLotNo, false, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostingWithLotNoWithoutCrMemo()
    begin
        // Test Undo Consumption after posting Service Order as Ship and Consume with Item having Item Tracking Code for Lot No.

        UndoConsumptionPostingWithItemTracking(
          CreateItemWithItemTrackingCode(FindItemTrackingCode(true, false)), TrackingAction::AssignLotNo, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostingWithSerialAndLotNo()
    begin
        // Test Undo Consumption after posting Service Order as Ship and Consume with Item having Item Tracking Code for Serial and Lot No.

        UndoConsumptionPostingWithItemTracking(
          CreateItemWithItemTrackingCode(FindItemTrackingCode(true, true)), TrackingAction::AssignSerialNo, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionPostingWithSerialAndLotNoWithoutCrMemo()
    begin
        // Test Undo Consumption after posting Service Order as Ship and Consume with Item having Item Tracking Code for Serial and Lot No.

        UndoConsumptionPostingWithItemTracking(
          CreateItemWithItemTrackingCode(FindItemTrackingCode(true, true)), TrackingAction::AssignSerialNo, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnterCostWithAccountCombineFullVATInService()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
    begin
        // Test cost with Full VAT calculate type account can be entered in Service Line.

        // 1. Setup: Create a customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // Create VAT Prod Posting Group, create VAT Posting Setup, create a G/L account combine Full VAT, create a Service Cost.
        CreateServiceCostWithAccountCombineFullVAT(ServiceCost, Customer."VAT Bus. Posting Group");

        // Create Service Header with Service Item Line.
        CreateServiceHeaderWithServiceItemLine(ServiceHeader, Customer."No.");

        // 2. Exercise & Verify: Enter cost in Service Line - Verify no error.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoConsumptionCreatesReversedServiceRegister()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceRegister: Record "Service Register";
        ServiceShipmentHeaderNo: Code[20];
        LastServiceLedgEntryNo: Integer;
        LastWarrantyLedgEntryNo: Integer;
    begin
        // [FEATURE] [Undo Consumption] [Service Shipment] [Service Register]
        // [SCENARIO 207606] Service Register should be created when "Undo Consumption" is run for posted service shipment.
        Initialize();

        // [GIVEN] Service Order with turned on warranty on service item line.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        ServiceItemLine.Validate(Warranty, true);
        ServiceItemLine.Modify(true);

        // [GIVEN] Service Lines are set to be shipped and consumed.
        UpdatePartialQtyOnServiceLines(ServiceItemLine);

        // [GIVEN] The Service Order is posted with "Ship and Consume" option.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        ServiceRegister.FindLast();
        LastServiceLedgEntryNo := ServiceRegister."To Entry No.";
        LastWarrantyLedgEntryNo := ServiceRegister."To Warranty Entry No.";

        // [WHEN] Undo Consumption for the posted service shipment.
        LibraryService.UndoConsumptionLinesByServiceOrderNo(ServiceItemLine."Document No.");

        // [THEN] Service Register entry is created showing nos. of first and last entries of service and warranty ledgers generated by the reversed consumption.
        VerifyServiceRegister(ServiceShipmentHeaderNo, LastServiceLedgEntryNo, LastWarrantyLedgEntryNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentCreatesReversedServiceRegister()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceRegister: Record "Service Register";
        ServiceShipmentHeaderNo: Code[20];
        LastServiceLedgEntryNo: Integer;
        LastWarrantyLedgEntryNo: Integer;
    begin
        // [FEATURE] [Undo Shipment] [Service Shipment] [Service Register]
        // [SCENARIO 207606] Service Register should be created when "Undo Shipment" is run for posted service shipment.
        Initialize();

        // [GIVEN] Service Order with turned on warranty on service item line.
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        ServiceItemLine.Validate(Warranty, true);
        ServiceItemLine.Modify(true);

        // [GIVEN] Service Lines are set to be shipped.
        UpdateFullQtyToShipOnServiceLines(ServiceItemLine);

        // [GIVEN] The Service Order is posted with "Ship" option.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceShipmentHeaderNo := FindServiceShipmentHeader(ServiceHeader."No.");
        ServiceRegister.FindLast();
        LastServiceLedgEntryNo := ServiceRegister."To Entry No.";
        LastWarrantyLedgEntryNo := ServiceRegister."To Warranty Entry No.";

        // [WHEN] Undo Shipment for the posted service shipment.
        LibraryService.UndoShipmentLinesByServiceOrderNo(ServiceItemLine."Document No.");

        // [THEN] Service Register entry is created showing nos. of first and last entries of service and warranty ledgers generated by the reversed shipment.
        VerifyServiceRegister(ServiceShipmentHeaderNo, LastServiceLedgEntryNo, LastWarrantyLedgEntryNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Posting - Consumption");
        // Initialize global variables.
        Clear(CreateLotNo);
        Clear(TrackingAction);
        Quantity := 0;

        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Posting - Consumption");

        // Create Demonstration Database
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Posting - Consumption");
    end;

    local procedure UndoConsumptionPostingWithItemTracking(ItemNo: Code[20]; TrackingActionFrom: Option; CreateNewLotNo: Boolean; UseCrMemo: Boolean)
    var
        ItemLedgerEntry2: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceShipmentLine2: Record "Service Shipment Line";
        EntryNo: Integer;
    begin
        // 1. Setup: Create Purchase Order, assign Item Tracking on Purchase Line, Post it as Receive, Create Service Order, select Item Tracking for
        // Service Line and Post it as Ship and Consume.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);  // 1 is important for test case.

        // Assign global variables for page handler.
        TrackingAction := TrackingActionFrom;
        CreateLotNo := CreateNewLotNo;
        OpenItemTrackingLinesForPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithoutLocation(ServiceLine, ServiceHeader, PurchaseLine."No.");
        UpdateQtyToShipOnServiceLine(ServiceLine, ServiceItemLine."Line No.", PurchaseLine.Quantity + LibraryRandom.RandInt(10), 1);  // 1 is important for test case.

        TrackingAction := TrackingAction::SelectEntries;  // Assign global variable for page handler.
        OpenServiceLine(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        EntryNo := FindItemLedgerEntryNo(ServiceLine."No.", ServiceHeader."No.");

        // 2. Exercise: a) Create Sales Credit Memo, assign Item Tracking Entries same as on Service Line and Post it  OR
        // b) Use the bulit-in undo consumption functionality  from posted service shipment
        if UseCrMemo then begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", ServiceHeader."Customer No.");
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ServiceLine."No.", 1);  // 1 is important for test case.

            TrackingAction := TrackingAction::EnterValues;  // Assign global variable for page handler.
            OpenItemTrackingLinesForSalesCreditMemo(SalesHeader."No.");
            LibrarySales.PostSalesDocument(SalesHeader, false, false);
        end else begin
            ServiceShipmentLine.FindLast();
            ServiceShipmentLine.SetRecFilter();
            CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);
        end;
        // 3. Verify: Verify Item Ledger Entry for Undo Consumption.
        ItemLedgerEntry2.Get(EntryNo);
        ItemLedgerEntry2.TestField("Shipped Qty. Not Returned", 0);
        if not UseCrMemo then begin
            ServiceShipmentLine2 := ServiceShipmentLine;
            ServiceShipmentLine2.Next();
            ServiceShipmentLine2.TestField(Quantity, -ServiceShipmentLine.Quantity);
            // Value entries:
            VerifyValueEntries();
        end;
    end;

    local procedure VerifyValueEntries()
    var
        ValueEntry: Record "Value Entry";
        ValueEntry2: Record "Value Entry";
    begin
        ValueEntry.Find('+');
        ValueEntry2 := ValueEntry;
        ValueEntry.Next(-1);
        ValueEntry.TestField("Valued Quantity", -ValueEntry2."Valued Quantity");
        ValueEntry.TestField("Item Ledger Entry Quantity", -ValueEntry2."Invoiced Quantity");
        ValueEntry.TestField("Invoiced Quantity", -ValueEntry2."Invoiced Quantity");
    end;

    local procedure AssignSerialNumberToCreditMemo(var ServiceCreditMemo: TestPage "Service Credit Memo"; No: Code[20])
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
        ServiceCreditMemo.ServLines.ItemTrackingLines.Invoke();
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
          ItemNo, LibraryRandom.RandInt(10));  // Use integer Random Value for Quantity for Item Tracking.

        // Validate Document No. as combination of Journal Batch Name and Line No.
        ItemJournalLine.Validate("Document No.", ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."));
        ItemJournalLine.Modify(true);
        Commit();
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

    local procedure CreateLineForDifferentTypes(var ServiceLines: TestPage "Service Lines"; Type: Enum "Service Line Type"; No: Code[20]; Quantity2: Decimal)
    begin
        ServiceLines.Type.SetValue(Type);
        ServiceLines."No.".SetValue(No);
        ServiceLines.Quantity.SetValue(Quantity2);
        ServiceLines."Qty. to Consume".SetValue(Quantity2 / 2);  // Using partial value for Qty to Consume.
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", '');
        PurchaseHeader.Validate("Expected Receipt Date", WorkDate());
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Location Code", '');
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceHeaderWithServiceItemLine(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
    end;

    local procedure CreateServiceItemLine(No: Code[20]; CustomerNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceOrder: TestPage "Service Order";
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceOrderPageOpenEdit(ServiceOrder, No);
        ServiceOrder."Customer No.".SetValue(CustomerNo);
        ServiceOrder.ServItemLines.ServiceItemNo.SetValue(ServiceItem."No.");
        ServiceOrder.ServItemLines.New();
        ServiceOrder.OK().Invoke();
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QtyToConsume: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Consume", QtyToConsume);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithoutLocation(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; No: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate("Location Code", '');
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line")
    begin
        Initialize();
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineForItem(ServiceHeader, ServiceItemLine."Line No.");
        CreateServiceLineForResource(ServiceHeader);
    end;

    local procedure CreateServiceLineForItem(ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        Item: Record Item;
        Counter: Integer;
    begin
        // Create 2 to 12 Service Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(10) do begin
            LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, 0, LibraryRandom.RandDec(10, 2));
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
            ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateServiceLineForResource(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        Counter: Integer;
    begin
        // Create 2 to 12 Service Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(10) do
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
    end;

    local procedure CreateServiceLineWithQuantity(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; QuantitytoSet: Decimal)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate(Quantity, QuantitytoSet);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrderWithCurrency(var ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // 1. Create Service Order - Service Header, Service Item Line and Service Line for Type Item.
        Initialize();

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        ServiceHeader.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceOrderWithServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; Type: Enum "Service Line Type"; No: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        CreateServiceHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, Type, No, LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost")
    begin
        // Using Random Number for Default Unit Cost.
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceCost.Validate("Cost Type", ServiceCost."Cost Type"::Other);
        ServiceCost.Validate("Default Unit Cost", LibraryRandom.RandDec(100, 2));
        ServiceCost.Modify(true);
    end;

    local procedure CreateServiceCostWithAccountCombineFullVAT(var ServiceCost: Record "Service Cost"; VATBusPostingGroupCode: Code[20])
    begin
        // Using Random Number for Default Unit Cost.
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Account No.", CreateGLAccountCombineFullVAT(VATBusPostingGroupCode));
        ServiceCost.Validate("Cost Type", ServiceCost."Cost Type"::Other);
        ServiceCost.Validate("Default Unit Cost", LibraryRandom.RandDec(100, 2));
        ServiceCost.Modify(true);
    end;

    local procedure CreateGLAccountCombineFullVAT(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(
          VATPostingSetup, VATBusPostingGroupCode,
          VATPostingSetup."VAT Calculation Type"::"Full VAT", LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGLAccount(GLAccount);

        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20]; VATCalType: Enum "Tax Calculation Type"; VATPct: Decimal)
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        VATPostingSetup.SetRange("VAT Calculation Type", VATCalType);
        if not VATPostingSetup.FindFirst() then begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProdPostingGroup.Code);
            VATPostingSetup.Validate("VAT Calculation Type", VATCalType);
            VATPostingSetup.Validate("VAT %", VATPct);
            VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountWithSalesSetup());
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLine: Record "Service Item Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceLine.FindSet();
    end;

    local procedure FindServiceLinesByHeaderNo(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
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

    local procedure FindItemLedgerEntryNo(ItemNo: Code[20]; DocumentNo: Code[20]): Integer
    var
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry2.SetRange("Item No.", ItemNo);
        ItemLedgerEntry2.SetRange("Document No.", FindServiceShipmentHeader(DocumentNo));
        ItemLedgerEntry2.FindFirst();

        ItemLedgerEntry := ItemLedgerEntry2;  // Assign global variable for page handler.
        exit(ItemLedgerEntry2."Entry No.");
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
        ItemTrackingCode.SetRange("Man. Warranty Date Entry Reqd.", false);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure InsertServiceLinesIntoTemp(ServiceLine: Record "Service Line"; var TempServiceLineBeforePosting: Record "Service Line" temporary)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();

        repeat
            TempServiceLineBeforePosting := ServiceLine;
            TempServiceLineBeforePosting.Insert();
        until ServiceLine.Next() = 0;
    end;

    local procedure InsertTempServiceLine(var TempServiceLine: Record "Service Line" temporary; Type: Enum "Service Line Type"; No: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("No.", No);
        ServiceLine.SetRange(Type, Type);
        ServiceLine.FindFirst();
        TempServiceLine.Init();
        TempServiceLine := ServiceLine;
        TempServiceLine.Insert();
    end;

    local procedure InventorySetupCostPosting()
    begin
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);
    end;

    local procedure OpenItemTrackingLinesForPurchaseOrder(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchLines."Item Tracking Lines".Invoke();
    end;

    local procedure OpenItemTrackingLinesForSalesCreditMemo(No: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
        SalesCreditMemo.SalesLines.ItemTrackingLines.Invoke();
    end;

    local procedure OpenServiceLine(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenView();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
    end;

    local procedure ServiceOrderPageOpenEdit(var ServiceOrder: TestPage "Service Order"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Order));
        ServiceOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure SaveServiceLineInTempTable(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQtyToShipOnServiceLine(ServiceLine: Record "Service Line"; ServiceItemLineLineNo: Integer; Quantity: Decimal; QtyToShip: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Ship", QtyToShip);
        ServiceLine.Validate("Qty. to Consume", QtyToShip);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateFullQtyToShipOnServiceLines(ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        FindServiceLine(ServiceLine, ServiceItemLine);
        repeat
            Quantity := LibraryRandom.RandInt(10);
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Validate(Quantity, Quantity);
            ServiceLine.Validate("Qty. to Ship", Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartialQtyOnServiceLines(ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        FindServiceLine(ServiceLine, ServiceItemLine);
        repeat
            Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
            UpdateQtyToShipOnServiceLine(ServiceLine, ServiceItemLine."Line No.", Quantity, Quantity * LibraryUtility.GenerateRandomFraction());
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateFullQtyOnServiceLines(ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        FindServiceLine(ServiceLine, ServiceItemLine);
        repeat
            Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
            UpdateQtyToShipOnServiceLine(ServiceLine, ServiceItemLine."Line No.", Quantity, Quantity);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePostingDateOnServiceLines(ServiceItemLine: Record "Service Item Line"; NewPostingDate: Date)
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ServiceItemLine);
        repeat
            ServiceLine.Validate("Posting Date", NewPostingDate);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateFullQtyToConsume(ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ServiceItemLine);
        repeat
            ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdatePartialQtyToInvoice(ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        FindServiceLine(ServiceLine, ServiceItemLine);
        repeat
            Quantity := LibraryRandom.RandInt(10);  // Use Random because value is not important.
            UpdateQtyToInvoice(ServiceLine, ServiceItemLine."Line No.", Quantity, Quantity * LibraryUtility.GenerateRandomFraction());
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQtyToInvoice(ServiceLine: Record "Service Line"; ServiceItemLineLineNo: Integer; Quantity: Decimal; QtyForPost: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Ship", QtyForPost);
        ServiceLine.Validate("Qty. to Invoice", QtyForPost);
        ServiceLine.Modify(true);
    end;

    local procedure UpdatePriceAndQtyToConsume(var ServiceLine: Record "Service Line"; QuantityToSet: Decimal)
    begin
        ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Consume", QuantityToSet);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateServiceLineInsertTemp(var TempServiceLineBeforePosting: Record "Service Line" temporary; var ServiceLine: Record "Service Line")
    begin
        UpdatePriceAndQtyToConsume(ServiceLine, ServiceLine.Quantity);
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);

        Assert.AreEqual(ServiceLine.Quantity, ServiceLine."Qty. to Consume", UnknownError);
        InsertServiceLinesIntoTemp(ServiceLine, TempServiceLineBeforePosting);
    end;

    local procedure PostServiceOrderLineByLine(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Invoice: Boolean;
        Consume: Boolean;
    begin
        Ship := true;
        Consume := true;
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Quantity Consumed", 0);
        ServiceLine.FindSet();
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
            ServiceHeader.Get(TempServiceLine."Document Type", TempServiceLine."Document No.");
            ServicePost.PostWithLines(ServiceHeader, TempServiceLine, Ship, Consume, Invoice);
            TempServiceLine.Delete();
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyCreditMemoServiceLedger(PreAssignedNo: Code[20]; Quantity: Integer; CustomerNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::"Credit Memo");
        ServiceLedgerEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField(Quantity, Quantity);
            ServiceLedgerEntry.TestField("Customer No.", CustomerNo);
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyPostedShipmentLine(var PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines"; Type: Enum "Service Line Type")
    begin
        PostedServiceShipmentLines.FILTER.SetFilter(Type, Format(Type));
        PostedServiceShipmentLines.Next();
        PostedServiceShipmentLines."Quantity Consumed".AssertEquals(-Quantity / 2);
    end;

    local procedure VerifyServiceLine(var TempServiceLine: Record "Service Line" temporary; ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
    begin
        TempServiceLine.FindSet();
        ServiceLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", TempServiceLine."Qty. to Ship");
            ServiceLine.TestField("Quantity Consumed", TempServiceLine."Qty. to Consume");
            ServiceLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyPostedEntry(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        TempServiceLine.FindSet();
        ServiceShipmentHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceShipmentHeader.FindLast();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.FindSet();
        repeat
            ServiceShipmentLine.TestField(Type, TempServiceLine.Type);
            ServiceShipmentLine.TestField("No.", TempServiceLine."No.");
            ServiceShipmentLine.TestField(Quantity, TempServiceLine."Qty. to Consume");
            ServiceShipmentLine.TestField("Quantity Consumed", TempServiceLine."Qty. to Consume");
            ServiceShipmentLine.Next();
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyItemEntries(var TempServiceLine: Record "Service Line" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        TempServiceLine.SetRange(Type, TempServiceLine.Type::Item);
        TempServiceLine.FindSet();
        ServiceShipmentHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceShipmentHeader.FindLast();
        repeat
            ServiceShipmentLine.Get(ServiceShipmentHeader."No.", TempServiceLine."Line No.");
            ItemLedgerEntry.Get(ServiceShipmentLine."Item Shpt. Entry No.");
            ItemLedgerEntry.TestField("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
            ItemLedgerEntry.TestField("Item No.", TempServiceLine."No.");
            ItemLedgerEntry.TestField(Quantity, -TempServiceLine."Qty. to Consume (Base)");
            ItemLedgerEntry.TestField("Invoiced Quantity", -TempServiceLine."Qty. to Consume (Base)");
            VerifyValueEntry(TempServiceLine, ItemLedgerEntry."Entry No.");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyResourceLedgerEntry(var TempServiceLine: Record "Service Line" temporary)
    var
        ResourceLedgerEntry: Record "Res. Ledger Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        TempServiceLine.SetRange(Type, TempServiceLine.Type::Resource);
        TempServiceLine.FindSet();
        ServiceShipmentHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceShipmentHeader.FindLast();
        ResourceLedgerEntry.SetRange("Entry Type", ResourceLedgerEntry."Entry Type"::Usage);
        ResourceLedgerEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        repeat
            ResourceLedgerEntry.SetRange("Resource No.", TempServiceLine."No.");
            ResourceLedgerEntry.FindFirst();
            ResourceLedgerEntry.TestField(Quantity, TempServiceLine."Qty. to Consume");
            ResourceLedgerEntry.TestField("Order Type", ResourceLedgerEntry."Order Type"::Service);
            ResourceLedgerEntry.TestField("Order No.", TempServiceLine."Document No.");
            ResourceLedgerEntry.TestField("Order Line No.", TempServiceLine."Line No.");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyValueEntry(var TempServiceLine: Record "Service Line" temporary; ItemLedgerEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.");
        ValueEntry.TestField("Item No.", TempServiceLine."No.");
        ValueEntry.TestField("Valued Quantity", -TempServiceLine."Qty. to Consume (Base)");
        ValueEntry.TestField("Invoiced Quantity", -TempServiceLine."Qty. to Consume (Base)");
        ValueEntry.TestField("Source No.", TempServiceLine."Customer No.");
        ValueEntry.TestField("Cost Amount (Actual)",
          -Round(
            TempServiceLine."Unit Cost (LCY)" * TempServiceLine."Qty. to Consume", LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure UpdateConsumedQtyOnServiceLine(ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship" * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
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

    local procedure VerifyUpdatedValueConsumedQty(var TempServiceLine: Record "Service Line" temporary; var TempServiceLine2: Record "Service Line" temporary; ServiceItemLine: Record "Service Item Line")
    var
        ServiceLine: Record "Service Line";
    begin
        TempServiceLine.FindFirst();
        TempServiceLine2.FindFirst();
        ServiceLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", TempServiceLine."Qty. to Ship" + TempServiceLine2."Qty. to Ship");
            ServiceLine.TestField("Quantity Invoiced", TempServiceLine."Qty. to Invoice" + TempServiceLine2."Qty. to Invoice");
            ServiceLine.TestField("Quantity Consumed", TempServiceLine."Qty. to Consume" + TempServiceLine2."Qty. to Consume");
            TempServiceLine.Next();
            TempServiceLine2.Next();
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyUndoConsumptionEntries(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        TotalQuantity: Decimal;
        TotalConsumedQuantity: Decimal;
    begin
        TempServiceLine.FindSet();
        ServiceShipmentLine.SetRange("Order No.", TempServiceLine."Document No.");
        repeat
            TotalQuantity := 0;
            TotalConsumedQuantity := 0;
            ServiceShipmentLine.SetRange(Type, TempServiceLine.Type);
            ServiceShipmentLine.SetRange("No.", TempServiceLine."No.");
            ServiceShipmentLine.FindSet();
            repeat
                TotalQuantity += ServiceShipmentLine.Quantity;
                TotalConsumedQuantity += ServiceShipmentLine."Quantity Consumed";
            until ServiceShipmentLine.Next() = 0;
            Assert.AreEqual(TotalQuantity, 0, StrSubstNo(ServiceShipmentLineError, TotalQuantity));
            Assert.AreEqual(TotalConsumedQuantity, 0, StrSubstNo(ServiceShipmentLineError, TotalConsumedQuantity));
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyItemEntriesAfterUndo(ServiceOrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceOrderNo);
        ServiceShipmentLine.SetRange(Type, ServiceShipmentLine.Type::Item);
        ServiceShipmentLine.FindSet();
        repeat
            ItemLedgerEntry.Get(ServiceShipmentLine."Item Shpt. Entry No.");
            ItemLedgerEntry.TestField("Posting Date", ServiceShipmentLine."Posting Date");
        until ServiceShipmentLine.Next() = 0;
    end;

    local procedure VerifyResourceEntriesAfterUndo(ServiceOrderNo: Code[20])
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", ServiceOrderNo);
        ServiceShipmentLine.SetRange(Type, ServiceShipmentLine.Type::Resource);
        ServiceShipmentLine.FindFirst();
        ResLedgerEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
        ResLedgerEntry.SetFilter(Quantity, '<%1', 0);
        ResLedgerEntry.FindSet();
        repeat
            ResLedgerEntry.TestField("Posting Date", ServiceShipmentLine."Posting Date");
        until ResLedgerEntry.Next() = 0;
    end;

    local procedure VerifyServiceLineAfterUndo(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        TempServiceLine.FindSet();
        ServiceLine.SetRange("Document Type", TempServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", TempServiceLine."Document No.");
        ServiceLine.SetRange("Service Item Line No.", TempServiceLine."Service Item Line No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField(Type, TempServiceLine.Type);
            ServiceLine.TestField("No.", TempServiceLine."No.");
            ServiceLine.TestField(Quantity, TempServiceLine.Quantity);
            ServiceLine.TestField("Quantity Shipped", 0);
            ServiceLine.TestField("Quantity Consumed", 0);
            TempServiceLine.Next();
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyGLEntry(OrderNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindLast();
        GLEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        GLEntry.FindFirst();
    end;

    local procedure VerifyGLEntryIsEmpty(ShipmentHeaderNo: Code[20])
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.SetRange("Document No.", ShipmentHeaderNo);
        Assert.RecordIsEmpty(DummyGLEntry);
    end;

    local procedure VerifyVATEntryIsEmpty(ShipmentHeaderNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", ShipmentHeaderNo);
        Assert.RecordIsEmpty(VATEntry);
    end;

    local procedure VerifyGLAndVATEntriesForDocumentAreEmpty(ShipmentHeaderNo: Code[20])
    begin
        VerifyGLEntryIsEmpty(ShipmentHeaderNo);
        VerifyVATEntryIsEmpty(ShipmentHeaderNo);
    end;

    local procedure VerifyServiceLedgerEntriesAfterConsumption(var TempServiceLineBeforePosting: Record "Service Line" temporary; ShipmentHeaderNo: Code[20]; IsUndo: Boolean)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceShipmentHeader: Record "Service Shipment Header";
        SignFactor: Integer;
        CurrencyFactor: Decimal;
        UnitPriceLCY: Decimal;
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", ShipmentHeaderNo);

        TempServiceLineBeforePosting.SetFilter(Type, '%1|%2',
          TempServiceLineBeforePosting.Type::"G/L Account", TempServiceLineBeforePosting.Type::Cost);
        ServiceLedgerEntry.SetFilter(Type, '%1|%2',
          ServiceLedgerEntry.Type::"G/L Account", ServiceLedgerEntry.Type::"Service Cost");
        TempServiceLineBeforePosting.SetFilter("Qty. to Consume", '>0');
        TempServiceLineBeforePosting.FindSet();
        if IsUndo then
            SignFactor := -1
        else
            SignFactor := 1;

        ServiceShipmentHeader.Get(ShipmentHeaderNo);
        CurrencyFactor := 1;
        if ServiceShipmentHeader."Currency Code" <> '' then
            CurrencyFactor := ServiceShipmentHeader."Currency Factor";

        repeat
            ServiceLedgerEntry.SetRange("No.", TempServiceLineBeforePosting."No.");
            ServiceLedgerEntry.SetRange("Entry Type", ServiceLedgerEntry."Entry Type"::Usage);
            if IsUndo then
                ServiceLedgerEntry.FindLast()
            else
                ServiceLedgerEntry.FindFirst();
            ServiceLedgerEntry.TestField(Quantity, SignFactor * TempServiceLineBeforePosting."Qty. to Consume");
            UnitPriceLCY := TempServiceLineBeforePosting."Unit Price" / CurrencyFactor;
            Assert.AreNearlyEqual(ServiceLedgerEntry."Unit Price", UnitPriceLCY, LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(FieldError, ServiceLedgerEntry.FieldCaption("Unit Price"), UnitPriceLCY, ServiceLedgerEntry.TableCaption()));
            ServiceLedgerEntry.TestField(Amount, 0);
            ServiceLedgerEntry.TestField("Charged Qty.", 0);

            ServiceLedgerEntry.SetRange("Entry Type", ServiceLedgerEntry."Entry Type"::Consume);
            if IsUndo then
                ServiceLedgerEntry.FindLast()
            else
                ServiceLedgerEntry.FindFirst();
            ServiceLedgerEntry.TestField(Quantity, SignFactor * -TempServiceLineBeforePosting."Qty. to Consume");
            Assert.AreNearlyEqual(ServiceLedgerEntry."Unit Price", -UnitPriceLCY, LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(FieldError, ServiceLedgerEntry.FieldCaption("Unit Price"), UnitPriceLCY, ServiceLedgerEntry.TableCaption()));
            ServiceLedgerEntry.TestField(Amount, 0);

        until TempServiceLineBeforePosting.Next() = 0;
    end;

    local procedure VerifyServiceShipmentLineAfterConsumption(var TempServiceLine: Record "Service Line" temporary; ServiceShipmentHeaderNo: Code[20]; IsUndo: Boolean)
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        SignFactor: Integer;
    begin
        // Verify service shipment line quantities match after all shipments are undone
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", TempServiceLine."Line No.");
            ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeaderNo);
            if IsUndo then begin
                SignFactor := -1;
                ServiceShipmentLine.FindLast();
            end else begin
                SignFactor := 1;
                ServiceShipmentLine.FindFirst();
            end;
            ServiceShipmentLine.TestField("Quantity Consumed", SignFactor * TempServiceLine."Qty. to Consume");
            ServiceShipmentLine.TestField(Quantity, SignFactor * TempServiceLine."Qty. to Consume");
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceRegister(ServiceShipmentNo: Code[20]; LastServiceLedgEntryNo: Integer; LastWarrantyLedgEntryNo: Integer)
    var
        ServiceRegister: Record "Service Register";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        ServiceRegister.FindLast();

        ServiceLedgerEntry.SetCurrentKey("Entry No.");
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", ServiceShipmentNo);
        ServiceLedgerEntry.SetFilter("Entry No.", '>%1', LastServiceLedgEntryNo);

        WarrantyLedgerEntry.SetCurrentKey("Entry No.");
        WarrantyLedgerEntry.SetRange("Document No.", ServiceShipmentNo);
        WarrantyLedgerEntry.SetFilter("Entry No.", '>%1', LastWarrantyLedgEntryNo);

        ServiceLedgerEntry.FindFirst();
        WarrantyLedgerEntry.FindFirst();
        ServiceRegister.TestField("From Entry No.", ServiceLedgerEntry."Entry No.");
        ServiceRegister.TestField("From Warranty Entry No.", WarrantyLedgerEntry."Entry No.");

        ServiceLedgerEntry.FindLast();
        WarrantyLedgerEntry.FindLast();
        ServiceRegister.TestField("To Entry No.", ServiceLedgerEntry."Entry No.");
        ServiceRegister.TestField("To Warranty Entry No.", WarrantyLedgerEntry."Entry No.");
    end;

    local procedure CheckGeneralPostingSetupExists(ServiceLine: Record "Service Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if GeneralPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group") then
            exit;

        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
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
            TrackingAction::EnterValues:
                begin
                    ItemTrackingLines."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
                    ItemTrackingLines."Lot No.".SetValue(ItemLedgerEntry."Lot No.");
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
                    ItemTrackingLines."Appl.-from Item Entry".SetValue(ItemLedgerEntry."Entry No.");
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostAsShipAndConsumeHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 4;  // Post as Ship and Consume.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines."Serial No.".AssertEquals(ItemLedgerEntry."Serial No.");
        PostedItemTrackingLines."Lot No.".AssertEquals(ItemLedgerEntry."Lot No.");
        PostedItemTrackingLines.Quantity.AssertEquals(ItemLedgerEntry.Quantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentLinesHandler(var PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines")
    begin
        PostedServiceShipmentLines.ItemTrackingEntries.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedShipmentLineHandler(var PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines")
    begin
        PostedServiceShipmentLines.UndoConsumption.Invoke();
        // Verifying the Service Shipment Line Quantity which was Undone.
        PostedServiceShipmentLines.Next();
        PostedServiceShipmentLines."Quantity Consumed".AssertEquals(-Quantity / 2);  // Using partial value for Quantity Consumed.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(CreateLotNo);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines.ItemTrackingLines.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShipmentMultipleLinesHandler(var PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines")
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Undo consumption of the Service Lines.
        PostedServiceShipmentLines.UndoConsumption.Invoke();
        PostedServiceShipmentLines.Last();
        PostedServiceShipmentLines.UndoConsumption.Invoke();

        // Verifying the Service Shipment Lines Quantity which was Undone.
        VerifyPostedShipmentLine(PostedServiceShipmentLines, ServiceShipmentLine.Type::Item);
        VerifyPostedShipmentLine(PostedServiceShipmentLines, ServiceShipmentLine.Type::Resource);
        PostedServiceShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateItemResourceHandler(var ServiceLines: TestPage "Service Lines")
    var
        Item: Record Item;
        Resource: Record Resource;
        ServHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        Item.Modify(true);
        LibraryResource.CreateResourceNew(Resource);
        Quantity := LibraryRandom.RandDec(100, 2);  // Assign random Quantity to global variable Quantity.
        CreateLineForDifferentTypes(ServiceLines, TempServiceLine.Type::Item, Item."No.", Quantity);
        ServiceLines.Next();
        CreateLineForDifferentTypes(ServiceLines, TempServiceLine.Type::Resource, Resource."No.", Quantity);
        ServiceLines.Next();

        // Post the service Order as Ship and Consume.
        InsertTempServiceLine(TempServiceLine, TempServiceLine.Type::Item, Item."No.");
        InsertTempServiceLine(TempServiceLine, TempServiceLine.Type::Resource, Resource."No.");

        ServHeader.Get(TempServiceLine."Document Type", TempServiceLine."Document No.");
        LibraryService.PostServiceOrderWithPassedLines(ServHeader, TempServiceLine, true, true, false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateQuantityPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        Item.Modify(true);
        Quantity := LibraryRandom.RandDec(100, 2);  // Assign random Quantity to global variable Quantity.
        CreateLineForDifferentTypes(ServiceLines, ServiceLine.Type::Item, Item."No.", Quantity);

        // Post the service Order as Ship and Consume.
        ServiceLines.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

