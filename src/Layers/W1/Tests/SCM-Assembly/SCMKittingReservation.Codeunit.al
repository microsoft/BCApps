// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Warehouse.Journal;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;
using Microsoft.Inventory.Tracking;
using Microsoft.Assembly.Document;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Document;
using Microsoft.Assembly.History;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Setup;
using Microsoft.Assembly.Setup;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Sales.History;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;

codeunit 137099 "SCM Kitting Reservation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Reservation] [SCM]
        isInitialized := false;
    end;

    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        LocationWhite: Record Location;
        LibraryRandom: Codeunit "Library - Random";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        CannotMatchItemTracking: Label 'Cannot match item tracking.';
        ReservationEntryDelete: Label '%1 must be deleted.';
        PurchaseLineOrder: Label 'Purchase Line, Order';
        StartingDateError: Label 'You have modified the Starting Date from ';
        ReservationEntryShouldBeBlank: Label 'Reservation Entry should be blank';
        ReleasedProdOrderLine: Label 'Released Prod. Order Line';
        BindingOrderToOrderError: Label 'You cannot state item tracking on a demand when it is linked to a supply by Binding = Order-to-Order.';
        AvailabilityWarningsConfirmMessage: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        NotAffectExistingEntriesMsg: Label 'The change will not affect existing entries.';
        BeforeWorkDateMsg: Label 'is before work date %1 in one or more of the assembly lines';
        ItemInPickWorksheetLinesErr: Label 'Item in Pick Worksheet is not correct.';
        PickWorksheetLinesErr: Label 'The total lines in Pick Worksheet are not correct.';
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,SetLotNo;
        ReservationMode: Option " ",ReserveFromCurrentLine,Verify,VerifyBlank,AvailableToReserve;
        UndoPostedAssemblyOrderQst: Label 'Do you want to undo posting of the posted assembly order?';
        RecreateAssemblyOrderQst: Label 'Do you want to recreate the assembly order from the posted assembly order?';
        ReserveSpecificLotNoQst: Label 'Do you want to reserve specific tracking numbers?';
        ReservationEntryErr: Label 'Reservation Entry is not correct for %1.';
        QtyIsNotCorrectErr: Label 'Quantity is incorrect in Sales Invoice Line';
        IsBeforeWorkDateMsg: Label 'is before work date';
        QtyBaseIsNotCorrectErr: Label 'Quantity(Base) is incorrect in Item Tracking Lines';

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderAgainstAssemblyOrderWithoutLot()
    begin
        // Setup.
        Initialize();
        CreateAssemblyOrderWithoutLotAndSalesOrderWithLot(false);  // Post Sales Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderAndSalesOrderWithLot()
    begin
        // Setup.
        Initialize();
        CreateAssemblyOrderWithoutLotAndSalesOrderWithLot(true);  // Post Sales Order as TRUE.
    end;

    local procedure CreateAssemblyOrderWithoutLotAndSalesOrderWithLot(PostSalesOrder: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        LotNo: Code[50];
        OldStockOutWarning: Boolean;
    begin
        // Update Stock Out Warning on Assembly Setup. Create Assembly Order without Tracking. Create and Post Item Journal Line.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        CreateAssemblyOrderWithLotItemTracking(AssemblyHeader, false);
        LotNo := CreateAndPostItemJournalLine(AssemblyHeader."Item No.", AssemblyHeader.Quantity, true);  // Use Tracking as TRUE.

        // Exercise.
        CreateSalesOrderWithReservationAndLotTracking(SalesHeader, AssemblyHeader);

        // Verify.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Item Ledger Entry", LotNo,
          AssemblyHeader.Quantity);
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Sales Line", LotNo,
          -AssemblyHeader.Quantity);

        if PostSalesOrder then begin
            // Exercise: Add Component inventory, Assign Tracking on Assembly Order and Post Assembly Order. Post Sales Order as Ship.
            AddComponentInventoryAndPostAssemblyOrder(AssemblyHeader, AssemblyHeader.Quantity / 2, true);  // Value Required for Add Component to Inventory. Use Tracking as TRUE.
            LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Ship as TRUE.

            // Verify.
            VerifyReservationEntryExists(AssemblyHeader."Item No.");
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderAgainstAssemblyOrderWithLot()
    begin
        // Setup.
        Initialize();
        CreateAssemblyOrderWithLotAndSalesOrderWithLot(false);  // Post Sales Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderWithoutLotAndSalesOrderWithLot()
    begin
        // Setup.
        Initialize();
        CreateAssemblyOrderWithLotAndSalesOrderWithLot(true);  // Post Sales Order as TRUE.
    end;

    local procedure CreateAssemblyOrderWithLotAndSalesOrderWithLot(PostSalesOrder: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        LotNo: Code[50];
        OldStockOutWarning: Boolean;
    begin
        // Update Stock Out Warning on Assembly Setup. Create Assembly Order with Tracking. Create and Post Item Journal Line.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        CreateAssemblyOrderWithLotItemTracking(AssemblyHeader, true);  // Use Tracking as TRUE.
        LotNo := CreateAndPostItemJournalLine(AssemblyHeader."Item No.", AssemblyHeader.Quantity, true);  // Use Tracking as TRUE.

        // Exercise.
        CreateSalesOrderWithReservationAndLotTracking(SalesHeader, AssemblyHeader);

        // Verify.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Item Ledger Entry", LotNo,
          AssemblyHeader.Quantity);
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Sales Line", LotNo,
          -AssemblyHeader.Quantity);

        if PostSalesOrder then begin
            // Exercise: Add Component Inventory and Post Assembly Order. Post Sales Order as Ship.
            AddComponentInventoryAndPostAssemblyOrder(AssemblyHeader, AssemblyHeader.Quantity / 2, false);  // Value Required for Add Component to Inventory.
            LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Ship as TRUE.

            // Verify.
            VerifyReservationEntryExists(AssemblyHeader."Item No.");
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveSOAgainstAOAfterApplyingTrackingOnSOError()
    begin
        // Setup.
        Initialize();
        ReserveSOAgainstAOAfterApplyingTrackingOnSO(false);  // Specific Reservation as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderAgainstAOWithSpecificReservation()
    begin
        // Setup.
        Initialize();
        ReserveSOAgainstAOAfterApplyingTrackingOnSO(true);  // Specific Reservation as FALSE.
    end;

    local procedure ReserveSOAgainstAOAfterApplyingTrackingOnSO(SpecificReservation: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Code[50];
        OldStockOutWarning: Boolean;
    begin
        // Update Stock Out Warning on Assembly Setup. Create Assembly Order with Tracking. Create and Post Item Journal Line. Create Sales Order.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        CreateAssemblyOrderWithLotItemTracking(AssemblyHeader, true);  // Use Tracking as TRUE.
        LotNo := CreateAndPostItemJournalLine(AssemblyHeader."Item No.", AssemblyHeader.Quantity / 2, true);  // Post Item Journal Line of Partial Quantity. Use Tracking as TRUE.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateSalesOrder(
          SalesHeader, SalesLine, AssemblyHeader."Due Date", AssemblyHeader."Item No.", AssemblyHeader.Quantity, '', false, true);  // Use Tracking as TRUE.

        // Exercise.
        EnqueueValuesForHandlers(false, false);
        asserterror SalesLine.ShowReservation();

        // Verify.
        Assert.ExpectedError(CannotMatchItemTracking);

        if SpecificReservation then begin
            // Exercise.
            EnqueueValuesForHandlers(false, true);
            SalesLine.ShowReservation();

            // Verify.
            VerifyReservationEntry(
              ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Item Ledger Entry", LotNo,
              AssemblyHeader.Quantity / 2);  // Verify Partial Reservation Quantity.
            VerifyReservationEntry(
              ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Sales Line", LotNo,
              -AssemblyHeader.Quantity / 2);  // Verify Partial Reservation Quantity.
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSOAgainstAOWithoutNonSpecificReservation()
    begin
        // Setup.
        Initialize();
        ReserveFromAOAfterApplyingTrackingOnSalesOrder(false);  // Non Specific Reservation as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSOAgainstAOWithNonSpecificReservation()
    begin
        // Setup.
        Initialize();
        ReserveFromAOAfterApplyingTrackingOnSalesOrder(true);  // Non Specific Reservation as TRUE.
    end;

    local procedure ReserveFromAOAfterApplyingTrackingOnSalesOrder(NonSpecificReservation: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Code[50];
        LotNo2: Code[50];
        OldStockOutWarning: Boolean;
    begin
        // Update Stock Out Warning on Assembly Setup. Create Assembly Order with Tracking. Create and Post Item Journal Line. Create Sales Order.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        LotNo := CreateAssemblyOrderWithLotItemTracking(AssemblyHeader, true);  // Use Tracking as TRUE.
        LotNo2 := CreateAndPostItemJournalLine(AssemblyHeader."Item No.", AssemblyHeader.Quantity / 2, true);  // Post Item Journal Line of Partial Quantity. Use Tracking as TRUE.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateSalesOrder(
          SalesHeader, SalesLine, AssemblyHeader."Due Date", AssemblyHeader."Item No.", AssemblyHeader.Quantity, '', false, true);  // Use Tracking as TRUE.

        // Exercise.
        EnqueueValuesForHandlers(true, true);
        SalesLine.ShowReservation();

        // Verify.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Item Ledger Entry", LotNo2,
          AssemblyHeader.Quantity / 2);  // Verify Partial Reservation Quantity.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Sales Line", LotNo2,
          -AssemblyHeader.Quantity / 2);  // Verify Partial Reservation Quantity.

        if NonSpecificReservation then begin
            // Exercise.
            EnqueueValuesForHandlers(false, false);
            SalesLine.ShowReservation();

            // Verify.
            VerifyReservationEntry(
              ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Assembly Header", LotNo,
              AssemblyHeader.Quantity / 2);  // Verify Partial Reservation Quantity.
            VerifyReservationEntry(
              ReservationEntry."Reservation Status"::Reservation, AssemblyHeader."Item No.", DATABASE::"Sales Line", '',
              -AssemblyHeader.Quantity / 2);  // Verify Partial Reservation Quantity.
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderAndSOWithSpecificReservation()
    begin
        // Setup.
        Initialize();
        PostAssemblyOrderAndSalesOrderWithReservation(false, true);  // Enqueue Confirm as FALSE, Enqueue Reservation as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure PostAOAndSOWithoutNonSpecificReservation()
    begin
        // Setup.
        Initialize();
        PostAssemblyOrderAndSalesOrderWithReservation(true, true);  // Enqueue Confirm as TRUE, Enqueue Reservation as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderAndSOWithNonSpecificReservation()
    begin
        // Setup.
        Initialize();
        PostAssemblyOrderAndSalesOrderWithReservation(true, false);  // Enqueue Confirm as TRUE, Enqueue Reservation as FALSE.
    end;

    local procedure PostAssemblyOrderAndSalesOrderWithReservation(EnqueueConfirm: Boolean; EnqueueReservation: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldStockOutWarning: Boolean;
    begin
        // Update Stock Out Warning on Assembly Setup. Create Initial Setup for Assembly Order. Open Reservation from Sales Line.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        CreateInitialSetupForAssemblyOrder(AssemblyHeader, SalesHeader, SalesLine);
        EnqueueValuesForHandlers(EnqueueConfirm, EnqueueReservation);
        SalesLine.ShowReservation();

        // Exercise: Add Component Inventory and Post Assembly Order. Post Sales Order as Ship.
        AddComponentInventoryAndPostAssemblyOrder(AssemblyHeader, AssemblyHeader.Quantity, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Ship as TRUE.

        // Verify.
        VerifyReservationEntryExists(AssemblyHeader."Item No.");

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAOAfterRefreshProductionOrder()
    begin
        // Setup.
        Initialize();
        CreateAOAfterRefreshProdOrderWithDifferentUOM(false);  // Update UOM as FALSE.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAOAfterRefreshProdOrderWithDifferentUOM()
    begin
        // Setup.
        Initialize();
        CreateAOAfterRefreshProdOrderWithDifferentUOM(true);  // Update UOM as TRUE.
    end;

    local procedure CreateAOAfterRefreshProdOrderWithDifferentUOM(UpdateUOM: Boolean)
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        AssemblyLine: Record "Assembly Line";
        OldStockOutWarning: Boolean;
        ComponentItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Create and post Item Journal Line. Create Purchase Order. Create and refresh Production Order.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        Quantity := LibraryRandom.RandDec(10, 2);
        ComponentItemNo := CreateAssemblyItemWithComponent(Item, Item."Assembly Policy"::"Assemble-to-Stock", Quantity, '', '');
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ComponentItemNo);
        CreateAndPostItemJournalLine(ComponentItemNo, Quantity, false);
        CreatePurchaseOrder(PurchaseHeader, ComponentItemNo, Quantity, ItemUnitOfMeasure.Code, false);
        CreateAndRefreshReleasedProductionOrder(ComponentItemNo, Quantity);
        EnqueueValuesForConfirmHandler(StartingDateError, true);
        CreateAssemblyOrder(AssemblyHeader, Item."No.", Quantity, false);
        UpdateStartingDateOnAssemblyHeader(
          AssemblyHeader, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', AssemblyHeader."Due Date"));
        FindAssemblyLine(AssemblyLine, AssemblyLine."Document Type"::Order, ComponentItemNo);

        // Exercise.
        EnqueueValuesForReservationEntry(ReservationMode::Verify, Quantity, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for UOM Conversion.
        AssemblyLine.ShowReservation();

        // Verify: Verification is covered in handler.

        if UpdateUOM then begin
            // Exercise.
            UpdateUnitOfMeasureOnPurchaseLine(PurchaseHeader."No.", Item."Base Unit of Measure");

            // Verify.
            EnqueueValuesForReservationEntry(ReservationMode::Verify, Quantity, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for UOM Conversion.
            AssemblyLine.ShowReservation();
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityToReserveForAssemblyItem()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        OldStockOutWarning: Boolean;
    begin
        // Setup: Create Assembly Order. Update starting date on Assembly Header.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        LibraryAssembly.CreateItem(Item, Item."Costing Method", Item."Replenishment System"::Assembly, '', '');
        EnqueueValuesForConfirmHandler(StartingDateError, true);
        CreateAssemblyOrder(AssemblyHeader, Item."No.", LibraryRandom.RandDec(10, 2), false);
        UpdateStartingDateOnAssemblyHeader(
          AssemblyHeader, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', AssemblyHeader."Due Date"));
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2), Item."No.");

        // Exercise.
        ShowReservationOnAssemblyLine(AssemblyLine."Document Type"::Order, Item."No.");

        // Verify: Verification is done in ReservationPageHandler.

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithAlwaysReserveItemForSalesOrder()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        AssemblyLine: Record "Assembly Line";
        OldStockOutWarning: Boolean;
        ComponentItemNo: Code[20];
    begin
        // Setup: Create Assembly Item with components. Update Reserve as always on Item. Create Purchase Order and Sales Order.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        ComponentItemNo := CreateInitialSetupForSalesDocument(Item, PurchaseHeader);
        CreateSalesOrder(
          SalesHeader, SalesLine, PurchaseHeader."Order Date", Item."No.", LibraryRandom.RandDec(10, 2), '', false, false);

        // Exercise.
        ShowReservationOnAssemblyLine(AssemblyLine."Document Type"::Order, ComponentItemNo);

        // Verify: Verification is done in ReservationPageHandler.

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AOWithAlwaysReserveItemForBlanketSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        AssemblyLine: Record "Assembly Line";
        OldStockOutWarning: Boolean;
        ComponentItemNo: Code[20];
    begin
        // Setup: Create Assembly Item with components. Update Reserve as always on Item. Create Purchase Order and Blanket Sales Order.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        ComponentItemNo := CreateInitialSetupForSalesDocument(Item, PurchaseHeader);
        CreateBlanketSalesOrder(SalesHeader, Item."No.", PurchaseHeader."Order Date", LibraryRandom.RandDec(10, 2));

        // Exercise.
        ShowReservationOnAssemblyLine(AssemblyLine."Document Type"::"Blanket Order", ComponentItemNo);

        // Verify: Verification is done in ReservationPageHandler.

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithAlwaysReserveItemForSalesQuote()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        AssemblyLine: Record "Assembly Line";
        OldStockOutWarning: Boolean;
        ComponentItemNo: Code[20];
    begin
        // Setup: Create Assembly Item with components. Update Reserve as always on Item. Create Purchase Order and Sales Quote.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        ComponentItemNo := CreateInitialSetupForSalesDocument(Item, PurchaseHeader);
        CreateSalesQuote(SalesHeader, Item."No.", PurchaseHeader."Order Date", LibraryRandom.RandDec(10, 2));

        // Exercise.
        ShowReservationOnAssemblyLine(AssemblyLine."Document Type"::Quote, ComponentItemNo);

        // Verify: Verification is done in ReservationPageHandler.

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAOAfterCreatingPickFromSalesOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        ComponentItem: Record Item;
        AssemblyLine: Record "Assembly Line";
        OldStockOutWarning: Boolean;
        ComponentItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item with components. Update Inventory using Warehouse Journal. Create Sales Order and reserve quantity. Create Assembly Order and Update Location on Assembly Line.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        Quantity := LibraryRandom.RandDec(10, 2);
        ComponentItemNo := CreateAssemblyItemWithComponent(Item, Item."Assembly Policy"::"Assemble-to-Order", Quantity, '', '');
        FindBinForPickZone(Bin, LocationWhite.Code);
        ComponentItem.Get(ComponentItemNo);
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem, Quantity);
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);  // Enqueue for ReservationPageHandler.
        CreateSalesOrder(
          SalesHeader, SalesLine, CalculateDateUsingDefaultSafetyLeadTime(), ComponentItemNo, Quantity / 4, LocationWhite.Code, true, false);  // Value required for Partial Reservation for Partial Quantity. Reserve as TRUE.
        CreatePickFromSalesOrder(SalesHeader2, ComponentItemNo, Quantity / 4, LocationWhite.Code);  // Value required for Partial Reservation for Partial Quantity.
        CreateAssemblyOrderAndUpdateLocationOnAssemblyLine(AssemblyLine, Item."No.", ComponentItem."No.", Quantity, LocationWhite.Code);

        // Exercise.
        EnqueueValuesForReservationEntry(ReservationMode::AvailableToReserve, Quantity, Quantity / 2);  // Value required for Partial Reservation.
        asserterror AssemblyLine.ShowReservation();

        // Verify: Verification is done in ReservationPageHandler.

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ConfirmHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrdWithTrackedQtyLessThanReserveQty()
    begin
        // Setup.
        Initialize();
        ReserveFromAOWithTrackedQtyLessThanReserveQty(false);  // Post Assembly Order as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ConfirmHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrdWithTrackedQtyLessThanReserveQty()
    begin
        // Setup.
        Initialize();
        ReserveFromAOWithTrackedQtyLessThanReserveQty(true);  // Post Assembly Order as True.
    end;

    local procedure ReserveFromAOWithTrackedQtyLessThanReserveQty(PostAssembly: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        AssemblyItem: Record Item;
        OldStockOutWarning: Boolean;
        Quantity: Decimal;
        ComponentItemNo: Code[20];
        LotNo: Code[50];
    begin
        // Create Purchase Order. Create and post Item Journal Line. Create Assembly Order.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        Quantity := LibraryRandom.RandDec(10, 2);
        ComponentItemNo :=
          CreateAssemblyItemWithTrackedComponentItem(AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Order", Quantity);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');  // No. Series as blank.
        LotNo := CreateAndPostItemJournalLine(ComponentItemNo, Quantity, true);  // UseTracking as True.
        CreatePurchaseOrder(PurchaseHeader, ComponentItemNo, Quantity, AssemblyItem."Base Unit of Measure", true);  // UseTracking as True.
        CreateAndUpdateAssemblyOrder(
          AssemblyHeader, AssemblyLine, AssemblyItem."No.", ComponentItemNo, Quantity + LibraryRandom.RandDec(10, 2));  // Value required for test.

        // Exercise.
        ApplyItemTrkgAfterReserveQuantityOnAssemblyOrder(AssemblyLine);

        // Verify.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, ComponentItemNo, DATABASE::"Item Ledger Entry", LotNo, Quantity);
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, ComponentItemNo, DATABASE::"Assembly Line", LotNo, -Quantity);

        if PostAssembly then begin
            PostAssemblyOrder(AssemblyHeader, AssemblyLine, Quantity);

            // Verify.
            VerifyReservationEntryExists(AssemblyItem."No.");
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ConfirmHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrdWithTrackedQtyGreaterThanReserveQty()
    begin
        // Setup.
        Initialize();
        ReserveFromAOWithTrackedQtyGreaterThanReserveQty(false);  // PostAssembly as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ConfirmHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrdWithTrackedQtyGreaterThanReserveQty()
    begin
        // Setup.
        Initialize();
        ReserveFromAOWithTrackedQtyGreaterThanReserveQty(true);  // PostAssembly as False.
    end;

    local procedure ReserveFromAOWithTrackedQtyGreaterThanReserveQty(PostAssembly: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        AssemblyItem: Record Item;
        OldStockOutWarning: Boolean;
        Lot1Qty: Decimal;
        Lot2Qty: Decimal;
        ComponentQtyPer: Decimal;
        QtyToAssemble: Decimal;
        ComponentItemNo: Code[20];
        LotNo: Code[50];
        LotNo2: Code[50];
    begin
        // Create Purchase Order. Create and post Item Journal Line. Create Assembly Order.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        QtyToAssemble := LibraryRandom.RandIntInRange(3, 6);
        ComponentQtyPer := LibraryRandom.RandDecInRange(2, 5, 2);
        Lot1Qty := LibraryRandom.RandDec(10, 2);
        Lot2Qty := QtyToAssemble * ComponentQtyPer + LibraryRandom.RandDec(10, 2);
        ComponentItemNo := CreateAssemblyItemWithTrackedComponentItem(AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Order", ComponentQtyPer);
        LotNo := CreateAndPostItemJournalLine(ComponentItemNo, Lot1Qty, true);  // UseTracking as True.
        LotNo2 := CreateAndPostItemJournalLine(ComponentItemNo, Lot2Qty, true);  // UseTracking as True.
        CreatePurchaseOrder(PurchaseHeader, ComponentItemNo, Lot1Qty, AssemblyItem."Base Unit of Measure", true);  // UseTracking as True.
        CreateAndUpdateAssemblyOrder(AssemblyHeader, AssemblyLine, AssemblyItem."No.", ComponentItemNo, QtyToAssemble);

        // Exercise.
        ApplyItemTrkgAfterReserveQuantityOnAssemblyOrder(AssemblyLine);

        // Verify.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, ComponentItemNo, DATABASE::"Item Ledger Entry", LotNo, Lot1Qty);
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, ComponentItemNo, DATABASE::"Assembly Line", LotNo, -Lot1Qty);
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Surplus, ComponentItemNo, DATABASE::"Assembly Line", LotNo2,
          -(QtyToAssemble * ComponentQtyPer - Lot1Qty));  // Calculated value required.

        if PostAssembly then begin
            PostAssemblyOrder(AssemblyHeader, AssemblyLine, Lot1Qty);

            // Verify.
            VerifyReservationEntryExists(AssemblyHeader."Item No.");
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ReservationPageHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAOAfterApplyingTrackingOnAssemblyOrder()
    begin
        // Setup.
        Initialize();
        ReserveFromAOAfterApplyingTrackingOnAssemblyOrd(false);  // PostAssemblyOrder as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ReservationPageHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderAfterApplyingTrackingOnAO()
    begin
        // Setup.
        Initialize();
        ReserveFromAOAfterApplyingTrackingOnAssemblyOrd(true);  // PostAssemblyOrder as True.
    end;

    local procedure ReserveFromAOAfterApplyingTrackingOnAssemblyOrd(PostAssembly: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        ReservationEntry: Record "Reservation Entry";
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        AssemblyItem: Record Item;
        OldStockOutWarning: Boolean;
        Quantity: Decimal;
        ComponentItemNo: Code[20];
        LotNo: Code[50];
    begin
        // Create Purchase Order. Create and post Item Journal Line. Create Assembly Order.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        Quantity := LibraryRandom.RandDec(10, 2);
        ComponentItemNo :=
          CreateAssemblyItemWithTrackedComponentItem(AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Order", Quantity);
        LotNo := CreateAndPostItemJournalLine(ComponentItemNo, Quantity, true);  // UseTracking as True.
        CreatePurchaseOrder(PurchaseHeader, ComponentItemNo, Quantity, AssemblyItem."Base Unit of Measure", true);  // UseTracking as True.
        CreateAndUpdateAssemblyOrder(
          AssemblyHeader, AssemblyLine, AssemblyItem."No.", ComponentItemNo, Quantity + LibraryRandom.RandDec(10, 2));
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        AssemblyLine.OpenItemTrackingLines();

        // Exercise.
        EnqueueValuesForHandlers(true, false);
        AssemblyLine.ShowReservation();

        // Verify.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, ComponentItemNo, DATABASE::"Item Ledger Entry", LotNo, Quantity);
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, ComponentItemNo, DATABASE::"Assembly Line", LotNo, -Quantity);

        if PostAssembly then begin
            // Exercise.
            PostAssemblyOrder(AssemblyHeader, AssemblyLine, Quantity);

            // Verify.
            VerifyReservationEntryExists(AssemblyHeader."Item No.");
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAOWithTrackedQtyOnPurchaseOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PurchaseHeader: Record "Purchase Header";
        AssemblyItem: Record Item;
        OldStockOutWarning: Boolean;
        Quantity: Decimal;
        ComponentItemNo: Code[20];
    begin
        // Setup: Create Purchase Order. Create and post Item Journal Line. Create Assembly Order.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        Quantity := LibraryRandom.RandDec(10, 2);
        ComponentItemNo :=
          CreateAssemblyItemWithTrackedComponentItem(AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Order", Quantity / 2);
        CreateAndPostItemJournalLine(ComponentItemNo, Quantity, true);  // UseTracking as True.
        CreatePurchaseOrder(PurchaseHeader, ComponentItemNo, Quantity, AssemblyItem."Base Unit of Measure", true);  // UseTracking as True.
        CreateAndUpdateAssemblyOrder(AssemblyHeader, AssemblyLine, AssemblyItem."No.", ComponentItemNo, Quantity / 2);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        AssemblyLine.OpenItemTrackingLines();

        // Exercise.
        EnqueueValuesForHandlers(false, false);
        asserterror AssemblyLine.ShowReservation();

        // Verify.
        Assert.ExpectedError(CannotMatchItemTracking);

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityTrackedGreaterThanReservationQuantityError()
    begin
        // Setup.
        Initialize();
        PostSalesOrderAfterUpdateTrackedQtyOnReservation(true, false);  // Quantity Tracked Greater Than Reservation as TRUE, Post Sales Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSOWithQuantityTrackedGreaterThanReservationQty()
    begin
        // Setup.
        Initialize();
        PostSalesOrderAfterUpdateTrackedQtyOnReservation(true, true);  // Quantity Tracked Greater Than Reservation, Post Sales Order as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityTrackedLessThanReservationQuantityError()
    begin
        // Setup.
        Initialize();
        PostSalesOrderAfterUpdateTrackedQtyOnReservation(false, false);  // Quantity Tracked Greater Than Reservation, Post Sales Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSOWithQuantityTrackedLessThanReservationQty()
    begin
        // Setup.
        Initialize();
        PostSalesOrderAfterUpdateTrackedQtyOnReservation(false, true);  // Quantity Tracked Greater Than Reservation as FALSE, Post Sales Order as TRUE.
    end;

    local procedure PostSalesOrderAfterUpdateTrackedQtyOnReservation(QtyTrackedGreaterThanReservation: Boolean; PostSalesOrder: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingCode: Record "Item Tracking Code";
        AssemblyHeader: Record "Assembly Header";
        OldStockOutWarning: Boolean;
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Update Stock Out Warning on Assembly Setup. Create Lot Item Tracking Code. Create Assembly Item with Component. Create Sales Order. Create and Post Item Journal Line. Update Quantity Base on Reservation Entry.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        Quantity := LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);
        CreateItemTrackingCode(ItemTrackingCode);
        CreateAssemblyItemWithComponent(
          Item, Item."Assembly Policy"::"Assemble-to-Order", Quantity, ItemTrackingCode.Code, LibraryUtility.GetGlobalNoSeriesCode());
        CreateSalesOrder(SalesHeader, SalesLine, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", Quantity + Quantity2, '', false, false);  // Greater Quantity Value Required for Sales Order.
        CreateAndPostItemJournalLine(Item."No.", SalesLine.Quantity, true);  // Use Tracking as TRUE.
        if QtyTrackedGreaterThanReservation then
            Quantity := Quantity2;
        UpdateQuantityBaseOnReservationEntry(Item."No.", Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.

        // Exercise.
        asserterror SalesLine.OpenItemTrackingLines();

        // Verify: Verify error message.
        Assert.ExpectedError(BindingOrderToOrderError);

        if PostSalesOrder then begin
            // Exercise: Update Quantity Base on Reservation Entry, Assign Tracking on Assembly Order and Open Item Tracking from Sales Line.
            UpdateQuantityBaseAndAssignTrackingOnAssemblyOrder(Item."No.", Quantity2);
            OpenItemTrackingFromSalesLine(SalesLine);
            asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Ship as TRUE.

            // Verify.
            // Bug 280672 is closed By Design for now. A new deliverable will be implemented in NAV8 covering this scenario.
            // Test code to be updated accordingly when the design will change.
            Assert.ExpectedTestFieldError(AssemblyHeader.FieldCaption("Reserved Qty. (Base)"), Format(SalesLine.Quantity));
        end;

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithQuantityTrackedOnReservation()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        AssemblyHeader: Record "Assembly Header";
        OldStockOutWarning: Boolean;
        Quantity: Decimal;
    begin
        // Setup: Update Stock Out Warning on Assembly Setup. Create Lot Item Tracking Code. Create Assembly Item with Component. Create Sales Order. Create Purchase Order. Assign Tracking on assembly Order. Update Quantity to Ship on Sales Line.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemTrackingCode(ItemTrackingCode);
        CreateAssemblyItemWithComponent(
          Item, Item."Assembly Policy"::"Assemble-to-Order", Quantity, ItemTrackingCode.Code, LibraryUtility.GetGlobalNoSeriesCode());
        CreateSalesOrder(
          SalesHeader, SalesLine, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", Quantity + LibraryRandom.RandDec(10, 2), '',
          false, false);  // Greater Quantity Value Required for Sales Order.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", SalesLine.Quantity, Item."Base Unit of Measure", false);
        UpdateQuantityBaseOnReservationEntry(Item."No.", Quantity);
        AssignTrackingOnAssemblyOrder(Item."No.");
        UpdateQuantityToShipOnSalesLine(SalesLine, Quantity);

        // Exercise.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Ship as TRUE.

        // Verify.
        // Bug 280672 is closed By Design for now. A new deliverable will be implemented in NAV8 covering this scenario.
        // Test code to be updated accordingly when the design will change.
        Assert.ExpectedTestFieldError(AssemblyHeader.FieldCaption("Reserved Qty. (Base)"), Format(SalesLine.Quantity));

        // Tear Down.
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesOrderForAssemblyItemWithSerialItemTracking()
    begin
        // Test creating sales order for assembly item with Tracking Only policy and SN Specific Item Tracking Code can succeed. Verify Reservation Entry created.
        Initialize();
        CreateSalesOrderForAssemblyItemWithItemTracking(true, false); // TRUE for SN Specific Tracking, FALSE for Lot Specific Tracking
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesOrderForAssemblyItemWithLotItemTracking()
    begin
        // Test creating sales order for assembly item with Tracking Only policy and Lot Specific Item Tracking Code can succeed. Verify Reservation Entry created.
        Initialize();
        CreateSalesOrderForAssemblyItemWithItemTracking(false, true); // FALSE for SN Specific Tracking, TRUE for Lot Specific Tracking
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure GetWarehouseDocumentOnPickWorksheetWithAssembly()
    var
        AsmItem: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Test Pick Worksheet Lines are correct by Get Warehouse Document in Pick Worksheet with Assembly.

        // Setup: Create Assembly Item and Assembly BOM with at least three component Items.
        // Create Sales Order with Assembly Item. Add inventory for component Items.
        Initialize();
        LibraryAssembly.CreateItem(
          AsmItem, AsmItem."Costing Method"::Standard, AsmItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(
          AsmItem."Costing Method"::Standard, AsmItem."No.", true, LibraryRandom.RandIntInRange(3, 5),
          0, 0, LibraryRandom.RandInt(5), '', '');
        CreateAndReleaseSalesOrderWithQtyToAssemble(SalesHeader, AsmItem."No.", LocationWhite.Code);
        AddComponentInventory(AsmItem."No.");

        // Create Whse. Shipment from Sales Order and release it.
        CreateAndReleaseWhseShipmentFromSalesOrder(SalesHeader, WarehouseShipmentHeader);

        // Exercise: Click Get Warehouse Document in Pick Worksheet.
        LibraryVariableStorage.Enqueue(WarehouseShipmentHeader."No."); // Enqueue for PickSelectionPageHandler.
        InvokeGetWarehouseDocumentOnPickWorksheet();

        // Verify: Verify Pick Worksheet Lines are correct.
        VerifyWarehouseWorksheetLines(WarehouseShipmentHeader."No.", AsmItem."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoPostedAssemblyOrderWithLotTrackingAndExpirationDate()
    var
        AssemblyItem: Record Item;
        OrderNo: Code[20];
        ComponentItemNo: Code[20];
        Quantity: Decimal;
        ExpirationDate: Date;
    begin
        // Test Expiration Date should exist for Assembly Component after posting Undo Assembly.

        // Setup: Update Stock Out Warning on Assembly Setup.
        // Create Item with Assembly Component. Assembly Component Item with Lot Tracking and "Man. Expir. Date Entry Reqd.".
        Initialize();
        ComponentItemNo := CreateAssemblyItemWithTrackedComponentItemAndExpirDateReqd(AssemblyItem);

        // Update Inventory for Assembly Component Item with setting Lot No. and Expiration Date.
        Quantity := LibraryRandom.RandDec(10, 2);
        ExpirationDate := CalcDate('<CY>', WorkDate());
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, ''); // No. Series as blank.
        CreateAndPostItemJournalLineWithLotNoAndExpirDate(ComponentItemNo, Quantity, ExpirationDate);

        // Create and Post Assembly Order with Select Entries.
        OrderNo := CreateAndPostAssemblyOrderWithItemTracking(AssemblyItem."No.", ComponentItemNo, Quantity);

        // Exercise: Undo Posted Assembly Order.
        UndoPostedAssemblyOrder(OrderNo);

        // Verify: Expiration Date exists for Assembly Component after posting Undo Assembly.
        VerifyReservationEntryForExpirationDate(ComponentItemNo, ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateAndPostSalesOrderWithQtyToAssembleAndDeliveryDate()
    var
        AsmItem: Record Item;
        SalesHeader: Record "Sales Header";
        Qty: Decimal;
    begin
        // Test "The following C/AL functions..." error does not pop up when setting the Quantity on a Sales Line, which has a related Assembly Order.

        // Setup: Create Assembly Item, add inventory for Assembly Item.
        Initialize();
        LibraryAssembly.CreateItem(
          AsmItem, AsmItem."Costing Method"::Standard, AsmItem."Replenishment System"::Assembly, '', '');
        Qty := LibraryRandom.RandInt(20);
        CreateAndPostItemJournalLine(AsmItem."No.", 2 * Qty, false); // Use Tracking as False.

        // Create 2 Sales Orders with Assembly Item. Set "Qty. to Assemble to Order", "Requested Delivery Date" and "Promised Delivery Date"
        CreateSalesOrderWithQtyToAssembleAndDeliveryDate(SalesHeader, AsmItem."No.", Qty, WorkDate(), WorkDate());

        LibraryVariableStorage.Enqueue(IsBeforeWorkDateMsg); // Enqueue for MessageHandler.
        CreateSalesOrderWithQtyToAssembleAndDeliveryDate(
          SalesHeader, AsmItem."No.", Qty + LibraryRandom.RandInt(10),
          CalcDate(StrSubstNo('<-%1D>', LibraryRandom.RandInt(10)), WorkDate()),
          CalcDate(StrSubstNo('<+%1D>', LibraryRandom.RandInt(10)), WorkDate()));

        // Create Sales Header
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // Exercise: Fill Item No. and Quantity
        OpenAndEditSalesOrder(SalesHeader."No.", AsmItem."No.", Qty);

        // Verify: Sales Order created successfully without error.
        // Exercise and Verify: Post Sales Order and verify Quantity in Posted Sales Invoice.
        VerifyPostedSalesInvoice(LibrarySales.PostSalesDocument(SalesHeader, true, true), Qty);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure UndoPartialPostedAssemblyOrderAfterFullPost()
    var
        AssemblyItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PartialPostedAssemblyHeader: Record "Posted Assembly Header";
        ComponentItemNo: Code[20];
        QtyPer: Decimal;
        PartialQtyToAssemble: Decimal;
        RestOfQtyToAssemble: Decimal;
        AssemblyItemQty: Decimal;
        RestOfQtyPicked: Decimal;
    begin
        // [FEATURE] [Assembly Order] [Picks]
        // [SCENARIO 378847] "Qty. Picked" should be equal to the rest of Quantity in Assembly Line when undo a partial Posted Assembly Order after full posting.
        Initialize();
        QtyPer := LibraryRandom.RandDec(10, 2);
        PartialQtyToAssemble := LibraryRandom.RandDec(10, 2);
        RestOfQtyToAssemble := PartialQtyToAssemble + LibraryRandom.RandDec(20, 2);
        AssemblyItemQty := PartialQtyToAssemble + RestOfQtyToAssemble;
        RestOfQtyPicked := RestOfQtyToAssemble * QtyPer;

        // [GIVEN] Assembly Item with Component Item.
        CreateAssemblyItemWithComponentInStock(AssemblyItem, ComponentItemNo, QtyPer, AssemblyItemQty * QtyPer);

        // [GIVEN] Create and release Assembly Order for Assembly Item.
        CreateAndReleaseAssemblyOrder(AssemblyHeader, AssemblyItem."No.", LocationWhite.Code, AssemblyItemQty);

        // [GIVEN] Pick and post a partial Assembly Order.
        PickAndPostPartialAssemblyOrder(AssemblyHeader, PartialPostedAssemblyHeader, PartialQtyToAssemble, PartialQtyToAssemble * QtyPer);
        // [GIVEN] Pick and post the rest of "Quantity to Assemble" of Assembly Order.
        PickAndPostRestOfAssemblyOrder(AssemblyHeader, RestOfQtyToAssemble, RestOfQtyPicked);

        // [WHEN] Undo a partial Posted Assembly Order.
        LibraryAssembly.UndoPostedAssembly(PartialPostedAssemblyHeader, true, '');

        // [THEN] "Qty. Picked" is equal to the rest of Quantinty in Assembly Line.
        VerifyQtyAfterUndoPartialPostedAssemblyOrder(ComponentItemNo, RestOfQtyPicked);
    end;

    [Test]
    [HandlerFunctions('ReservationModalPageHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure ItemPickedToAsmBinCannotBeReservedAsAllocatedInWhse()
    var
        AssemblyItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CompItemNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Pick]
        // [SCENARIO 381763] Item that is picked to assembly bin cannot be reserved by another demand as it is now blocked as allocated in warehouse.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Assembly Item "I" with a component "C" in stock.
        CreateAssemblyItemWithComponentInStock(AssemblyItem, CompItemNo, 1, Qty);

        // [GIVEN] Assembly Order for "I" on location set up for directed put-away and pick.
        CreateAndReleaseAssemblyOrder(AssemblyHeader, AssemblyItem."No.", LocationWhite.Code, Qty);

        // [GIVEN] Item "C" is picked to a bin defined by "To-Assembly Bin Code" on location.
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
        UpdateQtyToHandleAndRegisterPick(AssemblyHeader."No.", Qty);

        // [GIVEN] Sales Order for item "C".
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), CompItemNo, Qty, LocationWhite.Code, false, false);

        // [WHEN] Open reservation page for the sales line.
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(0);
        SalesLine.ShowReservation();

        // [THEN] Item "C" is not available for reservation.
        // Verification is done in ReservationModalPageHandler
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinePageHandler,ItemTrackingLinesPageHandler,ItemTrackingListPageHandler,ReservationModalPageHandler,ConfirmHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure LotPickedToAsmBinCannotBeReservedAsAllocatedInWhse()
    var
        AssemblyItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CompItemNo: Code[20];
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [Item Tracking] [Lot Warehouse Tracking]
        // [SCENARIO 381763] Lot that is picked to assembly bin cannot be reserved by another demand as it is now blocked as allocated in warehouse.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Assembly Item "I" with a lot-tracked component "C" in stock. Lot No. = "L".
        CreateAssemblyItemWithTrackedComponentInStock(AssemblyItem, CompItemNo, 1, Qty, LotNo);

        // [GIVEN] Assembly Order for "I" on location set up for directed put-away and pick.
        // [GIVEN] Lot "L" is selected on Assembly Line.
        CreateAndReleaseAssemblyOrder(AssemblyHeader, AssemblyItem."No.", LocationWhite.Code, Qty);
        FindAssemblyLine(AssemblyLine, AssemblyLine."Document Type"::Order, CompItemNo);
        EnqueueValuesForItemTrackingLines(LotNo, Qty);
        AssemblyLine.OpenItemTrackingLines();

        // [GIVEN] Item "C" is picked to a bin defined by "To-Assembly Bin Code" on location.
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
        UpdateQtyToHandleAndRegisterPick(AssemblyHeader."No.", Qty);

        // [GIVEN] Sales Order for item "C" with lot "L" selected on the sales line.
        EnqueueValuesForItemTrackingLines(LotNo, Qty);
        EnqueueValuesForConfirmHandler(AvailabilityWarningsConfirmMessage, true);
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), CompItemNo, Qty, LocationWhite.Code, false, true);

        // [WHEN] Open reservation page for the sales line.
        EnqueueValuesForConfirmHandler(LibraryInventory.GetReservConfirmText(), true);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(0);
        SalesLine.ShowReservation();

        // [THEN] Lot "L" is not available for reservation.
        // Verification is done in ReservationModalPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ConfirmHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure AvailQtyToReserveWhenQtyIsBothInOutboundBinAndToAssemblyBin()
    var
        Location: Record Location;
        Bin: array[3] of Record Bin;
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNos: array[3] of Code[50];
    begin
        // [FEATURE] [Assemble-to-Order] [Item Tracking] [Pick]
        // [SCENARIO 364320] A user can separately reserve component when some quantity of it is reserved and picked for assembly-to-order.
        Initialize();

        // [GIVEN] Location with required shipment and pick.
        // [GIVEN] Set "From-Assembly Bin Code" = "ASM"; "Shipment Bin Code" = "SHIP".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", Bin[1].Code);
        Location.Validate("From-Assembly Bin Code", Bin[2].Code);
        Location.Validate("To-Assembly Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Assemble-to-order item "A" with component "C".
        CompItem.Get(CreateAssemblyItemWithTrackedComponentItem(AsmItem, AsmItem."Assembly Policy"::"Assemble-to-Order", 1));

        // [GIVEN] Post the component item "C" to inventory - 20 pcs of lot "L1", 10 pcs of lot "L2", 100 pcs of lot "L3".
        LotNos[1] := CreateAndPostItemJournalLineWithLocationAndBin(Location.Code, Bin[3].Code, CompItem."No.", 20);
        LotNos[2] := CreateAndPostItemJournalLineWithLocationAndBin(Location.Code, Bin[3].Code, CompItem."No.", 10);
        LotNos[3] := CreateAndPostItemJournalLineWithLocationAndBin(Location.Code, Bin[3].Code, CompItem."No.", 100);

        // [GIVEN] Sales order for 10 pcs of assembled item "A". An assembly order is created in the background.
        // [GIVEN] Open assembly line for item "C", set lot no. "L1" and reserve.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', AsmItem."No.", 10, Location.Code, WorkDate());
        AssignItemTrackingAndReserveATO(SalesLine, CompItem."No.", LotNos[1], 10);
        CreateAndRegisterPickFromSalesOrder(SalesHeader, CompItem."No.");

        // [GIVEN] Sales order for 20 pcs of assembled item "A".
        // [GIVEN] Open assembly line for item "C", set lot no. "L3" and reserve.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', AsmItem."No.", 20, Location.Code, WorkDate());
        AssignItemTrackingAndReserveATO(SalesLine, CompItem."No.", LotNos[3], 20);
        CreateAndRegisterPickFromSalesOrder(SalesHeader, CompItem."No.");

        // [GIVEN] Sales order for 80 pcs of component "C".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', CompItem."No.", 80, Location.Code, WorkDate());

        // [GIVEN] Set lot no. on the sales line = "L3".
        EnqueueValuesForItemTrackingLines(LotNos[3], 80);
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Reserve the sales line for 80 pcs of lot "L3".
        EnqueueValuesForITSpecificReservation();
        SalesLine.ShowReservation();

        // [THEN] The sales line is fully reserved.
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 80);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyItemTrackingLinesQuantityBasePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyQuantityBaseUndoPostedAssemblyOrderWithLotTracking()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ComponentItemNo: Code[20];
        ConsumedQty: Decimal;
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [SCENARIO 574824] Verify Quantity(Base) after Undo Posted Assembly Order with Lot Tracking.
        Initialize();
        Quantity := LibraryRandom.RandDecInRange(5, 5, 2);
        ConsumedQty := LibraryRandom.RandDecInRange(3, 3, 2);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create Item Tracking Code.
        CreateItemTrackingCode(ItemTrackingCode);

        // [GIVEN] Create Assembly Item with Component Item.
        ComponentItemNo := CreateAssemblyItemWithComponent(
              AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Stock", 1, ItemTrackingCode.Code, LibraryUtility.GetGlobalNoSeriesCode());

        // [GIVEN] Create and Post Item Journal for Component Item.
        CreateAndPostItemJournalLine(ComponentItemNo, Quantity, false);

        // [GIVEN] Create Assembly Header and assign Quantity to Assemble.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AssemblyItem."No.", '', Quantity, '');
        AssemblyHeader.Validate("Quantity to Assemble", ConsumedQty);
        AssemblyHeader.Modify(true);

        // [GIVEN] Open Item Tracking Lines and Set Lot No. and Quantity(Base).
        EnqueueValuesForItemTrackingLines(LotNo, ConsumedQty);
        AssemblyHeader.OpenItemTrackingLines();

        // [GIVEN] Post Assembly Header
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [WHEN] Undo Posted Assembly Order.
        UndoPartialPostedAssemblyOrder(AssemblyHeader."No.");

        // [THEN] Verify Item Tracking Lines Quantity(Base).
        LibraryVariableStorage.Enqueue(ConsumedQty);
        VerifyAssemblyOrderItemTracking(AssemblyHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ExpirationDateDisappearsFromItemTrackingLineAfterAddingOrModifyingThePromisedDeliveryDate()
    begin
        // [SCENARIO 580018] Expiration date disappears from item tracking lines after adding / modifying the "Promised Delivery date"
        Initialize();

        // [GIVEN] Create Assembly and Sales Order and check Expiration Date not chnaged
        CreateAssemblyOrderAndSalesOrderWithLot();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting Reservation");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting Reservation");

        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting Reservation");
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure NoSeriesSetup()
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        LibrarySales.SetOrderNoSeriesInSetup();

        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Modify(true);
    end;

    local procedure AddComponentInventoryAndPostAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; Quantity: Decimal; UseTracking: Boolean)
    var
        LotNo: Variant;
    begin
        LibraryAssembly.AddCompInventory(AssemblyHeader, AssemblyHeader."Due Date", AssemblyHeader.Quantity * Quantity);  // Calculated Value required.
        if UseTracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
            AssemblyHeader.OpenItemTrackingLines();
            LibraryVariableStorage.Dequeue(LotNo);
        end;
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');  // Expected Error as Blank.
    end;

    local procedure AddComponentInventory(ItemNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        FindAssemblyHeader(AssemblyHeader, ItemNo);
        LibraryAssembly.AddCompInventory(
          AssemblyHeader, WorkDate(), LibraryRandom.RandInt(50) + 100); // Large inventory for component items.
    end;

    local procedure ApplyItemTrkgAfterReserveQuantityOnAssemblyOrder(AssemblyLine: Record "Assembly Line")
    begin
        LibraryVariableStorage.Enqueue(false);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);  // Enqueue for ReservationPageHandler.
        AssemblyLine.ShowReservation();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        AssemblyLine.OpenItemTrackingLines();
    end;

    local procedure AssignTrackingOnAssemblyOrder(ItemNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
        LotNo: Variant;
    begin
        FindAssemblyHeader(AssemblyHeader, ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        AssemblyHeader.OpenItemTrackingLines();
        LibraryVariableStorage.Dequeue(LotNo);
    end;

    local procedure CalculateDateUsingDefaultSafetyLeadTime(): Date
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        exit(CalcDate(InventorySetup."Default Safety Lead Time", WorkDate()));
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; UseTracking: Boolean) LotNo: Code[50]
    var
        DequeueVariable: Variant;
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo,
          Quantity);
        if UseTracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
            ItemJournalLine.OpenItemTrackingLines(false);
            LibraryVariableStorage.Dequeue(DequeueVariable);
            LotNo := DequeueVariable;
        end;
    end;

    local procedure CreateAndPostItemJournalLineWithLocationAndBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal) LotNo: Code[50]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LotNo := LibraryVariableStorage.DequeueText();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; UseTracking: Boolean) LotNo: Code[50]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LotNo := CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, UseTracking);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithLotNoAndExpirDate(ItemNo: Code[20]; Quantity: Decimal; ExpirationDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, true);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineFromWhseAdjustment(Item: Record Item)
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // CalcLines, CalcRoutings, CalcComponents as TRUE.
    end;

    local procedure CreateAndReleaseAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; AssemblyItemNo: Code[20]; LocationCode: Code[10]; AssemblyItemQty: Decimal)
    begin
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AssemblyItemNo, LocationCode, AssemblyItemQty, '');
        LibraryAssembly.ReleaseAO(AssemblyHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Shipment Date", ItemNo, Quantity, LocationCode, false, false);  // Reserve and Item Tracking as False.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndUpdateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; ItemNo: Code[20]; ComponentItemNo: Code[20]; Quantity: Decimal)
    begin
        EnqueueValuesForConfirmHandler(StartingDateError, true);
        CreateAssemblyOrder(AssemblyHeader, ItemNo, Quantity, false);
        UpdateStartingDateOnAssemblyHeader(
          AssemblyHeader, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', AssemblyHeader."Due Date"));  // Calculated date required for test.
        FindAssemblyLine(AssemblyLine, AssemblyLine."Document Type"::Order, ComponentItemNo);
    end;

    local procedure CreateAssemblyItem(var Item: Record Item; AssemblyPolicy: Enum "Assembly Policy"; ItemTrackingCode: Code[10]; LotNos: Code[20])
    begin
        LibraryAssembly.CreateItem(Item, Item."Costing Method", Item."Replenishment System"::Assembly, '', '');
        Item.Validate("Assembly Policy", AssemblyPolicy);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Lot Nos.", LotNos);
        Item.Modify(true);
    end;

    local procedure CreateAssemblyItemWithComponent(var Item: Record Item; AssemblyPolicy: Enum "Assembly Policy"; Quantity: Decimal; ItemTrackingCode: Code[10]; LotNos: Code[20]): Code[20]
    var
        BOMComponent: Record "BOM Component";
        ComponentItem: Record Item;
    begin
        LibraryAssembly.CreateItem(ComponentItem, ComponentItem."Costing Method", ComponentItem."Replenishment System", '', '');
        CreateAssemblyItem(Item, AssemblyPolicy, ItemTrackingCode, LotNos);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", Item."No.", '', BOMComponent."Resource Usage Type", Quantity, true);
        exit(ComponentItem."No.");
    end;

    local procedure CreateAssemblyItemWithComponentInStock(var AssemblyItem: Record Item; var ComponentItemNo: Code[20]; QtyPer: Decimal; ComponentItemQtyInStock: Decimal)
    var
        Bin: Record Bin;
        ComponentItem: Record Item;
    begin
        ComponentItemNo :=
          CreateAssemblyItemWithComponent(
            AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Stock", QtyPer, '', '');

        FindBinForPickZone(Bin, LocationWhite.Code);
        ComponentItem.Get(ComponentItemNo);
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem, ComponentItemQtyInStock);
    end;

    local procedure CreateAssemblyItemWithTrackedComponentInStock(var AssemblyItem: Record Item; var ComponentItemNo: Code[20]; QtyPer: Decimal; ComponentItemQtyInStock: Decimal; LotNo: Code[50])
    var
        Bin: Record Bin;
        ComponentItem: Record Item;
    begin
        ComponentItemNo :=
          CreateAssemblyItemWithTrackedComponentItem(AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Stock", QtyPer);
        FindBinForPickZone(Bin, LocationWhite.Code);
        ComponentItem.Get(ComponentItemNo);
        UpdateInventoryForTrackedItemUsingWhseJournal(Bin, ComponentItem, ComponentItemQtyInStock, LotNo);
    end;

    local procedure CreateAssemblyItemWithTrackedComponentItem(var KitItem: Record Item; AssemblyPolicy: Enum "Assembly Policy"; Quantity: Decimal): Code[20]
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        CreateItemTrackingCode(ItemTrackingCode);
        CreateAssemblyItem(KitItem, AssemblyPolicy, '', '');
        CreateTrackedComponentItem(ComponentItem, ItemTrackingCode.Code, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", KitItem."No.", '', BOMComponent."Resource Usage Type", Quantity, true);
        exit(ComponentItem."No.");
    end;

    local procedure CreateAssemblyItemWithTrackedComponentItemAndExpirDateReqd(var AssemblyItem: Record Item) ComponentItemNo: Code[20]
    var
        ComponentItem: Record Item;
    begin
        ComponentItemNo :=
          CreateAssemblyItemWithTrackedComponentItem(
            AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandDec(1, 2));
        ComponentItem.Get(ComponentItemNo);
        UpdateItemTrackingCodeForExpirDate(ComponentItem."Item Tracking Code", true);
        exit(ComponentItemNo);
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; Quantity: Decimal; UseTracking: Boolean) LotNo: Code[50]
    var
        DequeueVariable: Variant;
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), ItemNo, '', Quantity, '');  // Location Code, Variant Code as Blank.
        if UseTracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
            AssemblyHeader.OpenItemTrackingLines();
            LibraryVariableStorage.Dequeue(DequeueVariable);
            LotNo := DequeueVariable;
        end;
    end;

    local procedure CreateAssemblyOrderAndUpdateLocationOnAssemblyLine(var AssemblyLine: Record "Assembly Line"; ItemNo: Code[20]; ComponentItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        EnqueueValuesForConfirmHandler(StartingDateError, true);
        CreateAssemblyOrder(AssemblyHeader, ItemNo, Quantity, false);
        UpdateStartingDateOnAssemblyHeader(
          AssemblyHeader, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', AssemblyHeader."Due Date"));
        FindAssemblyLine(AssemblyLine, AssemblyLine."Document Type"::Order, ComponentItemNo);
        UpdateLocationCodeOnAssemblyLine(AssemblyLine, LocationCode);
    end;

    local procedure CreateAssemblyOrderWithLotItemTracking(var AssemblyHeader: Record "Assembly Header"; UseTracking: Boolean) LotNo: Code[50]
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemTrackingCode(ItemTrackingCode);
        CreateAssemblyItemWithComponent(
          Item, Item."Assembly Policy"::"Assemble-to-Stock", Quantity, ItemTrackingCode.Code, LibraryUtility.GetGlobalNoSeriesCode());
        LotNo := CreateAssemblyOrder(AssemblyHeader, Item."No.", Quantity * 2, UseTracking);  // Large Quantity Required for Assembly Order.
    end;

    local procedure CreateAndPostAssemblyOrderWithItemTracking(AssemblyItemNo: Code[20]; ComponentItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        CreateAndUpdateAssemblyOrder(
          AssemblyHeader, AssemblyLine, AssemblyItemNo, ComponentItemNo, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries); // Enqueue for ItemTrackingLinesPageHandler.
        AssemblyLine.OpenItemTrackingLines();
        PostAssemblyOrder(AssemblyHeader, AssemblyLine, AssemblyLine."Quantity per" * Quantity);
        exit(AssemblyHeader."No.");
    end;

    local procedure CreateBlanketSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ShipmentDate: Date; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        SalesHeader.Validate("Order Date", ShipmentDate);
        SalesHeader.Validate("Posting Date", ShipmentDate);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateInitialSetupForAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemTrackingCode(ItemTrackingCode);
        CreateAssemblyItemWithComponent(
          Item, Item."Assembly Policy"::"Assemble-to-Stock", Quantity, ItemTrackingCode.Code, LibraryUtility.GetGlobalNoSeriesCode());
        CreateAssemblyOrder(AssemblyHeader, Item."No.", Quantity * 2, true);  // Large Quantity Required for Assembly Order. Use Tracking as TRUE.
        CreateAndPostItemJournalLine(Item."No.", AssemblyHeader.Quantity, true);  // Use Tracking as TRUE.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateSalesOrder(SalesHeader, SalesLine, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", AssemblyHeader.Quantity, '', false, true);  // Use Tracking as TRUE.
    end;

    local procedure CreateInitialSetupForSalesDocument(var Item: Record Item; var PurchaseHeader: Record "Purchase Header") ComponentItemNo: Code[20]
    var
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        ComponentItemNo := CreateAssemblyItemWithComponent(Item, Item."Assembly Policy"::"Assemble-to-Order", Quantity, '', '');
        UpdateReserveOnItem(Item);
        CreatePurchaseOrder(PurchaseHeader, ComponentItemNo, Quantity, Item."Base Unit of Measure", false);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreatePickFromSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity, LocationCode);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateAndRegisterPickFromSalesOrder(SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; UseTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        DequeueVariable: Variant;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Order Date", CalculateDateUsingDefaultSafetyLeadTime());
        PurchaseHeader.Validate("Posting Date", PurchaseHeader."Order Date");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, Quantity, UnitOfMeasureCode);
        if UseTracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
            PurchaseLine.OpenItemTrackingLines();
            LibraryVariableStorage.Dequeue(DequeueVariable);
        end;
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Order Date", ShipmentDate);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShipmentDate: Date; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean; UseTracking: Boolean)
    begin
        CreateSalesHeader(SalesHeader, ShipmentDate);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        if Reserve then
            SalesLine.ShowReservation();
        if UseTracking then
            SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderWithReservationAndLotTracking(var SalesHeader: Record "Sales Header"; var AssemblyHeader: Record "Assembly Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryVariableStorage.Enqueue(false);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateSalesOrder(SalesHeader, SalesLine, AssemblyHeader."Due Date", AssemblyHeader."Item No.", AssemblyHeader.Quantity, '', true, true);  // Reserve as TRUE. Use Tracking as TRUE.
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ShipmentDate: Date; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        SalesHeader.Validate("Order Date", ShipmentDate);
        SalesHeader.Validate("Posting Date", ShipmentDate);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateTrackedComponentItem(var ComponentItem: Record Item; ItemTrackingCode: Code[10]; LotNos: Code[20])
    begin
        LibraryAssembly.CreateItem(ComponentItem, ComponentItem."Costing Method", ComponentItem."Replenishment System", '', '');
        ComponentItem.Validate("Item Tracking Code", ItemTrackingCode);
        ComponentItem.Validate("Lot Nos.", LotNos);
        ComponentItem.Modify(true);
    end;

    local procedure CreateWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.WarehouseJournalSetup(Bin."Location Code", WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure CreateWarehouseShipmentFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateSalesOrderForAssemblyItemWithItemTracking(SerialTracking: Boolean; LotTracking: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Assemly Item with Item Tracking Code, set Item."Order Tracking Policy" to "Tracking Only".
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SerialTracking, LotTracking);
        CreateAssemblyItemWithComponent(
          Item, Item."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandDec(10, 2),
          ItemTrackingCode.Code, LibraryUtility.GetGlobalNoSeriesCode());
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking Only");

        // Exercise: Create Sales Order, the Assembly Order will be generated.
        // Verify: No error pops up.
        CreateSalesOrder(
          SalesHeader, SalesLine, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", LibraryRandom.RandInt(10), '', false, false);

        // Verify: Reservation Entries are created.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, Item."No.", DATABASE::"Sales Line", '', -SalesLine.Quantity);
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Reservation, Item."No.", DATABASE::"Assembly Header", '', SalesLine.Quantity);
    end;

    local procedure CreateAndReleaseSalesOrderWithQtyToAssemble(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(
          SalesHeader, SalesLine, WorkDate(), ItemNo, LibraryRandom.RandInt(5), LocationCode, false, false); // Use Reserve and Tracking as FALSE.
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesOrderWithQtyToAssembleAndDeliveryDate(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; RequestedDeliveryDate: Date; PromisedDeliveryDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, WorkDate(), ItemNo, Qty, '', false, false);
        // Use Reserve and Tracking as FALSE.
        SalesLine.Validate("Qty. to Assemble to Order", Qty);
        SalesLine.Validate("Requested Delivery Date", RequestedDeliveryDate);
        SalesLine.Validate("Promised Delivery Date", PromisedDeliveryDate);
        SalesLine.Modify(true);
    end;

    local procedure EnqueueValuesForConfirmHandler(ConfirmMessage: Text; ConfirmReply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(ConfirmReply);  // Enqueue for ConfirmHandler.
    end;

    local procedure EnqueueValuesForHandlers(EnqueueConfirm: Boolean; EnqueueReservation: Boolean)
    begin
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(EnqueueConfirm);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(EnqueueReservation);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);  // Enqueue for ReservationPageHandler.
    end;

    local procedure EnqueueValuesForReservationEntry(ReservationMode: Option; Quantity: Decimal; Quantity2: Decimal)
    begin
        LibraryVariableStorage.Enqueue(false);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(ReservationMode);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(Quantity2);  // Enqueue for ReservationPageHandler.
    end;

    local procedure EnqueueValuesForItemTrackingLines(LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
    end;

    local procedure EnqueueValuesForITSpecificReservation()
    begin
        LibraryVariableStorage.Enqueue(ReserveSpecificLotNoQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);
    end;

    local procedure FindAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20])
    begin
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindFirst();
    end;

    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; DocumentType: Enum "Assembly Document Type"; ItemNo: Code[20])
    begin
        AssemblyLine.SetRange("Document Type", DocumentType);
        AssemblyLine.SetRange("No.", ItemNo);
        AssemblyLine.FindFirst();
    end;

    local procedure FindAssemblyLines(var AssemblyLine: Record "Assembly Line"; ItemNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        FindAssemblyHeader(AssemblyHeader, ItemNo);
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindSet();
    end;

    local procedure AssignItemTrackingAndReserveATO(SalesLine: Record "Sales Line"; CompItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryAssembly.FindLinkedAssemblyOrder(
          AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange("No.", CompItemNo);
        AssemblyLine.FindFirst();

        EnqueueValuesForItemTrackingLines(LotNo, Qty);
        AssemblyLine.OpenItemTrackingLines();

        LibraryVariableStorage.Enqueue(ReserveSpecificLotNoQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);
        AssemblyLine.ShowReservation();
    end;

    local procedure FindBinForPickZone(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, true));  // Put Away and Pick as TRUE.
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));  // Find Random Bin.
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindWhseWorksheetLines(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseDocumentType: Enum "Warehouse Worksheet Document Type"; WhseDocumentNo: Code[20])
    begin
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseDocumentType);
        WhseWorksheetLine.SetRange("Whse. Document No.", WhseDocumentNo);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure InvokeGetWarehouseDocumentOnPickWorksheet()
    var
        PickWorksheetTestPage: TestPage "Pick Worksheet";
    begin
        PickWorksheetTestPage.Trap();
        PickWorksheetTestPage.OpenEdit();
        PickWorksheetTestPage."Get Warehouse Documents".Invoke();
        PickWorksheetTestPage.Close();
    end;

    local procedure OpenItemTrackingFromSalesLine(var SalesLine: Record "Sales Line")
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarningsConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure OpenAndEditSalesOrder(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
        SalesOrder.OK().Invoke();
    end;

    local procedure PickAndPostPartialAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; QtyToAssemble: Decimal; QtyPicked: Decimal)
    begin
        AssemblyHeader.Validate("Quantity to Assemble", QtyToAssemble);
        AssemblyHeader.Modify(true);

        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, true, false);
        UpdateQtyToHandleAndRegisterPick(AssemblyHeader."No.", QtyPicked);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        AssemblyHeader.Find();
        LibraryAssembly.FindPostedAssemblyHeaders(PostedAssemblyHeader, AssemblyHeader);
        PostedAssemblyHeader.FindFirst();
    end;

    local procedure PickAndPostRestOfAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; QtyToAssemble: Decimal; QtyPicked: Decimal)
    begin
        AssemblyHeader.Validate("Quantity to Assemble", QtyToAssemble);
        AssemblyHeader.Modify(true);

        UpdateQtyToHandleAndRegisterPick(AssemblyHeader."No.", QtyPicked);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    local procedure PostAssemblyOrder(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; Quantity: Decimal)
    begin
        AssemblyLine.Validate("Quantity to Consume", Quantity);
        AssemblyLine.Modify(true);
        AssemblyHeader.Find();
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');  // Expected Error as Blank.
    end;

    local procedure CreateAndReleaseWhseShipmentFromSalesOrder(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader)
    end;

    local procedure ShowReservationOnAssemblyLine(DocumentType: Enum "Assembly Document Type"; ItemNo: Code[20])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryVariableStorage.Enqueue(false);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(ReservationMode::VerifyBlank);  // Enqueue for ReservationPageHandler.
        FindAssemblyLine(AssemblyLine, DocumentType, ItemNo);
        AssemblyLine.ShowReservation();
    end;

    local procedure UndoPostedAssemblyOrder(OrderNo: Code[20])
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        PostedAssemblyHeader.SetRange("Order No.", OrderNo);
        PostedAssemblyHeader.FindFirst();

        LibraryVariableStorage.Enqueue(UndoPostedAssemblyOrderQst); // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(true); // First time the answer is "Yes" for conform dialog.
        LibraryVariableStorage.Enqueue(RecreateAssemblyOrderQst); // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(true); // Second time the answer is "Yes" for conform dialog.
        CODEUNIT.Run(CODEUNIT::"Pstd. Assembly - Undo (Yes/No)", PostedAssemblyHeader);
    end;

    local procedure UpdateInventoryUsingWhseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        CreateWhseJournalLine(WarehouseJournalLine, Bin, Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);  // UseBatchJob as TRUE.
        CreateAndPostItemJournalLineFromWhseAdjustment(Item);
    end;

    local procedure UpdateInventoryForTrackedItemUsingWhseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal; LotNo: Code[50])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        CreateWhseJournalLine(WarehouseJournalLine, Bin, Item."No.", Quantity);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
        CreateAndPostItemJournalLineFromWhseAdjustment(Item);
    end;

    local procedure UpdateItemTrackingCodeForExpirDate(TrackingCode: Code[10]; ManExpirDateEntryReqd: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange(Code, TrackingCode);
        ItemTrackingCode.FindFirst();
        if not ItemTrackingCode."Use Expiration Dates" then
            ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntryReqd);
        ItemTrackingCode.Modify(true);
    end;

    local procedure UpdateLocationCodeOnAssemblyLine(AssemblyLine: Record "Assembly Line"; LocationCode: Code[10])
    begin
        AssemblyLine.Validate("Location Code", LocationCode);
        AssemblyLine.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Find();
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdateReserveOnItem(var Item: Record Item)
    begin
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure UpdateQtyToHandleAndRegisterPick(AssemblyOrderNo: Code[20]; QtyPicked: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Whse. Document No.", AssemblyOrderNo);
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Assembly);
        if WarehouseActivityLine.FindSet(true) then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", QtyPicked);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;
        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WarehouseActivityLine);
    end;

    local procedure UpdateQuantityBaseAndAssignTrackingOnAssemblyOrder(ItemNo: Code[20]; Quantity: Decimal)
    begin
        UpdateQuantityBaseOnReservationEntry(ItemNo, Quantity);
        AssignTrackingOnAssemblyOrder(ItemNo);
    end;

    local procedure UpdateQuantityBaseOnReservationEntry(ItemNo: Code[20]; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        SignFactor: Integer;
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            SignFactor := 1;
            if ReservationEntry."Quantity (Base)" < 0 then
                SignFactor := -1;
            ReservationEntry.Validate("Quantity (Base)", SignFactor * Quantity);
            ReservationEntry.Modify(true);
        until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateQuantityToShipOnSalesLine(var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", Quantity);
        SalesLine.Modify(true);
    end;

    local procedure UpdateStartingDateOnAssemblyHeader(AssemblyHeader: Record "Assembly Header"; StartingDate: Date)
    begin
        AssemblyHeader.Validate("Starting Date", StartingDate);
        AssemblyHeader.Modify(true);
    end;

    local procedure UpdateStockOutWarningOnAssemblySetup(NewStockOutWarning: Boolean) OldStockOutWarning: Boolean
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        OldStockOutWarning := AssemblySetup."Stockout Warning";
        AssemblySetup.Validate("Stockout Warning", NewStockOutWarning);
        AssemblySetup.Modify(true);
    end;

    local procedure UpdateUnitOfMeasureOnPurchaseLine(DocumentNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Unit of Measure", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateOrderTrackingPolicyOnItem(var Item: Record Item; OrderTrackingPolicy: Enum "Order Tracking Policy")
    begin
        if OrderTrackingPolicy <> Item."Order Tracking Policy"::None then
            LibraryVariableStorage.Enqueue(NotAffectExistingEntriesMsg);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateQtyToAssembleOnSalesLine(var SalesLine: Record "Sales Line"; QtyToAssemble: Decimal)
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate()));
        SalesLine.Validate("Qty. to Assemble to Order", QtyToAssemble);
        SalesLine.Modify(true);
    end;

    local procedure VerifyQtyAfterUndoPartialPostedAssemblyOrder(ComponentItemNo: Code[20]; RestOfQtyPicked: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FindAssemblyLine(AssemblyLine, AssemblyLine."Document Type"::Order, ComponentItemNo);
        AssemblyLine.TestField("Qty. Picked", RestOfQtyPicked);
    end;

    local procedure VerifyReservationEntry(ReservationStatus: Enum "Reservation Status"; ItemNo: Code[20]; SourceType: Integer; LotNo: Code[50]; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationEntries(var Reservation: TestPage Reservation; SummaryType: Text[50]; Quantity: Variant)
    begin
        Reservation.FILTER.SetFilter("Summary Type", SummaryType);
        Reservation."Total Quantity".AssertEquals(Quantity);
    end;

    local procedure VerifyReservationEntryExists(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ReservationEntry.IsEmpty, StrSubstNo(ReservationEntryDelete, ReservationEntry.TableCaption()));
    end;

    local procedure VerifyReservationEntryForExpirationDate(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        Assert.AreEqual(ExpirationDate, ReservationEntry."Expiration Date", StrSubstNo(ReservationEntryErr, ReservationEntry.FieldCaption("Expiration Date")));
    end;

    local procedure VerifyWarehouseWorksheetLines(WhseDocumentNo: Code[20]; AsmItemNo: Code[20])
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        AssemblyLine: Record "Assembly Line";
    begin
        FindWhseWorksheetLines(WhseWorksheetLine, WhseWorksheetLine."Whse. Document Type"::Shipment, WhseDocumentNo);
        FindAssemblyLines(AssemblyLine, AsmItemNo);
        Assert.AreEqual(AssemblyLine.Count, WhseWorksheetLine.Count, PickWorksheetLinesErr);
        repeat
            Assert.AreEqual(WhseWorksheetLine."Item No.", AssemblyLine."No.", ItemInPickWorksheetLinesErr);
            AssemblyLine.Next();
        until WhseWorksheetLine.Next() = 0;
    end;

    local procedure VerifyPostedSalesInvoice(DocumentNo: Code[20]; Qty: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(Qty, SalesInvoiceLine.Quantity, QtyIsNotCorrectErr);
    end;

    local procedure UndoPartialPostedAssemblyOrder(OrderNo: Code[20])
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        PostedAssemblyHeader.SetRange("Order No.", OrderNo);
        PostedAssemblyHeader.FindFirst();

        LibraryVariableStorage.Enqueue(UndoPostedAssemblyOrderQst); // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(true); // First time the answer is "Yes" for conform dialog.
        CODEUNIT.Run(CODEUNIT::"Pstd. Assembly - Undo (Yes/No)", PostedAssemblyHeader);
    end;

    local procedure VerifyAssemblyOrderItemTracking(AssemblyOrderNo: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("No.", AssemblyOrderNo);
        AssemblyOrder."Item Tracking Lines".Invoke();
    end;

    local procedure CreateAssemblyOrderAndSalesOrderWithLot()
    var
        ReservationEntry: Record "Reservation Entry";
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        LotNo: Code[50];
        OldStockOutWarning: Boolean;
    begin
        // Update Stock Out Warning on Assembly Setup. Create Assembly Order with Tracking. Create and Post Item Journal Line.
        OldStockOutWarning := UpdateStockOutWarningOnAssemblySetup(false);

        // [GIVEN] Create Assembly Order with Tracking and Post Item Journal
        CreateAssemblyOrderWithLotItemTracking(AssemblyHeader, true);
        LotNo := CreateAndPostItemJournalLine(AssemblyHeader."Item No.", AssemblyHeader.Quantity, true);  // Use Tracking as TRUE.

        // [GIVEN] Create sales Order with Tracking and update Expiration Date
        CreateSalesOrderWithReservationAndLotTracking(SalesHeader, AssemblyHeader);
        ReservationEntry.SetRange("Item No.", AssemblyHeader."Item No.");
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry."Expiration Date" := WorkDate();
                ReservationEntry.Modify();
            until ReservationEntry.Next() = 0;
        UpdateStockOutWarningOnAssemblySetup(OldStockOutWarning);

        //[WHEN] Update Expiration Date on Sales Header
        SalesHeader."Promised Delivery Date" := 20270129D;
        SalesHeader.Modify();

        //[THEN] Check Expiration Date must not be blank.
        ReservationEntry.SetRange("Item No.", AssemblyHeader."Item No.");
        Assert.AreEqual(WorkDate(), ReservationEntry."Expiration Date", '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(ConfirmMessage, LocalMessage) > 0, ConfirmMessage);
        LibraryVariableStorage.Dequeue(DequeueVariable);
        Reply := DequeueVariable;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        TrackingAction: Option;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        TrackingAction := DequeueVariable;
        case TrackingAction of
            ItemTrackingMode::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            ItemTrackingMode::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::SetLotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinePageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        DequeueVariable: Variant;
        Quantity: Variant;
        Quantity2: Variant;
        FindFirstRec: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        FindFirstRec := DequeueVariable;
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ReservationMode := DequeueVariable;
        if FindFirstRec then
            Reservation.First();
        case ReservationMode of
            ReservationMode::ReserveFromCurrentLine:
                Reservation."Reserve from Current Line".Invoke();
            ReservationMode::Verify:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    Quantity := DequeueVariable;
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    Quantity2 := DequeueVariable;
                    VerifyReservationEntries(Reservation, ItemLedgerEntry.TableCaption(), Quantity);
                    VerifyReservationEntries(Reservation, ReleasedProdOrderLine, Quantity);
                    VerifyReservationEntries(Reservation, PurchaseLineOrder, Quantity2);
                end;
            ReservationMode::VerifyBlank:
                Assert.IsFalse(Reservation.First(), ReservationEntryShouldBeBlank);
            ReservationMode::AvailableToReserve:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    Quantity := DequeueVariable;
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    Quantity2 := DequeueVariable;
                    VerifyReservationEntries(Reservation, ItemLedgerEntry.TableCaption(), Quantity);
                    Reservation.TotalAvailableQuantity.AssertEquals(Quantity2);
                end;
        end;
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationModalPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.QtyAllocatedInWarehouse.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation.TotalAvailableQuantity.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelectionTestPage: TestPage "Pick Selection")
    var
        WhsePickRequest: Record "Whse. Pick Request";
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PickSelectionTestPage.FILTER.SetFilter("Document Type", Format(WhsePickRequest."Document Type"::Shipment));
        PickSelectionTestPage.FILTER.SetFilter("Document No.", DocumentNo);
        PickSelectionTestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VerifyItemTrackingLinesQuantityBasePageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ActualQuantity: Decimal;
        ExpectedQuantity: Decimal;
        DequeueVariable: Variant;
        TrackingAction: Option;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        if not DequeueVariable.IsDecimal then begin
            TrackingAction := DequeueVariable;
            case TrackingAction of
                ItemTrackingMode::AssignLotNo:
                    begin
                        ItemTrackingLines."Assign Lot No.".Invoke();
                        LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                    end;
                ItemTrackingMode::SelectEntries:
                    ItemTrackingLines."Select Entries".Invoke();
                ItemTrackingMode::SetLotNo:
                    begin
                        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    end;
            end;
        end
        else begin
            ExpectedQuantity := DequeueVariable;
            ActualQuantity := ItemTrackingLines."Quantity (Base)".AsDecimal();
            Assert.AreEqual(ExpectedQuantity, ActualQuantity, QtyBaseIsNotCorrectErr);
        end;
        ItemTrackingLines.OK().Invoke();
    end;
}

