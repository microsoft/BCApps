// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.TestLibraries.Utilities;

codeunit 139960 "Qlty. Tests - Dispositions"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ReUsedLibraryItemTracking: Codeunit "Library - Item Tracking";
        NoPurchRcptLineErr: Label 'Could not find a related purchase receipt line with sufficient quantity for %1 from Quality Inspection %2,%3. Confirm the inspection source is a Purchase Line and that it has been received prior to creating a return.', Comment = '%1=item,%2=inspection,%3=re-inspection';
        WriteOffEntireItemTrackingErr: Label 'Reducing inventory using the item tracked quantity for inspection %1 was requested, however the item associated with this inspection does not require tracking.', Comment = '%1=the inspection';
        MissingAdjBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the adjustment batch.';
        MissingBinReclassBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the Reclass batch.';
        MissingReclassBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the Reclassification Journal Batch or Warehouse Reclassification Batch';
        CannotGetJournalBatchErr: Label 'Could not get journal batch %1,%2%3. Check the adjustment batch on the Quality Management Setup page.', Comment = '%1=template,%2=batch name,%3=location';
        LocationTok: Label ' Location: %1', Comment = '%1=location';
        NoTrackingChangesErr: Label 'No changes to item tracking information were provided.';
        MissingBinMoveBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the movement batches.';
        RequestedInventoryMoveButUnableToFindSufficientDetailsErr: Label 'A worksheet movement for the inventory related to inspection %1 was requested, however insufficient inventory information is available to do this task.\\  Please verify that the inspection has sufficient details for the item, variant, lot, serial and package. \\ Make sure to define the quantity to move.', Comment = '%1=the inspection';
        RequestedBinMoveButUnableToFindSufficientDetailsErr: Label 'A bin movement for the inventory related to inspection %1 was requested, however insufficient inventory information is available to do this task.\\ Please verify that the inspection has sufficient details for the location, item, variant, lot, serial and package. \\ Make sure to define the quantity to move.', Comment = '%1=Inspection No';
        ThereIsNothingToMoveToErr: Label 'There is no location or bin to move to. Unable to perform the inventory related transaction on the inspection %1. Please define the target location and bin and try again.', Locked = true, Comment = '%1=the inspection';
        UnableToChangeBinsBetweenLocationsBecauseDirectedPickAndPutErr: Label 'Unable to change location of the inventory from inspection %1 from location %2 to %3 because %2 is directed pick and put-away, you can only change bins with the same location.', Comment = '%1=the inspection, %2=from location, %3=to location';
        IsInitialized: Boolean;

    [Test]
    procedure PurchaseReturnFullLotAdvLocation()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        AdvWhseLocation: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        TempTrackedPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
    begin
        // [SCENARIO] Create a purchase return order from a quality inspection for a full lot-tracked quantity in an advanced warehouse location

        // [GIVEN] An advanced warehouse location with full warehouse management is created
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(AdvWhseLocation, 3);

        // [GIVEN] Lot tracked item is created
        QltyInspectionUtility.CreateLotTrackedItemWithVariant(Item, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, AdvWhseLocation, Item, Vendor, OptionalItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, PurOrdReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(AdvWhseLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);
        PurOrdPurchaseLine.Get(PurOrdPurchaseLine."Document Type", PurOrdPurchaseLine."Document No.", PurOrdPurchaseLine."Line No.");
        LibraryAssert.AreEqual(PurOrderPurchaseHeader.Status, PurOrderPurchaseHeader.Status::Released, 'Purchase Order was not released.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Quantity (Base)", PurOrdPurchaseLine."Qty. Received (Base)", 'Purchase Order was not fully received.');

        // [GIVEN] A quality inspection template and generation rule are created for the purchase line
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with purchase line and tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurOrdPurchaseLine, PurOrdReservationEntry, QltyInspectionHeader);

        // [GIVEN] A return reason code is obtained or created
        Reason := GetOrCreateReturnReasonCode();

        // [GIVEN] A credit memo number is generated
        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] A specific quantity is set for return
        SpecificQty := 9;

        // [WHEN] Purchase return disposition is performed with item tracked quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Item Tracked Quantity", SpecificQty, '', '', Reason, CreditMemo, TempTrackedPurRtnBufferPurchaseHeader);
        QltyInspectionGenRule.Delete();

        // [THEN] The inspection assertions verify the purchase return order was created correctly
        VerifyInspectionAssertions(100, QltyInspectionHeader, TempTrackedPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);
    end;

    [Test]
    procedure PurchaseReturnLotTrackedAdvLocation()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        AdvWhseLocation: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        TempSamplePurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempPassPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempFailPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempSpecificPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
    begin
        // [SCENARIO] Create purchase return orders from a quality inspection for different quantity behaviors (sample size, pass quantity, fail quantity, and specific quantity) in an advanced warehouse location

        Initialize();

        // [GIVEN] An advanced warehouse location with full warehouse management is created
        LibraryWarehouse.CreateFullWMSLocation(AdvWhseLocation, 3);

        // [GIVEN] Lot tracked item is created
        QltyInspectionUtility.CreateLotTrackedItemWithVariant(Item, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order is created, released, and fully received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, AdvWhseLocation, Item, Vendor, OptionalItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, PurOrdReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(AdvWhseLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);
        PurOrdPurchaseLine.Get(PurOrdPurchaseLine."Document Type", PurOrdPurchaseLine."Document No.", PurOrdPurchaseLine."Line No.");
        LibraryAssert.AreEqual(PurOrderPurchaseHeader.Status, PurOrderPurchaseHeader.Status::Released, 'Purchase Order was not released.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Qty. Received (Base)", PurOrdPurchaseLine."Quantity (Base)", 'Purchase Order was not fully received.');

        // [GIVEN] A quality inspection template and generation rule are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with sample, pass, and fail quantities
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurOrdPurchaseLine, PurOrdReservationEntry, QltyInspectionHeader);
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Pass Quantity" := 3;
        QltyInspectionHeader."Fail Quantity" := 2;
        QltyInspectionHeader.Modify(false);

        // [GIVEN] A return reason code and credit memo number are prepared
        Reason := GetOrCreateReturnReasonCode();

        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] A specific quantity is set for testing
        SpecificQty := 9;

        QltyInspectionGenRule.Delete();

        // [WHEN] Purchase return disposition is performed with sample quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Sample Quantity", SpecificQty, '', '', Reason, CreditMemo, TempSamplePurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for sample quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Sample Size", QltyInspectionHeader, TempSamplePurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with passed quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Passed Quantity", SpecificQty, '', '', Reason, CreditMemo, TempPassPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for passed quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Pass Quantity", QltyInspectionHeader, TempPassPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with failed quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Failed Quantity", SpecificQty, '', '', Reason, CreditMemo, TempFailPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for failed quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Fail Quantity", QltyInspectionHeader, TempFailPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with specific quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Specific Quantity", SpecificQty, '', '', Reason, CreditMemo, TempSpecificPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for specific quantity is verified
        VerifyInspectionAssertions(SpecificQty, QltyInspectionHeader, TempSpecificPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);
    end;

    [Test]
    procedure PurchaseReturnLotTrackedAdvLocation_MultipleBins()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        AdvWhseLocation: Record Location;
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWarehouseJournalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WarehouseEntry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        Item: Record Item;
        Vendor: Record Vendor;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        TempSamplePurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
    begin
        // [SCENARIO] Create a purchase return order for lot-tracked items distributed across multiple bins

        Initialize();

        // [GIVEN] An advanced warehouse location with full warehouse management is created
        LibraryWarehouse.CreateFullWMSLocation(AdvWhseLocation, 3);

        // [GIVEN] Lot tracked item is created
        QltyInspectionUtility.CreateLotTrackedItemWithVariant(Item, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order is created, released, and fully received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, AdvWhseLocation, Item, Vendor, OptionalItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, PurOrdReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(AdvWhseLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);
        PurOrdPurchaseLine.Get(PurOrdPurchaseLine."Document Type", PurOrdPurchaseLine."Document No.", PurOrdPurchaseLine."Line No.");
        LibraryAssert.AreEqual(PurOrderPurchaseHeader.Status, PurOrderPurchaseHeader.Status::Released, 'Purchase Order was not released.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Qty. Received (Base)", PurOrdPurchaseLine."Quantity (Base)", 'Purchase Order was not fully received.');

        // [GIVEN] A quality inspection template and generation rule are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with sample, pass, and fail quantities
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurOrdPurchaseLine, PurOrdReservationEntry, QltyInspectionHeader);
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Pass Quantity" := 3;
        QltyInspectionHeader."Fail Quantity" := 2;
        QltyInspectionHeader.Modify(false);

        // [GIVEN] A return reason code and credit memo number are prepared
        Reason := GetOrCreateReturnReasonCode();

        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] A specific quantity is set for testing
        SpecificQty := 9;

        // [GIVEN] A warehouse reclassification journal is prepared to move items between bins
        ReclassWhseItemWarehouseJournalTemplate.Reset();
        ReclassWhseItemWarehouseJournalTemplate.SetRange(Type, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        if ReclassWhseItemWarehouseJournalTemplate.Count() > 1 then
            ReclassWhseItemWarehouseJournalTemplate.DeleteAll();

        if not ReclassWhseItemWarehouseJournalTemplate.FindFirst() then
            LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, AdvWhseLocation.Code);

        // [GIVEN] Warehouse entry is found for the received lot
        WarehouseEntry.SetRange("Location Code", AdvWhseLocation.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", PurOrdReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        // [GIVEN] A reclassification journal line is created to move 50 units to a different bin
        QltyInspectionUtility.SetCurrLocationWhseEmployee(AdvWhseLocation.Code);
        QltyInspectionUtility.CreateReclassWhseJournalLine(ReclassWarehouseJournalLine, ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, AdvWhseLocation.Code,
            WarehouseEntry."Zone Code", WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."Entry Type"::Movement, Item."No.", 50);
        Bin.SetRange("Location Code", AdvWhseLocation.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();
        ReclassWarehouseJournalLine."Variant Code" := OptionalItemVariant;
        ReclassWarehouseJournalLine."From Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."From Bin Code" := ReclassWarehouseJournalLine."Bin Code";
        ReclassWarehouseJournalLine."To Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."To Bin Code" := Bin.Code;
        ReclassWarehouseJournalLine."Lot No." := PurOrdReservationEntry."Lot No.";
        ReclassWarehouseJournalLine."New Lot No." := ReclassWarehouseJournalLine."Lot No.";
        ReclassWarehouseJournalLine.Modify();
        // [GIVEN] Item tracking is created for the reclassification journal line
        ReUsedLibraryItemTracking.CreateWhseJournalLineItemTracking(ReclassWarehouseJournalWhseItemTrackingLine, ReclassWarehouseJournalLine, '', PurOrdReservationEntry."Lot No.", 50);
        ReclassWarehouseJournalWhseItemTrackingLine."New Lot No." := ReclassWarehouseJournalWhseItemTrackingLine."Lot No.";
        ReclassWarehouseJournalWhseItemTrackingLine.Modify();
        // [GIVEN] The warehouse journal is registered to complete the movement
        LibraryWarehouse.RegisterWhseJournalLine(ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, AdvWhseLocation.Code, true);

        // [GIVEN] Two bin contents exist with 50 units each
        BinContent.SetRange("Location Code", AdvWhseLocation.Code);
        BinContent.SetRange("Item No.", Item."No.");
        LibraryAssert.AreEqual(2, BinContent.Count(), 'Test setup failed. Two bins should have a quantity of 50 each of the item.');

        QltyInspectionGenRule.Delete();

        // [WHEN] Purchase return disposition is performed with item tracked quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Item Tracked Quantity", SpecificQty, '', '', Reason, CreditMemo, TempSamplePurRtnBufferPurchaseHeader);
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();

        // [THEN] The inspection assertions verify the purchase return order was created correctly for items across multiple bins
        VerifyInspectionAssertions(100, QltyInspectionHeader, TempSamplePurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);
    end;

    [Test]
    procedure PurchaseReturnFullPackageAdvLocation()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        AdvWhseLocation: Record Location;
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        TempTrackedPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
        UnitCost: Decimal;
    begin
        // [SCENARIO] Create a purchase return order from a quality inspection for full package-tracked quantity in an advanced warehouse location

        Initialize();

        // [GIVEN] An advanced warehouse location with full warehouse management is created
        LibraryWarehouse.CreateFullWMSLocation(AdvWhseLocation, 3);

        // [GIVEN] Package tracking is created with item tracking code
        QltyInspectionUtility.CreatePackageTracking(PackageNoSeries, PackageNoSeriesLine, PackageItemTrackingCode);
        UnitCost := LibraryRandom.RandDecInRange(1, 10, 2);
        QltyInspectionUtility.CreatePackageTrackedItem(Item, PackageItemTrackingCode.Code, UnitCost, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order for 100 package-tracked items is created, released, and fully received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, AdvWhseLocation, Item, Vendor, OptionalItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, PurOrdReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(AdvWhseLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);
        PurOrdPurchaseLine.Get(PurOrdPurchaseLine."Document Type", PurOrdPurchaseLine."Document No.", PurOrdPurchaseLine."Line No.");
        LibraryAssert.AreEqual(PurOrderPurchaseHeader.Status, PurOrderPurchaseHeader.Status::Released, 'Purchase Order was not released.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Quantity (Base)", PurOrdPurchaseLine."Qty. Received (Base)", 'Purchase Order was not fully received.');

        // [GIVEN] A quality inspection template and generation rule are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with purchase line and tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurOrdPurchaseLine, PurOrdReservationEntry, QltyInspectionHeader);

        // [GIVEN] A return reason code and credit memo number are prepared
        Reason := GetOrCreateReturnReasonCode();

        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] A specific quantity is set for return
        SpecificQty := 9;

        QltyInspectionGenRule.Delete();

        // [WHEN] Purchase return disposition is performed with item tracked quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Item Tracked Quantity", SpecificQty, '', '', Reason, CreditMemo, TempTrackedPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order is created correctly for full package-tracked quantity
        VerifyInspectionAssertions(100, QltyInspectionHeader, TempTrackedPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);
    end;

    [Test]
    procedure PurchaseReturnPackageTrackedAdvLocation()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        AdvWhseLocation: Record Location;
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        TempSamplePurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempPassPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempFailPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempSpecificPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
        UnitCost: Decimal;
    begin
        // [SCENARIO] Create purchase return orders from a quality inspection for different quantity behaviors (sample size, pass quantity, fail quantity, and specific quantity) with package-tracked items

        Initialize();

        // [GIVEN] An advanced warehouse location with full warehouse management is created
        LibraryWarehouse.CreateFullWMSLocation(AdvWhseLocation, 3);

        // [GIVEN] Package tracking is created with item tracking code
        QltyInspectionUtility.CreatePackageTracking(PackageNoSeries, PackageNoSeriesLine, PackageItemTrackingCode);
        UnitCost := LibraryRandom.RandDecInRange(1, 10, 2);
        QltyInspectionUtility.CreatePackageTrackedItem(Item, PackageItemTrackingCode.Code, UnitCost, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order for 100 package-tracked items is created, released, and fully received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, AdvWhseLocation, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, PurOrdReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(AdvWhseLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);
        PurOrdPurchaseLine.Get(PurOrdPurchaseLine."Document Type", PurOrdPurchaseLine."Document No.", PurOrdPurchaseLine."Line No.");
        LibraryAssert.AreEqual(PurOrderPurchaseHeader.Status, PurOrderPurchaseHeader.Status::Released, 'Purchase Order was not released.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Qty. Received (Base)", PurOrdPurchaseLine."Quantity (Base)", 'Purchase Order was not fully received.');

        // [GIVEN] A quality inspection template and generation rule are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with sample, pass, and fail quantities
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurOrdPurchaseLine, PurOrdReservationEntry, QltyInspectionHeader);
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Pass Quantity" := 3;
        QltyInspectionHeader."Fail Quantity" := 2;
        QltyInspectionHeader.Modify(false);

        // [GIVEN] A return reason code and credit memo number are prepared
        Reason := GetOrCreateReturnReasonCode();

        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] A specific quantity is set for testing
        SpecificQty := 9;

        QltyInspectionGenRule.Delete();

        // [WHEN] Purchase return disposition is performed with sample quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Sample Quantity", SpecificQty, '', '', Reason, CreditMemo, TempSamplePurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for sample quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Sample Size", QltyInspectionHeader, TempSamplePurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with passed quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Passed Quantity", SpecificQty, '', '', Reason, CreditMemo, TempPassPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for passed quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Pass Quantity", QltyInspectionHeader, TempPassPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with failed quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Failed Quantity", SpecificQty, '', '', Reason, CreditMemo, TempFailPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for failed quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Fail Quantity", QltyInspectionHeader, TempFailPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with specific quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Specific Quantity", SpecificQty, '', '', Reason, CreditMemo, TempSpecificPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for specific quantity is verified
        VerifyInspectionAssertions(SpecificQty, QltyInspectionHeader, TempSpecificPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);
    end;

    [Test]
    procedure PurchaseReturnUntrackedBasicLocation()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        BasicLocation: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSamplePurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempPassPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempFailPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        TempSpecificPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
        UnitCost: Decimal;
    begin
        // [SCENARIO] Create purchase return orders from a quality inspection for different quantity behaviors (sample size, pass quantity, fail quantity, and specific quantity) with untracked items in a basic location

        Initialize();

        // [GIVEN] A basic warehouse location without advanced warehousing is created
        LibraryWarehouse.CreateLocationWMS(BasicLocation, false, false, false, false, false);

        // [GIVEN] An untracked item is created
        UnitCost := LibraryRandom.RandDecInRange(1, 10, 2);
        QltyInspectionUtility.CreateUntrackedItem(Item, UnitCost, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order for 100 untracked items is created, released, and fully received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, BasicLocation, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(BasicLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);
        PurOrdPurchaseLine.Get(PurOrdPurchaseLine."Document Type", PurOrdPurchaseLine."Document No.", PurOrdPurchaseLine."Line No.");
        LibraryAssert.AreEqual(PurOrderPurchaseHeader.Status, PurOrderPurchaseHeader.Status::Released, 'Purchase Order was not released.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Qty. Received (Base)", PurOrdPurchaseLine."Quantity (Base)", 'Purchase Order was not fully received.');

        // [GIVEN] A quality inspection template and generation rule are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with sample, pass, and fail quantities
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurOrdPurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Pass Quantity" := 3;
        QltyInspectionHeader."Fail Quantity" := 2;
        QltyInspectionHeader.Modify(false);

        // [GIVEN] A return reason code and credit memo number are prepared
        Reason := GetOrCreateReturnReasonCode();

        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] A specific quantity is set for testing
        SpecificQty := 9;

        QltyInspectionGenRule.Delete();

        // [WHEN] Purchase return disposition is performed with sample quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Sample Quantity", SpecificQty, '', '', Reason, CreditMemo, TempSamplePurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for sample quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Sample Size", QltyInspectionHeader, TempSamplePurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", BasicLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with passed quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Passed Quantity", SpecificQty, '', '', Reason, CreditMemo, TempPassPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for passed quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Pass Quantity", QltyInspectionHeader, TempPassPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", BasicLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with failed quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Failed Quantity", SpecificQty, '', '', Reason, CreditMemo, TempFailPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for failed quantity is verified
        VerifyInspectionAssertions(QltyInspectionHeader."Fail Quantity", QltyInspectionHeader, TempFailPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", BasicLocation.Code, Reason);

        // [WHEN] Purchase return disposition is performed with specific quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Specific Quantity", SpecificQty, '', '', Reason, CreditMemo, TempSpecificPurRtnBufferPurchaseHeader);
        // [THEN] The purchase return order for specific quantity is verified
        VerifyInspectionAssertions(SpecificQty, QltyInspectionHeader, TempSpecificPurRtnBufferPurchaseHeader, TempSpecificPurRtnBufferPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", BasicLocation.Code, Reason);
    end;

    [Test]
    procedure PurchaseReturn_Unreceived_ShouldErr()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        BasicLocation: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempDummyPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
        UnitCost: Decimal;
    begin
        // [SCENARIO] Validate that attempting to create a purchase return for an unreceived purchase order results in an error

        Initialize();

        // [GIVEN] A basic warehouse location without advanced warehousing is created
        LibraryWarehouse.CreateLocationWMS(BasicLocation, false, false, false, false, false);

        // [GIVEN] An untracked item is created
        UnitCost := LibraryRandom.RandDecInRange(1, 10, 2);
        QltyInspectionUtility.CreateUntrackedItem(Item, UnitCost, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order is created but NOT received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, BasicLocation, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);

        // [GIVEN] A quality inspection template and generation rule are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with sample, pass, and fail quantities
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurOrdPurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Pass Quantity" := 3;
        QltyInspectionHeader."Fail Quantity" := 2;
        QltyInspectionHeader.Modify(false);

        // [GIVEN] A return reason code and credit memo number are prepared
        Reason := GetOrCreateReturnReasonCode();

        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] A specific quantity is set for testing
        SpecificQty := 9;

        QltyInspectionGenRule.Delete();

        // [WHEN] Purchase return disposition is attempted on an unreceived purchase order
        asserterror QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Sample Quantity", SpecificQty, '', '', Reason, CreditMemo, TempDummyPurchaseHeader);
        // [THEN] An error is expected indicating no purchase receipt line exists
        LibraryAssert.ExpectedError(StrSubstNo(NoPurchRcptLineErr, QltyInspectionHeader."Source Item No.", QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No."));
    end;

    [Test]
    procedure PurchaseReturn_NoInventoryFound_ShouldExit()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        BasicLocation: Record Location;
        FilterLocation: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ReturnOrderPurchaseHeader: Record "Purchase Header";
        DummyReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempDummyPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
        UnitCost: Decimal;
        BeforeCount: Integer;
    begin
        // [SCENARIO] Validate that no purchase return order is created when no inventory is found at the specified location

        Initialize();

        // [GIVEN] A basic warehouse location and a filter location are created
        LibraryWarehouse.CreateLocationWMS(BasicLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocation(FilterLocation);

        // [GIVEN] An untracked item is created
        UnitCost := LibraryRandom.RandDecInRange(1, 10, 2);
        QltyInspectionUtility.CreateUntrackedItem(Item, UnitCost, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order is created (not received to avoid inventory)
        QltyPurOrderGenerator.CreatePurchaseOrder(100, BasicLocation, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);

        // [GIVEN] A quality inspection template and generation rule are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with sample, pass, and fail quantities
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurOrdPurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Pass Quantity" := 3;
        QltyInspectionHeader."Fail Quantity" := 2;
        QltyInspectionHeader.Modify(false);

        // [GIVEN] A return reason code and credit memo number are prepared
        Reason := GetOrCreateReturnReasonCode();

        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] Specific quantity is set to 0
        SpecificQty := 0;

        QltyInspectionGenRule.Delete();

        // [GIVEN] The initial count of purchase return orders is recorded
        ReturnOrderPurchaseHeader.SetRange("Document Type", ReturnOrderPurchaseHeader."Document Type"::"Return Order");
        BeforeCount := ReturnOrderPurchaseHeader.Count();
        // [WHEN] Purchase return disposition is performed with a filter location that has no inventory
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Sample Quantity", SpecificQty, FilterLocation.Code, '', Reason, CreditMemo, TempDummyPurchaseHeader);
        // [THEN] No purchase return order is created
        LibraryAssert.AreEqual(BeforeCount, ReturnOrderPurchaseHeader.Count(), 'Should not have created a purchase return order');
    end;

    [Test]
    procedure NegativeAdjustment_NonDirectedPickWithBins_Tracked()
    var
        Location: Record Location;
        PickBin: Record Bin;
        Item: Record Item;
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NegativeAdjustItemJournalTemplate: Record "Item Journal Template";
        NegativeAdjustItemJournalBatch: Record "Item Journal Batch";
        NegativeAdjustmentItemJournalLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[50];
    begin
        // [SCENARIO] Validate negative inventory adjustment disposition for lot-tracked items in a bin location

        Initialize();

        // [GIVEN] Quality management setup is initialized with warehouse trigger disabled
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] An item journal template and batch are created for negative adjustments
        LibraryInventory.CreateItemJournalTemplateByType(NegativeAdjustItemJournalTemplate, NegativeAdjustItemJournalTemplate.Type::Item);

        LibraryInventory.CreateItemJournalBatch(NegativeAdjustItemJournalBatch, NegativeAdjustItemJournalTemplate.Name);
        QltyManagementSetup."Item Journal Batch Name" := NegativeAdjustItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Item with lot tracking is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A pick bin is selected from the location
        PickBin.SetRange("Location Code", Location.Code);

        PickBin.FindFirst();

        // [GIVEN] Initial journal lines are verified to be empty
        NegativeAdjustmentItemJournalLine.Reset();
        NegativeAdjustmentItemJournalLine.SetRange("Journal Template Name", NegativeAdjustItemJournalTemplate.Name);
        NegativeAdjustmentItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(0, NegativeAdjustmentItemJournalLine.Count(), 'test setup failed, should be 0 lines as an input..');

        // [GIVEN] An initial positive adjustment journal line is created for 10 units to establish inventory
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, NegativeAdjustItemJournalTemplate.Name, NegativeAdjustItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        NegativeAdjustmentItemJournalLine.Reset();
        NegativeAdjustmentItemJournalLine.SetRange("Journal Template Name", NegativeAdjustItemJournalTemplate.Name);
        NegativeAdjustmentItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, NegativeAdjustmentItemJournalLine.Count(), 'test setup failed, should be only 1 line.');

        // [GIVEN] Lot number is generated and journal line is updated with location and bin
        OriginalLotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        InitialInspectionInventoryJnlItemJournalLine.Validate("Location Code", Location.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Bin Code", PickBin.Code);
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        NegativeAdjustmentItemJournalLine.Reset();
        NegativeAdjustmentItemJournalLine.SetRange("Journal Template Name", NegativeAdjustItemJournalTemplate.Name);
        NegativeAdjustmentItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, NegativeAdjustmentItemJournalLine.Count(), 'test setup failed, should be only 1 line after a modify');

        // [GIVEN] Item tracking with lot number is assigned to the journal line
        ReUsedLibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', OriginalLotNo, InitialInspectionInventoryJnlItemJournalLine.Quantity);

        // [GIVEN] Item ledger entry filters are set up for validation
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Lot No.", OriginalLotNo);
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        // [GIVEN] Initial inventory journal is posted
        InitialInspectionInventoryJnlItemJournalLine.SetRecFilter();
        InitialInspectionInventoryJnlItemJournalLine.FindFirst();
        ItemJnlPostBatch.Run(InitialInspectionInventoryJnlItemJournalLine);

        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        InitialInspectionInventoryJnlItemJournalLine.Reset();
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Template Name", NegativeAdjustItemJournalTemplate.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.", Item."No.");
        InitialInspectionInventoryJnlItemJournalLine.SetFilter(Quantity, '<>0');
        LibraryAssert.AreEqual(0, InitialInspectionInventoryJnlItemJournalLine.Count(), 'test setup failed, 0 posted item journal lines should exist after posting.');

        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.");
        InitialInspectionInventoryJnlItemJournalLine.SetRange(Quantity);
        InitialInspectionInventoryJnlItemJournalLine.DeleteAll();

        // [GIVEN] Temporary inspection header is populated with item ledger entry and location information
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;

        // [GIVEN] Disposition buffer is configured with location, bin, and quantity details
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Negative adjustment disposition is performed
        LibraryAssert.AreEqual(true, QltyInspectionUtility.PerformNegAdjustInvDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer),
            'expected the negative adjustment to work.');

        // [THEN] One journal line is created in the negative adjustment batch
        NegativeAdjustmentItemJournalLine.Reset();
        NegativeAdjustmentItemJournalLine.SetRange(
            "Journal Batch Name",
            QltyManagementSetup."Item Journal Batch Name");
        LibraryAssert.AreEqual(1, NegativeAdjustmentItemJournalLine.Count(), 'There should be one journal line in the negative adjustment batch.');
        NegativeAdjustmentItemJournalLine.FindLast();

        // [THEN] One reservation entry is created with correct tracking and quantity
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", NegativeAdjustmentItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Source ID", NegativeAdjustItemJournalTemplate.Name);
        ReservationEntry.SetRange("Source Batch Name", NegativeAdjustItemJournalBatch.Name);

        NegativeAdjustItemJournalBatch.Delete();
        NegativeAdjustItemJournalTemplate.Delete();

        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created.');
        ReservationEntry.FindFirst();

        // [THEN] The reservation entry has correct item, location, lot, and quantity details
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalLotNo, ReservationEntry."Lot No.", 'The lot no. should match the original.');
        LibraryAssert.AreEqual(NegativeAdjustmentItemJournalLine.Quantity, -ReservationEntry.Quantity, 'The quantity should match the item journal line.');
        LibraryAssert.AreEqual(NegativeAdjustmentItemJournalLine."Quantity (Base)", -ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(InitialInspectionInventoryJnlItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');
    end;

    [Test]
    procedure NegativeAdjustment_DirectedPickFullWMS_Tracked()
    var
        AdvWhseLocation: Record Location;
        PickBin: Record Bin;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        InitialInventoryWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        InitialInventoryWarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        CheckCreatedJnlWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WarehouseEntry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[50];
    begin
        // [SCENARIO] Validate negative inventory adjustment disposition for lot-tracked items in a full warehouse management location

        Initialize();

        // [GIVEN] Quality management setup is initialized with warehouse trigger disabled
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] A full warehouse management location is created with directed put-away and pick
        LibraryWarehouse.CreateFullWMSLocation(AdvWhseLocation, 3);

        QltyInspectionUtility.SetCurrLocationWhseEmployee(AdvWhseLocation.Code);

        // [GIVEN] A warehouse journal template and batch are created for inventory adjustments
        LibraryWarehouse.CreateWhseJournalTemplate(InitialInventoryWhseItemWarehouseJournalTemplate, InitialInventoryWhseItemWarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(InitialInventoryWarehouseJournalBatch, InitialInventoryWhseItemWarehouseJournalTemplate.Name, AdvWhseLocation.Code);

        QltyManagementSetup."Whse. Item Journal Batch Name" := InitialInventoryWarehouseJournalBatch.Name;

        // [GIVEN] Quality management setup is updated with warehouse adjustment batch
        QltyManagementSetup.Modify();

        // [GIVEN] Lot tracking is created with number series and item tracking code
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        ReUsedLibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Bin contents are created for all bins in the location
        PickBin.SetRange("Location Code", AdvWhseLocation.Code);
        if PickBin.FindSet() then
            repeat
                LibraryWarehouse.CreateBinContent(BinContent, AdvWhseLocation.Code, PickBin."Zone Code", PickBin.Code, Item."No.", '', Item."Base Unit of Measure");
            until PickBin.Next() = 0;

        // [GIVEN] A pick bin is selected from the PICK zone
        PickBin.SetRange("Location Code", AdvWhseLocation.Code);
        PickBin.SetRange("Zone Code", 'PICK');
        PickBin.FindFirst();

        // [GIVEN] Lot number is generated and inspection header is prepared
        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        TempQltyInspectionHeader."No." := 'initialinventory';
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyDispositionBuffer."Location Filter" := AdvWhseLocation.Code;
        TempQltyDispositionBuffer."Bin Filter" := AdvWhseLocation."Adjustment Bin Code";
        TempQltyDispositionBuffer."New Bin Code" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 100;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [GIVEN] Initial warehouse journal line is created and posted
        QltyInspectionUtility.CreateWarehouseJournalLine(TempQltyInspectionHeader, TempQltyDispositionBuffer, InitialInventoryWarehouseJournalBatch, WhseItemWarehouseJournalLine, CheckCreatedJnlWhseItemTrackingLine);
        LibraryAssert.AreEqual(true, QltyInspectionUtility.PostWarehouseJournal(TempQltyInspectionHeader, TempQltyDispositionBuffer, WhseItemWarehouseJournalLine),
            'ensure the initial inventory journal posted.');

        WarehouseEntry.SetRange("Location Code", AdvWhseLocation.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Bin Code", TempQltyDispositionBuffer."New Bin Code");
        WarehouseEntry.SetRange("Lot No.", OriginalLotNo);

        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Sanity check on inventory creation prior to the actual test.');
        WarehouseEntry.FindFirst();

        // [GIVEN] Warehouse journal is verified to be empty after posting initial inventory
        WhseItemWarehouseJournalLine.Reset();
        WhseItemWarehouseJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Whse. Item Journal Batch Name");
        WhseItemWarehouseJournalLine.SetFilter("Item No.", '<>''''');
        LibraryAssert.AreEqual(0, WhseItemWarehouseJournalLine.Count(), 'The warehouse journal should be empty after posting the initial inventory.');

        // [GIVEN] Inspection header is configured with warehouse entry source
        TempQltyInspectionHeader."Source RecordId" := WarehouseEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Warehouse Entry";
        TempQltyInspectionHeader."Location Code" := AdvWhseLocation.Code;

        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyDispositionBuffer."Location Filter" := TempQltyInspectionHeader."Location Code";
        TempQltyDispositionBuffer."Bin Filter" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Negative adjustment disposition is performed for the warehouse
        LibraryAssert.AreEqual(true, QltyInspectionUtility.PerformNegAdjustInvDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer),
            'expected the negative adjustment to work.');

        // [THEN] One warehouse journal line is created in the adjustment batch
        WhseItemWarehouseJournalLine.Reset();
        WhseItemWarehouseJournalLine.SetRange(
            "Journal Batch Name",
            QltyManagementSetup."Whse. Item Journal Batch Name");
        WhseItemWarehouseJournalLine.SetFilter("Item No.", '<>''''');

        InitialInventoryWarehouseJournalBatch.Delete();
        InitialInventoryWhseItemWarehouseJournalTemplate.Delete();

        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine.Count(), 'There should be one warehouse journal line in the negative adjustment batch.');
        WhseItemWarehouseJournalLine.FindLast();

        // [THEN] One warehouse item tracking line is created for the journal
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Batch Name", WhseItemWarehouseJournalLine."Journal Template Name");
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine.Count(), 'There should be one reservation entry created.');
        CheckCreatedJnlWhseItemTrackingLine.FindFirst();

        // [THEN] The tracking line has correct item, location, lot, and quantity details
        LibraryAssert.AreEqual(Item."No.", CheckCreatedJnlWhseItemTrackingLine."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(AdvWhseLocation.Code, CheckCreatedJnlWhseItemTrackingLine."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalLotNo, CheckCreatedJnlWhseItemTrackingLine."Lot No.", 'The lot no. should match the original.');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine.Quantity, 'The quantity should match the item journal line.');
    end;

    [Test]
    procedure CreateNegativeAdjustment_NonDirectedWithBins_Untracked()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReasonCode: Record "Reason Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        AdjustmentItemJournalLine: Record "Item Journal Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ReasonCodeToTest: Text;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Create a negative inventory adjustment for untracked items in a bin location

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template and rule are created
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A warehouse location with bins but without directed put-away is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, released, and received with bin specified
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created from the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A reason code is generated and created
        QltyInspectionUtility.GenerateRandomCharacters(20, ReasonCodeToTest);
        ReasonCode.Init();
        ReasonCode.Validate(Code, CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Code)));
        ReasonCode.Description := CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Description));
        ReasonCode.Insert();

        // [GIVEN] An item journal template and batch are created for adjustments
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        QltyManagementSetup.Get();
        QltyManagementSetup."Item Journal Batch Name" := ItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        QltyInspectionGenRule.Delete();

        // [WHEN] Negative adjustment disposition is performed with specific quantity
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::"Prepare only", ReasonCode.Code), 'Should have created negative adjustment');

        AdjustmentItemJournalLine.Get(ItemJournalTemplate.Name, ItemJournalBatch.Name, 10000);

        // [THEN] A negative adjustment journal line is created with correct item, location, quantity, and reason code
        LibraryAssert.AreEqual(AdjustmentItemJournalLine."Entry Type"::"Negative Adjmt.", AdjustmentItemJournalLine."Entry Type", 'Adjustment line should be negative.');
        LibraryAssert.AreEqual(QltyInspectionHeader."Source Item No.", AdjustmentItemJournalLine."Item No.", 'Adjustment line should be for correct item.');
        LibraryAssert.AreEqual(QltyInspectionHeader."Location Code", AdjustmentItemJournalLine."Location Code", 'Adjustment line should be for correct location.');
        LibraryAssert.AreEqual(50, AdjustmentItemJournalLine.Quantity, 'Adjustment line should be for correct quantity');
        LibraryAssert.AreEqual(ReasonCode.Code, AdjustmentItemJournalLine."Reason Code", 'Adjustment line should have provided reason code.');

        ItemJournalBatch.Delete();
        ItemJournalTemplate.Delete();
    end;

    [Test]
    procedure CreateNegativeAdjustment_Directed_Untracked()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReasonCode: Record "Reason Code";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        AdjustmentWarehouseJournalLine: Record "Warehouse Journal Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ReasonCodeToTest: Text;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Create a negative inventory adjustment for untracked items in a directed put-away location

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template is created for warehouse entries
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry");

        // [GIVEN] A full warehouse management location with directed put-away is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] An untracked item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A warehouse entry is found and a quality inspection is created from it
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A reason code is generated and created
        QltyInspectionUtility.GenerateRandomCharacters(20, ReasonCodeToTest);
        ReasonCode.Init();
        ReasonCode.Validate(Code, CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Code)));
        ReasonCode.Description := CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Description));
        ReasonCode.Insert();

        // [GIVEN] A warehouse journal template and batch are created for adjustments
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Item Journal Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Negative adjustment disposition is performed with specific quantity
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::"Prepare only", ReasonCode.Code), 'Should have created negative adjustment');

        QltyInspectionGenRule.DeleteAll();
        WarehouseJournalBatch.Delete();
        WarehouseJournalTemplate.Delete();

        AdjustmentWarehouseJournalLine.Get(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code, 10000);

        // [THEN] A negative warehouse adjustment journal line is created with correct item, location, quantity, and reason code
        LibraryAssert.AreEqual(AdjustmentWarehouseJournalLine."Entry Type"::"Negative Adjmt.", AdjustmentWarehouseJournalLine."Entry Type", 'Adjustment line should be negative.');
        LibraryAssert.AreEqual(QltyInspectionHeader."Source Item No.", AdjustmentWarehouseJournalLine."Item No.", 'Adjustment line should be for correct item.');
        LibraryAssert.AreEqual(QltyInspectionHeader."Location Code", AdjustmentWarehouseJournalLine."Location Code", 'Adjustment line should be for correct location.');
        LibraryAssert.AreEqual(50, AdjustmentWarehouseJournalLine.Quantity, 'Adjustment line should be for correct quantity');
        LibraryAssert.AreEqual(ReasonCode.Code, AdjustmentWarehouseJournalLine."Reason Code", 'Adjustment line should have provided reason code.');
    end;

    [Test]
    procedure CreateNegativeAdjustment_Directed_Tracked_MultipleBins()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        Bin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReasonCode: Record "Reason Code";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        AdjustmentWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWarehouseJournalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ReasonCodeToTest: Text;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Create negative warehouse adjustments for lot-tracked items split across multiple bins

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template is created for purchase lines
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr);

        // [GIVEN] A full warehouse management location with directed put-away is created
        // [GIVEN] A full warehouse management location with directed put-away is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, PurOrdReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created with purchase line and item tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurOrdReservationEntry, QltyInspectionHeader);

        // [GIVEN] A warehouse entry is found for the received items
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", PurOrdReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        // [GIVEN] A warehouse reclassification journal is created to split items across multiple bins
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWarehouseJournalTemplate, ReclassWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] A warehouse employee is set for the current location and reclassification journal line is created to move items to another bin
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        QltyInspectionUtility.CreateReclassWhseJournalLine(ReclassWarehouseJournalLine, ReclassWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code,
            WarehouseEntry."Zone Code", WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."Entry Type"::Movement, Item."No.", 50);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        ReclassWarehouseJournalLine."From Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."From Bin Code" := ReclassWarehouseJournalLine."Bin Code";
        ReclassWarehouseJournalLine."To Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."To Bin Code" := Bin.Code;
        ReclassWarehouseJournalLine."Lot No." := PurOrdReservationEntry."Lot No.";
        ReclassWarehouseJournalLine."New Lot No." := ReclassWarehouseJournalLine."Lot No.";
        ReclassWarehouseJournalLine.Modify();

        ReUsedLibraryItemTracking.CreateWhseJournalLineItemTracking(ReclassWarehouseJournalWhseItemTrackingLine, ReclassWarehouseJournalLine, '', PurOrdReservationEntry."Lot No.", 50);
        ReclassWarehouseJournalWhseItemTrackingLine."New Lot No." := ReclassWarehouseJournalWhseItemTrackingLine."Lot No.";
        ReclassWarehouseJournalWhseItemTrackingLine.Modify();

        LibraryWarehouse.RegisterWhseJournalLine(ReclassWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code, true);

        // [GIVEN] A reason code is generated and created
        QltyInspectionUtility.GenerateRandomCharacters(20, ReasonCodeToTest);
        ReasonCode.Init();
        ReasonCode.Validate(Code, CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Code)));
        ReasonCode.Description := CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Description));
        ReasonCode.Insert();

        // [GIVEN] A warehouse journal template and batch are created for adjustments
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Item Journal Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Negative adjustment disposition is performed for item tracked quantity
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 0, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity", '', '', QltyItemAdjPostBehavior::"Prepare only", ReasonCode.Code), 'Should have created negative adjustment');

        QltyInspectionGenRule.DeleteAll();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWarehouseJournalTemplate.Delete();
        WarehouseJournalBatch.Delete();
        WarehouseJournalTemplate.Delete();

        AdjustmentWarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        AdjustmentWarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        AdjustmentWarehouseJournalLine.SetRange("Location Code", Location.Code);
        AdjustmentWarehouseJournalLine.SetRange("Item No.", Item."No.");
        AdjustmentWarehouseJournalLine.SetRange("Reason Code", ReasonCode.Code);
        AdjustmentWarehouseJournalLine.SetRange(Quantity, 50);

        // [THEN] Two adjustment lines are created, one for each bin containing the tracked items
        LibraryAssert.AreEqual(2, AdjustmentWarehouseJournalLine.Count(), 'There should be 2 adjustment lines created.');
    end;

    [Test]
    procedure CreateNegativeAdjustment_NonDirectedWithBins_Tracked_Post()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReasonCode: Record "Reason Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ReasonCodeToTest: Text;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Post a negative inventory adjustment for lot-tracked items in a bin location

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template is created for purchase lines
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A warehouse location with bins is created (non-directed)
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created with a specific bin, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, PurOrdReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created with purchase line and item tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, PurOrdReservationEntry, QltyInspectionHeader);

        // [GIVEN] A reason code is generated and created
        QltyInspectionUtility.GenerateRandomCharacters(20, ReasonCodeToTest);
        ReasonCode.Init();
        ReasonCode.Validate(Code, CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Code)));
        ReasonCode.Description := CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Description));
        ReasonCode.Insert();

        // [GIVEN] An item journal template and batch are created for adjustments
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        QltyManagementSetup.Get();
        QltyManagementSetup."Item Journal Batch Name" := ItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Negative adjustment disposition is performed and posted with specific quantity
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::Post, ReasonCode.Code), 'Should have posted negative adjustment');

        QltyInspectionGenRule.Delete();
        ItemJournalBatch.Delete();
        ItemJournalTemplate.Delete();

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", PurOrdReservationEntry."Lot No.");
        ItemLedgerEntry.SetRange(Quantity, -50);

        // [THEN] One negative adjustment item ledger entry is posted
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'Should have posted one negative adjustment.');
    end;

    [Test]
    procedure CreateNegativeAdjustment_Directed_Tracked_Register()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReasonCode: Record "Reason Code";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ReasonCodeToTest: Text;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Register a warehouse negative adjustment for lot-tracked items in a directed location

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template is created for warehouse entries
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry");

        // [GIVEN] A full warehouse management location with directed put-away is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, PurOrdReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A warehouse entry is found and a quality inspection is created from it with tracking
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, PurOrdReservationEntry, QltyInspectionHeader);

        // [GIVEN] A reason code is generated and created
        QltyInspectionUtility.GenerateRandomCharacters(20, ReasonCodeToTest);
        ReasonCode.Init();
        ReasonCode.Validate(Code, CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Code)));
        ReasonCode.Description := CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Description));
        ReasonCode.Insert();

        // [GIVEN] A warehouse journal template and batch are created for adjustments
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Item Journal Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Negative adjustment disposition is performed and registered with specific quantity
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::Post, ReasonCode.Code), 'Should have registered negative adjustment');

        QltyInspectionGenRule.DeleteAll();
        WarehouseJournalBatch.Delete();
        WarehouseJournalTemplate.Delete();

        Clear(WarehouseEntry);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Zone Code", 'ADJUSTMENT');
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange(Quantity, 50);

        // [THEN] A warehouse entry is created in the adjustment bin with the correct quantity
        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Should have adjustment in adjustment bin.');
    end;

    [Test]
    procedure CreateNegativeAdjustmentWithTrackedQty_Untracked_ShouldErr()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Raise an error when attempting item tracked quantity disposition on untracked items

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template is created for warehouse entries
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full warehouse management location with directed put-away is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] An untracked item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A warehouse entry is found and a quality inspection is created from it
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [WHEN] Negative adjustment disposition is performed with Item Tracked Quantity behavior on untracked item
        asserterror QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity", '', '', QltyItemAdjPostBehavior::Post, '');

        // [THEN] An error is raised indicating the entire lot must be written off
        LibraryAssert.ExpectedError(StrSubstNo(WriteOffEntireItemTrackingErr, QltyInspectionHeader.GetFriendlyIdentifier()));
    end;

    [Test]
    procedure CreateNegativeAdjustment_NoInventoryFound_ShouldExit()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        FilterLocation: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Exit without creating adjustment lines when no inventory is found at the filtered location

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template is created for purchase lines
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A full warehouse management location and a separate filter location are created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        LibraryWarehouse.CreateLocation(FilterLocation);

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created and released but not received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] A quality inspection is created with the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A warehouse journal template and batch are created for adjustments
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Item Journal Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [WHEN] Negative adjustment disposition is performed with a location filter where no inventory exists
        QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", FilterLocation.Code, '', QltyItemAdjPostBehavior::"Prepare only", '');

        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);

        // [THEN] No adjustment journal line is created
        LibraryAssert.IsTrue(WarehouseJournalLine.IsEmpty(), 'No adjustment line should have been created');

        QltyInspectionGenRule.Delete();
        WarehouseJournalBatch.Delete();
        WarehouseJournalTemplate.Delete();
    end;

    [Test]
    procedure CreateNegativeAdjustment_NonDirected_NoBatchInSetup_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Raise an error when adjustment batch is not configured for non-directed location

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template is created for purchase lines
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A warehouse location with bins is created (non-directed)
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created with a specific bin, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created with the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [GIVEN] The Item Journal Batch Name is cleared from quality management setup
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Journal Batch Name" := '';
        QltyManagementSetup.Modify();

        // [WHEN] Negative adjustment disposition is performed without adjustment batch configured
        asserterror QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::"Prepare only", '');

        // [THEN] An error is raised indicating the adjustment batch is missing
        LibraryAssert.ExpectedError(MissingAdjBatchErr);
    end;

    [Test]
    procedure CreateNegativeAdjustment_Directed_NoBatchInSetup_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Raise an error when warehouse adjustment batch is not configured for directed location

        Initialize();

        // [GIVEN] Quality management setup is initialized and an inspection template is created for warehouse entries
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full warehouse management location with directed put-away is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A warehouse entry is found and a quality inspection is created from it
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [GIVEN] The warehouse Item Journal Batch Name is cleared from quality management setup
        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Item Journal Batch Name" := '';
        QltyManagementSetup.Modify();

        // [WHEN] Negative adjustment disposition is performed without warehouse adjustment batch configured
        asserterror QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::"Prepare only", '');

        // [THEN] An error is raised indicating the adjustment batch is missing
        LibraryAssert.ExpectedError(MissingAdjBatchErr);
    end;

    [Test]
    procedure CreateNegativeAdjustment_NonDirected_CantFindBatch_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Validate that an error is raised when the configured item journal batch cannot be found in a non-directed location

        // [GIVEN] Quality management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();
        // [GIVEN] An inspection template and generation rule for purchase lines are created
        // [GIVEN] An inspection template and generation rule for purchase lines are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Three bins are created for the location
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, released, and received with a bin assignment
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] All item journal templates are deleted and then recreated with a batch
        ItemJournalTemplate.DeleteAll();
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        QltyManagementSetup.Get();
        QltyManagementSetup."Item Journal Batch Name" := ItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] The inspection generation rule and journal batch are then deleted to trigger the error condition
        QltyInspectionGenRule.Delete();
        ItemJournalBatch.Delete();

        // [WHEN] Negative adjustment disposition is attempted
        asserterror QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::"Prepare only", '');
        // [THEN] An error is raised indicating the journal batch cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(CannotGetJournalBatchErr, ItemJournalTemplate.Name, QltyManagementSetup."Item Journal Batch Name", ''));
    end;

    [Test]
    procedure CreateNegativeAdjustment_Directed_CantFindBatch_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Validate that an error is raised when the configured warehouse adjustment batch cannot be found in a directed location

        // [GIVEN] Quality management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();
        // [GIVEN] An inspection template and generation rule for purchase lines
        // [GIVEN] An inspection template and generation rule for purchase lines
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A full WMS location is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created and released
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] All warehouse journal templates are deleted and then recreated
        WarehouseJournalTemplate.DeleteAll();

        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Item Journal Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] The inspection generation rule and journal batch are then deleted to trigger the error condition
        QltyInspectionGenRule.Delete();
        WarehouseJournalBatch.Delete();

        // [WHEN] Negative adjustment disposition is performed
        asserterror QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::"Prepare only", '');
        // [THEN] An error is raised indicating the journal batch cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(CannotGetJournalBatchErr, WarehouseJournalTemplate.Name, QltyManagementSetup."Whse. Item Journal Batch Name", StrSubstNo(LocationTok, Location.Code)));
    end;

    [Test]
    procedure ChangeLotDisposition_NonDirectedPickWithBins()
    var
        Location: Record Location;
        PickBin: Record Bin;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InitialInventoryItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        NegativeAdjustItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInventoryItemJournalLine: Record "Item Journal Line";
        ChangeLotNumberItemJournalLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[50];
        NewLotNo: Code[50];
    begin
        // [SCENARIO] Change lot number for items in a non-directed pick location with bins

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Item journal templates and batches are created for adjustments and reclassification
        LibraryInventory.CreateItemJournalTemplateByType(InitialInventoryItemJournalTemplate, InitialInventoryItemJournalTemplate.Type::Item);

        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);

        LibraryInventory.CreateItemJournalBatch(NegativeAdjustItemJournalBatch, InitialInventoryItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        ReclassItemJournalBatch.CalcFields("Template Type");
        NegativeAdjustItemJournalBatch.CalcFields("Template Type");

        QltyManagementSetup."Item Journal Batch Name" := NegativeAdjustItemJournalBatch.Name;
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Lot tracking is created with number series and item tracking code
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        ReUsedLibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Non-directed pick location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A pick bin is identified from the location
        PickBin.SetRange("Location Code", Location.Code);
        PickBin.FindFirst();

        // [GIVEN] Initial inventory journal lines are verified to be empty before test setup
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(0, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be 0 lines as an input..');

        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, InitialInventoryItemJournalTemplate.Name, NegativeAdjustItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line.');

        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        NewLotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Location Code", Location.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Bin Code", PickBin.Code);
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line after a modify');

        // [GIVEN] Item tracking with original lot number is assigned to the journal line
        ReUsedLibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', OriginalLotNo, InitialInspectionInventoryJnlItemJournalLine.Quantity);

        // [GIVEN] Item ledger entry filters are set up and journal is posted
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Lot No.", OriginalLotNo);
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        InitialInspectionInventoryJnlItemJournalLine.SetRecFilter();
        InitialInspectionInventoryJnlItemJournalLine.FindFirst();
        ItemJnlPostBatch.Run(InitialInspectionInventoryJnlItemJournalLine);

        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        InitialInspectionInventoryJnlItemJournalLine.Reset();
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.", Item."No.");
        InitialInspectionInventoryJnlItemJournalLine.SetFilter(Quantity, '<>0');
        LibraryAssert.AreEqual(0, InitialInspectionInventoryJnlItemJournalLine.Count(), 'test setup failed, 0 posted item journal lines should exist after posting.');

        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.");
        InitialInspectionInventoryJnlItemJournalLine.SetRange(Quantity);
        InitialInspectionInventoryJnlItemJournalLine.DeleteAll();

        // [GIVEN] Temporary inspection header is populated with item ledger entry, location, and original lot number
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;

        // [GIVEN] Disposition buffer is configured with new lot number, location, bin, and quantity details
        TempQltyDispositionBuffer."New Lot No." := NewLotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to change the lot number
        LibraryAssert.AreEqual(true, QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer),
            'expected the adjustment to work.');

        // [THEN] One journal line is created in the bin move batch
        ChangeLotNumberItemJournalLine.Reset();
        ChangeLotNumberItemJournalLine.SetRange(
            "Journal Batch Name",
            QltyManagementSetup."Item Reclass. Batch Name");

        LibraryAssert.AreEqual(1, ChangeLotNumberItemJournalLine.Count(),
        'There should be one journal line in the change lot adjustment batch.');
        ChangeLotNumberItemJournalLine.FindLast();

        // [THEN] One reservation entry is created for the lot change
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ChangeLotNumberItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");

        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created for this item in this test.');
        ReservationEntry.FindFirst();

        // [THEN] Journal line and reservation entry values match expected tracking change
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalLotNo, ReservationEntry."Lot No.", 'The lot no. should match the original.');
        LibraryAssert.AreEqual(NewLotNo, ReservationEntry."New Lot No.", 'The new lot no. should match the request');
        LibraryAssert.AreEqual(ChangeLotNumberItemJournalLine."Bin Code", ChangeLotNumberItemJournalLine."New Bin Code", 'the bin codes should match. Found by QA earlier.');
        LibraryAssert.AreEqual(6, ChangeLotNumberItemJournalLine.Quantity, 'The quantity should match the requested amount.');
        LibraryAssert.AreEqual(ChangeLotNumberItemJournalLine."Quantity (Base)", -1 * ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(ChangeLotNumberItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');

        ChangeLotNumberItemJournalLine.Delete();
        NegativeAdjustItemJournalBatch.Delete();
        ReclassItemJournalBatch.Delete();
        InitialInventoryItemJournalTemplate.Delete();
    end;

    [Test]
    procedure ChangeLotDisposition_DirectedPickAndPut()
    var
        Location: Record Location;
        AnyBin: Record Bin;
        PickBin: Record Bin;
        InitialInventoryWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        CheckCreatedJnlWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        BinContent: Record "Bin Content";
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        WarehouseEntry: Record "Warehouse Entry";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        InitialInventoryWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[50];
        NewLotNo: Code[50];
    begin
        // [SCENARIO] Change lot number for items in a full WMS location with directed pick and put

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Lot number series and item tracking code are created for lot tracking
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        ReUsedLibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Full WMS location is created with bins and bin content for the item
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        AnyBin.SetRange("Location Code", Location.Code);
        if AnyBin.FindSet() then
            repeat
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, AnyBin."Zone Code", AnyBin.Code, Item."No.", '', Item."Base Unit of Measure");
            until AnyBin.Next() = 0;
        PickBin.SetRange("Location Code", Location.Code);
        PickBin.SetRange("Zone Code", 'PICK');
        PickBin.FindFirst();

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Warehouse journal templates and batches are created for adjustments and reclassification
        LibraryWarehouse.CreateWhseJournalTemplate(InitialInventoryWhseItemWarehouseJournalTemplate, InitialInventoryWhseItemWarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(InitialInventoryWarehouseJournalBatch, InitialInventoryWhseItemWarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup."Whse. Item Journal Batch Name" := InitialInventoryWarehouseJournalBatch.Name;

        // [GIVEN] Reclassification warehouse journal template and batch are created
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Original and new lot numbers are generated
        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        NewLotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        // [GIVEN] Initial warehouse inventory is created with original lot number and posted
        TempQltyInspectionHeader."No." := 'initialinventory';
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := Location."Adjustment Bin Code";
        TempQltyDispositionBuffer."New Bin Code" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 100;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [GIVEN] Initial warehouse journal line is created and posted
        QltyInspectionUtility.CreateWarehouseJournalLine(TempQltyInspectionHeader, TempQltyDispositionBuffer, InitialInventoryWarehouseJournalBatch, WhseItemWarehouseJournalLine, CheckCreatedJnlWhseItemTrackingLine);
        QltyInspectionUtility.PostWarehouseJournal(TempQltyInspectionHeader, TempQltyDispositionBuffer, WhseItemWarehouseJournalLine);

        // [GIVEN] Warehouse entry is verified for the posted inventory
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Bin Code", TempQltyDispositionBuffer."New Bin Code");
        WarehouseEntry.SetRange("Lot No.", OriginalLotNo);

        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Sanity check on inventory creation prior to the actual test.');
        WarehouseEntry.FindFirst();

        // [GIVEN] Temporary inspection header is populated with warehouse entry and tracking information
        TempQltyInspectionHeader."Source RecordId" := WarehouseEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Warehouse Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := WarehouseEntry."Bin Code";
        TempQltyDispositionBuffer."New Lot No." := NewLotNo;

        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to change the lot number
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        InitialInventoryWarehouseJournalBatch.Delete();
        InitialInventoryWhseItemWarehouseJournalTemplate.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();

        // [THEN] One warehouse journal line is created in the reclassification batch
        WhseItemWarehouseJournalLine.Reset();
        WhseItemWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        WhseItemWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine.Count(), 'warehouse journal Line should have been created.');
        WhseItemWarehouseJournalLine.FindFirst();

        // [THEN] Warehouse journal line has matching bin codes and correct quantities
        LibraryAssert.AreEqual(WhseItemWarehouseJournalLine."From Bin Code", WhseItemWarehouseJournalLine."To Bin Code", 'with item tracking changes, the bins must match.');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine."Qty. (Base)", 'base quantity should match');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine.Quantity, 'quantity should match');

        // [THEN] Warehouse item tracking line is created with correct lot tracking information
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source ID", ReclassWarehouseJournalBatch.Name);
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Batch Name", ReclassWarehouseJournalBatch."Journal Template Name");
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine.Count(), 'Tracking Line should have been created.');
        CheckCreatedJnlWhseItemTrackingLine.FindFirst();

        // [THEN] Item tracking line has correct lot numbers and quantities
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Subtype" = 0, 'Tracking Line should have subtype 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Prod. Order Line" = 0, 'Tracking Line should have Source Prod. Order Line 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Qty. per Unit of Measure" = 1, 'Should have Qty. per Unit of Measure = 1');
        LibraryAssert.AreEqual(OriginalLotNo, CheckCreatedJnlWhseItemTrackingLine."Lot No.", 'Lot No. should match provided lot no.');
        LibraryAssert.AreEqual(NewLotNo, CheckCreatedJnlWhseItemTrackingLine."New Lot No.", 'Lot No. should match provided lot no.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Quantity (Base)", 'Quantity (Base) should match.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle (Base)", 'Quantity to Handle (Base) should match.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle", 'Quantity to Handle should match.');
    end;

    [Test]
    procedure ChangeSerialDisposition_NonDirectedPickWithBins()
    var
        Location: Record Location;
        PickBin: Record Bin;
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InitialInventoryItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        NegativeAdjustItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInventoryItemJournalLine: Record "Item Journal Line";
        ChangeSerialNumberItemJournalLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        NoSeries: Codeunit "No. Series";
        OriginalSerialNo: Code[50];
        NewSerialNo: Code[50];
    begin
        // [SCENARIO] Change serial number for items in a non-directed pick location with bins

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Item journal templates and batches are created for adjustments and reclassification
        LibraryInventory.CreateItemJournalTemplateByType(InitialInventoryItemJournalTemplate, InitialInventoryItemJournalTemplate.Type::Item);

        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);

        LibraryInventory.CreateItemJournalBatch(NegativeAdjustItemJournalBatch, InitialInventoryItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        ReclassItemJournalBatch.CalcFields("Template Type");
        NegativeAdjustItemJournalBatch.CalcFields("Template Type");

        QltyManagementSetup."Item Journal Batch Name" := NegativeAdjustItemJournalBatch.Name;
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Serial number series and item tracking code are created for serial tracking
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        ReUsedLibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, true, false, false);
        LibraryInventory.CreateTrackedItem(Item, '', SerialNoSeries.Code, SerialItemTrackingCode.Code);

        // [GIVEN] Non-directed pick location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] Pick bin is created and identified
        PickBin.SetRange("Location Code", Location.Code);

        PickBin.FindFirst();

        // [GIVEN] Initial inventory journal line is created with positive adjustment and serial tracking
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(0, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be 0 lines as an input..');

        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, InitialInventoryItemJournalTemplate.Name, NegativeAdjustItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line.');

        OriginalSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        NewSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Location Code", Location.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Bin Code", PickBin.Code);
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line after a modify');

        // [GIVEN] Item tracking with original serial number is assigned to the journal line
        ReUsedLibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, OriginalSerialNo, '', InitialInspectionInventoryJnlItemJournalLine.Quantity);

        // [GIVEN] Item ledger entry filters are set up and journal is posted
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Serial No.", OriginalSerialNo);
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        InitialInspectionInventoryJnlItemJournalLine.SetRecFilter();
        InitialInspectionInventoryJnlItemJournalLine.FindFirst();
        ItemJnlPostBatch.Run(InitialInspectionInventoryJnlItemJournalLine);

        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        InitialInspectionInventoryJnlItemJournalLine.Reset();
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.", Item."No.");
        InitialInspectionInventoryJnlItemJournalLine.SetFilter(Quantity, '<>0');
        LibraryAssert.AreEqual(0, InitialInspectionInventoryJnlItemJournalLine.Count(), 'test setup failed, 0 posted item journal lines should exist after posting.');

        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.");
        InitialInspectionInventoryJnlItemJournalLine.SetRange(Quantity);
        InitialInspectionInventoryJnlItemJournalLine.DeleteAll();

        // [GIVEN] Temporary inspection header is populated with item ledger entry and serial tracking information
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;

        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Serial No." := OriginalSerialNo;
        TempQltyDispositionBuffer."New Serial No." := NewSerialNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 1;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to change the serial number
        LibraryAssert.AreEqual(true, QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer),
            'expected the adjustment to work.');

        // [THEN] One journal line is created in the bin move batch
        ChangeSerialNumberItemJournalLine.Reset();
        ChangeSerialNumberItemJournalLine.SetRange(
            "Journal Batch Name",
            QltyManagementSetup."Item Reclass. Batch Name");

        LibraryAssert.AreEqual(1, ChangeSerialNumberItemJournalLine.Count(),
        'There should be one journal line in the change serial adjustment batch.');
        ChangeSerialNumberItemJournalLine.FindLast();

        // [THEN] One reservation entry is created for the serial change
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ChangeSerialNumberItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");

        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created for this item in this test.');
        ReservationEntry.FindFirst();

        // [THEN] Journal line and reservation entry values match expected serial tracking change
        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalSerialNo, ReservationEntry."Serial No.", 'The serial no. should match the original.');
        LibraryAssert.AreEqual(NewSerialNo, ReservationEntry."New Serial No.", 'The new serial no. should match the request');
        LibraryAssert.AreEqual(ChangeSerialNumberItemJournalLine."Bin Code", ChangeSerialNumberItemJournalLine."New Bin Code", 'the bin codes should match. Found by QA earlier.');
        LibraryAssert.AreEqual(1, ChangeSerialNumberItemJournalLine.Quantity, 'The quantity should match the requested amount.');
        LibraryAssert.AreEqual(ChangeSerialNumberItemJournalLine."Quantity (Base)", -1 * ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(ChangeSerialNumberItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');

        ReservationEntry.Delete();
        ChangeSerialNumberItemJournalLine.Delete();
        NegativeAdjustItemJournalBatch.Delete();
        ReclassItemJournalBatch.Delete();
        InitialInventoryItemJournalTemplate.Delete();
    end;

    [Test]
    procedure ChangeSerialDisposition_DirectedPickAndPut()
    var
        Location: Record Location;
        AnyBin: Record Bin;
        PickBin: Record Bin;
        InitialInventoryWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        CheckCreatedJnlWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        BinContent: Record "Bin Content";
        Item: Record Item;
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        WarehouseEntry: Record "Warehouse Entry";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        InitialInventoryWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        OriginalSerialNo: Code[50];
        NewSerialNo: Code[50];
    begin
        // [SCENARIO] Change serial number for items in a full WMS location with directed pick and put

        // [GIVEN] Quality management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Warehouse trigger is set to NoTrigger
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Serial number series is created
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);

        // [GIVEN] Serial number series line is created with date-based numbering
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Item tracking code is created for serial tracking
        ReUsedLibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, true, false, false);

        // [GIVEN] Serial-tracked item is created with item tracking code
        LibraryInventory.CreateTrackedItem(Item, '', SerialNoSeries.Code, SerialItemTrackingCode.Code);

        // [GIVEN] Full WMS location with directed put-away and pick is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Bin content is created for all bins in the location
        AnyBin.SetRange("Location Code", Location.Code);
        if AnyBin.FindSet() then
            repeat
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, AnyBin."Zone Code", AnyBin.Code, Item."No.", '', Item."Base Unit of Measure");
            until AnyBin.Next() = 0;

        // [GIVEN] A pick bin is selected from the PICK zone
        PickBin.SetRange("Location Code", Location.Code);
        PickBin.SetRange("Zone Code", 'PICK');
        PickBin.FindFirst();

        // [GIVEN] Warehouse employee is set for the location
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Warehouse journal template is created for item adjustments
        LibraryWarehouse.CreateWhseJournalTemplate(InitialInventoryWhseItemWarehouseJournalTemplate, InitialInventoryWhseItemWarehouseJournalTemplate.Type::Item);

        // [GIVEN] Warehouse journal batch is created for initial inventory adjustments
        LibraryWarehouse.CreateWhseJournalBatch(InitialInventoryWarehouseJournalBatch, InitialInventoryWhseItemWarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] Quality management setup is configured with warehouse adjustment batch
        QltyManagementSetup."Whse. Item Journal Batch Name" := InitialInventoryWarehouseJournalBatch.Name;

        // [GIVEN] Warehouse journal template is created for reclassification
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);

        // [GIVEN] Warehouse journal batch is created for bin reclassification moves
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] Quality management setup is configured with Item Reclass. Batch Name
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Original serial number is generated for initial inventory
        OriginalSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);

        // [GIVEN] New serial number is generated for disposition change
        NewSerialNo := NoSeries.GetNextNo(SerialNoSeries.Code);

        // [GIVEN] Temporary inspection header is prepared for initial inventory setup
        TempQltyInspectionHeader."No." := 'initialinventory';
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Serial No." := OriginalSerialNo;

        // [GIVEN] Disposition buffer is configured to move items from adjustment bin to pick bin
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := Location."Adjustment Bin Code";
        TempQltyDispositionBuffer."New Bin Code" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 1;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [GIVEN] Warehouse journal line is created for initial inventory
        QltyInspectionUtility.CreateWarehouseJournalLine(TempQltyInspectionHeader, TempQltyDispositionBuffer, InitialInventoryWarehouseJournalBatch, WhseItemWarehouseJournalLine, CheckCreatedJnlWhseItemTrackingLine);

        // [GIVEN] Warehouse journal is posted to establish initial inventory
        QltyInspectionUtility.PostWarehouseJournal(TempQltyInspectionHeader, TempQltyDispositionBuffer, WhseItemWarehouseJournalLine);

        // [GIVEN] Warehouse entry is verified and retrieved for the serial-tracked item
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Bin Code", TempQltyDispositionBuffer."New Bin Code");
        WarehouseEntry.SetRange("Serial No.", OriginalSerialNo);
        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Sanity check on inventory creation prior to the actual test.');
        WarehouseEntry.FindFirst();

        // [GIVEN] Temporary inspection header is populated with warehouse entry source record
        TempQltyInspectionHeader."Source RecordId" := WarehouseEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Warehouse Entry";

        // [GIVEN] Inspection header is configured with location and item information
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";

        // [GIVEN] Inspection header is configured with original serial number
        TempQltyInspectionHeader."Source Serial No." := OriginalSerialNo;

        // [GIVEN] Disposition buffer is configured with location and bin filters
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := WarehouseEntry."Bin Code";

        // [GIVEN] Disposition buffer is configured with new serial number for disposition change
        TempQltyDispositionBuffer."New Serial No." := NewSerialNo;

        // [GIVEN] Disposition buffer entry behavior is set to prepare only
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [GIVEN] Inspection source quantity is set to 1 unit
        TempQltyInspectionHeader."Source Quantity (Base)" := 1;

        // [GIVEN] Disposition buffer quantity to handle is set to 1 unit
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 1;

        // [GIVEN] Disposition buffer quantity behavior is set to specific quantity
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to change the serial number
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        InitialInventoryWarehouseJournalBatch.Delete();
        InitialInventoryWhseItemWarehouseJournalTemplate.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();

        WhseItemWarehouseJournalLine.Reset();
        WhseItemWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        WhseItemWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine.Count(), 'warehouse journal Line should have been created.');
        WhseItemWarehouseJournalLine.FindFirst();
        LibraryAssert.AreEqual(WhseItemWarehouseJournalLine."From Bin Code", WhseItemWarehouseJournalLine."To Bin Code", 'with item tracking changes, the bins must match.');
        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine."Qty. (Base)", 'base quantity should match');
        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine.Quantity, 'quantity should match');

        // [THEN] Warehouse item tracking line is created with correct serial numbers
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source ID", ReclassWarehouseJournalBatch.Name);
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Batch Name", ReclassWarehouseJournalBatch."Journal Template Name");
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine.Count(), 'Tracking Line should have been created.');
        CheckCreatedJnlWhseItemTrackingLine.FindFirst();

        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Subtype" = 0, 'Tracking Line should have subtype 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Prod. Order Line" = 0, 'Tracking Line should have Source Prod. Order Line 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Qty. per Unit of Measure" = 1, 'Should have Qty. per Unit of Measure = 1');
        LibraryAssert.AreEqual(OriginalSerialNo, CheckCreatedJnlWhseItemTrackingLine."Serial No.", 'Serial No. should match provided serial no.');
        LibraryAssert.AreEqual(NewSerialNo, CheckCreatedJnlWhseItemTrackingLine."New Serial No.", 'Serial No. should match provided serial no.');
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine."Quantity (Base)", 'Quantity (Base) should match.');
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle (Base)", 'Quantity to Handle (Base) should match.');
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle", 'Quantity to Handle should match.');
    end;

    [Test]
    procedure ChangePackageDisposition_NonDirectedPickWithBins()
    var
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
        PickBin: Record Bin;
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InitialInventoryItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        NegativeAdjustItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInventoryItemJournalLine: Record "Item Journal Line";
        ChangePackageNumberItemJournalLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        NoSeries: Codeunit "No. Series";
        OriginalPackageNo: Code[50];
        NewPackageNo: Code[50];
    begin
        // [SCENARIO] Change package disposition for items in a non-directed pick location with bins

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Item journal templates and batches are created for adjustments and reclassification
        LibraryInventory.CreateItemJournalTemplateByType(InitialInventoryItemJournalTemplate, InitialInventoryItemJournalTemplate.Type::Item);

        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);

        LibraryInventory.CreateItemJournalBatch(NegativeAdjustItemJournalBatch, InitialInventoryItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        ReclassItemJournalBatch.CalcFields("Template Type");
        NegativeAdjustItemJournalBatch.CalcFields("Template Type");

        QltyManagementSetup."Item Journal Batch Name" := NegativeAdjustItemJournalBatch.Name;
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Package number series and item tracking code are created for package tracking
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        ReUsedLibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);
        InventorySetup.Get();
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, '', '', PackageItemTrackingCode.Code);

        // [GIVEN] Non-directed pick location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] Pick bin is identified
        PickBin.SetRange("Location Code", Location.Code);

        PickBin.FindFirst();

        // [GIVEN] Initial inventory journal line is created with positive adjustment
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(0, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be 0 lines as an input..');

        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, InitialInventoryItemJournalTemplate.Name, NegativeAdjustItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line.');

        // [GIVEN] Package numbers are generated and journal line is updated with location and bin
        OriginalPackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        NewPackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Location Code", Location.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Bin Code", PickBin.Code);
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line after a modify');

        // [GIVEN] Item tracking with original package number is assigned to the journal line
        ReUsedLibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', '', InitialInspectionInventoryJnlItemJournalLine.Quantity);
        ReservationEntry.Validate("Package No.", OriginalPackageNo);
        ReservationEntry.Validate("New Package No.", OriginalPackageNo);
        ReservationEntry.Modify();

        // [GIVEN] Item ledger entry filters are set up and journal is posted
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Package No.", OriginalPackageNo);
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        InitialInspectionInventoryJnlItemJournalLine.SetRecFilter();
        InitialInspectionInventoryJnlItemJournalLine.FindFirst();
        ItemJnlPostBatch.Run(InitialInspectionInventoryJnlItemJournalLine);

        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        InitialInspectionInventoryJnlItemJournalLine.Reset();
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.", Item."No.");
        InitialInspectionInventoryJnlItemJournalLine.SetFilter(Quantity, '<>0');
        LibraryAssert.AreEqual(0, InitialInspectionInventoryJnlItemJournalLine.Count(), 'test setup failed, 0 posted item journal lines should exist after posting.');

        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.");
        InitialInspectionInventoryJnlItemJournalLine.SetRange(Quantity);
        InitialInspectionInventoryJnlItemJournalLine.DeleteAll();

        // [GIVEN] Temporary inspection header is populated with item ledger entry and package tracking information
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;

        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Package No." := OriginalPackageNo;
        TempQltyDispositionBuffer."New Package No." := NewPackageNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to change the package number
        LibraryAssert.AreEqual(true, QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer), 'expected the adjustment to work.');

        // [THEN] One journal line is created in the bin move batch
        ChangePackageNumberItemJournalLine.Reset();
        ChangePackageNumberItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");

        LibraryAssert.AreEqual(1, ChangePackageNumberItemJournalLine.Count(),
        'There should be one journal line in the change package adjustment batch.');
        ChangePackageNumberItemJournalLine.FindLast();

        // [THEN] One reservation entry is created for the package change
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ChangePackageNumberItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");

        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created for this item in this test.');
        ReservationEntry.FindFirst();

        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalPackageNo, ReservationEntry."Package No.", 'The package no. should match the original.');
        LibraryAssert.AreEqual(NewPackageNo, ReservationEntry."New Package No.", 'The new package no. should match the request');
        LibraryAssert.AreEqual(ChangePackageNumberItemJournalLine."Bin Code", ChangePackageNumberItemJournalLine."New Bin Code", 'the bin codes should match. Found by QA earlier.');
        LibraryAssert.AreEqual(6, ChangePackageNumberItemJournalLine.Quantity, 'The quantity should match the requested amount.');
        LibraryAssert.AreEqual(ChangePackageNumberItemJournalLine."Quantity (Base)", -1 * ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(ChangePackageNumberItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');

        ReservationEntry.Delete();
        ChangePackageNumberItemJournalLine.Delete();
        NegativeAdjustItemJournalBatch.Delete();
        ReclassItemJournalBatch.Delete();
        InitialInventoryItemJournalTemplate.Delete();
    end;

    [Test]
    procedure ChangePackageDisposition_DirectedPickAndPut()
    var
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
        AnyBin: Record Bin;
        PickBin: Record Bin;
        InitialInventoryWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        CheckCreatedJnlWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        BinContent: Record "Bin Content";
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        WarehouseEntry: Record "Warehouse Entry";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        InitialInventoryWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        OriginalPackageNo: Code[50];
        NewPackageNo: Code[50];
    begin
        // [SCENARIO] Change package disposition for items in a full WMS location with directed pick and put

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Package number series and item tracking code are created for package tracking
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        ReUsedLibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);
        InventorySetup.Get();
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, '', '', PackageItemTrackingCode.Code);

        // [GIVEN] Full WMS location is created with bins and bin content for the item
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        AnyBin.SetRange("Location Code", Location.Code);
        if AnyBin.FindSet() then
            repeat
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, AnyBin."Zone Code", AnyBin.Code, Item."No.", '', Item."Base Unit of Measure");
            until AnyBin.Next() = 0;

        PickBin.SetRange("Location Code", Location.Code);
        PickBin.SetRange("Zone Code", 'PICK');
        PickBin.FindFirst();

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Warehouse journal templates and batches are created for adjustments and reclassification
        LibraryWarehouse.CreateWhseJournalTemplate(InitialInventoryWhseItemWarehouseJournalTemplate, InitialInventoryWhseItemWarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(InitialInventoryWarehouseJournalBatch, InitialInventoryWhseItemWarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup."Whse. Item Journal Batch Name" := InitialInventoryWarehouseJournalBatch.Name;

        // [GIVEN] Reclassification warehouse journal template and batch are created
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Original and new package numbers are generated
        OriginalPackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        NewPackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);

        // [GIVEN] Initial warehouse inventory is created with original package number and posted
        TempQltyInspectionHeader."No." := 'initialinventory';
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Package No." := OriginalPackageNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := Location."Adjustment Bin Code";
        TempQltyDispositionBuffer."New Bin Code" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 100;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        QltyInspectionUtility.CreateWarehouseJournalLine(TempQltyInspectionHeader, TempQltyDispositionBuffer, InitialInventoryWarehouseJournalBatch, WhseItemWarehouseJournalLine, CheckCreatedJnlWhseItemTrackingLine);
        QltyInspectionUtility.PostWarehouseJournal(TempQltyInspectionHeader, TempQltyDispositionBuffer, WhseItemWarehouseJournalLine);

        // [GIVEN] Warehouse entry is verified for the posted inventory
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Bin Code", TempQltyDispositionBuffer."New Bin Code");
        WarehouseEntry.SetRange("Package No.", OriginalPackageNo);

        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Sanity check on inventory creation prior to the actual test.');
        WarehouseEntry.FindFirst();

        // [GIVEN] Temporary inspection header is populated with warehouse entry and package tracking information
        TempQltyInspectionHeader."Source RecordId" := WarehouseEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Warehouse Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Package No." := OriginalPackageNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := WarehouseEntry."Bin Code";
        TempQltyDispositionBuffer."New Package No." := NewPackageNo;

        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to change the package number
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        InitialInventoryWarehouseJournalBatch.Delete();
        InitialInventoryWhseItemWarehouseJournalTemplate.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();

        // [THEN] One warehouse journal line is created in the reclassification batch with matching bin codes
        WhseItemWarehouseJournalLine.Reset();
        WhseItemWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        WhseItemWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine.Count(), 'warehouse journal Line should have been created.');
        WhseItemWarehouseJournalLine.FindFirst();
        LibraryAssert.AreEqual(WhseItemWarehouseJournalLine."From Bin Code", WhseItemWarehouseJournalLine."To Bin Code", 'with item tracking changes, the bins must match.');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine."Qty. (Base)", 'base quantity should match');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine.Quantity, 'quantity should match');

        // [THEN] Warehouse item tracking line is created with correct package numbers
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source ID", ReclassWarehouseJournalBatch.Name);
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Batch Name", ReclassWarehouseJournalBatch."Journal Template Name");
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine.Count(), 'Tracking Line should have been created.');
        CheckCreatedJnlWhseItemTrackingLine.FindFirst();

        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Subtype" = 0, 'Tracking Line should have subtype 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Prod. Order Line" = 0, 'Tracking Line should have Source Prod. Order Line 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Qty. per Unit of Measure" = 1, 'Should have Qty. per Unit of Measure = 1');
        LibraryAssert.AreEqual(OriginalPackageNo, CheckCreatedJnlWhseItemTrackingLine."Package No.", 'Package No. should match provided package no.');
        LibraryAssert.AreEqual(NewPackageNo, CheckCreatedJnlWhseItemTrackingLine."New Package No.", 'Package No. should match provided package no.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Quantity (Base)", 'Quantity (Base) should match.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle (Base)", 'Quantity to Handle (Base) should match.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle", 'Quantity to Handle should match.');
    end;

    [Test]
    procedure ChangeLotAndExpirationDisposition_NonDirectedPickWithBins()
    var
        Location: Record Location;
        PickBin: Record Bin;
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InitialInventoryItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        NegativeAdjustItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInventoryItemJournalLine: Record "Item Journal Line";
        ChangeLotNumberItemJournalLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[50];
        NewLotNo: Code[50];
    begin
        // [SCENARIO] Change lot number and expiration date for items in a non-directed pick location with bins

        // [GIVEN] Quality management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Warehouse trigger is set to NoTrigger
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Item journal template is created for item adjustments
        LibraryInventory.CreateItemJournalTemplateByType(InitialInventoryItemJournalTemplate, InitialInventoryItemJournalTemplate.Type::Item);

        // [GIVEN] Item journal template is created for transfer/reclassification
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);

        // [GIVEN] Item journal batch is created for negative adjustments
        LibraryInventory.CreateItemJournalBatch(NegativeAdjustItemJournalBatch, InitialInventoryItemJournalTemplate.Name);

        // [GIVEN] Item journal batch is created for reclassification
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        // [GIVEN] Template types are calculated for both batches
        ReclassItemJournalBatch.CalcFields("Template Type");
        NegativeAdjustItemJournalBatch.CalcFields("Template Type");

        // [GIVEN] Quality management setup is configured with Item Journal Batch Name
        QltyManagementSetup."Item Journal Batch Name" := NegativeAdjustItemJournalBatch.Name;

        // [GIVEN] Quality management setup is configured with Item Reclass. Batch Name
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Lot number series is created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);

        // [GIVEN] Lot number series line is created with date-based numbering
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Item tracking code is created for lot tracking
        ReUsedLibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);

        // [GIVEN] Item tracking code is configured to use expiration dates
        LotItemTrackingCode."Use Expiration Dates" := true;
        LotItemTrackingCode.Modify();

        // [GIVEN] Lot-tracked item with expiration is created
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Non-directed pick location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Three bins are created in the location
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] Pick bin is identified from the location
        PickBin.SetRange("Location Code", Location.Code);
        PickBin.FindFirst();

        // [GIVEN] Initial inventory journal lines are verified to be empty before test setup
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(0, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be 0 lines as an input..');

        // [GIVEN] Initial positive adjustment journal line is created for 10 units
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, InitialInventoryItemJournalTemplate.Name, NegativeAdjustItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);

        // [GIVEN] Journal line creation is verified
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line.');

        // [GIVEN] Original lot number is generated for initial inventory
        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        // [GIVEN] New lot number is generated for disposition change
        NewLotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        // [GIVEN] Journal line is updated with location code
        InitialInspectionInventoryJnlItemJournalLine.Validate("Location Code", Location.Code);

        // [GIVEN] Journal line is updated with bin code
        InitialInspectionInventoryJnlItemJournalLine.Validate("Bin Code", PickBin.Code);
        InitialInspectionInventoryJnlItemJournalLine.Modify();

        // [GIVEN] Journal line modification is verified
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line after a modify');

        // [GIVEN] Item tracking with lot number is assigned to the journal line
        ReUsedLibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', OriginalLotNo, InitialInspectionInventoryJnlItemJournalLine.Quantity);

        // [GIVEN] Expiration date is set to work date for the reservation entry
        ReservationEntry."Expiration Date" := WorkDate();
        ReservationEntry.Modify();

        // [GIVEN] Item ledger entry filters are set up for validation
        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Lot No.", OriginalLotNo);
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        // [GIVEN] Journal line is filtered for posting
        InitialInspectionInventoryJnlItemJournalLine.SetRecFilter();
        InitialInspectionInventoryJnlItemJournalLine.FindFirst();

        // [GIVEN] Initial inventory journal is posted
        ItemJnlPostBatch.Run(InitialInspectionInventoryJnlItemJournalLine);

        // [GIVEN] Item ledger entry is verified and retrieved
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        // [GIVEN] Posted journal lines are verified to be empty
        InitialInspectionInventoryJnlItemJournalLine.Reset();
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.", Item."No.");
        InitialInspectionInventoryJnlItemJournalLine.SetFilter(Quantity, '<>0');
        LibraryAssert.AreEqual(0, InitialInspectionInventoryJnlItemJournalLine.Count(), 'test setup failed, 0 posted item journal lines should exist after posting.');

        // [GIVEN] Posted journal lines are cleaned up
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.");
        InitialInspectionInventoryJnlItemJournalLine.SetRange(Quantity);
        InitialInspectionInventoryJnlItemJournalLine.DeleteAll();

        // [GIVEN] Temporary inspection header is populated with item ledger entry source record
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";

        // [GIVEN] Inspection header is configured with location code
        TempQltyInspectionHeader."Location Code" := Location.Code;

        // [GIVEN] Inspection header is configured with item number and original lot number
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;

        // [GIVEN] Disposition buffer is configured with new lot number for disposition change
        TempQltyDispositionBuffer."New Lot No." := NewLotNo;

        // [GIVEN] Disposition buffer is configured with new expiration date 10 days in the future
        TempQltyDispositionBuffer."New Expiration Date" := CalcDate('<+10D>', WorkDate());

        // [GIVEN] Disposition buffer is configured with location and bin filters
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := PickBin.Code;

        // [GIVEN] Disposition buffer entry behavior is set to prepare only
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [GIVEN] Inspection source quantity is set to 5 units
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;

        // [GIVEN] Disposition buffer quantity to handle is set to 6 units
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;

        // [GIVEN] Disposition buffer quantity behavior is set to specific quantity
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to change the lot number and expiration date
        LibraryAssert.AreEqual(true, QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer),
            'expected the adjustment to work.');

        // [THEN] One journal line is created in the bin move batch
        ChangeLotNumberItemJournalLine.Reset();
        ChangeLotNumberItemJournalLine.SetRange(
            "Journal Batch Name",
            QltyManagementSetup."Item Reclass. Batch Name");

        LibraryAssert.AreEqual(1, ChangeLotNumberItemJournalLine.Count(),
        'There should be one journal line in the change lot adjustment batch.');
        ChangeLotNumberItemJournalLine.FindLast();

        // [THEN] One reservation entry is created for the lot and expiration date change
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source Subtype", ChangeLotNumberItemJournalLine."Entry Type".AsInteger());
        ReservationEntry.SetRange("Item No.", TempQltyInspectionHeader."Source Item No.");

        LibraryAssert.AreEqual(1, ReservationEntry.Count(), 'There should be one reservation entry created for this item in this test.');
        ReservationEntry.FindFirst();

        LibraryAssert.AreEqual(Item."No.", ReservationEntry."Item No.", 'The item no. should match the item journal line.');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'The location code should match the item journal line.');
        LibraryAssert.AreEqual(OriginalLotNo, ReservationEntry."Lot No.", 'The lot no. should match the original.');
        LibraryAssert.AreEqual(NewLotNo, ReservationEntry."New Lot No.", 'The new lot no. should match the request.');
        LibraryAssert.AreEqual(WorkDate(), ReservationEntry."Expiration Date", 'The original expiration date should match.');
        LibraryAssert.AreEqual(CalcDate('<+10D>', WorkDate()), ReservationEntry."New Expiration Date", 'The new expiration date should match the request.');
        LibraryAssert.AreEqual(ChangeLotNumberItemJournalLine."Bin Code", ChangeLotNumberItemJournalLine."New Bin Code", 'the bin codes should match. Found by QA earlier.');
        LibraryAssert.AreEqual(6, ChangeLotNumberItemJournalLine.Quantity, 'The quantity should match the requested amount.');
        LibraryAssert.AreEqual(ChangeLotNumberItemJournalLine."Quantity (Base)", -1 * ReservationEntry."Quantity (Base)", 'The Quantity (Base) should match the item journal line.');
        LibraryAssert.AreEqual(ChangeLotNumberItemJournalLine."Qty. per Unit of Measure", ReservationEntry."Qty. per Unit of Measure", 'The qty. per UOM should match the item journal line.');

        ReservationEntry.Delete();
        ChangeLotNumberItemJournalLine.Delete();
        NegativeAdjustItemJournalBatch.Delete();
        ReclassItemJournalBatch.Delete();
        InitialInventoryItemJournalTemplate.Delete();
    end;

    [Test]
    procedure ChangeLotAndExpirationDisposition_DirectedPickAndPut()
    var
        Location: Record Location;
        AnyBin: Record Bin;
        PickBin: Record Bin;
        InitialInventoryWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        CheckCreatedJnlWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        BinContent: Record "Bin Content";
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        WarehouseEntry: Record "Warehouse Entry";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        InitialInventoryWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[50];
        NewLotNo: Code[50];
    begin
        // [SCENARIO] Change lot number and expiration date for items in a full WMS location with directed pick and put

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Lot tracking with expiration dates is created
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        ReUsedLibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LotItemTrackingCode."Use Expiration Dates" := true;
        LotItemTrackingCode.Modify();

        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] Full WMS location is created with bins and bin content for the item
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        AnyBin.SetRange("Location Code", Location.Code);
        if AnyBin.FindSet() then
            repeat
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, AnyBin."Zone Code", AnyBin.Code, Item."No.", '', Item."Base Unit of Measure");
            until AnyBin.Next() = 0;

        PickBin.SetRange("Location Code", Location.Code);
        PickBin.SetRange("Zone Code", 'PICK');
        PickBin.FindFirst();

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Warehouse journal templates and batches are created for initial inventory and reclassification
        LibraryWarehouse.CreateWhseJournalTemplate(InitialInventoryWhseItemWarehouseJournalTemplate, InitialInventoryWhseItemWarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(InitialInventoryWarehouseJournalBatch, InitialInventoryWhseItemWarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup."Whse. Item Journal Batch Name" := InitialInventoryWarehouseJournalBatch.Name;

        // [GIVEN] Reclassification warehouse journal template and batch are created
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Original and new lot numbers are generated
        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code);
        NewLotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        TempQltyInspectionHeader."No." := 'initialinventory';
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := Location."Adjustment Bin Code";
        TempQltyDispositionBuffer."New Bin Code" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 100;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [GIVEN] Initial warehouse journal line is created and posted with expiration date
        QltyInspectionUtility.CreateWarehouseJournalLine(TempQltyInspectionHeader, TempQltyDispositionBuffer, InitialInventoryWarehouseJournalBatch, WhseItemWarehouseJournalLine, CheckCreatedJnlWhseItemTrackingLine);
        CheckCreatedJnlWhseItemTrackingLine."Expiration Date" := WorkDate();
        CheckCreatedJnlWhseItemTrackingLine.Modify();

        QltyInspectionUtility.PostWarehouseJournal(TempQltyInspectionHeader, TempQltyDispositionBuffer, WhseItemWarehouseJournalLine);

        // [GIVEN] Warehouse entry is verified for posted inventory with original lot number
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Bin Code", TempQltyDispositionBuffer."New Bin Code");
        WarehouseEntry.SetRange("Lot No.", OriginalLotNo);

        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Sanity check on inventory creation prior to the actual test.');
        WarehouseEntry.FindFirst();

        TempQltyInspectionHeader."Source RecordId" := WarehouseEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Warehouse Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := WarehouseEntry."Bin Code";
        TempQltyDispositionBuffer."New Lot No." := NewLotNo;
        TempQltyDispositionBuffer."New Expiration Date" := CalcDate('<+10D>', WorkDate());

        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to change the lot number and expiration date
        QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        InitialInventoryWarehouseJournalBatch.Delete();
        InitialInventoryWhseItemWarehouseJournalTemplate.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();

        // [THEN] One warehouse journal line is created in the reclassification batch with correct quantity
        WhseItemWarehouseJournalLine.Reset();
        WhseItemWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        WhseItemWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine.Count(), 'warehouse journal Line should have been created.');
        WhseItemWarehouseJournalLine.FindFirst();
        LibraryAssert.AreEqual(WhseItemWarehouseJournalLine."From Bin Code", WhseItemWarehouseJournalLine."To Bin Code", 'with item tracking changes, the bins must match.');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine."Qty. (Base)", 'base quantity should match');
        LibraryAssert.AreEqual(6, WhseItemWarehouseJournalLine.Quantity, 'quantity should match');

        // [THEN] Warehouse item tracking line is created with correct lot and expiration dates
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source ID", ReclassWarehouseJournalBatch.Name);
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Batch Name", ReclassWarehouseJournalBatch."Journal Template Name");
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine.Count(), 'Tracking Line should have been created.');
        CheckCreatedJnlWhseItemTrackingLine.FindFirst();

        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Subtype" = 0, 'Tracking Line should have subtype 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Prod. Order Line" = 0, 'Tracking Line should have Source Prod. Order Line 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Qty. per Unit of Measure" = 1, 'Should have Qty. per Unit of Measure = 1');
        LibraryAssert.AreEqual(OriginalLotNo, CheckCreatedJnlWhseItemTrackingLine."Lot No.", 'Lot No. should match provided lot no.');
        LibraryAssert.AreEqual(NewLotNo, CheckCreatedJnlWhseItemTrackingLine."New Lot No.", 'Lot No. should match provided lot no.');
        LibraryAssert.AreEqual(WorkDate(), CheckCreatedJnlWhseItemTrackingLine."Expiration Date", 'The original expiration date should match.');
        LibraryAssert.AreEqual(CalcDate('<+10D>', WorkDate()), CheckCreatedJnlWhseItemTrackingLine."New Expiration Date", 'The new expiration date should match the request.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Quantity (Base)", 'Quantity (Base) should match.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle (Base)", 'Quantity to Handle (Base) should match.');
        LibraryAssert.AreEqual(6, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle", 'Quantity to Handle should match.');
    end;

    [Test]
    procedure NumberSeriesDefinedInWhseJournalBatch()
    var
        Location: Record Location;
        AnyBin: Record Bin;
        InitialBin: Record Bin;
        Destination1Bin: Record Bin;
        InitialInventoryWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        InitialInventoryWhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        InitialInventoryWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        CreatedReclassWhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        BinContent: Record "Bin Content";
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        WhseJournalNoSeries: Record "No. Series";
        WhseJournalNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        WarehouseEntry: Record "Warehouse Entry";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        InitialInventoryWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        OriginalLotNo: Code[50];
    begin
        // [SCENARIO] Validate that the number series defined in the warehouse journal batch is used for warehouse document numbers

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Lot tracking is created with number series
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Lot-tracked item tracking code and item are created
        ReUsedLibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] A full WMS location with bins and bin content is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        AnyBin.SetRange("Location Code", Location.Code);
        if AnyBin.FindSet() then
            repeat
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, AnyBin."Zone Code", AnyBin.Code, Item."No.", '', Item."Base Unit of Measure");
            until AnyBin.Next() = 0;

        InitialBin.SetRange("Location Code", Location.Code);
        InitialBin.SetRange("Zone Code", 'PICK');
        InitialBin.FindFirst();

        Destination1Bin.SetRange("Location Code", Location.Code);
        Destination1Bin.SetRange("Zone Code", 'PICK');
        Destination1Bin.SetFilter(Code, '<>%1', InitialBin.Code);
        Destination1Bin.FindFirst();

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Warehouse journal templates and batches are created for initial inventory
        LibraryWarehouse.CreateWhseJournalTemplate(InitialInventoryWhseItemWarehouseJournalTemplate, InitialInventoryWhseItemWarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(InitialInventoryWarehouseJournalBatch, InitialInventoryWhseItemWarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup."Whse. Item Journal Batch Name" := InitialInventoryWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify(false);

        // [GIVEN] Reclassification warehouse journal template and batch are created with custom number series
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] Custom number series is created and assigned to the reclassification batch
        LibraryUtility.CreateNoSeries(WhseJournalNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(WhseJournalNoSeriesLine, WhseJournalNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        ReclassWarehouseJournalBatch."No. Series" := WhseJournalNoSeries.Code;
        ReclassWarehouseJournalBatch.Modify();

        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Original lot number is generated
        OriginalLotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        // [GIVEN] Initial warehouse inventory is created with lot tracking and expiration date
        TempQltyInspectionHeader."No." := 'initialinventory';
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := Location."Adjustment Bin Code";
        TempQltyDispositionBuffer."New Bin Code" := InitialBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 100;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        QltyInspectionUtility.CreateWarehouseJournalLine(TempQltyInspectionHeader, TempQltyDispositionBuffer, InitialInventoryWarehouseJournalBatch, InitialInventoryWhseItemWarehouseJournalLine, InitialInventoryWhseItemTrackingLine);
        InitialInventoryWhseItemTrackingLine."Expiration Date" := WorkDate();
        InitialInventoryWhseItemTrackingLine.Modify();

        // [GIVEN] Initial warehouse journal is posted and warehouse entry is verified
        QltyInspectionUtility.PostWarehouseJournal(TempQltyInspectionHeader, TempQltyDispositionBuffer, InitialInventoryWhseItemWarehouseJournalLine);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Bin Code", TempQltyDispositionBuffer."New Bin Code");
        WarehouseEntry.SetRange("Lot No.", OriginalLotNo);

        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Sanity check on inventory creation prior to the actual test.');
        WarehouseEntry.FindFirst();

        // [GIVEN] Temporary inspection header is populated with warehouse entry and destination bin information
        TempQltyInspectionHeader."Source RecordId" := WarehouseEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Warehouse Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Lot No." := OriginalLotNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := WarehouseEntry."Bin Code";
        TempQltyDispositionBuffer."New Bin Code" := Destination1Bin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 2;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed to create a warehouse journal line with prepare only behavior
        QltyInspectionUtility.PerformMoveWhseReclassDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One reclass warehouse journal line is created with auto-assigned document number
        CreatedReclassWhseItemWarehouseJournalLine.Reset();
        CreatedReclassWhseItemWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        CreatedReclassWhseItemWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(1, CreatedReclassWhseItemWarehouseJournalLine.Count(), 'reclass warehouse journal Line should have been created.');
        CreatedReclassWhseItemWarehouseJournalLine.FindFirst();

        // [THEN] The warehouse document number is automatically assigned from the number series (not the inspection header number)
        LibraryAssert.AreNotEqual(TempQltyInspectionHeader."No.", CreatedReclassWhseItemWarehouseJournalLine."Whse. Document No.", 'No manual no series are allowed.');
        CreatedReclassWhseItemWarehouseJournalLine."Whse. Document No." := 'INCORRECT';
        CreatedReclassWhseItemWarehouseJournalLine.Modify();

        // [WHEN] Entry behavior is changed to Post and disposition is performed again
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWhseReclassDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer),
            'second line with a post should have succeeded even if the first line was incorrect.');

        // [THEN] A second warehouse journal line is created and posted successfully
        CreatedReclassWhseItemWarehouseJournalLine.Reset();
        CreatedReclassWhseItemWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        CreatedReclassWhseItemWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(1, CreatedReclassWhseItemWarehouseJournalLine.Count(), 'second line should have been created and then posted.');
        CreatedReclassWhseItemWarehouseJournalLine.FindFirst();

        // [THEN] The first line with incorrect warehouse document number fails to post
        LibraryAssert.IsFalse(QltyInspectionUtility.PostWarehouseJournal(TempQltyInspectionHeader, TempQltyDispositionBuffer, CreatedReclassWhseItemWarehouseJournalLine), 'the first line should not have posted successfully');
    end;

    [Test]
    procedure ChangeLotAndExpirationDisposition_MultipleBins_DirectedPickAndPut()
    var
        Location: Record Location;
        Bin: Record Bin;
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWarehouseJournalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        LotNoSeries: Record "No. Series";
        LotItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        eQltyPurOrderGenerator2: Codeunit "Qlty. Pur. Order Generator";
        NoSeries: Codeunit "No. Series";
        NewLotNo: Code[50];
    begin
        // [SCENARIO] Change lot number and expiration date for items split across multiple bins in a directed location

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Inspection template and rule for purchase lines, warehouse journals, and lot-tracked item with expiration dates
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Inspection template and rule for purchase lines are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] Reclassification warehouse journal template and batch are created
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Lot-tracked item with expiration dates is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        LotItemTrackingCode.Get(Item."Item Tracking Code");
        LotItemTrackingCode."Use Expiration Dates" := true;
        LotItemTrackingCode.Modify();

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Purchase order is created, released, and received with lot tracking and expiration date
        eQltyPurOrderGenerator2.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        ReservationEntry."Expiration Date" := WorkDate();
        ReservationEntry.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        eQltyPurOrderGenerator2.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] Inspection is created with purchase line and tracking information
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Warehouse entry is found for the received item (excluding receive bin)
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        // [GIVEN] Reclassification warehouse journal line is created to split inventory across two bins
        QltyInspectionUtility.CreateReclassWhseJournalLine(ReclassWarehouseJournalLine, ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code,
            WarehouseEntry."Zone Code", WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."Entry Type"::Movement, Item."No.", 50);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        ReclassWarehouseJournalLine."From Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."From Bin Code" := ReclassWarehouseJournalLine."Bin Code";
        ReclassWarehouseJournalLine."To Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."To Bin Code" := Bin.Code;
        ReclassWarehouseJournalLine."Lot No." := ReservationEntry."Lot No.";
        ReclassWarehouseJournalLine."New Lot No." := ReclassWarehouseJournalLine."Lot No.";
        ReclassWarehouseJournalLine.Modify();

        // [GIVEN] Warehouse item tracking line is created with lot and expiration information
        ReUsedLibraryItemTracking.CreateWhseJournalLineItemTracking(ReclassWarehouseJournalWhseItemTrackingLine, ReclassWarehouseJournalLine, '', ReservationEntry."Lot No.", 50);
        ReclassWarehouseJournalWhseItemTrackingLine."New Lot No." := ReclassWarehouseJournalWhseItemTrackingLine."Lot No.";
        ReclassWarehouseJournalWhseItemTrackingLine."Expiration Date" := ReservationEntry."Expiration Date";
        ReclassWarehouseJournalWhseItemTrackingLine."New Expiration Date" := ReservationEntry."Expiration Date";
        ReclassWarehouseJournalWhseItemTrackingLine.Modify();

        // [GIVEN] Warehouse journal line is registered to split inventory across two bins
        LibraryWarehouse.RegisterWhseJournalLine(ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code, true);

        ReclassWarehouseJournalLine.Reset();
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.DeleteAll();

        // [GIVEN] New lot number is generated for the disposition
        LotNoSeries.Get(Item."Lot Nos.");
        NewLotNo := NoSeries.GetNextNo(LotNoSeries.Code);

        // [GIVEN] Disposition buffer is configured to change lot number and expiration date for all tracked quantity
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."New Lot No." := NewLotNo;
        TempQltyDispositionBuffer."New Expiration Date" := CalcDate('<+10D>', WorkDate());
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] Disposition is performed to change lot number and expiration date
        QltyInspectionUtility.PerformChangeTrackingDisposition(QltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] Two warehouse journal lines are created (one for each bin) with correct quantities
        ReclassWarehouseJournalLine.Reset();
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(2, ReclassWarehouseJournalLine.Count(), 'warehouse journal Lines should have been created.');
        ReclassWarehouseJournalLine.FindSet();
        repeat
            LibraryAssert.AreEqual(ReclassWarehouseJournalLine."From Bin Code", ReclassWarehouseJournalLine."To Bin Code", 'with item tracking changes, the bins must match.');
            LibraryAssert.AreEqual(50, ReclassWarehouseJournalLine."Qty. (Base)", 'base quantity should match');
            LibraryAssert.AreEqual(50, ReclassWarehouseJournalLine.Quantity, 'quantity should match');
        until ReclassWarehouseJournalLine.Next() = 0;

        // [THEN] Two warehouse item tracking lines are created with correct lot numbers and expiration dates for both bins
        ReclassWarehouseJournalWhseItemTrackingLine.Reset();
        ReclassWarehouseJournalWhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        ReclassWarehouseJournalWhseItemTrackingLine.SetRange("Source ID", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalWhseItemTrackingLine.SetRange("Source Batch Name", ReclassWarehouseJournalBatch."Journal Template Name");
        LibraryAssert.AreEqual(2, ReclassWarehouseJournalWhseItemTrackingLine.Count(), 'Tracking Lines should have been created.');
        ReclassWarehouseJournalWhseItemTrackingLine.FindSet();
        repeat
            LibraryAssert.IsTrue(ReclassWarehouseJournalWhseItemTrackingLine."Source Subtype" = 0, 'Tracking Line should have subtype 0');
            LibraryAssert.IsTrue(ReclassWarehouseJournalWhseItemTrackingLine."Source Prod. Order Line" = 0, 'Tracking Line should have Source Prod. Order Line 0');
            LibraryAssert.IsTrue(ReclassWarehouseJournalWhseItemTrackingLine."Qty. per Unit of Measure" = 1, 'Should have Qty. per Unit of Measure = 1');
            LibraryAssert.AreEqual(QltyInspectionHeader."Source Lot No.", ReclassWarehouseJournalWhseItemTrackingLine."Lot No.", 'Lot No. should match provided lot no.');
            LibraryAssert.AreEqual(NewLotNo, ReclassWarehouseJournalWhseItemTrackingLine."New Lot No.", 'Lot No. should match provided lot no.');
            LibraryAssert.AreEqual(WorkDate(), ReclassWarehouseJournalWhseItemTrackingLine."Expiration Date", 'The original expiration date should match.');
            LibraryAssert.AreEqual(CalcDate('<+10D>', WorkDate()), ReclassWarehouseJournalWhseItemTrackingLine."New Expiration Date", 'The new expiration date should match the request.');
            LibraryAssert.AreEqual(50, ReclassWarehouseJournalWhseItemTrackingLine."Quantity (Base)", 'Quantity (Base) should match.');
            LibraryAssert.AreEqual(50, ReclassWarehouseJournalWhseItemTrackingLine."Qty. to Handle (Base)", 'Quantity to Handle (Base) should match.');
            LibraryAssert.AreEqual(50, ReclassWarehouseJournalWhseItemTrackingLine."Qty. to Handle", 'Quantity to Handle should match.');
        until ReclassWarehouseJournalWhseItemTrackingLine.Next() = 0;

        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
    end;

    [Test]
    procedure ChangePackageDisposition_NonDirectedPickWithBins_Post()
    var
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
        PickBin: Record Bin;
        Item: Record Item;
        PackageNoSeries: Record "No. Series";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        InitialInspectionInventoryJnlItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InitialInventoryItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        NegativeAdjustItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        InitialInventoryItemJournalLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        NoSeries: Codeunit "No. Series";
        OriginalPackageNo: Code[50];
        NewPackageNo: Code[50];
    begin
        // [SCENARIO] Change and post package number for items in a non-directed pick location with bins

        // [GIVEN] Quality management setup is initialized with warehouse trigger set to NoTrigger
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;

        // [GIVEN] Item journal templates are created for initial inventory and reclassification
        LibraryInventory.CreateItemJournalTemplateByType(InitialInventoryItemJournalTemplate, InitialInventoryItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);

        // [GIVEN] Item journal batches are created for initial inventory and reclassification
        LibraryInventory.CreateItemJournalBatch(NegativeAdjustItemJournalBatch, InitialInventoryItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        ReclassItemJournalBatch.CalcFields("Template Type");
        NegativeAdjustItemJournalBatch.CalcFields("Template Type");

        QltyManagementSetup."Item Journal Batch Name" := NegativeAdjustItemJournalBatch.Name;
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Package tracking is created with number series
        LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        ReUsedLibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);
        InventorySetup.Get();
        InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
        InventorySetup.Modify(true);

        // [GIVEN] A package-tracked item is created
        LibraryInventory.CreateTrackedItem(Item, '', '', PackageItemTrackingCode.Code);

        // [GIVEN] A non-directed pick location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        PickBin.SetRange("Location Code", Location.Code);
        PickBin.FindFirst();

        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(0, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be 0 lines as an input..');

        // [GIVEN] Initial inventory journal line is created with positive adjustment of 10 units
        LibraryInventory.CreateItemJournalLine(InitialInspectionInventoryJnlItemJournalLine, InitialInventoryItemJournalTemplate.Name, NegativeAdjustItemJournalBatch.Name, InitialInspectionInventoryJnlItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10);
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line.');

        // [GIVEN] Original and new package numbers are generated
        OriginalPackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);
        NewPackageNo := NoSeries.GetNextNo(PackageNoSeries.Code);

        // [GIVEN] Journal line is updated with location and bin information
        InitialInspectionInventoryJnlItemJournalLine.Validate("Location Code", Location.Code);
        InitialInspectionInventoryJnlItemJournalLine.Validate("Bin Code", PickBin.Code);
        InitialInspectionInventoryJnlItemJournalLine.Modify();
        InitialInventoryItemJournalLine.Reset();
        InitialInventoryItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInventoryItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        LibraryAssert.AreEqual(1, InitialInventoryItemJournalLine.Count(), 'test setup failed, should be only 1 line after a modify');

        // [GIVEN] Item tracking with original package number is assigned to the journal line
        ReUsedLibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, InitialInspectionInventoryJnlItemJournalLine, '', '', InitialInspectionInventoryJnlItemJournalLine.Quantity);
        ReservationEntry.Validate("Package No.", OriginalPackageNo);
        ReservationEntry.Validate("New Package No.", OriginalPackageNo);
        ReservationEntry.Modify();

        ItemLedgerEntry.SetRange("Item No.", InitialInspectionInventoryJnlItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Package No.", OriginalPackageNo);
        ItemLedgerEntry.SetRange("Location Code", InitialInspectionInventoryJnlItemJournalLine."Location Code");

        // [GIVEN] Initial inventory journal is posted creating item ledger entry with package tracking
        InitialInspectionInventoryJnlItemJournalLine.SetRecFilter();
        InitialInspectionInventoryJnlItemJournalLine.FindFirst();
        ItemJnlPostBatch.Run(InitialInspectionInventoryJnlItemJournalLine);

        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'test setup failed, expected one item ledger entry.');
        ItemLedgerEntry.FindLast();

        InitialInspectionInventoryJnlItemJournalLine.Reset();
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Template Name", InitialInventoryItemJournalTemplate.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Journal Batch Name", NegativeAdjustItemJournalBatch.Name);
        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.", Item."No.");
        InitialInspectionInventoryJnlItemJournalLine.SetFilter(Quantity, '<>0');
        LibraryAssert.AreEqual(0, InitialInspectionInventoryJnlItemJournalLine.Count(), 'test setup failed, 0 posted item journal lines should exist after posting.');

        InitialInspectionInventoryJnlItemJournalLine.SetRange("Item No.");
        InitialInspectionInventoryJnlItemJournalLine.SetRange(Quantity);
        InitialInspectionInventoryJnlItemJournalLine.DeleteAll();

        // [GIVEN] Temporary inspection header is populated with item ledger entry and package tracking information
        TempQltyInspectionHeader."No." := 'test';
        TempQltyInspectionHeader."Source RecordId" := ItemLedgerEntry.RecordId();
        TempQltyInspectionHeader."Source Table No." := Database::"Item Ledger Entry";
        TempQltyInspectionHeader."Location Code" := Location.Code;
        TempQltyInspectionHeader."Source Item No." := Item."No.";
        TempQltyInspectionHeader."Source Package No." := OriginalPackageNo;
        TempQltyInspectionHeader."Source Quantity (Base)" := 5;

        // [GIVEN] Disposition buffer is configured to change package number with specific quantity and post immediately
        TempQltyDispositionBuffer."New Package No." := NewPackageNo;
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := PickBin.Code;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Package disposition is performed with post behavior to change package number from original to new
        LibraryAssert.AreEqual(true, QltyInspectionUtility.PerformChangeTrackingDisposition(TempQltyInspectionHeader, TempQltyDispositionBuffer),
            'expected the adjustment to work.');

        // [THEN] One item ledger entry with transfer type is created with new package number and quantity of 6
        Clear(ItemLedgerEntry);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Package No.", NewPackageNo);
        ItemLedgerEntry.SetRange(Quantity, 6);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'Should have posted one adjustment line.');
    end;

    [Test]
    procedure ChangeLotDisposition_DirectedPickAndPut_Post()
    var
        Location: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        WarehouseEntry: Record "Warehouse Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyManagementSetup: Record "Qlty. Management Setup";
        NoSeries: Codeunit "No. Series";
        NewLotNo: Code[50];
    begin
        // [SCENARIO] Change and post lot number for items in a directed pick and put location

        // [GIVEN] Quality management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A prioritized quality inspection rule is created for warehouse entries
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full WMS location with directed pick and put is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created, released, and received at the location
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] Warehouse entry is found for the received item (excluding receive zone)
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        // [GIVEN] Quality inspection is created with warehouse entry and tracking information
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Reclassification warehouse journal template and batch are created
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Reclass. Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Disposition buffer is configured to change lot number with specific quantity and post immediately
        TempQltyDispositionBuffer."Location Filter" := Location.Code;
        TempQltyDispositionBuffer."Bin Filter" := WarehouseEntry."Bin Code";
        NewLotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        TempQltyDispositionBuffer."New Lot No." := NewLotNo;
        TempQltyDispositionBuffer."Entry Behavior" := TempQltyDispositionBuffer."Entry Behavior"::Post;
        TempQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempQltyDispositionBuffer."Quantity Behavior" := TempQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        // [WHEN] Disposition is performed with post behavior to change and post the lot number
        QltyInspectionUtility.PerformChangeTrackingDisposition(QltyInspectionHeader, TempQltyDispositionBuffer);

        // [THEN] One item ledger entry is created with transfer entry type and new lot number
        Clear(ItemLedgerEntry);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", NewLotNo);
        ItemLedgerEntry.SetRange(Quantity, 6);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'Should have posted one adjustment line.');

        WarehouseJournalTemplate.Delete();
        WarehouseJournalBatch.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure ChangeLotDisposition_NoInventoryFound_ShouldExit()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        FilterLocation: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ReservationEntry: Record "Reservation Entry";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        NoSeries: Codeunit "No. Series";
    begin
        // [SCENARIO] Validate that no warehouse journal lines are created when no inventory is found at the filtered location

        // [GIVEN] Quality management setup and inspection generation rule are initialized
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A full WMS location and a filter location are created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        LibraryWarehouse.CreateLocation(FilterLocation);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order for 100 units is created and released at the main location
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] A quality inspection is created with purchase line and tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Warehouse journal template and batch are created for adjustments
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);

        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] Quality management setup is configured with warehouse adjustment batch
        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Item Journal Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] Disposition buffer is configured with filter location where no inventory exists
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."Location Filter" := FilterLocation.Code;
        TempInstructionQltyDispositionBuffer."New Lot No." := NoSeries.GetNextNo(Item."Lot Nos.");

        // [WHEN] Lot disposition is performed with filter location that has no inventory
        QltyInspectionUtility.PerformChangeTrackingDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer);
        // [THEN] No warehouse journal lines are created because no inventory was found at the filtered location
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        LibraryAssert.IsTrue(WarehouseJournalLine.IsEmpty(), 'No adjustment line should have been created');

        QltyInspectionGenRule.Delete();
        WarehouseJournalBatch.Delete();
        WarehouseJournalTemplate.Delete();
    end;

    [Test]
    procedure ChangeLotDisposition_NoTracking_ShouldErr()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReservationEntry: Record "Reservation Entry";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Validate that an error is raised when attempting lot disposition without specifying new tracking information

        // [GIVEN] Quality management setup and inspection generation rule are initialized
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A full WMS location is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order for 100 units is created with lot tracking
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] A quality inspection is created with purchase line and tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Disposition buffer is configured without new tracking information
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";

        QltyInspectionGenRule.Delete();

        // [WHEN] Disposition is attempted without new tracking information
        asserterror QltyInspectionUtility.PerformChangeTrackingDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer);
        // [THEN] An error is raised indicating no tracking changes were provided
        LibraryAssert.ExpectedError(NoTrackingChangesErr);
    end;

    [Test]
    procedure ChangeLotDisposition_NoBatch_Directed_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReservationEntry: Record "Reservation Entry";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        NoSeries: Codeunit "No. Series";
    begin
        // [SCENARIO] Validate that an error is raised when reclassification batch is not configured for directed location

        // [GIVEN] Quality management setup is initialized with empty bin warehouse move batch name
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Reclass. Batch Name" := '';
        QltyManagementSetup.Modify();

        // [GIVEN] A full WMS location with directed pick and put-away is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created with purchase line and tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Disposition buffer is configured with new lot number
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Lot No." := NoSeries.GetNextNo(Item."Lot Nos.");

        QltyInspectionGenRule.Delete();

        // [WHEN] Lot disposition is attempted without configured reclassification batch
        asserterror QltyInspectionUtility.PerformChangeTrackingDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer);
        // [THEN] An error is raised indicating missing reclassification batch configuration
        LibraryAssert.ExpectedError(MissingReclassBatchErr);
    end;

    [Test]
    procedure ChangeLotDisposition_NoBatch_NonDirected_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReservationEntry: Record "Reservation Entry";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        NoSeries: Codeunit "No. Series";
    begin
        // [SCENARIO] Validate that an error is raised when bin move batch is not configured for non-directed location with bins

        // [GIVEN] Quality management setup is initialized with empty Item Reclass. Batch Name
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Reclass. Batch Name" := '';
        QltyManagementSetup.Modify();

        // [GIVEN] A non-directed location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Three bins are created at the location
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created with bin assignment, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created with purchase line and tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Disposition buffer is configured with new lot number
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 6;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Lot No." := NoSeries.GetNextNo(Item."Lot Nos.");

        QltyInspectionGenRule.Delete();

        // [WHEN] Lot disposition is attempted without configured bin move batch
        asserterror QltyInspectionUtility.PerformChangeTrackingDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer);
        // [THEN] An error is raised indicating missing reclassification batch configuration
        LibraryAssert.ExpectedError(MissingReclassBatchErr);
    end;

    [Test]
    procedure CreateTransfer_NonDirectedWithBins_DirectTransfer_Untracked()
    var
        Location: Record Location;
        DestinationLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create a direct transfer order for untracked items from a non-directed location with bins

        // [GIVEN] Quality management setup and inspection generation rule are initialized
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A non-directed location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Three bins are created at the source location
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A destination location is created
        LibraryWarehouse.CreateLocation(DestinationLocation);

        // [GIVEN] An untracked item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order for 100 units is created with bin assignment, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created with the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [WHEN] Transfer disposition is performed for 50 units to the destination location
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformTransferDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', DestinationLocation.Code, ''), 'Should have created transfer.');

        // [THEN] One direct transfer header is created between source and destination locations
