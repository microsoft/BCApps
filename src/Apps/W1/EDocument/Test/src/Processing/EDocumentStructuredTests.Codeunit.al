// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Format;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.TestLibraries.Config;
using System.TestLibraries.Utilities;

codeunit 139891 "E-Document Structured Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Vendor: Record Vendor;
        Assert: Codeunit Assert;
        EDocImplState: Codeunit "E-Doc. Impl. State";
        StructuredValidations: Codeunit "EDoc Structured Validations";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        EDocumentStatusNotUpdatedErr: Label 'The status of the EDocument was not updated to the expected status after the step was executed.';

    #region CAPI JSON
    [Test]
    procedure TestCAPIInvoice_ValidDocument()
    var
        EDocument: Record "E-Document";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        SetupCAPIEDocumentService();
        CreateInboundEDocumentFromJSON(EDocument, 'capi/capi-invoice-valid-0.json');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertFullCAPIDocumentExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestCAPIInvoice_UnexpectedFieldValues()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        SetupCAPIEDocumentService();
        CreateInboundEDocumentFromJSON(EDocument, 'capi/capi-invoice-unexpected-values-0.json');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then begin
            StructuredValidations.AssertMinimalCAPIDocumentParsed(EDocument."Entry No");
            EDocumentPurchaseHeader.Get(EDocument."Entry No");
            // "value_text": null
            Assert.AreEqual('', EDocumentPurchaseHeader."Shipping Address", 'Text field should be empty when JSON value is null');
            // "value_text": 1
            Assert.AreEqual('1', EDocumentPurchaseHeader."Shipping Address Recipient", 'Text field should convert non-text JSON values to their string representation');

            // "value_number": null
            Assert.AreEqual(0, EDocumentPurchaseHeader."Sub Total", 'Number field should be 0 when JSON value is null');
            // "value_number": "10"
            Assert.AreEqual(10, EDocumentPurchaseHeader."Total VAT", 'Number field should parse numeric string values');
            // "value_number": "abc"
            Assert.AreEqual(0, EDocumentPurchaseHeader."Amount Due", 'Number field should be 0 when JSON value is not a valid numeric value');

            // "value_date": null
            Assert.AreEqual(0D, EDocumentPurchaseHeader."Service Start Date", 'Date field should be empty when JSON value is null');
            // "value_date": "aaa"
            Assert.AreEqual(0D, EDocumentPurchaseHeader."Service End Date", 'Date field should be empty when JSON value is not a valid date value');
        end
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;
    #endregion

    #region PEPPOL 3.0 XML
    [Test]
    procedure TestPEPPOLInvoice_ValidDocument()
    var
        EDocument: Record "E-Document";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-0.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertFullPEPPOLDocumentExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;
    [Test]
    procedure TestPEPPOLCreditNote_ValidDocument()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] A valid PEPPOL CreditNote XML is parsed into the staging tables with correct header, lines, and BillingReference
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-creditnote-0.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then begin
            StructuredValidations.AssertFullPEPPOLCreditNoteExtracted(EDocument."Entry No");
            EDocument.Get(EDocument."Entry No");
            Assert.AreEqual(Enum::"E-Doc. Process Draft"::"Purchase Credit Memo", EDocument."Process Draft Impl.", 'The process draft implementation should be set to Purchase Credit Memo for credit notes.');
        end
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_ReturnsInvoiceProcessDraftImpl()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] After parsing a PEPPOL Invoice, the Process Draft Impl. is set to "Purchase Invoice" (not the obsoleted "Purchase Document")
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-0.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then begin
            EDocument.Get(EDocument."Entry No");
            Assert.AreEqual(Enum::"E-Doc. Process Draft"::"Purchase Invoice", EDocument."Process Draft Impl.", 'The process draft implementation should be set to Purchase Invoice for invoices.');
        end
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_BaseExample()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] A basic PEPPOL invoice with 2 lines and a document-level charge is parsed correctly.
        // Covers: vendor GLN (schemeID=0088), customer non-0088 endpoint (no GLN), charge line creation.
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-basic.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertPEPPOLBaseExampleExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_WithCharges()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Document-level charges (ChargeIndicator=true) create purchase lines; allowances (ChargeIndicator=false) do not.
        // Covers: completeness item "Document-level AllowanceCharge lines not created"
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-charges.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertPEPPOLInvoiceWithChargesExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_VatCategoryS()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Invoice with multiple VAT rates (25% and 15%), StandardItemIdentification priority over SellersItemIdentification.
        // Covers: completeness item "SellersItemIdentification vs StandardItemIdentification merged"
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-vat-category-s.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertPEPPOLVatCategorySExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_VatCategoryZ()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Invoice with zero-rated VAT (category Z), no DueDate, GBP currency.
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-vat-category-z.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertPEPPOLVatCategoryZExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_AllowanceExample()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Full PEPPOL example with both charge and allowance at document level, SellersItemIdentification only, 3 invoice lines.
        // Covers: allowance does NOT create line, charge DOES, SellersItemIdentification as product code fallback.
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-allowance.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertPEPPOLAllowanceExampleExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLCreditNote_CorrectionNoDueDate()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] CreditNote without PaymentMeans/PaymentDueDate results in blank Due Date.
        // Covers: completeness item "CreditNote DueDate uses wrong XPath" (negative case - no DueDate at all)
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-creditnote-no-duedate.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then begin
            StructuredValidations.AssertPEPPOLCreditNoteCorrectionExtracted(EDocument."Entry No");
            EDocument.Get(EDocument."Entry No");
            Assert.AreEqual(Enum::"E-Doc. Process Draft"::"Purchase Credit Memo", EDocument."Process Draft Impl.", 'The process draft implementation should be set to Purchase Credit Memo for credit notes.');
        end
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_EmbeddedAttachments()
    var
        EDocument: Record "E-Document";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] Embedded base64 attachments are extracted; external URI and bare references are skipped.
        // Test XML: 1 valid PDF, 1 valid PNG, 1 external URI (no embedded content), 1 bare reference (no attachment node).
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-attachment.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then begin
            StructuredValidations.AssertPEPPOLAttachmentHeaderExtracted(EDocument."Entry No");
            // Verify exactly 2 attachments were created (embedded PDF + embedded PNG); external URI and bare ref skipped
            DocumentAttachment.SetRange("E-Document Entry No.", EDocument."Entry No");
            Assert.AreEqual(2, DocumentAttachment.Count(), 'Expected 2 embedded attachments (PDF + PNG). External URI and bare references should be skipped.');
        end
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_DescriptionFallback()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] When Item/Name is absent, Description is used as fallback. When both exist, Name takes priority.
        // Covers: completeness item "Description cascade vs separate fields"
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-description-fallback.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertPEPPOLDescriptionFallbackExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_PayeePartyOverride()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] When PayeeParty is present, it overrides vendor company name and VAT ID from AccountingSupplierParty.
        // Covers: completeness item "PayeeParty/PartyIdentification fallback missing"
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-payee-party.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertPEPPOLPayeePartyOverrideExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;
    #endregion

    #region MLLM JSON
    [Test]
    procedure TestMLLMInvoice_ValidDocument()
    var
        EDocument: Record "E-Document";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        SetupMLLMEDocumentService();
        CreateInboundEDocumentFromJSON(EDocument, 'mllm/mllm-invoice-valid-0.json');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertFullMLLMDocumentExtracted(EDocument."Entry No")
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;
    #endregion

    #region Experiment Configuration
    [Test]
    procedure TestExperiment_ControlAllocation_PreferredImplIsADI()
    var
        EDocPDFFileFormat: Codeunit "E-Doc. PDF File Format";
        FeatureConfigTestLib: Codeunit "Feature Config Test Lib.";
    begin
        // [SCENARIO] With control allocation, the PDF file format returns ADI as the preferred implementation
        LibraryLowerPermission.SetOutsideO365Scope();

        FeatureConfigTestLib.UseControlAllocation();

        Assert.AreEqual(
            "Structure Received E-Doc."::ADI,
            EDocPDFFileFormat.PreferredStructureDataImplementation(),
            'Control allocation should prefer ADI for PDF processing');
    end;

    // Todo: Reenable once #624677 is fixed
    // [Test]
    // procedure TestExperiment_TreatmentAllocation_PreferredImplIsMLLM()
    // var
    //     EDocPDFFileFormat: Codeunit "E-Doc. PDF File Format";
    //     FeatureConfigTestLib: Codeunit "Feature Config Test Lib.";
    // begin
    //     // [SCENARIO] With treatment allocation, the PDF file format returns MLLM as the preferred implementation
    //     LibraryLowerPermission.SetOutsideO365Scope();

    //     FeatureConfigTestLib.UseTreatmentAllocation();

    //     Assert.AreEqual(
    //         "Structure Received E-Doc."::MLLM,
    //         EDocPDFFileFormat.PreferredStructureDataImplementation(),
    //         'Treatment allocation should prefer MLLM for PDF processing');
    // end;

    // Todo: Reenable once #624677 is fixed
    // [Test]
    // procedure TestExperiment_TreatmentAllocation_MLLMProcessesValidDocument()
    // var
    //     EDocument: Record "E-Document";
    //     FeatureConfigTestLib: Codeunit "Feature Config Test Lib.";
    // begin
    //     // [SCENARIO] With treatment allocation active, MLLM is used to process a valid UBL invoice E2E
    //     Initialize(Enum::"Service Integration"::"Mock");
    //     SetupMLLMEDocumentService();

    //     FeatureConfigTestLib.UseTreatmentAllocation();

    //     CreateInboundEDocumentFromJSON(EDocument, 'mllm/mllm-invoice-valid-0.json');
    //     if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
    //         StructuredValidations.AssertFullMLLMDocumentExtracted(EDocument."Entry No")
    //     else
    //         Assert.Fail(EDocumentStatusNotUpdatedErr);
    // end;
    #endregion

    #region Fallback
    [Test]
    procedure TestMLLM_InvalidJson_ProducesEmptyDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        // [SCENARIO] When MLLM produces invalid/empty JSON, ReadIntoDraft creates a minimal draft without error
        Initialize(Enum::"Service Integration"::"Mock");
        SetupMLLMEDocumentService();
        CreateInboundEDocumentFromJSON(EDocument, 'mllm/mllm-invoice-empty.json');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then begin
            EDocumentPurchaseHeader.Get(EDocument."Entry No");
            Assert.AreEqual('', EDocumentPurchaseHeader."Sales Invoice No.", 'Empty JSON should produce empty header fields');
            Assert.AreEqual(0, EDocumentPurchaseHeader.Total, 'Empty JSON should produce zero totals');
        end
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;

    [Test]
    procedure TestPEPPOLInvoice_NamespacePrefixedRootElement()
    var
        EDocument: Record "E-Document";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        SetupPEPPOLEDocumentService();
        CreateInboundEDocumentFromXML(EDocument, 'peppol/peppol-invoice-prefixed-ns.xml');
        if ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft") then
            StructuredValidations.AssertFullPEPPOLDocumentExtracted(EDocument."Entry No")            
        else
            Assert.Fail(EDocumentStatusNotUpdatedErr);
    end;
    #endregion

    local procedure Initialize(Integration: Enum "Service Integration")
    var
        Currency: Record Currency;
        DocumentAttachment: Record "Document Attachment";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentServiceStatus: Record "E-Document Service Status";
        TransformationRule: Record "Transformation Rule";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();
        Clear(EDocImplState);
        Clear(LibraryVariableStorage);

        if IsInitialized then
            exit;

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        EDocDataStorage.DeleteAll();
        EDocumentPurchaseHeader.DeleteAll();
        EDocumentPurchaseLine.DeleteAll();
        DocumentAttachment.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::"PDF Mock";
        EDocumentService.Modify();

        // Set a currency that can be used across all localizations
        Currency.Init();
        Currency.Validate(Code, 'XYZ');
        if Currency.Insert(true) then;

        TransformationRule.DeleteAll();
        TransformationRule.CreateDefaultTransformations();

        IsInitialized := true;
    end;

    local procedure SetupCAPIEDocumentService()
    begin
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::ADI;
        EDocumentService.Modify();
    end;

    local procedure SetupPEPPOLEDocumentService()
    begin
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();
    end;

    local procedure SetupMLLMEDocumentService()
    begin
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::MLLM;
        EDocumentService.Modify();
    end;

    local procedure CreateInboundEDocumentFromJSON(var EDocument: Record "E-Document"; FilePath: Text)
    var
        EDocLogRecord: Record "E-Document Log";
        EDocumentLog: Codeunit "E-Document Log";
    begin
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::JSON, NavApp.GetResourceAsText(FilePath));
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Readable);

        EDocument."Structured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();
    end;

    local procedure CreateInboundEDocumentFromXML(var EDocument: Record "E-Document"; FilePath: Text)
    var
        EDocLogRecord: Record "E-Document Log";
        EDocumentLog: Codeunit "E-Document Log";
    begin
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::XML, NavApp.GetResourceAsText(FilePath));
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Readable);

        EDocument."Structured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();
    end;

    local procedure ProcessEDocumentToStep(var EDocument: Record "E-Document"; ProcessingStep: Enum "Import E-Document Steps"): Boolean
    var
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Readable);
        TempEDocImportParameters."Step to Run" := ProcessingStep;
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);
        EDocument.CalcFields("Import Processing Status");
        exit(EDocument."Import Processing Status" = Enum::"Import E-Doc. Proc. Status"::"Ready for draft");
    end;
}
