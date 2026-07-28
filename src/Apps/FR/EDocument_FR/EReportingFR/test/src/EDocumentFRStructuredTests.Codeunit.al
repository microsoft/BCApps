// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 148149 "E-Doc. FR Struct. Import Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        MockCurrencyCode: Code[10];
        EDocumentStatusNotUpdatedErr: Label 'The status of the EDocument was not updated to the expected status after the step was executed.';
        FacturXInvoiceTok: Label 'facturx/facturx-invoice-0.xml', Locked = true;
        FacturXCreditMemoTok: Label 'facturx/facturx-creditmemo-0.xml', Locked = true;
        PeppolBIS30FRInvoiceTok: Label 'peppolfr/peppol-bis-fr-invoice-0.xml', Locked = true;

    #region Factur-X
    [Test]
    procedure FacturXInvoiceIsReadIntoDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // [FEATURE] [E-Document] [Factur-X] [Import]
        // [SCENARIO] A Factur-X invoice is read into a purchase invoice draft

        // [GIVEN] A Factur-X CII invoice is imported on a service that reads Factur-X into draft
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::"Factur-X FR");
        CreateInboundEDocumentFromResource(EDocument, FacturXInvoiceTok);

        // [WHEN] The document is read into draft
        if not ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            Assert.Fail(EDocumentStatusNotUpdatedErr);

        // [THEN] The draft is prepared as a purchase invoice
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Invoice"), Format(EDocument."Process Draft Impl."), 'The draft should be processed as a purchase invoice.');

        // [THEN] The header data is extracted from the Cross Industry Invoice
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('FX-INV-3001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('CMD-2024-9', EDocumentPurchaseHeader."Purchase Order No.", 'Wrong purchase order number.');
        Assert.AreEqual('SERVICE-ACHATS', EDocumentPurchaseHeader."Buyer Reference", 'Wrong buyer reference.');
        Assert.AreEqual('Fournisseur SARL', EDocumentPurchaseHeader."Vendor Company Name", 'Wrong vendor name.');
        Assert.AreEqual('FR12345678901', EDocumentPurchaseHeader."Vendor VAT Id", 'Wrong vendor VAT registration number.');
        Assert.AreEqual('Acheteur SA', EDocumentPurchaseHeader."Customer Company Name", 'Wrong customer name.');
        Assert.AreEqual(20240301D, EDocumentPurchaseHeader."Document Date", 'Wrong document date.');
        Assert.AreEqual(20240331D, EDocumentPurchaseHeader."Due Date", 'Wrong due date.');
        Assert.AreEqual(MockCurrencyCode, EDocumentPurchaseHeader."Currency Code", 'Wrong currency code.');
        Assert.AreEqual(360, EDocumentPurchaseHeader."Sub Total", 'Wrong sub total.');
        Assert.AreEqual(72, EDocumentPurchaseHeader."Total VAT", 'Wrong total VAT.');
        Assert.AreEqual(432, EDocumentPurchaseHeader.Total, 'Wrong total.');

        // [THEN] The line data is extracted from the Cross Industry Invoice
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, EDocumentPurchaseLine.Count(), 'Wrong number of draft lines.');
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('Chaise de bureau', EDocumentPurchaseLine.Description, 'Wrong line description.');
        Assert.AreEqual('ART-500', EDocumentPurchaseLine."Product Code", 'Wrong product code.');
        Assert.AreEqual(3, EDocumentPurchaseLine.Quantity, 'Wrong quantity.');
        Assert.AreEqual(120, EDocumentPurchaseLine."Unit Price", 'Wrong unit price.');
        Assert.AreEqual(360, EDocumentPurchaseLine."Sub Total", 'Wrong line sub total.');
        Assert.AreEqual(20, EDocumentPurchaseLine."VAT Rate", 'Wrong VAT rate.');
    end;

    [Test]
    procedure FacturXCreditMemoIsReadIntoDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        // [FEATURE] [E-Document] [Factur-X] [Import]
        // [SCENARIO] A Factur-X credit memo is read into a purchase credit memo draft

        // [GIVEN] A Factur-X CII credit memo is imported
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::"Factur-X FR");
        CreateInboundEDocumentFromResource(EDocument, FacturXCreditMemoTok);

        // [WHEN] The document is read into draft
        if not ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            Assert.Fail(EDocumentStatusNotUpdatedErr);

        // [THEN] The draft is prepared as a purchase credit memo referring to the original invoice
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Credit Memo"), Format(EDocument."Process Draft Impl."), 'The draft should be processed as a purchase credit memo.');
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('FX-AVR-4001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('FX-INV-3001', EDocumentPurchaseHeader."Applies-to Ext. Invoice No.", 'Wrong applies-to external invoice number.');
    end;

    [Test]
    procedure FacturXUnsupportedRootElementFails()
    var
        EDocument: Record "E-Document";
        UnsupportedXmlTok: Label '<?xml version="1.0" encoding="UTF-8"?><SomethingElse xmlns="urn:test" />', Locked = true;
    begin
        // [FEATURE] [E-Document] [Factur-X] [Import]
        // [SCENARIO] Reading a document that is not a Cross Industry Invoice fails with a clear error

        // [GIVEN] An XML document with an unsupported root element is imported
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::"Factur-X FR");
        CreateInboundEDocumentFromText(EDocument, UnsupportedXmlTok);

        // [WHEN] The document is read into draft
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft");

        // [THEN] The document is not readable into a draft
        EDocument.Get(EDocument."Entry No");
        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(Format("Import E-Doc. Proc. Status"::Readable), Format(EDocument."Import Processing Status"), 'The document should not have been read into a draft.');
    end;

    [Test]
    procedure FacturXInvoiceCanBeReadIntoDraftTwice()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // [FEATURE] [E-Document] [Factur-X] [Import]
        // [SCENARIO] Re-running Read into Draft replaces the previous draft instead of duplicating it

        // [GIVEN] A Factur-X invoice that has been read into draft
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::"Factur-X FR");
        CreateInboundEDocumentFromResource(EDocument, FacturXInvoiceTok);
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft");

        // [WHEN] The document is read into draft again
        if not ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            Assert.Fail(EDocumentStatusNotUpdatedErr);

        // [THEN] The draft still contains a single line
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, EDocumentPurchaseLine.Count(), 'Re-reading the document should not duplicate the draft lines.');
    end;
    #endregion

    #region Peppol BIS 3.0 FR
    [Test]
    procedure PeppolBIS30FRInvoiceIsReadIntoDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // [FEATURE] [E-Document] [Peppol BIS 3.0 FR] [Import]
        // [SCENARIO] A Peppol BIS 3.0 FR invoice is read into a purchase invoice draft

        // [GIVEN] A Peppol BIS 3.0 FR invoice is imported on a service that reads Peppol BIS 3.0 FR into draft
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::"Peppol BIS 3.0 FR");
        CreateInboundEDocumentFromResource(EDocument, PeppolBIS30FRInvoiceTok);

        // [WHEN] The document is read into draft
        if not ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            Assert.Fail(EDocumentStatusNotUpdatedErr);

        // [THEN] The draft is prepared as a purchase invoice
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Invoice"), Format(EDocument."Process Draft Impl."), 'The draft should be processed as a purchase invoice.');

        // [THEN] The header data, including the buyer reference, is extracted
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('PBIS-FR-6001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('CMD-2026-4', EDocumentPurchaseHeader."Purchase Order No.", 'Wrong purchase order number.');
        Assert.AreEqual('SERVICE-ACHATS', EDocumentPurchaseHeader."Buyer Reference", 'Wrong buyer reference.');
        Assert.AreEqual('Fournisseur SARL', EDocumentPurchaseHeader."Vendor Company Name", 'Wrong vendor name.');
        Assert.AreEqual('Acheteur SA', EDocumentPurchaseHeader."Customer Company Name", 'Wrong customer name.');
        Assert.AreEqual(MockCurrencyCode, EDocumentPurchaseHeader."Currency Code", 'Wrong currency code.');
        Assert.AreEqual(360, EDocumentPurchaseHeader."Sub Total", 'Wrong sub total.');
        Assert.AreEqual(432, EDocumentPurchaseHeader.Total, 'Wrong total.');

        // [THEN] The line data is extracted
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, EDocumentPurchaseLine.Count(), 'Wrong number of draft lines.');
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('Chaise de bureau', EDocumentPurchaseLine.Description, 'Wrong line description.');
        Assert.AreEqual('ART-500', EDocumentPurchaseLine."Product Code", 'Wrong product code.');
        Assert.AreEqual(3, EDocumentPurchaseLine.Quantity, 'Wrong quantity.');
        Assert.AreEqual(360, EDocumentPurchaseLine."Sub Total", 'Wrong line sub total.');
    end;
    #endregion

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        DocumentAttachment: Record "Document Attachment";
        Currency: Record Currency;
        EDocumentsSetup: Record "E-Documents Setup";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();

        if IsInitialized then
            exit;

        EDocument.DeleteAll(false);
        EDocumentServiceStatus.DeleteAll(false);
        EDocumentService.DeleteAll(false);
        EDocDataStorage.DeleteAll(false);
        EDocumentPurchaseHeader.DeleteAll(false);
        EDocumentPurchaseLine.DeleteAll(false);
        DocumentAttachment.DeleteAll(false);

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"No Integration");
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"No Integration");
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService.Modify();
        EDocumentsSetup.InsertNewExperienceSetup();

        // Set a currency that can be used across all localizations
        MockCurrencyCode := 'XYZ';
        Currency.Init();
        Currency.Validate(Code, MockCurrencyCode);
        if Currency.Insert(true) then;
        CreateCurrencyExchangeRate();

        IsInitialized := true;
    end;

    local procedure SetReadIntoDraftImpl(ReadIntoDraftImpl: Enum "E-Doc. Read into Draft")
    begin
        EDocumentService."Read into Draft Impl." := ReadIntoDraftImpl;
        EDocumentService.Modify(false);
    end;

    local procedure CreateInboundEDocumentFromResource(var EDocument: Record "E-Document"; FilePath: Text)
    begin
        CreateInboundEDocumentFromText(EDocument, NavApp.GetResourceAsText(FilePath));
    end;

    local procedure CreateInboundEDocumentFromText(var EDocument: Record "E-Document"; Content: Text)
    var
        EDocLogRecord: Record "E-Document Log";
        EDocumentLog: Codeunit "E-Document Log";
    begin
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::XML, Content);
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Readable);

        EDocument."Structured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify(false);
    end;

    local procedure ProcessEDocumentToStep(var EDocument: Record "E-Document"; ProcessingStep: Enum "Import E-Document Steps"): Boolean
    var
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Readable);
        EDocImportParameters."Step to Run" := ProcessingStep;
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
        EDocument.CalcFields("Import Processing Status");

        case ProcessingStep of
            "Import E-Document Steps"::"Finish draft":
                exit(EDocument."Import Processing Status" = Enum::"Import E-Doc. Proc. Status"::Processed);
            "Import E-Document Steps"::"Prepare draft":
                exit(EDocument."Import Processing Status" = Enum::"Import E-Doc. Proc. Status"::"Draft Ready");
            else
                exit(EDocument."Import Processing Status" = Enum::"Import E-Doc. Proc. Status"::"Ready for draft");
        end;
    end;

    local procedure CreateCurrencyExchangeRate()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := MockCurrencyCode;
        CurrencyExchangeRate."Starting Date" := WorkDate();
        CurrencyExchangeRate."Exchange Rate Amount" := 10;
        CurrencyExchangeRate."Relational Exch. Rate Amount" := 1.23;
        CurrencyExchangeRate.Insert(true);
    end;
}
