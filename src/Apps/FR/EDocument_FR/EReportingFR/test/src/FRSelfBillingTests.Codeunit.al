// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.Bank.BankAccount;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Utilities;

codeunit 148152 "FR Self-Billing Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    Permissions = tabledata "Service Participant" = rimd,
                  tabledata "E-Doc. Service Supported Type" = rimd,
                  tabledata "Company Information" = m,
                  tabledata "Report Selections" = rimd;

    var
        EDocumentService: Record "E-Document Service";
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        VendorBankAccount: Record "Vendor Bank Account";
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        EDocHelpers: Codeunit "EDoc. Helpers";
        IsInitialized: Boolean;

    [Test]
    procedure PostingSelfBillingInvoiceCreatesPeppolFR()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Posting self-billing invoice "PI" creates outgoing Peppol FR with vendor "V" as seller.
        Initialize();

        // [GIVEN] Vendor "V" has a French service and distinct company and vendor routing addresses.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");

        // [WHEN] Purchase invoice "PI" is posted.
        PostInvoice(PurchInvHeader);

        // [THEN] The workflow exports invoice 389 with the posted financial values and correct parties.
        GetExportedDocument(PurchInvHeader, EDocument, TempBlob);
        ReadXml(TempBlob, XmlDoc);
        VerifyPeppolInvoice(XmlDoc, PurchInvHeader);
    end;

    [Test]
    procedure PostingSelfBillingInvoiceCreatesFacturXFR()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        PDFBlob: Codeunit "Temp Blob";
        XMLBlob: Codeunit "Temp Blob";
        PDFDocument: Codeunit "PDF Document";
        PDFInStream: InStream;
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Posting self-billing invoice "PI" creates a PDF containing the French CII invoice 389.
        Initialize();

        // [GIVEN] Vendor "V" has a Factur-X service and a beneficiary bank different from the company bank.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");

        // [WHEN] Purchase invoice "PI" is posted.
        PostInvoice(PurchInvHeader);

        // [THEN] The actual exported PDF contains CII XML with the correct invoice, parties and beneficiary.
        GetExportedDocument(PurchInvHeader, EDocument, PDFBlob);
        PDFBlob.CreateInStream(PDFInStream);
        Assert.IsTrue(PDFDocument.GetDocumentAttachmentStream(PDFInStream, XMLBlob), 'The PDF must contain the invoice XML.');
        ReadXml(XMLBlob, XmlDoc);
        VerifyCIIInvoice(XmlDoc, PurchInvHeader);
    end;

    [Test]
    procedure OrdinaryPurchaseDoesNotCreatePeppolSelfBill()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Ordinary purchase invoice "PI" does not become an outgoing Peppol FR self-bill.
        Initialize();

        // [GIVEN] Vendor "V" uses Peppol FR without a self-billing agreement.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");
        DisableSelfBillingAgreement();

        // [WHEN] Purchase invoice "PI" is posted.
        PostInvoice(PurchInvHeader);

        // [THEN] There is no outgoing self-billing E-Document.
        VerifyNoEDocument(PurchInvHeader.RecordId());
    end;

    [Test]
    procedure OrdinaryPurchaseDoesNotCreateFacturXSelfBill()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Ordinary purchase invoice "PI" does not become an outgoing Factur-X FR self-bill.
        Initialize();

        // [GIVEN] Vendor "V" uses Factur-X FR without a self-billing agreement.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        DisableSelfBillingAgreement();

        // [WHEN] Purchase invoice "PI" is posted.
        PostInvoice(PurchInvHeader);

        // [THEN] There is no outgoing self-billing E-Document.
        VerifyNoEDocument(PurchInvHeader.RecordId());
    end;

    [Test]
    procedure ExistingPeppolServiceIsNotEnabledAutomatically()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Revalidating an existing Peppol FR service preserves its customized supported types.
        Initialize();

        // [GIVEN] Service "S" has customized supported document types.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");
        CustomizeSupportedTypes();

        // [WHEN] Its existing format is validated again.
        EDocumentService.Validate("Document Format", EDocumentService."Document Format");

        // [THEN] Existing directions are preserved and self-billing still requires explicit opt-in.
        VerifyCustomizedSupportedTypes();
    end;

    [Test]
    procedure ExistingFacturXServiceIsNotEnabledAutomatically()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Revalidating an existing Factur-X FR service preserves its customized supported types.
        Initialize();

        // [GIVEN] Service "S" has customized supported document types.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        CustomizeSupportedTypes();

        // [WHEN] Its existing format is validated again.
        EDocumentService.Validate("Document Format", EDocumentService."Document Format");

        // [THEN] Existing directions are preserved and self-billing still requires explicit opt-in.
        VerifyCustomizedSupportedTypes();
    end;

    [Test]
    procedure PeppolRejectsInvalidSelfBillingSellerAddress()
    var
        PurchaseHeader: Record "Purchase Header";
        PeppolFormat: Codeunit "Peppol BIS 3.0 FR Format";
        SourceHeader: RecordRef;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Peppol FR rejects a vendor email destination instead of a French self-billing destination.
        Initialize();

        // [GIVEN] Invoice "PI" has an invalid vendor service address.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");
        CreateInvoice(PurchaseHeader);
        SetInvalidSellerAddress();
        SourceHeader.GetTable(PurchaseHeader);

        // [WHEN] Peppol FR validates the invoice.
        asserterror PeppolFormat.Check(SourceHeader, EDocumentService, Enum::"E-Document Processing Phase"::Create);

        // [THEN] An actionable address error is raised.
        Assert.ExpectedError('Specify the vendor electronic address with scheme 0225');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure FacturXRejectsInvalidSelfBillingSellerAddress()
    var
        PurchaseHeader: Record "Purchase Header";
        FacturXFormat: Codeunit "Factur-X Format";
        SourceHeader: RecordRef;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Factur-X FR rejects an invalid vendor self-billing destination.
        Initialize();

        // [GIVEN] Invoice "PI" has an invalid vendor service address.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        CreateInvoice(PurchaseHeader);
        SetInvalidSellerAddress();
        SourceHeader.GetTable(PurchaseHeader);

        // [WHEN] Factur-X FR validates the invoice.
        asserterror FacturXFormat.Check(SourceHeader, EDocumentService, Enum::"E-Document Processing Phase"::Create);

        // [THEN] An actionable address error is raised.
        Assert.ExpectedError('Specify the vendor electronic address with scheme 0225');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure FacturXRejectsOrdinaryPurchaseAsSelfBill()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        EDocument: Record "E-Document";
        FacturXFormat: Codeunit "Factur-X Format";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Setting an E-Document type cannot turn an ordinary posted purchase into a self-bill.
        Initialize();

        // [GIVEN] Ordinary invoice "PI" is presented with a self-billed E-Document type.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        DisableSelfBillingAgreement();
        PostInvoice(PurchInvHeader);
        SourceHeader.GetTable(PurchInvHeader);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        SourceLines.GetTable(PurchInvLine);
        EDocument."Document Type" := EDocument."Document Type"::"Self-Billed Purchase Invoice";

        // [WHEN] Factur-X creates the document.
        asserterror FacturXFormat.Create(EDocumentService, EDocument, SourceHeader, SourceLines, TempBlob);

        // [THEN] The posted self-billing flag is required.
        Assert.ExpectedError(PurchInvHeader.FieldCaption("Self-Billing Invoice"));
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure PeppolRejectsOrdinaryPurchaseAsSelfBill()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        EDocument: Record "E-Document";
        PeppolFormat: Codeunit "Peppol BIS 3.0 FR Format";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Setting an E-Document type cannot turn an ordinary purchase into a Peppol self-bill.
        Initialize();

        // [GIVEN] Ordinary invoice "PI" is presented with a self-billed E-Document type.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");
        DisableSelfBillingAgreement();
        PostInvoice(PurchInvHeader);
        SourceHeader.GetTable(PurchInvHeader);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        SourceLines.GetTable(PurchInvLine);
        EDocument."Document Type" := EDocument."Document Type"::"Self-Billed Purchase Invoice";

        // [WHEN] Peppol FR creates the document.
        asserterror PeppolFormat.Create(EDocumentService, EDocument, SourceHeader, SourceLines, TempBlob);

        // [THEN] The posted self-billing flag is required.
        Assert.ExpectedError(PurchInvHeader.FieldCaption("Self-Billing Invoice"));
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure FacturXReconcilesVATInclusivePurchaseLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        PDFBlob: Codeunit "Temp Blob";
        XMLBlob: Codeunit "Temp Blob";
        PDFDocument: Codeunit "PDF Document";
        PDFInStream: InStream;
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] VAT-inclusive purchase prices produce net CII lines, not an artificial invoice discount.
        Initialize();

        // [GIVEN] Self-billing invoice "PI" has prices including VAT.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        CreateInvoice(PurchaseHeader);
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);

        // [WHEN] Invoice "PI" is posted and the embedded CII XML is extracted.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        GetExportedDocument(PurchInvHeader, EDocument, PDFBlob);
        PDFBlob.CreateInStream(PDFInStream);
        Assert.IsTrue(PDFDocument.GetDocumentAttachmentStream(PDFInStream, XMLBlob), 'The PDF must contain the invoice XML.');
        ReadXml(XMLBlob, XmlDoc);

        // [THEN] Line totals reconcile to the posted net amount without an invented invoice discount.
        VerifyVATInclusiveAmounts(XmlDoc, PurchInvHeader);
    end;

    [Test]
    procedure FacturXRejectsReportWithoutXMLAttachment()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        ReportSelections: Record "Report Selections";
        TempRecordExportBuffer: Record "Record Export Buffer" temporary;
        ExportFacturXDocument: Codeunit "Export Factur-X Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] A selected ordinary purchase report cannot silently produce a plain PDF as Factur-X.
        Initialize();

        // [GIVEN] Posted self-billing invoice "PI" has a selected report without the Factur-X rendering hook.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        PostInvoice(PurchInvHeader);
        ReportSelections.Get(Enum::"Report Selection Usage"::"P.Self Billing Invoice", '1');
        ReportSelections."Report ID" := Report::"Purchase - Invoice";
        ReportSelections.Modify();
        TempRecordExportBuffer.RecordID := PurchInvHeader.RecordId();
        TempRecordExportBuffer.Insert();

        // [WHEN] The selected report is used to export the invoice.
        asserterror ExportFacturXDocument.ExportDocument(TempRecordExportBuffer, EDocumentService.Code);

        // [THEN] Missing XML integration is reported instead of returning a successful plain PDF.
        Assert.ExpectedError('must attach factur-x.xml');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure PostingSelfBillingCreditMemoCreatesPeppolFR()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Credit "PC" applied to self-billing invoice "PI" creates Peppol FR credit 261.
        Initialize();

        // [GIVEN] Invoice "PI" was self-billed, even though vendor "V" no longer has an agreement.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");
        PostInvoice(PurchInvHeader);
        DisableSelfBillingAgreement();

        // [WHEN] Credit "PC" is posted against invoice "PI".
        PostCreditMemo(PurchCrMemoHeader, PurchInvHeader."No.");

        // [THEN] The outgoing credit preserves the parties, reference and posted amounts.
        GetExportedDocument(PurchCrMemoHeader, EDocument, TempBlob);
        ReadXml(TempBlob, XmlDoc);
        VerifyPeppolCreditMemo(XmlDoc, PurchCrMemoHeader, PurchInvHeader);
    end;

    [Test]
    procedure PostingSelfBillingCreditMemoCreatesFacturXFR()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        EDocument: Record "E-Document";
        PDFBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Credit "PC" applied to self-billing invoice "PI" creates a PDF with CII credit 261.
        Initialize();

        // [GIVEN] Invoice "PI" was self-billed, even though vendor "V" no longer has an agreement.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        PostInvoice(PurchInvHeader);
        DisableSelfBillingAgreement();

        // [WHEN] Credit "PC" is posted against invoice "PI".
        PostCreditMemo(PurchCrMemoHeader, PurchInvHeader."No.");

        // [THEN] The actual PDF contains credit XML with the correct parties, reference and totals.
        GetExportedDocument(PurchCrMemoHeader, EDocument, PDFBlob);
        ReadPDFXml(PDFBlob, XmlDoc);
        VerifyCIICreditMemo(XmlDoc, PurchCrMemoHeader, PurchInvHeader);
    end;

    [Test]
    procedure UnappliedCreditDoesNotCreatePeppolSelfBill()
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] An unapplied credit "PC" is not a Peppol self-bill despite the vendor agreement.
        Initialize();

        // [GIVEN] Vendor "V" has a self-billing agreement and Peppol FR.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");

        // [WHEN] Credit "PC" is posted without applying it to an invoice.
        PostCreditMemo(PurchCrMemoHeader, '');

        // [THEN] No self-billing E-Document is created.
        VerifyNoEDocument(PurchCrMemoHeader.RecordId());
    end;

    [Test]
    procedure UnappliedCreditDoesNotCreateFacturXSelfBill()
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] An unapplied credit "PC" is not a Factur-X self-bill despite the vendor agreement.
        Initialize();

        // [GIVEN] Vendor "V" has a self-billing agreement and Factur-X FR.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");

        // [WHEN] Credit "PC" is posted without applying it to an invoice.
        PostCreditMemo(PurchCrMemoHeader, '');

        // [THEN] No self-billing E-Document is created.
        VerifyNoEDocument(PurchCrMemoHeader.RecordId());
    end;

    [Test]
    procedure OrdinaryInvoiceCreditDoesNotCreatePeppolSelfBill()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Applying credit "PC" to ordinary invoice "PI" does not make it a Peppol self-bill.
        Initialize();

        // [GIVEN] Invoice "PI" was posted without self-billing.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");
        DisableSelfBillingAgreement();
        PostInvoice(PurchInvHeader);

        // [WHEN] Credit "PC" is posted against invoice "PI".
        PostCreditMemo(PurchCrMemoHeader, PurchInvHeader."No.");

        // [THEN] No self-billing E-Document is created.
        VerifyNoEDocument(PurchCrMemoHeader.RecordId());
    end;

    [Test]
    procedure OrdinaryInvoiceCreditDoesNotCreateFacturXSelfBill()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Applying credit "PC" to ordinary invoice "PI" does not make it a Factur-X self-bill.
        Initialize();

        // [GIVEN] Invoice "PI" was posted without self-billing.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        DisableSelfBillingAgreement();
        PostInvoice(PurchInvHeader);

        // [WHEN] Credit "PC" is posted against invoice "PI".
        PostCreditMemo(PurchCrMemoHeader, PurchInvHeader."No.");

        // [THEN] No self-billing E-Document is created.
        VerifyNoEDocument(PurchCrMemoHeader.RecordId());
    end;

    [Test]
    procedure PeppolRejectsUnappliedCreditAsSelfBill()
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] A self-billed type cannot make unapplied credit "PC" eligible for Peppol export.
        Initialize();

        // [GIVEN] Credit "PC" has no applied invoice.
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");
        PostCreditMemo(PurchCrMemoHeader, '');

        // [WHEN] Export is requested with the self-billed credit type.
        asserterror CreateSelfBillingCreditMemo(PurchCrMemoHeader);

        // [THEN] The missing original invoice is reported.
        Assert.ExpectedError(PurchCrMemoHeader.FieldCaption("Applies-to Doc. No."));
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure FacturXRejectsUnappliedCreditAsSelfBill()
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] A self-billed type cannot make unapplied credit "PC" eligible for Factur-X export.
        Initialize();

        // [GIVEN] Credit "PC" has no applied invoice.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        PostCreditMemo(PurchCrMemoHeader, '');

        // [WHEN] Export is requested with the self-billed credit type.
        asserterror CreateSelfBillingCreditMemo(PurchCrMemoHeader);

        // [THEN] The missing original invoice is reported.
        Assert.ExpectedError(PurchCrMemoHeader.FieldCaption("Applies-to Doc. No."));
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure PeppolRejectsOrdinaryInvoiceCreditAsSelfBill()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Credit "PC" applied to an ordinary invoice cannot be explicitly exported as a Peppol self-bill.
        Initialize();

        // [GIVEN] Credit "PC" applies to ordinary invoice "PI".
        SetupScenario(Enum::"E-Document Format"::"Peppol BIS 3.0 FR");
        DisableSelfBillingAgreement();
        PostInvoice(PurchInvHeader);
        PostCreditMemo(PurchCrMemoHeader, PurchInvHeader."No.");

        // [WHEN] Export is requested with the self-billed credit type.
        asserterror CreateSelfBillingCreditMemo(PurchCrMemoHeader);

        // [THEN] The original invoice must itself be self-billed.
        Assert.ExpectedError(PurchInvHeader.FieldCaption("Self-Billing Invoice"));
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure FacturXRejectsOrdinaryInvoiceCreditAsSelfBill()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Credit "PC" applied to an ordinary invoice cannot be explicitly exported as a Factur-X self-bill.
        Initialize();

        // [GIVEN] Credit "PC" applies to ordinary invoice "PI".
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        DisableSelfBillingAgreement();
        PostInvoice(PurchInvHeader);
        PostCreditMemo(PurchCrMemoHeader, PurchInvHeader."No.");

        // [WHEN] Export is requested with the self-billed credit type.
        asserterror CreateSelfBillingCreditMemo(PurchCrMemoHeader);

        // [THEN] The original invoice must itself be self-billed.
        Assert.ExpectedError(PurchInvHeader.FieldCaption("Self-Billing Invoice"));
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure FacturXReconcilesVATInclusiveCreditMemoLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        EDocument: Record "E-Document";
        PDFBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] VAT-inclusive credit "PC" produces net CII lines without an artificial invoice discount.
        Initialize();

        // [GIVEN] Credit "PC" applies to self-billed invoice "PI" and includes VAT in prices.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        PostInvoice(PurchInvHeader);
        CreateCreditMemo(PurchaseHeader, PurchInvHeader."No.");
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);

        // [WHEN] Credit "PC" is posted.
        PurchCrMemoHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        PurchCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        // [THEN] The PDF contains credit 261 with reconciled net lines, tax and total.
        GetExportedDocument(PurchCrMemoHeader, EDocument, PDFBlob);
        ReadPDFXml(PDFBlob, XmlDoc);
        VerifyCIICreditMemo(XmlDoc, PurchCrMemoHeader, PurchInvHeader);
    end;

    [Test]
    procedure FacturXRetryRetainsMasterAddressFallback()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        ServiceParticipant: Record "Service Participant";
        EDocExport: Codeunit "E-Doc. Export";
        PDFBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        XmlDoc: XmlDocument;
        ReExported: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Existing Factur-X retries retain master-data fallback after initiation participants disappear.
        Initialize();

        // [GIVEN] PI was exported with participants that are subsequently deleted.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        PostInvoice(PurchInvHeader);
        GetExportedDocument(PurchInvHeader, EDocument, PDFBlob);
        ServiceParticipant.SetRange(Service, EDocumentService.Code);
        ServiceParticipant.DeleteAll();
        SourceHeader.GetTable(PurchInvHeader);
        EDocumentService.SetRecFilter();

        // [WHEN] The existing public raw creation/re-export API is used.
        ReExported := EDocExport.CreateAndExportEDocument(SourceHeader, EDocumentService,
            EDocument."Workflow Code", EDocument."Document Sending Profile", EDocument."Document Type", true);

        // [THEN] No new initiation gate is applied and the PDF XML uses the existing master-data fallback.
        Assert.IsTrue(ReExported, 'Existing exports must remain retryable without initiation participants.');
        GetExportedDocument(PurchInvHeader, EDocument, PDFBlob);
        ReadPDFXml(PDFBlob, XmlDoc);
        Assert.AreEqual('987654321_MASTER', NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID'), 'Keep the seller master-data fallback.');
        Assert.AreEqual(CompanyInformation."SIRET No.", NodeValue(XmlDoc, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'), 'Keep the company master-data fallback.');
    end;

    [Test]
    procedure FacturXKeepsSelectedServiceWithOtherServicePresent()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        ServiceParticipant: Record "Service Participant";
        PDFBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        OtherServiceCode: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Shared source helpers must not lose the selected service during PDF XML rendering.
        Initialize();

        // [GIVEN] S1 and S2 have different addresses for the same seller V.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        OtherServiceCode := LibraryEDocument.CreateService(Enum::"E-Document Format"::"Factur-X FR", Enum::"Service Integration"::Mock);
        ServiceParticipant.Get(EDocumentService.Code, Enum::"E-Document Source Type"::Vendor, Vendor."No.");
        ServiceParticipant.Service := OtherServiceCode;
        ServiceParticipant."Participant Identifier" := '987654321_OTHER';
        ServiceParticipant.Insert(true);

        // [WHEN] PI is posted using S1.
        PostInvoice(PurchInvHeader);

        // [THEN] The actual PDF attachment retains S1's identifiers and all existing CII mappings.
        GetExportedDocument(PurchInvHeader, EDocument, PDFBlob);
        ReadPDFXml(PDFBlob, XmlDoc);
        VerifyCIIInvoice(XmlDoc, PurchInvHeader);
    end;

    [Test]
    procedure FacturXPreservesSellerSnapshotAndSeparatePayToBank()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PayToVendor: Record Vendor;
        PayToBankAccount: Record "Vendor Bank Account";
        EDocument: Record "E-Document";
        EDocExport: Codeunit "E-Doc. Export";
        PDFBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        XmlDoc: XmlDocument;
        ReExported: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] CII retains the posted Buy-from seller and the distinct Pay-to beneficiary.
        Initialize();

        // [GIVEN] PI has seller V and pay-to V2 with its own bank account.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        LibraryPurchase.CreateVendor(PayToVendor);
        PayToVendor."Document Sending Profile" := Vendor."Document Sending Profile";
        PayToVendor."Self-Billing Agreement" := true;
        PayToVendor.Validate("Self-Billing Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        PayToVendor.Validate("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        PayToVendor.Validate("Country/Region Code", Vendor."Country/Region Code");
        PayToVendor."VAT Registration No." := Vendor."VAT Registration No.";
        PayToVendor."Payment Method Code" := Vendor."Payment Method Code";
        LibraryPurchase.CreateVendorBankAccount(PayToBankAccount, PayToVendor."No.");
        PayToBankAccount.Validate(IBAN, 'FR7630006000011234567890189');
        PayToBankAccount.Modify(true);
        PayToVendor.Validate("Preferred Bank Account Code", PayToBankAccount.Code);
        PayToVendor.Modify(true);
        CreateInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendor."No.");
        PurchaseHeader.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        Vendor.Name := 'Changed live seller';
        Vendor.Modify(true);
        GetExportedDocument(PurchInvHeader, EDocument, PDFBlob);
        SourceHeader.GetTable(PurchInvHeader);
        EDocumentService.SetRecFilter();

        // [WHEN] PI is exported again after V's live name changes.
        ReExported := EDocExport.CreateAndExportEDocument(SourceHeader, EDocumentService,
            EDocument."Workflow Code", EDocument."Document Sending Profile", EDocument."Document Type", true);

        // [THEN] The seller snapshot, selected seller endpoint and V2's bank policy remain distinct.
        Assert.IsTrue(ReExported, 'The posted self-bill must be exported.');
        GetExportedDocument(PurchInvHeader, EDocument, PDFBlob);
        ReadPDFXml(PDFBlob, XmlDoc);
        Assert.AreEqual(PurchInvHeader."Buy-from Vendor Name", NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:Name'), 'CII retains the posted seller name.');
        Assert.AreEqual('987654321_DEST', NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID'), 'The Buy-from vendor remains the seller.');
        Assert.AreEqual(PayToBankAccount.IBAN, NodeValue(XmlDoc, '//ram:PayeePartyCreditorFinancialAccount/ram:IBANID'), 'The Pay-to vendor remains the beneficiary.');
    end;

    [Test]
    procedure FacturXNetNormalizationRetainsFilteredTemporaryLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        TempPurchInvLine: Record "Purch. Inv. Line" temporary;
        EDocument: Record "E-Document";
        CIIXMLBuilder: Codeunit "CII XML Builder";
        XMLBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
        XmlDoc: XmlDocument;
        Nodes: XmlNodeList;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637647] Shared normalization keeps the supplied temporary/filtered CII line view.
        Initialize();

        // [GIVEN] VAT-inclusive PI has a temporary line view excluding an extra line.
        SetupScenario(Enum::"E-Document Format"::"Factur-X FR");
        CreateInvoice(PurchaseHeader);
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        TempPurchInvLine := PurchInvLine;
        TempPurchInvLine.Insert();
        TempPurchInvLine."Line No." += 10000;
        TempPurchInvLine.Insert();
        TempPurchInvLine.SetRange("Line No.", PurchInvLine."Line No.");
        TempPurchInvLine.FindFirst();
        SourceHeader.GetTable(PurchInvHeader);
        SourceLines.GetTable(TempPurchInvLine);
        EDocument."Document Type" := EDocument."Document Type"::"Self-Billed Purchase Invoice";
        EDocument."Document No." := PurchInvHeader."No.";
        EDocument."Document Date" := PurchInvHeader."Document Date";
        EDocument."Currency Code" := PurchInvHeader."Currency Code";
        EDocument."Amount Excl. VAT" := PurchInvHeader.Amount;
        EDocument."Amount Incl. VAT" := PurchInvHeader."Amount Including VAT";

        // [WHEN] CII is created from that filtered view.
        CIIXMLBuilder.CreateInvoiceXml(EDocument, SourceHeader, SourceLines, XMLBlob, EDocumentService.Code);

        // [THEN] Exactly the selected line is normalized, with the original net amount.
        ReadXml(XMLBlob, XmlDoc);
        XmlDoc.SelectNodes('//*[local-name()="IncludedSupplyChainTradeLineItem"]', Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'The excluded temporary line must not be serialized.');
        VerifyVATInclusiveAmounts(XmlDoc, PurchInvHeader);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"FR Self-Billing Tests");
        Clear(EDocumentService);
        Clear(Vendor);
        if IsInitialized then begin
            LibrarySetupStorage.Restore();
            exit;
        end;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"FR Self-Billing Tests");
        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"FR Self-Billing Tests");
    end;

    local procedure SetupScenario(DocumentFormat: Enum "E-Document Format")
    var
        Customer: Record Customer;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SupportedType: Record "E-Doc. Service Supported Type";
        PaymentMethod: Record "Payment Method";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, DocumentFormat, Enum::"Service Integration"::Mock);
        SupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        SupportedType.DeleteAll();
        EDocumentService.Validate("Document Format", DocumentFormat);
        EDocumentService.Modify(true);

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then begin
            GeneralLedgerSetup."LCY Code" := 'EUR';
            GeneralLedgerSetup.Modify(true);
        end;

        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation."SIRET No." := '12345678901234';
        CompanyInformation."VAT Registration No." := 'FR00123456789';
        CompanyInformation."Country/Region Code" := 'FR';
        CompanyInformation.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Document Sending Profile" := Customer."Document Sending Profile";
        Vendor.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        Vendor.Validate("Self-Billing Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        Vendor."Self-Billing Agreement" := true;
        Vendor."Registration Number" := '987654321';
        Vendor."VAT Registration No." := 'FR00987654321';
        Vendor."Country/Region Code" := 'FR';
        Vendor.Address := '10 Rue du Fournisseur';
        Vendor.City := 'Paris';
        Vendor."Post Code" := '75001';
        Vendor."FR Electronic Address" := '987654321_MASTER';
        Vendor."FR Elec. Address Scheme" := Vendor."FR Elec. Address Scheme"::"0225";
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate(IBAN, 'FR1420041010050500013M02606');
        VendorBankAccount.Modify(true);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Payment Means Code" := '58';
        PaymentMethod.Modify(true);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Self-Billing Inv. Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Validate("Credit Memo Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
        InsertParticipant(Enum::"E-Document Source Type"::Vendor, Vendor."No.", '987654321_DEST', Enum::"Electronic Address Scheme"::"0225");
        InsertParticipant(Enum::"E-Document Source Type"::Company, '', 'issuer@example.test', Enum::"Electronic Address Scheme"::EM);

        SetReportSelection(Enum::"Report Selection Usage"::"P.Self Billing Invoice", Report::"Self Billing Invoice");
        SetReportSelection(Enum::"Report Selection Usage"::"P.Cr.Memo", Report::"Purchase - Credit Memo");
    end;

    local procedure SetReportSelection(ReportUsage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Usage := ReportUsage;
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := ReportId;
        ReportSelections.Insert(true);
    end;

    local procedure InsertParticipant(ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20]; Identifier: Text[200]; IdentifierScheme: Enum "Electronic Address Scheme")
    var
        ServiceParticipant: Record "Service Participant";
    begin
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ParticipantType;
        ServiceParticipant.Participant := ParticipantNo;
        ServiceParticipant."Participant Identifier" := Identifier;
        ServiceParticipant."FR Identifier Scheme" := IdentifierScheme;
        ServiceParticipant.Insert(true);
    end;

    local procedure CreateInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryEDocument.CreateItemWithStandardVAT(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine,
            Enum::"Purchase Document Type"::Invoice, Vendor."No.", Item."No.", 1, '', 0D);
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Modify(true);
    end;

    local procedure PostInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateInvoice(PurchaseHeader);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
    end;

    local procedure GetExportedDocument(PurchInvHeader: Record "Purch. Inv. Header"; var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
        GetExportedDocument(PurchInvHeader.RecordId(), Enum::"E-Document Type"::"Self-Billed Purchase Invoice", EDocument, TempBlob);
    end;

    local procedure GetExportedDocument(PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
        GetExportedDocument(PurchCrMemoHeader.RecordId(), Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo", EDocument, TempBlob);
    end;

    local procedure GetExportedDocument(SourceRecordId: RecordId; DocumentType: Enum "E-Document Type"; var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    var
        EDocumentLog: Record "E-Document Log";
        DataStorage: Record "E-Doc. Data Storage";
    begin
        EDocument.SetRange("Document Record ID", SourceRecordId);
        Assert.RecordIsNotEmpty(EDocument);
        EDocument.FindFirst();
        Assert.AreEqual(DocumentType, EDocument."Document Type", 'The document must have the correct self-billed type.');
        Assert.AreEqual(Enum::"E-Document Direction"::Outgoing, EDocument.Direction, 'The document must be outgoing.');
        EDocumentLog.SetRange("E-Doc. Entry No", EDocument."Entry No");
        EDocumentLog.SetRange("Service Code", EDocumentService.Code);
        EDocumentLog.SetRange(Status, Enum::"E-Document Service Status"::Exported);
        Assert.RecordIsNotEmpty(EDocumentLog);
        EDocumentLog.FindLast();
        DataStorage.Get(EDocumentLog."E-Doc. Data Storage Entry No.");
        TempBlob := DataStorage.GetTempBlob();
        Assert.IsTrue(TempBlob.HasValue(), 'Posting must produce an exported document.');
    end;

    local procedure VerifyPeppolInvoice(XmlDoc: XmlDocument; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        Assert.AreEqual('389', NodeValue(XmlDoc, '/*/cbc:InvoiceTypeCode'), 'Incorrect invoice type.');
        Assert.AreEqual(PurchInvHeader."No.", NodeValue(XmlDoc, '/*/cbc:ID'), 'Incorrect invoice number.');
        Assert.AreEqual('B1', NodeValue(XmlDoc, '/*/cbc:ProfileID'), 'Incorrect purchase billing mode.');
        Assert.AreEqual(PurchInvHeader."Buy-from Vendor Name", NodeValue(XmlDoc, '/*/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name'), 'The vendor must remain seller.');
        Assert.AreEqual('987654321', NodeValue(XmlDoc, '/*/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID'), 'Incorrect seller SIREN.');
        Assert.AreEqual('987654321_DEST', NodeValue(XmlDoc, '/*/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'), 'Use the selected-service vendor address.');
        Assert.AreEqual('0225', NodeValue(XmlDoc, '/*/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID'), 'Incorrect seller address scheme.');
        Assert.AreEqual(CompanyInformation.Name, NodeValue(XmlDoc, '/*/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name'), 'The company must remain buyer.');
        Assert.AreEqual(CompanyInformation."Registration No.", NodeValue(XmlDoc, '/*/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID'), 'Incorrect buyer SIREN.');
        Assert.AreEqual('issuer@example.test', NodeValue(XmlDoc, '/*/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'), 'Use the selected-service company address.');
        Assert.AreEqual('EM', NodeValue(XmlDoc, '/*/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'), 'The buyer issuer may use email.');
        Assert.AreEqual(PurchInvHeader."Amount Including VAT", NodeAmount(XmlDoc, '/*/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount'), 'Incorrect invoice total.');
    end;

    local procedure VerifyCIIInvoice(XmlDoc: XmlDocument; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        Assert.AreEqual('389', NodeValue(XmlDoc, '//rsm:ExchangedDocument/ram:TypeCode'), 'Incorrect invoice type.');
        Assert.AreEqual(PurchInvHeader."No.", NodeValue(XmlDoc, '//rsm:ExchangedDocument/ram:ID'), 'Incorrect invoice number.');
        Assert.AreEqual('B1', NodeValue(XmlDoc, '//ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID'), 'Incorrect purchase billing mode.');
        Assert.AreEqual(PurchInvHeader."Buy-from Vendor Name", NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:Name'), 'The vendor must be seller.');
        Assert.AreEqual('987654321', NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID'), 'Incorrect seller SIREN.');
        Assert.AreEqual('987654321_DEST', NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID'), 'Use the selected-service vendor address.');
        Assert.AreEqual('0225', NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'), 'Incorrect seller address scheme.');
        Assert.AreEqual(CompanyInformation.Name, NodeValue(XmlDoc, '//ram:BuyerTradeParty/ram:Name'), 'The company must be buyer.');
        Assert.AreEqual('issuer@example.test', NodeValue(XmlDoc, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'), 'Use the selected-service company address.');
        Assert.AreEqual('EM', NodeValue(XmlDoc, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'), 'The buyer issuer may use email.');
        Assert.AreEqual(VendorBankAccount.IBAN, NodeValue(XmlDoc, '//ram:PayeePartyCreditorFinancialAccount/ram:IBANID'), 'The beneficiary must be the vendor.');
        Assert.AreEqual(PurchInvHeader."Amount Including VAT", NodeAmount(XmlDoc, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount'), 'Incorrect invoice total.');
        Assert.AreEqual(PurchInvHeader.Amount, NodeAmount(XmlDoc, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount'), 'Incorrect taxable total.');
    end;

    local procedure VerifyVATInclusiveAmounts(XmlDoc: XmlDocument; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        Assert.AreNotEqual(PurchInvHeader.Amount, PurchInvHeader."Amount Including VAT", 'The fixture must include VAT.');
        Assert.AreEqual(PurchInvHeader.Amount, NodeAmount(XmlDoc, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount'), 'CII line totals must exclude VAT.');
        Assert.AreEqual(PurchInvHeader.Amount, NodeAmount(XmlDoc, '//ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount'), 'The CII invoice line must exclude VAT.');
        Assert.AreEqual('', NodeValue(XmlDoc, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:AllowanceTotalAmount'), 'VAT must not become an invoice discount.');
    end;

    local procedure CreateCreditMemo(var PurchaseHeader: Record "Purchase Header"; InvoiceNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryEDocument.CreateItemWithStandardVAT(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine,
            Enum::"Purchase Document Type"::"Credit Memo", Vendor."No.", Item."No.", 1, '', 0D);
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        if InvoiceNo <> '' then
            PurchaseHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Modify(true);
    end;

    local procedure PostCreditMemo(var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; InvoiceNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateCreditMemo(PurchaseHeader, InvoiceNo);
        PurchCrMemoHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        PurchCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
    end;

    local procedure CreateSelfBillingCreditMemo(PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        EDocument: Record "E-Document";
        PeppolFormat: Codeunit "Peppol BIS 3.0 FR Format";
        FacturXFormat: Codeunit "Factur-X Format";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        SourceHeader.GetTable(PurchCrMemoHeader);
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHeader."No.");
        SourceLines.GetTable(PurchCrMemoLine);
        EDocument."Document Type" := EDocument."Document Type"::"Self-Billed Purch. Cr. Memo";
        case EDocumentService."Document Format" of
            Enum::"E-Document Format"::"Peppol BIS 3.0 FR":
                PeppolFormat.Create(EDocumentService, EDocument, SourceHeader, SourceLines, TempBlob);
            Enum::"E-Document Format"::"Factur-X FR":
                FacturXFormat.Create(EDocumentService, EDocument, SourceHeader, SourceLines, TempBlob);
            else
                Error('Unsupported test format.');
        end;
    end;

    local procedure VerifyPeppolCreditMemo(XmlDoc: XmlDocument; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        Assert.AreEqual('261', NodeValue(XmlDoc, '/*/cbc:CreditNoteTypeCode'), 'Incorrect credit type.');
        Assert.AreEqual(PurchCrMemoHeader."No.", NodeValue(XmlDoc, '/*/cbc:ID'), 'Incorrect credit number.');
        Assert.AreEqual('B1', NodeValue(XmlDoc, '/*/cbc:ProfileID'), 'Incorrect purchase billing mode.');
        Assert.AreEqual(PurchCrMemoHeader."Buy-from Vendor Name", NodeValue(XmlDoc, '/*/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name'), 'The vendor must remain seller.');
        Assert.AreEqual('987654321_DEST', NodeValue(XmlDoc, '/*/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'), 'Use the selected-service seller address.');
        Assert.AreEqual('0225', NodeValue(XmlDoc, '/*/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID'), 'Incorrect seller address scheme.');
        Assert.AreEqual(CompanyInformation.Name, NodeValue(XmlDoc, '/*/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name'), 'The company must remain buyer.');
        Assert.AreEqual('issuer@example.test', NodeValue(XmlDoc, '/*/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'), 'Use the selected-service buyer address.');
        Assert.AreEqual('EM', NodeValue(XmlDoc, '/*/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'), 'Incorrect buyer address scheme.');
        Assert.AreEqual(PurchInvHeader."No.", NodeValue(XmlDoc, '/*/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID'), 'Reference the original self-billed invoice.');
        Assert.AreEqual(Format(PurchInvHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'), NodeValue(XmlDoc, '/*/cac:BillingReference/cac:InvoiceDocumentReference/cbc:IssueDate'), 'Incorrect original invoice date.');
        Assert.AreEqual(PurchCrMemoHeader.Amount, NodeAmount(XmlDoc, '/*/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount'), 'Incorrect credit net amount.');
        Assert.AreEqual(PurchCrMemoHeader."Amount Including VAT", NodeAmount(XmlDoc, '/*/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount'), 'Incorrect credit total.');
        Assert.AreEqual(PurchCrMemoHeader."Amount Including VAT" - PurchCrMemoHeader.Amount, NodeAmount(XmlDoc, '/*/cac:TaxTotal/cbc:TaxAmount'), 'Incorrect credit tax amount.');
    end;

    local procedure VerifyCIICreditMemo(XmlDoc: XmlDocument; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        Assert.AreEqual('261', NodeValue(XmlDoc, '//rsm:ExchangedDocument/ram:TypeCode'), 'Incorrect credit type.');
        Assert.AreEqual(PurchCrMemoHeader."No.", NodeValue(XmlDoc, '//rsm:ExchangedDocument/ram:ID'), 'Incorrect credit number.');
        Assert.AreEqual('B1', NodeValue(XmlDoc, '//ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID'), 'Incorrect purchase billing mode.');
        Assert.AreEqual(PurchCrMemoHeader."Buy-from Vendor Name", NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:Name'), 'The vendor must remain seller.');
        Assert.AreEqual('987654321_DEST', NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID'), 'Use the selected-service seller address.');
        Assert.AreEqual('0225', NodeValue(XmlDoc, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'), 'Incorrect seller address scheme.');
        Assert.AreEqual(CompanyInformation.Name, NodeValue(XmlDoc, '//ram:BuyerTradeParty/ram:Name'), 'The company must remain buyer.');
        Assert.AreEqual('issuer@example.test', NodeValue(XmlDoc, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'), 'Use the selected-service buyer address.');
        Assert.AreEqual('EM', NodeValue(XmlDoc, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'), 'Incorrect buyer address scheme.');
        Assert.AreEqual(PurchInvHeader."No.", NodeValue(XmlDoc, '//ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument/ram:IssuerAssignedID'), 'Reference the original self-billed invoice.');
        Assert.AreEqual(Format(PurchInvHeader."Document Date", 0, '<Year4><Month,2><Day,2>'), NodeValue(XmlDoc, '//ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument/ram:FormattedIssueDateTime/*'), 'Incorrect original invoice date.');
        Assert.AreNotEqual(PurchCrMemoHeader.Amount, PurchCrMemoHeader."Amount Including VAT", 'The fixture must include VAT.');
        Assert.AreEqual(PurchCrMemoHeader.Amount, NodeAmount(XmlDoc, '//ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount'), 'The credit line must exclude VAT.');
        Assert.AreEqual(PurchCrMemoHeader.Amount, NodeAmount(XmlDoc, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount'), 'Incorrect credit net amount.');
        Assert.AreEqual(PurchCrMemoHeader."Amount Including VAT", NodeAmount(XmlDoc, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount'), 'Incorrect credit total.');
        Assert.AreEqual(PurchCrMemoHeader."Amount Including VAT" - PurchCrMemoHeader.Amount, NodeAmount(XmlDoc, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount'), 'Incorrect credit tax amount.');
        Assert.AreEqual('', NodeValue(XmlDoc, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:AllowanceTotalAmount'), 'VAT must not become an invoice discount.');
        Assert.AreEqual('', NodeValue(XmlDoc, '//ram:SpecifiedTradeSettlementPaymentMeans'), 'An applied credit must not imply a cash refund instruction.');
    end;

    local procedure ReadPDFXml(var PDFBlob: Codeunit "Temp Blob"; var XmlDoc: XmlDocument)
    var
        XMLBlob: Codeunit "Temp Blob";
        PDFDocument: Codeunit "PDF Document";
        PDFInStream: InStream;
    begin
        PDFBlob.CreateInStream(PDFInStream);
        Assert.IsTrue(PDFDocument.GetDocumentAttachmentStream(PDFInStream, XMLBlob), 'The PDF must contain the credit XML.');
        ReadXml(XMLBlob, XmlDoc);
    end;

    local procedure VerifyNoEDocument(SourceRecordId: RecordId)
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Document Record ID", SourceRecordId);
        Assert.RecordIsEmpty(EDocument);
    end;

    local procedure DisableSelfBillingAgreement()
    begin
        Vendor."Self-Billing Agreement" := false;
        Vendor.Modify(true);
    end;

    local procedure CustomizeSupportedTypes()
    var
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        SupportedType.Delete();
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo");
        SupportedType.Delete();
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Sales Invoice");
        SupportedType.Direction := Enum::"E-Doc. Supp. Type Direction"::Incoming;
        SupportedType.Modify();
    end;

    local procedure VerifyCustomizedSupportedTypes()
    var
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        Assert.IsFalse(SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purchase Invoice"), 'Existing services require explicit opt-in.');
        Assert.IsFalse(SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo"), 'Existing services require explicit credit opt-in.');
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Sales Invoice");
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Incoming, SupportedType.Direction, 'Preserve the customized direction.');
    end;

    local procedure SetInvalidSellerAddress()
    var
        ServiceParticipant: Record "Service Participant";
    begin
        ServiceParticipant.Get(EDocumentService.Code, Enum::"E-Document Source Type"::Vendor, Vendor."No.");
        ServiceParticipant."Participant Identifier" := 'vendor@example.test';
        ServiceParticipant."FR Identifier Scheme" := ServiceParticipant."FR Identifier Scheme"::EM;
        ServiceParticipant.Modify();
    end;

    local procedure ReadXml(var TempBlob: Codeunit "Temp Blob"; var XmlDoc: XmlDocument)
    var
        XmlInStream: InStream;
    begin
        TempBlob.CreateInStream(XmlInStream);
        XmlDocument.ReadFrom(XmlInStream, XmlDoc);
    end;

    local procedure NodeValue(XmlDoc: XmlDocument; XPath: Text): Text
    var
        NamespaceMgr: XmlNamespaceManager;
    begin
        NamespaceMgr.NameTable(XmlDoc.NameTable());
        NamespaceMgr.AddNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        NamespaceMgr.AddNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        NamespaceMgr.AddNamespace('rsm', 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100');
        NamespaceMgr.AddNamespace('ram', 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');
        exit(EDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, XPath));
    end;

    local procedure NodeAmount(XmlDoc: XmlDocument; XPath: Text) Amount: Decimal
    begin
        Evaluate(Amount, NodeValue(XmlDoc, XPath), 9);
    end;
}
