// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 149910 "Subc. WIP Transfer Post Test"
{
    // [FEATURE] Subcontracting Warehouse Combined Scenarios Tests
    Subtype = Test;
    TestType = IntegrationTest;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure LegacyTransferKeepsUnclassifiedCustody()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        RoutingLine: Record "Prod. Order Routing Line";
        Application: Record "Subc. WIP Receipt Appl.";
    begin
        Initialize();
        SubcWarehouseLibrary.CreateLegacyWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10);
        SubcWarehouseLibrary.PostStateWIPSupply(PurchaseHeader);
        Entry.SetRange("Prod. Order No.", ProductionOrder."No.");
        Entry.SetRange("In Transit", false);
        Entry.CalcSums("Quantity (Base)");
        Assert.AreEqual(10, Entry."Quantity (Base)", 'Legacy physical custody must remain native.');
        Entry.SetRange("State Tracked", true);
        Assert.RecordIsEmpty(Entry);
        Entry.SetRange("State Tracked", false);
        Entry.FindFirst();
        Assert.AreEqual('', Entry.ProcessingStateCaption(), 'Legacy custody must not be labelled Unprocessed.');
        RoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", PurchaseLine."Routing Reference No.",
            PurchaseLine."Routing No.", PurchaseLine."Operation No.");
        RoutingLine.CalcFields("WIP Qty. (Base) at Subc.", "Unprocessed WIP Qty. (Base)", "Processed WIP Qty. (Base)");
        Assert.AreEqual(10, RoutingLine."WIP Qty. (Base) at Subc.", 'Legacy routing retains total custody.');
        Assert.AreEqual(0, RoutingLine."Unprocessed WIP Qty. (Base)", 'Legacy quantity is not new-state supply.');
        Assert.AreEqual(0, RoutingLine."Processed WIP Qty. (Base)", 'Legacy quantity is not processed supply.');
        Application.SetRange("Purchase Order No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(Application);
        AssertNoWIPInventory(PurchaseLine."No.");
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure OnwardAndDirectCarrySelectedState()
    var
        ProductionOrder: Record "Production Order";
        FirstHeader: Record "Purchase Header";
        SecondHeader: Record "Purchase Header";
        FirstLine: Record "Purchase Line";
        SecondLine: Record "Purchase Line";
        Receipt: Record "Purch. Rcpt. Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Route: Record "Transfer Route";
        Transit: Record Location;
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
        Entry: Record "Subcontractor WIP Ledger Entry";
        LotIDs: Dictionary of [Integer, Guid];
        ApplicationIDs: Dictionary of [Integer, Guid];
        Direct: Boolean;
        I: Integer;
    begin
        Initialize();
        for I := 1 to 2 do begin
            Direct := I = 2;
            OnwardProposal := false;
            SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, FirstHeader, FirstLine, 10, 1, true);
            SubcWarehouseLibrary.PostStateWIPSupply(FirstHeader);
            SubcWarehouseLibrary.ReceiveStateWIP(FirstHeader, FirstLine, 7, Receipt);
            SubcWarehouseLibrary.CreateNextStateWIPPurchaseOrder(FirstLine, SecondHeader, SecondLine);
            FirstVendor.Get(FirstHeader."Buy-from Vendor No.");
            SecondVendor.Get(SecondHeader."Buy-from Vendor No.");
            Assert.AreNotEqual(FirstVendor."Subc. Location Code", SecondVendor."Subc. Location Code", 'Onward custody needs a second subcontractor location.');
            if Direct then begin
                Route.Init();
                Route."Transfer-from Code" := FirstVendor."Subc. Location Code";
                Route."Transfer-to Code" := SecondVendor."Subc. Location Code";
                Route.Validate("Direct Transfer", true);
                Route.Validate("Direct Transfer Posting", Route."Direct Transfer Posting"::"Direct Transfer");
                Route.Insert(true);
            end else begin
                LibraryWarehouse.CreateInTransitLocation(Transit);
                LibraryWarehouse.CreateAndUpdateTransferRoute(Route, FirstVendor."Subc. Location Code",
                    SecondVendor."Subc. Location Code", Transit.Code, '', '');
            end;
            LotIDs.Clear();
            ApplicationIDs.Clear();
            Entry.Reset();
            Entry.SetProductionOrderFilter(ProductionOrder, false);
            Entry.SetRange("Operation No.", FirstLine."Operation No.");
            Entry.SetRange("In Transit", false);
            Entry.SetFilter("Quantity (Base)", '>0');
            Entry.FindSet();
            repeat
                if not LotIDs.ContainsKey(Entry."WIP State".AsInteger()) then begin
                    LotIDs.Add(Entry."WIP State".AsInteger(), Entry."Supply Lot ID");
                    ApplicationIDs.Add(Entry."WIP State".AsInteger(), Entry."Receipt Application ID");
                end;
            until Entry.Next() = 0;
            OnwardProposal := true;
            SecondHeader.SetRecFilter();
            Report.Run(Report::"Subc. Create Transf. Order", true, false, SecondHeader);
            TransferLine.Reset();
            TransferLine.SetRange("Subc. Purch. Order No.", SecondHeader."No.");
            TransferLine.SetRange("Derived From Line No.", 0);
            Assert.RecordCount(TransferLine, 2);
            TransferLine.FindFirst();
            TransferHeader.Get(TransferLine."Document No.");
            Assert.AreEqual(Direct, TransferHeader."Direct Transfer", 'The native selected transport mode must be retained.');
            if Direct then
                Codeunit.Run(Codeunit::"TransferOrder-Post Transfer", TransferHeader)
            else begin
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
                SubcWarehouseLibrary.AssertStateWIP(FirstLine, 8, 2, 6, 0);
                SubcWarehouseLibrary.AssertStateWIP(SecondLine, 0, 0, 0, 2);
                LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
            end;
            SubcWarehouseLibrary.AssertStateWIP(FirstLine, 8, 2, 6, 0);
            SubcWarehouseLibrary.AssertStateWIP(SecondLine, 2, 1, 1, 0);
            Entry.Reset();
            Entry.SetProductionOrderFilter(ProductionOrder, false);
            Entry.SetRange("Operation No.", SecondLine."Operation No.");
            Entry.SetRange("Location Code", SecondVendor."Subc. Location Code");
            Entry.SetRange("In Transit", false);
            Entry.FindSet();
            repeat
                Assert.AreEqual(LotIDs.Get(Entry."WIP State".AsInteger()), Entry."Supply Lot ID", 'Physical movement must preserve the original supply lot.');
                Assert.AreEqual(ApplicationIDs.Get(Entry."WIP State".AsInteger()), Entry."Receipt Application ID", 'Processed provenance must survive onward movement.');
            until Entry.Next() = 0;
            AssertNoWIPInventory(FirstLine."No.");
        end;
        OnwardProposal := false;
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure InitialTransferCreatesUnprocessedCustody()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        Initialize();
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true);
        SubcWarehouseLibrary.CreateStateWIPSupply(PurchaseHeader, TransferHeader, TransferLine);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 0, 0, 0, 0);
        Assert.AreEqual(0, TransferLine."Quantity (Base)", 'WIP must retain native inventory suppression.');
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 0, 0, 0, 10);
        AssertNoWIPInventory(PurchaseLine."No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 10, 0, 0);
        AssertNoWIPInventory(PurchaseLine."No.");
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure ProcessedShipmentRelievesOnlySourceState()
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
        CreateProcessedStateFixture(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        SubcWarehouseLibrary.FindStateWIPEntry(Entry, PurchaseLine, Entry."WIP State"::Processed);
        SubcWarehouseLibrary.CreateStateWIPClaim(PurchaseLine, Entry, 2, TransferHeader, TransferLine);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
        Assert.AreEqual(2, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Creation must allocate two.');
        Assert.AreEqual(5, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Only five processed units remain unallocated.');
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 8, 3, 5, 2);
        Assert.AreEqual(0, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Shipped quantity is no longer an open claim.');
        Assert.AreEqual(5, Availability.Available(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Do not subtract shipped quantity twice.');
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 8, 3, 5, 0);
        Entry.Reset();
        Entry.SetRange("Supply Lot ID", TransferLine."Subc. Supply Lot ID");
        Entry.SetRange("Document Type", Entry."Document Type"::"Transfer Order");
        Assert.RecordIsNotEmpty(Entry);
        Entry.FindSet();
        repeat
            Assert.AreEqual(Entry."WIP State"::Processed, Entry."WIP State", 'Physical movement must carry the selected processing state.');
        until Entry.Next() = 0;
        AssertNoWIPInventory(PurchaseLine."No.");
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure RoutingBalancesRetainTotalAndTransit()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        RoutingLine: Record "Prod. Order Routing Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        Initialize();
        CreateProcessedStateFixture(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        RoutingLine.Get(
            ProductionOrder.Status, ProductionOrder."No.", PurchaseLine."Routing Reference No.",
            PurchaseLine."Routing No.", PurchaseLine."Operation No.");
        RoutingLine.CalcFields("WIP Qty. (Base) at Subc.", "WIP Qty. (Base) in Transit");
        Assert.AreEqual(10, RoutingLine."WIP Qty. (Base) at Subc.", 'Existing routing custody combines both states.');
        Assert.AreEqual(0, RoutingLine."WIP Qty. (Base) in Transit", 'Receipt processing does not create physical transit.');
        SubcWarehouseLibrary.FindStateWIPEntry(Entry, PurchaseLine, Entry."WIP State"::Processed);
        SubcWarehouseLibrary.CreateStateWIPClaim(PurchaseLine, Entry, 2, TransferHeader, TransferLine);
        RoutingLine.CalcFields("WIP Qty. (Base) at Subc.", "WIP Qty. (Base) in Transit");
        Assert.AreEqual(10, RoutingLine."WIP Qty. (Base) at Subc.", 'An unshipped claim does not change posted custody.');
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        RoutingLine.CalcFields("WIP Qty. (Base) at Subc.", "WIP Qty. (Base) in Transit");
        Assert.AreEqual(8, RoutingLine."WIP Qty. (Base) at Subc.", 'Physical shipment relieves custody exactly once.');
        Assert.AreEqual(2, RoutingLine."WIP Qty. (Base) in Transit", 'Physical shipment increases only the transit total.');
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 8, 3, 5, 2);
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,StateWIPLifecycleConfirm,HandleTransferOrder,StateWIPFinishDialog')]
    procedure FinishBalancesEachStateAndDimension()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        LineageID: Guid;
    begin
        Initialize();
        CreateProcessedStateFixture(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        LineageID := ProductionOrder."Subc. WIP Lineage ID";
        SubcWarehouseLibrary.CompleteStateWIPProduction(ProductionOrder);
        StateWIPCleanup := true;
        ProductionOrder.SetRecFilter();
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProductionOrder);
        FindFinishedStateOrder(ProductionOrder, PurchaseLine, LineageID);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 0, 0, 0, 0);
        Entry.SetRange("Lineage ID", LineageID);
        Entry.SetRange("Document Type", Entry."Document Type"::"Adjustment (Finish Prod Order)");
        Entry.SetRange("WIP State", Entry."WIP State"::Unprocessed);
        Entry.CalcSums("Quantity (Base)");
        Assert.AreEqual(-3, Entry."Quantity (Base)", 'Cleanup must balance unprocessed state independently.');
        Entry.SetRange("WIP State", Entry."WIP State"::Processed);
        Entry.CalcSums("Quantity (Base)");
        Assert.AreEqual(-7, Entry."Quantity (Base)", 'Cleanup must balance processed state independently.');
        Entry.SetRange("Document Type");
        Entry.SetRange("WIP State");
        Entry.SetRange("Purchase Receipt No.", ReceiptLine."Document No.");
        Entry.SetRange("Purchase Receipt Line No.", ReceiptLine."Line No.");
        Assert.RecordCount(Entry, 2);
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,StateWIPLifecycleConfirm,HandleTransferOrder,StateWIPFinishDialog')]
    procedure ProgrammaticFinishAndDialogOptOut()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        LineageID: Guid;
    begin
        Initialize();
        CreateProcessedStateFixture(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        LineageID := ProductionOrder."Subc. WIP Lineage ID";
        SubcWarehouseLibrary.CompleteStateWIPProduction(ProductionOrder);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);
        FindFinishedStateOrder(ProductionOrder, PurchaseLine, LineageID);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 0, 0, 0, 0);
        Entry.SetRange("Lineage ID", LineageID);
        Entry.SetRange("Document Type", Entry."Document Type"::"Adjustment (Finish Prod Order)");
        Assert.RecordCount(Entry, 2);

        CreateProcessedStateFixture(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        LineageID := ProductionOrder."Subc. WIP Lineage ID";
        SubcWarehouseLibrary.CompleteStateWIPProduction(ProductionOrder);
        StateWIPCleanup := false;
        ProductionOrder.SetRecFilter();
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProductionOrder);
        FindFinishedStateOrder(ProductionOrder, PurchaseLine, LineageID);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
        Entry.SetRange("Lineage ID", LineageID);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,StateWIPLifecycleConfirm,HandleTransferOrder')]
    procedure ReopenAndHistoricalInverseKeepState()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        StatusManagement: Codeunit "Prod. Order Status Management";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        LineageID: Guid;
        FinishedNo: Code[20];
        EntryCount: Integer;
    begin
        Initialize();
        CreateProcessedStateFixture(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        LineageID := ProductionOrder."Subc. WIP Lineage ID";
        SubcWarehouseLibrary.CompleteStateWIPProduction(ProductionOrder);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);
        FindFinishedStateOrder(ProductionOrder, PurchaseLine, LineageID);
        FinishedNo := ProductionOrder."No.";
        Entry.SetRange("Lineage ID", LineageID);
        EntryCount := Entry.Count();
        StatusManagement.ReopenFinishedProdOrder(ProductionOrder);
        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Subc. WIP Lineage ID", LineageID);
        ProductionOrder.FindFirst();
        Assert.AreEqual(ProductionOrder."Subc. WIP Cohort"::StateV1, ProductionOrder."Subc. WIP Cohort", 'Reopening is a continuation, not another enrollment.');
        Assert.AreEqual(LineageID, CohortMgt.GetLineage(ProductionOrder.Status::Finished, FinishedNo), 'The finished source alias must remain available.');
        Assert.AreEqual(EntryCount, Entry.Count(), 'Reopening must not replay cleanup or create a backfill.');
        PurchaseLine."Prod. Order No." := ProductionOrder."No.";
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 0, 0, 0, 0);
        ReceiptLine.SetRecFilter();
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", ReceiptLine);
        Assert.ExpectedError('moved or allocated');
        Assert.AreEqual(EntryCount, Entry.Count(), 'A blocked historical inverse must not resurrect unavailable processed WIP.');
    end;

    local procedure FindFinishedStateOrder(var ProductionOrder: Record "Production Order"; var PurchaseLine: Record "Purchase Line"; LineageID: Guid)
    begin
        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Finished);
        ProductionOrder.SetRange("Subc. WIP Lineage ID", LineageID);
        ProductionOrder.FindFirst();
        Assert.AreEqual(ProductionOrder."Subc. WIP Cohort"::StateV1, ProductionOrder."Subc. WIP Cohort", 'Finishing retains the cohort.');
        PurchaseLine."Prod. Order No." := ProductionOrder."No.";
    end;

    [ModalPageHandler]
    procedure StateWIPFinishDialog(var Dialog: TestPage "Change Status on Prod. Order")
    begin
        Dialog.FirmPlannedStatus.SetValue('Finished');
        Dialog."WIP Quantity Clean Up".SetValue(StateWIPCleanup);
        Dialog.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure StateWIPLifecycleConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not Question.ToLower().Contains('view') and not Question.ToLower().Contains('open the');
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,StateWIPUndoConfirm,HandleTransferOrder')]
    procedure UndoShipmentRestoresOriginalState()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        ShipmentLine: Record "Transfer Shipment Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Availability: Codeunit "Subc. WIP Availability";
    begin
        Initialize();
        CreateProcessedStateFixture(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        SubcWarehouseLibrary.FindStateWIPEntry(Entry, PurchaseLine, Entry."WIP State"::Processed);
        SubcWarehouseLibrary.CreateStateWIPClaim(PurchaseLine, Entry, 2, TransferHeader, TransferLine);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 8, 3, 5, 2);
        ShipmentLine.SetRange("Transfer Order No.", TransferHeader."No.");
        ShipmentLine.SetRange("Trans. Order Line No.", TransferLine."Line No.");
        ShipmentLine.FindFirst();
        ShipmentLine.SetRecFilter();
        Codeunit.Run(Codeunit::"Undo Transfer Shipment", ShipmentLine);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
        Assert.AreEqual(2, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Undo must restore the unshipped open claim.');
        asserterror Codeunit.Run(Codeunit::"Undo Transfer Shipment", ShipmentLine);
        Assert.ExpectedError('already');
        AssertNoWIPInventory(PurchaseLine."No.");
    end;

    local procedure CreateProcessedStateFixture(var ProductionOrder: Record "Production Order"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ReceiptLine: Record "Purch. Rcpt. Line")
    begin
        SubcWarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, true);
        SubcWarehouseLibrary.PostStateWIPSupply(PurchaseHeader);
        SubcWarehouseLibrary.ReceiveStateWIP(PurchaseHeader, PurchaseLine, 7, ReceiptLine);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
    end;

    [Test]
    [HandlerFunctions('StateWIPRequest,StateWIPProposal,StateWIPMessage,DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPPreviewSelection,StateWIPPostingPreview')]
    procedure TransferPreviewRetainsStateAndSource()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        TempEntry: Record "Subcontractor WIP Ledger Entry" temporary;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        GLSetup: Record "General Ledger Setup";
        Availability: Codeunit "Subc. WIP Availability";
        PreviewHandler: Codeunit "Subc. Pst. Prev. Event Handler";
        TransferPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        EntryCount: Integer;
    begin
        Initialize();
        CreateProcessedStateFixture(ProductionOrder, PurchaseHeader, PurchaseLine, ReceiptLine);
        SubcWarehouseLibrary.FindStateWIPEntry(Entry, PurchaseLine, Entry."WIP State"::Processed);
        SubcWarehouseLibrary.CreateStateWIPClaim(PurchaseLine, Entry, 2, TransferHeader, TransferLine);
        EntryCount := Entry.Count();
        GLSetup.Get();
        GLSetup."Posting Preview Type" := GLSetup."Posting Preview Type"::Standard;
        GLSetup.Modify();
        TransferPostYesNo.Preview(TransferHeader);
        PreviewHandler.GetTempSubcontractorWIPLedgerEntry(TempEntry);
        TempEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(TempEntry, 2);
        TempEntry.FindSet();
        repeat
            Assert.AreEqual(TempEntry."WIP State"::Processed, TempEntry."WIP State", 'Preview carries the actual selected processing state.');
            Assert.AreEqual(Entry."Supply Lot ID", TempEntry."Supply Lot ID", 'Preview carries the actual original source lot.');
            Assert.AreEqual('***', TempEntry."Document No.", 'Preview document identity must stay masked.');
        until TempEntry.Next() = 0;
        Assert.AreEqual(EntryCount, Entry.Count(), 'Preview must not persist movement entries.');
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(0, TransferLine."Quantity Shipped", 'Preview must roll back the native transfer shipment.');
        Assert.AreEqual(2, Availability.OpenClaim(Entry."Source Position No.", Entry."WIP State", Entry."Supply Lot ID", '', 0), 'Preview must preserve the open claim.');
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 10, 3, 7, 0);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        SubcWarehouseLibrary.AssertStateWIP(PurchaseLine, 8, 3, 5, 2);
        AssertNoWIPInventory(PurchaseLine."No.");
    end;

    [StrMenuHandler]
    procedure StateWIPPreviewSelection(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Assert.IsTrue(Options.Contains('Ship'), 'Transfer preview must offer the native shipment operation.');
        Choice := 1;
    end;

    [PageHandler]
    procedure StateWIPPostingPreview(var Preview: TestPage "G/L Posting Preview")
    begin
        Preview.Close();
    end;

    local procedure AssertNoWIPInventory(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetFilter(
            "Document Type", '%1|%2|%3', ItemLedgerEntry."Document Type"::"Transfer Shipment",
            ItemLedgerEntry."Document Type"::"Transfer Receipt", ItemLedgerEntry."Document Type"::"Direct Transfer");
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetFilter(
            "Document Type", '%1|%2|%3', ValueEntry."Document Type"::"Transfer Shipment",
            ValueEntry."Document Type"::"Transfer Receipt", ValueEntry."Document Type"::"Direct Transfer");
        Assert.RecordIsEmpty(ItemLedgerEntry);
        Assert.RecordIsEmpty(ValueEntry);
    end;

    [RequestPageHandler]
    procedure StateWIPRequest(var Request: TestRequestPage "Subc. Create Transf. Order")
    begin
        Request.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure StateWIPProposal(var Proposal: TestPage "Subc. Transfer Proposal")
    var
        Count: Integer;
    begin
        if OnwardProposal then begin
            Proposal.First();
            repeat
                Count += 1;
                Proposal."Quantity to Transfer".SetValue(1);
            until not Proposal.Next();
            Assert.AreEqual(2, Count, 'Onward proposal must expose separate unprocessed and processed sources.');
        end;
        Proposal.OK().Invoke();
    end;

    [MessageHandler]
    procedure StateWIPMessage(Message: Text[1024])
    begin
        if OnwardProposal then begin
            Assert.AreEqual('1 transfer order(s) with 2 line(s) were created.', Message, 'Both selected state lines must be created.');
            exit;
        end;
        Assert.IsTrue(
            (Message = '1 transfer order(s) with 1 line(s) were created.') or
            Message.StartsWith('No available quantity was found for: '),
            'Unexpected state WIP creation message: ' + Message);
    end;

    [ConfirmHandler]
    procedure StateWIPUndoConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := Question.Contains('undo');
    end;

    [Test]
    procedure CreateTransferOrderWithWIPItemFlag_CreatesSimpleWIPTransferLine()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Create Transfer Order with WIP Item and validate Transfer Line fields
        Initialize();
        // [GIVEN] Valid From and To Locations, In-Transit Location, and WIP Item details
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        LibraryInventory.CreateItem(Item);
        Quantity := 5;

        // [WHEN] Create Transfer Order with WIP Item
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        // [THEN] Assert TransferLine has WIP flag and every base quantity field is 0 as expected for WIP Item
        Assert.AreEqual(TransferLine."Transfer-from Code", FromLocation.Code, 'Transfer Line should have correct From Location');
        Assert.AreEqual(TransferLine."Transfer-to Code", ToLocation.Code, 'Transfer Line should have correct To Location');
        Assert.IsTrue(TransferLine."Transfer WIP Item", 'Transfer Line should have WIP Item flag set');
        Assert.AreEqual(TransferLine.Quantity, Quantity, 'Transfer Line should have correct quantity');
        Assert.AreEqual(TransferLine."Qty. to Ship", Quantity, 'Transfer Line should have correct Qty. to Ship');
        Assert.AreEqual(TransferLine."Qty. to receive", 0, 'Transfer Line should have correct Qty. to receive');
        Assert.AreEqual(TransferLine."Outstanding Quantity", Quantity, 'Transfer Line should have correct Outstanding Quantity');

        Assert.AreEqual(TransferLine."Qty. per Unit of Measure", 0, 'Transfer Line should have 0 in Qty. per Unit of Measure for WIP Item');
        Assert.AreEqual(TransferLine."Quantity (Base)", 0, 'Transfer Line should have 0 in Quantity (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", 0, 'Transfer Line should have 0 in Qty. to Ship (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Transfer Line should have 0 in Qty. to Receive (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", 0, 'Transfer Line should have 0 in Outstanding Qty. (Base) for WIP Item');
    end;

    [Test]
    procedure ToggleWIPFlag_UpdatesBaseQuantitiesCorrectly()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        QtyPerUOM: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO] Set WIP-Flag, validate base quantities, then unset WIP-Flag and validate quantities again, and repeat to ensure consistent behavior
        Initialize();
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 7;

        // [GIVEN] Transfer order with WIP flag
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        // [WHEN] Remove WIP flag from Transfer Line
        TransferLine.Validate("Transfer WIP Item", false);
        TransferLine.Modify();

        // [THEN] Base quantity fields should be calculated based on Quantity and Qty. per Unit of Measure, and WIP flag should be false
        QtyPerUOM := 1; // Default value if not set
        Assert.IsFalse(TransferLine."Transfer WIP Item", 'Transfer Line should not have WIP Item flag set');
        Assert.AreEqual(TransferLine."Quantity (Base)", Quantity, 'Quantity (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", Quantity, 'Qty. to Ship (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Qty. to Receive (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", Quantity, 'Outstanding Qty. (Base) should match Quantity');

        // [WHEN] Set WIP flag back on Transfer Line
        TransferLine.Validate("Transfer WIP Item", true);
        TransferLine.Modify();

        // [THEN] Base quantity fields should be reset to 0 and WIP flag should be true again
        Assert.IsTrue(TransferLine."Transfer WIP Item", 'Transfer Line should have WIP Item flag set again');
        Assert.AreEqual(TransferLine."Qty. per Unit of Measure", 0, 'Qty. per Unit of Measure should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Quantity (Base)", 0, 'Quantity (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", 0, 'Qty. to Ship (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Qty. to Receive (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", 0, 'Outstanding Qty. (Base) should be 0 for WIP again');
    end;

    [Test]
    procedure PostWIPTransferOrder_ShipPartialReceiveFullReceive()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromReceiveBin, FromPutAwayBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
    begin
        // [SCENARIO] Post WIP Transfer Order: first shipment only, then partial receipt, then remaining receipt
        Initialize();

        // [GIVEN] Transfer Order with WIP Item and bin handling
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(FromLocation, FromReceiveBin, FromPutAwayBin);
        FromLocation."Require Pick" := false;
        FromLocation."Require Put-away" := false;
        FromLocation."Require Receive" := false;
        FromLocation."Require Shipment" := false;
        FromLocation.Modify();

        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(ToLocation, ToReceiveBin, ToPutAwayBin);
        ToLocation."Require Pick" := false;
        ToLocation."Require Put-away" := false;
        ToLocation."Require Receive" := false;
        ToLocation."Require Shipment" := false;
        ToLocation.Modify();
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        LibraryInventory.CreateItem(Item);
        CreateInventory(Item, FromLocation, FromPutAwayBin, Quantity, '');

        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);
        TransferLine.Validate("Transfer-from Bin Code", FromPutAwayBin.Code);
        TransferLine.Validate("Transfer-to Bin Code", ToReceiveBin.Code);
        TransferLine.Modify();

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Post shipment only
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [THEN] Transfer Shipment is created and Qty. in Transit equals full quantity. No ItemLedgerEntries should be created since it's a WIP transfer
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Post partial receipt
        TransferLine.Validate("Qty. to receive", PartialQty);
        TransferLine.Modify();
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Partial Transfer Receipt is created, Quantity Received equals partial and remaining is still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should still be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receive Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receive Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after receive of WIP transfer');

        // [WHEN] Post remaining receipt
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after receive of WIP transfer');
    end;

    [Test]
    [HandlerFunctions('BinMessageHandler,DeleteWhseReceiptConfimHandler')]
    procedure PostWIPTransferOrder_FullWhseHandling_ShipPartialReceiveFullReceive()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromStorageBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
    begin
        // [SCENARIO] Post WIP Transfer Order using warehouse documents (Require Shipment, Receive, Pick, Put-Away all true):
        // ship via warehouse shipment, partial receive and full receive via warehouse receipts.
        // No Warehouse Picks or Put-Aways must be created despite Require Pick and Require Put-Away being enabled.
        Initialize();

        // [GIVEN] From location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(FromLocation, 5);
        LibraryWarehouse.CreateBin(FromStorageBin, FromLocation.Code, 'STORAGE', 'BULK', '');
        FromLocation.Validate("Default Bin Code", FromStorageBin.Code);
        FromLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);

        // [GIVEN] To location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(ToLocation, 5);
        LibraryWarehouse.CreateBin(ToReceiveBin, ToLocation.Code, 'RECEIVE', 'BULK', '');
        LibraryWarehouse.CreateBin(ToPutAwayBin, ToLocation.Code, 'PUTAWAY', 'BULK', '');
        ToLocation.Validate("Receipt Bin Code", ToReceiveBin.Code);
        ToLocation.Validate("Default Bin Code", ToPutAwayBin.Code);
        ToLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ToLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        LibraryInventory.CreateItem(Item);
        CreateInventory(Item, FromLocation, FromStorageBin, Quantity, '');

        // [GIVEN] Transfer Order with WIP Item and bin assignment
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Release Transfer Order and create Warehouse Shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] No Warehouse Pick is created despite Require Pick = true (WIP transfer bypasses pick creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Location Code", FromLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Post Warehouse Shipment
        WarehouseShipmentHeader.SetRange("Location Code", FromLocation.Code);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer Shipment is created with WIP behavior: base quantities are 0, no item/warehouse ledger entries created
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Create Warehouse Receipt for To Location and post partial receive
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Qty. to Receive", PartialQty);
        WarehouseReceiptLine.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Partial Transfer Receipt created with WIP behavior and remaining quantity still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 for WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after partial receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after partial receive of WIP transfer');

        // [THEN] No Warehouse Put-Away created despite Require Put-Away = true (WIP transfer bypasses put-away creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Create second Warehouse Receipt for remaining quantity and post
        WarehouseReceiptHeader.Find('=');
        WarehouseReceiptHeader.Delete(true);
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after full receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after full receive of WIP transfer');

        // [THEN] Still no Warehouse Put-Away after final receive
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    [Test]
    [HandlerFunctions('BinMessageHandler,DeleteWhseReceiptConfimHandler')]
    procedure PostWIPTransferOrder_FullWhseHandling_SerialTrackedItem()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromStorageBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        NewLotNo: Code[50];
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
        TransferOrder: TestPage "Transfer Order";
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
        WarehouseShipment: TestPage "Warehouse Shipment";
    begin
        // [SCENARIO] Post WIP Transfer Order via full-WMS warehouse documents using a serial-tracked item.
        // The item tracking actions on the Transfer Order Subform and the Warehouse Receipt Subform
        // must be Enabled = false for WIP items. Posting succeeds without creating any item or warehouse
        // ledger/tracking entries, and no Warehouse Picks or Put-Aways are generated.
        Initialize();

        // [GIVEN] From location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(FromLocation, 5);
        LibraryWarehouse.CreateBin(FromStorageBin, FromLocation.Code, 'STORAGE', 'BULK', '');
        FromLocation.Validate("Default Bin Code", FromStorageBin.Code);
        FromLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);

        // [GIVEN] To location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(ToLocation, 5);
        LibraryWarehouse.CreateBin(ToReceiveBin, ToLocation.Code, 'RECEIVE', 'BULK', '');
        LibraryWarehouse.CreateBin(ToPutAwayBin, ToLocation.Code, 'PUTAWAY', 'BULK', '');
        ToLocation.Validate("Receipt Bin Code", ToReceiveBin.Code);
        ToLocation.Validate("Default Bin Code", ToPutAwayBin.Code);
        ToLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ToLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        // [GIVEN] Create lot-tracked item (Lot Warehouse Tracking enabled; Lot Specific = false so that
        // a plain item-journal inventory adjustment can be posted without assigning lot numbers,
        // while warehouse activities still enforce lot numbers — which are skipped for WIP transfers)
        LibraryItemTracking.CreateLotItem(Item);
        NewLotNo := LibraryUtility.GetNextNoFromNoSeries(LibraryUtility.GetGlobalNoSeriesCode(), WorkDate());

        // [GIVEN] Create inventory at From Location
        CreateInventory(Item, FromLocation, FromStorageBin, Quantity, NewLotNo);

        // [GIVEN] Transfer Order with WIP Item flag
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        Commit();
        TransferOrder.OpenEdit();
        TransferOrder.GoToRecord(TransferHeader);
        Assert.IsFalse(TransferOrder.TransferLines.Shipment.Enabled(), 'Shipment action should be disabled on Transfer Order Subform for WIP item');
        Assert.IsFalse(TransferOrder.TransferLines.Receipt.Enabled(), 'Receipt action should be disabled on Transfer Order Subform for WIP item');
        Assert.IsFalse(TransferOrder.TransferLines.Reserve.Enabled(), 'Reserve action should be disabled on Transfer Order Subform for WIP item');
        TransferOrder.Close();

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Release Transfer Order and create Warehouse Shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] No Warehouse Pick is created despite Require Pick = true (WIP transfer bypasses pick creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Location Code", FromLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
        Commit();

        // [THEN] Item Tracking Lines action on Warehouse Shipment Subform should be Enabled = false for WIP item (enforced by page extension Subc. Whse Rcpt Subform Ext.)
        WarehouseShipmentHeader.SetRange("Location Code", FromLocation.Code);
        WarehouseShipmentHeader.FindFirst();
        WarehouseShipment.OpenEdit();
        WarehouseShipment.GoToRecord(WarehouseShipmentHeader);
        Assert.IsFalse(WarehouseShipment.WhseShptLines.ItemTrackingLines.Enabled(), 'Item Tracking Lines action should be disabled on Warehouse Shipment Subform for WIP item');
        WarehouseShipment.Close();

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer Shipment created with WIP behavior: base quantities are 0, no item/warehouse ledger entries
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Create Warehouse Receipt for To Location
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        // [THEN] Verify via TestPage that ItemTrackingLines action is disabled on Warehouse Receipt Subform
        WarehouseReceiptPage.OpenView();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        Assert.IsFalse(WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Enabled(), 'Item Tracking Lines action should be disabled on Warehouse Receipt Subform for WIP item');
        WarehouseReceiptPage.Close();

        // [WHEN] Post partial receipt
        WarehouseReceiptLine.Validate("Qty. to Receive", PartialQty);
        WarehouseReceiptLine.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Partial Transfer Receipt created with WIP behavior and remaining qty still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 for WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after partial receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after partial receive of WIP transfer');

        // [THEN] No Warehouse Put-Away created despite Require Put-Away = true
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Delete consumed receipt and create second Warehouse Receipt for remaining quantity
        WarehouseReceiptHeader.Find('=');
        WarehouseReceiptHeader.Delete(true);
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after full receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after full receive of WIP transfer');

        // [THEN] No Warehouse Put-Away after final receipt
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    [Test]
    procedure CalcRegenPlanForPlanWksh_WIPTransferLine_NotConsideredAsDemandOrSupply()
    var
        Customer: Record Customer;
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Planning Worksheet (Regenerative Plan) does not consider WIP Transfer Lines as demand or supply
        // because all base quantity fields ("Quantity (Base)", "Outstanding Qty. (Base)", etc.) are 0.
        // The planning uses SKU-level configuration with Replenishment System = Transfer.
        Initialize();
        Quantity := 10;

        // [GIVEN] Locations with Transfer Route and In-Transit Location
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);

        // [GIVEN] An item with a SKU at ToLocation configured for Transfer replenishment from FromLocation
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A WIP Transfer Order for the item (base quantities = 0)
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, ToLocation.Code, Item."No.", '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Validate("Transfer-from Code", FromLocation.Code);
        StockkeepingUnit.Modify(true);

        // [GIVEN] Verify the WIP Transfer Line has base quantities = 0 (precondition)
        Assert.AreEqual(0, TransferLine."Quantity (Base)", 'Precondition: WIP Transfer Line Quantity (Base) must be 0');
        Assert.AreEqual(0, TransferLine."Outstanding Qty. (Base)", 'Precondition: WIP Transfer Line Outstanding Qty. (Base) must be 0');
        Assert.AreEqual(0, TransferLine."Qty. per Unit of Measure", 'Precondition: WIP Transfer Line Qty. per Unit of Measure must be 0');

        // [GIVEN] A Sales Order creating real demand for the item at the To Location
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, Customer."No.", Item."No.", Quantity, ToLocation.Code, WorkDate());

        // [WHEN] Run Regenerative Plan for Planning Worksheet
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));
        Commit();

        // [THEN] Requisition Lines are created for the Sales Order demand (Replenishment System = Transfer via SKU)
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::Transfer);
        Assert.IsTrue(RequisitionLine.FindFirst(), 'Planning should create a Requisition Line for the Sales Order demand');

        // [THEN] The planned transfer has the full base quantity (from Sales demand), proving the WIP Transfer Line was NOT used as supply
        Assert.AreEqual(RequisitionLine.Quantity, Quantity, 'Requisition Line Quantity should equal Sales Order quantity');
        Assert.AreEqual(Quantity, RequisitionLine."Quantity (Base)", 'Requisition Line Quantity (Base) should equal Sales demand quantity, proving WIP Transfer was not counted as supply');

        // [WHEN] Delete the Planning Worksheet lines, remove the WIP flag from the transfer line and run planning again
        RequisitionLine.Reset();
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.DeleteAll(true);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        TransferLine.Validate("Transfer WIP Item", false);
        TransferLine.Modify(true);
        Commit();

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));
        Commit();

        // [THEN] The transfer line is now considered by planning because it carries non-zero base quantities. No new Requisition Line should be created since the existing transfer can cover the demand.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,StateWIPRequest,StateWIPProposal')]
    procedure PostWIPTransfer_WhenTransferLineHasAlternativeUOM_WIPLedgerEntryHasBaseUOM()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] WIP Ledger Entries use the item's base unit of measure even when the
        // subcontracting purchase order line carries a different (alternative) unit of measure.
        Initialize();

        // [GIVEN] Work centers, machine centers, item with subcontracting routing and Transfer WIP Item flag
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Item has an additional alternative UOM (6 base units each) — different from the base UOM
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", 6);

        // [GIVEN] Released Production Order refreshed at the manufacturing components location
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Subcontracting Purchase Order created via the Prod. Order Routing page
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [GIVEN] Change the purchase line UOM to the alternative UOM to simulate a non-base-UOM document
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Unit of Measure Code", ItemUOM.Code);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create Transfer Route from production order location to subcontractor location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        CreateAndUpdateTransferRoute(ProductionOrder."Location Code", Vendor."Subc. Location Code");

        // [WHEN] Create WIP Transfer Order to Subcontractor and post the shipment
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [THEN] WIP Ledger Entries carry the item base unit of measure, not the document UOM
        WIPLedgerEntry.SetRange("Item No.", Item."No.");
        Assert.IsTrue(WIPLedgerEntry.FindSet(), 'WIP Ledger Entries must be created after posting the WIP transfer shipment.');
        repeat
            Assert.AreEqual(Item."Base Unit of Measure", WIPLedgerEntry."Base Unit of Measure",
                'WIP Ledger Entry Base Unit of Measure must equal the item base UOM, not the document UOM.');
        until WIPLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure PostWhseShipment_WIPTransferLineBlankBin_BinMandatoryLocation_Posts()
    var
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Warehouse shipment for a WIP transfer line with blank Bin Code posts at a bin-mandatory, non-directed location
        Initialize();

        // [GIVEN] Bin-mandatory, non-directed location "L" with Require Shipment and no shipment or default bin
        LibraryWarehouse.CreateLocationWMS(FromLocation, true, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Released WIP transfer order "TO" from "L" for item "I"
        LibraryInventory.CreateItem(Item);
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse shipment "WS" created from "TO" with WIP line having blank Bin Code
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, TransferLine);
        Assert.IsTrue(WarehouseShipmentLine."Transfer WIP Item", 'Warehouse Shipment Line must be a WIP line.');
        Assert.AreEqual('', WarehouseShipmentLine."Bin Code", 'Warehouse Shipment Line must have blank Bin Code.');

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Item No.", Item."No.");

        // [WHEN] Post warehouse shipment "WS"
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer shipment is posted, full quantity is in transit and no item ledger or warehouse entries are created
        VerifyWIPTransferShipmentPosted(TransferLine, Quantity);
        Assert.RecordIsEmpty(ItemLedgerEntry);
        Assert.RecordIsEmpty(WarehouseEntry);
    end;

    [ConfirmHandler]
    procedure DoNotConfirmShowCreatedPurchOrderForSubcontracting(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
        TransfOrderPage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure DeleteWhseReceiptConfimHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question.Contains('Do you really want to delete the Whse. Receipt') then begin
            Reply := true;
            exit;
        end;
        Error('Unexpected confirmation message.');
    end;

    [MessageHandler]
    procedure BinMessageHandler(Message: Text[1024])
    begin
        if Message.Contains('Transfer order') and Message.Contains('was successfully posted') then
            exit;
        Error('Unexpected Message.');
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        StateWIPCleanup: Boolean;
        OnwardProposal: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. WIP Transfer Post Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. WIP Transfer Post Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. WIP Transfer Post Test");
    end;

    procedure CreateInventory(Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Decimal; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
        ItemJournalLine, Item."No.", Location.Code, Bin.Code, Quantity);

        if LotNo <> '' then
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
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
        RoutingLine."Transfer WIP Item" := TransferWIPItem;
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

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TransferLine: Record "Transfer Line")
    begin
        WarehouseShipmentLine.SetRange("Source Type", Database::"Transfer Line");
        WarehouseShipmentLine.SetRange("Source No.", TransferLine."Document No.");
        WarehouseShipmentLine.SetRange("Source Line No.", TransferLine."Line No.");
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure VerifyWIPTransferShipmentPosted(TransferLine: Record "Transfer Line"; ExpectedQuantity: Decimal)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferLine."Document No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", TransferLine."Line No.");
        Assert.AreEqual(ExpectedQuantity, TransferShipmentLine.Quantity, 'Transfer Shipment Line Quantity is incorrect.');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Transfer Shipment Line Quantity (Base) must be 0 for WIP transfer.');

        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(ExpectedQuantity, TransferLine."Qty. in Transit", 'Qty. in Transit is incorrect.');

        PostedWhseShipmentLine.SetRange("Source No.", TransferLine."Document No.");
        PostedWhseShipmentLine.SetRange("Source Line No.", TransferLine."Line No.");
        PostedWhseShipmentLine.FindFirst();
        Assert.AreEqual(ExpectedQuantity, PostedWhseShipmentLine.Quantity, 'Posted Whse. Shipment Line Quantity is incorrect.');
        Assert.AreEqual('', PostedWhseShipmentLine."Bin Code", 'Posted Whse. Shipment Line Bin Code must remain blank.');
    end;
}