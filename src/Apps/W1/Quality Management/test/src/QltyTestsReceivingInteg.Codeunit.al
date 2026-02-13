// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using System.TestLibraries.Utilities;

codeunit 139958 "Qlty. Tests - Receiving Integ."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        IsInitialized: Boolean;

    [Test]
    procedure AttemptCreateInspectionWithPurchaseLineAndTracking_LotTracked()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from a lot-tracked purchase order when receiving

        // [GIVEN] A WMS location, quality inspection template, and generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on purchase order receive
        QltyInspectionGenRule."Purchase Order Trigger" := QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is received
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code, lot number, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match purchase.');
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity (base) should match.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithPurchaseLineAndTracking_OnPurchPost()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from a purchase order without lot tracking when receiving

        // [GIVEN] A WMS location, quality inspection template, and generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A standard item (not lot-tracked) is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on purchase order receive
        QltyInspectionGenRule."Purchase Order Trigger" := QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is received
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithWhseJournalLine_LotTracked_OnReceiptPost()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from warehouse journal line for lot-tracked item on receipt post

        // [GIVEN] A full WMS location, quality inspection template, and warehouse journal generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Journal Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt post
        QltyInspectionGenRule."Warehouse Receipt Trigger" := QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptPost;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code, lot number, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match purchase.');

        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithWhseJournalLine_LotTracked_OnReceiptCreate()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from warehouse receipt line for lot-tracked item on receipt create

        // [GIVEN] A full WMS location, quality inspection template, and warehouse receipt line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Receipt Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt create
        QltyInspectionGenRule."Warehouse Receipt Trigger" := QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code and lot number
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match purchase.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithWhseJournalLine()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from warehouse journal line for standard item on receipt post

        // [GIVEN] A full WMS location, quality inspection template, and warehouse journal generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Journal Line", QltyInspectionGenRule);

        // [GIVEN] A standard item (not lot-tracked) is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt post
        QltyInspectionGenRule."Warehouse Receipt Trigger" := QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptPost;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithReceiptLine_LotTracked_OnReceiptPost()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from purchase line for lot-tracked item on warehouse receipt post

        // [GIVEN] A full WMS location, quality inspection template, and purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt post
        QltyInspectionGenRule."Warehouse Receipt Trigger" := QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptPost;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code and lot number
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match purchase.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Document No.", QltyInspectionHeader."Source Document No.", 'Inspection source document should be for purchase order.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Line No.", QltyInspectionHeader."Source Document Line No.", 'Inspection source document line no. should match purchase order line.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithReceiptLine_LotTracked_OnReceiptCreate()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from purchase line for lot-tracked item on warehouse receipt create

        // [GIVEN] A full WMS location, quality inspection template, and purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt create
        QltyInspectionGenRule."Warehouse Receipt Trigger" := QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match purchase.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Document No.", QltyInspectionHeader."Source Document No.", 'Inspection source document should be for purchase order.');
        LibraryAssert.AreEqual(PurOrdPurchaseLine."Line No.", QltyInspectionHeader."Source Document Line No.", 'Inspection source document line no. should match purchase order line.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithReceiptLine()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from purchase line for standard item on warehouse receipt create

        // [GIVEN] A full WMS location, quality inspection template, and purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A standard item (not lot-tracked) is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt create
        QltyInspectionGenRule."Warehouse Receipt Trigger" := QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
    end;

    [Test]
    procedure AttemptCreateInspectionOnSalesReturnPost_LotTracked()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        Customer: Record Customer;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RtnOrderSalesHeader: Record "Sales Header";
        RtnSalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        UnitPrice: Decimal;
        UnitCost: Decimal;
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from sales return order for lot-tracked item on receive post

        // [GIVEN] A WMS location, quality inspection template, and sales line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Sales Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item with unit cost and price is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);
        UnitCost := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        UnitPrice := LibraryRandom.RandDecInDecimalRange(2, 20, 2);
        Item."Unit Cost" := UnitCost;
        Item."Unit Price" := UnitPrice;
        Item.Modify();

        // [GIVEN] A purchase order is created, received, and inventory is available
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A sales order is created and shipped with lot tracking
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(OrderSalesHeader, OrderSalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, OrderSalesHeader, SalesLine.Type::Item, Item."No.", 100);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Qty. to Ship", 100);
        SalesLine.Modify();
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', ReservationEntry."Lot No.", 100);
        LibrarySales.PostSalesDocument(OrderSalesHeader, true, false);

        // [GIVEN] A sales return order is created with lot tracking and released
        LibrarySales.CreateSalesReturnOrderWithLocation(RtnOrderSalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLineWithUnitPrice(RtnSalesLine, RtnOrderSalesHeader, Item."No.", UnitPrice, 100);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, RtnSalesLine, '', ReservationEntry."Lot No.", 100);
        LibrarySales.ReleaseSalesDocument(RtnOrderSalesHeader);

        // [GIVEN] The generation rule is set to trigger on sales return order receive
        QltyInspectionGenRule."Sales Return Trigger" := QltyInspectionGenRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The sales return order is posted to receive
        LibrarySales.PostSalesDocument(RtnOrderSalesHeader, true, false);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match purchase.');
    end;

    [Test]
    procedure AttemptCreateInspectionOnSalesReturnPost()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        Customer: Record Customer;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RtnOrderSalesHeader: Record "Sales Header";
        RtnSalesLine: Record "Sales Line";
        DummyReservationEntry: Record "Reservation Entry";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        UnitPrice: Decimal;
        UnitCost: Decimal;
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from sales return order for standard item on receive post

        // [GIVEN] A WMS location, quality inspection template, and sales line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Sales Line", QltyInspectionGenRule);

        // [GIVEN] A standard item with unit cost and price is created
        UnitCost := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        UnitPrice := LibraryRandom.RandDecInDecimalRange(2, 20, 2);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, UnitPrice, UnitCost);

        // [GIVEN] A purchase order is created, received, and inventory is available
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A sales order is created and shipped
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(OrderSalesHeader, OrderSalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, OrderSalesHeader, SalesLine.Type::Item, Item."No.", 100);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Qty. to Ship", 100);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(OrderSalesHeader, true, false);

        // [GIVEN] A sales return order is created and released
        LibrarySales.CreateSalesReturnOrderWithLocation(RtnOrderSalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLineWithUnitPrice(RtnSalesLine, RtnOrderSalesHeader, Item."No.", UnitPrice, 100);
        LibrarySales.ReleaseSalesDocument(RtnOrderSalesHeader);

        // [GIVEN] The generation rule is set to trigger on sales return order receive
        QltyInspectionGenRule."Sales Return Trigger" := QltyInspectionGenRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The sales return order is posted to receive
        LibrarySales.PostSalesDocument(RtnOrderSalesHeader, true, false);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AttemptCreateInspectionOn_OnTransferReceivePost_LotTracked_Direct()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from direct transfer order for lot-tracked item on receive post

        // [GIVEN] From and To locations are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);

        // [GIVEN] A quality inspection template and transfer line generation rule are set up
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Transfer Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created, received at From location, and inventory is available with lot tracking
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(FromLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A direct transfer order is created from From location to To location with lot tracking
        OrderTransferHeader.Init();
        OrderTransferHeader.Insert(true);
        OrderTransferHeader.Validate("Transfer-from Code", FromLocation.Code);
        OrderTransferHeader.Validate("Transfer-to Code", ToLocation.Code);
        OrderTransferHeader.Validate("Direct Transfer", true);
        OrderTransferHeader.Modify();

        LibraryWarehouse.CreateTransferLine(OrderTransferHeader, TransferLine, Item."No.", 100);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', ReservationEntry."Lot No.", 100);
        LibraryWarehouse.ReleaseTransferOrder(OrderTransferHeader);

        // [GIVEN] The generation rule is set to trigger on transfer order receive post
        QltyInspectionGenRule."Transfer Order Trigger" := QltyInspectionGenRule."Transfer Order Trigger"::OnTransferOrderPostReceive;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The transfer order is posted to receive
        Codeunit.Run(Codeunit::"TransferOrder-Post Transfer", OrderTransferHeader);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code, location, lot number, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ToLocation.Code, QltyInspectionHeader."Location Code", 'Location code should match the "To" Location');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Lot no. should match source');
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AttemptCreateInspectionOn_OnTransferReceivePost_Direct()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        UnusedReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from direct transfer order for standard item on receive post

        // [GIVEN] From and To locations are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);

        // [GIVEN] A quality inspection template and transfer line generation rule are set up
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Transfer Line", QltyInspectionGenRule);

        // [GIVEN] A standard item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, received at From location, and inventory is available
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, UnusedReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(FromLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A direct transfer order is created from From location to To location and released
        OrderTransferHeader.Init();
        OrderTransferHeader.Insert(true);
        OrderTransferHeader.Validate("Transfer-from Code", FromLocation.Code);
        OrderTransferHeader.Validate("Transfer-to Code", ToLocation.Code);
        OrderTransferHeader.Validate("Direct Transfer", true);
        OrderTransferHeader.Modify();

        LibraryWarehouse.CreateTransferLine(OrderTransferHeader, TransferLine, Item."No.", 100);
        LibraryWarehouse.ReleaseTransferOrder(OrderTransferHeader);

        // [GIVEN] The generation rule is set to trigger on transfer order receive post
        QltyInspectionGenRule."Transfer Order Trigger" := QltyInspectionGenRule."Transfer Order Trigger"::OnTransferOrderPostReceive;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The transfer order is posted to receive
        Codeunit.Run(Codeunit::"TransferOrder-Post Transfer", OrderTransferHeader);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code, location, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ToLocation.Code, QltyInspectionHeader."Location Code", 'Location code should match the "To" Location');
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateInspectionOn_OnTransferReceivePost_LotTracked()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from transfer order with in-transit for lot-tracked item on receive post

        // [GIVEN] From, To, and In-Transit locations are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] A quality inspection template and transfer line generation rule are set up
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Transfer Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created, received at From location, and inventory is available with lot tracking
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(FromLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A transfer order is created with in-transit location, lot tracking is assigned, and it is released
        LibraryWarehouse.CreateTransferHeader(OrderTransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(OrderTransferHeader, TransferLine, Item."No.", 100);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', ReservationEntry."Lot No.", 100);
        LibraryWarehouse.ReleaseTransferOrder(OrderTransferHeader);

        // [GIVEN] The generation rule is set to trigger on transfer order receive post
        QltyInspectionGenRule."Transfer Order Trigger" := QltyInspectionGenRule."Transfer Order Trigger"::OnTransferOrderPostReceive;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The transfer order is posted to ship and receive
        LibraryWarehouse.PostTransferOrder(OrderTransferHeader, true, true);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code, location, lot number, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ToLocation.Code, QltyInspectionHeader."Location Code", 'Location code should match the "To" Location');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match source');
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateInspectionOn_OnTransferReceivePost()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DummyReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from transfer order with in-transit for standard item on receive post

        // [GIVEN] From, To, and In-Transit locations are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] A quality inspection template and transfer line generation rule are set up
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Transfer Line", QltyInspectionGenRule);

        // [GIVEN] A standard item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, received at From location, and inventory is available
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(FromLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A transfer order is created with in-transit location and released
        LibraryWarehouse.CreateTransferHeader(OrderTransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(OrderTransferHeader, TransferLine, Item."No.", 100);
        LibraryWarehouse.ReleaseTransferOrder(OrderTransferHeader);

        // [GIVEN] The generation rule is set to trigger on transfer order receive post
        QltyInspectionGenRule."Transfer Order Trigger" := QltyInspectionGenRule."Transfer Order Trigger"::OnTransferOrderPostReceive;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The transfer order is posted to ship and receive
        LibraryWarehouse.PostTransferOrder(OrderTransferHeader, true, true);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code, location, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ToLocation.Code, QltyInspectionHeader."Location Code", 'Location code should match the "To" Location');
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match.');
    end;

    [Test]
    procedure WarehouseIntegration_AttemptCreateInspectionWithWhseJournalLine()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWarehouseJournalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        Item: Record Item;
        Bin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionHeaderForCounting: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from warehouse journal line with warehouse movement integration

        // [GIVEN] Setup is ensured and a quality inspection template is created
        Initialize();
        LibraryERMCountryData.CreateVATData();
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full WMS location is created with bins and zones
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A warehouse journal template and batch are created for reclassification
        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created, received, and inventory is available with lot tracking
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A warehouse entry is found for the received lot-tracked item in a bin
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        // [GIVEN] A warehouse reclassification journal line is created to move items between bins
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);
        QltyInspectionUtility.CreateReclassWhseJournalLine(ReclassWarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code,
            WarehouseEntry."Zone Code", WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."Entry Type"::Movement, Item."No.", 50);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        ReclassWarehouseJournalLine."From Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."From Bin Code" := WarehouseEntry."Bin Code";
        ReclassWarehouseJournalLine."To Zone Code" := WarehouseEntry."Zone Code";
        ReclassWarehouseJournalLine."To Bin Code" := Bin.Code;
        ReclassWarehouseJournalLine."Lot No." := ReservationEntry."Lot No.";
        ReclassWarehouseJournalLine."New Lot No." := ReclassWarehouseJournalLine."Lot No.";
        ReclassWarehouseJournalLine."Source Line No." := PurchaseLine."Line No.";
        ReclassWarehouseJournalLine."Source Type" := Database::"Purchase Line";
        ReclassWarehouseJournalLine."Source Subtype" := PurchaseHeader."Document Type".AsInteger();
        ReclassWarehouseJournalLine."Source No." := PurchaseHeader."No.";
        ReclassWarehouseJournalLine.Modify();
        LibraryItemTracking.CreateWhseJournalLineItemTracking(ReclassWarehouseJournalWhseItemTrackingLine, ReclassWarehouseJournalLine, '', ReservationEntry."Lot No.", 50);
        ReclassWarehouseJournalWhseItemTrackingLine."New Lot No." := ReclassWarehouseJournalWhseItemTrackingLine."Lot No.";
        ReclassWarehouseJournalWhseItemTrackingLine.Modify();

        // [GIVEN] The generation rule is set to trigger on warehouse movement register
        QltyInspectionGenRule."Warehouse Movement Trigger" := QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeaderForCounting.Count();

        // [WHEN] The warehouse journal line is registered
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code, true);

        // [THEN] One quality inspection is created with matching template code, lot number, and quantity
        LibraryAssert.AreEqual(BeforeCount + 1, QltyInspectionHeaderForCounting.Count(), 'Should be one new inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match.');
        LibraryAssert.AreEqual(50, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match.');
    end;

    [Test]
    procedure WarehouseIntegration_CreateInspectionDuringReceive()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Item: Record Item;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ForCountQltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        OrdQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection during warehouse receipt process for lot-tracked items into bin

        // [GIVEN] Quality management setup with template and warehouse entry generation rule are configured
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full WMS location with warehouse journal template and batch are set up
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] The generation rule is set to trigger on movement into bin and a lot-tracked item is created
        QltyInspectionGenRule."Warehouse Movement Trigger" := QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister;
        QltyInspectionGenRule.Modify();

        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created and released
        OrdQltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        BeforeCount := ForCountQltyInspectionHeader.Count();

        // [WHEN] The purchase order is received
        OrdQltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [THEN] One quality inspection is created with matching template code, lot number, and full received quantity
        LibraryAssert.AreEqual(BeforeCount + 1, ForCountQltyInspectionHeader.Count(), 'Should be one new inspection created during receive.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match.');
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match full received quantity.');
    end;

    [Test]
    procedure WarehouseIntegration_SalesPickShipBin()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Zone: Record Zone;
        BinType: Record "Bin Type";
        WarehouseEntry: Record "Warehouse Entry";
        Item: Record Item;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ForCountQltyInspectionHeader: Record "Qlty. Inspection Header";
        Customer: Record Customer;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        OrdQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection during warehouse pick operation from storage bin to ship bin for sales order

        // [GIVEN] Quality management setup with template and warehouse entry generation rule are configured
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A full WMS location is created and a lot-tracked item is available in inventory
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyInspectionUtility.CreateLotTrackedItem(Item);
        OrdQltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        OrdQltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A warehouse entry is found and the bin type is configured for picking
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        Zone.Get(Location.Code, WarehouseEntry."Zone Code");
        BinType.Get(Zone."Bin Type Code");
        if not BinType.Pick then begin
            BinType.Pick := true;
            BinType.Modify();
        end;

        // [GIVEN] A sales order is created with lot tracking and warehouse shipment is prepared
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 50);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify();
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', ReservationEntry."Lot No.", 50);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] The generation rule is set to trigger on movement into bin
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        QltyInspectionGenRule."Warehouse Movement Trigger" := QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister;
        QltyInspectionGenRule.Modify();

        BeforeCount := ForCountQltyInspectionHeader.Count();

        // [WHEN] The warehouse pick activity is registered to move items to ship bin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] One quality inspection is created with matching template code, lot number, and picked quantity
        LibraryAssert.AreEqual(BeforeCount + 1, ForCountQltyInspectionHeader.Count(), 'Should be one new inspection created during warehouse pick to ship bin.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match.');
        LibraryAssert.AreEqual(50, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match picked quantity.');
    end;

    [Test]
    procedure WarehouseIntegration_TransferPickShipBin()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        Zone: Record Zone;
        BinType: Record "Bin Type";
        WarehouseEntry: Record "Warehouse Entry";
        Item: Record Item;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ForCountQltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection during warehouse pick operation from storage bin to ship bin for transfer order

        // [GIVEN] Quality management setup with template and warehouse entry generation rule are configured
        Initialize();
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] From, To, and In-Transit locations are set up with lot-tracked item in inventory
        LibraryWarehouse.CreateFullWMSLocation(FromLocation, 3);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        QltyInspectionUtility.CreateLotTrackedItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(FromLocation, PurchaseHeader, PurchaseLine);

        // [GIVEN] A warehouse entry is found and the bin type is configured for picking
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", FromLocation.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        Zone.Get(FromLocation.Code, WarehouseEntry."Zone Code");
        BinType.Get(Zone."Bin Type Code");
        if not BinType.Pick then begin
            BinType.Pick := true;
            BinType.Modify();
        end;

        // [GIVEN] A transfer order is created with lot tracking and warehouse shipment is prepared
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 50);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', ReservationEntry."Lot No.", 50);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        WarehouseShipmentHeader.SetRange("Location Code", FromLocation.Code);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] The generation rule is set to trigger on movement into bin
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        QltyInspectionGenRule."Warehouse Movement Trigger" := QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister;
        QltyInspectionGenRule.Modify();

        BeforeCount := ForCountQltyInspectionHeader.Count();

        // [WHEN] The warehouse pick activity is registered to move items to ship bin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Location Code", FromLocation.Code);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] One quality inspection is created with matching template code, lot number, and picked quantity
        LibraryAssert.AreEqual(BeforeCount + 1, ForCountQltyInspectionHeader.Count(), 'Should be one new inspection created during warehouse pick to ship bin.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Inspection lot no. should match.');
        LibraryAssert.AreEqual(50, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match picked quantity.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithPurchaseLineAndTracking_MultiLot_OnPurchRelease()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        FirstReservationEntry: Record "Reservation Entry";
        SecondReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create quality inspections from purchase line with multiple lot tracking on purchase release

        // [GIVEN] A WMS location and quality inspection template with purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created with one reservation entry
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, FirstReservationEntry);

        // [GIVEN] The reservation entry is split into two lots of 50 each
        SecondReservationEntry.TransferFields(FirstReservationEntry);
        SecondReservationEntry."Entry No." := 0;
        SecondReservationEntry.Validate("Quantity (Base)", 50);
        FirstReservationEntry.Validate("Quantity (Base)", 50);
        FirstReservationEntry.Modify();
        SecondReservationEntry.Insert();

        // [GIVEN] The generation rule is set to trigger on purchase order release
        QltyInspectionGenRule."Purchase Order Trigger" := QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderRelease;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The purchase order is released
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] Two quality inspections are created, each with matching template code and quantity of 50
        LibraryAssert.AreEqual((BeforeCount + 2), QltyInspectionHeader.Count(), 'Should be two inspections created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindSet();
        repeat
            LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
            LibraryAssert.AreEqual(50, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity(base) should match reservation entry quantity, not qty. to receive.');
        until QltyInspectionHeader.Next() = 0;
    end;

    [Test]
    procedure AttemptCreateInspectionWithPurchaseLineAndTracking_LotTracked_Unassigned_OnPurchRelease()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from purchase line with lot-tracked item but unassigned lot on purchase release

        // [GIVEN] A WMS location and quality inspection template with purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created with a reservation entry that is then deleted to simulate unassigned lot
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);

        ReservationEntry.Delete();

        // [GIVEN] The generation rule is set to trigger on purchase order release
        QltyInspectionGenRule."Purchase Order Trigger" := QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderRelease;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [GIVEN] The quantity to receive is set to 50
        PurOrdPurchaseLine.Validate("Qty. to Receive (Base)", 50);
        PurOrdPurchaseLine.Modify();

        // [WHEN] The purchase order is released
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code and quantity matching qty. to receive
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(50, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity (base) should match qty. to receive.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithPurchaseLine_Untracked_OnPurchRelease()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from purchase line with untracked item on purchase release

        // [GIVEN] A WMS location and quality inspection template with purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A standard item without item tracking is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created for the untracked item
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);

        // [GIVEN] The generation rule is set to trigger on purchase order release
        QltyInspectionGenRule."Purchase Order Trigger" := QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderRelease;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [GIVEN] The quantity to receive is set to 50
        PurOrdPurchaseLine.Validate("Qty. to Receive (Base)", 50);
        PurOrdPurchaseLine.Modify();

        // [WHEN] The purchase order is released
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection is created with matching template code and quantity matching qty. to receive
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one inspection created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(50, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity (base) should match qty. to receive.');
    end;

    [Test]
    procedure AttemptCreateInspectionWithPurchaseLineAndTracking_SerialTracked_OnPurchRelease()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        IWXOrdQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        QltyInspectionUtility.CreateSerialTrackedItem(Item);

        IWXOrdQltyPurOrderGenerator.CreatePurchaseOrder(2, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);

        QltyInspectionGenRule."Purchase Order Trigger" := QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderRelease;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        LibraryAssert.AreEqual(BeforeCount + 2, QltyInspectionHeader.Count(), 'Should be two inspections created.');
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.FindSet();
        repeat
            LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Template code should match provided template');
            LibraryAssert.AreEqual(1, QltyInspectionHeader."Source Quantity (Base)", 'Inspection quantity (base) should be 1 for serial-tracked items.');
        until QltyInspectionHeader.Next() = 0;
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(MessageText: Text)
    begin
    end;
}
