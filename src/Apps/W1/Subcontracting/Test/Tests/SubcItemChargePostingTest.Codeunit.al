// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;

codeunit 149917 "Subc. Item Charge Posting Test"
{
    // [FEATURE] Subcontracting Item Charge Posting
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        UnitCostCalculation: Option Time,Units;
        SerialNoMustHaveValueEntryLbl: Label 'Serial number %1 from the first receipt must have its own value entry.', Comment = '%1 = Serial No.';
        SerialNoSecondRcptMustHaveValueEntryLbl: Label 'Serial number %1 from the second receipt must have its own value entry.', Comment = '%1 = Serial No.';

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage')]
    procedure ItemChargePostingForLastOperationSubcontractingReceipt()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        NoSeriesCodeunit: Codeunit "No. Series";
        Qty: Decimal;
        SerialNo: Code[50];
    begin
        // [SCENARIO] Posting an item charge assigned to a subcontracting purchase receipt for the last routing operation should
        // [SCENARIO] link the resulting value entry to the production output item ledger entry.
        // [SCENARIO] Before the fix, PurchRcptLine."Item Rcpt. Entry No." stored the Capacity Ledger Entry no. (not the Output ILE no.)
        // [SCENARIO] because ItemJnlPostLine returns CapLedgEntryNo when Subcontracting = true. This caused PostItem to call
        // [SCENARIO] GlobalItemLedgEntry.Get with the wrong entry number, silently linking the charge to an unrelated item ledger
        // [SCENARIO] entry or failing with "The Item Ledger Entry does not exist".

        // [GIVEN] Subcontracting setup with a single-operation routing where the operation is a subcontracting work center (= last operation)
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        AddSerialTrackingToItem(Item);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 1 (required for serial tracking)
        Qty := 1;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty, Location.Code);

        // [GIVEN] Assign a serial number to the production order line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        SerialNo := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo, '', Qty);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [GIVEN] The subcontracting purchase order is found and its receipt posted
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] The receipt is posted; serial number tracking flows automatically from the production order reservation entries
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] The posted receipt line for the subcontracting order
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] A purchase invoice at the same vendor with an item charge line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");

        // [GIVEN] The item charge is assigned to the subcontracting receipt line
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLine, Qty, PurchaseLineCharge."Direct Unit Cost");

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] The posting succeeds and a value entry of type "Direct Cost" exists linked to the item's output ledger entry
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.RecordIsNotEmpty(ValueEntry);

        // [THEN] The value entry is linked to an output item ledger entry (not a capacity ledger entry)
        ValueEntry.FindLast();
        Assert.AreNotEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry should be linked to an item ledger entry.');
        Assert.AreEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must not reference a capacity ledger entry.');

        // [THEN] The item ledger entry has the correct entry type and serial number
        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        Assert.AreEqual("Item Ledger Entry Type"::Output, ItemLedgerEntry."Entry Type", 'Value entry should point to an output item ledger entry.');
        Assert.AreEqual(SerialNo, ItemLedgerEntry."Serial No.", 'Item ledger entry should carry the serial number from the production order.');

        // [THEN] The item ledger entry is specifically the Output ILE for this production order
        // (not an unrelated ILE that coincidentally shares the same entry number)
        Assert.AreEqual(ProductionOrder."No.", ItemLedgerEntry."Order No.",
            'Output ILE must reference the correct production order.');
        Assert.AreEqual(ProdOrderLine."Line No.", ItemLedgerEntry."Order Line No.",
            'Output ILE must reference the correct production order line.');

        // [THEN] The value entry cost equals the item charge direct unit cost (qty = 1)
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost", ValueEntry."Cost Amount (Actual)",
            'Value entry cost amount should match the item charge direct unit cost.');
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost", ValueEntry."Cost per Unit",
            'Value entry cost per unit should match the item charge direct unit cost.');
        Assert.AreEqual(Qty, ValueEntry."Valued Quantity", 'Value entry valued quantity should match the invoiced quantity.');

        // [THEN] The value entry references the production order (not a blank order)
        Assert.AreEqual("Inventory Order Type"::Production, ValueEntry."Order Type",
            'Value entry order type should be Production.');
        Assert.AreEqual(ProductionOrder."No.", ValueEntry."Order No.",
            'Value entry order no. should match the production order.');
        Assert.AreEqual(ProdOrderLine."Line No.", ValueEntry."Order Line No.",
            'Value entry order line no. should match the production order line.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage')]
    procedure ItemChargePostingDistributedAcrossSerialNumbers()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        NoSeriesCodeunit: Codeunit "No. Series";
        Qty: Decimal;
        SerialNo: array[3] of Code[50];
        SerialNosFound: array[3] of Boolean;
        I: Integer;
    begin
        // [SCENARIO] When an item charge is posted for a last-operation subcontracting receipt
        // with multiple serial-tracked items, the charge is distributed across each Output ILE
        // via the standard CollectItemEntryRelation path ("Item Rcpt. Entry No." = 0).
        // One value entry must exist per serial number, each linked to the correct Output ILE.
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        Qty := 3;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        AddSerialTrackingToItem(Item);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 3 with 3 distinct serial numbers
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        for I := 1 to 3 do begin
            SerialNo[I] := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
            LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo[I], '', 1);
        end;

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [GIVEN] The subcontracting purchase receipt is posted — creates 3 Output ILEs, one per serial
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] A purchase invoice with an item charge for qty = 3 assigned to the receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLine, Qty, PurchaseLineCharge."Direct Unit Cost" * Qty);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly 3 value entries exist — one per Output ILE (one per serial number)
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(3, ValueEntry.Count(), 'There should be exactly one value entry per serial-tracked Output ILE.');

        // [THEN] Each value entry links to a distinct Output ILE — not a capacity ledger entry
        ValueEntry.FindSet();
        repeat
            Assert.AreNotEqual(0, ValueEntry."Item Ledger Entry No.", 'Each value entry should link to an item ledger entry.');
            Assert.AreEqual(0, ValueEntry."Capacity Ledger Entry No.", 'No value entry should reference a capacity ledger entry.');
            ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
            Assert.AreEqual("Item Ledger Entry Type"::Output, ItemLedgerEntry."Entry Type",
                'Each value entry must point to an Output ILE.');
            Assert.AreEqual(ProductionOrder."No.", ItemLedgerEntry."Order No.",
                'Each Output ILE must reference the correct production order.');
            // Record which serial numbers appear across the linked ILEs
            for I := 1 to 3 do
                if ItemLedgerEntry."Serial No." = SerialNo[I] then
                    SerialNosFound[I] := true;
        until ValueEntry.Next() = 0;

        // [THEN] All 3 serial numbers are covered — each gets its own value entry
        for I := 1 to 3 do
            Assert.IsTrue(SerialNosFound[I], 'Each serial number must be covered by a dedicated value entry.');

        // [THEN] Total cost across all value entries equals the full item charge amount
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost" * Qty, ValueEntry."Cost Amount (Actual)",
            'The total cost across all value entries must equal the complete item charge amount.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage')]
    procedure ItemChargePostingWithoutItemTracking()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        Qty: Decimal;
    begin
        // [SCENARIO] Posting an item charge assigned to a subcontracting receipt for a non-tracked item
        // (no serial/lot tracking) should link the resulting value entry to the single Output ILE.

        // [GIVEN] Subcontracting setup with a single-operation routing, item has no item tracking
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 1
        Qty := 1;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [GIVEN] The subcontracting purchase receipt is posted — creates one Output ILE
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] A purchase invoice with an item charge assigned to the subcontracting receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLine, Qty, PurchaseLineCharge."Direct Unit Cost");

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly one value entry of type "Direct Cost" exists for the item charge
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(1, ValueEntry.Count(), 'There should be exactly one value entry for the item charge.');

        // [THEN] For non-tracked items the value entry links to the Capacity Ledger Entry from
        // the service receipt (not to an Item Ledger Entry). Order info is provided via the journal line.
        ValueEntry.FindFirst();
        Assert.AreEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry for non-tracked item must not reference an item ledger entry.');
        Assert.AreNotEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must reference the capacity ledger entry from the service receipt.');

        // [THEN] The value entry cost equals the item charge direct unit cost
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost", ValueEntry."Cost Amount (Actual)",
            'Value entry cost amount should match the item charge direct unit cost.');
        Assert.AreEqual(Qty, ValueEntry."Valued Quantity", 'Value entry valued quantity should match the invoiced quantity.');

        // [THEN] The value entry references the production order
        Assert.AreEqual("Inventory Order Type"::Production, ValueEntry."Order Type", 'Value entry order type should be Production.');
        Assert.AreEqual(ProductionOrder."No.", ValueEntry."Order No.", 'Value entry order no. should match the production order.');
        Assert.AreEqual(ProdOrderLine."Line No.", ValueEntry."Order Line No.", 'Value entry order line no. should match the production order line.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage,ItemTrackingLinesPartialHandler')]
    procedure ItemChargePostingSerialNumbersTwoReceiptsChargeOnFirstRcpt()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLineFirst: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        NoSeriesCodeunit: Codeunit "No. Series";
        QtyPerReceipt: Decimal;
        SerialNo: array[4] of Code[50];
        SerialNosFound: array[2] of Boolean;
        I: Integer;
    begin
        // [SCENARIO] An item charge assigned to the FIRST of two partial subcontracting receipts (serial-tracked)
        // must produce one value entry per serial number received in that first receipt,
        // each linked to the corresponding Output ILE — and not to the serials from the second receipt.
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        QtyPerReceipt := 2;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        AddSerialTrackingToItem(Item);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 4 with 4 distinct serial numbers (SN[1]..SN[4])
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", QtyPerReceipt * 2, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        for I := 1 to 4 do begin
            SerialNo[I] := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
            LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo[I], '', 1);
        end;

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] First partial receipt: SN[1] and SN[2] (qty = 2)
        PurchaseLine.Validate("Qty. to Receive", QtyPerReceipt);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(QtyPerReceipt); // count
        LibraryVariableStorage.Enqueue(SerialNo[1]);
        LibraryVariableStorage.Enqueue(SerialNo[2]);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchRcptLineFirst.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLineFirst.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLineFirst.FindFirst();

        // [GIVEN] Second partial receipt: SN[3] and SN[4] (qty = 2)
        PurchaseLine.FindFirst();
        LibraryVariableStorage.Enqueue(QtyPerReceipt); // count
        LibraryVariableStorage.Enqueue(SerialNo[3]);
        LibraryVariableStorage.Enqueue(SerialNo[4]);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Item charge on an invoice assigned to the FIRST receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", QtyPerReceipt);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLineFirst, QtyPerReceipt, PurchaseLineCharge."Direct Unit Cost" * QtyPerReceipt);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly 2 value entries — one per serial from the first receipt
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(2, ValueEntry.Count(), 'There should be exactly 2 value entries for the 2 serials on the first receipt.');

        // [THEN] Each value entry links to an Output ILE with a serial from SN[1]..SN[2]
        ValueEntry.FindSet();
        repeat
            Assert.AreNotEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry must link to an item ledger entry.');
            Assert.AreEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must not reference a capacity ledger entry.');
            ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
            Assert.AreEqual("Item Ledger Entry Type"::Output, ItemLedgerEntry."Entry Type", 'Value entry must point to an Output ILE.');
            Assert.AreEqual(ProductionOrder."No.", ItemLedgerEntry."Order No.", 'Output ILE must reference the correct production order.');
            for I := 1 to 2 do
                if ItemLedgerEntry."Serial No." = SerialNo[I] then
                    SerialNosFound[I] := true;
        until ValueEntry.Next() = 0;
        for I := 1 to 2 do
            Assert.IsTrue(SerialNosFound[I], StrSubstNo(SerialNoMustHaveValueEntryLbl, SerialNo[I]));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage,ItemTrackingLinesPartialHandler')]
    procedure ItemChargePostingSerialNumbersTwoReceiptsChargeOnSecondRcpt()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLineSecond: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        NoSeriesCodeunit: Codeunit "No. Series";
        QtyPerReceipt: Decimal;
        SerialNo: array[4] of Code[50];
        SerialNosFound: array[2] of Boolean;
        I: Integer;
    begin
        // [SCENARIO] An item charge assigned to the SECOND of two partial subcontracting receipts (serial-tracked)
        // must produce one value entry per serial number received in that second receipt,
        // each linked to the corresponding Output ILE — and not to the serials from the first receipt.
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        QtyPerReceipt := 2;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        AddSerialTrackingToItem(Item);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 4 with 4 distinct serial numbers (SN[1]..SN[4])
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", QtyPerReceipt * 2, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        for I := 1 to 4 do begin
            SerialNo[I] := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
            LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo[I], '', 1);
        end;

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] First partial receipt: SN[1] and SN[2] (qty = 2)
        PurchaseLine.Validate("Qty. to Receive", QtyPerReceipt);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(QtyPerReceipt); // count
        LibraryVariableStorage.Enqueue(SerialNo[1]);
        LibraryVariableStorage.Enqueue(SerialNo[2]);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Second partial receipt: SN[3] and SN[4] (qty = 2)
        PurchaseLine.FindFirst();
        LibraryVariableStorage.Enqueue(QtyPerReceipt); // count
        LibraryVariableStorage.Enqueue(SerialNo[3]);
        LibraryVariableStorage.Enqueue(SerialNo[4]);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Get the SECOND receipt line
        PurchRcptLineSecond.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLineSecond.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLineSecond.FindLast();

        // [GIVEN] Item charge on an invoice assigned to the SECOND receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", QtyPerReceipt);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLineSecond, QtyPerReceipt, PurchaseLineCharge."Direct Unit Cost" * QtyPerReceipt);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly 2 value entries — one per serial from the second receipt
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(2, ValueEntry.Count(), 'There should be exactly 2 value entries for the 2 serials on the second receipt.');

        // [THEN] Each value entry links to an Output ILE with a serial from SN[3]..SN[4]
        ValueEntry.FindSet();
        repeat
            Assert.AreNotEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry must link to an item ledger entry.');
            Assert.AreEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must not reference a capacity ledger entry.');
            ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
            Assert.AreEqual("Item Ledger Entry Type"::Output, ItemLedgerEntry."Entry Type", 'Value entry must point to an Output ILE.');
            Assert.AreEqual(ProductionOrder."No.", ItemLedgerEntry."Order No.", 'Output ILE must reference the correct production order.');
            for I := 3 to 4 do
                if ItemLedgerEntry."Serial No." = SerialNo[I] then
                    SerialNosFound[I - 2] := true;
        until ValueEntry.Next() = 0;
        for I := 3 to 4 do
            Assert.IsTrue(SerialNosFound[I - 2], StrSubstNo(SerialNoSecondRcptMustHaveValueEntryLbl, SerialNo[I]));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage')]
    procedure ItemChargePostingNoTrackingTwoReceiptsChargeOnFirstRcpt()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        PurchRcptLineFirst: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        QtyFirstRcpt: Decimal;
        QtyLastRcpt: Decimal;
    begin
        // [Scenario] receipts must link to the Output ILE posted for that specific receipt, not the second one.
        // Different quantities per receipt (3 vs 2) allow Quantity on the ILE to uniquely identify
        // which receipt the value entry belongs to.
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        QtyFirstRcpt := 3;
        QtyLastRcpt := 2;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] Production order qty = 5 (3 + 2), no item tracking
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", QtyFirstRcpt + QtyLastRcpt, Location.Code);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] First partial receipt (qty = 3)
        PurchaseLine.Validate("Qty. to Receive", QtyFirstRcpt);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLineFirst.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLineFirst.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLineFirst.FindFirst();

        // [GIVEN] Second partial receipt (remaining qty = 2)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Item charge assigned to the FIRST receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", QtyFirstRcpt);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLineFirst, QtyFirstRcpt, PurchaseLineCharge."Direct Unit Cost" * QtyFirstRcpt);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly one value entry for the item charge
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(1, ValueEntry.Count(), 'There should be exactly one value entry for the item charge on the first receipt.');

        // [THEN] For non-tracked items, value entry links to the Capacity Ledger Entry from the FIRST
        // receipt. The cap entry quantity uniquely identifies which receipt it belongs to.
        ValueEntry.FindFirst();
        Assert.AreEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry must not reference an item ledger entry.');
        Assert.AreNotEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must reference the capacity ledger entry from the service receipt.');
        CapacityLedgerEntry.Get(ValueEntry."Capacity Ledger Entry No.");
        Assert.AreEqual(ProductionOrder."No.", ValueEntry."Order No.", 'Value entry must reference the correct production order.');
        Assert.AreEqual(QtyFirstRcpt, CapacityLedgerEntry.Quantity, 'Capacity ledger entry must carry exactly the first receipt qty (3), not the second receipt qty (2).');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage')]
    procedure ItemChargePostingNoTrackingTwoReceiptsChargeOnLastRcpt()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        PurchRcptLineLast: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        QtyFirstRcpt: Decimal;
        QtyLastRcpt: Decimal;
    begin
        // [Subcontracting] receipts must link to the Output ILE posted for that specific receipt, not the first one.
        // Different quantities per receipt (3 vs 2) allow Quantity on the ILE to uniquely identify
        // which receipt the value entry belongs to.
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        QtyFirstRcpt := 3;
        QtyLastRcpt := 2;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", QtyFirstRcpt + QtyLastRcpt, Location.Code);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] First partial receipt (qty = 3)
        PurchaseLine.Validate("Qty. to Receive", QtyFirstRcpt);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Second partial receipt (remaining qty = 2)
        PurchaseLine.FindFirst();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLineLast.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLineLast.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLineLast.FindLast();

        // [GIVEN] Item charge assigned to the LAST receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", QtyLastRcpt);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLineLast, QtyLastRcpt, PurchaseLineCharge."Direct Unit Cost" * QtyLastRcpt);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly one value entry for the item charge
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(1, ValueEntry.Count(), 'There should be exactly one value entry for the item charge on the last receipt.');

        // [THEN] For non-tracked items, value entry links to the Capacity Ledger Entry from the LAST
        // receipt. The cap entry quantity uniquely identifies which receipt it belongs to.
        ValueEntry.FindFirst();
        Assert.AreEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry must not reference an item ledger entry.');
        Assert.AreNotEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must reference the capacity ledger entry from the service receipt.');
        CapacityLedgerEntry.Get(ValueEntry."Capacity Ledger Entry No.");
        Assert.AreEqual(ProductionOrder."No.", ValueEntry."Order No.", 'Value entry must reference the correct production order.');
        Assert.AreEqual(QtyLastRcpt, CapacityLedgerEntry.Quantity, 'Capacity ledger entry must carry exactly the last receipt qty (2), not the first receipt qty (3).');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage,ItemTrackingLinesLotPartialHandler')]
    procedure ItemChargePostingLotTrackingOneReceiptOneLot()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        NoSeriesCodeunit: Codeunit "No. Series";
        Qty: Decimal;
        LotNoSeriesCode: Code[20];
        LotNo: Code[50];
    begin
        // [SCENARIO] Posting an item charge assigned to a single subcontracting receipt for a
        // lot-tracked item (one lot, one receipt) should link the resulting value entry to the
        // single Output ILE carrying the correct lot number.
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        Qty := 3;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        AddLotTrackingToItem(Item, LotNoSeriesCode);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 3 with a single lot number
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LotNo := NoSeriesCodeunit.GetNextNo(LotNoSeriesCode);
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', LotNo, Qty);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [GIVEN] The subcontracting purchase receipt is posted for the full quantity with the lot number
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryVariableStorage.Enqueue(Qty);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] A purchase invoice with an item charge assigned to the receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLine, Qty, PurchaseLineCharge."Direct Unit Cost" * Qty);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly one value entry of type "Direct Cost" exists for the item charge
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(1, ValueEntry.Count(), 'There should be exactly one value entry for the lot-tracked item charge.');

        // [THEN] The value entry is linked to an Output ILE, not a capacity ledger entry
        ValueEntry.FindFirst();
        Assert.AreNotEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry should be linked to an item ledger entry.');
        Assert.AreEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must not reference a capacity ledger entry.');

        // [THEN] The linked ILE is the Output ILE for this production order with the correct lot number
        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        Assert.AreEqual("Item Ledger Entry Type"::Output, ItemLedgerEntry."Entry Type", 'Value entry should point to an output item ledger entry.');
        Assert.AreEqual(ProductionOrder."No.", ItemLedgerEntry."Order No.", 'Output ILE must reference the correct production order.');
        Assert.AreEqual(ProdOrderLine."Line No.", ItemLedgerEntry."Order Line No.", 'Output ILE must reference the correct production order line.');
        Assert.AreEqual(LotNo, ItemLedgerEntry."Lot No.", 'Output ILE must carry the correct lot number.');
        Assert.AreEqual(Qty, ItemLedgerEntry.Quantity, 'Output ILE must carry the full quantity.');

        // [THEN] The value entry cost equals the total item charge amount
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost" * Qty, ValueEntry."Cost Amount (Actual)",
            'Value entry cost amount should match the total item charge amount.');
        Assert.AreEqual(Qty, ValueEntry."Valued Quantity", 'Value entry valued quantity should match the invoiced quantity.');

        // [THEN] The value entry references the production order
        Assert.AreEqual("Inventory Order Type"::Production, ValueEntry."Order Type", 'Value entry order type should be Production.');
        Assert.AreEqual(ProductionOrder."No.", ValueEntry."Order No.", 'Value entry order no. should match the production order.');
        Assert.AreEqual(ProdOrderLine."Line No.", ValueEntry."Order Line No.", 'Value entry order line no. should match the production order line.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage,ItemTrackingLinesLotPartialHandler')]
    procedure ItemChargePostingLotTrackingTwoReceiptsChargeOnFirstRcpt()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLineFirst: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        NoSeriesCodeunit: Codeunit "No. Series";
        QtyFirstRcpt: Decimal;
        QtyLastRcpt: Decimal;
        LotNoSeriesCode: Code[20];
        LotNo: Code[50];
    begin
        // [SCENARIO] An item charge assigned to the FIRST of two lot-tracked partial subcontracting
        // receipts (same lot across both) must link only to the Output ILE from that first receipt.
        // Different quantities per receipt (3 vs 2) allow Quantity on the ILE to uniquely identify
        // which receipt the value entry belongs to.
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        QtyFirstRcpt := 3;
        QtyLastRcpt := 2;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        AddLotTrackingToItem(Item, LotNoSeriesCode);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] Production order qty = 5 (3 + 2), single lot covering all units
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", QtyFirstRcpt + QtyLastRcpt, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LotNo := NoSeriesCodeunit.GetNextNo(LotNoSeriesCode);
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', LotNo, QtyFirstRcpt + QtyLastRcpt);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] First partial receipt (qty = 3, lot = LotNo)
        PurchaseLine.Validate("Qty. to Receive", QtyFirstRcpt);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(QtyFirstRcpt);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLineFirst.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLineFirst.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLineFirst.FindFirst();

        // [GIVEN] Second partial receipt (remaining qty = 2, same lot)
        PurchaseLine.FindFirst();
        LibraryVariableStorage.Enqueue(QtyLastRcpt);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Item charge assigned to the FIRST receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", QtyFirstRcpt);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLineFirst, QtyFirstRcpt, PurchaseLineCharge."Direct Unit Cost" * QtyFirstRcpt);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly one value entry for the item charge
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(1, ValueEntry.Count(), 'There should be exactly one value entry for the lot-tracked first receipt.');

        // [THEN] Value entry links to the Output ILE from the FIRST receipt — uniquely identified by Quantity = 3
        ValueEntry.FindFirst();
        Assert.AreNotEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry must link to an item ledger entry.');
        Assert.AreEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must not reference a capacity ledger entry.');
        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        Assert.AreEqual("Item Ledger Entry Type"::Output, ItemLedgerEntry."Entry Type", 'Value entry must point to an Output ILE.');
        Assert.AreEqual(LotNo, ItemLedgerEntry."Lot No.", 'Output ILE must carry the correct lot number.');
        Assert.AreEqual(QtyFirstRcpt, ItemLedgerEntry.Quantity, 'Output ILE must carry exactly the first receipt qty (3), not the second receipt qty (2).');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage,ItemTrackingLinesLotPartialHandler')]
    procedure ItemChargePostingLotTrackingTwoReceiptsChargeOnLastRcpt()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLineLast: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        NoSeriesCodeunit: Codeunit "No. Series";
        QtyFirstRcpt: Decimal;
        QtyLastRcpt: Decimal;
        LotNoSeriesCode: Code[20];
        LotNo: Code[50];
    begin
        // [SCENARIO] An item charge assigned to the LAST of two lot-tracked partial subcontracting
        // receipts (same lot across both) must link only to the Output ILE from that last receipt.
        // Different quantities per receipt (3 vs 2) allow Quantity on the ILE to uniquely identify
        // which receipt the value entry belongs to.
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        QtyFirstRcpt := 3;
        QtyLastRcpt := 2;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        AddLotTrackingToItem(Item, LotNoSeriesCode);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", QtyFirstRcpt + QtyLastRcpt, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LotNo := NoSeriesCodeunit.GetNextNo(LotNoSeriesCode);
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', LotNo, QtyFirstRcpt + QtyLastRcpt);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] First partial receipt (qty = 3, lot = LotNo)
        PurchaseLine.Validate("Qty. to Receive", QtyFirstRcpt);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(QtyFirstRcpt);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Second partial receipt (remaining qty = 2, same lot)
        PurchaseLine.FindFirst();
        LibraryVariableStorage.Enqueue(QtyLastRcpt);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLineLast.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLineLast.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLineLast.FindLast();

        // [GIVEN] Item charge assigned to the LAST receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", QtyLastRcpt);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLineLast, QtyLastRcpt, PurchaseLineCharge."Direct Unit Cost" * QtyLastRcpt);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly one value entry for the item charge
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(1, ValueEntry.Count(), 'There should be exactly one value entry for the lot-tracked last receipt.');

        // [THEN] Value entry links to the Output ILE from the LAST receipt — uniquely identified by Quantity = 2
        ValueEntry.FindFirst();
        Assert.AreNotEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry must link to an item ledger entry.');
        Assert.AreEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must not reference a capacity ledger entry.');
        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        Assert.AreEqual("Item Ledger Entry Type"::Output, ItemLedgerEntry."Entry Type", 'Value entry must point to an Output ILE.');
        Assert.AreEqual(LotNo, ItemLedgerEntry."Lot No.", 'Output ILE must carry the correct lot number.');
        Assert.AreEqual(QtyLastRcpt, ItemLedgerEntry.Quantity, 'Output ILE must carry exactly the last receipt qty (2), not the first receipt qty (3).');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage')]
    procedure ItemChargePostingForNonLastOperationWithoutItemTracking()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        Qty: Decimal;
    begin
        // [SCENARIO] Posting an item charge assigned to a subcontracting receipt for a NON-last routing
        // operation (no item tracking) should link the value entry to the Capacity Ledger Entry from the
        // service receipt. No Output ILE exists yet at this stage, so Item Ledger Entry No. must be 0.

        // [GIVEN] A two-operation routing where operation 10 is subcontracting (not the last operation)
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        Qty := 1;
        CreateItemWithTwoOperationsFirstSubcontracting(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 1
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [GIVEN] The subcontracting purchase receipt is posted for the non-last operation
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] A purchase invoice with an item charge assigned to the non-last-operation receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLine, Qty, PurchaseLineCharge."Direct Unit Cost");

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly one value entry of type "Direct Cost" exists for the item charge
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(1, ValueEntry.Count(), 'There should be exactly one value entry for the non-last operation item charge.');

        // [THEN] The value entry links to the Capacity Ledger Entry from the service receipt — no Output ILE exists yet
        ValueEntry.FindFirst();
        Assert.AreEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry for a non-last operation must not reference an item ledger entry.');
        Assert.AreNotEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must reference the capacity ledger entry from the service receipt.');

        // [THEN] The capacity ledger entry belongs to the correct production order
        CapacityLedgerEntry.Get(ValueEntry."Capacity Ledger Entry No.");
        Assert.AreEqual(ProductionOrder."No.", CapacityLedgerEntry."Order No.", 'Capacity ledger entry must reference the correct production order.');

        // [THEN] The value entry references the production order
        Assert.AreEqual("Inventory Order Type"::Production, ValueEntry."Order Type", 'Value entry order type should be Production.');
        Assert.AreEqual(ProductionOrder."No.", ValueEntry."Order No.", 'Value entry order no. should match the production order.');
        Assert.AreEqual(ProdOrderLine."Line No.", ValueEntry."Order Line No.", 'Value entry order line no. should match the production order line.');

        // [THEN] The value entry cost equals the item charge direct unit cost
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost", ValueEntry."Cost Amount (Actual)",
            'Value entry cost amount should match the item charge direct unit cost.');
        Assert.AreEqual(Qty, ValueEntry."Valued Quantity", 'Value entry valued quantity should match the invoiced quantity.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage')]
    procedure ItemChargePostingForNonLastOperationWithSerialTracking()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        Location: Record Location;
        NoSeriesCodeunit: Codeunit "No. Series";
        Qty: Decimal;
        SerialNo: Code[50];
    begin
        // [SCENARIO] Posting an item charge assigned to a subcontracting receipt for a NON-last routing
        // operation with serial tracking should still link the value entry to the Capacity Ledger Entry.
        // No Output ILE exists at this intermediate stage, so the item charge cannot link to an ILE
        // regardless of tracking. The serial number on the production order does not change this behavior.

        // [GIVEN] A two-operation routing where operation 10 is subcontracting (not the last operation)
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        Qty := 1;
        CreateItemWithTwoOperationsFirstSubcontracting(Item, SubcWorkCenter);
        AddSerialTrackingToItem(Item);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 1 with a serial number
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        SerialNo := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo, '', Qty);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [GIVEN] The subcontracting purchase receipt is posted for the non-last operation
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] A purchase invoice with an item charge assigned to the non-last-operation receipt line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLine, Qty, PurchaseLineCharge."Direct Unit Cost");

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Exactly one value entry of type "Direct Cost" exists for the item charge
        // (serial tracking does not split the charge here — there is no Output ILE per serial yet)
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.AreEqual(1, ValueEntry.Count(), 'There should be exactly one value entry for the non-last operation serial-tracked item charge.');

        // [THEN] The value entry links to the Capacity Ledger Entry — not an Output ILE (which does not exist yet)
        ValueEntry.FindFirst();
        Assert.AreEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry for a non-last operation must not reference an item ledger entry.');
        Assert.AreNotEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Value entry must reference the capacity ledger entry from the service receipt.');

        // [THEN] The capacity ledger entry belongs to the correct production order
        CapacityLedgerEntry.Get(ValueEntry."Capacity Ledger Entry No.");
        Assert.AreEqual(ProductionOrder."No.", CapacityLedgerEntry."Order No.", 'Capacity ledger entry must reference the correct production order.');

        // [THEN] The value entry references the production order
        Assert.AreEqual("Inventory Order Type"::Production, ValueEntry."Order Type", 'Value entry order type should be Production.');
        Assert.AreEqual(ProductionOrder."No.", ValueEntry."Order No.", 'Value entry order no. should match the production order.');
        Assert.AreEqual(ProdOrderLine."Line No.", ValueEntry."Order Line No.", 'Value entry order line no. should match the production order line.');

        // [THEN] The value entry cost equals the item charge direct unit cost
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost", ValueEntry."Cost Amount (Actual)",
            'Value entry cost amount should match the item charge direct unit cost.');
        Assert.AreEqual(Qty, ValueEntry."Valued Quantity", 'Value entry valued quantity should match the invoiced quantity.');
    end;

    [Test]
    [HandlerFunctions('CancelInvoiceConfirmHandler')]
    procedure CancelInvoiceWithSubcontractingItemChargeIsBlocked()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SubcWorkCenter: Record "Work Center";
        SubcPurchaseHeader: Record "Purchase Header";
        SubcPurchaseLine: Record "Purchase Line";
        SubcPurchRcptLine: Record "Purch. Rcpt. Line";
        ItemCharge: Record "Item Charge";
        ItemChargeInvHeader: Record "Purchase Header";
        ItemChargeInvLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 637502] Cancelling a Posted Purchase Invoice whose Item Charge is assigned to a subcontracting service
        // receipt line must be blocked. Letting the cancel run today silently skips the capacity portion (Value Entry has
        // Item Ledger Entry No. = 0) and redistributes it to inventory, corrupting cost. Until a proper reversal path exists,
        // the Subcontracting App blocks the cancel with a clear error so the user creates a corrective credit memo manually.

        // [GIVEN] Subcontracting setup with a routing whose subcontracting operation is not the last operation, so the
        // item charge is booked against the work center capacity
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateItemWithTwoOperationsFirstSubcontracting(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] Released production order and a subcontracting purchase order received in full
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");

        SubcPurchaseLine.SetRange("Document Type", SubcPurchaseLine."Document Type"::Order);
        SubcPurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        SubcPurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        SubcPurchaseLine.FindFirst();
        SubcPurchaseHeader.Get(SubcPurchaseLine."Document Type", SubcPurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(SubcPurchaseLine."Gen. Bus. Posting Group", SubcPurchaseLine."Gen. Prod. Posting Group");

        LibraryPurchase.PostPurchaseDocument(SubcPurchaseHeader, true, false);

        SubcPurchRcptLine.SetRange("Order No.", SubcPurchaseHeader."No.");
        SubcPurchRcptLine.SetRange("Order Line No.", SubcPurchaseLine."Line No.");
        SubcPurchRcptLine.FindFirst();

        // [GIVEN] A separate purchase invoice with a single Item Charge line assigned to the subcontracting receipt line
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchHeader(ItemChargeInvHeader, ItemChargeInvHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(ItemChargeInvLine, ItemChargeInvHeader, ItemChargeInvLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        ItemChargeInvLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        ItemChargeInvLine.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(ItemChargeInvLine."Gen. Bus. Posting Group", ItemChargeInvLine."Gen. Prod. Posting Group");

        AssignItemChargeToReceiptLine(ItemChargeInvLine, SubcPurchRcptLine, 1, ItemChargeInvLine."Direct Unit Cost");

        // [GIVEN] The invoice is posted
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(ItemChargeInvHeader, false, true);
        PurchInvHeader.Get(PostedInvoiceNo);
        Commit();

        // [WHEN] The user tries to cancel the posted invoice
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] The Subcontracting App blocks the cancel with the dedicated error
        Assert.ExpectedError('contains item charges assigned to a subcontracting order receipt');
    end;

    [Test]
    procedure AssignItemChargeToUndoneSubcontractingReceiptIsBlocked()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // [SCENARIO 637503] Assigning an item charge to a subcontracting receipt line that has been undone must be blocked,
        // otherwise posting it would book the capacity cost onto the original entry while the undo entry stays at 0.

        // [GIVEN] An undone subcontracting receipt line
        Initialize();
        MockSubcontractingPurchRcptLine(PurchRcptLine, true);

        // [GIVEN] An item charge assignment context on a purchase invoice line
        ItemChargeAssignmentPurch."Document Type" := ItemChargeAssignmentPurch."Document Type"::Invoice;
        ItemChargeAssignmentPurch."Document No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ItemChargeAssignmentPurch."Document No."));
        ItemChargeAssignmentPurch."Document Line No." := 10000;
        ItemChargeAssignmentPurch."Line No." := 10000;

        // [WHEN] Assigning the item charge to the undone receipt line
        PurchRcptLine.SetRecFilter();
        asserterror ItemChargeAssgntPurch.CreateRcptChargeAssgnt(PurchRcptLine, ItemChargeAssignmentPurch);

        // [THEN] It is blocked
        Assert.ExpectedError('has been undone');
    end;

    local procedure AddLotTrackingToItem(var Item: Record Item; var LotNoSeriesCode: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, 'LOT-0001', 'LOT-9999');
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LotNoSeries.Code);
        Item.Modify(true);
        LotNoSeriesCode := LotNoSeries.Code;
    end;

    local procedure AddSerialTrackingToItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code,
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'),
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", SerialNoSeries.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithSingleSubcontractingOperation(var Item: Record Item; var SubcWorkCenter: Record "Work Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ComponentItem1: Record Item;
        ComponentItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ShopCalendarCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();
        CreateSubcontractingWorkCenter(WorkCenterNo, ShopCalendarCode);
        SubcWorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(SubcWorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", SubcWorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryInventory.CreateItem(ComponentItem1);
        LibraryInventory.CreateItem(ComponentItem2);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ComponentItem1."No.", ComponentItem2."No.", 1);

        LibraryManufacturing.CreateItemManufacturing(
            Item, "Costing Method"::FIFO, LibraryRandom.RandInt(10),
            "Reordering Policy"::"Lot-for-Lot", Microsoft.Manufacturing.Setup."Flushing Method"::"Pick + Manual",
            RoutingHeader."No.", ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithTwoOperationsFirstSubcontracting(var Item: Record Item; var SubcWorkCenter: Record "Work Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ComponentItem1: Record Item;
        ComponentItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RegularWorkCenter: Record "Work Center";
        ShopCalendarCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();
        CreateSubcontractingWorkCenter(WorkCenterNo, ShopCalendarCode);
        SubcWorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(SubcWorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // Create a regular (non-subcontracting) work center for the second (last) operation
        LibraryMfgManagement.CreateWorkCenterWithFixedCost(RegularWorkCenter, ShopCalendarCode, 0);
        LibraryManufacturing.CalculateWorkCenterCalendar(RegularWorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        // Operation 10: Subcontracting work center — NOT the last operation
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", SubcWorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
        // Operation 20: Regular work center — the last operation
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", RegularWorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryInventory.CreateItem(ComponentItem1);
        LibraryInventory.CreateItem(ComponentItem2);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ComponentItem1."No.", ComponentItem2."No.", 1);

        LibraryManufacturing.CreateItemManufacturing(
            Item, "Costing Method"::FIFO, LibraryRandom.RandInt(10),
            "Reordering Policy"::"Lot-for-Lot", Microsoft.Manufacturing.Setup."Flushing Method"::"Pick + Manual",
            RoutingHeader."No.", ProductionBOMHeader."No.");
    end;

    local procedure CreateSubcontractingWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        WorkCenter: Record "Work Center";
    begin
        LibraryMfgManagement.CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalculation);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GenProductPostingGroup.FindFirst();
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure AssignItemChargeToReceiptLine(PurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToAssign: Decimal; AmountToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        NextLineNo: Integer;
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseLine."Line No.");
        if ItemChargeAssignmentPurch.FindLast() then
            NextLineNo := ItemChargeAssignmentPurch."Line No." + 10000
        else
            NextLineNo := 10000;

        ItemChargeAssignmentPurch.Init();
        ItemChargeAssignmentPurch."Document Type" := PurchaseLine."Document Type";
        ItemChargeAssignmentPurch."Document No." := PurchaseLine."Document No.";
        ItemChargeAssignmentPurch."Document Line No." := PurchaseLine."Line No.";
        ItemChargeAssignmentPurch."Item Charge No." := PurchaseLine."No.";
        ItemChargeAssignmentPurch."Unit Cost" := PurchaseLine."Direct Unit Cost";

        ItemChargeAssgntPurch.InsertItemChargeAssignmentWithValues(
            ItemChargeAssignmentPurch,
            "Purchase Applies-to Document Type"::Receipt,
            PurchRcptLine."Document No.",
            PurchRcptLine."Line No.",
            PurchRcptLine."No.",
            PurchRcptLine.Description,
            QtyToAssign,
            AmountToAssign,
            NextLineNo);
    end;

    local procedure MockSubcontractingPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; Undone: Boolean)
    var
        Item: Record Item;
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryInventory.CreateItem(Item);
        PurchRcptLine.Init();
        PurchRcptLine."Document No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PurchRcptLine."Document No."));
        PurchRcptLine."Line No." := 10000;
        PurchRcptLine.Type := PurchRcptLine.Type::Item;
        PurchRcptLine."No." := Item."No.";
        PurchRcptLine."Prod. Order No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PurchRcptLine."Prod. Order No."));
        PurchRcptLine."Routing No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PurchRcptLine."Routing No."));
        PurchRcptLine."Operation No." := '10';
        PurchRcptLine.Quantity := LibraryRandom.RandIntInRange(5, 10);
        PurchRcptLine."Qty. Rcd. Not Invoiced" := PurchRcptLine.Quantity;
        PurchRcptLine.Correction := Undone;
        PurchRcptLine.Insert();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Item Charge Posting Test");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Item Charge Posting Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        LibraryMfgManagement.Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Item Charge Posting Test");
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure CancelInvoiceConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        case true of
            Question.Contains('Do you really want to change Inventory Account although value entries exist?'),
            Question.Contains('Do you want to create a production order from'),
            Question.Contains('Do you really want to change Inventory Account (Interim) although value entries exist?'):
                Reply := true;
            else
                Reply := false;
        end;
    end;

    [PageHandler]
    procedure HandlePurchaseOrderPage(var PurchaseOrderPage: TestPage "Purchase Order")
    begin
        PurchaseOrderPage.Close();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesPartialHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SerialNosToHandle: Text;
        QtyToHandle: Integer;
        I: Integer;
    begin
        // Dequeue: first value = count of serial numbers to handle.
        // Subsequent values = the serial numbers themselves.
        // Tracking lines whose Serial No. matches are set to Qty. to Handle = 1; all others to 0.
        QtyToHandle := LibraryVariableStorage.DequeueInteger();
        SerialNosToHandle := '';
        for I := 1 to QtyToHandle do
            SerialNosToHandle += '|' + LibraryVariableStorage.DequeueText();
        if ItemTrackingLines.First() then
            repeat
                if ItemTrackingLines."Serial No.".Value = '' then
                    continue;
                if SerialNosToHandle.Contains('|' + ItemTrackingLines."Serial No.".Value) then
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(1)
                else
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(0);
            until not ItemTrackingLines.Next();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesLotPartialHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        QtyToHandle: Decimal;
    begin
        // Sets Qty. to Handle (Base) on the first (lot) line to the enqueued quantity.
        // All other lines are cleared. Used for partial receipt of a lot-tracked item.
        QtyToHandle := LibraryVariableStorage.DequeueDecimal();
        if ItemTrackingLines.First() then
            ItemTrackingLines."Qty. to Handle (Base)".SetValue(QtyToHandle);
        ItemTrackingLines.OK().Invoke();
    end;
}