#pragma warning disable AA0210 
        TransferHeader.SetRange("Transfer-from Code", Location.Code);
        TransferHeader.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferHeader.SetRange("Direct Transfer", true);
#pragma warning restore AA0210
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'Should be one transfer header created.');

        // [THEN] One transfer line is created with requested quantity of 50 and transfer-from bin code
        TransferLine.SetRange("Transfer-from Code", Location.Code);
        TransferLine.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferLine.SetRange("Item No.", Item."No.");
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'Should be one transfer line created.');

        TransferLine.FindFirst();
        LibraryAssert.AreEqual(50, TransferLine.Quantity, 'Should have requested quantity.');
        LibraryAssert.AreEqual(Bin.Code, TransferLine."Transfer-from Bin Code", 'Should have transfer-from bin code.');
    end;

    [Test]
    procedure CreateTransfer_NonDirectedWithBins_DirectTransfer_Untracked_ShouldPost()
    var
        Location: Record Location;
        DestinationLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
    begin
        // [SCENARIO] Create, release, and post a direct transfer order for untracked items

        // [GIVEN] Quality management setup and inspection generation rule are initialized
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A non-directed source location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Three bins are created at the source location
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A destination location is created
        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] An untracked item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order for 100 units is created with bin assignment, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created with the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [WHEN] Transfer disposition is performed for 50 units to create a direct transfer
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformTransferDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', DestinationLocation.Code, ''), 'Should have created transfer.');

        // [THEN] One direct transfer header is created between source and destination locations
