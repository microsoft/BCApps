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
using System.TestLibraries.Utilities;
using Microsoft.Purchases.Vendor;

codeunit 133508 "E-Doc. PO Matching Test"
{
    Subtype = Test;
    TestType = UnitTest;

    var
        Assert: Codeunit Assert;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        EDocPOMatching: Codeunit "E-Doc. PO Matching";
        IsInitialized: Boolean;

    [Test]
    procedure LoadAvailablePOLinesForEDocLineWithNoLinkedVendor()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        Initialize();
        // [SCENARIO] Loading available purchase order lines for an E-Document line with no linked vendor returns empty result
        // [GIVEN] An E-Document line with no linked vendor
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);

        // Create E-Document Purchase Header with no vendor
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := ''; // No linked vendor
        EDocumentPurchaseHeader.Insert();

        // Create E-Document Purchase Line
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."Line No." := 10000;
        EDocumentPurchaseLine.Insert();

        // [WHEN] LoadAvailablePurchaseOrderLinesForEDocumentLine is called
        EDocPOMatching.LoadAvailablePurchaseOrderLinesForEDocumentLine(EDocumentPurchaseLine, TempPurchaseLine);

        // [THEN] The temporary purchase line record should be empty
        Assert.IsTrue(TempPurchaseLine.IsEmpty(), 'Expected no purchase lines when E-Document line has no linked vendor');
    end;

    // Tests for LoadAvailablePurchaseOrderLinesForEDocumentLine
    // [SCENARIO] Loading available purchase order lines for an E-Document line with no linked vendor returns empty result
    // [GIVEN] An E-Document line with no linked vendor
    // [WHEN] LoadAvailablePurchaseOrderLinesForEDocumentLine is called
    // [THEN] The temporary purchase line record should be empty

    // [SCENARIO] Loading available purchase order lines for an E-Document line with linked vendor but no PO lines returns empty result
    // [GIVEN] An E-Document line with a linked vendor but no purchase order lines exist for that vendor
    // [WHEN] LoadAvailablePurchaseOrderLinesForEDocumentLine is called
    // [THEN] The temporary purchase line record should be empty

    // [SCENARIO] Loading available purchase order lines for an E-Document line returns unmatched PO lines for the same vendor
    // [GIVEN] An E-Document line with a linked vendor and multiple purchase order lines exist for that vendor, none matched to other E-Document lines
    // [WHEN] LoadAvailablePurchaseOrderLinesForEDocumentLine is called
    // [THEN] All purchase order lines for the vendor should be loaded into the temporary record

    // [SCENARIO] Loading available purchase order lines excludes lines already matched to other E-Document lines
    // [GIVEN] An E-Document line with a linked vendor, multiple PO lines for that vendor, some already matched to other E-Document lines
    // [WHEN] LoadAvailablePurchaseOrderLinesForEDocumentLine is called
    // [THEN] Only unmatched PO lines and lines matched to the current E-Document line should be loaded

    // [SCENARIO] Loading available purchase order lines includes lines already matched to the current E-Document line
    // [GIVEN] An E-Document line with a linked vendor and PO lines already matched to this E-Document line
    // [WHEN] LoadAvailablePurchaseOrderLinesForEDocumentLine is called
    // [THEN] The PO lines matched to this E-Document line should be included in the result

    // Tests for LoadPOLinesLinkedToEDocumentLine
    // [SCENARIO] Loading PO lines linked to an E-Document line with no matches returns empty result
    // [GIVEN] An E-Document line with no linked purchase order lines
    // [WHEN] LoadPOLinesLinkedToEDocumentLine is called
    // [THEN] The temporary purchase line record should be empty

    // [SCENARIO] Loading PO lines linked to an E-Document line returns all matched PO lines
    // [GIVEN] An E-Document line with multiple linked purchase order lines
    // [WHEN] LoadPOLinesLinkedToEDocumentLine is called
    // [THEN] All linked purchase order lines should be loaded into the temporary record

    // [SCENARIO] Loading PO lines linked to an E-Document line excludes lines with receipt line matches
    // [GIVEN] An E-Document line with PO line matches, some having receipt line matches
    // [WHEN] LoadPOLinesLinkedToEDocumentLine is called
    // [THEN] Only PO lines without receipt line matches should be loaded

    // Tests for LoadPOsLinkedToEDocumentLine
    // [SCENARIO] Loading POs linked to an E-Document line with no linked PO lines returns empty result
    // [GIVEN] An E-Document line with no linked purchase order lines
    // [WHEN] LoadPOsLinkedToEDocumentLine is called
    // [THEN] The temporary purchase header record should be empty

    // [SCENARIO] Loading POs linked to an E-Document line returns unique purchase headers
    // [GIVEN] An E-Document line linked to multiple PO lines from different purchase orders
    // [WHEN] LoadPOsLinkedToEDocumentLine is called
    // [THEN] All unique purchase headers should be loaded into the temporary record

    // [SCENARIO] Loading POs linked to an E-Document line avoids duplicate headers when multiple lines from same PO
    // [GIVEN] An E-Document line linked to multiple PO lines from the same purchase order
    // [WHEN] LoadPOsLinkedToEDocumentLine is called
    // [THEN] Only one instance of the purchase header should be loaded

    // Tests for LoadAvailableReceiptLinesForEDocumentLine
    // [SCENARIO] Loading available receipt lines for an E-Document line with no linked PO lines returns empty result
    // [GIVEN] An E-Document line with no linked purchase order lines
    // [WHEN] LoadAvailableReceiptLinesForEDocumentLine is called
    // [THEN] The temporary receipt line record should be empty

    // [SCENARIO] Loading available receipt lines returns receipt lines for linked PO lines
    // [GIVEN] An E-Document line linked to PO lines that have associated receipt lines
    // [WHEN] LoadAvailableReceiptLinesForEDocumentLine is called
    // [THEN] All receipt lines for the linked PO lines should be loaded

    // [SCENARIO] Loading available receipt lines excludes receipt lines with zero quantity
    // [GIVEN] An E-Document line linked to PO lines with receipt lines having zero and non-zero quantities
    // [WHEN] LoadAvailableReceiptLinesForEDocumentLine is called
    // [THEN] Only receipt lines with non-zero quantities should be loaded

    // Tests for LoadReceiptsLinkedToEDocumentLine
    // [SCENARIO] Loading receipts linked to an E-Document line with no receipt line matches returns empty result
    // [GIVEN] An E-Document line with no receipt line matches
    // [WHEN] LoadReceiptsLinkedToEDocumentLine is called
    // [THEN] The temporary receipt header record should be empty

    // [SCENARIO] Loading receipts linked to an E-Document line returns unique receipt headers
    // [GIVEN] An E-Document line with receipt line matches from different receipt documents
    // [WHEN] LoadReceiptsLinkedToEDocumentLine is called
    // [THEN] All unique receipt headers should be loaded into the temporary record

    // [SCENARIO] Loading receipts linked to an E-Document line avoids duplicate headers
    // [GIVEN] An E-Document line with multiple receipt line matches from the same receipt document
    // [WHEN] LoadReceiptsLinkedToEDocumentLine is called
    // [THEN] Only one instance of each receipt header should be loaded

    // Tests for CalculatePOMatchWarnings
    // [SCENARIO] Calculating PO match warnings for E-Document with no lines returns no warnings
    // [GIVEN] An E-Document with no purchase lines
    // [WHEN] CalculatePOMatchWarnings is called
    // [THEN] No warnings should be generated

    // [SCENARIO] Calculating PO match warnings generates missing information warning for item lines without proper setup
    // [GIVEN] An E-Document with item lines that have missing item or unit of measure information
    // [WHEN] CalculatePOMatchWarnings is called
    // [THEN] MissingInformationForMatch warnings should be generated for those lines

    // [SCENARIO] Calculating PO match warnings generates quantity mismatch warning when quantities don't match
    // [GIVEN] An E-Document with lines where calculated quantity differs from original quantity
    // [WHEN] CalculatePOMatchWarnings is called
    // [THEN] QuantityMismatch warnings should be generated

    // [SCENARIO] Calculating PO match warnings generates not yet received warning when trying to invoice more than received
    // [GIVEN] An E-Document with lines where E-Doc quantity plus already invoiced quantity exceeds received quantity
    // [WHEN] CalculatePOMatchWarnings is called
    // [THEN] NotYetReceived warnings should be generated

    // Tests for IsPOMatchConsistent
    // [SCENARIO] PO match consistency check returns true for E-Document with zero entry number
    // [GIVEN] An E-Document with entry number of zero
    // [WHEN] IsPOMatchConsistent is called
    // [THEN] The result should be true

    // [SCENARIO] PO match consistency check returns true for E-Document with no lines
    // [GIVEN] An E-Document with no purchase lines
    // [WHEN] IsPOMatchConsistent is called
    // [THEN] The result should be true

    // [SCENARIO] PO match consistency check returns true when all matches are valid
    // [GIVEN] An E-Document with lines having valid PO and receipt line matches
    // [WHEN] IsPOMatchConsistent is called
    // [THEN] The result should be true

    // [SCENARIO] PO match consistency check returns false when receipt line match refers to non-existent receipt line
    // [GIVEN] An E-Document with a line having a receipt line match that refers to a deleted receipt line
    // [WHEN] IsPOMatchConsistent is called
    // [THEN] The result should be false

    // [SCENARIO] PO match consistency check returns false when PO line match refers to non-existent purchase line
    // [GIVEN] An E-Document with a line having a PO line match that refers to a deleted purchase line
    // [WHEN] IsPOMatchConsistent is called
    // [THEN] The result should be false

    // Tests for IsEDocumentLineLinkedToAnyPOLine
    // [SCENARIO] E-Document line linked check returns false when no matches exist
    // [GIVEN] An E-Document line with no PO line matches
    // [WHEN] IsEDocumentLineLinkedToAnyPOLine is called
    // [THEN] The result should be false

    // [SCENARIO] E-Document line linked check returns true when matches exist
    // [GIVEN] An E-Document line with one or more PO line matches
    // [WHEN] IsEDocumentLineLinkedToAnyPOLine is called
    // [THEN] The result should be true

    // Tests for IsEDocumentLinkedToAnyPOLine
    // [SCENARIO] E-Document linked check returns false for null GUID system ID
    // [GIVEN] An E-Document with null GUID system ID
    // [WHEN] IsEDocumentLinkedToAnyPOLine is called
    // [THEN] The result should be false

    // [SCENARIO] E-Document linked check returns false when no lines exist
    // [GIVEN] An E-Document with no purchase lines
    // [WHEN] IsEDocumentLinkedToAnyPOLine is called
    // [THEN] The result should be false

    // [SCENARIO] E-Document linked check returns false when no lines are linked
    // [GIVEN] An E-Document with purchase lines but none linked to PO lines
    // [WHEN] IsEDocumentLinkedToAnyPOLine is called
    // [THEN] The result should be false

    // [SCENARIO] E-Document linked check returns true when at least one line is linked
    // [GIVEN] An E-Document with multiple purchase lines where at least one is linked to a PO line
    // [WHEN] IsEDocumentLinkedToAnyPOLine is called
    // [THEN] The result should be true

    // Tests for IsPurchaseOrderLineLinkedToEDocumentLine
    // [SCENARIO] PO line linked check returns false when no match exists
    // [GIVEN] A purchase line and E-Document line with no link between them
    // [WHEN] IsPurchaseOrderLineLinkedToEDocumentLine is called
    // [THEN] The result should be false

    // [SCENARIO] PO line linked check returns true when match exists
    // [GIVEN] A purchase line and E-Document line with a link between them
    // [WHEN] IsPurchaseOrderLineLinkedToEDocumentLine is called
    // [THEN] The result should be true

    // Tests for IsEDocumentLineLinkedToAnyReceiptLine
    // [SCENARIO] E-Document line receipt linked check returns false when no receipt line matches exist
    // [GIVEN] An E-Document line with no receipt line matches
    // [WHEN] IsEDocumentLineLinkedToAnyReceiptLine is called
    // [THEN] The result should be false

    // [SCENARIO] E-Document line receipt linked check returns true when receipt line matches exist
    // [GIVEN] An E-Document line with one or more receipt line matches
    // [WHEN] IsEDocumentLineLinkedToAnyReceiptLine is called
    // [THEN] The result should be true

    // Tests for IsReceiptLineLinkedToEDocumentLine
    // [SCENARIO] Receipt line linked check returns false when no match exists
    // [GIVEN] A receipt line and E-Document line with no link between them
    // [WHEN] IsReceiptLineLinkedToEDocumentLine is called
    // [THEN] The result should be false

    // [SCENARIO] Receipt line linked check returns true when match exists
    // [GIVEN] A receipt line and E-Document line with a link between them
    // [WHEN] IsReceiptLineLinkedToEDocumentLine is called
    // [THEN] The result should be true

    // Tests for RemoveAllReceiptMatchesForEDocumentLine
    // [SCENARIO] Removing all receipt matches for E-Document line with no matches completes without error
    // [GIVEN] An E-Document line with no receipt line matches
    // [WHEN] RemoveAllReceiptMatchesForEDocumentLine is called
    // [THEN] The operation should complete without error and no matches should remain

    // [SCENARIO] Removing all receipt matches for E-Document line removes only receipt matches
    // [GIVEN] An E-Document line with both PO line matches and receipt line matches
    // [WHEN] RemoveAllReceiptMatchesForEDocumentLine is called
    // [THEN] Only receipt line matches should be removed, PO line matches should remain

    // Tests for RemoveAllMatchesForEDocumentLine
    // [SCENARIO] Removing all matches for E-Document line with no matches completes without error
    // [GIVEN] An E-Document line with no matches
    // [WHEN] RemoveAllMatchesForEDocumentLine is called
    // [THEN] The operation should complete without error

    // [SCENARIO] Removing all matches for E-Document line removes all types of matches
    // [GIVEN] An E-Document line with both PO line matches and receipt line matches
    // [WHEN] RemoveAllMatchesForEDocumentLine is called
    // [THEN] All matches should be removed

    // Tests for RemoveAllMatchesForEDocument
    // [SCENARIO] Removing all matches for E-Document with no lines completes without error
    // [GIVEN] An E-Document with no purchase lines
    // [WHEN] RemoveAllMatchesForEDocument is called
    // [THEN] The operation should complete without error

    // [SCENARIO] Removing all matches for E-Document removes matches for all lines
    // [GIVEN] An E-Document with multiple purchase lines having various matches
    // [WHEN] RemoveAllMatchesForEDocument is called
    // [THEN] All matches for all lines should be removed

    // Tests for LinkPOLinesToEDocumentLine
    // [SCENARIO] Linking empty list of PO lines to E-Document line completes without creating matches
    // [GIVEN] An empty temporary list of PO lines and an E-Document line
    // [WHEN] LinkPOLinesToEDocumentLine is called
    // [THEN] No matches should be created and existing matches should be removed

    // [SCENARIO] Linking valid PO lines to E-Document line creates matches and updates E-Document line properties
    // [GIVEN] Valid PO lines from the same vendor with same type and number, and an E-Document line
    // [WHEN] LinkPOLinesToEDocumentLine is called
    // [THEN] Matches should be created and E-Document line should be updated with PO line properties

    // [SCENARIO] Linking PO lines to E-Document line removes existing matches first
    // [GIVEN] An E-Document line with existing matches and new PO lines to link
    // [WHEN] LinkPOLinesToEDocumentLine is called
    // [THEN] Existing matches should be removed and new matches should be created

    // [SCENARIO] Linking PO lines with different vendors to E-Document line raises error
    // [GIVEN] PO lines from different vendors and an E-Document line linked to one specific vendor
    // [WHEN] LinkPOLinesToEDocumentLine is called
    // [THEN] An error should be raised

    // [SCENARIO] Linking PO lines with different types or numbers to E-Document line raises error
    // [GIVEN] PO lines with different types or item numbers
    // [WHEN] LinkPOLinesToEDocumentLine is called
    // [THEN] An error should be raised

    // [SCENARIO] Linking PO lines already linked to other E-Document lines raises error
    // [GIVEN] PO lines that are already linked to other E-Document lines
    // [WHEN] LinkPOLinesToEDocumentLine is called
    // [THEN] An error should be raised indicating the lines are already linked

    // Tests for LinkReceiptLinesToEDocumentLine
    // [SCENARIO] Linking empty list of receipt lines to E-Document line completes without creating matches
    // [GIVEN] An empty temporary list of receipt lines and an E-Document line
    // [WHEN] LinkReceiptLinesToEDocumentLine is called
    // [THEN] Existing receipt matches should be removed and no new matches should be created

    // [SCENARIO] Linking valid receipt lines to E-Document line creates matches
    // [GIVEN] Valid receipt lines linked to PO lines that are linked to the E-Document line
    // [WHEN] LinkReceiptLinesToEDocumentLine is called
    // [THEN] Receipt line matches should be created

    // [SCENARIO] Linking receipt lines to E-Document line removes existing receipt matches first
    // [GIVEN] An E-Document line with existing receipt matches and new receipt lines to link
    // [WHEN] LinkReceiptLinesToEDocumentLine is called
    // [THEN] Existing receipt matches should be removed and new matches should be created

    // [SCENARIO] Linking receipt lines not linked to any PO lines linked to E-Document line raises error
    // [GIVEN] Receipt lines that are not linked to any of the PO lines linked to the E-Document line
    // [WHEN] LinkReceiptLinesToEDocumentLine is called
    // [THEN] An error should be raised indicating the receipt lines are not linked

    // [SCENARIO] Linking receipt lines with insufficient quantity to cover E-Document line raises error
    // [GIVEN] Receipt lines with total quantity less than the E-Document line quantity
    // [WHEN] LinkReceiptLinesToEDocumentLine is called
    // [THEN] An error should be raised indicating insufficient quantity coverage

    local procedure Initialize()
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        if IsInitialized then
            exit;
        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock, Enum::"E-Document Import Process"::"Version 2.0");
    end;

}