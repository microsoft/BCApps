// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

codeunit 133508 "E-Doc. PO Matching Unit Tests"
{
    Subtype = Test;
    TestType = UnitTest;

    var
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        IsInitialized: Boolean;

    [Test]
    procedure LoadAvailablePOLinesForEDocLineWithNoMatchedVendor()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        Initialize();
        ClearPurchaseDocumentsForVendor();
        // [SCENARIO] Loading available purchase order lines for an E-Document line with no linked vendor returns empty result
        // [GIVEN] An E-Document line with no linked vendor
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        // Create E-Document Purchase Header with no vendor
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := ''; // No linked vendor
        EDocumentPurchaseHeader.Modify();

        // Create E-Document Purchase Line
        LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] LoadAvailablePOLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] The temporary purchase line record should be empty
        Assert.IsTrue(TempPurchaseLine.IsEmpty(), 'Expected no purchase lines when E-Document line has no matched vendor');
    end;

    [Test]
    procedure LoadAvailablePOLinesForEDocLineWithVendorButNoPOLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        Initialize();
        ClearPurchaseDocumentsForVendor();
        // [SCENARIO] Loading available purchase order lines for an E-Document line with assigned BC vendor but no PO lines returns empty result
        // [GIVEN] An E-Document line with an assigned BC vendor but no purchase order lines exist for that vendor
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header with vendor
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // Create E-Document Purchase Line
        LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] LoadAvailablePOLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] The temporary purchase line record should be empty
        Assert.IsTrue(TempPurchaseLine.IsEmpty(), 'Expected no purchase lines when no PO lines exist for vendor');
    end;

    [Test]
    procedure LoadAvailablePOLinesReturnsUnmatchedPOLinesForSameVendor()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        ClearPurchaseDocumentsForVendor();
        // [SCENARIO] Loading available purchase order lines for an E-Document line returns unmatched PO lines for the same vendor
        // [GIVEN] An E-Document line with a matched vendor and multiple purchase order lines exist for that vendor, none matched to other E-Document lines
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header with vendor
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // Create E-Document Purchase Line
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with lines for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] LoadAvailablePOLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] All purchase order lines for the vendor should be loaded into the temporary record
        Assert.AreEqual(2, TempPurchaseLine.Count(), 'Expected 2 purchase lines to be loaded');
        TempPurchaseLine.FindSet();
        Assert.AreEqual(PurchaseLine1.SystemId, TempPurchaseLine.SystemId, 'First purchase line should match');
        TempPurchaseLine.Next();
        Assert.AreEqual(PurchaseLine2.SystemId, TempPurchaseLine.SystemId, 'Second purchase line should match');
    end;

    [Test]
    procedure LoadAvailablePOLinesExcludesLinesMatchedToOtherEDocLines()
    var
        EDocument1, EDocument2 : Record "E-Document";
        EDocumentPurchaseHeader1, EDocumentPurchaseHeader2 : Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2 : Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2, PurchaseLine3 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        ClearPurchaseDocumentsForVendor();
        // [SCENARIO] Loading available purchase order lines excludes lines already matched to other E-Document lines
        // [GIVEN] An E-Document line with a matched vendor, multiple PO lines for that vendor, some already matched to other E-Document lines
        LibraryEDocument.CreateInboundEDocument(EDocument1, EDocumentService);
        LibraryEDocument.CreateInboundEDocument(EDocument2, EDocumentService);

        // Create first E-Document Purchase Header and Line
        EDocumentPurchaseHeader1 := LibraryEDocument.MockPurchaseDraftPrepared(EDocument1);
        EDocumentPurchaseHeader1."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader1.Modify();
        EDocumentPurchaseLine1 := LibraryEDocument.InsertPurchaseDraftLine(EDocument1);

        // Create second E-Document Purchase Header and Line
        EDocumentPurchaseHeader2 := LibraryEDocument.MockPurchaseDraftPrepared(EDocument2);
        EDocumentPurchaseHeader2."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader2.Modify();
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument2);

        // Create Purchase Order with three lines for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine3, PurchaseHeader, PurchaseLine3.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match first PO line to first E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseLine1);

        // [WHEN] LoadAvailablePOLinesForEDocumentLine is called for the second E-Document line
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine2, TempPurchaseLine);

        // [THEN] Only unmatched PO lines should be loaded (excluding the first line that's already matched)
        Assert.AreEqual(2, TempPurchaseLine.Count(), 'Expected 2 unmatched purchase lines to be loaded');
        TempPurchaseLine.SetRange(SystemId, PurchaseLine1.SystemId);
        Assert.IsTrue(TempPurchaseLine.IsEmpty(), 'First purchase line should be excluded as it is already matched');
    end;

    [Test]
    procedure LoadAvailablePOLinesIncludesLinesMatchedToCurrentEDocLine()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        ClearPurchaseDocumentsForVendor();
        // [SCENARIO] Loading available purchase order lines includes lines already matched to the current E-Document line
        // [GIVEN] An E-Document line with a matched vendor and PO lines already matched to this E-Document line
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with lines for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match first PO line to the E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine1);

        // [WHEN] LoadAvailablePOLinesForEDocumentLine is called for the same E-Document line
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] The PO lines matched to this E-Document line should be included in the result
        Assert.AreEqual(2, TempPurchaseLine.Count(), 'Expected 2 purchase lines to be loaded (1 matched + 1 unmatched)');
        TempPurchaseLine.SetRange(SystemId, PurchaseLine1.SystemId);
        Assert.IsFalse(TempPurchaseLine.IsEmpty(), 'Matched purchase line should be included');
        TempPurchaseLine.SetRange(SystemId, PurchaseLine2.SystemId);
        Assert.IsFalse(TempPurchaseLine.IsEmpty(), 'Unmatched purchase line should be included');
    end;

    [Test]
    procedure LoadAvailablePOLinesFiltersByUoMWhenEDocLineHasUoMSpecified()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
        UnitOfMeasure1, UnitOfMeasure2 : Record "Unit of Measure";
        ItemUnitOfMeasure1, ItemUnitOfMeasure2 : Record "Item Unit of Measure";
    begin
        // [SCENARIO 619582] Loading available PO lines filters by UoM when E-Document line has UoM specified
        Initialize();
        ClearPurchaseDocumentsForVendor();

        // [GIVEN] Item "I" with two units of measure "UOM1" and "UOM2"
        LibraryEDocument.GetGenericItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure1);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure2);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure1, Item."No.", UnitOfMeasure1.Code, 1);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure2, Item."No.", UnitOfMeasure2.Code, 1);

        // [GIVEN] Purchase order with line "PL1" having UoM "UOM1" and line "PL2" having UoM "UOM2"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", 10);
        PurchaseLine1.Validate("Unit of Measure Code", UnitOfMeasure1.Code);
        PurchaseLine1.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", 10);
        PurchaseLine2.Validate("Unit of Measure Code", UnitOfMeasure2.Code);
        PurchaseLine2.Modify(true);

        // [GIVEN] E-Document line with UoM "UOM1" specified
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Unit of Measure" := UnitOfMeasure1.Code;
        EDocumentPurchaseLine.Modify();

        // [WHEN] LoadAvailablePOLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] Only PO line "PL1" with matching UoM "UOM1" is returned
        Assert.AreEqual(1, TempPurchaseLine.Count(), 'Expected only 1 purchase line with matching UoM');
        TempPurchaseLine.FindFirst();
        Assert.AreEqual(PurchaseLine1.SystemId, TempPurchaseLine.SystemId, 'Expected purchase line with matching UoM to be returned');
    end;

    [Test]
    procedure LoadAvailablePOLinesReturnsAllLinesWhenEDocLineHasNoUoMSpecified()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
        UnitOfMeasure1, UnitOfMeasure2 : Record "Unit of Measure";
        ItemUnitOfMeasure1, ItemUnitOfMeasure2 : Record "Item Unit of Measure";
    begin
        // [SCENARIO 619582] Loading available PO lines returns all lines when E-Document line has no UoM specified
        Initialize();
        ClearPurchaseDocumentsForVendor();

        // [GIVEN] Item "I" with two units of measure "UOM1" and "UOM2"
        LibraryEDocument.GetGenericItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure1);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure2);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure1, Item."No.", UnitOfMeasure1.Code, 1);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure2, Item."No.", UnitOfMeasure2.Code, 1);

        // [GIVEN] Purchase order with line "PL1" having UoM "UOM1" and line "PL2" having UoM "UOM2"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", 10);
        PurchaseLine1.Validate("Unit of Measure Code", UnitOfMeasure1.Code);
        PurchaseLine1.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", 10);
        PurchaseLine2.Validate("Unit of Measure Code", UnitOfMeasure2.Code);
        PurchaseLine2.Modify(true);

        // [GIVEN] E-Document line with no UoM specified
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Unit of Measure" := '';
        EDocumentPurchaseLine.Modify();

        // [WHEN] LoadAvailablePOLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] Both PO lines "PL1" and "PL2" are returned
        Assert.AreEqual(2, TempPurchaseLine.Count(), 'Expected 2 purchase lines when E-Document line has no UoM specified');
        TempPurchaseLine.SetRange(SystemId, PurchaseLine1.SystemId);
        Assert.IsFalse(TempPurchaseLine.IsEmpty(), 'First purchase line should be included');
        TempPurchaseLine.SetRange(SystemId, PurchaseLine2.SystemId);
        Assert.IsFalse(TempPurchaseLine.IsEmpty(), 'Second purchase line should be included');
    end;

    [Test]
    procedure LoadAvailablePOLinesReturnsNoLinesWhenNoMatchingUoMExists()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
        UnitOfMeasure1, UnitOfMeasure2, UnitOfMeasure3 : Record "Unit of Measure";
        ItemUnitOfMeasure1, ItemUnitOfMeasure2, ItemUnitOfMeasure3 : Record "Item Unit of Measure";
    begin
        // [SCENARIO 619582] Loading available PO lines returns no lines when E-Document line has UoM specified but no PO lines have matching UoM
        Initialize();
        ClearPurchaseDocumentsForVendor();

        // [GIVEN] Item "I" with three units of measure "UOM1", "UOM2", and "UOM3"
        LibraryEDocument.GetGenericItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure1);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure2);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure3);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure1, Item."No.", UnitOfMeasure1.Code, 1);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure2, Item."No.", UnitOfMeasure2.Code, 1);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure3, Item."No.", UnitOfMeasure3.Code, 1);

        // [GIVEN] Purchase order with line "PL1" having UoM "UOM1" and line "PL2" having UoM "UOM2"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", 10);
        PurchaseLine1.Validate("Unit of Measure Code", UnitOfMeasure1.Code);
        PurchaseLine1.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", 10);
        PurchaseLine2.Validate("Unit of Measure Code", UnitOfMeasure2.Code);
        PurchaseLine2.Modify(true);

        // [GIVEN] E-Document line with UoM "UOM3" specified (not matching any PO line)
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Unit of Measure" := UnitOfMeasure3.Code;
        EDocumentPurchaseLine.Modify();

        // [WHEN] LoadAvailablePOLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailablePOLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] No PO lines are returned
        Assert.IsTrue(TempPurchaseLine.IsEmpty(), 'Expected no purchase lines when no PO lines have matching UoM');
    end;

    [Test]
    procedure LoadPOLinesMatchedToEDocLineWithNoMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        Initialize();
        // [SCENARIO] Loading PO lines matched to an E-Document line with no matches returns empty result
        // [GIVEN] An E-Document line with no matched purchase order lines
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] LoadPOLinesMatchedToEDocumentLine is called
        EDocPOMatching.LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] The temporary purchase line record should be empty
        Assert.IsTrue(TempPurchaseLine.IsEmpty(), 'Expected no purchase lines when E-Document line has no matches');
    end;

    [Test]
    procedure LoadPOsMatchedToEDocLineWithNoMatchedPOLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPurchaseHeader: Record "Purchase Header" temporary;
    begin
        Initialize();
        // [SCENARIO] Loading POs matched to an E-Document line with no matched PO lines returns empty result
        // [GIVEN] An E-Document line with no matched purchase order lines
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] LoadPOsMatchedToEDocumentLine is called
        EDocPOMatching.LoadPOsMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseHeader);

        // [THEN] The temporary purchase header record should be empty
        Assert.IsTrue(TempPurchaseHeader.IsEmpty(), 'Expected no purchase headers when E-Document line has no matched PO lines');
    end;

    [Test]
    procedure LoadAvailableReceiptLinesForEDocLineWithNoMatchedPOLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary;
    begin
        Initialize();
        ClearPurchaseDocumentsForVendor();
        // [SCENARIO] Loading available receipt lines for an E-Document line with no matched PO lines returns empty result
        // [GIVEN] An E-Document line with no matched purchase order lines
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] LoadAvailableReceiptLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailableReceiptLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseReceiptLine);

        // [THEN] The temporary receipt line record should be empty
        Assert.IsTrue(TempPurchaseReceiptLine.IsEmpty(), 'Expected no receipt lines when E-Document line has no matched PO lines');
    end;

    [Test]
    procedure LoadReceiptsMatchedToEDocLineWithNoReceiptMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPurchaseReceiptHeader: Record "Purch. Rcpt. Header" temporary;
    begin
        Initialize();
        // [SCENARIO] Loading receipts matched to an E-Document line with no receipt line matches returns empty result
        // [GIVEN] An E-Document line with no receipt line matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] LoadReceiptsMatchedToEDocumentLine is called
        EDocPOMatching.LoadReceiptsMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseReceiptHeader);

        // [THEN] The temporary receipt header record should be empty
        Assert.IsTrue(TempPurchaseReceiptHeader.IsEmpty(), 'Expected no receipt headers when E-Document line has no receipt line matches');
    end;

    [Test]
    procedure CalculatePOMatchWarningsGeneratesMissingInformationWarning()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine1: Record "E-Document Purchase Line";
        EDocumentPurchaseLine2: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] Calculating PO match warnings generates missing information warning for item lines without proper setup
        // [GIVEN] An E-Document with item lines that have missing item or unit of measure information
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // Create item unit of measure
        LibraryEDocument.GetGenericItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);

        // Create first E-Document line with non-existent item, but valid unit of measure
        EDocumentPurchaseLine1 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine1."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine1."[BC] Unit of Measure" := ItemUnitOfMeasure.Code;
        EDocumentPurchaseLine1.Quantity := 5;
        EDocumentPurchaseLine1.Modify();

        // Create second E-Document line with valid item but non-existent unit of measure
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine2."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine2.Quantity := 10;
        EDocumentPurchaseLine2.Modify();

        // Create purchase order and lines to match to
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", 5);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", 10);
        PurchaseLine1."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        PurchaseLine1.Modify();
        PurchaseLine2."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        PurchaseLine2.Modify();

        // Match E-Document lines to purchase order lines
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseLine1);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine2, PurchaseLine2);

        // Setting the first line to have a non-existent item and the second line to have a non-existent UOM
        EDocumentPurchaseLine1."[BC] Purchase Type No." := 'NONE';
        EDocumentPurchaseLine1.Modify();
        EDocumentPurchaseLine2."[BC] Unit of Measure" := 'NONE';
        EDocumentPurchaseLine2.Modify();

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] MissingInformationForMatch warnings should be generated for both lines
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::MissingInformationForMatch);
        Assert.AreEqual(2, TempPOMatchWarnings.Count(), 'Expected 2 MissingInformationForMatch warnings to be generated');

        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine1.SystemId);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected MissingInformationForMatch warning for line with non-existent item');

        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine2.SystemId);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected MissingInformationForMatch warning for line with non-existent unit of measure');
    end;

    // Quantity warning tests use the following notation:
    //   I = Invoice quantity (from the e-document line)
    //   R = Remaining to invoice on the PO (Ordered - Previously Invoiced)
    //   J = Invoiceable quantity (Received - Previously Invoiced)
    [Test]
    procedure CalculatePOMatchWarningsNoWarningsWhenInvoiceWithinOrderAndReceipts()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] I < R and I < J — partial invoice within order and receipts generates no warnings
        // [GIVEN] PO=100, I=30, Rcv=50, PrevInv=0 → R=100, J=50
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        LibraryEDocument.GetGenericItem(Item);
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine."[BC] Purchase Type No." := Item."No.";
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := 30;
        EDocumentPurchaseLine.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 100);
        PurchaseLine."Qty. Invoiced (Base)" := 0;
        PurchaseLine."Qty. Received (Base)" := 50;
        PurchaseLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] No warnings should be generated
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Expected no warnings for (I < R, I < J)');
    end;

    [Test]
    procedure CalculatePOMatchWarningsGeneratesExceedsInvoiceableQtyWarning()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] I < R but I > J — invoice within order but exceeds uninvoiced receipts
        // [GIVEN] PO=100, I=50, Rcv=60, PrevInv=20 → R=80, J=40
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        LibraryEDocument.GetGenericItem(Item);
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine."[BC] Purchase Type No." := Item."No.";
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := 50;
        EDocumentPurchaseLine.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 100);
        PurchaseLine."Qty. Invoiced (Base)" := 20;
        PurchaseLine."Qty. Received (Base)" := 60;
        PurchaseLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] ExceedsInvoiceableQty warning should be generated
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsInvoiceableQty);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected ExceedsInvoiceableQty warning for (I < R, I > J)');

        // [THEN] ExceedsRemainingToInvoice warning should NOT be generated
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsRemainingToInvoice);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect ExceedsRemainingToInvoice warning');
    end;

    [Test]
    procedure CalculatePOMatchWarningsGeneratesOverReceiptWarning()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] I = R and I < J — invoice closes out order but there is an over-receipt
        // [GIVEN] PO=100, I=50, Rcv=120, PrevInv=50 → R=50, J=70
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        LibraryEDocument.GetGenericItem(Item);
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine."[BC] Purchase Type No." := Item."No.";
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := 50;
        EDocumentPurchaseLine.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 100);
        PurchaseLine."Qty. Invoiced (Base)" := 50;
        PurchaseLine."Qty. Received (Base)" := 120;
        PurchaseLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] OverReceipt warning should be generated
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::OverReceipt);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected OverReceipt warning for (I = R, I < J)');

        // [THEN] No other quantity warnings should be generated
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsInvoiceableQty);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect ExceedsInvoiceableQty warning');
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsRemainingToInvoice);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect ExceedsRemainingToInvoice warning');
    end;

    [Test]
    procedure CalculatePOMatchWarningsGeneratesExceedsRemainingToInvoiceWarning()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] I > R but I < J — invoice exceeds order but within receipts (over-receipt charged)
        // [GIVEN] PO=100, I=60, Rcv=120, PrevInv=50 → R=50, J=70
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        LibraryEDocument.GetGenericItem(Item);
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine."[BC] Purchase Type No." := Item."No.";
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := 60;
        EDocumentPurchaseLine.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 100);
        PurchaseLine."Qty. Invoiced (Base)" := 50;
        PurchaseLine."Qty. Received (Base)" := 120;
        PurchaseLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] ExceedsRemainingToInvoice warning should be generated
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsRemainingToInvoice);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected ExceedsRemainingToInvoice warning (I > R, I < J)');

        // [THEN] ExceedsInvoiceableQty warning should NOT be generated
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsInvoiceableQty);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect ExceedsInvoiceableQty warning');
    end;

    [Test]
    procedure CalculatePOMatchWarningsGeneratesBothWarningsWhenExceedingBothRemainingAndInvoiceable()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] I > R and I > J — invoice exceeds both order and receipts
        // [GIVEN] PO=100, I=80, Rcv=100, PrevInv=50 → R=50, J=50
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        LibraryEDocument.GetGenericItem(Item);
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine."[BC] Purchase Type No." := Item."No.";
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := 80;
        EDocumentPurchaseLine.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 100);
        PurchaseLine."Qty. Invoiced (Base)" := 50;
        PurchaseLine."Qty. Received (Base)" := 100;
        PurchaseLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] Both ExceedsInvoiceableQty and ExceedsRemainingToInvoice warnings should be generated
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsInvoiceableQty);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected ExceedsInvoiceableQty warning (I > R, I > J)');

        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsRemainingToInvoice);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected ExceedsRemainingToInvoice warning (I > R, I > J)');
    end;

    [Test]
    procedure AmountMismatchWarningRaisedWhenUnitCostExceedsTolerance()
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] The invoiced unit cost exceeds the matched order's unit cost beyond the allowed tolerance.
        // [GIVEN] Tolerance 5%; invoiced net unit cost 110, order net unit cost 100 -> 10% difference
        SetMatchingDifferencePct(5);
        CreateMatchedAmountDraftLine(EDocumentPurchaseHeader, EDocumentPurchaseLine, Item, 10, 110, 0);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseLine := AddOrderLineWithCost(PurchaseHeader, Item."No.", 10, 100, 0);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] An AmountMismatch warning is generated for the line
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::AmountMismatch);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected AmountMismatch warning when unit cost exceeds tolerance');
        SetMatchingDifferencePct(0);
    end;

    [Test]
    procedure NoAmountMismatchWarningWhenWithinTolerance()
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] The invoiced unit cost differs from the order's unit cost but stays within the allowed tolerance.
        // [GIVEN] Tolerance 5%; invoiced net unit cost 103, order net unit cost 100 -> 3% difference
        SetMatchingDifferencePct(5);
        CreateMatchedAmountDraftLine(EDocumentPurchaseHeader, EDocumentPurchaseLine, Item, 10, 103, 0);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseLine := AddOrderLineWithCost(PurchaseHeader, Item."No.", 10, 100, 0);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] No AmountMismatch warning is generated
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::AmountMismatch);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect AmountMismatch warning within tolerance');
        SetMatchingDifferencePct(0);
    end;

    [Test]
    procedure AmountMismatchHonorsAbsoluteDiscountOnDraftLine()
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] The draft line's Total Discount is an absolute amount, so it nets the invoiced unit cost down.
        // [GIVEN] Tolerance 1%; qty 10, unit price 100, total discount 50 -> net (1000-50)/10 = 95 vs order 100 -> 5%
        SetMatchingDifferencePct(1);
        CreateMatchedAmountDraftLine(EDocumentPurchaseHeader, EDocumentPurchaseLine, Item, 10, 100, 50);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseLine := AddOrderLineWithCost(PurchaseHeader, Item."No.", 10, 100, 0);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] An AmountMismatch warning is generated because the discounted unit cost is out of tolerance
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::AmountMismatch);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected AmountMismatch warning after applying the absolute discount');
        SetMatchingDifferencePct(0);
    end;

    [Test]
    procedure NoAmountWarningWhenThresholdZeroButOnlyRoundingNoise()
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] With a 0% tolerance, a sub-rounding-precision difference must not warn.
        // [GIVEN] Tolerance 0%; invoiced net unit cost 100.001 vs order 100 (difference below the 0.01 rounding precision)
        SetMatchingDifferencePct(0);
        CreateMatchedAmountDraftLine(EDocumentPurchaseHeader, EDocumentPurchaseLine, Item, 1, 100.001, 0);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseLine := AddOrderLineWithCost(PurchaseHeader, Item."No.", 1, 100, 0);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] No AmountMismatch warning is generated because the difference is within rounding precision
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::AmountMismatch);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect AmountMismatch warning for sub-rounding-precision noise');
    end;

    [Test]
    procedure NoAmountWarningWhenCurrenciesDiffer()
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] When the draft line currency differs from the order line currency, the cost comparison is skipped.
        // [GIVEN] Tolerance 5%; a large cost gap (200 vs 100) but the draft line is in a different currency than the LCY order
        SetMatchingDifferencePct(5);
        CreateMatchedAmountDraftLine(EDocumentPurchaseHeader, EDocumentPurchaseLine, Item, 10, 200, 0);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseLine := AddOrderLineWithCost(PurchaseHeader, Item."No.", 10, 100, 0);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);
        EDocumentPurchaseLine."Currency Code" := 'EUR';
        EDocumentPurchaseLine.Modify();

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] No AmountMismatch warning is generated because currencies differ
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::AmountMismatch);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect AmountMismatch warning when currencies differ');
        SetMatchingDifferencePct(0);
    end;

    [Test]
    procedure AmountMismatchUsesQuantityWeightedAverageAcrossMultiplePOLines()
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] The expected order unit cost is a quantity-weighted average of all matched order lines, not a simple mean.
        // [GIVEN] Tolerance 5%; order lines (cost 100, qty 30) and (cost 200, qty 10) -> weighted avg 125; invoiced net unit cost 125
        SetMatchingDifferencePct(5);
        CreateMatchedAmountDraftLine(EDocumentPurchaseHeader, EDocumentPurchaseLine, Item, 1, 125, 0);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseLine1 := AddOrderLineWithCost(PurchaseHeader, Item."No.", 30, 100, 0);
        PurchaseLine2 := AddOrderLineWithCost(PurchaseHeader, Item."No.", 10, 200, 0);
        TempPurchaseLine := PurchaseLine1;
        TempPurchaseLine.Insert();
        TempPurchaseLine := PurchaseLine2;
        TempPurchaseLine.Insert();
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentPurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] No AmountMismatch warning is generated; 125 matches the weighted average (a simple mean of 150 would warn)
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::AmountMismatch);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect AmountMismatch warning when invoiced cost equals the quantity-weighted average');
        SetMatchingDifferencePct(0);
    end;

    [Test]
    procedure NoAmountWarningWhenDraftQuantityZero()
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] A draft line with zero quantity has no derivable unit cost and must not warn or error.
        // [GIVEN] Tolerance 5%; draft quantity 0 with a unit price, matched to an order line with a different cost
        SetMatchingDifferencePct(5);
        CreateMatchedAmountDraftLine(EDocumentPurchaseHeader, EDocumentPurchaseLine, Item, 0, 100, 0);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseLine := AddOrderLineWithCost(PurchaseHeader, Item."No.", 10, 50, 0);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] No AmountMismatch warning is generated and no error is raised
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::AmountMismatch);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Did not expect AmountMismatch warning for a zero-quantity draft line');
        SetMatchingDifferencePct(0);
    end;

    [Test]
    procedure IsPOMatchConsistentReturnsTrueWhenAllMatchesAreValid()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
        IsConsistent: Boolean;
    begin
        Initialize();
        // [SCENARIO] PO match consistency check returns true when all matches are valid
        // [GIVEN] An E-Document with lines having valid PO and receipt line matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Create receipt and receipt line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine);

        // Match E-Document line to PO line and receipt line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        // [WHEN] IsPOMatchConsistent is called
        IsConsistent := EDocPOMatching.IsPOMatchConsistent(EDocumentPurchaseHeader);

        // [THEN] The result should be true
        Assert.IsTrue(IsConsistent, 'Expected PO match consistency check to return true when all matches are valid');
    end;

    [Test]
    procedure IsPOMatchConsistentReturnsFalseWhenReceiptLineMatchRefersToDeletedReceiptLine()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
        IsConsistent: Boolean;
    begin
        Initialize();
        // [SCENARIO] PO match consistency check returns false when receipt line match refers to non-existent receipt line
        // [GIVEN] An E-Document with a line having a receipt line match that refers to a deleted receipt line
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Create receipt and receipt line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine);

        // Match E-Document line to PO line and receipt line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        // Delete the receipt line to make the match invalid
        PurchaseReceiptLine.Delete();

        // [WHEN] IsPOMatchConsistent is called
        IsConsistent := EDocPOMatching.IsPOMatchConsistent(EDocumentPurchaseHeader);

        // [THEN] The result should be false
        Assert.IsFalse(IsConsistent, 'Expected PO match consistency check to return false when receipt line match refers to deleted receipt line');
    end;

    [Test]
    procedure IsPOMatchConsistentReturnsFalseWhenPOLineMatchRefersToDeletedPurchaseLine()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        IsConsistent: Boolean;
    begin
        Initialize();
        // [SCENARIO] PO match consistency check returns false when PO line match refers to non-existent purchase line
        // [GIVEN] An E-Document with a line having a PO line match that refers to a deleted purchase line
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match E-Document line to PO line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // Delete the purchase line to make the match invalid
        PurchaseLine.Delete();

        // [WHEN] IsPOMatchConsistent is called
        IsConsistent := EDocPOMatching.IsPOMatchConsistent(EDocumentPurchaseHeader);

        // [THEN] The result should be false
        Assert.IsFalse(IsConsistent, 'Expected PO match consistency check to return false when PO line match refers to deleted purchase line');
    end;

    [Test]
    procedure IsEDocumentLineMatchedReturnsFalseWhenNoMatchesExist()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] E-Document line matched check returns false when no matches exist
        // [GIVEN] An E-Document line with no PO line matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] IsEDocumentLineMatchedToAnyPOLine is called
        IsMatched := EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine);

        // [THEN] The result should be false
        Assert.IsFalse(IsMatched, 'Expected IsEDocumentLineMatchedToAnyPOLine to return false when no matches exist');
    end;

    [Test]
    procedure IsEDocumentLineMatchedReturnsTrueWhenMatchesExist()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] E-Document line matched check returns true when matches exist
        // [GIVEN] An E-Document line with one or more PO line matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match E-Document line to PO line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] IsEDocumentLineMatchedToAnyPOLine is called
        IsMatched := EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine);

        // [THEN] The result should be true
        Assert.IsTrue(IsMatched, 'Expected IsEDocumentLineMatchedToAnyPOLine to return true when matches exist');
    end;

    [Test]
    procedure IsEDocumentMatchedReturnsFalseWhenNoLinesAreMatched()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2 : Record "E-Document Purchase Line";
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] E-Document matched check returns false when no lines are matched
        // [GIVEN] An E-Document with purchase lines but none matched to PO lines
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // Create multiple E-Document Purchase Lines
        EDocumentPurchaseLine1 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] IsEDocumentMatchedToAnyPOLine is called
        IsMatched := EDocPOMatching.IsEDocumentMatchedToAnyPOLine(EDocumentPurchaseHeader);

        // [THEN] The result should be false
        Assert.IsFalse(IsMatched, 'Expected IsEDocumentMatchedToAnyPOLine to return false when no lines are matched');
    end;

    [Test]
    procedure IsEDocumentMatchedReturnsTrueWhenAtLeastOneLineIsMatched()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2 : Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] E-Document matched check returns true when at least one line is matched
        // [GIVEN] An E-Document with multiple purchase lines where at least one is matched to a PO line
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // Create multiple E-Document Purchase Lines
        EDocumentPurchaseLine1 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match only the first E-Document line to PO line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseLine);

        // [WHEN] IsEDocumentMatchedToAnyPOLine is called
        IsMatched := EDocPOMatching.IsEDocumentMatchedToAnyPOLine(EDocumentPurchaseHeader);

        // [THEN] The result should be true
        Assert.IsTrue(IsMatched, 'Expected IsEDocumentMatchedToAnyPOLine to return true when at least one line is matched');
    end;

    [Test]
    procedure IsPOLineMatchedToEDocumentLineWithNoMatch()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] PO line matched check returns false when no match exists
        // [GIVEN] A purchase line and E-Document line with no match between them
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] IsPOLineMatchedToEDocumentLine is called
        IsMatched := EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseLine, EDocumentPurchaseLine);

        // [THEN] The result should be false
        Assert.IsFalse(IsMatched, 'Expected PO line matched check to return false when no match exists');
    end;

    [Test]
    procedure IsPOLineMatchedToEDocumentLineWithMatch()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] PO line matched check returns true when match exists
        // [GIVEN] A purchase line and E-Document line with a match between them
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match the PO line to the E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] IsPOLineMatchedToEDocumentLine is called
        IsMatched := EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseLine, EDocumentPurchaseLine);

        // [THEN] The result should be true
        Assert.IsTrue(IsMatched, 'Expected PO line matched check to return true when match exists');
    end;

    [Test]
    procedure IsEDocumentLineMatchedToAnyReceiptLineWithNoMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] E-Document line receipt matched check returns false when no receipt line matches exist
        // [GIVEN] An E-Document line with no receipt line matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] IsEDocumentLineMatchedToAnyReceiptLine is called
        IsMatched := EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine);

        // [THEN] The result should be false
        Assert.IsFalse(IsMatched, 'Expected E-Document line receipt matched check to return false when no receipt line matches exist');
    end;

    [Test]
    procedure IsEDocumentLineMatchedToAnyReceiptLineWithMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] E-Document line receipt matched check returns true when receipt line matches exist
        // [GIVEN] An E-Document line with one or more receipt line matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match the PO line to the E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // Create receipt header and line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(10, 2), PurchaseLine);

        // Match the receipt line to the E-Document line
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        // [WHEN] IsEDocumentLineMatchedToAnyReceiptLine is called
        IsMatched := EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine);

        // [THEN] The result should be true
        Assert.IsTrue(IsMatched, 'Expected E-Document line receipt matched check to return true when receipt line matches exist');
    end;

    [Test]
    procedure IsReceiptLineMatchedToEDocumentLineWithNoMatch()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] Receipt line matched check returns false when no match exists
        // [GIVEN] A receipt line and E-Document line with no match between them
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Create receipt header and line (not matched)
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(10, 2), PurchaseLine);

        // [WHEN] IsReceiptLineMatchedToEDocumentLine is called
        IsMatched := EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine, EDocumentPurchaseLine);

        // [THEN] The result should be false
        Assert.IsFalse(IsMatched, 'Expected receipt line matched check to return false when no match exists');
    end;

    [Test]
    procedure IsReceiptLineMatchedToEDocumentLineWithMatch()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
        IsMatched: Boolean;
    begin
        Initialize();
        // [SCENARIO] Receipt line matched check returns true when match exists
        // [GIVEN] A receipt line and E-Document line with a match between them
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match the PO line to the E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // Create receipt header and line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(10, 2), PurchaseLine);

        // Match the receipt line to the E-Document line
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        // [WHEN] IsReceiptLineMatchedToEDocumentLine is called
        IsMatched := EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine, EDocumentPurchaseLine);

        // [THEN] The result should be true
        Assert.IsTrue(IsMatched, 'Expected receipt line matched check to return true when match exists');
    end;

    [Test]
    procedure RemoveAllReceiptMatchesForEDocumentLineWithNoMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        Initialize();
        // [SCENARIO] Removing all receipt matches for E-Document line with no matches completes without error
        // [GIVEN] An E-Document line with no receipt line matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // [WHEN] RemoveAllReceiptMatchesForEDocumentLine is called
        EDocPOMatching.RemoveAllReceiptMatchesForEDocumentLine(EDocumentPurchaseLine);

        // [THEN] The operation should complete without error and no matches should remain
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected no receipt line matches to remain');
    end;

    [Test]
    procedure RemoveAllReceiptMatchesForEDocumentLineRemovesOnlyReceiptMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Removing all receipt matches for E-Document line removes only receipt matches
        // [GIVEN] An E-Document line with both PO line matches and receipt line matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match the PO line to the E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // Create receipt header and line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(10, 2), PurchaseLine);

        // Match the receipt line to the E-Document line
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        // Verify both PO and receipt matches exist
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine), 'Expected PO line match to exist before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected receipt line match to exist before removal');

        // [WHEN] RemoveAllReceiptMatchesForEDocumentLine is called
        EDocPOMatching.RemoveAllReceiptMatchesForEDocumentLine(EDocumentPurchaseLine);

        // [THEN] Only receipt line matches should be removed, PO line matches should remain
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine), 'Expected PO line match to remain after receipt match removal');
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected receipt line matches to be removed');
    end;

    [Test]
    procedure RemoveAllReceiptMatchesForEDocumentLineDoesNotAffectOtherLines()
    var
        EDocument1, EDocument2 : Record "E-Document";
        EDocumentPurchaseHeader1, EDocumentPurchaseHeader2 : Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2 : Record "E-Document Purchase Line";
        PurchaseHeader1, PurchaseHeader2 : Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        PurchaseReceiptHeader1, PurchaseReceiptHeader2 : Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2 : Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Removing all receipt matches for E-Document line does not affect other E-Document lines
        // [GIVEN] Multiple E-Document lines with matches, removing receipt matches from one line
        LibraryEDocument.CreateInboundEDocument(EDocument1, EDocumentService);
        LibraryEDocument.CreateInboundEDocument(EDocument2, EDocumentService);

        // Create first E-Document Purchase Header and Line
        EDocumentPurchaseHeader1 := LibraryEDocument.MockPurchaseDraftPrepared(EDocument1);
        EDocumentPurchaseHeader1."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader1.Modify();
        EDocumentPurchaseLine1 := LibraryEDocument.InsertPurchaseDraftLine(EDocument1);

        // Create second E-Document Purchase Header and Line
        EDocumentPurchaseHeader2 := LibraryEDocument.MockPurchaseDraftPrepared(EDocument2);
        EDocumentPurchaseHeader2."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader2.Modify();
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument2);

        // Create Purchase Orders with lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader1, PurchaseHeader1."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader1, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader2, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match the PO lines to the E-Document lines
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseLine1);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine2, PurchaseLine2);

        // Create receipt headers and lines
        CreateMockReceiptHeader(PurchaseReceiptHeader1, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader1, Item."No.", LibraryRandom.RandDec(10, 2), PurchaseLine1);

        CreateMockReceiptHeader(PurchaseReceiptHeader2, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader2, Item."No.", LibraryRandom.RandDec(10, 2), PurchaseLine2);

        // Match the receipt lines to the E-Document lines
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine1, PurchaseReceiptLine1);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine2, PurchaseReceiptLine2);

        // Verify both lines have receipt matches
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine1), 'Expected first E-Document line to have receipt match before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine2), 'Expected second E-Document line to have receipt match before removal');

        // [WHEN] RemoveAllReceiptMatchesForEDocumentLine is called on one line
        EDocPOMatching.RemoveAllReceiptMatchesForEDocumentLine(EDocumentPurchaseLine1);

        // [THEN] Matches on other E-Document lines should remain unaffected
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine1), 'Expected first E-Document line receipt matches to be removed');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine2), 'Expected second E-Document line receipt matches to remain unaffected');
    end;

    [Test]
    procedure RemoveAllMatchesForEDocumentLineRemovesBothPOAndReceiptMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Removing all matches for E-Document line removes both PO and receipt matches
        // [GIVEN] An E-Document line with both PO and receipt matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order line for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Create Receipt line matched to PO line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine);

        // Match E-Document line to PO line and Receipt line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        // Verify both matches exist
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine), 'Expected E-Document line to have PO match before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected E-Document line to have receipt match before removal');

        // [WHEN] RemoveAllMatchesForEDocumentLine is called
        EDocPOMatching.RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine);

        // [THEN] Both PO and receipt matches should be removed
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine), 'Expected PO matches to be removed');
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected receipt matches to be removed');
    end;

    [Test]
    procedure RemoveAllMatchesForEDocumentLineDoesNotAffectOtherLines()
    var
        EDocument1, EDocument2 : Record "E-Document";
        EDocumentPurchaseHeader1, EDocumentPurchaseHeader2 : Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2 : Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2 : Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Removing all matches for E-Document line does not affect other lines
        // [GIVEN] Multiple E-Document lines with matches
        LibraryEDocument.CreateInboundEDocument(EDocument1, EDocumentService);
        LibraryEDocument.CreateInboundEDocument(EDocument2, EDocumentService);

        // Create first E-Document Purchase Header and Line
        EDocumentPurchaseHeader1 := LibraryEDocument.MockPurchaseDraftPrepared(EDocument1);
        EDocumentPurchaseHeader1."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader1.Modify();
        EDocumentPurchaseLine1 := LibraryEDocument.InsertPurchaseDraftLine(EDocument1);

        // Create second E-Document Purchase Header and Line
        EDocumentPurchaseHeader2 := LibraryEDocument.MockPurchaseDraftPrepared(EDocument2);
        EDocumentPurchaseHeader2."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader2.Modify();
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument2);

        // Create Purchase Order with two lines for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Create Receipt lines matched to PO lines
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine1);
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine2);

        // Match first E-Document line to first PO line and Receipt line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseLine1);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine1, PurchaseReceiptLine1);

        // Match second E-Document line to second PO line and Receipt line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine2, PurchaseLine2);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine2, PurchaseReceiptLine2);

        // Verify both lines have matches
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine1), 'Expected first E-Document line to have PO match before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine1), 'Expected first E-Document line to have receipt match before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine2), 'Expected second E-Document line to have PO match before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine2), 'Expected second E-Document line to have receipt match before removal');

        // [WHEN] RemoveAllMatchesForEDocumentLine is called on first line
        EDocPOMatching.RemoveAllMatchesForEDocumentLine(EDocumentPurchaseLine1);

        // [THEN] Matches on other E-Document lines should remain unaffected
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine1), 'Expected first E-Document line matches to be removed');
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine1), 'Expected first E-Document line matches to be removed');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine2), 'Expected second E-Document line matches to remain unaffected');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine2), 'Expected second E-Document line matches to remain unaffected');
    end;

    [Test]
    procedure RemoveAllMatchesForEDocumentRemovesAllLineMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2 : Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2 : Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Removing all matches for E-Document removes all matches for all lines in the document
        // [GIVEN] An E-Document with multiple lines, all having PO and receipt matches
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // Create two E-Document Purchase Lines
        EDocumentPurchaseLine1 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with two lines for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Create Receipt lines matched to PO lines
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine1);
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine2);

        // Match E-Document lines to PO lines and Receipt lines
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseLine1);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine1, PurchaseReceiptLine1);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine2, PurchaseLine2);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine2, PurchaseReceiptLine2);

        // Verify all matches exist
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine1), 'Expected first E-Document line to have PO match before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine1), 'Expected first E-Document line to have receipt match before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine2), 'Expected second E-Document line to have PO match before removal');
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine2), 'Expected second E-Document line to have receipt match before removal');

        // [WHEN] RemoveAllMatchesForEDocument is called
        EDocPOMatching.RemoveAllMatchesForEDocument(EDocumentPurchaseHeader);

        // [THEN] All matches for all lines in the document should be removed
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine1), 'Expected first E-Document line PO matches to be removed');
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine1), 'Expected first E-Document line receipt matches to be removed');
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine2), 'Expected second E-Document line PO matches to be removed');
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine2), 'Expected second E-Document line receipt matches to be removed');
    end;

    [Test]
    procedure MatchValidPOLinesToEDocumentLineCreatesMatchesAndUpdatesProperties()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching valid PO lines to E-Document line creates matches and updates E-Document line properties
        // [GIVEN] Valid PO lines from the same vendor with same type and number, and an E-Document line
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        // [WHEN] MatchPOLinesToEDocumentLine is called
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentPurchaseLine);

        // [THEN] Matches should be created and E-Document line should be updated with PO line properties
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine), 'Expected E-Document line to be matched to PO line');
        EDocumentPurchaseLine.GetBySystemId(EDocumentPurchaseLine.SystemId);
        Assert.AreEqual(PurchaseLine.Type, EDocumentPurchaseLine."[BC] Purchase Line Type", 'E-Document line type should be updated');
        Assert.AreEqual(PurchaseLine."No.", EDocumentPurchaseLine."[BC] Purchase Type No.", 'E-Document line number should be updated');
    end;

    [Test]
    procedure MatchPOLinesToEDocumentLineRemovesExistingMatchesFirst()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching PO lines to E-Document line removes existing matches first
        // [GIVEN] An E-Document line with existing matches and new PO lines to match
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with two lines for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match first PO line to E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine1);
        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseLine1, EDocumentPurchaseLine), 'First line should be matched');

        // Prepare to match second line
        TempPurchaseLine.DeleteAll();
        TempPurchaseLine := PurchaseLine2;
        TempPurchaseLine.Insert();

        // [WHEN] MatchPOLinesToEDocumentLine is called
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentPurchaseLine);

        // [THEN] Existing matches should be removed and new matches should be created
        Assert.IsFalse(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseLine1, EDocumentPurchaseLine), 'First line should no longer be matched');
        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseLine2, EDocumentPurchaseLine), 'Second line should be matched');
    end;

    [Test]
    procedure MatchPOLinesWithDifferentVendorsToEDocumentLineRaisesError()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Vendor2: Record Vendor;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching PO lines with different vendors to E-Document line raises error
        // [GIVEN] PO lines from different vendors and an E-Document line assigned to one specific vendor in BC
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with line for a different vendor
        LibraryPurchase.CreateVendor(Vendor2);
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Modify();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor2."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        // [WHEN] MatchPOLinesToEDocumentLine is called
        // [THEN] An error should be raised
        asserterror EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentPurchaseLine);
    end;

    [Test]
    procedure MatchPOLinesAlreadyMatchedToOtherEDocumentLinesRaisesError()
    var
        EDocument1, EDocument2 : Record "E-Document";
        EDocumentPurchaseHeader1, EDocumentPurchaseHeader2 : Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2 : Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching PO lines already matched to other E-Document lines raises error
        // [GIVEN] PO lines that are already matched to other E-Document lines
        LibraryEDocument.CreateInboundEDocument(EDocument1, EDocumentService);
        LibraryEDocument.CreateInboundEDocument(EDocument2, EDocumentService);

        // Create first E-Document
        EDocumentPurchaseHeader1 := LibraryEDocument.MockPurchaseDraftPrepared(EDocument1);
        EDocumentPurchaseHeader1."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader1.Modify();
        EDocumentPurchaseLine1 := LibraryEDocument.InsertPurchaseDraftLine(EDocument1);

        // Create second E-Document
        EDocumentPurchaseHeader2 := LibraryEDocument.MockPurchaseDraftPrepared(EDocument2);
        EDocumentPurchaseHeader2."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader2.Modify();
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument2);

        // Create Purchase Order with line for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match PO line to first E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseLine);

        // Try to match the same PO line to second E-Document line
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        // [WHEN] MatchPOLinesToEDocumentLine is called
        // [THEN] An error should be raised indicating the lines are already matched
        asserterror EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentPurchaseLine2);
    end;

    [Test]
    procedure MatchEmptyReceiptLinesToEDocumentLineCompletesWithoutCreatingMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempReceiptLine: Record "Purch. Rcpt. Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching empty list of receipt lines to E-Document line completes without creating matches
        // [GIVEN] An empty temporary list of receipt lines and an E-Document line
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create and match PO line to have receipt line matches to remove
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] MatchReceiptLinesToEDocumentLine is called
        EDocPOMatching.MatchReceiptLinesToEDocumentLine(TempReceiptLine, EDocumentPurchaseLine);

        // [THEN] Existing receipt matches should be removed and no new matches should be created
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected no receipt line matches to exist');
    end;

    [Test]
    procedure MatchValidReceiptLinesToEDocumentLineCreatesMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        TempReceiptLine: Record "Purch. Rcpt. Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching valid receipt lines to E-Document line creates matches
        // [GIVEN] Valid receipt lines matched to PO lines that are matched to the E-Document line
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine.Quantity := 10;
        EDocumentPurchaseLine.Modify();

        // Create Purchase Order with line and match to E-Document line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // Create receipt line matched to the PO line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseLine);

        TempReceiptLine := PurchaseReceiptLine;
        TempReceiptLine.Insert();

        // [WHEN] MatchReceiptLinesToEDocumentLine is called
        EDocPOMatching.MatchReceiptLinesToEDocumentLine(TempReceiptLine, EDocumentPurchaseLine);

        // [THEN] Receipt line matches should be created
        Assert.IsTrue(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected E-Document line to be matched to receipt line');
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine, EDocumentPurchaseLine), 'Expected receipt line to be matched to E-Document line');
    end;

    [Test]
    procedure MatchReceiptLinesToEDocumentLineRemovesExistingReceiptMatchesFirst()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2 : Record "Purch. Rcpt. Line";
        TempReceiptLine: Record "Purch. Rcpt. Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching receipt lines to E-Document line removes existing receipt matches first
        // [GIVEN] An E-Document line with existing receipt matches and new receipt lines to match
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine.Quantity := 10;
        EDocumentPurchaseLine.Modify();

        // Create Purchase Order with line and match to E-Document line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // Create two receipt lines
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader, Item."No.", 10, PurchaseLine);
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader, Item."No.", 10, PurchaseLine);

        // Match first receipt line
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine1);
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine1, EDocumentPurchaseLine), 'First receipt line should be matched');

        // Prepare to match second receipt line
        TempReceiptLine.DeleteAll();
        TempReceiptLine := PurchaseReceiptLine2;
        TempReceiptLine.Insert();

        // [WHEN] MatchReceiptLinesToEDocumentLine is called
        EDocPOMatching.MatchReceiptLinesToEDocumentLine(TempReceiptLine, EDocumentPurchaseLine);

        // [THEN] Existing receipt matches should be removed and new matches should be created
        Assert.IsFalse(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine1, EDocumentPurchaseLine), 'First receipt line should no longer be matched');
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine2, EDocumentPurchaseLine), 'Second receipt line should be matched');
    end;

    [Test]
    procedure MatchReceiptLinesNotMatchedToAnyPOLinesMatchedToEDocumentLineRaisesError()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader1, PurchaseHeader2 : Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        TempReceiptLine: Record "Purch. Rcpt. Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching receipt lines not matched to any PO lines matched to E-Document line raises error
        // [GIVEN] Receipt lines that are not matched to any of the PO lines matched to the E-Document line
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create two Purchase Orders
        LibraryPurchase.CreatePurchHeader(PurchaseHeader1, PurchaseHeader1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader1, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader2, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match only first PO line to E-Document line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine1);

        // Create receipt line matched to the second (unmatched) PO line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseLine2);

        TempReceiptLine := PurchaseReceiptLine;
        TempReceiptLine.Insert();

        // [WHEN] MatchReceiptLinesToEDocumentLine is called
        // [THEN] An error should be raised indicating the receipt lines are not matched
        asserterror EDocPOMatching.MatchReceiptLinesToEDocumentLine(TempReceiptLine, EDocumentPurchaseLine);
    end;

    [Test]
    procedure MatchReceiptLinesWithInsufficientQuantityToCoverEDocumentLineRaisesError()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        TempReceiptLine: Record "Purch. Rcpt. Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Matching receipt lines with insufficient quantity to cover E-Document line raises error
        // [GIVEN] Receipt lines with total quantity less than the E-Document line quantity
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine.Quantity := 20; // E-Document line requires 20 units
        EDocumentPurchaseLine.Modify();

        // Create Purchase Order with line and match to E-Document line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // Create receipt line with insufficient quantity (only 10 units)
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseLine);

        TempReceiptLine := PurchaseReceiptLine;
        TempReceiptLine.Insert();

        // [WHEN] MatchReceiptLinesToEDocumentLine is called
        // [THEN] An error should be raised indicating insufficient quantity coverage
        asserterror EDocPOMatching.MatchReceiptLinesToEDocumentLine(TempReceiptLine, EDocumentPurchaseLine);
    end;

    [Test]
    procedure POMatchingPolicyNeverAllowsMatchingAndGeneratesWarning()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        Initialize();
        // [SCENARIO] A vendor whose policy never receives on invoice allows matching a not-yet-received PO line and surfaces a warning
        // [GIVEN] Vendor "Receipt on Invoice Policy" set to Manual and a PO line not yet received
        SetVendorReceiptOnInvoicePolicy(Vendor."No.", Enum::"Receipt on Invoice Policy"::Manual);

        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create PO line that is not yet received
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine.Modify();

        // Set up E-Document line to match the item
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := 10;
        EDocumentPurchaseLine.Modify();

        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        // [WHEN] MatchPOLinesToEDocumentLine is called
        // [THEN] Matching is allowed even though the line is not yet received (the gate has been removed)
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentPurchaseLine);
        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseLine, EDocumentPurchaseLine), 'PO line should be matched to E-Document line');

        // [THEN] An ExceedsInvoiceableQty warning is generated, because the line will not be received automatically at posting
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsInvoiceableQty);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected ExceedsInvoiceableQty warning to be generated');
    end;

    [Test]
    procedure POMatchingPolicyAlwaysAllowsMatchingWithoutWarning()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        Initialize();
        // [SCENARIO] A vendor whose policy always receives on invoice allows matching a not-yet-received PO line without a warning
        // [GIVEN] Vendor "Receipt on Invoice Policy" set to Enabled and a PO line not yet received
        SetVendorReceiptOnInvoicePolicy(Vendor."No.", Enum::"Receipt on Invoice Policy"::Enabled);

        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create PO line that is not yet received
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine.Modify();

        // Set up E-Document line to match the item
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := 10;
        EDocumentPurchaseLine.Modify();

        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        // [WHEN] MatchPOLinesToEDocumentLine is called
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentPurchaseLine);

        // [THEN] Matching should succeed
        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseLine, EDocumentPurchaseLine), 'PO line should be matched to E-Document line');

        // [THEN] No ExceedsInvoiceableQty warning is generated, because the line will be received automatically at posting
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::ExceedsInvoiceableQty);
        Assert.IsTrue(TempPOMatchWarnings.IsEmpty(), 'Expected no ExceedsInvoiceableQty warning to be generated');
    end;

    [Test]
    procedure SuggestReceiptsForMatchedOrderLinesDoesNotSuggestWhenEDocLineAlreadyHasReceiptMatch()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] SuggestReceiptsForMatchedOrderLines suggests no receipts when E-Document line already has a receipt match
        // [GIVEN] An E-Document line matched to a receipt line and an additional receipt line that could be suggested
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 10);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);

        // Match E-Document line to PO line
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // Create receipt with 2 lines that could be suggested, match the last one to an E-Document line
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseLine);
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseLine);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        // [WHEN] SuggestReceiptsForMatchedOrderLines is called
        EDocPOMatching.SuggestReceiptsForMatchedOrderLines(EDocumentPurchaseHeader);

        // [THEN] No additional receipt lines are matched (still just the one)
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine, EDocumentPurchaseLine), 'Expected the original receipt match to remain');
        Assert.AreEqual(1, CountReceiptMatchesForEDocumentLine(EDocumentPurchaseLine), 'Expected exactly one receipt match');
    end;

    [Test]
    procedure SuggestReceiptsForMatchedOrderLinesSuggestsReceiptWhenPOLineHasSingleReceiptCoveringFullQuantity()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] SuggestReceiptsForMatchedOrderLines suggests receipt when PO line has a single receipt that covers full quantity
        // [GIVEN] An E-Document line matched to a purchase order line with quantity 10
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 10);

        // [GIVEN] The purchase order line has one receipt line with quantity 10
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        EDocumentPurchaseLine."[BC] Unit of Measure" := PurchaseLine."Unit of Measure Code";
        EDocumentPurchaseLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseLine);

        // [WHEN] SuggestReceiptsForMatchedOrderLines is called
        EDocPOMatching.SuggestReceiptsForMatchedOrderLines(EDocumentPurchaseHeader);

        // [THEN] The receipt line is matched to the E-Document line
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine, EDocumentPurchaseLine), 'Expected receipt line to be matched to E-Document line');
    end;

    [Test]
    procedure SuggestReceiptsForMatchedOrderLinesSuggestsNoReceiptWhenAllReceiptsHaveInsufficientQuantity()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2 : Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] SuggestReceiptsForMatchedOrderLines suggests no receipt when all receipts have insufficient quantity
        // [GIVEN] An E-Document line matched to a purchase order line with quantity 10
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 10);

        // [GIVEN] The purchase order line has two receipt lines with quantities 5 and 7
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader, Item."No.", 5, PurchaseLine);
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader, Item."No.", 7, PurchaseLine);

        // [WHEN] SuggestReceiptsForMatchedOrderLines is called
        EDocPOMatching.SuggestReceiptsForMatchedOrderLines(EDocumentPurchaseHeader);

        // [THEN] No receipt lines are matched to the E-Document line
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected no receipt lines to be matched');
    end;

    [Test]
    procedure SuggestReceiptsForMatchedOrderLinesProcessesMultipleEDocumentLinesIndependently()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2 : Record "E-Document Purchase Line";
        PurchaseHeader1, PurchaseHeader2 : Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        PurchaseReceiptHeader1, PurchaseReceiptHeader2 : Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2 : Record "Purch. Rcpt. Line";
        Item1, Item2 : Record Item;
    begin
        Initialize();
        // [SCENARIO] SuggestReceiptsForMatchedOrderLines processes multiple E-Document lines independently
        // [GIVEN] An E-Document with two lines matched to different purchase order lines
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine1, 10);
        // Second E-Document line
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine2.Quantity := 15;
        EDocumentPurchaseLine2.Modify();

        // [GIVEN] Each purchase order line has its own receipt that covers the full quantity
        LibraryInventory.CreateItem(Item1);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader1, PurchaseHeader1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader1, PurchaseLine1.Type::Item, Item1."No.", 10);
        EDocumentPurchaseLine1."[BC] Unit of Measure" := PurchaseLine1."Unit of Measure Code";
        EDocumentPurchaseLine1.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseLine1);
        CreateMockReceiptHeader(PurchaseReceiptHeader1, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader1, Item1."No.", 10, PurchaseLine1);

        LibraryInventory.CreateItem(Item2);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader2, PurchaseLine2.Type::Item, Item2."No.", 15);
        EDocumentPurchaseLine2."[BC] Unit of Measure" := PurchaseLine2."Unit of Measure Code";
        EDocumentPurchaseLine2.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine2, PurchaseLine2);
        CreateMockReceiptHeader(PurchaseReceiptHeader2, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader2, Item2."No.", 15, PurchaseLine2);

        // [WHEN] SuggestReceiptsForMatchedOrderLines is called
        EDocPOMatching.SuggestReceiptsForMatchedOrderLines(EDocumentPurchaseHeader);

        // [THEN] Each E-Document line is matched to its corresponding receipt line
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine1, EDocumentPurchaseLine1), 'Expected first receipt line to be matched to first E-Document line');
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine2, EDocumentPurchaseLine2), 'Expected second receipt line to be matched to second E-Document line');
    end;

    [Test]
    procedure TransferPOMatchesFromEDocumentToInvoiceTransfersReceiptMatchAndRemovesEDocumentMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] TransferPOMatchesFromEDocumentToInvoice transfers receipt match to linked invoice line and removes E-Document matches
        // [GIVEN] An E-Document line matched to a receipt line
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 10);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine, PurchaseOrderHeader, PurchaseOrderLine.Type::Item, Item."No.", 10);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseOrderLine);

        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseOrderLine);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        // [AND] The E-Document line is linked to a purchase invoice line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromEDocumentToInvoice is called
        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);

        // [THEN] A matched order line links the invoice line to the order line and the receipt line, carrying the
        // receipt's received-not-invoiced quantity
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLine.SystemId);
        MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseOrderLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchaseReceiptLine.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Expected a matched order line linking the invoice line to the order and receipt lines');
        Assert.AreEqual(10, MatchedOrderLine."Qty. to Invoice", 'The receipt match should invoice the full received quantity');

        // [THEN] The E-Document line no longer has any PO or receipt matches
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyPOLine(EDocumentPurchaseLine), 'Expected E-Document line to have no PO matches');
        Assert.IsFalse(EDocPOMatching.IsEDocumentLineMatchedToAnyReceiptLine(EDocumentPurchaseLine), 'Expected E-Document line to have no receipt matches');
    end;

    [Test]
    procedure TransferPOMatchesFromEDocumentToInvoiceProcessesMultipleLinesIndependently()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2, EDocumentPurchaseLine3 : Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2, PurchaseLine3 : Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine1, PurchaseOrderLine2, PurchaseOrderLine3 : Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2, PurchaseReceiptLine3 : Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item1, Item2, Item3 : Record Item;
    begin
        Initialize();
        // [SCENARIO] TransferPOMatchesFromEDocumentToInvoice processes multiple lines independently
        // [GIVEN] An E-Document with three lines matched to different receipt lines
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine1, 10);
        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine2.Quantity := 15;
        EDocumentPurchaseLine2.Modify();
        EDocumentPurchaseLine3 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine3.Quantity := 20;
        EDocumentPurchaseLine3.Modify();

        // Create purchase order with three lines
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item1);
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine1, PurchaseOrderHeader, PurchaseOrderLine1.Type::Item, Item1."No.", 10);
        LibraryInventory.CreateItem(Item2);
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine2, PurchaseOrderHeader, PurchaseOrderLine2.Type::Item, Item2."No.", 15);
        LibraryInventory.CreateItem(Item3);
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine3, PurchaseOrderHeader, PurchaseOrderLine3.Type::Item, Item3."No.", 20);

        // Create receipt lines
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader, Item1."No.", 10, PurchaseOrderLine1);
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader, Item2."No.", 15, PurchaseOrderLine2);
        CreateMockReceiptLine(PurchaseReceiptLine3, PurchaseReceiptHeader, Item3."No.", 20, PurchaseOrderLine3);

        // Match E-Document lines to PO lines and receipt lines
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine1, PurchaseOrderLine1);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine1, PurchaseReceiptLine1);

        MatchEDocumentLineToPOLine(EDocumentPurchaseLine2, PurchaseOrderLine2);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine2, PurchaseReceiptLine2);

        MatchEDocumentLineToPOLine(EDocumentPurchaseLine3, PurchaseOrderLine3);
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine3, PurchaseReceiptLine3);

        // [GIVEN] A purchase invoice with three corresponding lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item1."No.", 10);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item2."No.", 15);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine3, PurchaseHeader, PurchaseLine3.Type::Item, Item3."No.", 20);

        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine1, PurchaseLine1);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine2, PurchaseLine2);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine3, PurchaseLine3);

        // [WHEN] TransferPOMatchesFromEDocumentToInvoice is called
        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);

        // [THEN] Each invoice line has a matched order line linking it to its order line and receipt line, carrying
        // the receipt's received-not-invoiced quantity.
        AssertMatchedOrderLineExists(PurchaseLine1.SystemId, PurchaseOrderLine1.SystemId, PurchaseReceiptLine1.SystemId, 10, 'first');
        AssertMatchedOrderLineExists(PurchaseLine2.SystemId, PurchaseOrderLine2.SystemId, PurchaseReceiptLine2.SystemId, 15, 'second');
        AssertMatchedOrderLineExists(PurchaseLine3.SystemId, PurchaseOrderLine3.SystemId, PurchaseReceiptLine3.SystemId, 20, 'third');
    end;

    local procedure AssertMatchedOrderLineExists(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; ReceiptLineSystemId: Guid; ExpectedQtyToInvoice: Decimal; LineLabel: Text)
    var
        MatchedOrderLine: Record "Matched Order Line";
    begin
        Assert.IsTrue(GetMatchedOrderLine(InvoiceLineSystemId, OrderLineSystemId, ReceiptLineSystemId, MatchedOrderLine), 'Expected a matched order line for the ' + LineLabel + ' invoice line');
        Assert.AreEqual(ExpectedQtyToInvoice, MatchedOrderLine."Qty. to Invoice", 'Unexpected quantity to invoice on the ' + LineLabel + ' matched order line');
    end;

    [Test]
    procedure TransferPOMatchesFromInvoiceToEDocumentReconstructsMatchesFromMatchedOrderLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLineMgmt: Codeunit "Matched Order Line Mgmt.";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] TransferPOMatchesFromInvoiceToEDocument reconstructs the e-document matches from the invoice's matched order lines
        // [GIVEN] A purchase invoice line that carries a matched order line for an order line and a posted receipt line
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine, PurchaseOrderHeader, PurchaseOrderLine.Type::Item, Item."No.", 10);

        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseOrderLine);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        MatchedOrderLineMgmt.CreateMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine.SystemId, PurchaseReceiptLine.SystemId, 10, 10, false);

        // [GIVEN] The invoice line is linked to an E-Document line
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 10);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromInvoiceToEDocument is called
        EDocPOMatching.TransferPOMatchesFromInvoiceToEDocument(PurchaseHeader);

        // [THEN] The E-Document line is matched back to the purchase order line
        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseOrderLine, EDocumentPurchaseLine), 'Expected E-Document line to be matched to PO line');

        // [THEN] The E-Document line is matched back to the receipt line
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine, EDocumentPurchaseLine), 'Expected E-Document line to be matched to receipt line');
    end;

    [Test]
    procedure TransferPOMatchesFromInvoiceToEDocumentReconstructsMatchesFromLegacyReceiptNo()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] TransferPOMatchesFromInvoiceToEDocument reconstructs the e-document matches from an invoice line linked to a posted receipt through the legacy Receipt No. fields (no matched order line)
        // [GIVEN] An order line and a posted receipt line for it
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine, PurchaseOrderHeader, PurchaseOrderLine.Type::Item, Item."No.", 10);

        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 10, PurchaseOrderLine);

        // [GIVEN] An invoice line linked to the receipt through Receipt No. / Receipt Line No. and no matched order line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine."Receipt No." := PurchaseReceiptLine."Document No.";
        PurchaseLine."Receipt Line No." := PurchaseReceiptLine."Line No.";
        PurchaseLine.Modify();

        // [GIVEN] The invoice line is linked to an E-Document line
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 10);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromInvoiceToEDocument is called
        EDocPOMatching.TransferPOMatchesFromInvoiceToEDocument(PurchaseHeader);

        // [THEN] The E-Document line is matched back to the order line and the receipt line
        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseOrderLine, EDocumentPurchaseLine), 'Expected E-Document line to be matched to PO line');
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine, EDocumentPurchaseLine), 'Expected E-Document line to be matched to receipt line');
    end;

    [Test]
    procedure TransferPOMatchesFromInvoiceToEDocumentProcessesMultipleLinesIndependently()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine1, EDocumentPurchaseLine2, EDocumentPurchaseLine3 : Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2, PurchaseLine3 : Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine1, PurchaseOrderLine2, PurchaseOrderLine3 : Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2, PurchaseReceiptLine3 : Record "Purch. Rcpt. Line";
        MatchedOrderLineMgmt: Codeunit "Matched Order Line Mgmt.";
        Item1, Item2, Item3 : Record Item;
    begin
        Initialize();
        // [SCENARIO] TransferPOMatchesFromInvoiceToEDocument processes multiple lines independently
        // [GIVEN] A purchase invoice with three lines, each carrying a matched order line for its own order and receipt line
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item1);
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine1, PurchaseOrderHeader, PurchaseOrderLine1.Type::Item, Item1."No.", 10);
        LibraryInventory.CreateItem(Item2);
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine2, PurchaseOrderHeader, PurchaseOrderLine2.Type::Item, Item2."No.", 15);
        LibraryInventory.CreateItem(Item3);
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine3, PurchaseOrderHeader, PurchaseOrderLine3.Type::Item, Item3."No.", 20);

        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader, Item1."No.", 10, PurchaseOrderLine1);
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader, Item2."No.", 15, PurchaseOrderLine2);
        CreateMockReceiptLine(PurchaseReceiptLine3, PurchaseReceiptHeader, Item3."No.", 20, PurchaseOrderLine3);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item1."No.", 10);
        MatchedOrderLineMgmt.CreateMatchedOrderLine(PurchaseLine1.SystemId, PurchaseOrderLine1.SystemId, PurchaseReceiptLine1.SystemId, 10, 10, false);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item2."No.", 15);
        MatchedOrderLineMgmt.CreateMatchedOrderLine(PurchaseLine2.SystemId, PurchaseOrderLine2.SystemId, PurchaseReceiptLine2.SystemId, 15, 15, false);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine3, PurchaseHeader, PurchaseLine3.Type::Item, Item3."No.", 20);
        MatchedOrderLineMgmt.CreateMatchedOrderLine(PurchaseLine3.SystemId, PurchaseOrderLine3.SystemId, PurchaseReceiptLine3.SystemId, 20, 20, false);

        // [GIVEN] An E-Document with three corresponding lines
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine1, 10);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine1, PurchaseLine1);

        EDocumentPurchaseLine2 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine2.Quantity := 15;
        EDocumentPurchaseLine2.Modify();
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine2, PurchaseLine2);

        EDocumentPurchaseLine3 := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine3.Quantity := 20;
        EDocumentPurchaseLine3.Modify();
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine3, PurchaseLine3);

        // [WHEN] TransferPOMatchesFromInvoiceToEDocument is called
        EDocPOMatching.TransferPOMatchesFromInvoiceToEDocument(PurchaseHeader);

        // [THEN] Each E-Document line is matched to its corresponding PO line and receipt line
        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseOrderLine1, EDocumentPurchaseLine1), 'Expected first E-Document line to be matched to first PO line');
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine1, EDocumentPurchaseLine1), 'Expected first E-Document line to be matched to first receipt line');

        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseOrderLine2, EDocumentPurchaseLine2), 'Expected second E-Document line to be matched to second PO line');
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine2, EDocumentPurchaseLine2), 'Expected second E-Document line to be matched to second receipt line');

        Assert.IsTrue(EDocPOMatching.IsPOLineMatchedToEDocumentLine(PurchaseOrderLine3, EDocumentPurchaseLine3), 'Expected third E-Document line to be matched to third PO line');
        Assert.IsTrue(EDocPOMatching.IsReceiptLineMatchedToEDocumentLine(PurchaseReceiptLine3, EDocumentPurchaseLine3), 'Expected third E-Document line to be matched to third receipt line');
    end;

    local procedure SetInvoiceNoSeriesInSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SetVendorReceiptOnInvoicePolicy(VendorNo: Code[20]; Policy: Enum "Receipt on Invoice Policy")
    var
        VendorToConfigure: Record Vendor;
    begin
        VendorToConfigure.Get(VendorNo);
        VendorToConfigure."Receipt on Invoice Policy" := Policy;
        VendorToConfigure.Modify();
    end;

    local procedure ClearPurchaseDocumentsForVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
    begin
        PurchaseLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseLine.DeleteAll();
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.DeleteAll();
        PurchaseReceiptLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseReceiptLine.DeleteAll();
        PurchaseReceiptHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseReceiptHeader.DeleteAll();
    end;

    local procedure Initialize()
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetPostedNoSeriesInSetup();
        SetInvoiceNoSeriesInSetup();
        ClearPurchaseDocumentsForVendor();

        if IsInitialized then
            exit;
        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock, Enum::"E-Document Import Process"::"Version 2.0");
        IsInitialized := true;
    end;

    [Test]
    procedure TransferAutoReceivesOutstandingWhenNoReceiptMatched()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        NullGuid: Guid;
    begin
        Initialize();
        // [SCENARIO] An e-document line matched to an order line without receipts becomes a single receive-on-invoice match for the full quantity.
        // [GIVEN] An e-document line of quantity 10 matched to an order line of quantity 10 flagged receipt on invoice
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 10);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine, PurchaseOrderHeader, PurchaseOrderLine.Type::Item, Item."No.", 10);
        PurchaseOrderLine."Receipt on Invoice" := true;
        PurchaseOrderLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseOrderLine);

        // [AND] The e-document line is linked to a purchase invoice line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromEDocumentToInvoice is called
        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);

        // [THEN] A single receive-on-invoice matched order line for the full quantity carries the order line's flag
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLine.SystemId);
        Assert.AreEqual(1, MatchedOrderLine.Count(), 'Expected exactly one matched order line');
        Assert.IsTrue(GetMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine.SystemId, NullGuid, MatchedOrderLine), 'Expected a receive-on-invoice matched order line');
        Assert.AreEqual(10, MatchedOrderLine."Qty. to Invoice", 'Auto-receive quantity should be the full quantity');
        Assert.AreEqual(10, MatchedOrderLine."Qty. to Invoice (Base)", 'Auto-receive base quantity should be the full quantity');
        Assert.IsTrue(MatchedOrderLine."Receipt on Invoice", 'The match should carry the order line receipt on invoice flag');
    end;

    [Test]
    procedure TransferInvoicesExistingReceiptThenAutoReceivesRemainder()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        NullGuid: Guid;
    begin
        Initialize();
        // [SCENARIO] When a matched receipt only partly covers what is invoiced (the rest of the receipt was
        // already invoiced), the receipt is invoiced for its received-not-invoiced quantity and the remaining
        // e-document quantity is received on invoice, capped at the order line's outstanding quantity.
        // [GIVEN] An order line of quantity 100 with 50 received (50 outstanding)
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 50);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine, PurchaseOrderHeader, PurchaseOrderLine.Type::Item, Item."No.", 100);
        PurchaseOrderLine."Receipt on Invoice" := true;
        PurchaseOrderLine.Modify();
        SetMockOrderLineReceived(PurchaseOrderLine, 50);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseOrderLine);

        // [AND] A receipt of 50 whose quantity covers the invoice but is only 30 not-yet-invoiced
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine, PurchaseReceiptHeader, Item."No.", 50, PurchaseOrderLine);
        PurchaseReceiptLine."Qty. Rcd. Not Invoiced" := 30;
        PurchaseReceiptLine.Modify();
        MatchEDocumentLineToReceiptLine(EDocumentPurchaseLine, PurchaseReceiptLine);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 50);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromEDocumentToInvoice is called
        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);

        // [THEN] The receipt match invoices 30 and the receive-on-invoice match covers the remaining 20
        Assert.IsTrue(GetMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine.SystemId, PurchaseReceiptLine.SystemId, MatchedOrderLine), 'Expected a matched order line for the receipt');
        Assert.AreEqual(30, MatchedOrderLine."Qty. to Invoice", 'The receipt match should invoice the received-not-invoiced quantity');

        Assert.IsTrue(GetMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine.SystemId, NullGuid, MatchedOrderLine), 'Expected a receive-on-invoice matched order line for the remainder');
        Assert.AreEqual(20, MatchedOrderLine."Qty. to Invoice", 'The receive-on-invoice match should cover the remaining quantity');
    end;

    [Test]
    procedure TransferCapsAutoReceiveAtOutstandingQuantity()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        NullGuid: Guid;
    begin
        Initialize();
        // [SCENARIO] The receive-on-invoice quantity never exceeds the order line's outstanding quantity.
        // [GIVEN] An e-document line of quantity 100 matched to an order line of only quantity 50
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 100);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine, PurchaseOrderHeader, PurchaseOrderLine.Type::Item, Item."No.", 50);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseOrderLine);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 100);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromEDocumentToInvoice is called
        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);

        // [THEN] The receive-on-invoice match is capped at the outstanding quantity (50), the rest is dropped
        Assert.IsTrue(GetMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine.SystemId, NullGuid, MatchedOrderLine), 'Expected a receive-on-invoice matched order line');
        Assert.AreEqual(50, MatchedOrderLine."Qty. to Invoice", 'Auto-receive should be capped at the outstanding quantity');
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLine.SystemId);
        Assert.AreEqual(1, MatchedOrderLine.Count(), 'No additional matched order line should be created for the dropped remainder');
    end;

    [Test]
    procedure TransferDistributesQuantityAcrossMatchedOrderLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine1, PurchaseOrderLine2 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        NullGuid: Guid;
    begin
        Initialize();
        // [SCENARIO] A single e-document line matched to several order lines distributes its quantity across them, each capped at its outstanding quantity.
        // [GIVEN] An e-document line of quantity 100 matched to two order lines (60 and 40) of the same item
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 100);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine1, PurchaseOrderHeader, PurchaseOrderLine1.Type::Item, Item."No.", 60);
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine2, PurchaseOrderHeader, PurchaseOrderLine2.Type::Item, Item."No.", 40);
        TempPurchaseLine := PurchaseOrderLine1;
        TempPurchaseLine.Insert();
        TempPurchaseLine := PurchaseOrderLine2;
        TempPurchaseLine.Insert();
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentPurchaseLine);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 100);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromEDocumentToInvoice is called
        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);

        // [THEN] Each order line receives on invoice up to its outstanding quantity (60 + 40 = 100)
        Assert.IsTrue(GetMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine1.SystemId, NullGuid, MatchedOrderLine), 'Expected a match for the first order line');
        Assert.AreEqual(60, MatchedOrderLine."Qty. to Invoice", 'First order line should receive on invoice its full outstanding quantity');
        Assert.IsTrue(GetMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine2.SystemId, NullGuid, MatchedOrderLine), 'Expected a match for the second order line');
        Assert.AreEqual(40, MatchedOrderLine."Qty. to Invoice", 'Second order line should receive on invoice its full outstanding quantity');
    end;

    [Test]
    procedure TransferConvertsAutoReceiveQuantityFromBaseUsingOrderLineUoM()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        NullGuid: Guid;
    begin
        Initialize();
        // [SCENARIO] The receive-on-invoice quantity is expressed in the order line's unit of measure (converted from the base quantity).
        // [GIVEN] An item with a box unit of measure of 12, and an order line of 5 boxes (60 base)
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 5);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 12);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine, PurchaseOrderHeader, PurchaseOrderLine.Type::Item, Item."No.", 5);
        PurchaseOrderLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseOrderLine.Modify(true);
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseOrderLine);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 5);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromEDocumentToInvoice is called
        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);

        // [THEN] The match carries 5 boxes (60 in base unit of measure)
        Assert.IsTrue(GetMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine.SystemId, NullGuid, MatchedOrderLine), 'Expected a receive-on-invoice matched order line');
        Assert.AreEqual(5, MatchedOrderLine."Qty. to Invoice", 'Quantity should be expressed in the order line unit of measure');
        Assert.AreEqual(60, MatchedOrderLine."Qty. to Invoice (Base)", 'Base quantity should be the full base quantity');
    end;

    [Test]
    procedure TransferHandlesOrderLineWithZeroQtyPerUnitOfMeasure()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderLine: Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        NullGuid: Guid;
    begin
        Initialize();
        // [SCENARIO] An order line with no conversion factor (Qty. per Unit of Measure = 0) does not raise a division error; the base quantity is used one to one.
        // [GIVEN] An order line whose quantity per unit of measure has been cleared
        CreateMockEDocumentDraftWithLine(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine, 10);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseOrderLine, PurchaseOrderHeader, PurchaseOrderLine.Type::Item, Item."No.", 10);
        PurchaseOrderLine."Qty. per Unit of Measure" := 0;
        PurchaseOrderLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseOrderLine);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        LinkEDocumentLineToPurchaseLine(EDocument, EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] TransferPOMatchesFromEDocumentToInvoice is called
        EDocPOMatching.TransferPOMatchesFromEDocumentToInvoice(EDocument);

        // [THEN] The transfer succeeds and the quantity equals the base quantity (one to one)
        Assert.IsTrue(GetMatchedOrderLine(PurchaseLine.SystemId, PurchaseOrderLine.SystemId, NullGuid, MatchedOrderLine), 'Expected a receive-on-invoice matched order line');
        Assert.AreEqual(10, MatchedOrderLine."Qty. to Invoice", 'Quantity should fall back to the base quantity when there is no conversion factor');
        Assert.AreEqual(10, MatchedOrderLine."Qty. to Invoice (Base)", 'Base quantity should be the full quantity');
    end;

    local procedure MatchEDocumentLineToPOLine(EDocumentLine: Record "E-Document Purchase Line"; PurchaseLine: Record "Purchase Line")
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentLine);
    end;

    local procedure SetMatchingDifferencePct(Pct: Decimal)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."E-Document Matching Difference" := Pct;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure CreateMatchedAmountDraftLine(var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var EDocumentPurchaseLine: Record "E-Document Purchase Line"; var Item: Record Item; EDocQuantity: Decimal; EDocUnitPrice: Decimal; EDocTotalDiscount: Decimal)
    var
        EDocument: Record "E-Document";
    begin
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        LibraryEDocument.GetGenericItem(Item);
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine."[BC] Purchase Type No." := Item."No.";
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := EDocQuantity;
        EDocumentPurchaseLine."Unit Price" := EDocUnitPrice;
        EDocumentPurchaseLine."Total Discount" := EDocTotalDiscount;
        EDocumentPurchaseLine.Modify();
    end;

    local procedure AddOrderLineWithCost(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; LineDiscountPct: Decimal) PurchaseLine: Record "Purchase Line"
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine."Direct Unit Cost" := DirectUnitCost;
        PurchaseLine."Line Discount %" := LineDiscountPct;
        PurchaseLine.Modify();
    end;

    local procedure MatchEDocumentLineToReceiptLine(EDocumentLine: Record "E-Document Purchase Line"; ReceiptLine: Record "Purch. Rcpt. Line")
    var
        TempReceiptLine: Record "Purch. Rcpt. Line" temporary;
    begin
        TempReceiptLine := ReceiptLine;
        TempReceiptLine.Insert();
        EDocPOMatching.MatchReceiptLinesToEDocumentLine(TempReceiptLine, EDocumentLine);
    end;

    local procedure CreateMockReceiptHeader(var PurchaseReceiptHeader: Record "Purch. Rcpt. Header"; VendorNo: Code[20])
    begin
        PurchaseReceiptHeader.Init();
        PurchaseReceiptHeader."No." := CopyStr(LibraryRandom.RandText(20), 1, 20);
        PurchaseReceiptHeader."Buy-from Vendor No." := VendorNo;
        PurchaseReceiptHeader."Pay-to Vendor No." := VendorNo;
        PurchaseReceiptHeader."Document Date" := WorkDate();
        PurchaseReceiptHeader."Posting Date" := WorkDate();
        PurchaseReceiptHeader.Insert();
    end;

    local procedure CreateMockReceiptLine(var PurchaseReceiptLine: Record "Purch. Rcpt. Line"; PurchaseReceiptHeader: Record "Purch. Rcpt. Header"; ItemNo: Code[20]; Quantity: Decimal; PurchaseLine: Record "Purchase Line")
    var
        LineNo: Integer;
    begin
        PurchaseReceiptLine.SetRange("Document No.", PurchaseReceiptHeader."No.");
        if PurchaseReceiptLine.FindLast() then
            LineNo := PurchaseReceiptLine."Line No." + 10000
        else
            LineNo := 10000;

        PurchaseReceiptLine.Init();
        PurchaseReceiptLine."Document No." := PurchaseReceiptHeader."No.";
        PurchaseReceiptLine."Line No." := LineNo;
        PurchaseReceiptLine.Type := PurchaseReceiptLine.Type::Item;
        PurchaseReceiptLine."No." := ItemNo;
        PurchaseReceiptLine.Quantity := Quantity;
        PurchaseReceiptLine."Quantity (Base)" := Quantity;
        // A freshly posted receipt has its whole quantity received but not yet invoiced; the transfer uses this
        // field as the quantity to invoice for each matched receipt.
        PurchaseReceiptLine."Qty. Rcd. Not Invoiced" := Quantity;
        PurchaseReceiptLine."Order No." := PurchaseLine."Document No.";
        PurchaseReceiptLine."Order Line No." := PurchaseLine."Line No.";
        PurchaseReceiptLine."Buy-from Vendor No." := PurchaseReceiptHeader."Buy-from Vendor No.";
        PurchaseReceiptLine."Pay-to Vendor No." := PurchaseReceiptHeader."Pay-to Vendor No.";
        PurchaseReceiptLine.Insert();
    end;

    local procedure SetMockOrderLineReceived(var PurchaseOrderLine: Record "Purchase Line"; ReceivedQuantity: Decimal)
    begin
        // Mark part of the order line as already received (base unit of measure = item unit of measure in these tests).
        PurchaseOrderLine."Quantity Received" := ReceivedQuantity;
        PurchaseOrderLine."Qty. Received (Base)" := ReceivedQuantity;
        PurchaseOrderLine."Outstanding Quantity" := PurchaseOrderLine.Quantity - ReceivedQuantity;
        PurchaseOrderLine."Outstanding Qty. (Base)" := PurchaseOrderLine."Quantity (Base)" - ReceivedQuantity;
        PurchaseOrderLine.Modify();
    end;

    local procedure GetMatchedOrderLine(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; ReceiptLineSystemId: Guid; var MatchedOrderLine: Record "Matched Order Line"): Boolean
    begin
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLineSystemId);
        MatchedOrderLine.SetRange("Matched Order Line SystemId", OrderLineSystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", ReceiptLineSystemId);
        exit(MatchedOrderLine.FindFirst());
    end;

    local procedure LinkEDocumentLineToPurchaseLine(EDocument: Record "E-Document"; EDocumentPurchaseLine: Record "E-Document Purchase Line"; PurchaseLine: Record "Purchase Line")
    var
        EDocRecordLink: Record "E-Doc. Record Link";
    begin
        EDocRecordLink."Source Table No." := Database::"E-Document Purchase Line";
        EDocRecordLink."Source SystemId" := EDocumentPurchaseLine.SystemId;
        EDocRecordLink."Target Table No." := Database::"Purchase Line";
        EDocRecordLink."Target SystemId" := PurchaseLine.SystemId;
        EDocRecordLink."E-Document Entry No." := EDocument."Entry No";
        EDocRecordLink.Insert();
    end;

    local procedure CountReceiptMatchesForEDocumentLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"): Integer
    var
        EDocPurchaseLinePOMatch: Record "E-Doc. Purchase Line PO Match";
        NullGuid: Guid;
    begin
        EDocPurchaseLinePOMatch.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        EDocPurchaseLinePOMatch.SetFilter("Receipt Line SystemId", '<>%1', NullGuid);
        exit(EDocPurchaseLinePOMatch.Count());
    end;

    local procedure CreateMockEDocumentDraftWithLine(var EDocument: Record "E-Document"; var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var EDocumentPurchaseLine: Record "E-Document Purchase Line"; Quantity: Decimal)
    begin
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine.Quantity := Quantity;
        EDocumentPurchaseLine.Modify();
    end;

}

