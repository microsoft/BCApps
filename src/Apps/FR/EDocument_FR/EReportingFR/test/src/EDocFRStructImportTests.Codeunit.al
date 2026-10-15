// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 148149 "E-Doc. FR Struct. Import Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        FRLegalIdentifiers: Codeunit "FR Legal Identifiers";
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
        Assert.AreEqual('FX-INV-3001', EDocumentPurchaseHeader."Vendor Invoice No.", 'Wrong vendor invoice number.');
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
        Assert.AreEqual('', EDocumentPurchaseHeader."Vendor External Id", 'A qualified SIRET is not a private vendor identifier.');
        Assert.AreEqual('Acheteur SA', EDocumentPurchaseHeader."Customer Company Name", 'Wrong customer name.');
        Assert.AreEqual('', EDocumentPurchaseHeader."Customer Company Id", 'A qualified SIRET is not a private customer identifier.');
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

    [Test]
    procedure AllReadersMatchExistingRegistrationSIRET()
    var
        Vendor: Record Vendor;
        VendorModifiedAt: DateTime;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Both structured and legacy readers use existing French registration SIRET without writing
        Initialize();

        // [GIVEN] French vendor "V" has a dedicated SIREN and an agreeing registration SIRET
        CreateIdentifiedVendor(Vendor, '123456789', '12345678901234');
        Vendor.Get(Vendor."No.");
        VendorModifiedAt := Vendor.SystemModifiedAt;

        // [WHEN] Both XML formats pass through both reader generations
        VerifyAllReadersMatch(Vendor."No.", '123456789', '12345678901234');

        // [THEN] Matching does not alter vendor master data
        VerifyVendorIdentifiersUnchanged(Vendor, '123456789', '12345678901234', VendorModifiedAt);
    end;

    [Test]
    procedure AllReadersMatchSIRENWithoutSIRET()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] SIREN-only incoming identity is sufficient for an unambiguous vendor
        Initialize();

        // [GIVEN] Vendor "V" has a dedicated SIREN
        CreateIdentifiedVendor(Vendor, '123456789', '');

        // [WHEN] SIREN-only documents pass through all readers
        VerifyAllReadersMatch(Vendor."No.", '123456789', '');

        // [THEN] No SIRET is invented
        Vendor.Get(Vendor."No.");
        Assert.AreEqual('', Vendor."Registration Number", 'Matching must not invent or store an establishment.');
    end;

    [Test]
    procedure AllReadersMatchSIRENDerivedFromLegacySIRET()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] SIREN-only input matches a French vendor whose existing registration SIRET supplies SIREN
        Initialize();

        // [GIVEN] French vendor "V" has a registration SIRET but no stored SIREN
        CreateIdentifiedVendor(Vendor, '', '12345678901234');

        // [WHEN] SIREN-only documents pass through all readers
        VerifyAllReadersMatch(Vendor."No.", '123456789', '');

        // [THEN] The derived identity is not silently persisted
        Vendor.Get(Vendor."No.");
        Assert.AreEqual('', Vendor."SIREN No.", 'Import must not backfill master data.');
    end;

    [Test]
    procedure ExactSIRETDisambiguatesSharedSIREN()
    var
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Exact establishment matching takes precedence over a broader legal-unit match
        Initialize();

        // [GIVEN] Two vendors belong to different establishments of the same legal unit
        CreateIdentifiedVendor(FirstVendor, '123456789', '12345678901234');
        CreateIdentifiedVendor(SecondVendor, '123456789', '12345678900011');

        // [WHEN] The second establishment is explicitly identified
        VerifyAllReadersMatch(SecondVendor."No.", '123456789', '12345678900011');

        // [THEN] The other establishment remains unchanged
        FirstVendor.Get(FirstVendor."No.");
        Assert.AreEqual('12345678901234', FirstVendor."Registration Number", 'The other establishment must not be rewritten.');
    end;

    [Test]
    procedure ExactSIRETIgnoresForeignRegistrationNumber()
    var
        FrenchVendor: Record Vendor;
        ForeignVendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A foreign generic registration cannot take precedence over French legal identity
        Initialize();

        // [GIVEN] French vendor "F" has SIREN and foreign vendor "G" has a matching generic registration
        CreateIdentifiedVendor(FrenchVendor, '123456789', '');
        CreateIdentifiedVendor(ForeignVendor, '', '12345678901234');
        ForeignVendor."Country/Region Code" := CreateCountry('DE');
        ForeignVendor.Modify();

        // [WHEN] All readers receive coherent French legal identifiers
        VerifyAllReadersMatch(FrenchVendor."No.", '123456789', '12345678901234');

        // [THEN] The foreign registration is not interpreted as a French establishment
        Assert.AreEqual('', FRLegalIdentifiers.GetVendorSIRET(ForeignVendor), 'Foreign registration numbers must remain generic.');
    end;

    [Test]
    procedure SIRENMatchingIgnoresOverlongLegacyRegistration()
    var
        ValidVendor: Record Vendor;
        OtherVendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An overlong generic registration sharing a SIREN prefix is not a legacy SIRET candidate
        Initialize();

        // [GIVEN] Vendor "V" has SIREN and vendor "G" has an overlong registration with the same prefix
        CreateIdentifiedVendor(ValidVendor, '123456789', '');
        CreateIdentifiedVendor(OtherVendor, '', '');
        OtherVendor."Registration Number" := '123456789012345';
        OtherVendor.Modify();

        // [WHEN] SIREN-only input passes through all readers
        VerifyAllReadersMatch(ValidVendor."No.", '123456789', '');

        // [THEN] The overlong value is not truncated into a SIRET
        Assert.AreEqual('', FRLegalIdentifiers.GetVendorSIRET(OtherVendor), 'Legacy evidence must be validated before narrowing.');
    end;

    [Test]
    procedure SIRENMatchingIgnoresNonnumericLegacyRegistration()
    var
        ValidVendor: Record Vendor;
        OtherVendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A generic registration with a nonnumeric suffix cannot create a SIREN candidate
        Initialize();

        // [GIVEN] Vendor "V" has SIREN and vendor "G" has fourteen characters rather than fourteen digits
        CreateIdentifiedVendor(ValidVendor, '123456789', '');
        CreateIdentifiedVendor(OtherVendor, '', '');
        OtherVendor."Registration Number" := '1234567890123X';
        OtherVendor.Modify();

        // [WHEN] SIREN-only input passes through all readers
        VerifyAllReadersMatch(ValidVendor."No.", '123456789', '');

        // [THEN] Generic text is not reinterpreted as an establishment identifier
        Assert.AreEqual('', FRLegalIdentifiers.GetVendorSIRET(OtherVendor), 'Only a complete numeric SIRET is legacy evidence.');
    end;

    [Test]
    procedure LegacySIRETRejectsConflictingStoredSIREN()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Exact legacy SIRET matching does not bypass a conflicting populated SIREN
        Initialize();

        // [GIVEN] French vendor "V" has contradictory existing identifiers
        CreateIdentifiedVendor(Vendor, '987654321', '12345678901234');

        // [WHEN] All readers receive the existing registration SIRET
        // [THEN] The stored conflict is reported rather than silently resolved
        VerifyAllReadersReject('123456789', '12345678901234', 'The first nine digits of SIRET must match SIREN');
    end;

    [Test]
    procedure SIRENFallbackRejectsDifferentLegacyEstablishment()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A SIREN match cannot select a different known establishment from legacy registration
        Initialize();

        // [GIVEN] French vendor "V" represents another establishment of the same legal unit
        CreateIdentifiedVendor(Vendor, '123456789', '12345678900011');

        // [WHEN] All readers receive a different SIRET with the same SIREN
        // [THEN] The establishment conflict requires manual resolution
        VerifyAllReadersReject('123456789', '12345678901234', 'different vendor identities or establishments');
    end;

    [Test]
    procedure SharedSIRENAmbiguityIsNotHiddenByVAT()
    var
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A weaker unique VAT match cannot hide ambiguity at the highest matching tier
        Initialize();

        // [GIVEN] Two vendors share SIREN but only one has the incoming VAT
        CreateIdentifiedVendor(FirstVendor, '123456789', '');
        CreateIdentifiedVendor(SecondVendor, '', '12345678900011');
        SecondVendor."VAT Registration No." := 'FR00123456789';
        SecondVendor.Modify();

        // [WHEN] SIREN and the second vendor's VAT are matched
        asserterror FRLegalIdentifiers.FindVendor('123456789', '', SecondVendor."VAT Registration No.", '', '', '', '', '');

        // [THEN] The user must resolve the legal-unit ambiguity
        AssertIdentifierError('More than one vendor matches');
    end;

    [Test]
    procedure DuplicateSIRETIsAmbiguous()
    var
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Master data may contain duplicate SIRETs but automatic matching cannot choose arbitrarily
        Initialize();

        // [GIVEN] Two French vendors share SIREN and the same registration SIRET
        CreateIdentifiedVendor(FirstVendor, '123456789', '12345678901234');
        CreateIdentifiedVendor(SecondVendor, '123456789', '12345678901234');

        // [WHEN] The establishment is matched
        asserterror FRLegalIdentifiers.FindVendor('123456789', '12345678901234', '', '', '', '', '', '');

        // [THEN] No first-record shortcut is used
        AssertIdentifierError('More than one vendor matches');
    end;

    [Test]
    procedure ConflictingVATCandidateCannotOverrideSIRET()
    var
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Different incoming identifiers may not silently select different vendor identities
        Initialize();

        // [GIVEN] Exact SIRET and VAT identify different vendors
        CreateIdentifiedVendor(FirstVendor, '123456789', '12345678901234');
        CreateIdentifiedVendor(SecondVendor, '987654321', '');
        SecondVendor."VAT Registration No." := 'FR00987654321';
        SecondVendor.Modify();

        // [WHEN] Both identifiers are supplied
        asserterror FRLegalIdentifiers.FindVendor('123456789', '12345678901234', SecondVendor."VAT Registration No.", '', '', '', '', '');

        // [THEN] The contradiction is reported
        AssertIdentifierError('different vendor identities or establishments');
    end;

    [Test]
    procedure VATFallbackRejectsContradictoryCanonicalIdentity()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A no-match at the SIREN tier does not authorize a contradictory VAT fallback
        Initialize();

        // [GIVEN] A VAT candidate has a different populated canonical SIREN
        CreateIdentifiedVendor(Vendor, '987654321', '');
        Vendor."VAT Registration No." := 'FR00987654321';
        Vendor.Modify();

        // [WHEN] An unmatched SIREN accompanies that VAT
        asserterror FRLegalIdentifiers.FindVendor('123456789', '', Vendor."VAT Registration No.", '', '', '', '', '');

        // [THEN] The candidate is rejected
        AssertIdentifierError('different vendor identities or establishments');
    end;

    [Test]
    procedure AllReadersPreserveVATFallbackWithoutLegalIDs()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Documents without qualified legal IDs retain compatible VAT matching
        Initialize();

        // [GIVEN] Vendor "V" matches the resource invoice's VAT
        CreateIdentifiedVendor(Vendor, '', '');
        Vendor."VAT Registration No." := 'FR12345678901';
        Vendor.Modify();

        // [WHEN] Documents without legal IDs pass through all readers
        VerifyAllReadersMatch(Vendor."No.", '', '');

        // [THEN] VAT was not promoted into a legal identifier
        Vendor.Get(Vendor."No.");
        Assert.AreEqual('', Vendor."SIREN No.", 'VAT fallback must not manufacture SIREN.');
    end;

    [Test]
    procedure GLNFallbackUsesCompleteThirteenDigits()
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] GLN remains an independent matching identifier
        Initialize();

        // [GIVEN] Vendor "V" has a GLN and no canonical French identifiers
        CreateIdentifiedVendor(Vendor, '', '');
        Vendor.GLN := '1234567890123';
        Vendor.Modify();

        // [WHEN] GLN is the only incoming identifier
        VendorNo := FRLegalIdentifiers.FindVendor('', '', '', Vendor.GLN, '', '', '', '');

        // [THEN] GLN matching remains available
        Assert.AreEqual(Vendor."No.", VendorNo, 'GLN fallback must be retained.');
    end;

    [Test]
    procedure GLNDoesNotTruncateSIRET()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A fourteen-digit value is rejected before assignment to GLN storage
        Initialize();

        // [WHEN] A SIRET-sized GLN is supplied
        asserterror FRLegalIdentifiers.ValidateGLN('12345678901234');

        // [THEN] The fourteenth digit is not silently lost
        AssertIdentifierError('exactly thirteen digits');
    end;

    [Test]
    procedure AllReadersRejectIncoherentIncomingPair()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Both reader generations reject conflicting qualified identifiers
        Initialize();

        // [WHEN] The incoming SIRET belongs to a different legal unit
        VerifyAllReadersReject('123456789', '98765432100011', 'first nine digits of SIRET must match SIREN');
    end;

    [Test]
    procedure AllReadersRequireLegalSIRENWhenSIRETIsSupplied()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Import does not silently synthesize a missing mandatory XML legal term
        Initialize();

        // [WHEN] Qualified SIRET is present without legal SIREN
        VerifyAllReadersReject('', '12345678901234', 'must supply a legal SIREN');
    end;

    [Test]
    procedure AllReadersRejectLongSIRENBeforeNarrowing()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] XML identifiers are validated before bounded AL assignment
        Initialize();

        // [WHEN] Ten digits are supplied as legal SIREN
        VerifyAllReadersReject('1234567890', '', 'exactly nine digits');
    end;

    [Test]
    procedure QualifiedCIIIdentifiersDoNotConsumePrivateID()
    var
        Vendor: Record Vendor;
        EDocument: Record "E-Document";
        Header: Record "E-Document Purchase Header";
        Handler: Codeunit "E-Document Factur-X Handler";
        Content: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unqualified private CII ID is neither SIRET nor GLN
        Initialize();

        // [GIVEN] A VAT-matched supplier has an unrelated private ID
        CreateIdentifiedVendor(Vendor, '', '');
        Vendor."VAT Registration No." := 'FR12345678901';
        Vendor.Modify();
        Content := NavApp.GetResourceAsText(FacturXInvoiceTok, TextEncoding::UTF8);
        Content := Content.Replace('<ram:SellerTradeParty>', '<ram:SellerTradeParty><ram:ID>PRIVATE-SUPPLIER</ram:ID>');
        CreateEDocument(EDocument);

        // [WHEN] The structured CII reader reads the supplier
        Handler.ReadIntoDraft(EDocument, CreateBlob(Content));

        // [THEN] Private ID is not misclassified as a legal or location identifier
        Header.GetFromEDocument(EDocument);
        Assert.AreEqual(Vendor."No.", Header."[BC] Vendor No.", 'VAT fallback must still identify the supplier.');
        Assert.AreEqual('', Header."Vendor GLN", 'Private ID is not GLN.');
    end;

    [Test]
    procedure LegacyW1ReaderRemainsUnboundAfterFrenchFailure()
    var
        Vendor: Record Vendor;
        EDocument: Record "E-Document";
        FrenchReader: Codeunit "PEPPOL BIS 3.0 FR Format";
        W1Reader: Codeunit "EDoc Import PEPPOL BIS 3.0";
        Blob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An exceptional French import does not bind stricter identity rules to later W1 imports
        Initialize();

        // [GIVEN] A VAT-matched vendor and a document with inconsistent French legal IDs
        CreateIdentifiedVendor(Vendor, '', '');
        Vendor."VAT Registration No." := 'FR12345678901';
        Vendor.Modify();
        CreateEDocument(EDocument);
        Blob := CreateIncomingBlob(true, '123456789', '98765432100011');
        asserterror FrenchReader.GetBasicInfoFromReceivedDocument(EDocument, Blob);
        AssertIdentifierError('first nine digits of SIRET must match SIREN');

        // [WHEN] The ordinary W1 importer reads the same document
        W1Reader.ParseBasicInfo(EDocument, Blob);

        // [THEN] It retains its existing VAT-based matching instead of inheriting French validation
        Assert.AreEqual(Vendor."No.", EDocument."Bill-to/Pay-to No.", 'The French manual subscription must not leak.');
    end;

    [Test]
    procedure DuplicateQualifiedUBLIdentifiersAreRejected()
    var
        Document: XmlDocument;
        Namespaces: XmlNamespaceManager;
        SIREN: Text;
        SIRET: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Conflicting qualified legal IDs cannot be reduced to the first XML node
        Initialize();

        // [GIVEN] Two qualified legal SIRENs in one UBL party
        XmlDocument.ReadFrom('<Party xmlns:cac="urn:test:cac" xmlns:cbc="urn:test:cbc"><cac:PartyLegalEntity><cbc:CompanyID schemeID="0002">123456789</cbc:CompanyID><cbc:CompanyID schemeID="0002">987654321</cbc:CompanyID></cac:PartyLegalEntity></Party>', Document);
        Namespaces.AddNamespace('cac', 'urn:test:cac');
        Namespaces.AddNamespace('cbc', 'urn:test:cbc');

        // [WHEN] The shared UBL parser reads the legal terms
        asserterror FRLegalIdentifiers.ReadUBLIdentifiers(Document, Namespaces, '/Party', SIREN, SIRET);

        // [THEN] Duplicate qualification is reported
        AssertIdentifierError('more than one legal identifier');
    end;

    [Test]
    procedure DuplicateQualifiedCIIIdentifiersAreRejected()
    var
        Document: XmlDocument;
        Namespaces: XmlNamespaceManager;
        SIREN: Text;
        SIRET: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Repeated CII SIRET nodes are not silently collapsed
        Initialize();

        // [GIVEN] Two qualified SIRETs in one CII party
        XmlDocument.ReadFrom('<Party xmlns:ram="urn:test:ram"><ram:GlobalID schemeID="0009">12345678901234</ram:GlobalID><ram:GlobalID schemeID="0009">12345678900011</ram:GlobalID><ram:SpecifiedLegalOrganization><ram:ID schemeID="0002">123456789</ram:ID></ram:SpecifiedLegalOrganization></Party>', Document);
        Namespaces.AddNamespace('ram', 'urn:test:ram');

        // [WHEN] The shared CII parser reads the legal terms
        asserterror FRLegalIdentifiers.ReadCIIIdentifiers(Document, Namespaces, '/Party', SIREN, SIRET);

        // [THEN] The conflicting establishment data must be corrected
        AssertIdentifierError('more than one legal identifier');
    end;

    [Test]
    procedure EmptyQualifiedLegalIdentifierIsRejected()
    var
        Document: XmlDocument;
        Namespaces: XmlNamespaceManager;
        SIREN: Text;
        SIRET: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An empty qualified identifier differs from an absent optional identifier
        Initialize();

        // [GIVEN] An empty CII legal SIREN node
        XmlDocument.ReadFrom('<Party xmlns:ram="urn:test:ram"><ram:SpecifiedLegalOrganization><ram:ID schemeID="0002"/></ram:SpecifiedLegalOrganization></Party>', Document);
        Namespaces.AddNamespace('ram', 'urn:test:ram');

        // [WHEN] The parser reads the qualified term
        asserterror FRLegalIdentifiers.ReadCIIIdentifiers(Document, Namespaces, '/Party', SIREN, SIRET);

        // [THEN] Empty input is not treated as missing optional setup
        AssertIdentifierError('identifier in the incoming document is empty');
    end;

    [Test]
    procedure AllReadersRejectOverlongSIRET()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] No reader truncates incoming SIRET to fit a fourteen-character field
        Initialize();

        // [WHEN] Fifteen digits are supplied as SIRET
        VerifyAllReadersReject('123456789', '123456789012345', 'exactly fourteen digits');
    end;

    [Test]
    procedure ParticipantFallbackPrefersSelectedService()
    var
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
        FirstService: Record "E-Document Service";
        SecondService: Record "E-Document Service";
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Legacy participant fallback preserves selected-service precedence
        Initialize();

        // [GIVEN] Different services map the same participant to different vendors
        CreateIdentifiedVendor(FirstVendor, '', '');
        CreateIdentifiedVendor(SecondVendor, '', '');
        CreateVendorParticipant(FirstService, FirstVendor."No.", '0002:123456789');
        CreateVendorParticipant(SecondService, SecondVendor."No.", '0002:123456789');

        // [WHEN] Matching is scoped to the second service
        VendorNo := FRLegalIdentifiers.FindVendor('', '', '', '', '', '', SecondService.Code, '0002:123456789');

        // [THEN] The selected-service participant wins
        Assert.AreEqual(SecondVendor."No.", VendorNo, 'Selected-service participant precedence must be retained.');
    end;

    [Test]
    procedure NameAddressFallbackMatchesUniqueVendor()
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Existing name/address matching remains available when no stronger identifier is present
        Initialize();

        // [GIVEN] A uniquely named vendor with an address
        CreateIdentifiedVendor(Vendor, '', '');
        Vendor.Name := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Vendor.Name));
        Vendor.Address := 'Unique matching address';
        Vendor.Modify();

        // [WHEN] Only name and address are supplied
        VendorNo := FRLegalIdentifiers.FindVendor('', '', '', '', Vendor.Name, Vendor.Address, '', '');

        // [THEN] The existing fallback finds the vendor
        Assert.AreEqual(Vendor."No.", VendorNo, 'Name/address fallback must remain available.');
    end;

    [Test]
    procedure AmbiguousNameAddressFallbackRequiresManualSelection()
    var
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] French matching does not silently accept the first fuzzy name/address candidate
        Initialize();

        // [GIVEN] Two vendors with identical names and addresses
        CreateIdentifiedVendor(FirstVendor, '', '');
        CreateIdentifiedVendor(SecondVendor, '', '');
        FirstVendor.Name := CopyStr(Format(CreateGuid()), 1, MaxStrLen(FirstVendor.Name));
        FirstVendor.Address := 'Shared matching address';
        FirstVendor.Modify();
        SecondVendor.Name := FirstVendor.Name;
        SecondVendor.Address := FirstVendor.Address;
        SecondVendor.Modify();

        // [WHEN] Only their common name and address are supplied
        asserterror FRLegalIdentifiers.FindVendor('', '', '', '', FirstVendor.Name, FirstVendor.Address, '', '');

        // [THEN] Ambiguity is reported rather than resolved by record order
        AssertIdentifierError('More than one vendor');
    end;

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

    local procedure CreateVendorParticipant(var Service: Record "E-Document Service"; VendorNo: Code[20]; Identifier: Text[200])
    var
        Participant: Record "Service Participant";
    begin
        Service.Code := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Service.Code));
        Service."Document Format" := Service."Document Format"::"Peppol BIS 3.0 FR";
        Service.Insert();
        Participant.Service := Service.Code;
        Participant."Participant Type" := Participant."Participant Type"::Vendor;
        Participant.Participant := VendorNo;
        Participant."Participant Identifier" := Identifier;
        Participant.Insert();
    end;

    local procedure CreateCountry(ISOCode: Code[2]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."ISO Code" := ISOCode;
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateIdentifiedVendor(var Vendor: Record Vendor; SIREN: Code[9]; LegacySIRET: Code[14])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CreateCountry('FR');
        Vendor."SIREN No." := SIREN;
        Vendor."Registration Number" := LegacySIRET;
        Vendor."VAT Registration No." := '';
        Vendor.GLN := '';
        Vendor.Modify();
    end;

    local procedure VerifyVendorIdentifiersUnchanged(var Vendor: Record Vendor; SIREN: Code[9]; RegistrationNumber: Text[50]; ModifiedAt: DateTime)
    begin
        Vendor.Get(Vendor."No.");
        Assert.AreEqual(SIREN, Vendor."SIREN No.", 'Matching must preserve SIREN.');
        Assert.AreEqual(RegistrationNumber, Vendor."Registration Number", 'Matching must preserve the existing registration SIRET.');
        Assert.AreEqual(ModifiedAt, Vendor.SystemModifiedAt, 'Matching must not write vendor master data.');
    end;

    local procedure VerifyAllReadersMatch(VendorNo: Code[20]; SIREN: Text; SIRET: Text)
    var
        EDocument: Record "E-Document";
        Header: Record "E-Document Purchase Header";
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        UBLReader: Codeunit "E-Doc. Peppol BIS 3.0 FR Hdlr";
        CIIReader: Codeunit "E-Document Factur-X Handler";
        LegacyUBL: Codeunit "PEPPOL BIS 3.0 FR Format";
        LegacyCII: Codeunit "Import Factur-X";
        Blob: Codeunit "Temp Blob";
        HeaderRef: RecordRef;
        LinesRef: RecordRef;
    begin
        CreateEDocument(EDocument);
        Blob := CreateIncomingBlob(true, SIREN, SIRET);
        UBLReader.ReadIntoDraft(EDocument, Blob);
        Header.GetFromEDocument(EDocument);
        Assert.AreEqual(VendorNo, Header."[BC] Vendor No.", 'Structured UBL must use canonical matching.');
        LegacyUBL.GetBasicInfoFromReceivedDocument(EDocument, Blob);
        Assert.AreEqual(VendorNo, EDocument."Bill-to/Pay-to No.", 'Legacy UBL must use canonical matching.');
        LegacyUBL.GetCompleteInfoFromReceivedDocument(EDocument, HeaderRef, LinesRef, Blob);
        HeaderRef.SetTable(TempPurchaseHeader);
        Assert.AreEqual(VendorNo, TempPurchaseHeader."Buy-from Vendor No.", 'Complete UBL import must retain the matched vendor.');

        CreateEDocument(EDocument);
        Blob := CreateIncomingBlob(false, SIREN, SIRET);
        CIIReader.ReadIntoDraft(EDocument, Blob);
        Header.GetFromEDocument(EDocument);
        Assert.AreEqual(VendorNo, Header."[BC] Vendor No.", 'Structured CII must use canonical matching.');
        LegacyCII.ParseBasicInfo(EDocument, Blob);
        Assert.AreEqual(VendorNo, EDocument."Bill-to/Pay-to No.", 'Legacy CII must use canonical matching.');
        Clear(TempPurchaseHeader);
        LegacyCII.ParseCompleteInfo(EDocument, TempPurchaseHeader, TempPurchaseLine, Blob);
        Assert.AreEqual(VendorNo, TempPurchaseHeader."Buy-from Vendor No.", 'Complete CII import must retain the matched vendor.');
    end;

    local procedure VerifyAllReadersReject(SIREN: Text; SIRET: Text; ExpectedError: Text)
    var
        EDocument: Record "E-Document";
        UBLReader: Codeunit "E-Doc. Peppol BIS 3.0 FR Hdlr";
        CIIReader: Codeunit "E-Document Factur-X Handler";
        LegacyUBL: Codeunit "PEPPOL BIS 3.0 FR Format";
        LegacyCII: Codeunit "Import Factur-X";
        Blob: Codeunit "Temp Blob";
    begin
        CreateEDocument(EDocument);
        Blob := CreateIncomingBlob(true, SIREN, SIRET);
        asserterror UBLReader.ReadIntoDraft(EDocument, Blob);
        AssertIdentifierError(ExpectedError);
        asserterror LegacyUBL.GetBasicInfoFromReceivedDocument(EDocument, Blob);
        AssertIdentifierError(ExpectedError);
        Blob := CreateIncomingBlob(false, SIREN, SIRET);
        asserterror CIIReader.ReadIntoDraft(EDocument, Blob);
        AssertIdentifierError(ExpectedError);
        asserterror LegacyCII.ParseBasicInfo(EDocument, Blob);
        AssertIdentifierError(ExpectedError);
    end;

    local procedure CreateIncomingBlob(IsUBL: Boolean; SIREN: Text; SIRET: Text): Codeunit "Temp Blob"
    var
        Document: XmlDocument;
        Namespaces: XmlNamespaceManager;
        Party: XmlNode;
        Anchor: XmlNode;
        Nodes: XmlNodeList;
        Node: XmlNode;
        Container: XmlElement;
        Identifier: XmlElement;
        Content: Text;
    begin
        if IsUBL then begin
            XmlDocument.ReadFrom(NavApp.GetResourceAsText(PeppolBIS30FRInvoiceTok, TextEncoding::UTF8), Document);
            Namespaces.AddNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
            Namespaces.AddNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
            Document.SelectSingleNode('/*/cac:AccountingSupplierParty/cac:Party', Namespaces, Party);
            Party.SelectNodes('cac:PartyIdentification[cbc:ID/@schemeID="0009"]|cac:PartyLegalEntity/cbc:CompanyID[@schemeID="0002"]', Namespaces, Nodes);
            foreach Node in Nodes do
                Node.Remove();
            if SIREN <> '' then begin
                Party.SelectSingleNode('cac:PartyLegalEntity', Namespaces, Anchor);
                Identifier := XmlElement.Create('CompanyID', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', SIREN);
                Identifier.SetAttribute('schemeID', '0002');
                Anchor.AsXmlElement().Add(Identifier);
            end;
            if SIRET <> '' then begin
                Container := XmlElement.Create('PartyIdentification', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
                Identifier := XmlElement.Create('ID', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', SIRET);
                Identifier.SetAttribute('schemeID', '0009');
                Container.Add(Identifier);
                Party.SelectSingleNode('cac:PartyName', Namespaces, Anchor);
                Anchor.AddBeforeSelf(Container);
            end;
        end else begin
            XmlDocument.ReadFrom(NavApp.GetResourceAsText(FacturXInvoiceTok, TextEncoding::UTF8), Document);
            Namespaces.AddNamespace('ram', 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');
            Document.SelectSingleNode('//ram:SellerTradeParty', Namespaces, Party);
            Party.SelectSingleNode('ram:Name', Namespaces, Anchor);
            if SIREN <> '' then begin
                Container := XmlElement.Create('SpecifiedLegalOrganization', 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');
                Identifier := XmlElement.Create('ID', 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', SIREN);
                Identifier.SetAttribute('schemeID', '0002');
                Container.Add(Identifier);
                Anchor.AddAfterSelf(Container);
            end;
            if SIRET <> '' then begin
                Identifier := XmlElement.Create('GlobalID', 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', SIRET);
                Identifier.SetAttribute('schemeID', '0009');
                Anchor.AddBeforeSelf(Identifier);
            end;
        end;
        Document.WriteTo(Content);
        exit(CreateBlob(Content));
    end;

    local procedure AssertIdentifierError(ExpectedError: Text)
    begin
        Assert.ExpectedError(ExpectedError);
        Assert.ExpectedErrorCode('Dialog');
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
