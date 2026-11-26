// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Integration.Graph;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.TestLibraries.Utilities;

codeunit 149551 "Filename API Tests"
{
    // [FEATURE] [Report Filename Manager] [API PDF Naming]
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AnApiPdfIsNamedByThePatternOfTheDocumentItRenders()
    var
        Invoice: Record "Sales Invoice Header";
        DraftInvoice: Record "Sales Header";
        Quote: Record "Sales Header";
        Pattern: Record "Report Filename Pattern";
        SalesPattern: Record "Report Filename Pattern";
        SalesInvoicePDFDocHandler: Codeunit "Sales Invoice PDF Doc.Handler";
        SalesQuotePDFDocHandler: Codeunit "Sales Quote PDF Doc.Handler";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] API PDFs use the rendered document, not another document type with the same number.
        // [GIVEN] Invoice and quote patterns and deliberately overlapping sales document numbers.
        Prepare();
        CustomerNo := TestData.CreateCustomer();
        TestData.PostNewInvoice(CustomerNo, Invoice);
        TestData.CreateSalesDocument(DraftInvoice."Document Type"::Invoice, CustomerNo, DraftInvoice);
        TestData.InsertSalesHeaderUnderNo(DraftInvoice."Document Type"::Order, DraftInvoice."No.", CustomerNo);
        TestData.CreateSalesDocument(Quote."Document Type"::Quote, CustomerNo, Quote);
        TestData.InsertSalesHeaderUnderNo(Quote."Document Type"::"Blanket Order", Quote."No.", CustomerNo);
        TestData.InsertSalesHeaderUnderNo(Quote."Document Type"::"Return Order", Quote."No.", CustomerNo);
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", InvoiceNoPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        SalesPattern.Validate("Table No.", Database::"Sales Header");
        SalesPattern.Validate("File Name Pattern", DocTypeNoPatternTok);
        SalesPattern.Enabled := true;
        SalesPattern.Insert(true);

        // [WHEN] The API handlers render each document.
        // [THEN] Each PDF has the filename for its own document type and number.
        AssertApiPdfName(SalesInvoicePDFDocHandler, Invoice.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Invoice", InvoicePrefixTok + Invoice."No." + PdfTok);
        AssertApiPdfName(SalesInvoicePDFDocHandler, DraftInvoice.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Invoice", InvoicePrefixTok + DraftInvoice."No." + PdfTok);
        AssertApiPdfName(SalesQuotePDFDocHandler, Quote.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Quote", QuotePrefixTok + Quote."No." + PdfTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ALegacyApiPdfKeepsItsServerFileAndUsesTheDefaultName()
    var
        Invoice: Record "Sales Invoice Header";
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        PdfDocumentManagement: Codeunit "PDF Document Management";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        ExpectedName: Text;
    begin
        // [SCENARIO] Legacy API rendering retains the server PDF while applying the default delivery name.
        // [GIVEN] A posted invoice and enabled default filename rules.
        Prepare();
        TestData.PostNewInvoice(Invoice);
        ReportFilenameDefaults.InitializeSetup(true);
        ExpectedName := ReportFilenameMgt.Sanitise(
            ReportDistributionManagement.GetFullDocumentTypeText(Invoice) + '-' + Invoice."No.") + PdfTok;

        // [WHEN] The legacy API renders and reopens its intermediate server PDF.
        Assert.IsTrue(
            PdfDocumentManagement.GeneratePdf(Invoice.SystemId, TempAttachmentEntityBuffer),
            'The legacy API must be able to read its rendered server PDF.');

        // [THEN] The returned PDF has content and the patterned delivery name.
        TempAttachmentEntityBuffer.CalcFields(Content);
        Assert.IsTrue(TempAttachmentEntityBuffer.Content.HasValue(), 'The legacy API must return the PDF content.');
        Assert.AreEqual(ExpectedName, TempAttachmentEntityBuffer."File Name", 'The delivery name must still follow the default pattern.');
    end;

    local procedure Prepare()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        TestData.Initialize();
        TestData.SetupDocumentReports();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());
        FilenameProofGuard.ClearPatterns();
    end;

    local procedure AssertApiPdfName(PdfDocumentHandler: Interface IPdfDocumentHandler; DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; Expected: Text)
    var
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
    begin
        if not PdfDocumentHandler.GeneratePdfBlobWithDocumentType(DocumentId, DocumentType, TempAttachmentEntityBuffer) then
            Error(NoApiPdfErr, Expected);
        if TempAttachmentEntityBuffer."File Name" <> Expected then
            Error(ApiPdfNotNamedErr, Expected, TempAttachmentEntityBuffer."File Name");
    end;

    var
        Assert: Codeunit "Library Assert";
        TestData: Codeunit "Filename Test Data";
        InvoiceNoPatternTok: Label 'Invoice-[No.]', Locked = true;
        DocTypeNoPatternTok: Label '[Document Type]-[No.]', Locked = true;
        InvoicePrefixTok: Label 'Invoice-', Locked = true;
        QuotePrefixTok: Label 'Quote-', Locked = true;
        PdfTok: Label '.pdf', Locked = true;
        NoApiPdfErr: Label 'The PDF document handler produced no PDF for the document that should be named "%1".', Comment = '%1 the expected name';
        ApiPdfNotNamedErr: Label 'The API''s PDF should be named "%1" but is "%2".', Comment = '%1 expected, %2 actual';
}