#pragma warning disable AA0210 
        TransferHeader.SetRange("Transfer-from Code", Location.Code);
        TransferHeader.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferHeader.SetRange("Direct Transfer", true);
#pragma warning restore AA0210
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'Should be one transfer header created.');

        // [THEN] One transfer line is created with correct quantity and bin code
        TransferLine.SetRange("Transfer-from Code", Location.Code);
        TransferLine.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferLine.SetRange("Item No.", Item."No.");
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'Should be one transfer line created.');

        TransferLine.FindFirst();
        LibraryAssert.AreEqual(50, TransferLine.Quantity, 'Should have requested quantity.');
        LibraryAssert.AreEqual(Bin.Code, TransferLine."Transfer-from Bin Code", 'Should have transfer-from bin code.');

        // [THEN] Transfer order is released and posted successfully
        TransferHeader.FindFirst();
        ReleaseTransferDocument.Release(TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    [Test]
    procedure CreateTransfer_NonDirectedWithBins_InTransit_TrackedWithVariant()
    var
        Location: Record Location;
        DestinationLocation: Record Location;
        InTransitLocation: Record Location;
        TransferRoute: Record "Transfer Route";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Vendor: Record Vendor;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create an in-transit transfer order for lot-tracked items with variants

        // [GIVEN] Quality management setup and inspection generation rule are initialized
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A non-directed location with bins, destination location, and in-transit location are created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        LibraryWarehouse.CreateLocation(DestinationLocation);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] A transfer route with in-transit location is configured
        LibraryWarehouse.CreateTransferRoute(TransferRoute, Location.Code, DestinationLocation.Code);
        TransferRoute."In-Transit Code" := InTransitLocation.Code;
        TransferRoute.Modify();

        // [GIVEN] A lot-tracked item with variant is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order for 100 units with variant is created with bin assignment, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, ItemVariant.Code, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created with purchase line and tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [WHEN] Transfer disposition is performed for 50 units to destination location with in-transit route
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformTransferDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', DestinationLocation.Code, ''), 'Should have created transfer.');

        // [THEN] One transfer header is created with in-transit location
