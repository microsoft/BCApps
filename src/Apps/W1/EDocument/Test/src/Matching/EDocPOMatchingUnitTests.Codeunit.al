// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Purchases.Document;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.History;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.VAT.Setup;

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
    procedure LoadPOLinesMatchedToEDocLineReturnsAllMatchedPOLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2, PurchaseLine3 : Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Loading PO lines matched to an E-Document line returns all matched PO lines
        // [GIVEN] An E-Document line with multiple matched purchase order lines
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with multiple lines for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine3, PurchaseHeader, PurchaseLine3.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match first two PO lines to the E-Document line
        MatchEDocumentLineToTwoPOLines(EDocumentPurchaseLine, PurchaseLine1, PurchaseLine2);

        // [WHEN] LoadPOLinesMatchedToEDocumentLine is called
        EDocPOMatching.LoadPOLinesMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] All matched purchase order lines should be loaded into the temporary record
        Assert.AreEqual(2, TempPurchaseLine.Count(), 'Expected 2 matched purchase lines to be loaded');
        TempPurchaseLine.SetRange(SystemId, PurchaseLine1.SystemId);
        Assert.IsFalse(TempPurchaseLine.IsEmpty(), 'First matched purchase line should be included');
        TempPurchaseLine.SetRange(SystemId, PurchaseLine2.SystemId);
        Assert.IsFalse(TempPurchaseLine.IsEmpty(), 'Second matched purchase line should be included');
        TempPurchaseLine.SetRange(SystemId, PurchaseLine3.SystemId);
        Assert.IsTrue(TempPurchaseLine.IsEmpty(), 'Unmatched purchase line should not be included');
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
    procedure LoadPOsMatchedToEDocLineReturnsUniquePurchaseHeaders()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader1, PurchaseHeader2 : Record "Purchase Header";
        PurchaseLine1, PurchaseLine2, PurchaseLine3 : Record "Purchase Line";
        TempPurchaseHeader: Record "Purchase Header" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Loading POs matched to an E-Document line returns unique purchase headers
        // [GIVEN] An E-Document line matched to multiple PO lines from different purchase orders
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create two Purchase Orders with lines for the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader1, PurchaseHeader1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader1, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader1, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine3, PurchaseHeader2, PurchaseLine3.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match lines from both purchase orders to the E-Document line
        MatchEDocumentLineToThreePOLines(EDocumentPurchaseLine, PurchaseLine1, PurchaseLine2, PurchaseLine3);

        // [WHEN] LoadPOsMatchedToEDocumentLine is called
        EDocPOMatching.LoadPOsMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseHeader);

        // [THEN] All unique purchase headers should be loaded into the temporary record
        Assert.AreEqual(2, TempPurchaseHeader.Count(), 'Expected 2 unique purchase headers to be loaded');
        TempPurchaseHeader.SetRange("No.", PurchaseHeader1."No.");
        Assert.IsFalse(TempPurchaseHeader.IsEmpty(), 'First purchase header should be included');
        TempPurchaseHeader.SetRange("No.", PurchaseHeader2."No.");
        Assert.IsFalse(TempPurchaseHeader.IsEmpty(), 'Second purchase header should be included');
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
    procedure LoadAvailableReceiptLinesReturnsReceiptLinesForMatchedPOLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2 : Record "Purch. Rcpt. Line";
        TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        ClearPurchaseDocumentsForVendor();
        // [SCENARIO] Loading available receipt lines returns receipt lines for matched PO lines
        // [GIVEN] An E-Document line matched to PO lines that have associated receipt lines
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match PO lines to E-Document line
        MatchEDocumentLineToTwoPOLines(EDocumentPurchaseLine, PurchaseLine1, PurchaseLine2);

        // Create receipt header and receipt lines for the purchase order
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine1);
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine2);

        // [WHEN] LoadAvailableReceiptLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailableReceiptLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseReceiptLine);

        // [THEN] All receipt lines for the matched PO lines should be loaded
        Assert.AreEqual(2, TempPurchaseReceiptLine.Count(), 'Expected 2 receipt lines for matched PO lines');
        TempPurchaseReceiptLine.SetRange("Document No.", PurchaseReceiptLine1."Document No.");
        TempPurchaseReceiptLine.SetRange("Line No.", PurchaseReceiptLine1."Line No.");
        Assert.IsFalse(TempPurchaseReceiptLine.IsEmpty(), 'First receipt line should be included');
        TempPurchaseReceiptLine.SetRange("Line No.", PurchaseReceiptLine2."Line No.");
        Assert.IsFalse(TempPurchaseReceiptLine.IsEmpty(), 'Second receipt line should be included');
    end;

    [Test]
    procedure LoadAvailableReceiptLinesExcludesZeroQuantityLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        PurchaseReceiptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2 : Record "Purch. Rcpt. Line";
        TempPurchaseReceiptLine: Record "Purch. Rcpt. Line" temporary;
        Item: Record Item;
    begin
        Initialize();
        ClearPurchaseDocumentsForVendor();
        // [SCENARIO] Loading available receipt lines excludes receipt lines with zero quantity
        // [GIVEN] An E-Document line matched to PO lines with receipt lines having zero and non-zero quantities
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match PO lines to E-Document line
        MatchEDocumentLineToTwoPOLines(EDocumentPurchaseLine, PurchaseLine1, PurchaseLine2);

        // Create receipt header and receipt lines - one with zero quantity, one with non-zero quantity
        CreateMockReceiptHeader(PurchaseReceiptHeader, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader, Item."No.", 0, PurchaseLine1); // Zero quantity
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine2); // Non-zero quantity

        // [WHEN] LoadAvailableReceiptLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailableReceiptLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseReceiptLine);

        // [THEN] Only receipt lines with non-zero quantities should be loaded
        Assert.AreEqual(1, TempPurchaseReceiptLine.Count(), 'Expected 1 receipt line (excluding zero quantity line)');
        TempPurchaseReceiptLine.FindFirst();
        Assert.AreEqual(PurchaseReceiptLine2.SystemId, TempPurchaseReceiptLine.SystemId, 'Only non-zero quantity receipt line should be included');
        Assert.IsTrue(TempPurchaseReceiptLine.Quantity > 0, 'Loaded receipt line should have non-zero quantity');
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
    procedure LoadReceiptsMatchedToEDocLineReturnsUniqueReceiptHeaders()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        PurchaseReceiptHeader1, PurchaseReceiptHeader2 : Record "Purch. Rcpt. Header";
        PurchaseReceiptLine1, PurchaseReceiptLine2, PurchaseReceiptLine3 : Record "Purch. Rcpt. Line";
        TempPurchaseReceiptHeader: Record "Purch. Rcpt. Header" temporary;
        Item: Record Item;
    begin
        Initialize();
        // [SCENARIO] Loading receipts matched to an E-Document line returns unique receipt headers
        // [GIVEN] An E-Document line with receipt line matches from different receipt documents
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Match E-Document line to PO lines
        MatchEDocumentLineToTwoPOLines(EDocumentPurchaseLine, PurchaseLine1, PurchaseLine2);

        // Create receipt headers and lines
        CreateMockReceiptHeader(PurchaseReceiptHeader1, Vendor."No.");
        CreateMockReceiptHeader(PurchaseReceiptHeader2, Vendor."No.");
        CreateMockReceiptLine(PurchaseReceiptLine1, PurchaseReceiptHeader1, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine1);
        CreateMockReceiptLine(PurchaseReceiptLine2, PurchaseReceiptHeader1, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine1);
        CreateMockReceiptLine(PurchaseReceiptLine3, PurchaseReceiptHeader2, Item."No.", LibraryRandom.RandDec(5, 2), PurchaseLine2);

        // Match receipt lines to E-Document line
        MatchEDocumentLineToThreeReceiptLines(EDocumentPurchaseLine, PurchaseReceiptLine1, PurchaseReceiptLine2, PurchaseReceiptLine3);

        // [WHEN] LoadReceiptsMatchedToEDocumentLine is called
        EDocPOMatching.LoadReceiptsMatchedToEDocumentLine(EDocumentPurchaseLine, TempPurchaseReceiptHeader);

        // [THEN] All unique receipt headers should be loaded into the temporary record
        Assert.AreEqual(2, TempPurchaseReceiptHeader.Count(), 'Expected 2 unique receipt headers to be loaded');
        TempPurchaseReceiptHeader.SetRange("No.", PurchaseReceiptHeader1."No.");
        Assert.IsFalse(TempPurchaseReceiptHeader.IsEmpty(), 'First receipt header should be included');
        TempPurchaseReceiptHeader.SetRange("No.", PurchaseReceiptHeader2."No.");
        Assert.IsFalse(TempPurchaseReceiptHeader.IsEmpty(), 'Second receipt header should be included');
    end;

    // [SCENARIO] Calculating PO match warnings generates missing information warning for item lines without proper setup
    // [GIVEN] An E-Document with item lines that have missing item or unit of measure information
    // [WHEN] CalculatePOMatchWarnings is called
    // [THEN] MissingInformationForMatch warnings should be generated for those lines

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

    [Test]
    procedure CalculatePOMatchWarningsGeneratesQuantityMismatchWarning()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempPOMatchWarnings: Record "E-Doc PO Match Warning" temporary;
    begin
        Initialize();
        // [SCENARIO] Calculating PO match warnings generates quantity mismatch warning when quantities don't match
        // [GIVEN] An E-Document with lines where calculated quantity differs from original quantity
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create a purchase order line with 10 units
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);

        // Create item with UOM that has different qty per unit of measure
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure."Item No." := Item."No.";
        ItemUnitOfMeasure.Code := 'BIGBOX';
        ItemUnitOfMeasure."Qty. per Unit of Measure" := 10;
        ItemUnitOfMeasure.Insert();

        // Create E-Document Purchase Header
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // Set up E-Document line to create quantity mismatch also with 10 units but different UOM
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine."[BC] Purchase Type No." := Item."No.";
        EDocumentPurchaseLine."[BC] Unit of Measure" := 'BIGBOX';
        EDocumentPurchaseLine.Quantity := 10;
        EDocumentPurchaseLine.Modify();


        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] QuantityMismatch warnings should be generated
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::QuantityMismatch);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected QuantityMismatch warning to be generated');
    end;

    [Test]
    procedure CalculatePOMatchWarningsGeneratesNotYetReceivedWarning()
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
        // [SCENARIO] Calculating PO match warnings generates not yet received warning when trying to invoice more than received
        // [GIVEN] An E-Document with lines where E-Doc quantity plus already invoiced quantity exceeds received quantity
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header and Line
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Set up E-Document line
        LibraryEDocument.GetGenericItem(Item);
        EDocumentPurchaseLine."[BC] Purchase Line Type" := Enum::"Purchase Line Type"::Item;
        EDocumentPurchaseLine."[BC] Purchase Type No." := Item."No.";
        EDocumentPurchaseLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
        EDocumentPurchaseLine.Quantity := 15; // More than what's received (10)
        EDocumentPurchaseLine.Modify();

        // Create purchase order line with some invoiced and received quantities
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 20);
        PurchaseLine."Qty. Invoiced (Base)" := 5; // Already invoiced 5
        PurchaseLine."Qty. Received (Base)" := 10; // Only received 10, so trying to invoice 15 + 5 = 20 > 10 received
        PurchaseLine.Modify();
        MatchEDocumentLineToPOLine(EDocumentPurchaseLine, PurchaseLine);

        // [WHEN] CalculatePOMatchWarnings is called
        EDocPOMatching.CalculatePOMatchWarnings(EDocumentPurchaseHeader, TempPOMatchWarnings);

        // [THEN] NotYetReceived warnings should be generated
        TempPOMatchWarnings.SetRange("E-Doc. Purchase Line SystemId", EDocumentPurchaseLine.SystemId);
        TempPOMatchWarnings.SetRange("Warning Type", Enum::"E-Doc PO Match Warning"::NotYetReceived);
        Assert.IsFalse(TempPOMatchWarnings.IsEmpty(), 'Expected NotYetReceived warning to be generated');
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
    procedure MatchPOLinesWithDifferentTypesToEDocumentLineRaisesError()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1, PurchaseLine2 : Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TempPurchaseLine: Record "Purchase Line" temporary;
        Item: Record Item;
        GLAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] Matching PO lines with different types or numbers to E-Document line raises error
        // [GIVEN] PO lines with different types or item numbers
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();
        EDocumentPurchaseLine := LibraryEDocument.InsertPurchaseDraftLine(EDocument);

        // Create Purchase Order with lines of different types
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryEDocument.GetGenericItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, Enum::"General Posting Type"::" ");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));

        TempPurchaseLine := PurchaseLine1;
        TempPurchaseLine.Insert();
        TempPurchaseLine := PurchaseLine2;
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
        if IsInitialized then
            exit;
        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock, Enum::"E-Document Import Process"::"Version 2.0");
        IsInitialized := true;
    end;

    local procedure MatchEDocumentLineToPOLine(EDocumentLine: Record "E-Document Purchase Line"; PurchaseLine: Record "Purchase Line")
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentLine);
    end;

    local procedure MatchEDocumentLineToTwoPOLines(EDocumentLine: Record "E-Document Purchase Line"; PurchaseLine1: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line")
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        TempPurchaseLine := PurchaseLine1;
        TempPurchaseLine.Insert();
        TempPurchaseLine := PurchaseLine2;
        TempPurchaseLine.Insert();
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentLine);
    end;

    local procedure MatchEDocumentLineToThreePOLines(EDocumentLine: Record "E-Document Purchase Line"; PurchaseLine1: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line"; PurchaseLine3: Record "Purchase Line")
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        TempPurchaseLine := PurchaseLine1;
        TempPurchaseLine.Insert();
        TempPurchaseLine := PurchaseLine2;
        TempPurchaseLine.Insert();
        TempPurchaseLine := PurchaseLine3;
        TempPurchaseLine.Insert();
        EDocPOMatching.MatchPOLinesToEDocumentLine(TempPurchaseLine, EDocumentLine);
    end;

    local procedure MatchEDocumentLineToReceiptLine(EDocumentLine: Record "E-Document Purchase Line"; ReceiptLine: Record "Purch. Rcpt. Line")
    var
        TempReceiptLine: Record "Purch. Rcpt. Line" temporary;
    begin
        TempReceiptLine := ReceiptLine;
        TempReceiptLine.Insert();
        EDocPOMatching.MatchReceiptLinesToEDocumentLine(TempReceiptLine, EDocumentLine);
    end;

    local procedure MatchEDocumentLineToThreeReceiptLines(EDocumentLine: Record "E-Document Purchase Line"; ReceiptLine1: Record "Purch. Rcpt. Line"; ReceiptLine2: Record "Purch. Rcpt. Line"; ReceiptLine3: Record "Purch. Rcpt. Line")
    var
        TempReceiptLine: Record "Purch. Rcpt. Line" temporary;
    begin
        TempReceiptLine := ReceiptLine1;
        TempReceiptLine.Insert();
        TempReceiptLine := ReceiptLine2;
        TempReceiptLine.Insert();
        TempReceiptLine := ReceiptLine3;
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
        PurchaseReceiptLine."Order No." := PurchaseLine."Document No.";
        PurchaseReceiptLine."Order Line No." := PurchaseLine."Line No.";
        PurchaseReceiptLine."Buy-from Vendor No." := PurchaseReceiptHeader."Buy-from Vendor No.";
        PurchaseReceiptLine."Pay-to Vendor No." := PurchaseReceiptHeader."Pay-to Vendor No.";
        PurchaseReceiptLine.Insert();
    end;

}