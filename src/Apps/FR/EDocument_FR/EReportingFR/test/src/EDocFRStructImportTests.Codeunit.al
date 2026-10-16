// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Utilities;

codeunit 148149 "E-Doc. FR Struct. Import Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        FacturXInvoiceTok: Label 'facturx/facturx-invoice-0.xml', Locked = true;
        FacturXCreditMemoTok: Label 'facturx/facturx-creditmemo-0.xml', Locked = true;
        PeppolBIS30FRInvoiceTok: Label 'peppolfr/peppol-bis-fr-invoice-0.xml', Locked = true;
        UnsupportedXmlTok: Label '<?xml version="1.0" encoding="UTF-8"?><SomethingElse xmlns="urn:test" />', Locked = true;

    #region Factur-X
    [Test]
    procedure FacturXInvoiceIsReadIntoDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentFacturXHandler: Codeunit "E-Document Factur-X Handler";
        ProcessDraft: Enum "E-Doc. Process Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Factur-X invoice is read into a purchase invoice draft
        Initialize();

        // [GIVEN] A Factur-X CII invoice
        CreateEDocument(EDocument);

        // [WHEN] The document is read into draft
        ProcessDraft := EDocumentFacturXHandler.ReadIntoDraft(EDocument, GetResourceBlob(FacturXInvoiceTok));

        // [THEN] The draft is prepared as a purchase invoice
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Invoice"), Format(ProcessDraft), 'The draft should be processed as a purchase invoice.');

        // [THEN] The header data is extracted from the Cross Industry Invoice
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('FX-INV-3001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('CMD-2024-9', EDocumentPurchaseHeader."Purchase Order No.", 'Wrong purchase order number.');
        Assert.AreEqual('Fournisseur SARL', EDocumentPurchaseHeader."Vendor Company Name", 'Wrong vendor name.');
        Assert.AreEqual('12 Rue de la Paix', EDocumentPurchaseHeader."Vendor Address", 'Wrong vendor address.');
        Assert.AreEqual('FR12345678901', EDocumentPurchaseHeader."Vendor VAT Id", 'Wrong vendor VAT registration number.');
        Assert.AreEqual('Acheteur SA', EDocumentPurchaseHeader."Customer Company Name", 'Wrong customer name.');
        Assert.AreEqual(20240301D, EDocumentPurchaseHeader."Document Date", 'Wrong document date.');
        Assert.AreEqual(20240331D, EDocumentPurchaseHeader."Due Date", 'Wrong due date.');
        Assert.AreEqual(360, EDocumentPurchaseHeader."Sub Total", 'Wrong sub total.');
        Assert.AreEqual(72, EDocumentPurchaseHeader."Total VAT", 'Wrong total VAT.');
        Assert.AreEqual(432, EDocumentPurchaseHeader.Total, 'Wrong total.');
        Assert.AreEqual(432, EDocumentPurchaseHeader."Amount Due", 'Wrong amount due.');

        // [THEN] The line data is extracted from the Cross Industry Invoice
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, EDocumentPurchaseLine.Count(), 'Wrong number of draft lines.');
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('Chaise de bureau', EDocumentPurchaseLine.Description, 'Wrong line description.');
        Assert.AreEqual('ART-500', EDocumentPurchaseLine."Product Code", 'Wrong product code.');
        Assert.AreEqual(3, EDocumentPurchaseLine.Quantity, 'Wrong quantity.');
        Assert.AreEqual('H87', EDocumentPurchaseLine."Unit of Measure", 'Wrong unit of measure.');
        Assert.AreEqual(120, EDocumentPurchaseLine."Unit Price", 'Wrong unit price.');
        Assert.AreEqual(360, EDocumentPurchaseLine."Sub Total", 'Wrong line sub total.');
        Assert.AreEqual(20, EDocumentPurchaseLine."VAT Rate", 'Wrong VAT rate.');
    end;

    [Test]
    procedure FacturXCreditMemoIsReadIntoDraft()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentFacturXHandler: Codeunit "E-Document Factur-X Handler";
        ProcessDraft: Enum "E-Doc. Process Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Factur-X credit memo is read into a purchase credit memo draft
        Initialize();

        // [GIVEN] A Factur-X CII credit memo
        CreateEDocument(EDocument);

        // [WHEN] The document is read into draft
        ProcessDraft := EDocumentFacturXHandler.ReadIntoDraft(EDocument, GetResourceBlob(FacturXCreditMemoTok));

        // [THEN] The draft is prepared as a purchase credit memo referring to the original invoice
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Credit Memo"), Format(ProcessDraft), 'The draft should be processed as a purchase credit memo.');
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('FX-AVR-4001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('FX-INV-3001', EDocumentPurchaseHeader."Vendor Invoice No.", 'Wrong applies-to external invoice number.');
    end;

    [Test]
    procedure FacturXUnsupportedRootElementFails()
    var
        EDocument: Record "E-Document";
        EDocumentFacturXHandler: Codeunit "E-Document Factur-X Handler";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Reading a document that is not a Cross Industry Invoice fails with a clear error
        Initialize();

        // [GIVEN] An XML document with an unsupported root element
        CreateEDocument(EDocument);

        // [WHEN] The document is read into draft
        asserterror EDocumentFacturXHandler.ReadIntoDraft(EDocument, CreateBlob(UnsupportedXmlTok));

        // [THEN] The reader rejects the document
        Assert.ExpectedError('Unsupported XML root element');
    end;

    [Test]
    procedure FacturXInvoiceCanBeReadIntoDraftTwice()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentFacturXHandler: Codeunit "E-Document Factur-X Handler";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Re-running Read into Draft replaces the previous draft instead of duplicating it
        Initialize();

        // [GIVEN] A Factur-X invoice that has been read into draft
        CreateEDocument(EDocument);
        EDocumentFacturXHandler.ReadIntoDraft(EDocument, GetResourceBlob(FacturXInvoiceTok));

        // [WHEN] The document is read into draft again
        EDocumentFacturXHandler.ReadIntoDraft(EDocument, GetResourceBlob(FacturXInvoiceTok));

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
        EDocPeppolBIS30FRHandler: Codeunit "E-Doc. Peppol BIS 3.0 FR Hdlr";
        ProcessDraft: Enum "E-Doc. Process Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Peppol BIS 3.0 FR invoice is read into a purchase invoice draft
        Initialize();

        // [GIVEN] A Peppol BIS 3.0 FR UBL invoice
        CreateEDocument(EDocument);

        // [WHEN] The document is read into draft
        ProcessDraft := EDocPeppolBIS30FRHandler.ReadIntoDraft(EDocument, GetResourceBlob(PeppolBIS30FRInvoiceTok));

        // [THEN] The draft is prepared as a purchase invoice
        Assert.AreEqual(Format("E-Doc. Process Draft"::"Purchase Invoice"), Format(ProcessDraft), 'The draft should be processed as a purchase invoice.');

        // [THEN] The header data, including the French party identification, is extracted
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        Assert.AreEqual('PBIS-FR-6001', EDocumentPurchaseHeader."Sales Invoice No.", 'Wrong document number.');
        Assert.AreEqual('CMD-2026-4', EDocumentPurchaseHeader."Purchase Order No.", 'Wrong purchase order number.');
        Assert.AreEqual('Fournisseur SARL', EDocumentPurchaseHeader."Vendor Company Name", 'Wrong vendor name.');
        Assert.AreEqual('FR12345678901', EDocumentPurchaseHeader."Vendor VAT Id", 'Wrong vendor VAT registration number.');
        Assert.AreEqual('12345678901234', EDocumentPurchaseHeader."Vendor External Id", 'The French SIRET should be mapped from PartyIdentification.');
        Assert.AreEqual('Acheteur SA', EDocumentPurchaseHeader."Customer Company Name", 'Wrong customer name.');
        Assert.AreEqual('98765432109876', EDocumentPurchaseHeader."Customer Company Id", 'The French SIRET should be mapped from PartyIdentification.');
        Assert.AreEqual(360, EDocumentPurchaseHeader."Sub Total", 'Wrong sub total.');
        Assert.AreEqual(432, EDocumentPurchaseHeader.Total, 'Wrong total.');
        Assert.AreEqual(72, EDocumentPurchaseHeader."Total VAT", 'Wrong total VAT.');

        // [THEN] The line data is extracted
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
    procedure PeppolBIS30FRUnsupportedRootElementFails()
    var
        EDocument: Record "E-Document";
        EDocPeppolBIS30FRHandler: Codeunit "E-Doc. Peppol BIS 3.0 FR Hdlr";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Reading a document that is neither an Invoice nor a CreditNote fails with a clear error
        Initialize();

        // [GIVEN] An XML document with an unsupported root element
        CreateEDocument(EDocument);

        // [WHEN] The document is read into draft
        asserterror EDocPeppolBIS30FRHandler.ReadIntoDraft(EDocument, CreateBlob(UnsupportedXmlTok));

        // [THEN] The reader rejects the document
        Assert.ExpectedError('Unsupported XML root element');
    end;
    #endregion

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        EDocumentPurchaseLine.DeleteAll(false);
        EDocumentPurchaseHeader.DeleteAll(false);
        EDocument.DeleteAll(false);
    end;

    local procedure CreateEDocument(var EDocument: Record "E-Document")
    begin
        Clear(EDocument);
        EDocument.Direction := EDocument.Direction::Incoming;
        EDocument.Insert(true);
    end;

    local procedure GetResourceBlob(FilePath: Text): Codeunit "Temp Blob"
    begin
        exit(CreateBlob(NavApp.GetResourceAsText(FilePath, TextEncoding::UTF8)));
    end;

    local procedure CreateBlob(Content: Text) TempBlob: Codeunit "Temp Blob"
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);
    end;
}
