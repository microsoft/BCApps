// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

codeunit 139547 "E-Doc. Self-Billing XML Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    Permissions = tabledata "Service Participant" = rimd;

    var
        EDocumentService: Record "E-Document Service";
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        EDocumentProcessing: Codeunit "E-Document Processing";
        IncorrectValueErr: Label 'The exported self-billing value is incorrect.';
        RootXPathTok: Label '/*[local-name()="%1"]', Locked = true, Comment = '%1 = XML root element name.';
        ElementXPathTok: Label '//*[local-name()="%1"]', Locked = true, Comment = '%1 = XML element name.';
        MissingXmlNodeErr: Label 'Missing XML node %1.', Comment = '%1 = XPath of the required XML node.';

    [Test]
    procedure W1InvoicePreservesNativeTotalsAndLiveSeller()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        EDocExport: Codeunit "E-Doc. Export";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Real W1 UBL keeps its live vendor name, native totals and existing profile.
        Initialize();

        // [GIVEN] Self-billed PI was posted before V changed its name.
        PostInvoice(PurchInvHeader);
        Vendor.Name := 'Live seller after posting';
        Vendor.Modify(true);
        GetEDocument(PurchInvHeader.RecordId(), EDocument);

        // [WHEN] The real W1 adapter exports PI again.
        EDocExport.Recreate(EDocument, EDocumentService);

        // [THEN] Invoice 389 uses V's live name, company buyer, and unchanged posted totals.
        ReadExport(EDocument, XmlDoc);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        VerifyUBL(XmlDoc, 'Invoice', 'InvoiceTypeCode', '389', PurchInvHeader.Amount, PurchInvHeader."Amount Including VAT");
    end;

    [Test]
    procedure W1CreditPreservesNativeTotalsAndExistingReferenceOutput()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Real W1 credit 261 retains its totals and does not gain FR reference/payment output.
        Initialize();

        // [GIVEN] PC is applied to self-billed PI.
        PostInvoice(PurchInvHeader);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Enum::"Purchase Document Type"::"Credit Memo");
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", PurchInvHeader."No.");
        PurchaseHeader.Modify(true);

        // [WHEN] PC is posted through the real W1 adapter.
        PurchCrMemoHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [THEN] CreditNote 261 has the native posted totals and the existing W1 element policy.
        GetEDocument(PurchCrMemoHeader.RecordId(), EDocument);
        ReadExport(EDocument, XmlDoc);
        PurchCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        VerifyUBL(XmlDoc, 'CreditNote', 'CreditNoteTypeCode', '261', PurchCrMemoHeader.Amount, PurchCrMemoHeader."Amount Including VAT");
    end;

    [Test]
    procedure W1InvoiceCanStillEmbedOptionalPDF()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        ReportSelections: Record "Report Selections";
        XmlDoc: XmlDocument;
        Node: XmlNode;
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] W1 still embeds the selected native purchase report inside UBL when requested.
        Initialize();

        // [GIVEN] The invoice report is selected and PDF embedding is enabled.
        ReportSelections.SetRange(Usage, Enum::"Report Selection Usage"::"P.Self Billing Invoice");
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Usage := Enum::"Report Selection Usage"::"P.Self Billing Invoice";
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := Report::"Self Billing Invoice";
        ReportSelections.Insert(true);
        EDocumentService."Embed PDF in export" := true;
        EDocumentService.Modify(true);

        // [WHEN] Self-billed PI is posted and exported.
        PostInvoice(PurchInvHeader);

        // [THEN] The UBL attachment contains an actual nonempty PDF payload.
        GetEDocument(PurchInvHeader.RecordId(), EDocument);
        ReadExport(EDocument, XmlDoc);
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="EmbeddedDocumentBinaryObject"]', Node), 'The optional PDF must be embedded.');
        Assert.AreEqual('application/pdf', GetXmlText(XmlDoc, '//*[local-name()="EmbeddedDocumentBinaryObject"]/@mimeCode'), IncorrectValueErr);
        Assert.IsTrue(StrLen(Node.AsXmlElement().InnerText()) > 0, 'The embedded PDF cannot be empty.');
    end;

    [Test]
    procedure W1DirectAdapterRejectsOrdinaryInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        PeppolFormat: Codeunit "EDoc PEPPOL BIS 3.0";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Direct W1 calls cannot relabel an ordinary purchase invoice as self-billed.
        Initialize();

        // [GIVEN] PI is ordinary but the requested E-Document type is self-billed.
        Vendor."Self-Billing Agreement" := false;
        Vendor.Modify(true);
        PostInvoice(PurchInvHeader);
        SourceHeader.GetTable(PurchInvHeader);
        EDocument."Document Type" := EDocument."Document Type"::"Self-Billed Purchase Invoice";

        // [WHEN] The real W1 adapter is called directly.
        asserterror PeppolFormat.Create(EDocumentService, EDocument, SourceHeader, SourceLines, TempBlob);

        // [THEN] Native source validation rejects the request before serialization.
        Assert.ExpectedError('Self-Billing Invoice');
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure SharedGuardRejectsMismatchedSourceType()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        SourceHeader: RecordRef;
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] A valid self-billed invoice is not a valid credit memo source.
        Initialize();

        // [GIVEN] PI is a posted self-billed invoice.
        PostInvoice(PurchInvHeader);
        SourceHeader.GetTable(PurchInvHeader);

        // [WHEN] A credit export is requested for PI.
        asserterror EDocumentProcessing.CheckSelfBillingSource(SourceHeader, Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo");

        // [THEN] The exact table/type guard rejects the source.
        Assert.ExpectedError('does not match self-billing document type');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SharedPartiesPreserveTemporarySourceAndDistinctRoles()
    var
        TempPurchInvHeader: Record "Purch. Inv. Header" temporary;
        PayToVendor: Record Vendor;
        SourceHeader: RecordRef;
        SourceRecordId: RecordId;
        SourceView: Text;
        SellerVendorNo: Code[20];
        PayToVendorNo: Code[20];
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Shared facts use the supplied temporary source without conflating seller and pay-to.
        Initialize();

        // [GIVEN] Temporary PI has V as seller, V2 as pay-to and a restricted source view.
        LibraryPurchase.CreateVendor(PayToVendor);
        TempPurchInvHeader."No." := 'TEMP-SELF-BILL';
        TempPurchInvHeader."Self-Billing Invoice" := true;
        TempPurchInvHeader."Buy-from Vendor No." := Vendor."No.";
        TempPurchInvHeader."Pay-to Vendor No." := PayToVendor."No.";
        TempPurchInvHeader.Insert();
        TempPurchInvHeader.SetRecFilter();
        SourceHeader.GetTable(TempPurchInvHeader);
        SourceView := SourceHeader.GetView();
        SourceRecordId := SourceHeader.RecordId();

        // [WHEN] Core validates PI and resolves its roles.
        EDocumentProcessing.CheckSelfBillingSource(SourceHeader, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        EDocumentProcessing.GetSelfBillingParties(SourceHeader, SellerVendorNo, PayToVendorNo);

        // [THEN] Both roles and all caller source properties are preserved.
        Assert.AreEqual(Vendor."No.", SellerVendorNo, IncorrectValueErr);
        Assert.AreEqual(PayToVendor."No.", PayToVendorNo, IncorrectValueErr);
        Assert.IsTrue(SourceHeader.IsTemporary(), 'The source must remain temporary.');
        Assert.AreEqual(SourceRecordId, SourceHeader.RecordId(), IncorrectValueErr);
        Assert.AreEqual(SourceView, SourceHeader.GetView(), IncorrectValueErr);
    end;

    [Test]
    procedure SharedReferenceDoesNotRequireFrenchReferenceDate()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        ReferencedInvoice: Record "Purch. Inv. Header";
        TempCreditHeader: Record "Purch. Cr. Memo Hdr." temporary;
        SourceHeader: RecordRef;
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Country-specific original-date requirements do not become a generic Core rule.
        Initialize();

        // [GIVEN] PC applies to a self-billed PI without a document date.
        PostInvoice(PurchInvHeader);
        PurchInvHeader."Document Date" := 0D;
        PurchInvHeader.Modify();
        TempCreditHeader."Applies-to Doc. Type" := TempCreditHeader."Applies-to Doc. Type"::Invoice;
        TempCreditHeader."Applies-to Doc. No." := PurchInvHeader."No.";
        SourceHeader.GetTable(TempCreditHeader);

        // [WHEN] Core resolves the required original.
        EDocumentProcessing.GetSelfBillingInvoiceReference(SourceHeader, ReferencedInvoice);

        // [THEN] PI is returned without imposing FR's additional date assertion.
        Assert.AreEqual(PurchInvHeader."No.", ReferencedInvoice."No.", IncorrectValueErr);
        Assert.AreEqual(0D, ReferencedInvoice."Document Date", IncorrectValueErr);
    end;

    [Test]
    procedure FailedReferenceLookupClearsOrdinaryOriginal()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        ReferencedInvoice: Record "Purch. Inv. Header";
        TempCreditHeader: Record "Purch. Cr. Memo Hdr." temporary;
        SourceHeader: RecordRef;
        ReferenceFound: Boolean;
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] A failed Try lookup cannot leak the ordinary original as a self-billed invoice.
        Initialize();

        // [GIVEN] PC applies to ordinary PI and the output already contains PI.
        Vendor."Self-Billing Agreement" := false;
        Vendor.Modify(true);
        PostInvoice(PurchInvHeader);
        ReferencedInvoice := PurchInvHeader;
        TempCreditHeader."Applies-to Doc. Type" := TempCreditHeader."Applies-to Doc. Type"::Invoice;
        TempCreditHeader."Applies-to Doc. No." := PurchInvHeader."No.";
        SourceHeader.GetTable(TempCreditHeader);

        // [WHEN] The optional reference is requested.
        ReferenceFound := EDocumentProcessing.TryGetSelfBillingInvoiceReference(SourceHeader, ReferencedInvoice);

        // [THEN] Neither eligibility nor a stale output is returned.
        Assert.IsFalse(ReferenceFound, 'An ordinary original does not qualify.');
        Assert.AreEqual('', ReferencedInvoice."No.", 'Failed lookup must clear its output.');
        Assert.IsFalse(EDocumentProcessing.IsSelfBillingSource(SourceHeader), 'The credit is not self-billed.');
    end;

    [Test]
    procedure MissingReferenceClearsPreviousSuccessfulOutput()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TempCreditHeader: Record "Purch. Cr. Memo Hdr." temporary;
        SourceHeader: RecordRef;
        ReferenceFound: Boolean;
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] An unapplied credit never retains a previous reference result.
        Initialize();

        // [GIVEN] The output contains PI but PC is unapplied.
        PostInvoice(PurchInvHeader);
        SourceHeader.GetTable(TempCreditHeader);

        // [WHEN] Core looks up PC's original.
        ReferenceFound := EDocumentProcessing.TryGetSelfBillingInvoiceReference(SourceHeader, PurchInvHeader);

        // [THEN] No eligible invoice or stale output is returned.
        Assert.IsFalse(ReferenceFound, 'An unapplied credit cannot have a self-billed reference.');
        Assert.AreEqual('', PurchInvHeader."No.", 'Failed lookup must clear its output.');
    end;

    [Test]
    procedure SharedRegistrationPreservesExistingDirections()
    var
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Shared defaults fill gaps idempotently without overwriting an explicit restriction.
        Initialize();

        // [GIVEN] The service explicitly restricts self-billed invoices to incoming.
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        SupportedType.Direction := SupportedType.Direction::Incoming;
        SupportedType.Modify();
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo");
        SupportedType.Delete();

        // [WHEN] Self-billing defaults are registered twice.
        EDocumentProcessing.RegisterDefaultSelfBillingTypes(EDocumentService.Code);
        EDocumentProcessing.RegisterDefaultSelfBillingTypes(EDocumentService.Code);

        // [THEN] The restriction survives and only the missing credit capability is added.
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        Assert.AreEqual(SupportedType.Direction::Incoming, SupportedType.Direction, IncorrectValueErr);
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo");
        Assert.AreEqual(SupportedType.Direction::Outgoing, SupportedType.Direction, IncorrectValueErr);
    end;

    local procedure Initialize()
    var
        Customer: Record Customer;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        Clear(EDocumentService);
        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Mock);
        EDocumentProcessing.RegisterDefaultSelfBillingTypes(EDocumentService.Code);
        CompanyInformation.Get();
        CompanyInformation.GLN := '1234567890128';
        CompanyInformation."Use GLN in Electronic Document" := true;
        CompanyInformation.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Document Sending Profile" := Customer."Document Sending Profile";
        Vendor.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        Vendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Vendor."VAT Registration No." := CompanyInformation."VAT Registration No.";
        Vendor.GLN := '1234567890128';
        Vendor."Self-Billing Agreement" := true;
        Vendor.Validate("Self-Billing Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        Vendor.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Self-Billing Inv. Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Validate("Credit Memo Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
        InsertParticipant(Enum::"E-Document Source Type"::Vendor, Vendor."No.");
        InsertParticipant(Enum::"E-Document Source Type"::Company, '');
    end;

    local procedure InsertParticipant(ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20])
    var
        ServiceParticipant: Record "Service Participant";
    begin
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ParticipantType;
        ServiceParticipant.Participant := ParticipantNo;
        ServiceParticipant."Participant Identifier" := '1234567890128';
        ServiceParticipant.Insert(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
    begin
        LibraryEDocument.CreateItemWithStandardVAT(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, DocumentType, Vendor."No.", Item."No.", 2, '', 0D);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Modify(true);
    end;

    local procedure PostInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Enum::"Purchase Document Type"::Invoice);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure GetEDocument(SourceRecordId: RecordId; var EDocument: Record "E-Document")
    begin
        EDocument.SetRange("Document Record ID", SourceRecordId);
        Assert.RecordCount(EDocument, 1);
        EDocument.FindFirst();
    end;

    local procedure ReadExport(EDocument: Record "E-Document"; var XmlDoc: XmlDocument)
    var
        EDocumentLog: Codeunit "E-Document Log";
        TempBlob: Codeunit "Temp Blob";
    begin
        Assert.IsTrue(EDocumentLog.GetDocumentBlobFromLog(EDocument, EDocumentService, TempBlob, Enum::"E-Document Service Status"::Exported), 'A successful real W1 export is required.');
        Assert.IsTrue(TempBlob.HasValue(), 'The real W1 payload must not be empty.');
        XmlDocument.ReadFrom(TempBlob.CreateInStream(), XmlDoc);
    end;

    local procedure VerifyUBL(XmlDoc: XmlDocument; RootName: Text; TypeElementName: Text; TypeCode: Text; Amount: Decimal; AmountIncludingVAT: Decimal)
    var
        Node: XmlNode;
        ExportedAmount: Decimal;
    begin
        Assert.IsTrue(XmlDoc.SelectSingleNode(StrSubstNo(RootXPathTok, RootName), Node), 'The native UBL document kind must be preserved.');
        Assert.AreEqual(TypeCode, GetXmlText(XmlDoc, StrSubstNo(ElementXPathTok, TypeElementName)), IncorrectValueErr);
        Assert.AreEqual('urn:fdc:peppol.eu:poacc:bis:selfbilling:3.0', GetXmlText(XmlDoc, '//*[local-name()="ProfileID"]'), IncorrectValueErr);
        Assert.AreEqual('urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:selfbilling:3.0', GetXmlText(XmlDoc, '//*[local-name()="CustomizationID"]'), IncorrectValueErr);
        Assert.AreEqual(Vendor.Name, GetXmlText(XmlDoc, '//*[local-name()="AccountingSupplierParty"]//*[local-name()="PartyName"]/*[local-name()="Name"]'), IncorrectValueErr);
        Assert.AreEqual(CompanyInformation.Name, GetXmlText(XmlDoc, '//*[local-name()="AccountingCustomerParty"]//*[local-name()="PartyName"]/*[local-name()="Name"]'), IncorrectValueErr);
        Evaluate(ExportedAmount, GetXmlText(XmlDoc, '//*[local-name()="LegalMonetaryTotal"]/*[local-name()="TaxExclusiveAmount"]'), 9);
        Assert.AreEqual(Amount, ExportedAmount, IncorrectValueErr);
        Evaluate(ExportedAmount, GetXmlText(XmlDoc, '//*[local-name()="LegalMonetaryTotal"]/*[local-name()="TaxInclusiveAmount"]'), 9);
        Assert.AreEqual(AmountIncludingVAT, ExportedAmount, IncorrectValueErr);
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="BillingReference"]', Node), 'This refactor must not add W1 reference output.');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="PaymentMeans"]', Node), 'This refactor must not add W1 payment policy.');
    end;

    local procedure GetXmlText(XmlDoc: XmlDocument; XPath: Text): Text
    var
        Node: XmlNode;
    begin
        Assert.IsTrue(XmlDoc.SelectSingleNode(XPath, Node), StrSubstNo(MissingXmlNodeErr, XPath));
        if Node.IsXmlAttribute() then
            exit(Node.AsXmlAttribute().Value());
        exit(Node.AsXmlElement().InnerText());
    end;
}
