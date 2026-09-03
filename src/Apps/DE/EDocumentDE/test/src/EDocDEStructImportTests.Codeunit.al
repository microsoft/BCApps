// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 148501 "E-Doc. DE Struct. Import Tests"
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
        ZUGFeRDInvoiceTok: Label 'zugferd/zugferd-invoice-0.xml', Locked = true;
        ZUGFeRDCreditMemoTok: Label 'zugferd/zugferd-creditmemo-0.xml', Locked = true;
        PEPPOLBIS30DEInvoiceTok: Label 'peppolde/peppol-bis-de-invoice-0.xml', Locked = true;

    #region ZUGFeRD
    [Test]
    procedure ZUGFeRDInvoiceIsReadIntoDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // [FEATURE] [E-Document] [ZUGFeRD] [Import]
        // [SCENARIO] A ZUGFeRD invoice is read into a purchase invoice draft

        // [GIVEN] A ZUGFeRD CII invoice is imported on a service that reads ZUGFeRD into draft
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::ZUGFeRD);
        CreateInboundEDocumentFromResource(EDocument, ZUGFeRDInvoiceTok);

        // [WHEN] The document is read into draft
        if not ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            Assert.Fail(EDocumentStatusNotUpdatedErr);

        // [THEN] The draft is prepared as a purchase invoice
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Invoice"), Format(EDocument."Process Draft Impl."), 'The draft should be processed as a purchase invoice.');

        // [THEN] The header data is extracted from the Cross Industry Invoice
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('ZF-INV-1001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('PO-2024-77', EDocumentPurchaseHeader."Purchase Order No.", 'Wrong purchase order number.');
        Assert.AreEqual('04011000-12345-34', EDocumentPurchaseHeader."Buyer Reference DE", 'Wrong buyer reference.');
        Assert.AreEqual('Fabrikam GmbH', EDocumentPurchaseHeader."Vendor Company Name", 'Wrong vendor name.');
        Assert.AreEqual('Hauptstrasse 1', EDocumentPurchaseHeader."Vendor Address", 'Wrong vendor address.');
        Assert.AreEqual('DE123456789', EDocumentPurchaseHeader."Vendor VAT Id", 'The VAT registration scheme should be preferred over other tax registrations.');
        Assert.AreEqual('Contoso AG', EDocumentPurchaseHeader."Customer Company Name", 'Wrong customer name.');
        Assert.AreEqual(20240115D, EDocumentPurchaseHeader."Document Date", 'Wrong document date.');
        Assert.AreEqual(20240214D, EDocumentPurchaseHeader."Due Date", 'Wrong due date.');
        Assert.AreEqual(MockCurrencyCode, EDocumentPurchaseHeader."Currency Code", 'Wrong currency code.');
        Assert.AreEqual(100, EDocumentPurchaseHeader."Sub Total", 'Wrong sub total.');
        Assert.AreEqual(19, EDocumentPurchaseHeader."Total VAT", 'Wrong total VAT.');
        Assert.AreEqual(119, EDocumentPurchaseHeader.Total, 'Wrong total.');
        Assert.AreEqual(119, EDocumentPurchaseHeader."Amount Due", 'Wrong amount due.');

        // [THEN] The line data is extracted from the Cross Industry Invoice
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, EDocumentPurchaseLine.Count(), 'Wrong number of draft lines.');
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('Coffee beans', EDocumentPurchaseLine.Description, 'Wrong line description.');
        Assert.AreEqual('ITEM-100', EDocumentPurchaseLine."Product Code", 'Wrong product code.');
        Assert.AreEqual(2, EDocumentPurchaseLine.Quantity, 'Wrong quantity.');
        Assert.AreEqual('H87', EDocumentPurchaseLine."Unit of Measure", 'Wrong unit of measure.');
        Assert.AreEqual(50, EDocumentPurchaseLine."Unit Price", 'Wrong unit price.');
        Assert.AreEqual(100, EDocumentPurchaseLine."Sub Total", 'Wrong line sub total.');
        Assert.AreEqual(19, EDocumentPurchaseLine."VAT Rate", 'Wrong VAT rate.');
    end;

    [Test]
    procedure ZUGFeRDRepeatedTaxRegistrationsAreImportedByScheme()
    var
        EDocument: Record "E-Document";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ImportZUGFeRDDocument: Codeunit "Import ZUGFeRD Document";
        EmptyTempBlob: Codeunit "Temp Blob";
        XMLTempBlob: Codeunit "Temp Blob";
        EmptyOutStream: OutStream;
        XMLOutStream: OutStream;
        PdfInStream: InStream;
        XMLInStream: InStream;
        XmlContent: Text;
        BuyerRegistrationNo: Text[20];
        BuyerTradePartyEndTok: Label '</ram:BuyerTradeParty>', Locked = true;
        BuyerLegalOrganizationTok: Label '<ram:SpecifiedLegalOrganization><ram:ID>%1</ram:ID></ram:SpecifiedLegalOrganization></ram:BuyerTradeParty>', Locked = true;
    begin
        // [FEATURE] [E-Document] [ZUGFeRD] [Import]
        // [SCENARIO 646793] Repeated ZUGFeRD tax registrations are selected by their scheme
        Initialize();

        // [GIVEN] The seller is matched by the VA registration that follows its FC registration
        Vendor."VAT Registration No." := 'DE123456789';
        Vendor."Registration Number" := '';
        Vendor.Modify(true);

        // [GIVEN] The buyer has a VA registration and a legal registration
        BuyerRegistrationNo := 'BUYER-LEGAL';
        XmlContent := NavApp.GetResourceAsText(ZUGFeRDInvoiceTok);
        XmlContent := XmlContent.Replace(BuyerTradePartyEndTok, StrSubstNo(BuyerLegalOrganizationTok, BuyerRegistrationNo));
        XMLTempBlob.CreateOutStream(XMLOutStream, TextEncoding::UTF8);
        XMLOutStream.WriteText(XmlContent);
        XMLTempBlob.CreateInStream(XMLInStream, TextEncoding::UTF8);
        TempXMLBuffer.LoadFromStream(XMLInStream);
        EmptyTempBlob.CreateOutStream(EmptyOutStream);
        EmptyTempBlob.CreateInStream(PdfInStream);

        // [WHEN] The ZUGFeRD basic information is parsed
        ImportZUGFeRDDocument.ParseInvoiceBasicInfo(EDocument, TempXMLBuffer, 'rsm:CrossIndustryInvoice', PdfInStream);

        // [THEN] The seller VA and the buyer VAT and legal registrations are imported independently
        Assert.AreEqual(Vendor."No.", EDocument."Bill-to/Pay-to No.", 'The vendor was not selected by the second VA tax registration.');
        Assert.AreEqual('DE987654321', EDocument."Receiving Company VAT Reg. No.", 'The buyer VAT Registration No. was not imported.');
        Assert.AreEqual(BuyerRegistrationNo, EDocument."Receiving Company Reg. No.", 'The buyer Registration No. was not imported.');
    end;

    [Test]
    procedure ZUGFeRDCreditMemoIsReadIntoDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        // [FEATURE] [E-Document] [ZUGFeRD] [Import]
        // [SCENARIO] A ZUGFeRD credit memo is read into a purchase credit memo draft

        // [GIVEN] A ZUGFeRD CII credit memo is imported
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::ZUGFeRD);
        CreateInboundEDocumentFromResource(EDocument, ZUGFeRDCreditMemoTok);

        // [WHEN] The document is read into draft
        if not ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            Assert.Fail(EDocumentStatusNotUpdatedErr);

        // [THEN] The draft is prepared as a purchase credit memo referring to the original invoice
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Credit Memo"), Format(EDocument."Process Draft Impl."), 'The draft should be processed as a purchase credit memo.');
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('ZF-CRM-2001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('ZF-INV-1001', EDocumentPurchaseHeader."Vendor Invoice No.", 'Wrong applies-to external invoice number.');
    end;

    [Test]
    procedure ZUGFeRDUnsupportedRootElementFails()
    var
        EDocument: Record "E-Document";
        UnsupportedXmlTok: Label '<?xml version="1.0" encoding="UTF-8"?><SomethingElse xmlns="urn:test" />', Locked = true;
    begin
        // [FEATURE] [E-Document] [ZUGFeRD] [Import]
        // [SCENARIO] Reading a document that is not a Cross Industry Invoice fails with a clear error

        // [GIVEN] An XML document with an unsupported root element is imported
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::ZUGFeRD);
        CreateInboundEDocumentFromText(EDocument, UnsupportedXmlTok);

        // [WHEN] The document is read into draft
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft");

        // [THEN] The document is not readable into a draft
        EDocument.Get(EDocument."Entry No");
        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(Format("Import E-Doc. Proc. Status"::Readable), Format(EDocument."Import Processing Status"), 'The document should not have been read into a draft.');
    end;

    [Test]
    procedure ZUGFeRDInvoiceCanBeReadIntoDraftTwice()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // [FEATURE] [E-Document] [ZUGFeRD] [Import]
        // [SCENARIO] Re-running Read into Draft replaces the previous draft instead of duplicating it

        // [GIVEN] A ZUGFeRD invoice that has been read into draft
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::ZUGFeRD);
        CreateInboundEDocumentFromResource(EDocument, ZUGFeRDInvoiceTok);
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft");

        // [WHEN] The document is read into draft again
        if not ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            Assert.Fail(EDocumentStatusNotUpdatedErr);

        // [THEN] The draft still contains a single line
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, EDocumentPurchaseLine.Count(), 'Re-reading the document should not duplicate the draft lines.');
    end;
    #endregion

    #region PEPPOL BIS 3.0 DE
    [Test]
    procedure PEPPOLBIS30DEInvoiceIsReadIntoDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // [FEATURE] [E-Document] [PEPPOL BIS 3.0 DE] [Import]
        // [SCENARIO] A PEPPOL BIS 3.0 DE invoice is read into a purchase invoice draft, including the Leitweg-ID

        // [GIVEN] A PEPPOL BIS 3.0 DE invoice is imported on a service that reads PEPPOL BIS 3.0 DE into draft
        Initialize();
        SetReadIntoDraftImpl("E-Doc. Read into Draft"::"PEPPOL BIS 3.0 DE");
        CreateInboundEDocumentFromResource(EDocument, PEPPOLBIS30DEInvoiceTok);

        // [WHEN] The document is read into draft
        if not ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            Assert.Fail(EDocumentStatusNotUpdatedErr);

        // [THEN] The draft is prepared as a purchase invoice
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Invoice"), Format(EDocument."Process Draft Impl."), 'The draft should be processed as a purchase invoice.');

        // [THEN] The header data, including the German buyer reference, is extracted
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('PBIS-DE-5001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('PO-2026-11', EDocumentPurchaseHeader."Purchase Order No.", 'Wrong purchase order number.');
        Assert.AreEqual('04011000-12345-34', EDocumentPurchaseHeader."Buyer Reference DE", 'The Leitweg-ID from BuyerReference should be extracted.');
        Assert.AreEqual('CRONUS International', EDocumentPurchaseHeader."Vendor Company Name", 'Wrong vendor name.');
        Assert.AreEqual('The Cannon Group PLC', EDocumentPurchaseHeader."Customer Company Name", 'Wrong customer name.');
        Assert.AreEqual(MockCurrencyCode, EDocumentPurchaseHeader."Currency Code", 'Wrong currency code.');
        Assert.AreEqual(1000, EDocumentPurchaseHeader."Sub Total", 'Wrong sub total.');
        Assert.AreEqual(1190, EDocumentPurchaseHeader.Total, 'Wrong total.');

        // [THEN] The line data is extracted
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, EDocumentPurchaseLine.Count(), 'Wrong number of draft lines.');
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('Bicycle', EDocumentPurchaseLine.Description, 'Wrong line description.');
        Assert.AreEqual(2, EDocumentPurchaseLine.Quantity, 'Wrong quantity.');
        Assert.AreEqual(1000, EDocumentPurchaseLine."Sub Total", 'Wrong line sub total.');
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
