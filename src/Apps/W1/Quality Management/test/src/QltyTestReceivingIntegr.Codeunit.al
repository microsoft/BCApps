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
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using System.TestLibraries.Utilities;

codeunit 139958 "Qlty. Test Receiving Integr."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        IsInitialized: Boolean;

    [Test]
    procedure AttemptCreateTestWithPurchaseLineAndTracking_LotTracked()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from a lot-tracked purchase order when receiving

        // [GIVEN] A WMS location, quality inspection template, and generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on purchase order receive
        QltyInTestGenerationRule."Purchase Trigger" := QltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderPostReceive;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is received
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code, lot number, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ResReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Test lot no. should match purchase.');
        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateTestWithPurchaseLineAndTracking_OnPurchPost()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        UnusedResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from a purchase order without lot tracking when receiving

        // [GIVEN] A WMS location, quality inspection template, and generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A standard item (not lot-tracked) is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, UnusedResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on purchase order receive
        QltyInTestGenerationRule."Purchase Trigger" := QltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderPostReceive;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is received
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateTestWithWhseJournalLine_LotTracked_OnReceiptPost()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from warehouse journal line for lot-tracked item on receipt post

        // [GIVEN] A full WMS location, quality inspection template, and warehouse journal generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Journal Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt post
        QltyInTestGenerationRule."Warehouse Receive Trigger" := QltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptPost;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code, lot number, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ResReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Test lot no. should match purchase.');

        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateTestWithWhseJournalLine_LotTracked_OnReceiptCreate()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from warehouse receipt line for lot-tracked item on receipt create

        // [GIVEN] A full WMS location, quality inspection template, and warehouse receipt line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Receipt Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt create
        QltyInTestGenerationRule."Warehouse Receive Trigger" := QltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code and lot number
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ResReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Test lot no. should match purchase.');
    end;

    [Test]
    procedure AttemptCreateTestWithWhseJournalLine()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        UnusedResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from warehouse journal line for standard item on receipt post

        // [GIVEN] A full WMS location, quality inspection template, and warehouse journal generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Journal Line", QltyInTestGenerationRule);

        // [GIVEN] A standard item (not lot-tracked) is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, UnusedResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt post
        QltyInTestGenerationRule."Warehouse Receive Trigger" := QltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptPost;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateTestWithReceiptLine_LotTracked_OnReceiptPost()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from purchase line for lot-tracked item on warehouse receipt post

        // [GIVEN] A full WMS location, quality inspection template, and purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt post
        QltyInTestGenerationRule."Warehouse Receive Trigger" := QltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptPost;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code and lot number
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ResReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Test lot no. should match purchase.');
    end;

    [Test]
    procedure AttemptCreateTestWithReceiptLine_LotTracked_OnReceiptCreate()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        ResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from purchase line for lot-tracked item on warehouse receipt create

        // [GIVEN] A full WMS location, quality inspection template, and purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order with lot tracking is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt create
        QltyInTestGenerationRule."Warehouse Receive Trigger" := QltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ResReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Test lot no. should match purchase.');
    end;

    [Test]
    procedure AttemptCreateTestWithReceiptLine()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        UnusedResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from purchase line for standard item on warehouse receipt create

        // [GIVEN] A full WMS location, quality inspection template, and purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A standard item (not lot-tracked) is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created and released
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, UnusedResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        // [GIVEN] The generation rule is set to trigger on warehouse receipt create
        QltyInTestGenerationRule."Warehouse Receive Trigger" := QltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is received through warehouse receipt
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
    end;

    [Test]
    procedure AttemptCreateTestOnSalesReturnPost_LotTracked()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        Customer: Record Customer;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RtnOrderSalesHeader: Record "Sales Header";
        RtnSalesLine: Record "Sales Line";
        ResReservationEntry: Record "Reservation Entry";
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
        // [SCENARIO] Create a quality inspection test from sales return order for lot-tracked item on receive post

        // [GIVEN] A WMS location, quality inspection template, and sales line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Sales Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item with unit cost and price is created
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);
        UnitCost := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        UnitPrice := LibraryRandom.RandDecInDecimalRange(2, 20, 2);
        Item."Unit Cost" := UnitCost;
        Item."Unit Price" := UnitPrice;
        Item.Modify();

        // [GIVEN] A purchase order is created, received, and inventory is available
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A sales order is created and shipped with lot tracking
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(OrderSalesHeader, OrderSalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, OrderSalesHeader, SalesLine.Type::Item, Item."No.", 100);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Qty. to Ship", 100);
        SalesLine.Modify();
        LibraryItemTracking.CreateSalesOrderItemTracking(ResReservationEntry, SalesLine, '', ResReservationEntry."Lot No.", 100);
        LibrarySales.PostSalesDocument(OrderSalesHeader, true, false);

        // [GIVEN] A sales return order is created with lot tracking and released
        LibrarySales.CreateSalesReturnOrderWithLocation(RtnOrderSalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLineWithUnitPrice(RtnSalesLine, RtnOrderSalesHeader, Item."No.", UnitPrice, 100);
        LibraryItemTracking.CreateSalesOrderItemTracking(ResReservationEntry, RtnSalesLine, '', ResReservationEntry."Lot No.", 100);
        LibrarySales.ReleaseSalesDocument(RtnOrderSalesHeader);

        // [GIVEN] The generation rule is set to trigger on sales return order receive
        QltyInTestGenerationRule."Sales Return Trigger" := QltyInTestGenerationRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The sales return order is posted to receive
        LibrarySales.PostSalesDocument(RtnOrderSalesHeader, true, false);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ResReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Test lot no. should match purchase.');
    end;

    [Test]
    procedure AttemptCreateTestOnSalesReturnPost()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        Customer: Record Customer;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RtnOrderSalesHeader: Record "Sales Header";
        RtnSalesLine: Record "Sales Line";
        UnusedResReservationEntry: Record "Reservation Entry";
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
        // [SCENARIO] Create a quality inspection test from sales return order for standard item on receive post

        // [GIVEN] A WMS location, quality inspection template, and sales line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Sales Line", QltyInTestGenerationRule);

        // [GIVEN] A standard item with unit cost and price is created
        UnitCost := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        UnitPrice := LibraryRandom.RandDecInDecimalRange(2, 20, 2);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, UnitPrice, UnitCost);

        // [GIVEN] A purchase order is created, received, and inventory is available
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, UnusedResReservationEntry);
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
        QltyInTestGenerationRule."Sales Return Trigger" := QltyInTestGenerationRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The sales return order is posted to receive
        LibrarySales.PostSalesDocument(RtnOrderSalesHeader, true, false);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AttemptCreateTestOn_OnTransferReceivePost_LotTracked_Direct()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from direct transfer order for lot-tracked item on receive post

        // [GIVEN] From and To locations are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);

        // [GIVEN] A quality inspection template and transfer line generation rule are set up
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Transfer Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order is created, received at From location, and inventory is available with lot tracking
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ResReservationEntry);
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
        LibraryItemTracking.CreateTransferOrderItemTracking(ResReservationEntry, TransferLine, '', ResReservationEntry."Lot No.", 100);
        LibraryWarehouse.ReleaseTransferOrder(OrderTransferHeader);

        // [GIVEN] The generation rule is set to trigger on transfer order receive post
        QltyInTestGenerationRule."Transfer Trigger" := QltyInTestGenerationRule."Transfer Trigger"::OnTransferOrderPostReceive;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The transfer order is posted to receive
        Codeunit.Run(Codeunit::"TransferOrder-Post Transfer", OrderTransferHeader);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code, location, lot number, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ToLocation.Code, QltyInspectionTestHeader."Location Code", 'Location code should match the "To" Location');
        LibraryAssert.AreEqual(ResReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Lot no. should match source');
        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AttemptCreateTestOn_OnTransferReceivePost_Direct()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        UnusedResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from direct transfer order for standard item on receive post

        // [GIVEN] From and To locations are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);

        // [GIVEN] A quality inspection template and transfer line generation rule are set up
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Transfer Line", QltyInTestGenerationRule);

        // [GIVEN] A standard item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, received at From location, and inventory is available
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, UnusedResReservationEntry);
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
        QltyInTestGenerationRule."Transfer Trigger" := QltyInTestGenerationRule."Transfer Trigger"::OnTransferOrderPostReceive;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The transfer order is posted to receive
        Codeunit.Run(Codeunit::"TransferOrder-Post Transfer", OrderTransferHeader);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code, location, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ToLocation.Code, QltyInspectionTestHeader."Location Code", 'Location code should match the "To" Location');
        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateTestOn_OnTransferReceivePost_LotTracked()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from transfer order with in-transit for lot-tracked item on receive post

        // [GIVEN] From, To, and In-Transit locations are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] A quality inspection template and transfer line generation rule are set up
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Transfer Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order is created, received at From location, and inventory is available with lot tracking
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(FromLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A transfer order is created with in-transit location, lot tracking is assigned, and it is released
        LibraryWarehouse.CreateTransferHeader(OrderTransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(OrderTransferHeader, TransferLine, Item."No.", 100);
        LibraryItemTracking.CreateTransferOrderItemTracking(ResReservationEntry, TransferLine, '', ResReservationEntry."Lot No.", 100);
        LibraryWarehouse.ReleaseTransferOrder(OrderTransferHeader);

        // [GIVEN] The generation rule is set to trigger on transfer order receive post
        QltyInTestGenerationRule."Transfer Trigger" := QltyInTestGenerationRule."Transfer Trigger"::OnTransferOrderPostReceive;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The transfer order is posted to ship and receive
        LibraryWarehouse.PostTransferOrder(OrderTransferHeader, true, true);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code, location, lot number, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ToLocation.Code, QltyInspectionTestHeader."Location Code", 'Location code should match the "To" Location');
        LibraryAssert.AreEqual(ResReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Lot no. should match source');
        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateTestOn_OnTransferReceivePost()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        OrderTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        UnusedResReservationEntry: Record "Reservation Entry";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        UnusedItemVariant: Code[10];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from transfer order with in-transit for standard item on receive post

        // [GIVEN] From, To, and In-Transit locations are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, false, false, false);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] A quality inspection template and transfer line generation rule are set up
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Transfer Line", QltyInTestGenerationRule);

        // [GIVEN] A standard item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created, received at From location, and inventory is available
        UnusedItemVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, FromLocation, Item, Vendor, UnusedItemVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, UnusedResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(FromLocation, PurOrderPurchaseHeader, PurOrdPurchaseLine);

        // [GIVEN] A transfer order is created with in-transit location and released
        LibraryWarehouse.CreateTransferHeader(OrderTransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(OrderTransferHeader, TransferLine, Item."No.", 100);
        LibraryWarehouse.ReleaseTransferOrder(OrderTransferHeader);

        // [GIVEN] The generation rule is set to trigger on transfer order receive post
        QltyInTestGenerationRule."Transfer Trigger" := QltyInTestGenerationRule."Transfer Trigger"::OnTransferOrderPostReceive;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The transfer order is posted to ship and receive
        LibraryWarehouse.PostTransferOrder(OrderTransferHeader, true, true);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code, location, and quantity
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ToLocation.Code, QltyInspectionTestHeader."Location Code", 'Location code should match the "To" Location');
        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    procedure WarehouseIntegration_AttemptCreateTestWithWhseJournalLine()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        ReclassWarehouseJournalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        Item: Record Item;
        Bin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestHeaderForCounting: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from warehouse journal line with warehouse movement integration

        // [GIVEN] Setup is ensured and a quality inspection template is created
        Initialize();
        LibraryERMCountryData.CreateVATData();
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);

        // [GIVEN] A full WMS location is created with bins and zones
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] A warehouse journal template and batch are created for reclassification
        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(
            WarehouseJournalTemplate,
            WarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(
            WarehouseJournalBatch,
            WarehouseJournalTemplate.Name,
            Location.Code);
        QltyManagementSetup."Bin Whse. Move Batch Name" := WarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

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
        QltyTestsUtility.SetCurrLocationWhseEmployee(Location.Code);
        QltyTestsUtility.CreateReclassWhseJournalLine(ReclassWarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code,
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
        QltyInTestGenerationRule."Warehouse Movement Trigger" := QltyInTestGenerationRule."Warehouse Movement Trigger"::OnWhseMovementRegister;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeaderForCounting.Count();

        // [WHEN] The warehouse journal line is registered
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code, true);

        // [THEN] One quality inspection test is created with matching template code, lot number, and quantity
        LibraryAssert.AreEqual(BeforeCount + 1, QltyInspectionTestHeaderForCounting.Count(), 'Should be one new test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", QltyInspectionTestHeader."Source Lot No.", 'Test lot no. should match.');
        LibraryAssert.AreEqual(50, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match.');
    end;

    [Test]
    procedure AttemptCreateTestWithPurchaseLineAndTracking_MultiLot_OnPurchRelease()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
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
        // [SCENARIO] Create quality inspection tests from purchase line with multiple lot tracking on purchase release

        // [GIVEN] A WMS location and quality inspection template with purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

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
        QltyInTestGenerationRule."Purchase Trigger" := QltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderRelease;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The purchase order is released
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] Two quality inspection tests are created, each with matching template code and quantity of 50
        LibraryAssert.AreEqual((BeforeCount + 2), QltyInspectionTestHeader.Count(), 'Should be two tests created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindSet();
        repeat
            LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
            LibraryAssert.AreEqual(50, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity(base) should match reservation entry quantity, not qty. to receive.');
        until QltyInspectionTestHeader.Next() = 0;
    end;

    [Test]
    procedure AttemptCreateTestWithPurchaseLineAndTracking_LotTracked_Unassigned_OnPurchRelease()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
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
        // [SCENARIO] Create a quality inspection test from purchase line with lot-tracked item but unassigned lot on purchase release

        // [GIVEN] A WMS location and quality inspection template with purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A lot-tracked item is created with lot number series
        QltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order is created with a reservation entry that is then deleted to simulate unassigned lot
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, ReservationEntry);

        ReservationEntry.Delete();

        // [GIVEN] The generation rule is set to trigger on purchase order release
        QltyInTestGenerationRule."Purchase Trigger" := QltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderRelease;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [GIVEN] The quantity to receive is set to 50
        PurOrdPurchaseLine.Validate("Qty. to Receive (Base)", 50);
        PurOrdPurchaseLine.Modify();

        // [WHEN] The purchase order is released
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code and quantity matching qty. to receive
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(50, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity (base) should match qty. to receive.');
    end;

    [Test]
    procedure AttemptCreateTestWithPurchaseLine_Untracked_OnPurchRelease()
    var
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        UnusedReservationEntry: Record "Reservation Entry";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from purchase line with untracked item on purchase release

        // [GIVEN] A WMS location and quality inspection template with purchase line generation rule are set up
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A standard item without item tracking is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created for the untracked item
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrderPurchaseHeader, PurOrdPurchaseLine, UnusedReservationEntry);

        // [GIVEN] The generation rule is set to trigger on purchase order release
        QltyInTestGenerationRule."Purchase Trigger" := QltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderRelease;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [GIVEN] The quantity to receive is set to 50
        PurOrdPurchaseLine.Validate("Qty. to Receive (Base)", 50);
        PurOrdPurchaseLine.Modify();

        // [WHEN] The purchase order is released
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One quality inspection test is created with matching template code and quantity matching qty. to receive
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one test created.');
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Template code should match provided template');
        LibraryAssert.AreEqual(50, QltyInspectionTestHeader."Source Quantity (Base)", 'Test quantity (base) should match qty. to receive.');
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
