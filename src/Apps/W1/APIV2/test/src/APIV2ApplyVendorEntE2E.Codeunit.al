codeunit 139867 "APIV2 - Apply Vendor Ent. E2E"
{
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        LibraryGraphMgt.SetAuthenticationProvider(
            Enum::"API Test Authentication"::"Microsoft Test Environment");
        LibraryGraphMgt.SetLicenseSafeWorkDate();
        // [FEATURE] [Graph] [Vendor Payments] [Apply Vendor Entries]
    end;

    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryGraphJournalLines: Codeunit "Library - Graph Journal Lines";
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
        VendorPaymentJournalsServiceTxt: Label 'vendorPaymentJournals';
        VendorPaymentsServiceTxt: Label 'vendorPayments';
        ApplyVendorEntriesServiceTxt: Label 'applyVendorEntries';
        DocumentNumberTxt: Label 'documentNumber';
        VendorNumberTxt: Label 'vendorNumber';
        VendorDoesNotExistErr: Label 'The Vendor does not exist', Locked = true;
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetApplyVendorEntriesReturnsOpenEntries()
    var
        JournalName: Code[10];
        VendorNo: Code[20];
        AppliesToDocNo: Code[20];
        VendorPaymentIdText: Text;
        LineJSON: Text;
        EntriesJSON: Text;
        EntryJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The applyVendorEntries part returns the vendor's open ledger entries for a vendor payment
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a vendor payments journal
        JournalName := LibraryGraphJournalLines.CreateVendorPaymentsJournal();

        // [GIVEN] a vendor with one open (posted) purchase invoice
        VendorNo := LibraryGraphJournalLines.CreateVendor();
        AppliesToDocNo := CreatePostedPurchaseInvoiceForVendor(VendorNo);

        // [GIVEN] a vendor payment for that vendor created through the API
        LineJSON := LibraryGraphMgt.AddPropertytoJSON('', VendorNumberTxt, VendorNo);
        Commit();
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), Page::"APIV2 - Vendor Paym. Journals", VendorPaymentJournalsServiceTxt, VendorPaymentsServiceTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);
        Assert.IsTrue(LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', VendorPaymentIdText), 'The created vendor payment should have an id');

        // [WHEN] we GET the applyVendorEntries for the payment
        TargetURL := GetApplyVendorEntriesURL(JournalName, VendorPaymentIdText);
        Clear(ResponseText);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the vendor's open invoice entry is returned
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'value', EntriesJSON);
        Assert.AreEqual(1, LibraryGraphMgt.GetCollectionCountFromJSON(EntriesJSON), 'The open vendor ledger entry should be returned');

        EntryJSON := LibraryGraphMgt.GetObjectFromCollectionByIndex(EntriesJSON, 0);
        LibraryGraphMgt.VerifyPropertyInJSON(EntryJSON, DocumentNumberTxt, AppliesToDocNo);
        LibraryGraphMgt.VerifyPropertyInJSON(EntryJSON, VendorNumberTxt, VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetApplyVendorEntriesFailsWhenNoVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        BlankGUID: Guid;
        VendorPaymentGUID: Guid;
        LineNo: Integer;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The applyVendorEntries part requires a vendor: for a vendor payment without a vendor the request fails
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a vendor payments journal
        JournalName := LibraryGraphJournalLines.CreateVendorPaymentsJournal();

        // [GIVEN] a vendor payment line without a vendor
        LineNo := LibraryGraphJournalLines.CreateVendorPayment(JournalName, '', BlankGUID, '', BlankGUID, 0, '');
        GenJournalLine.Get(GraphMgtJournal.GetDefaultVendorPaymentsTemplateName(), JournalName, LineNo);
        VendorPaymentGUID := GenJournalLine.SystemId;
        Commit();

        // [WHEN] we GET the applyVendorEntries for the line
        // [THEN] the request fails with a 400 because the payment does not have a vendor
        TargetURL := GetApplyVendorEntriesURL(JournalName, VendorPaymentGUID);
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
        Assert.ExpectedError('400');
        Assert.ExpectedError(VendorDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyVendorEntryAppliesPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        VendorNo: Code[20];
        AppliesToDocNo: Code[20];
        LineJSON: Text;
        EntriesJSON: Text;
        EntryJSON: Text;
        EntryId: Text;
        ResponseText: Text;
        TargetURL: Text;
        VendorPaymentGUID: Guid;
    begin
        // [SCENARIO] Applying a vendor entry through the applyVendorEntries part applies the vendor payment
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a vendor payments journal
        JournalName := LibraryGraphJournalLines.CreateVendorPaymentsJournal();

        // [GIVEN] a vendor with one open (posted) purchase invoice
        VendorNo := LibraryGraphJournalLines.CreateVendor();
        AppliesToDocNo := CreatePostedPurchaseInvoiceForVendor(VendorNo);

        // [GIVEN] a vendor payment for that vendor created through the API
        LineJSON := LibraryGraphMgt.AddPropertytoJSON('', VendorNumberTxt, VendorNo);
        Commit();
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            GetJournalID(JournalName), Page::"APIV2 - Vendor Paym. Journals", VendorPaymentJournalsServiceTxt, VendorPaymentsServiceTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, LineJSON, ResponseText);

        // [GIVEN] the created payment has a posting date on or after the invoice and is not applied yet
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultVendorPaymentsTemplateName());
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify();
        Assert.AreEqual('', GenJournalLine."Applies-to ID", 'The payment should not be applied before the API call');
        VendorPaymentGUID := GenJournalLine.SystemId;
        Commit();

        // [GIVEN] the open vendor ledger entry returned by the applyVendorEntries part
        TargetURL := GetApplyVendorEntriesURL(JournalName, Format(VendorPaymentGUID));
        Clear(ResponseText);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
        LibraryGraphMgt.GetPropertyValueFromJSON(ResponseText, 'value', EntriesJSON);
        EntryJSON := LibraryGraphMgt.GetObjectFromCollectionByIndex(EntriesJSON, 0);
        LibraryGraphMgt.VerifyPropertyInJSON(EntryJSON, DocumentNumberTxt, AppliesToDocNo);
        Assert.IsTrue(LibraryGraphMgt.GetObjectIDFromJSON(EntryJSON, 'id', EntryId), 'The apply vendor entry should have an id');

        // [WHEN] we PATCH the entry to apply it
        TargetURL := LibraryGraphMgt.AppendPathToTargetURL(
            TargetURL, '(' + LibraryGraphMgt.StripBrackets(EntryId) + ')');
        LibraryGraphMgt.PatchToWebService(TargetURL, '{"applied": true}', ResponseText);

        // [THEN] the vendor payment is now applied
        GenJournalLine.GetBySystemId(VendorPaymentGUID);
        Assert.AreNotEqual('', GenJournalLine."Applies-to ID", 'The payment should be applied after the API call');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"APIV2 - Apply Vendor Ent. E2E");

        if not isInitialized then
            isInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"APIV2 - Apply Vendor Ent. E2E");
    end;

    local procedure GetJournalID(JournalName: Code[10]): Guid
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(GraphMgtJournal.GetDefaultVendorPaymentsTemplateName(), JournalName);
        exit(GenJournalBatch.SystemId);
    end;

    local procedure GetApplyVendorEntriesURL(JournalName: Code[10]; VendorPaymentId: Text): Text
    begin
        exit(
          LibraryGraphMgt.CreateTargetURLWithTwoSubpages(
            Format(GetJournalID(JournalName)), VendorPaymentId, Page::"APIV2 - Vendor Paym. Journals",
            VendorPaymentJournalsServiceTxt, VendorPaymentsServiceTxt, ApplyVendorEntriesServiceTxt));
    end;

    local procedure CreatePostedPurchaseInvoiceForVendor(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 1000, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;
}
