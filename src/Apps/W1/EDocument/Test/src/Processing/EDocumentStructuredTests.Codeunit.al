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
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryEDoc: Codeunit "Library - E-Document";
        EDocImplState: Codeunit "E-Doc. Impl. State";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        StructuredValidations: Codeunit "EDoc Structured Validations";
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
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Readable);
        EDocImportParameters."Step to Run" := ProcessingStep;
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
        EDocument.CalcFields("Import Processing Status");
        exit(EDocument."Import Processing Status" = Enum::"Import E-Doc. Proc. Status"::"Ready for draft");
    end;
}
