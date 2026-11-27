// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;

codeunit 149911 "Subc. WIP Trans. Create Test"
{
    // [FEATURE] WIP Item Transfer for Subcontracting
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ConfirmationSerializesSharedSourceClaims()
    var
        Workers: Codeunit "Subc WIP Concurrent Worker";
    begin
        Initialize();
        Workers.ExerciseClaimRace();
    end;

    [Test]
    procedure UnlinkedTransferInsertClearsCopiedWIPIdentity()
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
        TransferLine: Record "Transfer Line";
    begin
        Initialize();
        CreateAvailabilityFixture(Entry, 1);
        CreateCalculationClaim(Entry, 1, 0, TransferLine);
        TransferLine."Line No." += 10000;
        Clear(TransferLine."Subc. Prod. Order No.");
        TransferLine."Subc. WIP Lineage ID" := Entry."Lineage ID";
        TransferLine."Subc. State Tracked" := true;
        TransferLine.Insert(false);

        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.IsTrue(IsNullGuid(TransferLine."Subc. WIP Lineage ID"), 'A copied line without a production order must not retain another order''s lineage.');
        Assert.IsFalse(TransferLine."Subc. State Tracked", 'An unlinked transfer must not claim state-tracked WIP.');
    end;

    [Test]
    procedure AvailabilitySubtractsOpenRemainderOnce()
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
        FirstLine: Record "Transfer Line";
        SecondLine: Record "Transfer Line";
        DerivedLine: Record "Transfer Line";
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        CreateAvailabilityFixture(Entry, 7);
        CreateCalculationClaim(Entry, 10, 0.1, FirstLine);
        CreateCalculationClaim(Entry, 2, 0.5, SecondLine);
        Assert.AreNotEqual(FirstLine."Document No.", SecondLine."Document No.", 'Competing documents must both contribute claims.');
        Assert.AreEqual(2, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Convert each unshipped line using its own UOM.');
        Assert.AreEqual(5, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Processed seven less two claimed base is five.');
        Assert.AreEqual(6, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", FirstLine."Document No.", FirstLine."Line No."), 'Self exclusion must exclude exactly one line.');

        // Calculation-only fixture: model one shipped base unit and its signed posted relief.
        FirstLine."Quantity Shipped" := FirstLine.Quantity;
        FirstLine.Modify(false);
        Entry."Entry No." := Entry.GetNextEntryNo();
        Entry."Quantity (Base)" := -1;
        Entry.Insert(false);
        DerivedLine := SecondLine;
        DerivedLine."Line No." += 10000;
        DerivedLine."Derived From Line No." := SecondLine."Line No.";
        DerivedLine.Insert(false);
        Assert.AreEqual(1, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Derived and already shipped quantities must not be open claims.');
        Assert.AreEqual(5, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Do not subtract shipped quantity twice.');
    end;

    [Test]
    procedure ConvertedNonDividingIncrementsSumExactly()
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
        FirstLine: Record "Transfer Line";
        SecondLine: Record "Transfer Line";
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        CreateAvailabilityFixture(Entry, 1);
        CreateCalculationClaim(Entry, 0.2, 1, FirstLine);
        CreateCalculationClaim(Entry, 0.3, 1, SecondLine);
        Assert.AreEqual(0.5, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Non-dividing increments must not be rounded to a contributor increment.');
        Assert.AreEqual(0.5, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Exact converted sum leaves half a base unit.');
        FirstLine.Delete(true);
        SecondLine.Delete(true);
        CreateCalculationClaim(Entry, 0.3, 1, SecondLine);
        CreateCalculationClaim(Entry, 0.2, 1, FirstLine);
        Assert.AreEqual(0.5, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Contributor order must not affect precision.');
        FirstLine.Delete(true);
        SecondLine.Delete(true);
        CreateCalculationClaim(Entry, 0.1, 1, FirstLine);
        CreateCalculationClaim(Entry, 0.2, 1, SecondLine);
        Assert.AreEqual(0.3, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Compatible increments use the same per-line conversion.');
        Assert.AreEqual(0.7, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'No aggregate minimum-increment rounding is allowed.');
    end;

    [Test]
    procedure NativePrecisionFallbackAndZeroGuard()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        TransferLine: Record "Transfer Line" temporary;
        QuantityBase: Decimal;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", 1.23456);
        TransferLine."Item No." := Item."No.";
        TransferLine."Unit of Measure Code" := ItemUOM.Code;
        TransferLine."Transfer WIP Item" := true;
        TransferLine."Qty. per Unit of Measure" := 0;
        Assert.AreEqual(0.12346, TransferLine.CalcBaseQty(0.1), 'Use the actual item UOM and native nearest precision fallback.');
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", 0.1);
        TransferLine."Unit of Measure Code" := ItemUOM.Code;
        asserterror QuantityBase := TransferLine.CalcBaseQty(0.00001);
        Assert.ExpectedError('out of balance');
    end;

    [Test]
    procedure FinalDocumentRoundingCannotExceedCap()
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        TransferLine: Record "Transfer Line" temporary;
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        CreateAvailabilityFixture(Entry, 1);
        Item.Get(Entry."Item No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", 3);
        TransferLine."Item No." := Item."No.";
        TransferLine."Unit of Measure Code" := ItemUOM.Code;
        Availability.CheckQuantity(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", TransferLine.CalcBaseQty(0.33333), '', 0);
        asserterror Availability.CheckQuantity(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", TransferLine.CalcBaseQty(0.33334), '', 0);
        Assert.ExpectedError('exceeds the available WIP quantity');
        Assert.AreEqual(1, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Validation must not allocate or silently clamp a rounded quantity.');
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ClaimsReleaseOnReductionAndDeletion()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        CreateStateReceipt(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        SubcWarehouseLibrary.FindStateWIPEntry(Entry, PurchaseLine, Entry."WIP State"::Processed);
        SubcWarehouseLibrary.CreateStateWIPClaim(PurchaseLine, Entry, 2, TransferHeader, TransferLine);
        Assert.AreEqual(5, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Two open units leave five.');
        TransferLine.Validate(Quantity, 1);
        TransferLine.Modify(true);
        Assert.AreEqual(6, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Native reduction releases the difference.');
        TransferLine.Delete(true);
        Assert.AreEqual(7, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Native deletion releases the remainder.');
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure OutboundRequestIsMandatoryAndFixed()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        Initialize();
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true);
        PurchaseHeader.SetRecFilter();
        asserterror Report.Run(Report::"Subc. Create Transf. Order", false, false, PurchaseHeader);
        Assert.IsTrue(GetLastErrorText().ToLower().Contains('request'), 'The suppressed mandatory request must be rejected explicitly.');
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(TransferHeader);
        Assert.RecordIsEmpty(TransferLine);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 0, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure OutboundProposalEditsAndCancelAreAtomic()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        Initialize();
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true);
        StateWIPCancelNextProposal := true;
        StateWIPProposalWasCalled := false;
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create Transf. Order", true, false, PurchaseHeader);
        Assert.IsTrue(StateWIPProposalWasCalled, 'Outbound creation must present its proposal before persisting documents.');
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(TransferHeader);
        Assert.RecordIsEmpty(TransferLine);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 0, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure OutboundMessagesUseActualConditionsAndCounts()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        OriginalNo: Code[20];
    begin
        Initialize();
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true);
        SubcWarehouseLibrary.CreateStateWIPSupply(PurchaseHeader, TransferHeader, TransferLine);
        OriginalNo := TransferHeader."No.";
        PurchaseHeader.SetRecFilter();
        asserterror Report.Run(Report::"Subc. Create Transf. Order", true, false, PurchaseHeader);
        Assert.ExpectedError('There are no components or WIP quantities to transfer');
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.RecordCount(TransferHeader, 1);
        TransferHeader.FindFirst();
        Assert.AreEqual(OriginalNo, TransferHeader."No.", 'A second invocation cannot duplicate fully claimed supply.');
        TransferLine.Reset();
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();
        Assert.AreEqual(10, TransferLine.Quantity, 'The reported single line must correspond to the real created quantity.');
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure OutboundListAndApiRejectBroadenedContext()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        OtherPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
    begin
        Initialize();
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true);
        LibraryPurchase.CreatePurchHeader(OtherPurchaseHeader, OtherPurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetFilter("No.", '%1|%2', PurchaseHeader."No.", OtherPurchaseHeader."No.");
        asserterror Report.Run(Report::"Subc. Create Transf. Order", true, false, PurchaseHeader);
        Assert.IsTrue(GetLastErrorText().ToLower().Contains('purchase order'), 'Multiple purchase orders must be rejected as an invalid current-order context.');
        TransferHeader.SetFilter("Subcontr. Purch. Order No.", PurchaseHeader.GetFilter("No."));
        Assert.RecordIsEmpty(TransferHeader);
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPReturnRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ReturnCancelBoundsAndMessages()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        CreateStateReceipt(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        SubcWarehouseLibrary.FindStateWIPEntry(Entry, PurchaseLine, Entry."WIP State"::Processed);
        StateWIPCancelNextProposal := true;
        StateWIPProposalWasCalled := false;
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, PurchaseHeader);
        Assert.IsTrue(StateWIPProposalWasCalled, 'Return creation must present its proposal before persisting documents.');
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.SetRange("Subc. Return Order", true);
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseHeader."No.");
        TransferLine.SetRange("Subc. Return Order", true);
        Assert.RecordIsEmpty(TransferHeader);
        Assert.RecordIsEmpty(TransferLine);
        Assert.AreEqual(0, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Cancelling a return must not allocate its proposed quantity.');
        Assert.AreEqual(7, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Cancelling must leave the entire processed receipt available.');
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedReturnRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ComponentDemandKeepsScrapAndUnits()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Component: Record "Prod. Order Component";
        TransferLine: Record "Transfer Line";
    begin
        Initialize();
        AdvancedMode := 'Setup';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 3;
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true, true);
        Component.SetRange(Status, ProductionOrder.Status);
        Component.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(Component, 2);
        Component.FindFirst();
        Assert.AreEqual(22, Component."Expected Qty. (Base)", 'The refreshed native BOM includes ten percent scrap.');
        Component.Next();
        Assert.AreEqual(30, Component."Expected Qty. (Base)", 'The second component retains its own three-base-unit UOM.');
        SubcWarehouseLibrary.PostStateWIPSupply(PurchaseHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(PurchaseHeader, PurchaseLine, 4, ReceiptLine);
        Component.FindFirst();
        Assert.AreEqual(8.8, Component."Expected Qty. (Base)" - Component."Remaining Qty. (Base)", 'Receipt backflush must include native scrap.');
        Component.Next();
        Assert.AreEqual(12, Component."Expected Qty. (Base)" - Component."Remaining Qty. (Base)", 'Second component is consumed in its own UOM.');
        AdvancedMode := 'Components';
        ExpectedNewLines := 2;
        ExpectedPurchaseLine := PurchaseLine;
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, PurchaseHeader);
        Component.FindSet();
        repeat
            TransferLine.Reset();
            TransferLine.SetRange("Subc. Purch. Order No.", PurchaseHeader."No.");
            TransferLine.SetRange("Subc. Return Order", true);
            TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", Component."Line No.");
            TransferLine.FindFirst();
            Assert.AreEqual(Component."Remaining Qty. (Base)", TransferLine."Quantity (Base)", 'Return quantity must use actual native remaining component demand.');
            Assert.AreEqual(Component."Unit of Measure Code", TransferLine."Unit of Measure Code", 'Components cannot inherit the parent WIP UOM.');
        until Component.Next() = 0;
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 6, 4, 0);
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedReturnRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure OutboundFiltersAndCategoriesAreSymmetric()
    begin
        Initialize();
        RunRequestFilterCases(false);
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedReturnRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ReturnFiltersApplyToEveryCategory()
    begin
        Initialize();
        RunRequestFilterCases(true);
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedReturnRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ReturnRequestDefaultsResetEveryRun()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        TransferHeader: Record "Transfer Header";
    begin
        Initialize();
        CreateAdvancedReceipt(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        AdvancedMode := 'Processed';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 1;
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, PurchaseHeader);
        AdvancedMode := 'Defaults';
        ExpectedNewOrders := 0;
        ExpectedNewLines := 3;
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, PurchaseHeader);
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.SetRange("Subc. Return Order", true);
        Assert.RecordCount(TransferHeader, 1);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedReturnRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ReturnProposalShowsStateAndNetAvailability()
    var
        ProductionOrder: Record "Production Order";
        ProductionLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        ItemUOM: Record "Item Unit of Measure";
        ClaimHeader: Record "Transfer Header";
        ClaimLine: Record "Transfer Line";
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        AdvancedMode := 'Setup';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 3;
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true, true);
        ProductionLine.Get(ProductionOrder.Status, ProductionOrder."No.", PurchaseLine."Prod. Order Line No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, ProductionLine."Item No.", 10);
        ProductionLine.Validate("Unit of Measure Code", ItemUOM.Code);
        ProductionLine.Validate(Quantity, 1);
        ProductionLine.Modify(true);
        SubcWarehouseLibrary.PostStateWIPSupply(PurchaseHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(PurchaseHeader, PurchaseLine, 7, ReceiptLine);
        ExpectedPurchaseLine := PurchaseLine;
        SubcWarehouseLibrary.FindStateWIPEntry(Entry, PurchaseLine, Entry."WIP State"::Processed);
        SubcWarehouseLibrary.CreateStateWIPClaim(PurchaseLine, Entry, 2, ClaimHeader, ClaimLine);
        AdvancedMode := 'Net';
        ExpectedNewOrders := 0;
        ExpectedNewLines := 4;
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, PurchaseHeader);
        Assert.AreEqual(7, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Two existing plus five new base units are exactly one processed balance.');
        Assert.AreEqual(0, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Already net availability must not be subtracted twice.');
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedReturnRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ProposalComponentQuantitiesPreserveLocations()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Component: Record "Prod. Order Component";
        BeforeComponent: Record "Prod. Order Component";
        Reservation: Record "Reservation Entry";
        PositiveReservation: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        BeforeCount: Integer;
        BeforeReservationCount: Integer;
        BeforeReservedBase: Decimal;
        ReturnedBase: Decimal;
    begin
        Initialize();
        CreateAdvancedReceipt(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        Component.SetRange(Status, ProductionOrder.Status);
        Component.SetRange("Prod. Order No.", ProductionOrder."No.");
        Component.FindFirst();
        BeforeComponent := Component;
        Reservation.SetRange("Source Type", Database::"Prod. Order Component");
        Reservation.SetRange("Source Subtype", Component.Status.AsInteger());
        Reservation.SetRange("Source ID", Component."Prod. Order No.");
        Reservation.SetRange("Source Prod. Order Line", Component."Prod. Order Line No.");
        Reservation.SetRange("Source Ref. No.", Component."Line No.");
        Assert.IsFalse(Reservation.IsEmpty(), 'The real outbound receipt must establish a native component reservation chain.');
        BeforeReservationCount := Reservation.Count();
        Reservation.CalcSums("Quantity (Base)");
        BeforeReservedBase := Reservation."Quantity (Base)";
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseHeader."No.");
        BeforeCount := TransferLine.Count();
        AdvancedMode := 'CancelComponents';
        ExpectedNewLines := 2;
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, PurchaseHeader);
        Component.Get(BeforeComponent.Status, BeforeComponent."Prod. Order No.", BeforeComponent."Prod. Order Line No.", BeforeComponent."Line No.");
        Assert.AreEqual(BeforeComponent."Location Code", Component."Location Code", 'Cancel cannot move component demand.');
        Assert.AreEqual(BeforeComponent."Bin Code", Component."Bin Code", 'Cancel cannot reset the original bin.');
        Assert.AreEqual(BeforeCount, TransferLine.Count(), 'Cancel cannot allocate a partial return.');
        Assert.AreEqual(BeforeReservationCount, Reservation.Count(), 'Cancel cannot split or replace native reservation entries.');
        Reservation.CalcSums("Quantity (Base)");
        Assert.AreEqual(BeforeReservedBase, Reservation."Quantity (Base)", 'Cancel cannot move reserved component demand.');
        AdvancedMode := 'ReduceComponents';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 2;
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, PurchaseHeader);
        TransferLine.SetRange("Subc. Return Order", true);
        TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", Component."Line No.");
        TransferLine.FindFirst();
        Assert.AreEqual(Round(Component."Remaining Quantity" / 2, 0.00001), TransferLine.Quantity, 'The confirmed component reduction must survive creation.');
        Component.Get(BeforeComponent.Status, BeforeComponent."Prod. Order No.", BeforeComponent."Prod. Order Line No.", BeforeComponent."Line No.");
        Assert.AreEqual(BeforeComponent."Subc. Original Location Code", Component."Location Code", 'Confirmed returns must retain the native move of demand to its original location.');
        Assert.AreEqual(BeforeComponent."Subc. Original Location Code", Component."Subc. Original Location Code", 'The original home location remains available to native posting.');
        Assert.AreEqual(BeforeComponent."Subc. Orig. Bin Code", Component."Subc. Orig. Bin Code", 'The native original-bin chain must survive proposal editing.');
        Reservation.Reset();
        Reservation.SetRange("Source Type", Database::"Transfer Line");
        Reservation.SetRange("Source ID", TransferLine."Document No.");
        Reservation.SetRange("Source Ref. No.", TransferLine."Line No.");
        Reservation.SetRange(Positive, true);
        Reservation.CalcSums("Quantity (Base)");
        Assert.AreEqual(TransferLine."Quantity (Base)", Reservation."Quantity (Base)", 'Native return-receipt reservations must follow the actual selected component quantity.');
        ReturnedBase := TransferLine."Quantity (Base)";
        ReturnHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(ReturnHeader, true, true);
        Component.Get(BeforeComponent.Status, BeforeComponent."Prod. Order No.", BeforeComponent."Prod. Order Line No.", BeforeComponent."Line No.");
        Assert.AreEqual(BeforeComponent."Subc. Original Location Code", Component."Location Code", 'Native receipt must restore component demand to its original home.');
        Assert.AreEqual(BeforeComponent."Subc. Orig. Bin Code", Component."Bin Code", 'Native receipt must restore the original legal bin.');
        Reservation.Reset();
        Reservation.SetRange("Source Type", Database::"Prod. Order Component");
        Reservation.SetRange("Source Subtype", Component.Status.AsInteger());
        Reservation.SetRange("Source ID", Component."Prod. Order No.");
        Reservation.SetRange("Source Prod. Order Line", Component."Prod. Order Line No.");
        Reservation.SetRange("Source Ref. No.", Component."Line No.");
        Reservation.SetRange("Location Code", Component."Location Code");
        Reservation.FindFirst();
        PositiveReservation.Get(Reservation."Entry No.", true);
        Assert.AreEqual(Database::"Item Ledger Entry", PositiveReservation."Source Type", 'The native chain must replace expected transfer supply with an actual receipt entry.');
        ItemLedgerEntry.Get(PositiveReservation."Source Ref. No.");
        Assert.AreEqual(Component."Location Code", ItemLedgerEntry."Location Code", 'The reserved physical receipt must be at the original component home.');
        Assert.AreEqual(Component."Variant Code", ItemLedgerEntry."Variant Code", 'The real receipt cannot reserve another component variant.');
        Assert.AreEqual(ReturnedBase, ItemLedgerEntry.Quantity, 'The physically returned quantity must equal the edited proposal in base units.');
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure OutboundReuseStaysCurrentOrderScoped()
    var
        FirstOrder: Record "Production Order";
        SecondOrder: Record "Production Order";
        FirstHeader: Record "Purchase Header";
        SecondHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        SecondPurchaseLine: Record "Purchase Line";
        FirstTransfer: Record "Transfer Header";
        SecondTransfer: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FirstTransferNo: Code[20];
    begin
        Initialize();
        AdvancedMode := 'Setup';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 1;
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(FirstOrder, FirstHeader, FirstPurchaseLine, 10, 1, true);
        SubcWarehouseLibrary.CreateStateWIPSupply(FirstHeader, FirstTransfer, TransferLine);
        FirstTransferNo := FirstTransfer."No.";
        TransferLine.Validate(Quantity, 2);
        TransferLine.Modify(true);
        SubcWarehouseLibrary.CreateAdditionalStateWIPPurchaseOrder(FirstPurchaseLine, SecondOrder, SecondHeader, SecondPurchaseLine, 5);
        Assert.AreNotEqual(FirstHeader."No.", SecondHeader."No.", 'The native fixture requires two purchase orders.');
        SubcWarehouseLibrary.CreateStateWIPSupply(SecondHeader, SecondTransfer, TransferLine);
        Assert.AreNotEqual(FirstTransferNo, SecondTransfer."No.", 'Compatible routes cannot append to another purchase order.');
        Assert.AreEqual(SecondHeader."No.", SecondTransfer."Subcontr. Purch. Order No.", 'The created document remains owned by the current purchase order.');
        ExpectedNewOrders := 0;
        FirstHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create Transf. Order", true, false, FirstHeader);
        FirstTransfer.SetRange("Subcontr. Purch. Order No.", FirstHeader."No.");
        Assert.RecordCount(FirstTransfer, 1);
        FirstTransfer.FindFirst();
        Assert.AreEqual(FirstTransferNo, FirstTransfer."No.", 'A compatible header for the same purchase order must be reused.');
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", FirstTransferNo);
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.CalcSums(Quantity);
        Assert.AreEqual(10, TransferLine.Quantity, 'The same-order retry creates only eight unclaimed units.');
        TransferLine.SetRange("Document No.", SecondTransfer."No.");
        TransferLine.CalcSums(Quantity);
        Assert.AreEqual(5, TransferLine.Quantity, 'Same-order reuse cannot change the other order.');
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedReturnRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ReturnReuseAndListStayOrderScoped()
    var
        FirstOrder: Record "Production Order";
        SecondOrder: Record "Production Order";
        FirstHeader: Record "Purchase Header";
        SecondHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        SecondPurchaseLine: Record "Purchase Line";
        Receipt: Record "Purch. Rcpt. Line";
        FirstReturn: Record "Transfer Header";
        SecondReturn: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FirstReturnNo: Code[20];
        SecondReturnNo: Code[20];
        PurchaseList: TestPage "Purchase Order List";
    begin
        Initialize();
        AdvancedMode := 'Setup';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 1;
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(FirstOrder, FirstHeader, FirstPurchaseLine, 10, 1, true);
        SubcWarehouseLibrary.PostStateWIPSupply(FirstHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(FirstHeader, FirstPurchaseLine, 7, Receipt);
        ExpectedPurchaseLine := FirstPurchaseLine;
        AdvancedMode := 'Reuse';
        FirstHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, FirstHeader);
        TransferLine.SetRange("Subc. Purch. Order No.", FirstHeader."No.");
        TransferLine.SetRange("Subc. Return Order", true);
        TransferLine.FindFirst();
        FirstReturnNo := TransferLine."Document No.";
        TransferLine.Validate(Quantity, 1);
        TransferLine.Modify(true);
        AdvancedMode := 'Setup';
        SubcWarehouseLibrary.CreateAdditionalStateWIPPurchaseOrder(FirstPurchaseLine, SecondOrder, SecondHeader, SecondPurchaseLine, 10);
        Assert.AreNotEqual(FirstHeader."No.", SecondHeader."No.", 'The native fixture requires two purchase orders.');
        SubcWarehouseLibrary.PostStateWIPSupply(SecondHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(SecondHeader, SecondPurchaseLine, 7, Receipt);
        ExpectedPurchaseLine := SecondPurchaseLine;
        AdvancedMode := 'Reuse';
        SecondHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, SecondHeader);
        TransferLine.Reset();
        TransferLine.SetRange("Subc. Purch. Order No.", SecondHeader."No.");
        TransferLine.SetRange("Subc. Return Order", true);
        TransferLine.FindFirst();
        SecondReturnNo := TransferLine."Document No.";
        Assert.AreNotEqual(FirstReturnNo, SecondReturnNo, 'Return creation cannot reuse another purchase order header.');
        TransferLine.Validate(Quantity, 1);
        TransferLine.Modify(true);
        ExpectedNewOrders := 0;
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, SecondHeader);
        SecondReturn.SetRange("Subcontr. Purch. Order No.", SecondHeader."No.");
        SecondReturn.SetRange("Subc. Return Order", true);
        Assert.RecordCount(SecondReturn, 1);
        SecondReturn.FindFirst();
        Assert.AreEqual(SecondReturnNo, SecondReturn."No.", 'A compatible current-order return must be reused.');
        TransferLine.SetRange("Document No.", SecondReturnNo);
        TransferLine.CalcSums(Quantity);
        Assert.AreEqual(3, TransferLine.Quantity, 'Only the current order remaining two units are appended.');
        FirstReturn.Get(FirstReturnNo);
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", FirstReturnNo);
        TransferLine.CalcSums(Quantity);
        Assert.AreEqual(1, TransferLine.Quantity, 'The adjacent purchase order remains unchanged.');
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", SecondReturnNo);
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.FindLast();
        TransferLine.Validate(Quantity, 1);
        TransferLine.Modify(true);
        PurchaseList.OpenView();
        PurchaseList.GoToRecord(SecondHeader);
        PurchaseList.CreateReturnFromSubcontractor.Invoke();
        PurchaseList.Close();
        TransferLine.CalcSums(Quantity);
        Assert.AreEqual(3, TransferLine.Quantity, 'The list action must operate on its actual current row and reuse only that order.');
        TransferLine.SetRange("Document No.", FirstReturnNo);
        TransferLine.CalcSums(Quantity);
        Assert.AreEqual(1, TransferLine.Quantity, 'An actual list action cannot expand its context to an adjacent order.');
        asserterror Report.Run(Report::"Subc. Create SubCReturnOrder", false, false, SecondHeader);
        Assert.ExpectedError('request page');
        SecondHeader.SetFilter("No.", '%1|%2', FirstHeader."No.", SecondHeader."No.");
        asserterror Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, SecondHeader);
        Assert.IsTrue(GetLastErrorText() <> '', 'A multi-order context must never be treated as the current purchase order.');
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure MixedCohortsNeverInventLegacyState()
    var
        LegacyOrder: Record "Production Order";
        StateOrder: Record "Production Order";
        LegacyHeader: Record "Purchase Header";
        StateHeader: Record "Purchase Header";
        LegacyLine: Record "Purchase Line";
        StateLine: Record "Purchase Line";
        MergedLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        Receipt: Record "Purch. Rcpt. Line";
        Selected: Record "Subc. Transfer Proposal" temporary;
        Activation: Record "Subc. WIP Activation";
        ProposalMgt: Codeunit "Subc. Transfer Proposal Mgt.";
        ActivatedAt: DateTime;
    begin
        Initialize();
        AdvancedMode := 'Setup';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 1;
        SubcWarehouseLibrary.CreateLegacyWIPPurchaseOrder(LegacyOrder, LegacyHeader, LegacyLine, 10);
        SubcWarehouseLibrary.PostStateWIPSupply(LegacyHeader);
        Activation.Get('');
        ActivatedAt := Activation.SystemModifiedAt;
        SubcWarehouseLibrary.CreateAdditionalStateWIPPurchaseOrder(LegacyLine, StateOrder, StateHeader, StateLine, 10);
        if StateHeader."No." <> LegacyHeader."No." then begin
            Assert.AreEqual(LegacyHeader."Buy-from Vendor No.", StateHeader."Buy-from Vendor No.", 'Both actual roots must belong to the same current vendor.');
            MergedLine := StateLine;
            MergedLine."Document No." := LegacyHeader."No.";
            MergedLine."Line No." := LegacyLine."Line No." + 10000;
            MergedLine.Insert(true);
            StateLine.Delete(true);
            StateLine := MergedLine;
            StateHeader := LegacyHeader;
        end;
        SubcWarehouseLibrary.PostStateWIPSupply(StateHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(StateHeader, StateLine, 7, Receipt);
        ProposalMgt.Configure(true, false, true, false, '', '', '', '', '', '');
        AddMixedReturnCandidate(ProposalMgt, LegacyOrder, LegacyLine);
        AddMixedReturnCandidate(ProposalMgt, StateOrder, StateLine);
        AdvancedMode := 'Mixed';
        ExpectedNewLines := 2;
        Assert.IsTrue(ProposalMgt.SelectRows(Selected), 'Default mixed selection contains Legacy and new unprocessed custody.');
        Selected.Reset();
        Selected.SetRange("State Tracked", false);
        Assert.RecordCount(Selected, 1);
        Selected.FindFirst();
        Assert.AreEqual(10, Selected."Quantity to Transfer", 'Legacy ten must remain one unclassified quantity.');
        Selected.Reset();
        Selected.SetRange("State Tracked", true);
        Assert.RecordCount(Selected, 1);
        Selected.FindFirst();
        Assert.AreEqual(3, Selected."Quantity to Transfer", 'Legacy custody cannot fill a new-state candidate.');
        Selected.Reset();
        Selected.DeleteAll();
        ProposalMgt.ClearRows();
        ProposalMgt.Configure(true, false, true, true, '', '', '', '', '', '');
        AddMixedReturnCandidate(ProposalMgt, LegacyOrder, LegacyLine);
        AddMixedReturnCandidate(ProposalMgt, StateOrder, StateLine);
        ExpectedNewLines := 3;
        Assert.IsTrue(ProposalMgt.SelectRows(Selected), 'Explicit processed selection adds exactly the new seven.');
        Selected.SetRange("State Tracked", true);
        Selected.SetRange("WIP State", Selected."WIP State"::Processed);
        Assert.RecordCount(Selected, 1);
        Selected.FindFirst();
        Assert.AreEqual(7, Selected."Quantity to Transfer", 'Processed quantity belongs only to the new cohort.');
        ExpectedPurchaseLine := StateLine;
        AdvancedMode := 'Mixed';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 2;
        StateHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, StateHeader);
        TransferLine.SetRange("Subc. Purch. Order No.", StateHeader."No.");
        TransferLine.SetRange("Subc. Return Order", true);
        Assert.RecordCount(TransferLine, 2);
        TransferLine.SetRange("Subc. State Tracked", false);
        TransferLine.FindFirst();
        Assert.AreEqual(10, TransferLine.Quantity, 'The same mandatory report must preserve the unsplit Legacy row.');
        TransferLine.SetRange("Subc. State Tracked", true);
        TransferLine.FindFirst();
        Assert.AreEqual(3, TransferLine.Quantity, 'The same current purchase order can allocate only the new unprocessed three by default.');
        AdvancedMode := 'MixedProcessed';
        ExpectedNewOrders := 0;
        ExpectedNewLines := 1;
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, StateHeader);
        TransferLine.SetRange("Subc. WIP State", TransferLine."Subc. WIP State"::Processed);
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();
        Assert.AreEqual(7, TransferLine.Quantity, 'Explicit processed selection must add only the new seven on the same purchase order.');
        Activation.Get('');
        Assert.AreEqual(ActivatedAt, Activation.SystemModifiedAt, 'Normal mixed use cannot rewrite activation.');
        SubcWarehouseLibrary.AssertStateWIP(StateLine, 10, 3, 7, 0);
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedReturnRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure FamilyAndAdjacentOrdersStayIsolated()
    var
        Family: Record Family;
        LegacyOrder: Record "Production Order";
        CurrentOrder: Record "Production Order";
        AdjacentOrder: Record "Production Order";
        LegacyHeader: Record "Purchase Header";
        CurrentHeader: Record "Purchase Header";
        AdjacentHeader: Record "Purchase Header";
        LegacyLines: array[2] of Record "Purchase Line";
        CurrentLines: array[2] of Record "Purchase Line";
        AdjacentLines: array[2] of Record "Purchase Line";
        Receipt: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        ClaimHeader: Record "Transfer Header";
        ClaimLine: Record "Transfer Line";
        ReturnLine: Record "Transfer Line";
        Fixture: Codeunit "Subc. WIP Upgrade Fixture";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        AdvancedMode := 'Setup';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 2;
        CreateStateFamilyPurchaseOrder(Family, LegacyOrder, LegacyHeader, LegacyLines);
        Fixture.RestorePreactivationColumns();
        CohortMgt.InitializeCompany();
        SubcWarehouseLibrary.PostStateWIPSupply(LegacyHeader);
        CreateStateFamilyPurchaseOrder(Family, CurrentOrder, CurrentHeader, CurrentLines);
        Assert.AreEqual(CurrentLines[1]."Routing Reference No.", CurrentLines[2]."Routing Reference No.", 'This is a real family fixture with a shared routing reference.');
        Assert.AreNotEqual(CurrentLines[1]."Prod. Order Line No.", CurrentLines[2]."Prod. Order Line No.", 'Shared routing must not collapse family output lines.');
        SubcWarehouseLibrary.PostStateWIPSupply(CurrentHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(CurrentHeader, CurrentLines[1], 7, Receipt);
        SubcWarehouseLibrary.ReceiveStateWIP(CurrentHeader, CurrentLines[2], 2, Receipt);
        SubcWarehouseLibrary.AssertStateWIP(CurrentLines[1], 10, 3, 7, 0);
        SubcWarehouseLibrary.AssertStateWIP(CurrentLines[2], 4, 2, 2, 0);
        CreateStateFamilyPurchaseOrder(Family, AdjacentOrder, AdjacentHeader, AdjacentLines);
        SubcWarehouseLibrary.PostStateWIPSupply(AdjacentHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(AdjacentHeader, AdjacentLines[1], 7, Receipt);
        SubcWarehouseLibrary.FindStateWIPEntry(Entry, AdjacentLines[1], Entry."WIP State"::Processed);
        SubcWarehouseLibrary.CreateStateWIPClaim(AdjacentLines[1], Entry, 2, ClaimHeader, ClaimLine);
        ExpectedPurchaseLine := CurrentLines[1];
        ExpectedFamilyLines[1] := CurrentLines[1];
        ExpectedFamilyLines[2] := CurrentLines[2];
        AdvancedMode := 'Family';
        ExpectedNewLines := 4;
        CurrentHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", true, false, CurrentHeader);
        ReturnLine.SetRange("Subc. Purch. Order No.", CurrentHeader."No.");
        ReturnLine.SetRange("Subc. Return Order", true);
        ReturnLine.SetRange("Derived From Line No.", 0);
        Assert.RecordCount(ReturnLine, 4);
        ReturnLine.SetRange("Subc. Prod. Order Line No.", CurrentLines[1]."Prod. Order Line No.");
        ReturnLine.CalcSums(Quantity);
        Assert.AreEqual(10, ReturnLine.Quantity, 'Current family A has exactly ten, without the adjacent claim reducing it.');
        ReturnLine.SetRange("Subc. Prod. Order Line No.", CurrentLines[2]."Prod. Order Line No.");
        ReturnLine.CalcSums(Quantity);
        Assert.AreEqual(4, ReturnLine.Quantity, 'Family B owns its four independently of the shared routing reference.');
        Assert.AreEqual(5, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Current family claims cannot consume the adjacent order seven less two.');
        Entry.Reset();
        Entry.SetRange("Prod. Order No.", LegacyOrder."No.");
        Entry.SetRange("State Tracked", true);
        Assert.RecordIsEmpty(Entry);
    end;

    local procedure CreateStateFamilyPurchaseOrder(var Family: Record Family; var ProductionOrder: Record "Production Order"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLines: array[2] of Record "Purchase Line")
    var
        FamilyLine: Record "Family Line";
        Item: Record Item;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        Template: Record "Req. Wksh. Template";
        Batch: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RoutingLine: Record "Prod. Order Routing Line";
        Vendor: Record Vendor;
        Calculate: Report "Subc. Calculate Subcontracts";
        CarryOut: Report "Carry Out Action Msg. - Req.";
    begin
        if Family."No." = '' then begin
            SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
            SubcontractingMgmtLibrary.SetupInventorySetup();
            SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
            LibraryManufacturing.CreateFamily(Family);
            LibraryInventory.CreateItem(Item);
            LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item."No.", 10);
            LibraryInventory.CreateItem(Item);
            LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item."No.", 4);
            CreateFamilyRoutingWithSubcontractingWC(Family, WorkCenter[2]."No.");
            SetTransferWIPItemOnRoutingLine(Family."Routing No.", WorkCenter[2]."No.", true);
            SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
            SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        end;
        Clear(ProductionOrder);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Family, Family."No.", 1);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        RoutingLine.SetRange("Routing No.", Family."Routing No.");
        RoutingLine.FindFirst();
        WorkCenter[2].Get(RoutingLine."Work Center No.");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        CreateAndUpdateTransferRoute(ProductionOrder."Location Code", Vendor."Subc. Location Code");
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(Template, Batch);
        RequisitionLine."Worksheet Template Name" := Batch."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := Batch.Name;
        Calculate.SetWkShLine(RequisitionLine);
        Calculate.SetTableView(RoutingLine);
        Calculate.UseRequestPage(false);
        Calculate.RunModal();
        RequisitionLine.SetRange("Worksheet Template Name", Batch."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", Batch.Name);
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(RequisitionLine, 2);
        RequisitionLine.FindFirst();
        CarryOut.SetReqWkshLine(RequisitionLine);
        CarryOut.UseRequestPage(false);
        CarryOut.RunModal();
        PurchaseLines[1].Reset();
        PurchaseLines[1].SetRange("Document Type", PurchaseLines[1]."Document Type"::Order);
        PurchaseLines[1].SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(PurchaseLines[1], 2);
        PurchaseLines[1].FindFirst();
        PurchaseLines[2] := PurchaseLines[1];
        PurchaseLines[1].Next();
        PurchaseLines[2] := PurchaseLines[1];
        PurchaseLines[1].FindFirst();
        Assert.AreEqual(PurchaseLines[1]."Document No.", PurchaseLines[2]."Document No.", 'Both family items must share the current subcontracting purchase order.');
        PurchaseHeader.Get(PurchaseLines[1]."Document Type", PurchaseLines[1]."Document No.");
    end;

    [Test]
    [HandlerFunctions('AdvancedOutboundRequest,AdvancedProposal,AdvancedMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ParallelSourcesKeepCompleteOperationKeys()
    var
        Item: Record Item;
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        Header: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TargetHeader: Record "Purchase Header";
        TargetLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        SourceEntry: Record "Subcontractor WIP Ledger Entry";
        FirstPosition: Integer;
        FirstLot: Guid;
        SourceVendor: Record Vendor;
        TargetVendor: Record Vendor;
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        AdvancedMode := 'Setup';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 1;
        SubcWarehouseLibrary.CreateParallelRoutingItemWithSubcontracting(Item, MachineCenter, WorkCenter);
        Item.Validate("Production BOM No.", '');
        Item.Modify(true);
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);
        RoutingLine.Get(Item."Routing No.", '', '20');
        RoutingLine.Validate(Type, RoutingLine.Type::"Work Center");
        RoutingLine.Validate("No.", WorkCenter[1]."No.");
        RoutingLine.Validate("Transfer WIP Item", true);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 6);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        CreatePurchaseOrderAtOperation(ProductionOrder, '20', 3, Header, PurchaseLine);
        SubcWarehouseLibrary.PostStateWIPSupply(Header);
        SubcWarehouseLibrary.FindStateWIPEntry(SourceEntry, PurchaseLine, SourceEntry."WIP State"::Unprocessed);
        FirstPosition := SourceEntry."Source Position No.";
        FirstLot := SourceEntry."Supply Lot ID";
        CreatePurchaseOrderAtOperation(ProductionOrder, '30', 3, Header, PurchaseLine);
        SubcWarehouseLibrary.PostStateWIPSupply(Header);
        SubcWarehouseLibrary.FindStateWIPEntry(SourceEntry, PurchaseLine, SourceEntry."WIP State"::Unprocessed);
        Assert.AreNotEqual(FirstPosition, SourceEntry."Source Position No.", 'Same-location predecessors still require distinct operation source keys.');
        Assert.AreNotEqual(FirstLot, SourceEntry."Supply Lot ID", 'Independent physical supplies retain distinct lots.');
        SourceVendor.Get(Header."Buy-from Vendor No.");
        CreatePurchaseOrderAtOperation(ProductionOrder, '40', 6, TargetHeader, TargetLine);
        TargetVendor.Get(TargetHeader."Buy-from Vendor No.");
        CreateAndUpdateTransferRoute(SourceVendor."Subc. Location Code", TargetVendor."Subc. Location Code");
        ExpectedNewLines := 2;
        TargetHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create Transf. Order", true, false, TargetHeader);
        TransferLine.SetRange("Subc. Purch. Order No.", TargetHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        Assert.RecordCount(TransferLine, 2);
        TransferLine.SetRange("Prev. Operation No.", '20');
        TransferLine.FindFirst();
        Assert.AreEqual(3, TransferLine.Quantity, 'The first predecessor cannot borrow the second three.');
        Assert.AreEqual(FirstPosition, TransferLine."Subc. Source Position No.", 'Confirmation must retain exact predecessor identity.');
        Assert.AreEqual(FirstLot, TransferLine."Subc. Supply Lot ID", 'Confirmation must retain original supply provenance.');
        TransferLine.SetRange("Prev. Operation No.", '30');
        TransferLine.FindFirst();
        Assert.AreEqual(3, TransferLine.Quantity, 'The second predecessor remains separately capped.');
        Assert.AreEqual(SourceEntry."Source Position No.", TransferLine."Subc. Source Position No.", 'Native previous-operation filters cannot become synthetic source keys.');
        Assert.AreEqual(0, Availability.Available(FirstPosition, SourceEntry."WIP State", FirstLot, '', 0), 'First source is claimed exactly once.');
        Assert.AreEqual(0, Availability.Available(SourceEntry."Source Position No.", SourceEntry."WIP State", SourceEntry."Supply Lot ID", '', 0), 'Second source is claimed exactly once.');
    end;

    local procedure CreatePurchaseOrderAtOperation(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; Quantity: Decimal; var Header: Record "Purchase Header"; var Line: Record "Purchase Line")
    var
        RoutingLine: Record "Prod. Order Routing Line";
        RoutingPage: TestPage "Prod. Order Routing";
    begin
        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        RoutingLine.SetRange("Operation No.", OperationNo);
        RoutingLine.FindFirst();
        RoutingPage.OpenView();
        RoutingPage.GoToRecord(RoutingLine);
        RoutingPage.CreateSubcontracting.Invoke();
        RoutingPage.Close();
        Line.Reset();
        Line.SetRange("Document Type", Line."Document Type"::Order);
        Line.SetRange("Prod. Order No.", ProductionOrder."No.");
        Line.SetRange("Operation No.", OperationNo);
        Line.FindFirst();
        Line.Validate(Quantity, Quantity);
        Line.Modify(true);
        Header.Get(Line."Document Type", Line."Document No.");
    end;

    local procedure AddMixedReturnCandidate(var ProposalMgt: Codeunit "Subc. Transfer Proposal Mgt."; ProductionOrder: Record "Production Order"; PurchaseLine: Record "Purchase Line")
    var
        ProductionLine: Record "Prod. Order Line";
        Vendor: Record Vendor;
        Header: Record "Purchase Header";
    begin
        Header.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Vendor.Get(Header."Buy-from Vendor No.");
        ProductionLine.Get(ProductionOrder.Status, ProductionOrder."No.", PurchaseLine."Prod. Order Line No.");
        ProposalMgt.AddWIP(PurchaseLine, ProductionLine, Vendor."Subc. Location Code", ProductionOrder."Location Code", '', 10, ProductionLine."Unit of Measure Code");
    end;

    local procedure CreateAdvancedReceipt(var ProductionOrder: Record "Production Order"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ReceiptLine: Record "Purch. Rcpt. Line")
    begin
        AdvancedMode := 'Setup';
        ExpectedNewOrders := 1;
        ExpectedNewLines := 3;
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true, true);
        SubcWarehouseLibrary.PostStateWIPSupply(PurchaseHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(PurchaseHeader, PurchaseLine, 7, ReceiptLine);
        ExpectedPurchaseLine := PurchaseLine;
    end;

    local procedure RunRequestFilterCases(ReturnOrder: Boolean)
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        TransferHeader: Record "Transfer Header";
        ReportID: Integer;
        I: Integer;
    begin
        for I := 1 to 6 do begin
            AdvancedMode := 'Setup';
            ExpectedNewOrders := 1;
            ExpectedNewLines := 3;
            SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true, true);
            if ReturnOrder then begin
                SubcWarehouseLibrary.PostStateWIPSupply(PurchaseHeader);
                SubcWarehouseLibrary.ReceiveStateWIP(PurchaseHeader, PurchaseLine, 7, ReceiptLine);
                ReportID := Report::"Subc. Create SubCReturnOrder";
            end else
                ReportID := Report::"Subc. Create Transf. Order";
            ExpectedPurchaseLine := PurchaseLine;
            ExpectedComponent.Reset();
            ExpectedComponent.SetRange(Status, ProductionOrder.Status);
            ExpectedComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
            ExpectedComponent.FindFirst();
            AdvancedMode := 'Filter';
            FilterNumber := I;
            FilterMatches := false;
            PurchaseHeader.SetRecFilter();
            asserterror Report.Run(ReportID, true, false, PurchaseHeader);
            Assert.ExpectedError('There are no components or WIP quantities to transfer');
            TransferHeader.Reset();
            TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
            TransferHeader.SetRange("Subc. Return Order", ReturnOrder);
            Assert.RecordIsEmpty(TransferHeader);
            FilterMatches := true;
            if I >= 5 then
                ExpectedNewLines := 1;
            Report.Run(ReportID, true, false, PurchaseHeader);
            TransferHeader.FindFirst();
            Assert.AreEqual(PurchaseHeader."No.", TransferHeader."Subcontr. Purch. Order No.", 'Filter confirmation cannot broaden the purchase context.');
        end;
        AdvancedMode := 'Setup';
        ExpectedNewLines := 3;
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true, true);
        if ReturnOrder then begin
            SubcWarehouseLibrary.PostStateWIPSupply(PurchaseHeader);
            SubcWarehouseLibrary.ReceiveStateWIP(PurchaseHeader, PurchaseLine, 7, ReceiptLine);
        end;
        AdvancedMode := 'Components';
        ExpectedNewLines := 2;
        ExpectedPurchaseLine := PurchaseLine;
        PurchaseHeader.SetRecFilter();
        Report.Run(ReportID, true, false, PurchaseHeader);
    end;

    local procedure CurrentFilter(): Text
    var
        Result: Text;
    begin
        case FilterNumber of
            1: Result := ExpectedPurchaseLine."Prod. Order No.";
            2: Result := Format(ExpectedPurchaseLine."Prod. Order Line No.");
            3: Result := ExpectedPurchaseLine."Operation No.";
            4: Result := ExpectedPurchaseLine."Work Center No.";
            5: Result := ExpectedComponent."Item No.";
            6: Result := ExpectedComponent."Variant Code";
        end;
        if not FilterMatches then
            if FilterNumber = 2 then
                Result := '2147483647'
            else
                Result := 'NO-MATCH';
        exit(Result);
    end;

    [RequestPageHandler]
    procedure AdvancedOutboundRequest(var Request: TestRequestPage "Subc. Create Transf. Order")
    begin
        if AdvancedMode = 'Filter' then
            case FilterNumber of
                1: Request.ProductionOrderNo.SetValue(CurrentFilter());
                2: Request.ProductionOrderLineNo.SetValue(CurrentFilter());
                3: Request.OperationNo.SetValue(CurrentFilter());
                4: Request.WorkCenterNo.SetValue(CurrentFilter());
                5: Request.ItemNo.SetValue(CurrentFilter());
                6: Request.VariantCode.SetValue(CurrentFilter());
            end;
        if AdvancedMode = 'Components' then
            Request.IncludeWIP.SetValue(false);
        Request.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure AdvancedReturnRequest(var Request: TestRequestPage "Subc. Create SubCReturnOrder")
    begin
        Request.IncludeComponents.AssertEquals(true);
        Request.IncludeUnprocessedWIP.AssertEquals(true);
        Request.IncludeProcessedWIP.AssertEquals(false);
        Request.PurchaseOrderNo.AssertEquals(ExpectedPurchaseLine."Document No.");
        Assert.IsFalse(Request.PurchaseOrderNo.Editable(), 'Current purchase order is fixed.');
        Assert.IsFalse(Request.VendorNo.Editable(), 'Current vendor is fixed.');
        Assert.IsFalse(Request.SubcontractorLocation.Editable(), 'Current subcontractor location is fixed.');
        if AdvancedMode = 'Filter' then
            case FilterNumber of
                1: Request.ProductionOrderNo.SetValue(CurrentFilter());
                2: Request.ProductionOrderLineNo.SetValue(CurrentFilter());
                3: Request.OperationNo.SetValue(CurrentFilter());
                4: Request.WorkCenterNo.SetValue(CurrentFilter());
                5: Request.ItemNo.SetValue(CurrentFilter());
                6: Request.VariantCode.SetValue(CurrentFilter());
            end;
        if AdvancedMode in ['Components', 'CancelComponents', 'ReduceComponents'] then
            Request.IncludeUnprocessedWIP.SetValue(false);
        if AdvancedMode = 'Processed' then begin
            Request.IncludeComponents.SetValue(false);
            Request.IncludeUnprocessedWIP.SetValue(false);
            Request.IncludeProcessedWIP.SetValue(true);
        end;
        if AdvancedMode in ['Net', 'Family', 'MixedProcessed'] then
            Request.IncludeProcessedWIP.SetValue(true);
        Request.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AdvancedProposal(var Proposal: TestPage "Subc. Transfer Proposal")
    var
        Count: Integer;
        ProcessedRows: Integer;
        ComponentRows: Integer;
    begin
        Assert.IsTrue(Proposal.First(), 'A positive proposal requires actual rows.');
        repeat
            Count += 1;
            if Proposal."WIP Status".Value() = '' then begin
                if AdvancedMode = 'Mixed' then begin
                    Proposal."WIP Cohort".AssertEquals('Legacy');
                    Proposal."Available Quantity".AssertEquals(10);
                end else
                    ComponentRows += 1;
                if AdvancedMode = 'ReduceComponents' then
                    Proposal."Quantity to Transfer".SetValue(Round(Proposal."Quantity to Transfer".AsDecimal() / 2, 0.00001));
            end else begin
                if AdvancedMode = 'Defaults' then begin
                    Proposal."WIP Status".AssertEquals('Unprocessed');
                    Proposal."Available Quantity".AssertEquals(3);
                end;
                if AdvancedMode = 'MixedProcessed' then begin
                    Proposal."WIP Status".AssertEquals('Processed');
                    Proposal."Available Quantity".AssertEquals(7);
                end;
                if (AdvancedMode = 'Net') and (Proposal."WIP Status".Value() = 'Processed') then begin
                    ProcessedRows += 1;
                    Proposal."Available Quantity".AssertEquals(0.5);
                    Proposal."Quantity on Transfer".AssertEquals(0.2);
                    Proposal."Quantity to Transfer".AssertEquals(0.5);
                end;
            end;
            if AdvancedMode = 'Filter' then begin
                Proposal."Production Order No.".AssertEquals(ExpectedPurchaseLine."Prod. Order No.");
                Proposal."Production Order Line No.".AssertEquals(ExpectedPurchaseLine."Prod. Order Line No.");
                Proposal."Operation No.".AssertEquals(ExpectedPurchaseLine."Operation No.");
                if FilterNumber = 5 then
                    Proposal."Item No.".AssertEquals(ExpectedComponent."Item No.");
                if FilterNumber = 6 then
                    Proposal."Variant Code".AssertEquals(ExpectedComponent."Variant Code");
            end;
            if AdvancedMode = 'Family' then begin
                Proposal."Production Order No.".AssertEquals(ExpectedPurchaseLine."Prod. Order No.");
                if Proposal."Production Order Line No.".AsInteger() = ExpectedFamilyLines[1]."Prod. Order Line No." then
                    Proposal."Item No.".AssertEquals(ExpectedFamilyLines[1]."No.")
                else begin
                    Proposal."Production Order Line No.".AssertEquals(ExpectedFamilyLines[2]."Prod. Order Line No.");
                    Proposal."Item No.".AssertEquals(ExpectedFamilyLines[2]."No.");
                end;
                Proposal."WIP Cohort".AssertEquals('State V1');
            end;
        until not Proposal.Next();
        Assert.AreEqual(ExpectedNewLines, Count, 'Only eligible, selected-category rows may reach confirmation.');
        if AdvancedMode = 'Net' then begin
            Assert.AreEqual(1, ProcessedRows, 'A processed source must not be duplicated.');
            Assert.AreEqual(2, ComponentRows, 'Components remain separate and have blank processing state.');
        end;
        if AdvancedMode = 'Defaults' then
            Assert.AreEqual(2, ComponentRows, 'Default components remain included after a processed-only invocation.');
        if AdvancedMode = 'CancelComponents' then
            Proposal.Cancel().Invoke()
        else
            Proposal.OK().Invoke();
    end;

    [MessageHandler]
    procedure AdvancedMessage(Message: Text[1024])
    begin
        Assert.AreEqual(StrSubstNo('%1 transfer order(s) with %2 line(s) were created.', ExpectedNewOrders, ExpectedNewLines), Message, 'Success counts must describe real inserted headers and lines.');
    end;

    local procedure CreateAvailabilityFixture(var Entry: Record "Subcontractor WIP Ledger Entry"; QuantityBase: Decimal)
    var
        Item: Record Item;
        Location: Record Location;
        Availability: Codeunit "Subc. WIP Availability";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Clear(Entry);
        Entry."Entry No." := Entry.GetNextEntryNo();
        Entry."Item No." := Item."No.";
        Entry."Base Unit of Measure" := Item."Base Unit of Measure";
        Entry."Location Code" := Location.Code;
        Entry."Lineage ID" := CreateGuid();
        Entry."State Tracked" := true;
        Entry."WIP State" := Entry."WIP State"::Processed;
        Entry."Supply Lot ID" := CreateGuid();
        Entry."Quantity (Base)" := QuantityBase;
        Availability.EnsurePosition(Entry);
        Entry.Insert(false);
    end;

    local procedure CreateCalculationClaim(Entry: Record "Subcontractor WIP Ledger Entry"; UOMFactor: Decimal; Quantity: Decimal; var TransferLine: Record "Transfer Line")
    var
        ItemUOM: Record "Item Unit of Measure";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Entry."Item No.", UOMFactor);
        FromLocation.Get(Entry."Location Code");
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Entry."Item No.", 0);
        TransferLine.Validate("Transfer WIP Item", true);
        TransferLine.Validate("Unit of Measure Code", ItemUOM.Code);
        TransferLine.Validate("Subc. Source Position No.", Entry."Source Position No.");
        TransferLine.Validate("Subc. WIP State", Entry."WIP State");
        TransferLine.Validate("Subc. Supply Lot ID", Entry."Supply Lot ID");
        TransferLine.Validate(Quantity, Quantity);
        TransferLine.Modify(true);
    end;

    local procedure CreateStateReceipt(var ProductionOrder: Record "Production Order"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ReceiptLine: Record "Purch. Rcpt. Line")
    begin
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true);
        SubcWarehouseLibrary.PostStateWIPSupply(PurchaseHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(PurchaseHeader, PurchaseLine, 7, ReceiptLine);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
    end;

    [RequestPageHandler]
    procedure StateWIPRequest(var Request: TestRequestPage "Subc. Create Transf. Order")
    begin
        Request.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StateWIPReturnRequest(var Request: TestRequestPage "Subc. Create SubCReturnOrder")
    begin
        Request.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure StateWIPProposal(var Proposal: TestPage "Subc. Transfer Proposal")
    begin
        StateWIPProposalWasCalled := true;
        if StateWIPCancelNextProposal then begin
            StateWIPCancelNextProposal := false;
            Proposal.Cancel().Invoke();
            exit;
        end;
        Proposal.OK().Invoke();
    end;

    [MessageHandler]
    procedure StateWIPMessage(Message: Text[1024])
    begin
        Assert.IsTrue(
            (Message = '1 transfer order(s) with 1 line(s) were created.') or
            Message.StartsWith('No available quantity was found for: '),
            'Unexpected state WIP creation message: ' + Message);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    [Scope('OnPrem')]
    procedure CoveredWIPExplainsWhyNoTransferIsCreated()
    var
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        OriginalQuantity: Decimal;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 648962] An existing WIP-only transfer fully covers positive eligible demand.
        Initialize();

        // [GIVEN] WIP demand with no eligible components is fully covered by an outbound transfer.
        CreateWIPOnlyTransfer(PurchaseHeader, TransferHeader, TransferLine);
        OriginalQuantity := TransferLine.Quantity;
        Assert.IsTrue(OriginalQuantity > 0, 'The WIP transfer must cover positive demand.');
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);

        // [WHEN] Attempting to create the same WIP transfer again.
        asserterror PurchaseOrder.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Coverage is explained and no duplicate WIP quantity is created.
        Assert.ExpectedError('There are no components or WIP quantities to transfer for the selected filters.');
        Assert.AreEqual(1, TransferLine.Count(), 'No duplicate WIP line should be created.');
        TransferLine.FindFirst();
        Assert.AreEqual(OriginalQuantity, TransferLine.Quantity, 'Covered WIP quantity must not change.');
        PurchaseOrder.Close();
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    [Scope('OnPrem')]
    procedure ShippedWIPCoverageExplainsAndNavigates()
    var
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SubcPurchaseHeaderExt: Codeunit "Subc. Purchase Header Ext";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 648962] WIP in transit explains coverage and the released unposted document remains navigable.
        Initialize();

        // [GIVEN] A WIP-only outbound transfer has been shipped but not received.
        CreateWIPOnlyTransfer(PurchaseHeader, TransferHeader, TransferLine);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        TransferHeader.Get(TransferHeader."No.");
        TransferLine.FindFirst();
        Assert.AreEqual(TransferLine.Quantity, TransferLine."Quantity Shipped", 'The WIP transfer must be shipped.');
        Assert.AreEqual(TransferHeader.Status::Released, TransferHeader.Status, 'The in-transit document must be released.');
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);

        // [WHEN] Attempting another transfer while WIP is in transit.
        asserterror PurchaseOrder.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Coverage is explained and the action opens the existing shipped transfer.
        Assert.ExpectedError('There are no components or WIP quantities to transfer for the selected filters.');
        PurchaseOrder.Close();
        OpenedTransferOrderNo := '';
        SubcPurchaseHeaderExt.ShowOutboundTransferOrdersForPurchHeader(
            SubcPurchaseHeaderExt.CreateCoveredTransferErrorInfo(PurchaseHeader));
        Assert.AreEqual(TransferHeader."No.", OpenedTransferOrderNo, 'The action must open the shipped outbound transfer.');
    end;

    local procedure CreateWIPOnlyTransfer(var PurchaseHeader: Record "Purchase Header"; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        CreateAndUpdateTransferRoute(ProductionOrder."Location Code", Vendor."Subc. Location Code");
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseOrder.Close();
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Transfer WIP Item", true);
        TransferLine.SetRange("Subc. Return Order", false);
        TransferLine.SetRange("Derived From Line No.", 0);
        Assert.AreEqual(1, TransferLine.Count(), 'Expected exactly one WIP transfer line.');
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");
    end;

    [Test]
    procedure TransferWIPItemFlagFromRoutingLineToPurchaseLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        SubcCalculateSubContracts: Report "Subc. Calculate Subcontracts";
    begin
        // [SCENARIO] The "Transfer WIP Item" flag set on a Routing Line is propagated through the
        // Prod. Order Routing Line to the Purchase Line when the subcontracting purchase order
        // is created via the Subcontracting Worksheet (Calculate Subcontracts → Carry Out Action).

        // [GIVEN] Complete setup of Manufacturing, Work- and Machine Centers, subcontracting item
        Initialize();

        // [GIVEN] Create work centers and machine centers
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create item with routing and prod. BOM – set "Transfer WIP Item" on routing
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Verify Prod. Order Routing Line carries the flag
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.IsTrue(ProdOrderRoutingLine."Transfer WIP Item",
            'Prod. Order Routing Line must inherit Transfer WIP Item from Routing Line.');

        // [GIVEN] Setup requisition worksheet
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        // [WHEN] Calculate Subcontracts and Carry Out Action Msg creates Purchase Order
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubContracts.UseRequestPage(false);
        SubcCalculateSubContracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] Purchase Line carries "Transfer WIP Item" = true
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        Assert.IsTrue(PurchaseLine."Transfer WIP Item",
            'Purchase Line must carry "Transfer WIP Item" = true from Prod. Order Routing Line.');
    end;

    [Test]
    procedure TransferWIPItemFlagNotSetWhenRoutingLineHasFlagOff()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        SubcCalculateSubContracts: Report "Subc. Calculate Subcontracts";
    begin
        // [SCENARIO] When "Transfer WIP Item" is NOT set on the Routing Line,
        // the Purchase Line must NOT have the flag set.

        // [GIVEN] Setup
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        // Routing line "Transfer WIP Item" defaults to false – do NOT set it

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Verify flag is false on Prod. Order Routing Line
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.IsFalse(ProdOrderRoutingLine."Transfer WIP Item",
            'Prod. Order Routing Line must NOT have Transfer WIP Item when routing line does not set it.');

        // [GIVEN] Setup worksheet
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        // [WHEN] Create Purchase Order via Subcontracting Worksheet
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubContracts.UseRequestPage(false);
        SubcCalculateSubContracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] Purchase Line carries "Transfer WIP Item" = false
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        Assert.IsFalse(PurchaseLine."Transfer WIP Item",
            'Purchase Line must NOT carry "Transfer WIP Item" when routing line flag is off.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPAndCompTransferOrderCreatedFromSubcontrPurchOrder_SameLocation()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When a Subcontracting Purchase Order is created for a routing line with
        // "Transfer WIP Item" = true, running "Create Transfer Order to Subcontractor" creates
        // a WIP Transfer Line with "Transfer WIP Item" = true, correct item, quantity, and locations.
        // Component lines and WIP Transfer Lines are created with the same locations.

        // [GIVEN] Complete setup
        Initialize();

        // [GIVEN] Work centers, machine centers, item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Set "Transfer WIP Item" on the subcontracting routing line
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Set up component transfer infrastructure
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order to Subcontractor
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] A WIP Transfer Line exists with correct properties
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Subc. Return Order", false);
        Assert.RecordCount(TransferLine, 2);

        //Only One transfer header should have been created for both the component and WIP transfer lines
        TransferLine.FindFirst();
        TransferLine.SetFilter("Document No.", '<>%1', TransferLine."Document No.");
        Assert.RecordCount(TransferLine, 0);

        //Only one of the two lines should have the Transfer WIP Item flag set
        TransferLine.SetRange("Document No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);

        TransferLine.FindFirst();
        Assert.AreEqual(Item."No.", TransferLine."Item No.",
            'WIP Transfer Line must reference the production order parent item.');
        Assert.AreEqual(ProductionOrder.Quantity, TransferLine.Quantity,
            'WIP Transfer Line must have the same quantity as the production order.');

        // [THEN] Transfer header has correct from/to locations
        TransferHeader.Get(TransferLine."Document No.");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Assert.AreEqual(Vendor."Subc. Location Code", TransferHeader."Transfer-to Code",
            'WIP Transfer must go TO the subcontractor location.');

        // [TEARDOWN]
        TransferHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrders,StateWIPRequest,StateWIPProposal')]
    procedure WIPAndCompTransferOrderCreatedFromSubcontrPurchOrder_DifferentLocation()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When a Subcontracting Purchase Order is created for a routing line with
        // "Transfer WIP Item" = true, running "Create Transfer Order to Subcontractor" creates
        // a WIP Transfer Line with "Transfer WIP Item" = true, correct item, quantity, and locations.
        // Component lines and WIP Transfer Lines are created with different locations.

        // [GIVEN] Complete setup
        Initialize();

        // [GIVEN] Work centers, machine centers, item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Set "Transfer WIP Item" on the subcontracting routing line
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Set up component transfer infrastructure
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No."); //different location for component transfer than WIP transfer
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order to Subcontractor
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Transfer Lines exists with correct properties
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Subc. Return Order", false);
        Assert.RecordCount(TransferLine, 2);

        //two transfer headers should have been created for both the component and WIP transfer lines
        TransferLine.FindFirst();
        TransferLine.SetFilter("Document No.", '<>%1', TransferLine."Document No.");
        Assert.RecordCount(TransferLine, 1);

        //Only one of the two lines should have the Transfer WIP Item flag set
        TransferLine.SetRange("Document No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);

        TransferLine.FindFirst();
        Assert.AreEqual(Item."No.", TransferLine."Item No.",
            'WIP Transfer Line must reference the production order parent item.');
        Assert.AreEqual(ProductionOrder.Quantity, TransferLine.Quantity,
            'WIP Transfer Line must have the same quantity as the production order.');

        // [THEN] Transfer header has correct from/to locations
        TransferHeader.Get(TransferLine."Document No.");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Assert.AreEqual(Vendor."Subc. Location Code", TransferHeader."Transfer-to Code",
            'WIP Transfer must go TO the subcontractor location.');
    end;

    [Test]
    [HandlerFunctions('HandleMultipleTransferOrders,StateWIPRequest,StateWIPProposal')]
    procedure MultipleWIPTransferOrdersFromPurchaseOrderOpenTransferOrdersPage()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: array[2] of Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        TransferHeader: Record "Transfer Header";
        WorkCenter: array[2] of Record "Work Center";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        SubcCalculateSubContracts: Report "Subc. Calculate Subcontracts";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 641284] Creating WIP transfer orders for purchase lines from production orders at different locations opens all transfer orders.
        Initialize();

        // [GIVEN] A subcontracting item with WIP transfer enabled
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Two released production orders for the item at different locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder[1], "Production Order Status"::Released,
            ProductionOrder[1]."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5, Location[1].Code);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder[2], "Production Order Status"::Released,
            ProductionOrder[2]."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5, Location[2].Code);

        // [GIVEN] One subcontracting purchase order containing a line for each production order
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        WorkCenter[2].SetRecFilter();
        SubcCalculateSubContracts.SetTableView(WorkCenter[2]);
        SubcCalculateSubContracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubContracts.UseRequestPage(false);
        SubcCalculateSubContracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        Assert.RecordCount(RequisitionLine, 2);
        RequisitionLine.FindFirst();
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);

        // [WHEN] Create Transfer Order to Subcontractor is invoked from the purchase order
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] A transfer order was created for each production order location
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.SetRange("Subc. Return Order", false);
        Assert.RecordCount(TransferHeader, 2);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferOrderNotCreatedWhenFlagIsOff()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When "Transfer WIP Item" flag is NOT set on the routing line, creating
        // a Transfer Order to Subcontractor must NOT create a WIP Transfer Line.

        // [GIVEN] Setup
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        // Do NOT set Transfer WIP Item on routing line

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Purchase Order and Transfer Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] No WIP Transfer Line exists
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Transfer WIP Item", true);
        Assert.RecordIsEmpty(TransferLine);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure NoWIPTransferCreatedWhenExpectedEqualsPostedQuantity()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcPurchaseHeaderExt: Codeunit "Subc. Purchase Header Ext";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 648962] Posted WIP covering positive eligible demand produces an explanatory error without a new transfer.
        Initialize();

        // [GIVEN] Work centers, machine centers, item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Set "Transfer WIP Item" on the subcontracting routing line
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Get routing line information
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] Create first Subcontracting Purchase Order and Transfer Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [GIVEN] Verify first WIP Transfer Line was created
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();

        // [GIVEN] Simulate posting the transfer by creating WIP Ledger Entry with quantity equal to expected quantity
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Vendor."Subc. Location Code",
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            WorkCenter[2]."No.", ProductionOrder.Quantity, false);

        // [GIVEN] Delete the first transfer order to allow re-creation attempt
        TransferHeader.Get(TransferLine."Document No.");
        TransferHeader.Delete(true);
        Assert.AreEqual(0, TransferLine.Count(), 'The posted-only setup must have no open WIP transfer lines.');

        // [WHEN] Attempt to create Transfer Order to Subcontractor again
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        asserterror PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] The error explains that transfer activity already covers the demand, and no WIP transfer is created.
        Assert.ExpectedError(SubcPurchaseHeaderExt.CreateCoveredTransferErrorInfo(PurchaseHeader).Message);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPReturnRequest,StateWIPProposal')]
    procedure WIPReturnTransferOrderCreatedWithCorrectLocations()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ProdOrderLocationCode: Code[10];
        SubcLocationCode: Code[10];
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] After a WIP Transfer Order has been created and posted, creating
        // a Return Transfer Order creates a WIP Return Transfer Line with reversed
        // from/to locations compared to the original WIP Transfer Order.

        // [GIVEN] Complete setup
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Get the WIP Transfer Line and locate the subcontractor location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SubcLocationCode := Vendor."Subc. Location Code";

        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLocationCode := ProdOrderLine."Location Code";

        // [GIVEN] Find the routing line to get operation details
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] Mock WIP Ledger Entry at subcontractor location (simulates posted WIP transfer)
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", SubcLocationCode,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            '', LibraryRandom.RandInt(10) + 1, false);

        // [WHEN] Create Return Transfer Order from Subcontractor
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] A WIP Return Transfer Line exists
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", true);
        Assert.RecordIsNotEmpty(TransferLine);

        TransferLine.FindFirst();
        Assert.AreEqual(Item."No.", TransferLine."Item No.",
            'WIP Return Transfer Line must reference the production order parent item.');
        Assert.AreEqual(WIPLedgerEntry."Quantity (Base)", TransferLine.Quantity,
            'WIP Return Transfer Line must have the same quantity as the WIP Ledger Entry.');

        // [THEN] Return Transfer Header has reversed locations (from subcontractor, to company WH)
        TransferHeader.Get(TransferLine."Document No.");
        Assert.AreEqual(SubcLocationCode, TransferHeader."Transfer-from Code",
            'Return WIP Transfer must come FROM the subcontractor location.');
        Assert.AreEqual(ProdOrderLocationCode, TransferHeader."Transfer-to Code",
            'Return WIP Transfer must go TO the Prod. Order Line location (company WH).');

        // [TEARDOWN]
        WIPLedgerEntry.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferOrderFromSubc1ToSubc2WhenPreviousOpIsSubcontracting()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Subc1LocationCode: Code[10];
        Subc2LocationCode: Code[10];
        WIPQty: Decimal;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When a WIP item has been processed at Subcontractor 1 (the immediate previous
        // subcontracting operation), creating a Transfer Order to Subcontractor 2 creates a WIP
        // Transfer Line going FROM Subcontractor 1's location TO Subcontractor 2's location.
        // The quantity on the WIP Transfer Line matches the WIP Ledger Entry at Subcontractor 1.

        // [GIVEN] Complete setup
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Two subcontracting work centers, each with their own vendor and location
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Set "Transfer WIP Item" on Subcontractor 1 and Subcontractor 2 routing line (the current operation)
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[1]."No.", true);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Assign dedicated subcontractor locations to both vendors
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[1]);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Read subcontractor location codes after all vendor updates
        Vendor1.Get(WorkCenter[1]."Subcontractor No.");
        Vendor2.Get(WorkCenter[2]."Subcontractor No.");
        Subc1LocationCode := Vendor1."Subc. Location Code";
        Subc2LocationCode := Vendor2."Subc. Location Code";

        // [GIVEN] Locate the Prod. Order line and the routing line for Subcontractor 1 (previous op)
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[1]."No.");
        ProdOrderRoutingLine.FindLast();

        // [GIVEN] Insert a WIP Ledger Entry at Subcontractor 1's location, simulating that
        // the production item has been processed and is physically at Subcontractor 1
        WIPQty := LibraryRandom.RandInt(10) + 1;
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Subc1LocationCode,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            WorkCenter[1]."No.", WIPQty, false);

        // [WHEN] Create Subcontracting Purchase Order for Subcontractor 2's operation
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Transfer Order to Subcontractor 2
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] A WIP Transfer Line exists for the production order
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        Assert.RecordCount(TransferLine, 1);

        TransferLine.FindFirst();
        Assert.AreEqual(Item."No.", TransferLine."Item No.",
            'WIP Transfer Line must reference the production order parent item.');
        Assert.AreEqual(WIPQty, TransferLine.Quantity,
            'WIP Transfer Line quantity must match the WIP Ledger Entry at Subcontractor 1.');

        // [THEN] Transfer Header must go FROM Subcontractor 1's location TO Subcontractor 2's location
        TransferHeader.Get(TransferLine."Document No.");
        Assert.AreEqual(Subc1LocationCode, TransferHeader."Transfer-from Code",
            'WIP Transfer must come FROM Subcontractor 1''s location (previous subcontracting operation).');
        Assert.AreEqual(Subc2LocationCode, TransferHeader."Transfer-to Code",
            'WIP Transfer must go TO Subcontractor 2''s location.');

        // [TEARDOWN]
        WIPLedgerEntry.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrders,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferOrdersCreatedForParallelRoutingPredecessors()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Loc30TransferFound: Boolean;
        ProdOrderLocTransferFound: Boolean;
        Loc30Code: Code[10];
        Loc40Code: Code[10];
        ProdOrderLocationCode: Code[10];
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] For a parallel routing 10 → 20 | 30 → 40 where:
        //   Creating a Transfer Order to Subcontractor for op 40's purchase order
        //   must create TWO separate WIP Transfer Orders:
        //   1. From Prod. Order Line location (our warehouse) → Subc40 location
        //      (path through non-SC op 20; WIP remains at our warehouse)
        //   2. From Subc30 location → Subc40 location
        //      (path through SC op 30; WIP is at Subc30's location)

        // [GIVEN] Complete setup
        Initialize();

        // [GIVEN] Parallel routing with machine centers, work centers and item
        SubcWarehouseLibrary.CreateParallelRoutingItemWithSubcontracting(
            Item, MachineCenter, WorkCenter);

        // [GIVEN] Get subcontractor location codes from work centers
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Loc30Code := Vendor."Subc. Location Code";
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Loc40Code := Vendor."Subc. Location Code";

        // [GIVEN] Create released production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Set the production order line location to Manufacturing "Components at Location"
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        ProdOrderLocationCode := ProductionOrder."Location Code";

        // [GIVEN] Create transfer routes for both WIP paths:
        //   1. ProdOrderLocation → Loc40  (non-SC op 20 path: WIP stays at our warehouse)
        CreateAndUpdateTransferRoute(ProdOrderLocationCode, Loc40Code);

        //   2. Loc30 → Loc40  (SC op 30 path: WIP is at Subc30 location)
        CreateAndUpdateTransferRoute(Loc30Code, Loc40Code);

        // [WHEN] Create a subcontracting purchase order for op 40 (the last SC operation)
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Transfer Orders to Subcontractor 40 — two parallel predecessors → two transfer orders
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Exactly two WIP Transfer Lines exist (one per parallel predecessor path)
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        Assert.RecordCount(TransferLine, 2);

        // [THEN] The two WIP Transfer Lines belong to two different Transfer Headers
        TransferLine.FindFirst();
        TransferLine.SetFilter("Document No.", '<>%1', TransferLine."Document No.");
        Assert.RecordCount(TransferLine, 1);

        // [THEN] Both WIP Transfer Lines reference the production order parent item,
        //        carry the full production order quantity (parallel routing preset),
        //        and each header delivers TO Subcontractor 40's location
        //        while coming FROM one of the two distinct source locations
        TransferLine.SetRange("Document No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        TransferLine.FindSet();
        repeat
            Assert.AreEqual(Item."No.", TransferLine."Item No.",
                'Each WIP Transfer Line must reference the production order parent item.');
            Assert.AreEqual(ProductionOrder.Quantity, TransferLine.Quantity,
                'Each parallel WIP Transfer Line must carry the full production order quantity.');

            TransferHeader.Get(TransferLine."Document No.");
            Assert.AreEqual(Loc40Code, TransferHeader."Transfer-to Code",
                'Both WIP Transfer Orders must go TO Subcontractor 40''s location.');

            if TransferHeader."Transfer-from Code" = ProdOrderLocationCode then
                ProdOrderLocTransferFound := true
            else
                if TransferHeader."Transfer-from Code" = Loc30Code then
                    Loc30TransferFound := true;
        until TransferLine.Next() = 0;

        // [THEN] One WIP transfer originates from our warehouse (non-SC op 20 path)
        Assert.IsTrue(ProdOrderLocTransferFound,
            'A WIP Transfer from the Prod. Order Line location (non-SC op 20 path) to Subc. 40 must exist.');

        // [THEN] One WIP transfer originates from Subcontractor 30''s location (SC op 30 path)
        Assert.IsTrue(Loc30TransferFound,
            'A WIP Transfer from Subcontractor 30''s location (SC op 30 path) to Subc. 40 must exist.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPReturnRequest,StateWIPProposal')]
    procedure DeleteReturnTransferOrderAndRecreateSucceeds()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcLocationCode: Code[10];
        WIPQty: Decimal;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] After creating a WIP return transfer order and deleting it,
        // the user must be able to re-create it from the same purchase order.
        Initialize();

        // [GIVEN] A subcontracting setup with WIP Transfer enabled
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Mock WIP Ledger Entry at subcontractor location (simulates posted WIP transfer)
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SubcLocationCode := Vendor."Subc. Location Code";

        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        WIPQty := LibraryRandom.RandInt(10) + 1;
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", SubcLocationCode,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            '', WIPQty, false);

        // [GIVEN] Create the first return transfer order
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", true);
        Assert.RecordIsNotEmpty(TransferLine);
        TransferLine.FindFirst();

        // [WHEN] The return transfer order is deleted
        TransferHeader.Get(TransferLine."Document No.");
        TransferHeader.Delete(true);

        // [VERIFY] Return transfer line no longer exists
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", true);
        Assert.RecordIsEmpty(TransferLine);

        // [WHEN] The return transfer order is created again
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] A new return transfer line is created successfully
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", true);
        Assert.RecordIsNotEmpty(TransferLine);
        TransferLine.FindFirst();
        Assert.AreEqual(WIPQty, TransferLine.Quantity,
            'Recreated WIP return transfer line must have the same quantity as the WIP Ledger Entry.');

        // [TEARDOWN]
        WIPLedgerEntry.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferCreatedPerProdOrderLineInFamilyProductionOrder()
    var
        Family: Record Family;
        FamilyLine: array[2] of Record "Family Line";
        FamilyItem: array[2] of Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        SubcCalculateSubContracts: Report "Subc. Calculate Subcontracts";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] A Production Order sourced from a Family with 2 family items shares a single
        // subcontracting routing (Transfer WIP Item = true on the subcontracting operation).
        // For every prod order line one purchase line is created via the subcontracting worksheet.
        // When "Create Transfer Order to Subcontractor" is invoked on the purchase order,
        // a separate WIP Transfer Line is created for each prod order line / family item.

        // [GIVEN] Complete setup
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Create subcontracting work centers and machine centers
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create two plain items that will become the family line output items
        LibraryInventory.CreateItem(FamilyItem[1]);
        LibraryInventory.CreateItem(FamilyItem[2]);

        // [GIVEN] Create a Production Family with both items as family lines
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", FamilyItem[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", FamilyItem[2]."No.", 1);

        // [GIVEN] Build a routing with the subcontracting work center and assign it to the family
        CreateFamilyRoutingWithSubcontractingWC(Family, WorkCenter[2]."No.");

        // [GIVEN] Set "Transfer WIP Item" on the subcontracting routing line
        SetTransferWIPItemOnRoutingLine(Family."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Give WC[2]'s vendor a dedicated subcontracting location
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");

        // [GIVEN] Create a released production order for the family
        // → produces 2 Prod. Order Lines (one per family item), each with the family routing
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Family, Family."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Create a transfer route from the prod order line location to the subcontractor location
        CreateAndUpdateTransferRoute(GetManufacturingSetupCompLocation(), Vendor."Subc. Location Code");
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Calculate Subcontracts: produces one requisition line per prod order routing line (= 2)
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubContracts.UseRequestPage(false);
        SubcCalculateSubContracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        // 2 requisition lines expected – one per family item / prod order line
        Assert.RecordCount(RequisitionLine, 2);
        RequisitionLine.FindFirst();

        // [WHEN] Carry Out Action processes all lines in the batch → creates purchase lines
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] 2 purchase lines exist for the production order – one per prod order line / family item
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        Assert.RecordCount(PurchaseLine, 2);

        // [WHEN] Invoke "Create Transfer Order to Subcontractor" on the purchase order
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Exactly 2 WIP Transfer Lines exist – one per family item / prod order line
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        Assert.RecordCount(TransferLine, 2);

        // [THEN] Each WIP Transfer Line references one of the two family items
        TransferLine.FindSet();
        repeat
            Assert.IsTrue(
                (TransferLine."Item No." = FamilyItem[1]."No.") or (TransferLine."Item No." = FamilyItem[2]."No."),
                'Each WIP Transfer Line must reference one of the two family items.');
        until TransferLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferQuantityFollowsChangedPurchaseLineQuantity()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        ChangedQty: Decimal;
        OriginalQty: Decimal;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When the purchase line quantity is changed from the original production order
        // quantity, the WIP transfer line must use the updated purchase line quantity, not the
        // original production order quantity.

        // [GIVEN] Complete setup with Transfer WIP Item = true on the subcontracting routing line
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Set up component transfer infrastructure (needed so TransferRoute can be created)
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh production order with the original quantity
        OriginalQty := LibraryRandom.RandInt(5) + 2;
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", OriginalQty);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [GIVEN] Create Subcontracting Purchase Order (purchase line qty = OriginalQty initially)
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [GIVEN] Change the purchase line quantity to a larger value
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        ChangedQty := OriginalQty + LibraryRandom.RandInt(5) + 1;
        PurchaseLine.Validate(Quantity, ChangedQty);
        PurchaseLine.Modify(true);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Transfer Order to Subcontractor
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] WIP Transfer Line quantity equals the changed purchase line quantity (not the original prod. order qty)
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Subc. Return Order", false);
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();
        Assert.AreEqual(ChangedQty, TransferLine.Quantity,
            'WIP Transfer Line quantity must follow the changed purchase line quantity, not the original production order quantity.');
        Assert.AreNotEqual(OriginalQty, TransferLine.Quantity,
            'WIP Transfer Line quantity must not equal the original production order quantity when the purchase line was changed.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferUsesUnitOfMeasureFromPurchaseLine()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        UnitOfMeasure: Record "Unit of Measure";
        WorkCenter: array[2] of Record "Work Center";
        BoxQtyPerPCS: Decimal;
        ProdOrderQty: Decimal;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When the item has a non-base Purchase Unit of Measure (e.g. BOX = 10 PCS),
        // the WIP Transfer Order line must use the purchase line UOM (BOX) and quantity,
        // not the base UOM (PCS) from the production order line.
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Add a non-base UOM BOX (= 10 PCS) to the item and set it as the Purchase UOM
        BoxQtyPerPCS := 10;
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, BoxQtyPerPCS);
        Item.Validate("Purch. Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Create and refresh production order with a quantity that is a whole multiple of BoxQtyPerPCS
        ProdOrderQty := BoxQtyPerPCS * (LibraryRandom.RandInt(5) + 1);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", ProdOrderQty);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [GIVEN] Create Subcontracting Purchase Order — the purchase line will carry UOM = BOX
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        // [GIVEN] Verify the purchase line received the item's Purch. Unit of Measure (BOX)
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        PurchaseLine.Validate(Quantity, ProdOrderQty / BoxQtyPerPCS);
        PurchaseLine.Modify(true);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Transfer Order to Subcontractor
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] The WIP Transfer Line uses the purchase line UOM (BOX), not the base UOM (PCS)
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Subc. Return Order", false);
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();
        Assert.AreEqual(UnitOfMeasure.Code, TransferLine."Unit of Measure Code",
            'WIP Transfer Line Unit of Measure must match the purchase line UOM (BOX), not the base UOM (PCS).');
        Assert.AreEqual(PurchaseLine.Quantity, TransferLine.Quantity,
            'WIP Transfer Line quantity must equal the purchase line quantity (in BOX).');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferPartiallyPostedTransfersRemainingQuantity()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        AlreadyPostedQty: Decimal;
        FullQty: Decimal;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When part of the WIP has already been posted at the vendor location,
        // creating a Transfer Order to Subcontractor must only transfer the remaining
        // quantity (FullQty - AlreadyPostedQty), not the full purchase line quantity.

        // [GIVEN] Complete setup with Transfer WIP Item = true on the subcontracting routing line
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh production order with a quantity that allows a partial remainder
        FullQty := LibraryRandom.RandIntInRange(6, 10);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", FullQty);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Locate the Prod. Order line and the routing line
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] Create Subcontracting Purchase Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        // [GIVEN] Simulate that a partial quantity has already been transferred and posted at the vendor location
        AlreadyPostedQty := LibraryRandom.RandIntInRange(1, FullQty - 1);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Vendor."Subc. Location Code",
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            WorkCenter[2]."No.", AlreadyPostedQty, false);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Transfer Order to Subcontractor
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Transfer line quantity equals only the remaining quantity
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Subc. Return Order", false);
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();
        Assert.AreEqual(FullQty - AlreadyPostedQty, TransferLine.Quantity,
            'WIP Transfer Line quantity must equal the remaining quantity (full qty minus already posted), not the full quantity.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferAfterQuantityIncreaseTransfersOnlyAdditionalQuantity()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ChangedQty: Decimal;
        OriginalQty: Decimal;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When the purchase line quantity is increased after the original quantity
        // has already been fully posted at the vendor location, creating a Transfer Order must
        // only transfer the additional quantity (ChangedQty - OriginalQty), not the full new quantity.

        // [GIVEN] Complete setup with Transfer WIP Item = true on the subcontracting routing line
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh production order with the original quantity
        OriginalQty := LibraryRandom.RandIntInRange(3, 7);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", OriginalQty);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Locate the Prod. Order line and routing line
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] Create Subcontracting Purchase Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        // [GIVEN] Simulate that the original quantity has been fully posted at the vendor location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Vendor."Subc. Location Code",
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            WorkCenter[2]."No.", OriginalQty, false);

        // [GIVEN] Increase the purchase line quantity beyond the already-posted amount
        ChangedQty := OriginalQty + LibraryRandom.RandIntInRange(1, 5);
        PurchaseLine.Validate(Quantity, ChangedQty);
        PurchaseLine.Modify(true);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Transfer Order to Subcontractor
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Transfer line quantity equals only the additional quantity (ChangedQty - OriginalQty)
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Subc. Return Order", false);
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();
        Assert.AreEqual(ChangedQty - OriginalQty, TransferLine.Quantity,
            'WIP Transfer Line quantity must equal only the additional quantity after the purchase line increase, not the full changed quantity.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferRemainderCreatedWhenOpenLineQuantityReduced()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        FullQty: Decimal;
        ReducedQty: Decimal;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 639382] When an open (unposted) WIP transfer line had its quantity reduced,
        // re-running "Create Transfer Order to Subcontractor" must create the remaining quantity
        // instead of erroring that there is nothing to create.

        // [GIVEN] Complete setup with Transfer WIP Item = true on the subcontracting routing line
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh production order with a quantity that allows a partial remainder
        FullQty := LibraryRandom.RandIntInRange(6, 10);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", FullQty);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Create Subcontracting Purchase Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create the initial WIP Transfer Order with the full quantity
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseHeaderPage.Close();

        // [GIVEN] Reduce the open WIP transfer line quantity (do not post it)
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Subc. Return Order", false);
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();
        ReducedQty := FullQty - LibraryRandom.RandIntInRange(1, FullQty - 1);
        TransferLine.Validate(Quantity, ReducedQty);
        TransferLine.Modify(true);

        // [WHEN] Re-run Create Transfer Order to Subcontractor
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] The remaining quantity is now covered (reduced line + new remainder line = FullQty)
        TransferLine.CalcSums(Quantity);
        Assert.AreEqual(FullQty, TransferLine.Quantity,
            'Re-running Create Transfer Order must create the remaining WIP quantity after the open line was reduced.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure ToggleOffDirectTransferOnWIPTransferOrderDoesNotError()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 638816] Toggling off "Direct Transfer" on a Transfer Order with a WIP item line
        // must not throw "No items are currently in transit" error.

        // [GIVEN] Complete setup with Transfer WIP Item enabled
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh released production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Create subcontracting purchase order and WIP Transfer Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [GIVEN] Transfer Order created with Direct Transfer = Yes and WIP Transfer Line
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");

        // IMPORTANT: this route must be created only after the transfer order is created.
        // The missing route at creation time forces Direct Transfer = true on the header.
        // Creating a matching in-transit route now allows toggling Direct Transfer off.
        CreateAndUpdateTransferRoute(TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code");

        Assert.IsTrue(TransferHeader."Direct Transfer",
            'Transfer Header must have Direct Transfer = true when no in-transit route exists.');

        // [WHEN] Toggle Direct Transfer from Yes to No
        TransferHeader.Validate("Direct Transfer", false);
        TransferHeader.Modify(true);

        // [THEN] No error is thrown - Direct Transfer is successfully turned off
        TransferHeader.Get(TransferLine."Document No.");
        Assert.IsFalse(TransferHeader."Direct Transfer",
            'Transfer Header Direct Transfer must be false after toggling off.');

        // [THEN] WIP Transfer Line still exists with correct quantity
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        TransferLine.FindFirst();
        Assert.IsTrue(TransferLine."Transfer WIP Item",
            'WIP Transfer Line must still have Transfer WIP Item = true after Direct Transfer toggle.');
        Assert.AreEqual(ProductionOrder.Quantity, TransferLine.Quantity,
            'WIP Transfer Line quantity must be preserved after toggling Direct Transfer.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure WIPTransferLineDescriptionNotClearedWhenDirectTransferEnabled()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
        ItemDescription: Text[100];
    begin
        // A WIP Transfer Line created without a Transfer Description on the routing line
        // gets its description from the item. When Direct Transfer is enabled on the Transfer Header
        // afterwards, the description must not be cleared.
        Initialize();

        // [GIVEN] Work centers, machine centers, and item with routing (Transfer Description left empty)
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");

        // [GIVEN] Create and refresh released production order at manufacturing components location
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Transfer route WITH in-transit location so the Transfer Header is created with Direct Transfer = false
        CreateAndUpdateTransferRoute(GetManufacturingSetupCompLocation(), Vendor."Subc. Location Code");

        // [GIVEN] Create subcontracting purchase order and then a WIP Transfer Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [GIVEN] WIP Transfer Line was created with the item description (Transfer Description is empty)
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        TransferLine.FindFirst();

        Item.Get(TransferLine."Item No.");
        ItemDescription := Item.Description;
        Assert.AreNotEqual('', ItemDescription, 'Item description must not be empty for this test to be meaningful.');
        Assert.AreEqual(ItemDescription, TransferLine.Description,
            'WIP Transfer Line description must be set from item description when Transfer Description is empty.');

        // [GIVEN] Transfer Header was created with Direct Transfer = false (in-transit route exists)
        TransferHeader.Get(TransferLine."Document No.");
        Assert.IsFalse(TransferHeader."Direct Transfer",
            'Transfer Header must initially have Direct Transfer = false when a transit route exists.');

        // [WHEN] Enable Direct Transfer on the Transfer Header
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);

        // [THEN] WIP Transfer Line description is preserved and not cleared
        TransferLine.FindFirst();
        Assert.AreEqual(ItemDescription, TransferLine.Description,
            'WIP Transfer Line description must not be cleared when Direct Transfer is enabled on the header.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure NoErrorWhenTogglingOffDirectTransferOnWIPTransferOrder()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 638816] Toggling off Direct Transfer on a Subcontracting Transfer Order
        // with a WIP item line must not throw "No items are currently in transit" error.

        // [GIVEN] Complete setup with subcontracting WIP item
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");

        // [GIVEN] Create and refresh released production order at manufacturing components location
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] NO transfer route exists → Transfer Header created with Direct Transfer = true
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [GIVEN] WIP Transfer Line exists with Direct Transfer = true on the header
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");
        Assert.IsTrue(TransferHeader."Direct Transfer",
            'Transfer Header must initially have Direct Transfer = true when no transit route exists.');

        // [GIVEN] Create a transit route so toggling off Direct Transfer can set In-Transit Code
        CreateAndUpdateTransferRoute(TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code");

        // [WHEN] Toggle off Direct Transfer on the Transfer Header
        TransferHeader.Validate("Direct Transfer", false);
        TransferHeader.Modify(true);

        // [THEN] No error is thrown and Direct Transfer is now false
        TransferHeader.Get(TransferLine."Document No.");
        Assert.IsFalse(TransferHeader."Direct Transfer",
            'Direct Transfer must be toggled off successfully without error.');

        // [THEN] WIP Transfer Line still exists and has Transfer WIP Item = true
        TransferLine.FindFirst();
        Assert.IsTrue(TransferLine."Transfer WIP Item",
            'WIP Transfer Line must retain Transfer WIP Item = true after toggling off Direct Transfer.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure TogglingOffDirectTransferWithoutTransitRouteOnWIPTransferOrder()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 638816] Toggling off Direct Transfer on a Subcontracting Transfer Order with a
        // WIP item line must not throw "No items are currently in transit" even when NO transfer route
        // exists (In-Transit Code stays empty), matching the reproduction reported after the first fix.

        // [GIVEN] Complete setup with subcontracting WIP item
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh released production order at manufacturing components location
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] NO transfer route exists -> Transfer Header created with Direct Transfer = true
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [GIVEN] WIP Transfer Line exists with Direct Transfer = true on the header
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Subc. Return Order", false);
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");
        Assert.IsTrue(TransferHeader."Direct Transfer",
            'Transfer Header must initially have Direct Transfer = true when no transit route exists.');

        // [WHEN] Toggle off Direct Transfer on the Transfer Header while In-Transit Code is empty
        // (no transit route was created, so no In-Transit Code can be inherited)
        TransferHeader.Validate("Direct Transfer", false);
        TransferHeader.Modify(true);

        // [THEN] No "No items are currently in transit" error is thrown and Direct Transfer is now false
        TransferHeader.Get(TransferLine."Document No.");
        Assert.IsFalse(TransferHeader."Direct Transfer",
            'Direct Transfer must be toggled off successfully without error even without a transit route.');

        // [THEN] WIP Transfer Line still exists and retains Transfer WIP Item = true
        TransferLine.FindFirst();
        Assert.IsTrue(TransferLine."Transfer WIP Item",
            'WIP Transfer Line must retain Transfer WIP Item = true after toggling off Direct Transfer.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure WIPTransferCreationFailsWithTestFieldErrorWhenSubcLocationBlank()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [FEATURE] WIP Item Transfer for Subcontracting
        // [SCENARIO 638815] When both the Vendor "Subc. Location Code" and the Purchase Header
        // "Subc. Location Code" are blank, creating a WIP Transfer Order must raise a TestField
        // error on Vendor "Subc. Location Code" instead of the generic "Nothing to create" error.

        // [GIVEN] Complete subcontracting setup with Transfer WIP Item = true on the routing line
        Initialize();

        // [GIVEN] Work centers, machine centers, item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh released production order at the components location
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Create Subcontracting Purchase Order from Prod. Order Routing
        // (vendor already has a Subc. Location Code from CreateAndCalculateNeededWorkAndMachineCenter,
        //  so the purchase header inherits it; we will clear both afterwards)
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Both the Vendor "Subc. Location Code" and the Purchase Header "Subc. Location Code" are cleared
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := '';
        Vendor.Modify();

        PurchaseHeader."Subc. Location Code" := '';
        PurchaseHeader.Modify();

        // [WHEN] Attempting to create a Transfer Order to the Subcontractor
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        asserterror PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] A targeted TestField error on "Subc. Location Code" is raised
        //        (not the generic "Nothing to create" error — that is the current, unfixed behaviour)
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Subcontracting Location Code');
    end;

    [Test]
    procedure ProdOrderRoutingLineTransferWIPItemValidationFailsForMachineCenterType()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Validating Transfer WIP Item = true on a Prod. Order Routing Line with
        // Machine Center type fails, even when the parent Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] Subcontracting work centers with machine centers and an item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] A released production order to create Prod. Order Routing Lines
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1);

        // [GIVEN] A Prod. Order Routing Line with Type = Machine Center
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Machine Center");
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] Transfer WIP Item is set to true on the Machine Center routing line
        // [THEN] An error is raised because the line type must be Work Center
        asserterror ProdOrderRoutingLine.Validate("Transfer WIP Item", true);
        Assert.ExpectedTestFieldError(ProdOrderRoutingLine.FieldCaption(Type), Format(ProdOrderRoutingLine.Type::"Work Center"));
    end;

    [Test]
    procedure ProdOrderRoutingPageTransferWIPItemDisabledForMachineCenterLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        ProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO] Transfer WIP Item field is disabled on Prod. Order Routing page for a Machine
        // Center routing line, even when the parent Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] Subcontracting work centers with machine centers and an item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] A released production order to create Prod. Order Routing Lines
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1);

        // [GIVEN] A Prod. Order Routing Line with Type = Machine Center
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Machine Center");
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] The Prod. Order Routing page is opened for that line
        ProdOrderRtng.OpenEdit();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);

        // [THEN] Transfer WIP Item is not enabled (Machine Center type is not eligible)
        Assert.IsFalse(ProdOrderRtng."Transfer WIP Item".Enabled(), ProdOrderRoutingTransferWIPEnabledErr);
        ProdOrderRtng.Close();
    end;

    [Test]
    [HandlerFunctions('CaptureReturnOrderCard,CaptureReturnOrdersList,StateWIPReturnRequest,StateWIPProposal')]
    procedure MultipleWIPReturnsFromOneProductionOrderOpenExactList()
    var
        PurchaseHeader: Record "Purchase Header";
        UnrelatedPurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [AI test 0.3] [Subcontracting] [WIP Return]
        // [SCENARIO] Two lines of one production order at different locations open exactly their two returns.
        Initialize();
        LibraryVariableStorage.Clear();

        // [GIVEN] An unrelated return for "P1" opens its real card.
        CreateReturnNavigationPurchaseOrder(UnrelatedPurchaseHeader, 1);
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(UnrelatedPurchaseHeader);
        PurchaseOrder.CreateReturnFromSubcontractor.Invoke();
        VerifyReturnNavigation(UnrelatedPurchaseHeader, 1, 'Card');

        // [GIVEN] "P2" contains two lines for the same item on one released production order.
        CreateReturnNavigationPurchaseOrder(PurchaseHeader, 2);
        CreateOutboundNavigationDecoy(PurchaseHeader);

        // [WHEN] Create Return from Subcontractor is invoked for "P2".
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.CreateReturnFromSubcontractor.Invoke();

        // [THEN] Exactly the two linked returns, and no unrelated or outbound orders, appear in a list.
        VerifyReturnNavigation(PurchaseHeader, 2, 'List');
        PurchaseOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureReturnOrderCard,CaptureReturnOrdersList,StateWIPReturnRequest,StateWIPProposal')]
    procedure ReturnFromAnotherOrderIsNotReusedOrOverallocated()
    var
        OtherPurchaseHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReusedReturnNo: Code[20];
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [AI test 0.3] [Subcontracting] [WIP Return]
        // [SCENARIO] Another order's return keeps its source allocation and is never reused.
        Initialize();
        LibraryVariableStorage.Clear();

        // [GIVEN] "P1" has two production lines; "P2" first creates a return for the first line.
        CreateReturnNavigationPurchaseOrder(PurchaseHeader, 2);
        LibraryPurchase.CreatePurchHeader(OtherPurchaseHeader, OtherPurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        PurchaseLine."Document No." := OtherPurchaseHeader."No.";
        PurchaseLine.Insert(true);
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(OtherPurchaseHeader);
        PurchaseOrder.CreateReturnFromSubcontractor.Invoke();
        VerifyReturnNavigation(OtherPurchaseHeader, 1, 'Card');
        TransferLine.SetRange("Subc. Purch. Order No.", OtherPurchaseHeader."No.");
        TransferLine.SetRange("Subc. Return Order", true);
        TransferLine.FindFirst();
        ReusedReturnNo := TransferLine."Document No.";
        CreateOutboundNavigationDecoy(PurchaseHeader);

        // [WHEN] "P1" creates its returns without reusing another purchase order's header.
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.CreateReturnFromSubcontractor.Invoke();

        // [THEN] The other header keeps "P2" as its origin and receives no line linked to "P1".
        TransferHeader.Get(ReusedReturnNo);
        Assert.AreEqual(OtherPurchaseHeader."No.", TransferHeader."Subcontr. Purch. Order No.", 'The reused header must retain its original purchase order.');
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseHeader."No.");
        TransferLine.SetRange("Document No.", ReusedReturnNo);
        Assert.RecordIsEmpty(TransferLine);

        // [THEN] Only the unallocated current-order line creates a return.
        VerifyReturnNavigation(PurchaseHeader, 1, 'Card');
        PurchaseOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureReturnOrderCard,StateWIPReturnRequest,StateWIPProposal')]
    procedure SingleWIPReturnOpensRealTransferOrderCard()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [AI test 0.3] [Subcontracting] [WIP Return]
        // [SCENARIO] A purchase order with one WIP return opens the real transfer order card.
        Initialize();
        LibraryVariableStorage.Clear();

        // [GIVEN] "P" has one production line with WIP at the subcontractor.
        CreateReturnNavigationPurchaseOrder(PurchaseHeader, 1);

        // [WHEN] Create Return from Subcontractor is invoked for "P".
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.CreateReturnFromSubcontractor.Invoke();

        // [THEN] The card shows the exact persisted return document.
        VerifyReturnNavigation(PurchaseHeader, 1, 'Card');
        PurchaseOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
        OpenedTransferOrderNo := CopyStr(TransfOrderPage."No.".Value(), 1, MaxStrLen(OpenedTransferOrderNo));
        TransfOrderPage.OK().Invoke();
    end;

    [PageHandler]
    procedure HandleTransferOrders(var TransfOrderPage: TestPage "Transfer Orders")
    begin
        TransfOrderPage.OK().Invoke();
    end;

    [PageHandler]
    procedure HandleMultipleTransferOrders(var TransferOrders: TestPage "Transfer Orders")
    var
        NoOfTransferOrders: Integer;
    begin
        if TransferOrders.First() then
            repeat
                NoOfTransferOrders += 1;
            until not TransferOrders.Next();
        Assert.AreEqual(2, NoOfTransferOrders, 'The Transfer Orders page must show all transfer orders created for the purchase order.');
        TransferOrders.OK().Invoke();
    end;

    [MessageHandler]
    procedure HandleCreateTransferOrderMsg(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure DoNotConfirmShowCreatedPurchOrderForSubcontracting(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. WIP Trans. Create Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. WIP Trans. Create Test");

        SubSetupLibrary.InitSetupFields();
        // Next lines should be uncommented if the Wizard has been moved to the Base App
        // SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
        // SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. WIP Trans. Create Test");
    end;

    local procedure SetTransferWIPItemOnRoutingLine(RoutingNo: Code[20]; WorkCenterNo: Code[20]; TransferWIPItem: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader.Get(RoutingNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine.Validate("Transfer WIP Item", TransferWIPItem);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure SetProdOrderLocationToCompSetupLocationAndRefresh(var ProductionOrder: Record "Production Order")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ProductionOrder.Validate("Location Code", ManufacturingSetup."Components at Location");
        ProductionOrder.Modify();

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndUpdateTransferRoute(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        Location: Record Location;
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        LibraryWarehouse.CreateAndUpdateTransferRoute(
            TransferRoute, FromLocationCode, ToLocationCode, Location.Code, '', '');
    end;

    local procedure CreateFamilyRoutingWithSubcontractingWC(var Family: Record Family; WorkCenterNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Creates a minimal serial routing containing only the subcontracting work center
        // and assigns it to the family.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);
    end;

    local procedure GetManufacturingSetupCompLocation(): Code[10]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        exit(ManufacturingSetup."Components at Location");
    end;

    local procedure CreateReturnNavigationPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; NumberOfLines: Integer)
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Vendor: Record Vendor;
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WorkCenter: array[2] of Record "Work Center";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        SubcCalculateSubcontracts: Report "Subc. Calculate Subcontracts";
        LineIndex: Integer;
    begin
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 0);
        for LineIndex := 1 to NumberOfLines do begin
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            LibraryManufacturing.CreateProdOrderLine(
                ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', Location.Code, 10);
            CreateAndUpdateTransferRoute(Vendor."Subc. Location Code", Location.Code);
        end;
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(ProdOrderLine, NumberOfLines);
        ProdOrderLine.FindSet();
        repeat
            ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
            ProdOrderRoutingLine.FindFirst();
            SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
                WIPLedgerEntry, Item."No.", Vendor."Subc. Location Code",
                ProductionOrder, ProdOrderLine, ProdOrderRoutingLine, WorkCenter[2]."No.", 10, false);
        until ProdOrderLine.Next() = 0;

        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        WorkCenter[2].SetRecFilter();
        SubcCalculateSubcontracts.SetTableView(WorkCenter[2]);
        SubcCalculateSubcontracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubcontracts.UseRequestPage(false);
        SubcCalculateSubcontracts.RunModal();
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        Assert.RecordCount(RequisitionLine, NumberOfLines);
        RequisitionLine.FindFirst();
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, NumberOfLines);
    end;

    local procedure CreateOutboundNavigationDecoy(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        LibraryInventory.CreateTransferHeader(TransferHeader);
        TransferHeader."Subcontr. Purch. Order No." := PurchaseHeader."No.";
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, PurchaseLine."No.", 1);
        TransferLine."Subc. Purch. Order No." := PurchaseHeader."No.";
        TransferLine.Modify(true);
    end;

    local procedure VerifyReturnNavigation(PurchaseHeader: Record "Purchase Header"; ExpectedCount: Integer; ExpectedPageType: Text)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ExpectedNumbers: List of [Code[20]];
        ActualNumbers: List of [Text];
        DocumentNo: Code[20];
        NumberIndex: Integer;
    begin
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseHeader."No.");
        TransferLine.SetRange("Subc. Return Order", true);
        TransferLine.SetRange("Derived From Line No.", 0);
        Assert.RecordCount(TransferLine, ExpectedCount);
        TransferLine.FindSet();
        repeat
            TransferHeader.Get(TransferLine."Document No.");
            Assert.IsTrue(TransferHeader."Subc. Return Order", 'The linked document must be a real return order.');
            if not ExpectedNumbers.Contains(TransferHeader."No.") then
                ExpectedNumbers.Add(TransferHeader."No.");
        until TransferLine.Next() = 0;
        Assert.AreEqual(ExpectedCount, ExpectedNumbers.Count(), 'Each source location must have a distinct return header.');
        Assert.AreEqual(ExpectedPageType, LibraryVariableStorage.DequeueText(), 'Return navigation must choose the correct page type.');
        Assert.AreEqual(ExpectedCount, LibraryVariableStorage.DequeueInteger(), 'Return navigation must show exactly the linked return orders.');
        for NumberIndex := 1 to ExpectedCount do
            ActualNumbers.Add(LibraryVariableStorage.DequeueText());
        foreach DocumentNo in ExpectedNumbers do
            Assert.IsTrue(ActualNumbers.Contains(DocumentNo), StrSubstNo(ReturnDocumentMissingErr, DocumentNo));
        LibraryVariableStorage.AssertEmpty();
    end;

    [PageHandler]
    procedure CaptureReturnOrderCard(var TransferOrder: TestPage "Transfer Order")
    begin
        LibraryVariableStorage.Enqueue('Card');
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(TransferOrder."No.".Value());
        TransferOrder.OK().Invoke();
    end;

    [PageHandler]
    procedure CaptureReturnOrdersList(var TransferOrders: TestPage "Transfer Orders")
    var
        DocumentNumbers: List of [Text];
        DocumentNo: Text;
    begin
        if TransferOrders.First() then
            repeat
                DocumentNumbers.Add(TransferOrders."No.".Value());
            until not TransferOrders.Next();
        LibraryVariableStorage.Enqueue('List');
        LibraryVariableStorage.Enqueue(DocumentNumbers.Count());
        foreach DocumentNo in DocumentNumbers do
            LibraryVariableStorage.Enqueue(DocumentNo);
        TransferOrders.OK().Invoke();
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        OpenedTransferOrderNo: Code[20];
        StateWIPCancelNextProposal: Boolean;
        StateWIPProposalWasCalled: Boolean;
        AdvancedMode: Text;
        ExpectedPurchaseLine: Record "Purchase Line";
        ExpectedComponent: Record "Prod. Order Component";
        ExpectedFamilyLines: array[2] of Record "Purchase Line";
        ExpectedNewOrders: Integer;
        ExpectedNewLines: Integer;
        FilterNumber: Integer;
        FilterMatches: Boolean;
        ProdOrderRoutingTransferWIPEnabledErr: Label 'Transfer WIP Item should not be enabled for a Machine Center prod. order routing line.';
        ReturnDocumentMissingErr: Label 'The return page must include document %1.', Comment = '%1 = Transfer Order No.';
}