#pragma warning disable AA0210 
        TransferHeader.SetRange("Transfer-from Code", Location.Code);
        TransferHeader.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferHeader.SetRange("In-Transit Code", InTransitLocation.Code);
#pragma warning restore AA0210
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'Should be one transfer header created.');

        // [THEN] One transfer line is created with correct item, variant, and bin code
        TransferLine.SetRange("Transfer-from Code", Location.Code);
        TransferLine.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferLine.SetRange("In-Transit Code", InTransitLocation.Code);
        TransferLine.SetRange("Item No.", Item."No.");
        TransferLine.SetRange("Variant Code", ItemVariant.Code);
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'Should be one transfer line created.');

        TransferLine.FindFirst();
        LibraryAssert.AreEqual(TransferLine."Transfer-from Bin Code", Bin.Code, 'Transfer-from bin code should be provided when location is bin mandatory.');

        // [THEN] Reservation entry is created with correct quantity, location, and shipment date
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(-50, ReservationEntry.Quantity, 'Should match request quantity and be negative (outbound).');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'Should have originating location.');
        LibraryAssert.AreEqual(WorkDate(), ReservationEntry."Shipment Date", 'Should have shipment date.');
    end;

    [Test]
    procedure CreateTransfer_Directed_InTransit_Tracked()
    var
        Location: Record Location;
        DestinationLocation: Record Location;
        InTransitLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create an in-transit transfer order for lot-tracked items in a directed pick and put location

        // [GIVEN] Quality management setup and inspection generation rule for warehouse entry are initialized
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full WMS location with directed pick and put-away is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A destination location and in-transit location are created
        LibraryWarehouse.CreateLocation(DestinationLocation);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] A lot-tracked item with number series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order for 100 units is created, released, and received at directed location
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A warehouse entry with movement type is found and a quality inspection is created
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [WHEN] Transfer disposition is performed for 50 units to destination location with in-transit location
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformTransferDisposition(QltyInspectionHeader, 50, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', DestinationLocation.Code, InTransitLocation.Code), 'Should have created transfer.');

        // [THEN] One transfer header is created with in-transit location
#pragma warning disable AA0210 
        TransferHeader.SetRange("Transfer-from Code", Location.Code);
        TransferHeader.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferHeader.SetRange("In-Transit Code", InTransitLocation.Code);
#pragma warning restore AA0210
        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'Should be one transfer header created.');

        // [THEN] One transfer line is created for the lot-tracked item
        TransferLine.SetRange("Transfer-from Code", Location.Code);
        TransferLine.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferLine.SetRange("In-Transit Code", InTransitLocation.Code);
        TransferLine.SetRange("Item No.", Item."No.");
        LibraryAssert.AreEqual(1, TransferLine.Count(), 'Should be one transfer line created.');

        TransferLine.FindFirst();

        // [THEN] Reservation entry is created with correct quantity, location, and shipment date
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        ReservationEntry.FindFirst();
        LibraryAssert.AreEqual(-50, ReservationEntry.Quantity, 'Should match request quantity and be negative (outbound).');
        LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'Should have originating location.');
        LibraryAssert.AreEqual(WorkDate(), ReservationEntry."Shipment Date", 'Should have shipment date.');
    end;

    [Test]
    procedure CreateTransfer_Directed_MultipleBins_InTransit_Tracked()
    var
        Location: Record Location;
        DestinationLocation: Record Location;
        InTransitLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create transfer order with lot tracking from directed location where inventory is spread across multiple bins using in-transit location

        // [GIVEN] A directed warehouse location, destination location, and in-transit location are created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] Directed, destination, and in-transit locations are configured
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        LibraryWarehouse.CreateLocation(DestinationLocation);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] A lot-tracked item is purchased and received at the directed location
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry with lot tracking
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Warehouse reclassification journal is created to redistribute inventory
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] Inventory is manually redistributed across two bins (50 in each bin) using warehouse journal
        Clear(WarehouseEntry);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);
        QltyInspectionUtility.CreateReclassWhseJournalLine(
            ReclassWarehouseJournalLine,
            ReclassWhseItemWarehouseJournalTemplate.Name,
            ReclassWarehouseJournalBatch.Name,
            Location.Code,
            WarehouseEntry."Zone Code",
            WarehouseEntry."Bin Code",
            ReclassWarehouseJournalLine."Entry Type"::Movement,
            Item."No.",
            50);
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();
        ReclassWarehouseJournalLine."From Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."From Bin Code" := ReclassWarehouseJournalLine."Bin Code";
        ReclassWarehouseJournalLine."To Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."To Bin Code" := Bin.Code;
        ReclassWarehouseJournalLine."Lot No." := ReservationEntry."Lot No.";
        ReclassWarehouseJournalLine."New Lot No." := ReclassWarehouseJournalLine."Lot No.";
        ReclassWarehouseJournalLine.Modify();
        ReUsedLibraryItemTracking.CreateWhseJournalLineItemTracking(ReclassWarehouseJournalWhseItemTrackingLine, ReclassWarehouseJournalLine, '', ReservationEntry."Lot No.", 50);
        ReclassWarehouseJournalWhseItemTrackingLine."New Lot No." := ReclassWarehouseJournalWhseItemTrackingLine."Lot No.";
        ReclassWarehouseJournalWhseItemTrackingLine.Modify();
        LibraryWarehouse.RegisterWhseJournalLine(ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code, true);

        // [GIVEN] Verification that inventory is now in two bins
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        LibraryAssert.AreEqual(2, BinContent.Count(), 'Test setup failed. Two bins should have a quantity of 50 each of the item.');
        QltyInspectionGenRule.Delete();

        // [WHEN] Perform disposition to create transfer order with item tracked quantity
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformTransferDisposition(QltyInspectionHeader, 0, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity", '', '', DestinationLocation.Code, InTransitLocation.Code), 'Should have created transfer.');

        // [THEN] Two transfer orders are created, one for each bin, each with correct reservation entries

#pragma warning disable AA0210 
        TransferHeader.SetRange("Transfer-from Code", Location.Code);
        TransferHeader.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferHeader.SetRange("In-Transit Code", InTransitLocation.Code);
#pragma warning restore AA0210
        LibraryAssert.AreEqual(2, TransferHeader.Count(), 'Should be two transfer headers created.');

        TransferLine.SetRange("Transfer-from Code", Location.Code);
        TransferLine.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferLine.SetRange("In-Transit Code", InTransitLocation.Code);
        TransferLine.SetRange("Item No.", Item."No.");
        LibraryAssert.AreEqual(2, TransferLine.Count(), 'Should be two transfer lines created.');

        TransferLine.FindSet();
        repeat
            Clear(ReservationEntry);
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
            ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
            ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
            ReservationEntry.FindFirst();
            LibraryAssert.AreEqual(-50, ReservationEntry.Quantity, 'Should match request quantity and be negative (outbound).');
            LibraryAssert.AreEqual(Location.Code, ReservationEntry."Location Code", 'Should have originating location.');
            LibraryAssert.AreEqual(WorkDate(), ReservationEntry."Shipment Date", 'Should have shipment date.');
        until TransferLine.Next() = 0;
    end;

    [Test]
    procedure CreateTransfer_NoInventoryFound_ShouldExit()
    var
        Location: Record Location;
        DestinationLocation: Record Location;
        FilterLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create transfer should exit gracefully when no inventory is found matching the location filter

        // [GIVEN] A directed warehouse location, destination location, and filter location are created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] Directed warehouse location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Destination and filter locations are created
        LibraryWarehouse.CreateLocation(DestinationLocation);

        LibraryWarehouse.CreateLocation(FilterLocation);

        // [GIVEN] An item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [WHEN] Perform disposition is called with a location filter that does not match the inventory location
        LibraryAssert.IsFalse(QltyInspectionUtility.PerformTransferDisposition(QltyInspectionHeader, 50,
        TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', FilterLocation.Code,
        DestinationLocation.Code, ''), 'Should not have created transfer.');

        // [THEN] No transfer order is created and the disposition returns false

#pragma warning disable AA0210 
        TransferHeader.SetRange("Transfer-from Code", Location.Code);
        TransferHeader.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferHeader.SetRange("Direct Transfer", true);
#pragma warning restore AA0210
        LibraryAssert.AreEqual(0, TransferHeader.Count(), 'Should be no transfer headers created.');

        TransferLine.SetRange("Transfer-from Code", Location.Code);
        TransferLine.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferLine.SetRange("Item No.", Item."No.");
        TransferLine.SetRange(Quantity, 50);
        LibraryAssert.AreEqual(0, TransferLine.Count(), 'Should be no transfer lines created.');
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_Untracked_SpecificQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create warehouse reclassification journal entries to move untracked items to a different bin within a directed location using specific quantity

        // [GIVEN] A full WMS location with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An untracked item is purchased and received in the directed location
        LibraryInventory.CreateItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected in the same zone
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured for warehouse reclassification with specific quantity
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] A warehouse reclassification journal line is created with correct details
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");
        ReclassWarehouseJournalLine.FindFirst();
        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", ReclassWarehouseJournalLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", ReclassWarehouseJournalLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassWarehouseJournalLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(50, ReclassWarehouseJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalLine.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_Untracked_SampleQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create warehouse reclassification journal entries to move untracked items to a different bin within a directed location using sample quantity

        // [GIVEN] A full WMS location with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An untracked item is purchased and received in the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry with sample size of 5
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected in the same zone
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Sample size is set with 5 total, 3 failures, 2 passes
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Fail Quantity" := 3;
        QltyInspectionHeader."Pass Quantity" := 2;
        QltyInspectionHeader.Modify();

        // [GIVEN] Disposition buffer is configured for warehouse reclassification using sample quantity
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Sample Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] A warehouse reclassification journal line is created with quantity equal to sample size
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");
        ReclassWarehouseJournalLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", ReclassWarehouseJournalLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", ReclassWarehouseJournalLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassWarehouseJournalLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(5, ReclassWarehouseJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalLine.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_Untracked_SampleFailQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create warehouse reclassification journal entries to move untracked items to a different bin within a directed location using failed sample quantity

        // [GIVEN] A full WMS location with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An untracked item is purchased and received in the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry with 3 failed items
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected in the same zone
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Sample quantities are set with 5 total, 3 failures, 2 passes
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Fail Quantity" := 3;
        QltyInspectionHeader."Pass Quantity" := 2;
        QltyInspectionHeader.Modify();

        // [GIVEN] Disposition buffer is configured for warehouse reclassification using failed quantity
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Failed Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] A warehouse reclassification journal line is created with quantity equal to failed quantity
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");
        ReclassWarehouseJournalLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", ReclassWarehouseJournalLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", ReclassWarehouseJournalLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassWarehouseJournalLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(3, ReclassWarehouseJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalLine.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_Untracked_SamplePassQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create warehouse reclassification journal entries to move untracked items to a different bin within a directed location using passed sample quantity

        // [GIVEN] A full WMS location with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An untracked item is purchased and received in the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry with 2 passed items
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected in the same zone
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Sample quantities are set with 5 total, 3 failures, 2 passes
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Fail Quantity" := 3;
        QltyInspectionHeader."Pass Quantity" := 2;
        QltyInspectionHeader.Modify();

        // [GIVEN] Disposition buffer is configured for warehouse reclassification using passed quantity
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Passed Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] A warehouse reclassification journal line is created with quantity equal to passed quantity
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");
        ReclassWarehouseJournalLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", ReclassWarehouseJournalLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", ReclassWarehouseJournalLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassWarehouseJournalLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(2, ReclassWarehouseJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalLine.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_Untracked_SpecificQty_Post()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Move inventory with warehouse reclassification for untracked items in directed location with specific quantity and post the journal

        // [GIVEN] A directed warehouse location with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] Directed warehouse location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Warehouse reclassification journal template and batch are configured in setup
        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An untracked item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to post warehouse reclassification for 50 units
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        // [WHEN] Perform disposition with post entry behavior
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification completed.');

        // [THEN] Inventory is physically moved to the target bin with correct quantity

        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Bin Code", Bin.Code);
        LibraryAssert.IsTrue(BinContent.Count() = 1, 'Should have inventory in new bin');
        BinContent.SetAutoCalcFields(Quantity);
        BinContent.FindFirst();
        LibraryAssert.AreEqual(50, BinContent.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_LotTracked_TrackedQty_MultiBin_Post()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWarehouseJournalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        BinToUse1: Code[20];
        BinToUse2: Code[20];
    begin
        // [SCENARIO] Register and post warehouse reclassification to move lot-tracked items distributed across multiple bins into a single destination bin in a directed location

        // [GIVEN] A full WMS location with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A lot-tracked item is purchased and received in the directed location
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the lot-tracked warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        BinToUse1 := WarehouseEntry."Bin Code";
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Half of the lot quantity is manually moved to a second bin in the same zone
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);
        QltyInspectionUtility.CreateReclassWhseJournalLine(ReclassWarehouseJournalLine, ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code,
            WarehouseEntry."Zone Code", WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."Entry Type"::Movement, Item."No.", 50);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();
        BinToUse2 := Bin.Code;

        ReclassWarehouseJournalLine."From Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."From Bin Code" := BinToUse1;
        ReclassWarehouseJournalLine."To Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."To Bin Code" := BinToUse2;
        ReclassWarehouseJournalLine."Lot No." := ReservationEntry."Lot No.";
        ReclassWarehouseJournalLine."New Lot No." := ReclassWarehouseJournalLine."Lot No.";
        ReclassWarehouseJournalLine.Modify();
        ReUsedLibraryItemTracking.CreateWhseJournalLineItemTracking(ReclassWarehouseJournalWhseItemTrackingLine, ReclassWarehouseJournalLine, '', ReservationEntry."Lot No.", 50);
        ReclassWarehouseJournalWhseItemTrackingLine."New Lot No." := ReclassWarehouseJournalWhseItemTrackingLine."Lot No.";
        ReclassWarehouseJournalWhseItemTrackingLine.Modify();
        LibraryWarehouse.RegisterWhseJournalLine(ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code, true);

        Clear(WarehouseEntry);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetRange("Bin Code", BinToUse2);
        WarehouseEntry.FindFirst();
        LibraryAssert.AreEqual(50, WarehouseEntry.Quantity, 'Test setup failed. Bin should have a quantity of 50 of the item.');

        // [GIVEN] A third target bin is selected for the final destination
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1&<>%2', BinToUse1, BinToUse2);
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to move all tracked quantities and post
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification completed.');

        // [THEN] Two warehouse entries are created in the destination bin from both source bins
        Clear(WarehouseEntry);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.FindSet();
        LibraryAssert.AreEqual(2, WarehouseEntry.Count(), 'Should be two movements into new bin.');
        repeat
            LibraryAssert.AreEqual(50, WarehouseEntry.Quantity, 'Bin should have received 50 of the item from each bin.');
        until WarehouseEntry.Next() = 0;

        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_LotTracked_SpecificQty_CannotPost_ShouldNotError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Attempt to post warehouse reclassification with quantity exceeding available inventory should create journal entries but not post, without throwing errors

        // [GIVEN] A full WMS location with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A lot-tracked item with 100 units is purchased and received
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the lot-tracked warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected in the same zone
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to post movement with quantity of 150 (exceeds available 100)
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 150;

        // [WHEN] The disposition action is performed
        LibraryAssert.IsFalse(QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should not claim posting completed.');

        // [THEN] Journal entries are created but posting fails gracefully without errors
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");
        ReclassWarehouseJournalLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", ReclassWarehouseJournalLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", ReclassWarehouseJournalLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassWarehouseJournalLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(150, ReclassWarehouseJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_Untracked_SpecificQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create item reclassification journal entries to move untracked items to a different bin within a non-directed location using specific quantity

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is purchased and received in a specific bin
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured for item reclassification with specific quantity
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] An item reclassification journal line is created with correct details
        ReclassItemJournalLine.SetRange("Journal Template Name", ReclassItemJournalTemplate.Name);
        ReclassItemJournalLine.SetRange("Journal Batch Name", ReclassItemJournalBatch.Name);
        ReclassItemJournalLine.SetRange("Item No.", Item."No.");
        ReclassItemJournalLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", ReclassItemJournalLine."Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassItemJournalLine."New Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(50, ReclassItemJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassItemJournalLine.Delete();
        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_Untracked_SampleQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create item reclassification journal entries to move untracked items to a different bin within a non-directed location using sample quantity

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line with sample size of 5
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Sample quantities are set with 5 total, 3 failures, 2 passes
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Fail Quantity" := 3;
        QltyInspectionHeader."Pass Quantity" := 2;
        QltyInspectionHeader.Modify();

        // [GIVEN] Disposition buffer is configured for item reclassification using sample quantity
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Sample Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] An item reclassification journal line is created with quantity equal to sample size
        ReclassItemJournalLine.SetRange("Journal Template Name", ReclassItemJournalTemplate.Name);
        ReclassItemJournalLine.SetRange("Journal Batch Name", ReclassItemJournalBatch.Name);
        ReclassItemJournalLine.SetRange("Item No.", Item."No.");
        ReclassItemJournalLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", ReclassItemJournalLine."Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassItemJournalLine."New Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(5, ReclassItemJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassItemJournalLine.Delete();
        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_Untracked_SampleFailQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create item reclassification journal entries to move untracked items to a different bin within a non-directed location using failed sample quantity

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is purchased and received in a specific bin
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line with 3 failed items
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Sample quantities are set with 5 total, 3 failures, 2 passes
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Fail Quantity" := 3;
        QltyInspectionHeader."Pass Quantity" := 2;
        QltyInspectionHeader.Modify();

        // [GIVEN] Disposition buffer is configured for item reclassification using failed quantity
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Failed Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] An item reclassification journal line is created with quantity equal to failed quantity
        ReclassItemJournalLine.SetRange("Journal Template Name", ReclassItemJournalTemplate.Name);
        ReclassItemJournalLine.SetRange("Journal Batch Name", ReclassItemJournalBatch.Name);
        ReclassItemJournalLine.SetRange("Item No.", Item."No.");
        ReclassItemJournalLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", ReclassItemJournalLine."Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassItemJournalLine."New Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(3, ReclassItemJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassItemJournalLine.Delete();
        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_Untracked_SamplePassQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create item reclassification journal entries to move untracked items to a different bin within a non-directed location using passed sample quantity

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is purchased and received in a specific bin
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line with 2 passed items
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Sample quantities are set with 5 total, 3 failures, 2 passes
        QltyInspectionHeader."Sample Size" := 5;
        QltyInspectionHeader."Fail Quantity" := 3;
        QltyInspectionHeader."Pass Quantity" := 2;
        QltyInspectionHeader.Modify();

        // [GIVEN] Disposition buffer is configured for item reclassification using passed quantity
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Passed Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] An item reclassification journal line is created with quantity equal to passed quantity
        ReclassItemJournalLine.SetRange("Journal Template Name", ReclassItemJournalTemplate.Name);
        ReclassItemJournalLine.SetRange("Journal Batch Name", ReclassItemJournalBatch.Name);
        ReclassItemJournalLine.SetRange("Item No.", Item."No.");
        ReclassItemJournalLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", ReclassItemJournalLine."Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassItemJournalLine."New Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(2, ReclassItemJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassItemJournalLine.Delete();
        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_Untracked_SpecificQty_Post()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Move inventory with item reclassification for untracked items in non-directed location with specific quantity and post the journal

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] Item reclassification journal template and batch are configured in setup
        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A non-directed location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is purchased and received at the non-directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to post item reclassification for 50 units
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        // [WHEN] Perform disposition with post entry behavior
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification completed.');

        // [THEN] Inventory is physically moved to the target bin with both bins containing 50 units each

        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        LibraryAssert.IsTrue(BinContent.Count() = 2, 'Should have inventory in new bin');
        BinContent.SetAutoCalcFields(Quantity);
        BinContent.FindSet();
        repeat
            LibraryAssert.AreEqual(50, BinContent.Quantity, 'Each bin should have 50 inventory.');
        until BinContent.Next() = 0;

        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_LotTracked_TrackedQty_MultiBin_Post()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ReclassReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        InitialChangeBin: Code[20];
    begin
        // [SCENARIO] Post item reclassification to move lot-tracked items distributed across multiple bins into a single destination bin in a non-directed location

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A lot-tracked item is purchased and received
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the lot-tracked purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Half of the lot quantity is manually moved to a second bin using item reclassification
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);
        LibraryInventory.CreateItemJournalLine(ReclassItemJournalLine, ReclassItemJournalTemplate.Name, ReclassItemJournalBatch.Name, ReclassItemJournalLine."Entry Type"::Transfer, Item."No.", 50);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();
        InitialChangeBin := Bin.Code;

        ReclassItemJournalLine."Location Code" := Location.Code;
        ReclassItemJournalLine."Bin Code" := PurchaseLine."Bin Code";
        ReclassItemJournalLine."New Location Code" := Location.Code;
        ReclassItemJournalLine."New Bin Code" := InitialChangeBin;
        ReclassItemJournalLine.Modify();

        ReUsedLibraryItemTracking.CreateItemReclassJnLineItemTracking(ReclassReservationEntry, ReclassItemJournalLine, '', ReservationEntry."Lot No.", 50);
        ReclassReservationEntry."New Lot No." := ReclassReservationEntry."Lot No.";
        ReclassReservationEntry.Modify();
        LibraryInventory.PostItemJournalBatch(ReclassItemJournalBatch);

        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetRange("Bin Code", InitialChangeBin);
        WarehouseEntry.FindFirst();
        LibraryAssert.AreEqual(50, WarehouseEntry.Quantity, 'Test setup failed. Bin should have a quantity of 50 of the item.');

        // [GIVEN] A third target bin is selected for the final destination
        Clear(Bin);
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1&<>%2', PurchaseLine."Bin Code", InitialChangeBin);
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to move all tracked quantities and post
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification completed.');

        // [THEN] Two warehouse entries are created in the destination bin from both source bins
        Clear(WarehouseEntry);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.FindSet();
        LibraryAssert.AreEqual(2, WarehouseEntry.Count(), 'Should be two movements into new bin.');
        repeat
            LibraryAssert.AreEqual(50, WarehouseEntry.Quantity, 'Bin should have received 50 of the item from each bin.');
        until WarehouseEntry.Next() = 0;

        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_LotTracked_SpecificQty_CannotPost_ShouldNotError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Attempt to post item reclassification with quantity exceeding available inventory should create journal entries but not post, without throwing errors

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A lot-tracked item with 100 units is purchased and received
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the lot-tracked purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Clear(Bin);
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code", PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to post movement with quantity of 150 (exceeds available 100)
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 150;

        // [WHEN] The disposition action is performed
        LibraryAssert.IsFalse(QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should not claim posting completed.');

        // [THEN] Journal entries are created but posting fails gracefully without errors
        ReclassItemJournalLine.SetRange("Journal Template Name", ReclassItemJournalTemplate.Name);
        ReclassItemJournalLine.SetRange("Journal Batch Name", ReclassItemJournalBatch.Name);
        ReclassItemJournalLine.SetRange("Item No.", Item."No.");
        ReclassItemJournalLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", ReclassItemJournalLine."Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassItemJournalLine."New Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(150, ReclassItemJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_MissingBatch_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Attempting to perform item reclassification disposition without configured batch name should throw an error

        // [GIVEN] Quality management setup with empty Item Reclass. Batch Name
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Reclass. Batch Name" := '';
        QltyManagementSetup.Modify();

        // [WHEN] Disposition action is performed
        asserterror QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer);

        // [THEN] An error is thrown indicating missing batch configuration
        LibraryAssert.ExpectedError(MissingBinMoveBatchErr);
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_MissingBatch_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Attempting to perform warehouse reclassification disposition without configured batch name should throw an error

        // [GIVEN] Quality management setup with empty bin warehouse move batch name
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Reclass. Batch Name" := '';
        QltyManagementSetup.Modify();

        // [WHEN] Disposition action is performed
        asserterror QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer);

        // [THEN] An error is thrown indicating missing batch configuration
        LibraryAssert.ExpectedError(MissingBinReclassBatchErr);
    end;

    [Test]
    procedure MoveInventory_Reclass_Directed_NoInventoryFound_ShouldExit()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        FilterLocation: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] When performing warehouse reclassification disposition with a location filter that doesn't match the inspection's location, no journal entries should be created and the operation should exit gracefully

        // [GIVEN] A directed warehouse location is configured with warehouse reclassification batch
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        LibraryWarehouse.CreateLocation(FilterLocation);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured with a location filter that doesn't match the inspection's location
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."Location Filter" := FilterLocation.Code;
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsFalse(QltyInspectionUtility.PerformMoveWhseReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should not claim reclassification created.');

        // [THEN] No warehouse journal lines are created
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");

        LibraryAssert.IsTrue(ReclassWarehouseJournalLine.IsEmpty(), 'Should not have created any journal lines.');

        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_Reclass_NonDirected_NoInventoryFound_ShouldExit()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        FilterLocation: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] When performing item reclassification disposition with a location filter that doesn't match the inspection's location, no journal entries should be created and the operation should exit gracefully

        // [GIVEN] A non-directed location is configured with item reclassification batch
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A non-directed location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        LibraryWarehouse.CreateLocation(FilterLocation);

        // [GIVEN] An item is purchased and received at the non-directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured with a location filter that doesn't match the inspection's location
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."Location Filter" := FilterLocation.Code;
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsFalse(QltyInspectionUtility.PerformMoveItemReclassDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should not claim reclassification created.');

        // [THEN] No item journal lines are created
        ReclassItemJournalLine.SetRange("Journal Template Name", ReclassItemJournalTemplate.Name);
        ReclassItemJournalLine.SetRange("Journal Batch Name", ReclassItemJournalBatch.Name);
        ReclassItemJournalLine.SetRange("Item No.", Item."No.");

        LibraryAssert.IsTrue(ReclassItemJournalLine.IsEmpty(), 'Should not have created any journal lines.');

        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_MoveWorksheet_Untracked_SpecificQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        WhseWorksheetTemplateToUse: Text;
    begin
        // [SCENARIO] Create movement worksheet entries for an untracked item with a specific quantity without posting

        // [GIVEN] A directed warehouse location is configured with movement worksheet template and name
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Movement worksheet template and name are created and configured in quality management setup
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll();
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        WhseWorksheetTemplate.Init();
        QltyInspectionUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUse);
        WhseWorksheetTemplate.Name := CopyStr(WhseWorksheetTemplateToUse, 1, MaxStrLen(WhseWorksheetTemplate.Name));
        WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
        WhseWorksheetTemplate."Page ID" := Page::"Movement Worksheet";
        WhseWorksheetTemplate.Insert();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        QltyManagementSetup.Get();
        QltyManagementSetup."Movement Worksheet Name" := WhseWorksheetName.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An untracked item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to move 50 units using movement worksheet without posting
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Movement Worksheet";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWorksheetDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim reclassification created.');

        // [THEN] A movement worksheet line is created with correct from/to locations and quantity
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.SetRange("Item No.", Item."No.");
        WhseWorksheetLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", WhseWorksheetLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", WhseWorksheetLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", WhseWorksheetLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, WhseWorksheetLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(50, WhseWorksheetLine.Quantity, 'Should have correct requested quantity.');

        WhseWorksheetLine.Delete();
        WhseWorksheetName.Delete();
        WhseWorksheetTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_MoveWorksheet_Directed_LotTracked_TrackedQty_MultiBin_Post()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWarehouseJournalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseMovementWarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        BinToUse1: Code[20];
        BinToUse2: Code[20];
        WhseWorksheetTemplateToUse: Text;
    begin
        // [SCENARIO] Create and post movement worksheet for lot-tracked item with quantity split across multiple bins using item tracked quantity behavior

        // [GIVEN] A directed warehouse location is configured with movement worksheet template and name
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Movement worksheet template and name are created and configured in quality management setup
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll();
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        WhseWorksheetTemplate.Init();
        QltyInspectionUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUse);
        WhseWorksheetTemplate.Name := CopyStr(WhseWorksheetTemplateToUse, 1, MaxStrLen(WhseWorksheetTemplate.Name));
        WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
        WhseWorksheetTemplate."Page ID" := Page::"Movement Worksheet";
        WhseWorksheetTemplate.Insert();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        QltyManagementSetup.Get();
        QltyManagementSetup."Movement Worksheet Name" := WhseWorksheetName.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A lot-tracked item is purchased and received at the directed location
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the lot-tracked warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        BinToUse1 := WarehouseEntry."Bin Code";
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Half of the lot quantity is manually moved to a second bin using warehouse reclassification
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        QltyInspectionUtility.CreateReclassWhseJournalLine(ReclassWarehouseJournalLine, ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code,
            WarehouseEntry."Zone Code", WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."Entry Type"::Movement, Item."No.", 50);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();
        BinToUse2 := Bin.Code;

        ReclassWarehouseJournalLine."From Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."From Bin Code" := BinToUse1;
        ReclassWarehouseJournalLine."To Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."To Bin Code" := BinToUse2;
        ReclassWarehouseJournalLine."Lot No." := ReservationEntry."Lot No.";
        ReclassWarehouseJournalLine."New Lot No." := ReclassWarehouseJournalLine."Lot No.";
        ReclassWarehouseJournalLine.Modify();
        ReUsedLibraryItemTracking.CreateWhseJournalLineItemTracking(ReclassWarehouseJournalWhseItemTrackingLine, ReclassWarehouseJournalLine, '', ReservationEntry."Lot No.", 50);
        ReclassWarehouseJournalWhseItemTrackingLine."New Lot No." := ReclassWarehouseJournalWhseItemTrackingLine."Lot No.";
        ReclassWarehouseJournalWhseItemTrackingLine.Modify();
        LibraryWarehouse.RegisterWhseJournalLine(ReclassWhseItemWarehouseJournalTemplate.Name, ReclassWarehouseJournalBatch.Name, Location.Code, true);

        // [GIVEN] Verify the second bin now contains 50 units of the lot-tracked item
        Clear(WarehouseEntry);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetRange("Bin Code", BinToUse2);
        WarehouseEntry.FindFirst();
        LibraryAssert.AreEqual(50, WarehouseEntry.Quantity, 'Test setup failed. Bin should have a quantity of 50 of the item.');

        // [GIVEN] A third target bin is selected for the final destination
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1&<>%2', BinToUse1, BinToUse2);
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to move all tracked quantities and post
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Movement Worksheet";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformMoveWorksheetDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim movement completed.');

        // [THEN] Four warehouse movement lines are created (take from two source bins, place in one destination bin)
        WhseMovementWarehouseActivityLine.SetRange("Activity Type", WhseMovementWarehouseActivityLine."Activity Type"::Movement);
        WhseMovementWarehouseActivityLine.SetRange("Location Code", Location.Code);
        WhseMovementWarehouseActivityLine.SetRange("Item No.", Item."No.");
        WhseMovementWarehouseActivityLine.SetRange("Lot No.", ReservationEntry."Lot No.");
        LibraryAssert.AreEqual(4, WhseMovementWarehouseActivityLine.Count(), 'Should be four movement lines (2 x take and place) created');
        WhseMovementWarehouseActivityLine.FindSet();
        repeat
            if WhseMovementWarehouseActivityLine."Action Type" = WhseMovementWarehouseActivityLine."Action Type"::Take then
                LibraryAssert.IsTrue(((WhseMovementWarehouseActivityLine."Bin Code" = BinToUse1) or (WhseMovementWarehouseActivityLine."Bin Code" = BinToUse2)), 'From bin code should match one of source bins.')
            else
                LibraryAssert.AreEqual(Bin.Code, WhseMovementWarehouseActivityLine."Bin Code", 'Should have correct requested to bin code.');
            LibraryAssert.AreEqual(50, WhseMovementWarehouseActivityLine.Quantity, 'Should be moving 50 of the item from each bin.');
        until WhseMovementWarehouseActivityLine.Next() = 0;

        WhseWorksheetName.Delete();
        WhseWorksheetTemplate.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_MoveWorksheet_Directed_NoToLocationOrBin_ShouldErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        WhseWorksheetTemplateToUse: Text;
    begin
        // [SCENARIO] Attempting to perform movement worksheet disposition without specifying destination location or bin should throw an error

        // [GIVEN] A directed warehouse location is configured with movement worksheet template and name
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Movement worksheet template and name are created and configured in quality management setup
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll();
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        WhseWorksheetTemplate.Init();
        QltyInspectionUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUse);
        WhseWorksheetTemplate.Name := CopyStr(WhseWorksheetTemplateToUse, 1, MaxStrLen(WhseWorksheetTemplate.Name));
        WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
        WhseWorksheetTemplate."Page ID" := Page::"Movement Worksheet";
        WhseWorksheetTemplate.Insert();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        QltyManagementSetup.Get();
        QltyManagementSetup."Movement Worksheet Name" := WhseWorksheetName.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] Disposition buffer is configured without specifying destination location or bin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Warehouse Reclassification";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        QltyInspectionGenRule.Delete();

        // [WHEN] Disposition action is performed
        asserterror QltyInspectionUtility.PerformMoveWorksheetDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer);

        // [THEN] An error is thrown indicating insufficient details for inventory movement
        LibraryAssert.ExpectedError(StrSubstNo(RequestedInventoryMoveButUnableToFindSufficientDetailsErr, QltyInspectionHeader."No."));
    end;

    [Test]
    procedure MoveInventory_InternalMovement_NonDirected_Untracked_SpecificQty_EntriesOnly()
    var
        InventorySetup: Record "Inventory Setup";
        IntMovementNoSeries: Record "No. Series";
        IntMovementNoSeriesLine: Record "No. Series Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        InternalMovementLine: Record "Internal Movement Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Create internal movement entries for an untracked item at a non-directed location with a specific quantity without posting

        // [GIVEN] A non-directed location with bins is configured and internal movement number series is set up
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is purchased and received at the non-directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Internal movement number series is configured
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        LibraryUtility.CreateNoSeries(IntMovementNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(IntMovementNoSeriesLine, IntMovementNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Get();
        InventorySetup."Internal Movement Nos." := IntMovementNoSeries.Code;
        InventorySetup.Modify();

        // [GIVEN] Disposition buffer is configured to move 50 units using internal movement without posting
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Internal Movement";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformInternalMoveDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim internal movement created.');

        // [THEN] An internal movement line is created with correct from/to bins and quantity
        InternalMovementLine.SetRange("Location Code", Location.Code);
        InternalMovementLine.SetRange("Item No.", Item."No.");
        InternalMovementLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", InternalMovementLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, InternalMovementLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(50, InternalMovementLine.Quantity, 'Should have correct requested quantity.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure MoveInventory_InternalMovement_NonDirected_LotTracked_TrackedQty_MultiBin_Post()
    var
        InventorySetup: Record "Inventory Setup";
        IntMovementNoSeries: Record "No. Series";
        IntMovementNoSeriesLine: Record "No. Series Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ReclassReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        InventoryMovementWarehouseActivityLine: Record "Warehouse Activity Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        InitialChangeBin: Code[20];
    begin
        // [SCENARIO] Create and post internal movement for lot-tracked item with quantity split across multiple bins using item tracked quantity behavior

        // [GIVEN] A non-directed location with bins is configured and internal movement number series is set up
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A lot-tracked item is purchased and received at the non-directed location
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the lot-tracked purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Half of the lot quantity is manually moved to a second bin using item reclassification
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);

        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);
        LibraryInventory.CreateItemJournalLine(ReclassItemJournalLine, ReclassItemJournalTemplate.Name, ReclassItemJournalBatch.Name, ReclassItemJournalLine."Entry Type"::Transfer, Item."No.", 50);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();
        InitialChangeBin := Bin.Code;

        ReclassItemJournalLine."Location Code" := Location.Code;
        ReclassItemJournalLine."Bin Code" := PurchaseLine."Bin Code";
        ReclassItemJournalLine."New Location Code" := Location.Code;
        ReclassItemJournalLine."New Bin Code" := InitialChangeBin;
        ReclassItemJournalLine.Modify();

        ReUsedLibraryItemTracking.CreateItemReclassJnLineItemTracking(ReclassReservationEntry, ReclassItemJournalLine, '', ReservationEntry."Lot No.", 50);
        ReclassReservationEntry."New Lot No." := ReclassReservationEntry."Lot No.";
        ReclassReservationEntry.Modify();
        LibraryInventory.PostItemJournalBatch(ReclassItemJournalBatch);

        // [GIVEN] Verify the second bin now contains 50 units of the lot-tracked item
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetRange("Bin Code", InitialChangeBin);
        WarehouseEntry.FindFirst();
        LibraryAssert.AreEqual(50, WarehouseEntry.Quantity, 'Test setup failed. Bin should have a quantity of 50 of the item.');

        // [GIVEN] Internal movement number series is configured
        LibraryUtility.CreateNoSeries(IntMovementNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(IntMovementNoSeriesLine, IntMovementNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'B<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'B<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Get();
        InventorySetup."Internal Movement Nos." := IntMovementNoSeries.Code;
        InventorySetup.Modify();

        // [GIVEN] A third target bin is selected for the final destination
        Clear(Bin);
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1&<>%2', PurchaseLine."Bin Code", InitialChangeBin);
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured to move all tracked quantities and post
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Internal Movement";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        // [WHEN] The disposition action is performed
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformInternalMoveDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer), 'Should claim inventory movement completed.');

        // [THEN] Four inventory movement lines are created (take from two source bins, place in one destination bin)
        InventoryMovementWarehouseActivityLine.SetRange("Activity Type", InventoryMovementWarehouseActivityLine."Activity Type"::"Invt. Movement");
        InventoryMovementWarehouseActivityLine.SetRange("Location Code", Location.Code);
        InventoryMovementWarehouseActivityLine.SetRange("Item No.", Item."No.");
        InventoryMovementWarehouseActivityLine.SetRange("Lot No.", ReservationEntry."Lot No.");
        LibraryAssert.AreEqual(4, InventoryMovementWarehouseActivityLine.Count(), 'Should be four movement lines (2 x take and place) created');
        InventoryMovementWarehouseActivityLine.FindSet();
        repeat
            if InventoryMovementWarehouseActivityLine."Action Type" = InventoryMovementWarehouseActivityLine."Action Type"::Take then
                LibraryAssert.IsTrue(((InventoryMovementWarehouseActivityLine."Bin Code" = PurchaseLine."Bin Code") or (InventoryMovementWarehouseActivityLine."Bin Code" = InitialChangeBin)), 'From bin code should match one of source bins.')
            else
                LibraryAssert.AreEqual(Bin.Code, InventoryMovementWarehouseActivityLine."Bin Code", 'Should have correct requested to bin code.');
            LibraryAssert.AreEqual(50, InventoryMovementWarehouseActivityLine.Quantity, 'Should be moving 50 of the item from each bin.');
        until InventoryMovementWarehouseActivityLine.Next() = 0;

        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure AutoChooseMoveInventory_Reclass_Directed_Untracked_SpecificQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Automatically choose warehouse reclassification to create journal entries for moving untracked items in a directed location

        // [GIVEN] A directed warehouse location with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An untracked item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured with automatic choice action to move 50 units
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Automatic Choice";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] Auto choose move inventory is performed
        QltyInspectionUtility.MoveInventory(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, false);

        // [THEN] A warehouse reclassification journal line is created with correct from/to locations and quantity
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");
        ReclassWarehouseJournalLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", ReclassWarehouseJournalLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", ReclassWarehouseJournalLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassWarehouseJournalLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(50, ReclassWarehouseJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalLine.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure AutoChooseMoveInventory_MoveWorksheet_Untracked_SpecificQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        WhseWorksheetTemplateToUse: Text;
    begin
        // [SCENARIO] Automatically choose movement worksheet to create worksheet entries for moving untracked items in a directed location

        // [GIVEN] A directed warehouse location with movement worksheet template and name configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Movement worksheet template and name are created and configured
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll();
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        WhseWorksheetTemplate.Init();
        QltyInspectionUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUse);
        WhseWorksheetTemplate.Name := CopyStr(WhseWorksheetTemplateToUse, 1, MaxStrLen(WhseWorksheetTemplate.Name));
        WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
        WhseWorksheetTemplate."Page ID" := Page::"Movement Worksheet";
        WhseWorksheetTemplate.Insert();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        QltyManagementSetup.Get();
        QltyManagementSetup."Movement Worksheet Name" := WhseWorksheetName.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] An untracked item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured with automatic choice action to move 50 units
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Automatic Choice";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] Auto choose move inventory is performed with worksheet preference
        QltyInspectionUtility.MoveInventory(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, true);

        // [THEN] A movement worksheet line is created with correct from/to locations and quantity
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.SetRange("Item No.", Item."No.");
        WhseWorksheetLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", WhseWorksheetLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", WhseWorksheetLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", WhseWorksheetLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, WhseWorksheetLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(50, WhseWorksheetLine.Quantity, 'Should have correct requested quantity.');

        WhseWorksheetLine.Delete();
        WhseWorksheetName.Delete();
        WhseWorksheetTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure AutoChooseMoveInventory_Reclass_NonDirected_Untracked_SpecificQty_EntriesOnly()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Automatically choose item reclassification to create journal entries for moving untracked items in a non-directed location

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is purchased and received at the non-directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured with automatic choice action to move 50 units
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Automatic Choice";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] Auto choose move inventory is performed
        QltyInspectionUtility.MoveInventory(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, false);

        // [THEN] An item reclassification journal line is created with correct from/to bins and quantity
        ReclassItemJournalLine.SetRange("Journal Template Name", ReclassItemJournalTemplate.Name);
        ReclassItemJournalLine.SetRange("Journal Batch Name", ReclassItemJournalBatch.Name);
        ReclassItemJournalLine.SetRange("Item No.", Item."No.");
        ReclassItemJournalLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", ReclassItemJournalLine."Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassItemJournalLine."New Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(50, ReclassItemJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassItemJournalLine.Delete();
        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure AutoChooseMoveInventory_InternalMovement_NonDirected_Untracked_SpecificQty_EntriesOnly()
    var
        InventorySetup: Record "Inventory Setup";
        IntMovementNoSeries: Record "No. Series";
        IntMovementNoSeriesLine: Record "No. Series Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        InternalMovementLine: Record "Internal Movement Line";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Automatically choose internal movement to create internal movement entries for moving untracked items in a non-directed location

        // [GIVEN] A non-directed location with bins and internal movement number series configured
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] An untracked item is purchased and received at the non-directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Internal movement number series is configured
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        LibraryUtility.CreateNoSeries(IntMovementNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(IntMovementNoSeriesLine, IntMovementNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'C<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'C<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Get();
        InventorySetup."Internal Movement Nos." := IntMovementNoSeries.Code;
        InventorySetup.Modify();

        // [GIVEN] Disposition buffer is configured with internal movement action to move 50 units
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Internal Movement";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] Auto choose move inventory is performed with internal movement preference
        QltyInspectionUtility.MoveInventory(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, true);

        // [THEN] An internal movement line is created with correct from/to bins and quantity
        InternalMovementLine.SetRange("Location Code", Location.Code);
        InternalMovementLine.SetRange("Item No.", Item."No.");
        InternalMovementLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", InternalMovementLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, InternalMovementLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(50, InternalMovementLine.Quantity, 'Should have correct requested quantity.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure AutoChooseMoveInventory_NoNewLocationOrBin_ShouldError()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Auto choose move inventory should error when no target location or bin is specified

        // [GIVEN] A directed warehouse location with a quality inspection
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A directed warehouse location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] An item is purchased and received at the location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] Disposition buffer is configured with automatic choice action but no target location or bin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Automatic Choice";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] Auto choose move inventory is performed without target location or bin
        asserterror QltyInspectionUtility.MoveInventory(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, true);

        // [THEN] An error is raised indicating there is nothing to move to
        LibraryAssert.ExpectedError(StrSubstNo(ThereIsNothingToMoveToErr, QltyInspectionHeader.GetFriendlyIdentifier()));

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure AutoChooseMoveInventory_Directed_NewLocation_ShouldError()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        SecondLocation: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Auto choose move inventory should error when attempting to change locations for a directed location

        // [GIVEN] A directed warehouse location with a quality inspection
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A directed warehouse location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A second location is created to use as target
        LibraryWarehouse.CreateLocation(SecondLocation);

        // [GIVEN] An item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] Disposition buffer is configured to move to a different location
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Automatic Choice";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."New Location Code" := SecondLocation.Code;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] Auto choose move inventory is performed with a different target location
        asserterror QltyInspectionUtility.MoveInventory(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, true);

        // [THEN] An error is raised indicating that bins cannot be changed between locations for directed pick and put
        LibraryAssert.ExpectedError(StrSubstNo(UnableToChangeBinsBetweenLocationsBecauseDirectedPickAndPutErr, QltyInspectionHeader."No.", Location.Code, SecondLocation.Code));

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure AutoChooseMoveInventory_NoInventoryFound_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        FilterLocation: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        // [SCENARIO] Auto choose move inventory should error when no inventory is found matching the location filter

        // [GIVEN] A non-directed location with item reclassification batch configured and bins created
        QltyInspectionUtility.EnsureSetupExists();
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] Item reclassification journal template and batch are configured
        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A non-directed location with bins is created
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] A second location is created to use as filter
        LibraryWarehouse.CreateLocation(FilterLocation);

        // [GIVEN] An item is purchased and received at the non-directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A target bin is selected for the movement
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        // [GIVEN] Disposition buffer is configured with a location filter that does not match the inventory location
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Automatic Choice";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."Location Filter" := FilterLocation.Code;
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := Bin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

        // [WHEN] Auto choose move inventory is performed with a non-matching location filter
        asserterror QltyInspectionUtility.MoveInventory(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, false);

        // [THEN] An error is raised indicating that insufficient inventory details were found
        LibraryAssert.ExpectedError(StrSubstNo(RequestedBinMoveButUnableToFindSufficientDetailsErr, QltyInspectionHeader.GetFriendlyIdentifier()));

        ReclassItemJournalLine.SetRange("Journal Template Name", ReclassItemJournalTemplate.Name);
        ReclassItemJournalLine.SetRange("Journal Batch Name", ReclassItemJournalBatch.Name);
        ReclassItemJournalLine.SetRange("Item No.", Item."No.");

        LibraryAssert.IsTrue(ReclassItemJournalLine.IsEmpty(), 'Should not have created any journal lines.');

        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure InternalPutaway_PerformDisposition()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WarehouseSetup: Record "Warehouse Setup";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Perform disposition with internal putaway creates a released internal putaway document for the specified quantity

        // [GIVEN] A directed warehouse location with warehouse number series configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] Warehouse setup has number series configured
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Current user is set as warehouse employee for the location
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] An item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [WHEN] Perform disposition with internal putaway is called for 50 units
        BeforeCount := WhseInternalPutAwayHeader.Count();
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformInternalPutAwayDisposition(QltyInspectionHeader, 50, '', '', true, Enum::"Qlty. Quantity Behavior"::"Specific Quantity"), 'Should claim internal putaway entry created');

        // [THEN] One internal putaway document is created with correct quantity and released status

        LibraryAssert.AreEqual(BeforeCount + 1, WhseInternalPutAwayHeader.Count(), 'Should have created one internal put-away');
        WhseInternalPutAwayLine.SetRange("Item No.", Item."No.");
        WhseInternalPutAwayLine.FindFirst();
        LibraryAssert.AreEqual(50, WhseInternalPutAwayLine.Quantity, 'Should have created internal put-away with quantity 50');
        WhseInternalPutAwayHeader.Get(WhseInternalPutAwayLine."No.");
        LibraryAssert.AreEqual(WhseInternalPutAwayHeader.Status::Released, WhseInternalPutAwayHeader.Status, 'Should have released internal putaway');
    end;

    [Test]
    procedure WarehousePutaway_PerformDisposition()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        WarehouseSetup: Record "Warehouse Setup";
        PutawayWarehouseActivityHeader: Record "Warehouse Activity Header";
        PutawayWarehouseActivityLine: Record "Warehouse Activity Line";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Perform disposition with warehouse putaway creates a warehouse putaway activity document for the specified quantity

        // [GIVEN] A directed warehouse location with warehouse number series configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] Warehouse setup has number series configured
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Current user is set as warehouse employee for the location
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] An item is purchased and received at the directed location
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A quality inspection is created for the warehouse entry
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] An internal putaway document is created for the inspection
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformInternalPutAwayDisposition(QltyInspectionHeader, 50, '', '', true, Enum::"Qlty. Quantity Behavior"::"Specific Quantity"), 'Should claim internal putaway entry created');

        // [WHEN] Perform disposition with warehouse putaway is called for 50 units
        PutawayWarehouseActivityHeader.SetRange(Type, PutawayWarehouseActivityHeader.Type::"Put-away");
        PutawayWarehouseActivityHeader.SetRange("Location Code", Location.Code);
        BeforeCount := PutawayWarehouseActivityHeader.Count();
        LibraryAssert.IsTrue(QltyInspectionUtility.PerformWarehousePutAwayDisposition(QltyInspectionHeader, 50, '', '', Enum::"Qlty. Quantity Behavior"::"Specific Quantity"), 'Should claim warehouse putaway entry created');

        // [THEN] One warehouse putaway activity is created with correct place line quantity
        LibraryAssert.AreEqual(BeforeCount + 1, PutawayWarehouseActivityHeader.Count(), 'Should have created a warehouse put-away');
        PutawayWarehouseActivityLine.SetRange("Activity Type", PutawayWarehouseActivityLine."Activity Type"::"Put-away");
        PutawayWarehouseActivityLine.SetRange("Item No.", Item."No.");
        PutawayWarehouseActivityLine.SetRange("Action Type", PutawayWarehouseActivityLine."Action Type"::Place);
        PutawayWarehouseActivityLine.FindFirst();
        LibraryAssert.AreEqual(50, PutawayWarehouseActivityLine.Quantity, 'Should have created warehouse put-away with quantity 50');
    end;

    [Test]
    procedure GetFromLocationAndBinBasedOnNamingConventions_PurchaseLine()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        TempQuantityQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Automatic location detection from purchase line using naming conventions when populating quantity buffer for inventory availability

        // [GIVEN] Quality management setup with template and generation rule for purchase lines are configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location, item, vendor, and purchase order with purchase line are created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine."Location Code" := Location.Code;
        PurchaseLine.Modify(true);

        // [GIVEN] A quality order is created from the purchase line and cleared for testing
        RecordRef.GetTable(PurchaseLine);
        QltyInspectionUtility.CreateInspection(RecordRef, false, QltyInspectionHeader);

        // [GIVEN] A disposition buffer is configured for automatic choice with specific quantity of 5 units
        TempInstructionQltyDispositionBuffer.Init();
        TempInstructionQltyDispositionBuffer."Buffer Entry No." := 1;
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with automatic choice";
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 5;
        TempInstructionQltyDispositionBuffer.Insert();

        // [GIVEN] The inspection quality order location and quantity are cleared to test naming convention detection
        QltyInspectionHeader."Location Code" := '';
        QltyInspectionHeader."Source Quantity (Base)" := 0;
        QltyInspectionHeader.Modify();

        // [WHEN] The quantity buffer is populated using inventory availability logic
        QltyInspectionUtility.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityQltyDispositionBuffer);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        TempQuantityQltyDispositionBuffer.Reset();
        TempQuantityQltyDispositionBuffer.FindFirst();

        // [THEN] The location is correctly detected from the purchase line through naming conventions and quantity matches the specified amount
        LibraryAssert.AreEqual(PurchaseLine."Location Code", TempQuantityQltyDispositionBuffer."Location Filter", 'Location from purchase line should be detected through GetFromLocationAndBinBasedOnNamingConventions');
        LibraryAssert.AreEqual(5, TempQuantityQltyDispositionBuffer."Qty. To Handle (Base)", 'Quantity should match the specified quantity');
    end;

    [Test]
    procedure PostItemJournalForNegativeAdjustmentCreatedFromTest()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        QltyManagementSetup: Record "Qlty. Management Setup";
        AdjustmentItemJournalLine: Record "Item Journal Line";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO 610785] Verify user can post item journal line for negative adjustment created from quality test
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] The generation rule is set to trigger on purchase order receive and automatic only
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::"Automatic only";
        QltyInspectionGenRule."Purchase Order Trigger" := QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive;
        QltyInspectionGenRule.Modify();

        // [GIVEN] An item journal template and batch are created for adjustments
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] User setup number series for item journal batch
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        ItemJournalBatch."No. Series" := NoSeries.Code;
        ItemJournalBatch.Modify();

        // [GIVEN] Quality management setup is updated with adjustment item journal batch
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Journal Batch Name" := ItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order with the Lot trackeditem is created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, PurchaseHeader, PurchaseLine);

        // [GIVEN] The purchase order is received
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Find Inspection Header created from purchase line
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();

        // [WHEN] Negative adjustment disposition is performed with specific quantity
        QltyInspectionUtility.PerformNegAdjustInvDisposition(QltyInspectionHeader, PurchaseLine.Quantity, TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity", '', '', QltyItemAdjPostBehavior::"Prepare only", '');

        // [THEN] Post item journal line should be successful
        AdjustmentItemJournalLine.Get(ItemJournalTemplate.Name, ItemJournalBatch.Name, 10000);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        ItemJournalBatch.Delete();
        ItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure PurchaseReturnSerialTrackedAdvLocation()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        AdvWhseLocation: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        PurOrdReservationEntry: Record "Reservation Entry";
        TempTrackedPurRtnBufferPurchaseHeader: Record "Purchase Header" temporary;
        OptionalItemVariant: Code[10];
        Reason: Code[10];
        CreditMemo: Code[35];
        SpecificQty: Decimal;
    begin
        // [SCENARIO] Create a purchase return order from a quality inspection for serial-tracked items in an advanced warehouse location

        Initialize();

        // [GIVEN] An advanced warehouse location with full warehouse management is created
        LibraryWarehouse.CreateFullWMSLocation(AdvWhseLocation, 3);

        // [GIVEN] Serial tracked item is created
        QltyInspectionUtility.CreateSerialTrackedItemWithVariant(Item, OptionalItemVariant);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order for 3 serial-tracked items is created, released, and fully received
        QltyPurOrderGenerator.CreatePurchaseOrder(3, AdvWhseLocation, Item, Vendor, OptionalItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, PurOrdReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(AdvWhseLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);
        PurOrdPurchaseLine.Get(PurOrdPurchaseLine."Document Type", PurOrdPurchaseLine."Document No.", PurOrdPurchaseLine."Line No.");
        LibraryAssert.AreEqual(PurOrderPurchaseHeader.Status, PurOrderPurchaseHeader.Status::Released, 'Purchase Order was not released.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Qty. Received (Base)", PurOrdPurchaseLine."Quantity (Base)", 'Purchase Order was not fully received.');

        // [GIVEN] A quality inspection template and generation rule are created
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(QltyInspectionTemplateHdr, QltyInspectionGenRule);
        // [GIVEN] A quality inspection is created with purchase line and tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurOrdPurchaseLine, PurOrdReservationEntry, QltyInspectionHeader);

        // [GIVEN] A return reason code and credit memo number are prepared
        Reason := GetOrCreateReturnReasonCode();

        CreditMemo := CopyStr(LibraryUtility.GenerateRandomText(35), 1, MaxStrLen(CreditMemo));

        // [GIVEN] A specific quantity is set for return
        SpecificQty := 3;

        QltyInspectionGenRule.Delete();

        // [WHEN] Purchase return disposition is performed with item tracked quantity behavior
        QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Item Tracked Quantity", SpecificQty, '', '', Reason, CreditMemo, TempTrackedPurRtnBufferPurchaseHeader);

        // [THEN] The purchase return order is created correctly for serial-tracked items
        VerifyInspectionAssertions(1, QltyInspectionHeader, TempTrackedPurRtnBufferPurchaseHeader, PurOrderPurchaseHeader, PurOrdPurchaseLine, CreditMemo, Item."No.", AdvWhseLocation.Code, Reason);

        // [WHEN] Purchase return disposition with specific quantity behavior is attempted on serial-tracked items
        asserterror QltyInspectionUtility.PerformPurchaseReturnDisposition(QltyInspectionHeader, Enum::"Qlty. Quantity Behavior"::"Specific Quantity", SpecificQty, '', '', Reason, CreditMemo, TempTrackedPurRtnBufferPurchaseHeader);
        // [THEN] An error is expected because no purchase receipt line exists for specific quantity with serial tracking
        LibraryAssert.ExpectedError(StrSubstNo(NoPurchRcptLineErr, Item."No.", QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No."));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    local procedure GetOrCreateReturnReasonCode(): Code[10]
    var
        ReturnReason: Record "Return Reason";
    begin
        if not ReturnReason.FindFirst() then begin
            ReturnReason.Init();
            ReturnReason.Code := LibraryUtility.GenerateRandomCode(1, Database::"Reason Code");
            ReturnReason.Description := CopyStr(LibraryUtility.GenerateRandomText(25), 1, MaxStrLen(ReturnReason.Description));
            ReturnReason.Insert();
        end;
        exit(ReturnReason.Code);
    end;

    local procedure EnsureInspectionTemplateAndRuleForPurchaseLineExist(var OutQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.")
    var
        PrioritizedQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        EnsureInspectionTemplateAndRuleForPurchaseLineExist(OutQltyInspectionTemplateHdr, PrioritizedQltyInspectionGenRule);
    end;

    local procedure EnsureInspectionTemplateAndRuleForPurchaseLineExist(var OutQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; var PrioritizedQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        QltyInspectionUtility2: Codeunit "Qlty. Inspection Utility";
    begin
        QltyInspectionUtility2.EnsureSetupExists();
        SpecificQltyInspectSourceConfig.SetRange("From Table No.", Database::"Purchase Line");
        if SpecificQltyInspectSourceConfig.IsEmpty() then
            QltyInspectionUtility.EnsureAtLeastOneSourceConfigurationExist(false);
        if OutQltyInspectionTemplateHdr.Code = '' then
            QltyInspectionUtility2.CreateTemplate(OutQltyInspectionTemplateHdr, 3);

        QltyInspectionUtility2.CreatePrioritizedRule(OutQltyInspectionTemplateHdr, Database::"Purchase Line", PrioritizedQltyInspectionGenRule);
    end;

    local procedure VerifyInspectionAssertions(BaseQty: Decimal; QltyInspectionHeader: Record "Qlty. Inspection Header"; PurReturnPurchaseHeader: Record "Purchase Header"; PurOrderPurchaseHeader: Record "Purchase Header"; PurPurchaseLine: Record "Purchase Line"; CreditMemo: Code[35]; ItemNo: Code[20]; Location: Code[10]; Reason: Code[35])
    var
        RtnPurchaseLine: Record "Purchase Line";
        RtnReservationEntry: Record "Reservation Entry";
    begin
        LibraryAssert.AreEqual(PurReturnPurchaseHeader."Buy-from Vendor Name", PurOrderPurchaseHeader."Buy-from Vendor Name", 'Return Order vendor does not match.');
        LibraryAssert.AreEqual(PurReturnPurchaseHeader."Vendor Cr. Memo No.", CreditMemo, 'Return Order vendor cr. memo no. does not match.');
        RtnPurchaseLine.SetRange(Type, RtnPurchaseLine.Type::Item);
        RtnPurchaseLine.SetRange("Document Type", RtnPurchaseLine."Document Type"::"Return Order");
        RtnPurchaseLine.SetRange("Document No.", PurReturnPurchaseHeader."No.");
        if RtnPurchaseLine.FindFirst() then;
        LibraryAssert.RecordCount(RtnPurchaseLine, 1);
        LibraryAssert.AreEqual(ItemNo, RtnPurchaseLine."No.", 'Return Order line item no. does not match.');
        LibraryAssert.AreEqual(PurPurchaseLine."Variant Code", RtnPurchaseLine."Variant Code", 'Return order line variant code does not match.');
        LibraryAssert.AreEqual(Location, RtnPurchaseLine."Location Code", 'Return Order line location does not match.');
        LibraryAssert.AreEqual(BaseQty, RtnPurchaseLine."Quantity (Base)", 'Return Order line quantity does not match.');
        LibraryAssert.AreEqual(PurPurchaseLine."Unit of Measure Code", RtnPurchaseLine."Unit of Measure Code", 'Return Order unit of measure does not match.');
        LibraryAssert.AreEqual(PurPurchaseLine."Direct Unit Cost", RtnPurchaseLine."Direct Unit Cost", 'Return Order direct unit cost does not match.');
        LibraryAssert.AreEqual(Reason, RtnPurchaseLine."Return Reason Code", 'Return Order reason code does not match.');
        if QltyInspectionUtility.IsInspectionItemTrackingUsed(QltyInspectionHeader) then begin
            RtnReservationEntry.SetRange("Location Code", RtnPurchaseLine."Location Code");
            RtnReservationEntry.SetRange("Item No.", QltyInspectionHeader."Source Item No.");
            RtnReservationEntry.SetRange("Source Type", Database::"Purchase Line");
            RtnReservationEntry.SetRange("Source ID", RtnPurchaseLine."Document No.");
            RtnReservationEntry.SetRange("Source Ref. No.", RtnPurchaseLine."Line No.");
            if RtnReservationEntry.FindLast() then;
            LibraryAssert.RecordCount(RtnReservationEntry, 1);
            LibraryAssert.AreEqual(QltyInspectionHeader."Source Lot No.", RtnReservationEntry."Lot No.", 'Purchase Return lot no. does not match inspection lot no.');
            LibraryAssert.AreEqual(QltyInspectionHeader."Source Serial No.", RtnReservationEntry."Serial No.", 'Purchase Return serial no. does not match inspection serial no.');
            LibraryAssert.AreEqual(QltyInspectionHeader."Source Package No.", RtnReservationEntry."Package No.", 'Purchase Return package no. does not match inspection package no.');
            LibraryAssert.AreEqual(RtnPurchaseLine."Quantity (Base)", (RtnReservationEntry."Quantity (Base)" * -1), 'Purchase Return tracking line quantity(base) does not match provided quantity.');
        end;
    end;
}
