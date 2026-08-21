// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 148500 "XRechnung Structured Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        XRechnungStructuredValidations: Codeunit "XRechnung Struct. Validations";
        IsInitialized: Boolean;
        CompanyIDFormatTok: Label '<cbc:CompanyID>%1</cbc:CompanyID>', Locked = true;
        EDocumentStatusNotUpdatedErr: Label 'The status of the EDocument was not updated to the expected status after the step was executed.';
        TestFileTok: Label 'xrechnung/xrechnung-invoice-0.xml', Locked = true;
        UnsupportedXmlRootElementErr: Label 'Unsupported XML root element: %1.', Comment = '%1 = local name of the XML root element';
        MockCurrencyCode: Code[10];
        MockDate: Date;

    #region XRechnung XML
    [Test]
    procedure TestXRechnungInvoice_ValidDocument()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [E-Document] [XRechnung] [Import]
        // [SCENARIO] Import and process a valid XRechnung invoice document

        // [GIVEN] A valid XRechnung XML invoice document is imported
        Initialize(Enum::"Service Integration"::"No Integration");
        SetupXRechnungEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, TestFileTok);

        // [WHEN] The document is processed to draft status
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then begin
            XRechnungStructuredValidations.SetMockCurrencyCode(MockCurrencyCode);
            XRechnungStructuredValidations.SetMockDate(MockDate);

            // [THEN] The full E-Document content is correctly extracted
            XRechnungStructuredValidations.AssertFullEDocumentContentExtracted(EDocument."Entry No");
        end else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    [HandlerFunctions('EDocumentPurchaseHeaderPageHandler')]
    procedure TestXRechnungInvoice_ValidDocument_ViewExtractedData()
    var
        EDocument: Record "E-Document";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        // [FEATURE] [E-Document] [XRechnung] [View Data]
        // [SCENARIO] View extracted data from a valid XRechnung invoice document

        // [GIVEN] A valid XRechnung XML invoice document is imported
        Initialize(Enum::"Service Integration"::"No Integration");
        SetupXRechnungEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, TestFileTok);

        // [WHEN] The document is processed to draft status
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft");
        EDocument.Get(EDocument."Entry No");

        // [WHEN] View extracted data is called
        EDocImport.ViewExtractedData(EDocument);

        // [THEN] The extracted data page opens and can be handled properly (verified by page handler)
        // EDocumentPurchaseHeaderPageHandler
    end;

    [Test]
    procedure TestXRechnungInvoice_ValidDocument_PurchaseInvoiceCreated()
    var
        EDocument: Record "E-Document";
        PurchaseHeader: Record "Purchase Header";
        DummyItem: Record Item;
        EDocumentProcessing: Codeunit "E-Document Processing";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        VariantRecord: Variant;
    begin
        // [FEATURE] [E-Document] [XRechnung] [Purchase Invoice Creation]
        // [SCENARIO] Create a purchase invoice from a valid XRechnung invoice document

        // [GIVEN] A valid XRechnung XML invoice document is imported
        Initialize(Enum::"Service Integration"::"No Integration");
        Vendor."VAT Registration No." := 'GB123456789';
        Vendor.Modify(true);
        SetupXRechnungEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, TestFileTok);

        // [WHEN] The document is processed through finish draft step
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Finish draft");
        EDocument.Get(EDocument."Entry No");

        // [WHEN] The created purchase record is retrieved
        EDocumentProcessing.GetRecord(EDocument, VariantRecord);
        DataTypeManagement.GetRecordRef(VariantRecord, RecRef);
        RecRef.SetTable(PurchaseHeader);

        // [THEN] The purchase header is correctly created with XRechnung data
        XRechnungStructuredValidations.SetMockCurrencyCode(MockCurrencyCode);
        XRechnungStructuredValidations.SetMockDate(MockDate);
        XRechnungStructuredValidations.AssertPurchaseDocument(Vendor."No.", PurchaseHeader, DummyItem);
    end;

    [Test]
    procedure TestXRechnungInvoice_RepeatedTaxSchemesSelectVendorAndValidateCompany()
    var
        CompanyInformation: Record "Company Information";
        EDocument: Record "E-Document";
        PurchaseHeader: Record "Purchase Header";
        EDocumentProcessing: Codeunit "E-Document Processing";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        VariantRecord: Variant;
        CompanyRegistrationNo: Text[20];
        VendorRegistrationNo: Text[20];
        XmlContent: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 646793] XRechnung VAT, FC, and legal identifiers are imported independently
        Initialize(Enum::"Service Integration"::"No Integration");
        SetupXRechnungEDocumentService();

        // [GIVEN] Vendor and company are configured for Registration No. matching
        VendorRegistrationNo := 'SUPPLIER-FC';
        Vendor.GLN := '';
        Vendor."VAT Registration No." := '';
        Vendor."Registration Number" := VendorRegistrationNo;
        Vendor."Use Reg. No. in E-Document" := true;
        Vendor.Modify(true);
        CompanyRegistrationNo := 'BUYER-LEGAL';
        CompanyInformation.Get();
        CompanyInformation.GLN := '';
        CompanyInformation."VAT Registration No." := 'GB789456278';
        CompanyInformation."Registration No." := CompanyRegistrationNo;
        CompanyInformation."Use GLN in Electronic Document" := false;
        CompanyInformation."Use Reg. No. in E-Document" := true;
        CompanyInformation.Modify(true);

        // [GIVEN] An XRechnung with supplier VAT and FC tax schemes and a buyer VAT scheme plus legal registration
        XmlContent := NavApp.GetResourceAsText(TestFileTok);
        AddSupplierFCTaxScheme(XmlContent, 'GB123456789', VendorRegistrationNo);
        XmlContent := XmlContent.Replace('<cbc:CompanyID>789456278</cbc:CompanyID>', StrSubstNo(CompanyIDFormatTok, CompanyRegistrationNo));
        XmlContent := XmlContent.Replace('<cbc:ID>8712345000004</cbc:ID>', '<cbc:ID></cbc:ID>');
        CreateInboundEDocumentFromXMLText(EDocument, XmlContent);

        // [WHEN] The document is processed into a purchase invoice
        Assert.IsTrue(ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Finish draft"), EDocumentStatusNotUpdatedErr);
        EDocument.Get(EDocument."Entry No");
        EDocumentProcessing.GetRecord(EDocument, VariantRecord);
        DataTypeManagement.GetRecordRef(VariantRecord, RecRef);
        RecRef.SetTable(PurchaseHeader);

        // [THEN] The supplier FC scheme selected the vendor and the buyer VAT and legal identifiers were imported
        Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", 'The vendor was not selected by Registration No.');
        Assert.AreEqual(CompanyInformation."VAT Registration No.", EDocument."Receiving Company VAT Reg. No.", 'The receiving company VAT Reg. No. was not imported from the buyer VAT tax scheme.');
        Assert.AreEqual(CompanyRegistrationNo, EDocument."Receiving Company Reg. No.", 'The receiving company Reg. No. was not imported from the buyer legal entity.');
    end;

    [Test]
    procedure TestXRechnungInvoice_ValidDocument_UpdateDraftAndFinalize()
    var
        EDocument: Record "E-Document";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        EDocPurchaseDraft: TestPage "E-Document Purchase Draft";
        VariantRecord: Variant;
    begin
        // [FEATURE] [E-Document] [XRechnung] [Draft Update]
        // [SCENARIO] Update draft purchase document data and finalize processing

        // [GIVEN] A valid XRechnung XML invoice document is imported and processed to draft preparation
        Initialize(Enum::"Service Integration"::"No Integration");
        Vendor."VAT Registration No." := 'GB123456789';
        Vendor.Modify(true);
        SetupXRechnungEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, TestFileTok);
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Prepare draft");

        // [GIVEN] A generic item is created for manual assignment
        LibraryEDoc.CreateGenericItem(Item, '');
        Item.Validate("Purch. Unit of Measure", Item."Base Unit of Measure");
        Item.Modify(true);

        // [WHEN] The draft document is opened and modified through UI
        EDocPurchaseDraft.OpenEdit();
        EDocPurchaseDraft.GoToRecord(EDocument);
        EDocPurchaseDraft.Lines.First();
        EDocPurchaseDraft.Lines."Line Type".SetValue("Purchase Line Type"::Item);
        EDocPurchaseDraft.Lines."No.".SetValue(Item."No.");
        EDocPurchaseDraft.Lines.Next();
        EDocPurchaseDraft.Close();

        // Prepare Draft matched the line to an item via the product code's item reference.
        // Clear that reference so the manual item assignment is not overwritten on Finish Draft.
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseLine.FindFirst();
        EDocumentPurchaseLine."[BC] Item Reference No." := '';
        EDocumentPurchaseLine.Modify();

        // [WHEN] The processing is completed to finish draft step
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
        EDocument.Get(EDocument."Entry No");

        // [WHEN] The final purchase record is retrieved
        EDocumentProcessing.GetRecord(EDocument, VariantRecord);
        DataTypeManagement.GetRecordRef(VariantRecord, RecRef);
        RecRef.SetTable(PurchaseHeader);

        // [THEN] The purchase header contains both imported XRechnung data and manual updates
        XRechnungStructuredValidations.SetMockCurrencyCode(MockCurrencyCode);
        XRechnungStructuredValidations.SetMockDate(MockDate);
        XRechnungStructuredValidations.AssertPurchaseDocument(Vendor."No.", PurchaseHeader, Item);
    end;

    [Test]
    procedure TestXRechnungUnsupportedRootElement_IsRejected()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        StructuredFormatReader: Interface IStructuredFormatReader;
        XmlOutStream: OutStream;
    begin
        // [FEATURE] [E-Document] [XRechnung] [Import]
        // [SCENARIO] An unsupported XRechnung document type is rejected instead of creating an empty draft
        Initialize(Enum::"Service Integration"::"No Integration");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        TempBlob.CreateOutStream(XmlOutStream, TextEncoding::UTF8);
        XmlOutStream.WriteText('<Reminder xmlns="urn:oasis:names:specification:ubl:schema:xsd:Reminder-2" />');
        StructuredFormatReader := Enum::"E-Doc. Read into Draft"::XRechnung;

        asserterror StructuredFormatReader.ReadIntoDraft(EDocument, TempBlob);

        Assert.ExpectedError(StrSubstNo(UnsupportedXmlRootElementErr, 'Reminder'));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure TestXRechnungUnexpectedRootNamespace_IsRejected()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        StructuredFormatReader: Interface IStructuredFormatReader;
        XmlOutStream: OutStream;
    begin
        // [FEATURE] [E-Document] [XRechnung] [Import]
        // [SCENARIO] An Invoice from an unsupported namespace is rejected instead of creating an empty draft
        Initialize(Enum::"Service Integration"::"No Integration");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        TempBlob.CreateOutStream(XmlOutStream, TextEncoding::UTF8);
        XmlOutStream.WriteText('<Invoice xmlns="urn:unsupported:invoice" />');
        StructuredFormatReader := Enum::"E-Doc. Read into Draft"::XRechnung;

        asserterror StructuredFormatReader.ReadIntoDraft(EDocument, TempBlob);

        Assert.ExpectedError(StrSubstNo(UnsupportedXmlRootElementErr, 'Invoice'));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure TestXRechnungInvoice_ReadIntoDraftTwice_DoesNotDuplicateLines()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        LineCountAfterFirstRead: Integer;
    begin
        // [FEATURE] [E-Document] [XRechnung] [Import]
        // [SCENARIO] Re-running Read into Draft resets the previous draft instead of appending duplicate lines

        // [GIVEN] A valid XRechnung XML invoice document is read into a draft
        Initialize(Enum::"Service Integration"::"No Integration");
        SetupXRechnungEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, TestFileTok);
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft");

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        LineCountAfterFirstRead := EDocumentPurchaseLine.Count();
        Assert.IsTrue(LineCountAfterFirstRead > 0, 'The first read into draft should create purchase lines.');

        // [WHEN] The document is read into a draft a second time
        EDocument.Get(EDocument."Entry No");
        ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft");

        // [THEN] The draft contains the same number of lines
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(LineCountAfterFirstRead, EDocumentPurchaseLine.Count(), 'Re-reading the draft should not duplicate purchase lines.');
    end;

    [PageHandler]
    procedure EDocumentPurchaseHeaderPageHandler(var EDocReadablePurchaseDoc: TestPage "E-Doc. Readable Purchase Doc.")
    begin
        EDocReadablePurchaseDoc.Close();
    end;
    #endregion

    local procedure Initialize(Integration: Enum "Service Integration")
    var
        TransformationRule: Record "Transformation Rule";
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
        LibraryVariableStorage.Clear();
        Clear(LibraryVariableStorage);

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
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::XRechnung;
        EDocumentService.Modify();
        EDocumentsSetup.InsertNewExperienceSetup();

        // Set a currency that can be used across all localizations
        MockCurrencyCode := 'XYZ';
        Currency.Init();
        Currency.Validate(Code, MockCurrencyCode);
        if Currency.Insert(true) then;
        CreateCurrencyExchangeRate();

        MockDate := DMY2Date(22, 01, 2026);

        TransformationRule.DeleteAll(false);
        TransformationRule.CreateDefaultTransformations();

        IsInitialized := true;
    end;

    local procedure SetupXRechnungEDocumentService()
    begin
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::XRechnung;
        EDocumentService.Modify(false);
    end;

    local procedure AddSupplierFCTaxScheme(var XmlContent: Text; VATRegistrationNo: Text; RegistrationNo: Text)
    var
        CompanyIDToken: Text;
        CompanyIDPosition: Integer;
        PartyTaxSchemeEndPosition: Integer;
        FiscalCodeTaxScheme: Text;
        PartyTaxSchemeEndTok: Label '</cac:PartyTaxScheme>', Locked = true;
        FiscalCodeTaxSchemeTok: Label '<cac:PartyTaxScheme><cbc:CompanyID>%1</cbc:CompanyID><cac:TaxScheme><cbc:ID>FC</cbc:ID></cac:TaxScheme></cac:PartyTaxScheme>', Locked = true;
    begin
        CompanyIDToken := StrSubstNo(CompanyIDFormatTok, VATRegistrationNo);
        CompanyIDPosition := StrPos(XmlContent, CompanyIDToken);
        Assert.IsTrue(CompanyIDPosition > 0, 'The supplier company identifier was not found in the test XML.');

        PartyTaxSchemeEndPosition := StrPos(CopyStr(XmlContent, CompanyIDPosition), PartyTaxSchemeEndTok);
        Assert.IsTrue(PartyTaxSchemeEndPosition > 0, 'The supplier party tax scheme end was not found in the test XML.');

        PartyTaxSchemeEndPosition += CompanyIDPosition + StrLen(PartyTaxSchemeEndTok) - 1;
        FiscalCodeTaxScheme := StrSubstNo(FiscalCodeTaxSchemeTok, RegistrationNo);
        XmlContent := InsStr(XmlContent, FiscalCodeTaxScheme, PartyTaxSchemeEndPosition);
    end;

    local procedure CreateInboundEDocumentFromXML(var EDocument: Record "E-Document"; FilePath: Text)
    begin
        CreateInboundEDocumentFromXMLText(EDocument, NavApp.GetResourceAsText(FilePath));
    end;

    local procedure CreateInboundEDocumentFromXMLText(var EDocument: Record "E-Document"; XmlContent: Text)
    var
        EDocLogRecord: Record "E-Document Log";
        EDocumentLog: Codeunit "E-Document Log";
    begin
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::XML, XmlContent);
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

        // Update the exit condition to handle different processing steps
        case ProcessingStep of
            "Import E-Document Steps"::"Read into Draft":
                exit(EDocument."Import Processing Status" = Enum::"Import E-Doc. Proc. Status"::"Ready for draft");
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
