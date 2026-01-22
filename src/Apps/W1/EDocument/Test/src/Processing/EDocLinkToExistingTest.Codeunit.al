// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;


codeunit 139886 "E-Doc Link To Existing Test"
{
    Subtype = Test;
    TestType = IntegrationTest;

    #region Validation Tests

    [Test]
    procedure LinkToExisting_ErrorWhenVendorNoIsMissing()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
        NoVendorErr: Label 'Cannot link e-document to existing purchase document because vendor number is missing in e-document purchase header.';
    begin
        // [SCENARIO] Should error when EDocumentPurchaseHeader."[BC] Vendor No." is empty
        Initialize();

        // [GIVEN] An inbound e-document with draft prepared but no vendor linked
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := '';
        EDocumentPurchaseHeader.Modify();

        // [WHEN] Opening the draft page and clicking Link to Existing Document
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);

        // [THEN] An error is thrown indicating vendor number is missing
        asserterror EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();
        Assert.ExpectedError(NoVendorErr);
    end;

    [Test]
    procedure LinkToExisting_ErrorWhenVendorHasNoICPartnerCode()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
    begin
        // [SCENARIO] Should error when vendor exists but IC Partner Code is blank
        Initialize();

        // [GIVEN] An inbound e-document with draft prepared and vendor linked, but vendor has no IC Partner Code
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // [GIVEN] The vendor has no IC Partner Code
        Vendor."IC Partner Code" := '';
        Vendor.Modify();

        // [WHEN] Opening the draft page and clicking Link to Existing Document
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);

        // [THEN] An error is thrown indicating IC Partner Code must have a value
        asserterror EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('IC Partner Code');
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicesModalPageHandler,ConfirmHandler,PIModalPageHandler')]
    procedure LinkToExisting_SuccessWhenVendorHasICPartnerCode()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
    begin
        // [SCENARIO] Should succeed when vendor has IC Partner Code set
        Initialize();
        SetupICPartner(ICPartner);

        // [GIVEN] An inbound e-document with draft prepared and vendor linked
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Total := 1000;
        EDocumentPurchaseHeader.Modify();

        // [GIVEN] An existing purchase invoice from the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Doc. Amount Incl. VAT" := 1000;
        PurchaseHeader.Modify();
        LibraryVariableStorage.Enqueue(true); // Signal handler to select
        LibraryVariableStorage.Enqueue(PurchaseHeader."No."); // For modal handler

        // [WHEN] Opening the draft page and clicking Link to Existing Document
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();

        // [THEN] The e-document is linked to the existing purchase document
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(EDocument.SystemId, PurchaseHeader."E-Document Link", 'E-Document Link should be set on purchase header');

        // [THEN] The e-document is marked as processed
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be marked as processed');
    end;


    #endregion

    #region Document Selection Tests

    [Test]
    [HandlerFunctions('PurchaseInvoicesModalPageHandler')]
    procedure LinkToExisting_OpensInvoiceListForPurchaseInvoice()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        ICPartner: Record "IC Partner";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
    begin
        // [SCENARIO] When e-document type is Purchase Invoice, the Purchase Invoices page opens
        Initialize();
        SetupICPartner(ICPartner);

        // [GIVEN] An inbound e-document of type Purchase Invoice
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocument."Document Type" := Enum::"E-Document Type"::"Purchase Invoice";
        EDocument.Modify();
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // [WHEN] Opening the draft page and clicking Link to Existing Document
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        LibraryVariableStorage.Enqueue(false); // Signal handler to cancel (no document to select)
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();

        // [THEN] The Purchase Invoices page is opened (verified by handler being called)
        // Handler is called - test passes if no error about missing handler
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemosModalPageHandler')]
    procedure LinkToExisting_OpensCreditMemoListForPurchaseCreditMemo()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        ICPartner: Record "IC Partner";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
    begin
        // [SCENARIO] When e-document type is Purchase Credit Memo, the Purchase Credit Memos page opens
        Initialize();
        SetupICPartner(ICPartner);

        // [GIVEN] An inbound e-document of type Purchase Credit Memo
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocument."Document Type" := Enum::"E-Document Type"::"Purchase Credit Memo";
        EDocument.Modify();
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Modify();

        // [WHEN] Opening the draft page and clicking Link to Existing Document
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();

        // [THEN] The Purchase Credit Memos page is opened (verified by handler being called)
        // Handler is called - test passes if no error about missing handler
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicesVerifyVendorFilterHandler')]
    procedure LinkToExisting_FiltersDocumentsByVendor()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeaderMatchingVendor: Record "Purchase Header";
        PurchaseHeaderOtherVendor: Record "Purchase Header";
        OtherVendor: Record Vendor;
        ICPartner: Record "IC Partner";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
    begin
        // [SCENARIO] The document list should be pre-filtered by vendor no.
        Initialize();
        SetupICPartner(ICPartner);

        // [GIVEN] An inbound e-document with vendor linked
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Total := 1000;
        EDocumentPurchaseHeader.Modify();

        // [GIVEN] A purchase invoice from the matching vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderMatchingVendor, PurchaseHeaderMatchingVendor."Document Type"::Invoice, Vendor."No.");
        PurchaseHeaderMatchingVendor."Doc. Amount Incl. VAT" := 1000;
        PurchaseHeaderMatchingVendor.Modify();

        // [GIVEN] A purchase invoice from a different vendor
        LibraryPurchase.CreateVendor(OtherVendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOtherVendor, PurchaseHeaderOtherVendor."Document Type"::Invoice, OtherVendor."No.");
        PurchaseHeaderOtherVendor."Doc. Amount Incl. VAT" := 1000;
        PurchaseHeaderOtherVendor.Modify();

        // [WHEN] Opening the draft page and clicking Link to Existing Document
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        LibraryVariableStorage.Enqueue(Vendor."No."); // Expected vendor filter
        LibraryVariableStorage.Enqueue(PurchaseHeaderMatchingVendor."No."); // Should be visible
        LibraryVariableStorage.Enqueue(PurchaseHeaderOtherVendor."No."); // Should NOT be visible
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();

        // [THEN] The handler verifies the vendor filter is applied
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicesVerifyAmountFilterHandler')]
    procedure LinkToExisting_FiltersDocumentsByAmount()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeaderMatchingAmount: Record "Purchase Header";
        PurchaseHeaderOtherAmount: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
    begin
        // [SCENARIO] The document list should be pre-filtered by Doc. Amount Incl. VAT matching e-doc total
        Initialize();
        SetupICPartner(ICPartner);

        // [GIVEN] An inbound e-document with total amount set
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Total := 1500;
        EDocumentPurchaseHeader.Modify();

        // [GIVEN] A purchase invoice with matching amount
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderMatchingAmount, PurchaseHeaderMatchingAmount."Document Type"::Invoice, Vendor."No.");
        PurchaseHeaderMatchingAmount."Doc. Amount Incl. VAT" := 1500;
        PurchaseHeaderMatchingAmount.Modify();

        // [GIVEN] A purchase invoice with different amount
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOtherAmount, PurchaseHeaderOtherAmount."Document Type"::Invoice, Vendor."No.");
        PurchaseHeaderOtherAmount."Doc. Amount Incl. VAT" := 2000;
        PurchaseHeaderOtherAmount.Modify();

        // [WHEN] Opening the draft page and clicking Link to Existing Document
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        LibraryVariableStorage.Enqueue(1500); // Expected amount filter
        LibraryVariableStorage.Enqueue(PurchaseHeaderMatchingAmount."No."); // Should be visible
        LibraryVariableStorage.Enqueue(PurchaseHeaderOtherAmount."No."); // Should NOT be visible
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();

        // [THEN] The handler verifies the amount filter is applied
    end;

    #endregion

    #region Post-Link Behavior Tests

    [Test]
    [HandlerFunctions('PurchaseInvoicesModalPageHandler,ConfirmHandler,PIModalPageHandler')]
    procedure LinkToExisting_VerifyPostLinkBehavior()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        AllPurchaseHeaders: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
        InitialPurchaseHeaderCount: Integer;
    begin
        // [SCENARIO] Verify all post-link behaviors:
        // - E-Document Link is set on purchase document
        // - No new document is created
        // - E-Document status becomes Processed
        // - Doc amounts are transferred to purchase document
        // - Created from E-Document is false (since it wasn't created from e-doc)
        Initialize();
        SetupICPartner(ICPartner);

        // [GIVEN] An inbound e-document with draft prepared and specific amounts
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Total := 1500;
        EDocumentPurchaseHeader."Total VAT" := 300;
        EDocumentPurchaseHeader.Modify();

        // [GIVEN] An existing purchase invoice from the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Doc. Amount Incl. VAT" := 1500;
        PurchaseHeader.Modify();

        // [GIVEN] Count of existing purchase headers
        InitialPurchaseHeaderCount := AllPurchaseHeaders.Count();

        LibraryVariableStorage.Enqueue(true); // Signal handler to select
        LibraryVariableStorage.Enqueue(PurchaseHeader."No."); // For modal handler

        // [WHEN] Opening the draft page and clicking Link to Existing Document
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();

        // [THEN] E-Document Link is set on purchase document
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(EDocument.SystemId, PurchaseHeader."E-Document Link", 'E-Document Link should be set on purchase header');

        // [THEN] No new purchase document was created
        Assert.AreEqual(InitialPurchaseHeaderCount, AllPurchaseHeaders.Count(), 'No new purchase document should be created when linking to existing');

        // [THEN] E-Document status becomes Processed
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be marked as processed');

        // [THEN] Doc amounts are transferred to purchase document
        Assert.AreEqual(1500, PurchaseHeader."Doc. Amount Incl. VAT", 'Doc. Amount Incl. VAT should be set from e-document');
        Assert.AreEqual(300, PurchaseHeader."Doc. Amount VAT", 'Doc. Amount VAT should be set from e-document');
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicesModalPageHandler,ConfirmHandler,PIModalPageHandler')]
    procedure LinkToExisting_RelinkToAnotherDocumentUnlinksFirst()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeaderA: Record "Purchase Header";
        PurchaseHeaderB: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
        EmptyGuid: Guid;
    begin
        // [SCENARIO] When relinking an e-document to a different document:
        // - The first document (A) is unlinked
        // - The second document (B) is linked
        // - Neither document is deleted since they weren't created from e-doc
        Initialize();
        SetupICPartner(ICPartner);

        // [GIVEN] An inbound e-document with draft prepared
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Total := 1000;
        EDocumentPurchaseHeader."Total VAT" := 200;
        EDocumentPurchaseHeader.Modify();

        // [GIVEN] Two existing purchase invoices from the same vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderA, PurchaseHeaderA."Document Type"::Invoice, Vendor."No.");
        PurchaseHeaderA."Doc. Amount Incl. VAT" := 1000;
        PurchaseHeaderA.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderB, PurchaseHeaderB."Document Type"::Invoice, Vendor."No.");
        PurchaseHeaderB."Doc. Amount Incl. VAT" := 1000;
        PurchaseHeaderB.Modify();

        // [WHEN] Linking to document A first
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(PurchaseHeaderA."No.");
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();
        EDocPurchaseDraftTestPage.Close();

        // [THEN] Document A is linked
        PurchaseHeaderA.Get(PurchaseHeaderA."Document Type", PurchaseHeaderA."No.");
        Assert.AreEqual(EDocument.SystemId, PurchaseHeaderA."E-Document Link", 'Document A should be linked to e-document');

        // [WHEN] Relinking to document B
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(PurchaseHeaderB."No.");
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();
        EDocPurchaseDraftTestPage.Close();

        // [THEN] Document A is unlinked (E-Document Link is cleared)
        PurchaseHeaderA.Get(PurchaseHeaderA."Document Type", PurchaseHeaderA."No.");
        Assert.AreEqual(EmptyGuid, PurchaseHeaderA."E-Document Link", 'Document A should be unlinked after relinking to B');

        // [THEN] Document B is now linked
        PurchaseHeaderB.Get(PurchaseHeaderB."Document Type", PurchaseHeaderB."No.");
        Assert.AreEqual(EDocument.SystemId, PurchaseHeaderB."E-Document Link", 'Document B should now be linked to e-document');

        // [THEN] Both documents still exist (neither was deleted)
        Assert.IsTrue(PurchaseHeaderA.Get(PurchaseHeaderA."Document Type", PurchaseHeaderA."No."), 'Document A should still exist');
        Assert.IsTrue(PurchaseHeaderB.Get(PurchaseHeaderB."Document Type", PurchaseHeaderB."No."), 'Document B should still exist');
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicesModalPageHandler,ConfirmHandler,PIModalPageHandler')]
    procedure LinkToExisting_UnlinksDocumentCreatedFromEDoc()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        CreatedPurchaseHeader: Record "Purchase Header";
        ExistingPurchaseHeader: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
        EDocPurchaseDraftTestPage: TestPage "E-Document Purchase Draft";
        CreatedDocNo: Code[20];
        EmptyGuid: Guid;
    begin
        // [SCENARIO] When linking to an existing document after a PI was already created from e-doc:
        // - The originally created PI is unlinked but NOT deleted (user must clean up manually)
        // - The existing document is linked
        Initialize();
        SetupICPartner(ICPartner);

        // [GIVEN] An inbound e-document with draft prepared
        LibraryEDocument.CreateInboundEDocument(EDocument, EDocumentService);
        EDocumentPurchaseHeader := LibraryEDocument.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocumentPurchaseHeader.Total := 2000;
        EDocumentPurchaseHeader."Total VAT" := 400;
        EDocumentPurchaseHeader.Modify();

        // [GIVEN] Finalize draft to create a new PI from e-document
        EDocImportParameters."Step to Run" := Enum::"Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
        EDocument.Get(EDocument."Entry No");

        // [GIVEN] Find the created purchase invoice
        CreatedPurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        CreatedPurchaseHeader.FindFirst();
        CreatedDocNo := CreatedPurchaseHeader."No.";

        // [GIVEN] An existing purchase invoice (not created from e-doc)
        LibraryPurchase.CreatePurchHeader(ExistingPurchaseHeader, ExistingPurchaseHeader."Document Type"::Invoice, Vendor."No.");
        ExistingPurchaseHeader."Doc. Amount Incl. VAT" := 2000;
        ExistingPurchaseHeader.Modify();

        // [WHEN] Linking to the existing document
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExistingPurchaseHeader."No.");
        EDocPurchaseDraftTestPage.OpenEdit();
        EDocPurchaseDraftTestPage.GoToRecord(EDocument);
        EDocPurchaseDraftTestPage.LinkToExistingDocument.Invoke();
        EDocPurchaseDraftTestPage.Close();

        // [THEN] The originally created PI is unlinked but still exists (user must clean up manually)
        Assert.IsTrue(CreatedPurchaseHeader.Get(CreatedPurchaseHeader."Document Type"::Invoice, CreatedDocNo), 'The PI created from e-doc should still exist');
        Assert.AreEqual(EmptyGuid, CreatedPurchaseHeader."E-Document Link", 'The PI created from e-doc should be unlinked');

        // [THEN] The existing document is now linked
        ExistingPurchaseHeader.Get(ExistingPurchaseHeader."Document Type", ExistingPurchaseHeader."No.");
        Assert.AreEqual(EDocument.SystemId, ExistingPurchaseHeader."E-Document Link", 'Existing document should be linked');
    end;

    #endregion

    [ModalPageHandler]
    procedure PurchaseInvoicesModalPageHandler(var PurchaseInvoices: TestPage "Purchase Invoices")
    var
        PurchaseInvoiceNo: Code[20];
        ShouldSelect: Boolean;
    begin
        if LibraryVariableStorage.Length() > 0 then begin
            ShouldSelect := LibraryVariableStorage.DequeueBoolean();
            if not ShouldSelect then
                exit; // Cancel selection by not selecting anything

            PurchaseInvoiceNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(PurchaseInvoiceNo));
            PurchaseInvoices.Filter.SetFilter("No.", PurchaseInvoiceNo);
            PurchaseInvoices.First();
            PurchaseInvoices.OK().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure PurchaseCreditMemosModalPageHandler(var PurchaseCreditMemos: TestPage "Purchase Credit Memos")
    begin
        // Handler confirms the page opened - no selection needed for this test
    end;

    [ModalPageHandler]
    procedure PurchaseOrdersModalPageHandler(var PurchaseOrders: TestPage "Purchase Orders")
    begin
        // Handler confirms the page opened - no selection needed for this test
    end;

    [ModalPageHandler]
    procedure PurchaseInvoicesVerifyVendorFilterHandler(var PurchaseInvoices: TestPage "Purchase Invoices")
    var
        VisibleDocNo: Code[20];
        NotVisibleDocNo: Code[20];
    begin
        LibraryVariableStorage.DequeueText(); // Discard expected vendor no. (not needed here)
        VisibleDocNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(VisibleDocNo));
        NotVisibleDocNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(NotVisibleDocNo));

        // Verify the matching vendor document is visible
        PurchaseInvoices.Filter.SetFilter("No.", VisibleDocNo);
        Assert.IsTrue(PurchaseInvoices.First(), 'Document from matching vendor should be visible');

        // Verify the other vendor document is NOT visible (filter should exclude it)
        PurchaseInvoices.Filter.SetFilter("No.", NotVisibleDocNo);
        Assert.IsFalse(PurchaseInvoices.First(), 'Document from different vendor should not be visible due to vendor filter');
    end;

    [ModalPageHandler]
    procedure PurchaseInvoicesVerifyAmountFilterHandler(var PurchaseInvoices: TestPage "Purchase Invoices")
    var
        VisibleDocNo: Code[20];
        NotVisibleDocNo: Code[20];
    begin
        LibraryVariableStorage.DequeueDecimal();
        VisibleDocNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(VisibleDocNo));
        NotVisibleDocNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(NotVisibleDocNo));

        // Verify the matching amount document is visible
        PurchaseInvoices.Filter.SetFilter("No.", VisibleDocNo);
        Assert.IsTrue(PurchaseInvoices.First(), 'Document with matching amount should be visible');

        // Verify the different amount document is NOT visible (filter should exclude it)
        PurchaseInvoices.Filter.SetFilter("No.", NotVisibleDocNo);
        Assert.IsFalse(PurchaseInvoices.First(), 'Document with different amount should not be visible due to amount filter');
    end;

    [PageHandler]
    procedure PIModalPageHandler(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        PurchaseInvoice.Close(); // Opens after finalize draft
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;


    local procedure Initialize()
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetPostedNoSeriesInSetup();
        SetInvoiceNoSeriesInSetup();

        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock, Enum::"E-Document Import Process"::"Version 2.0");
        Commit();
    end;

    local procedure SetInvoiceNoSeriesInSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SetupICPartner(var ICPartner: Record "IC Partner")
    begin
        if not ICPartner.Get('ICTEST') then begin
            ICPartner.Init();
            ICPartner.Code := 'ICTEST';
            ICPartner.Name := 'IC Partner Test';
            ICPartner.Insert();
        end;
        Vendor."IC Partner Code" := ICPartner.Code;
        Vendor.Modify();
    end;

    var
        EDocumentService: Record "E-Document Service";
        Vendor: Record Vendor;
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
}