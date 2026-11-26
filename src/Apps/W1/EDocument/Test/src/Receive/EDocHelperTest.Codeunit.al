// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.eServices.EDocument.Format;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Registration;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;
using System.Utilities;

codeunit 139799 "E-Doc. Helper Test"
{
    Subtype = Test;
    Access = Internal;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        MultipleVendorsWithRegistrationNoErr: Label 'Multiple vendors match the registration number on the electronic document.';

    trigger OnRun()
    begin
        // [FEATURE] [E-Document]
    end;


    [Test]
    procedure ValidateLineDiscountTest()
    var
        EDocument: Record "E-Document";
        TempPurchaseLine: Record "Purchase Line" temporary;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        RecordRef: RecordRef;
    begin
        TempPurchaseLine."Direct Unit Cost" := 0.99;
        TempPurchaseLine.Amount := 0.88 * 5;
        TempPurchaseLine.Quantity := 5;

        RecordRef.GetTable(TempPurchaseLine);
        EDocumentImportHelper.ValidateLineDiscount(EDocument, RecordRef);
        RecordRef.SetTable(TempPurchaseLine);
        Assert.AreEqual(TempPurchaseLine."Line Discount Amount", 0.55, 'Line Discount Amount does not equal');
    end;


    [Test]
    procedure ValidateDonotFindVendor()
    var
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        VendorNo: Code[20];
    begin
        VendorNo := EDocumentImportHelper.FindVendor('', '', '');
        Assert.IsTrue(VendorNo = '', 'Vendor No. should be empty');
    end;

    [Test]
    procedure FindVendorByRegistrationNo()
    var
        Vendor: Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        LibraryUtility: Codeunit "Library - Utility";
        RegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 646793] A vendor can be resolved by Registration No. when other identifiers are unavailable.
        RegistrationNo := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(RegistrationNo));
        CreateVendorForLookup(Vendor);
        Vendor."Use Reg. No. in E-Document" := true;
        Vendor."Registration Number" := RegistrationNo;
        Vendor.Modify();

        Assert.AreEqual(Vendor."No.", EDocumentImportHelper.FindVendor('', '', '', RegistrationNo), 'Vendor should be matched by Registration No.');
    end;

    [Test]
    procedure DoesNotFindVendorByRegistrationNoWithoutSetup()
    var
        Vendor: Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        LibraryUtility: Codeunit "Library - Utility";
        RegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 646793] Registration No. matching requires explicit vendor setup.
        RegistrationNo := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(RegistrationNo));
        CreateVendorForLookup(Vendor);
        Vendor."Registration Number" := RegistrationNo;
        Vendor.Modify();

        Assert.AreEqual('', EDocumentImportHelper.FindVendor('', '', '', RegistrationNo), 'Vendor should not be matched by Registration No. without setup.');
    end;

    [Test]
    procedure ErrorsWhenMultipleVendorsMatchByRegistrationNo()
    var
        Vendor: array[2] of Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        LibraryUtility: Codeunit "Library - Utility";
        RegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 646793] Vendor matching fails when a registration number identifies multiple vendors.
        RegistrationNo := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(RegistrationNo));
        CreateVendorForLookup(Vendor[1]);
        Vendor[1]."Use Reg. No. in E-Document" := true;
        Vendor[1]."Registration Number" := RegistrationNo;
        Vendor[1].Modify();
        CreateVendorForLookup(Vendor[2]);
        Vendor[2]."Use Reg. No. in E-Document" := true;
        Vendor[2]."Registration Number" := RegistrationNo;
        Vendor[2].Modify();

        asserterror EDocumentImportHelper.FindVendor('', '', '', RegistrationNo);

        Assert.ExpectedError(MultipleVendorsWithRegistrationNoErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ValidateReceivingCompanyInfoWithMatchingServiceParticipant()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        ServiceParticipant: Record "Service Participant";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        TestParticipantId: Text[200];
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        // [SCENARIO] Validation should succeed when a matching Company Service Participant exists
        // [GIVEN] An E-Document with a Receiving Company Id
        TestParticipantId := '0208:1234567890';
        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument."Receiving Company Id" := TestParticipantId;
        EDocument."Receiving Company GLN" := '';
        EDocument."Receiving Company VAT Reg. No." := '';
        EDocument.Insert(true);

        // [GIVEN] An E-Document Service
        LibraryEDoc.CreateTestReceiveServiceForEDoc(EDocService, Enum::"Service Integration"::"Mock");

        // [GIVEN] A matching Company Service Participant
        ServiceParticipant.Init();
        ServiceParticipant.Service := EDocService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Company;
        ServiceParticipant.Participant := '';
        ServiceParticipant."Participant Identifier" := TestParticipantId;
        ServiceParticipant.Insert(true);

        // [WHEN] Validating receiving company info
        EDocumentImportHelper.ValidateReceivingCompanyInfo(EDocument, EDocService);

        // [THEN] No errors should be logged (validation should exit early due to Service Participant match)
        Assert.IsFalse(EDocErrorHelper.HasErrors(EDocument), 'No errors should be logged when Service Participant matches');

        // Cleanup
        ServiceParticipant.Delete();
        EDocument.Delete();
    end;

    [Test]
    procedure OpenDraftPageForOutgoingEDocumentOpensEDocumentCard()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        EDocumentHelper: Codeunit "E-Document Helper";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Drilling into an outgoing E-Document should open the E-Document card, regardless of the
        // configured Import Process, since outgoing documents have no draft staging data.
        LibraryLowerPermission.SetOutsideO365Scope();

        // [GIVEN] An E-Document Service using the "Version 2.0" import process
        EDocService.Get(LibraryEDoc.CreateService(Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"Mock", Enum::"E-Document Import Process"::"Version 2.0"));

        // [GIVEN] An outgoing E-Document linked to that service
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Service := EDocService.Code;
        EDocument.Insert(true);

        // [WHEN] Opening the draft page for the outgoing E-Document
        EDocumentPage.Trap();
        EDocumentHelper.OpenDraftPage(EDocument);

        // [THEN] The E-Document card is opened, not the E-Document Purchase Draft page
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), 'Expected the E-Document card to open for the outgoing E-Document.');

        // Cleanup
        EDocumentPage.Close();
        EDocument.Delete();
    end;

    [Test]
    procedure ValidateReceivingCompanyInfoFallsBackToVATWhenNoServiceParticipant()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        CompanyInformation: Record "Company Information";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        // [SCENARIO] Validation should fall back to VAT/GLN matching when no Service Participant exists
        // [GIVEN] An E-Document with a Receiving Company Id that doesn't match any Service Participant
        // [GIVEN] But has matching VAT Registration No.
        CompanyInformation.Get();

        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument."Receiving Company Id" := '0208:NOMATCH';
        EDocument."Receiving Company VAT Reg. No." := CompanyInformation."VAT Registration No.";
        EDocument."Receiving Company GLN" := '';
        EDocument.Insert(true);

        // [GIVEN] An E-Document Service with no matching Company Service Participant
        LibraryEDoc.CreateTestReceiveServiceForEDoc(EDocService, Enum::"Service Integration"::"Mock");

        // [WHEN] Validating receiving company info
        EDocumentImportHelper.ValidateReceivingCompanyInfo(EDocument, EDocService);

        // [THEN] No errors should be logged (validation should succeed via VAT matching)
        Assert.IsFalse(EDocErrorHelper.HasErrors(EDocument), 'No errors should be logged when VAT Registration No. matches');

        // Cleanup
        EDocument.Delete();
    end;

    [Test]
    procedure ValidateReceivingCompanyInfoIgnoresGLNWhenUseGLNIsDisabled()
    var
        EDocument: Record "E-Document";
        CompanyInformation: Record "Company Information";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        // [SCENARIO 650323] GLN is not validated when "Use GLN in Electronic Documents" is disabled in Company Information
        
        // [GIVEN] Company Information with GLN filled, VAT Registration No. filled and "Use GLN in Electronic Documents" = false
        CompanyInformation.Get();
        CompanyInformation.GLN := CopyStr(LibraryUtility.GenerateRandomNumericText(MaxStrLen(CompanyInformation.GLN)), 1, MaxStrLen(CompanyInformation.GLN));
        CompanyInformation."VAT Registration No." := CopyStr(LibraryUtility.GenerateRandomNumericText(MaxStrLen(CompanyInformation."VAT Registration No.")), 1, MaxStrLen(CompanyInformation."VAT Registration No."));
        CompanyInformation."Use GLN in Electronic Document" := false;
        CompanyInformation.Modify();

        // [GIVEN] An incoming E-Document with matching VAT Registration No. and no GLN
        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument."Receiving Company VAT Reg. No." := CompanyInformation."VAT Registration No.";
        EDocument."Receiving Company GLN" := '';
        EDocument.Insert(true);

        // [WHEN] Validating receiving company info
        EDocumentImportHelper.ValidateReceivingCompanyInfo(EDocument);

        // [THEN] No GLN mismatch error is logged
        Assert.IsFalse(EDocErrorHelper.HasErrors(EDocument), 'GLN must not be validated when "Use GLN in Electronic Documents" is disabled');

        // Cleanup
        EDocument.Delete();
    end;

    [Test]
    procedure ValidateReceivingCompanyInfoChecksGLNWhenUseGLNIsEnabled()
    var
        EDocument: Record "E-Document";
        CompanyInformation: Record "Company Information";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        // [SCENARIO 650323] GLN is validated when "Use GLN in Electronic Documents" is enabled in Company Information
        
        // [GIVEN] Company Information with GLN filled, VAT Registration No. filled and "Use GLN in Electronic Documents" = true
        CompanyInformation.Get();
        CompanyInformation.GLN := CopyStr(LibraryUtility.GenerateRandomNumericText(MaxStrLen(CompanyInformation.GLN)), 1, MaxStrLen(CompanyInformation.GLN));
        CompanyInformation."VAT Registration No." := CopyStr(LibraryUtility.GenerateRandomNumericText(MaxStrLen(CompanyInformation."VAT Registration No.")), 1, MaxStrLen(CompanyInformation."VAT Registration No."));
        CompanyInformation."Use GLN in Electronic Document" := true;
        CompanyInformation.Modify();

        // [GIVEN] An incoming E-Document with matching VAT Registration No. and no GLN
        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument."Receiving Company VAT Reg. No." := CompanyInformation."VAT Registration No.";
        EDocument."Receiving Company GLN" := '';
        EDocument.Insert(true);

        // [WHEN] Validating receiving company info
        EDocumentImportHelper.ValidateReceivingCompanyInfo(EDocument);

        // [THEN] GLN mismatch error is logged
        Assert.IsTrue(EDocErrorHelper.HasErrors(EDocument), 'GLN mismatch must be reported when "Use GLN in Electronic Documents" is enabled');

        // Cleanup
        EDocument.Delete();
    end;

    [Test]
    procedure FullLegalIdentityCoexistsWithVATAndGLN()
    var
        Vendor: Record Vendor;
        Helper: Codeunit "E-Document Import Helper";
    begin
        SetRegistrationFeatureEnabled(true);
        CreateLegalVendor(Vendor, 'NL');
        Vendor.GLN := '1234567890123';
        Vendor."VAT Registration No." := 'NL123456789B01';
        Vendor.Modify();

        Assert.AreEqual(Vendor."No.", Helper.FindVendorByLegalRegistrationNo(Vendor."Registration Number", 'NL'), 'A full-width legal identifier must coexist with VAT and GLN.');
        Assert.AreEqual(Vendor."No.", Helper.FindVendorWithLegalIdentity('', Vendor.GLN, Vendor."VAT Registration No.", Vendor."Registration Number", 'NL'), 'All identifiers must resolve to the same vendor.');
    end;

    [Test]
    procedure LegalIdentityRequiresOptInAndCompletedMigration()
    var
        Vendor: Record Vendor;
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        Feature: Codeunit "Registration No. Feature";
        Helper: Codeunit "E-Document Import Helper";
    begin
        SetRegistrationFeatureEnabled(false);
        CreateLegalVendor(Vendor, 'NL');
        Vendor."Registration Number" := CopyStr(Vendor."Registration Number", 1, 20);
        Vendor."VAT Registration No." := 'NL123456789B01';
        Vendor.Modify();
        Assert.AreEqual('', Helper.FindVendor('', '', '', CopyStr(Vendor."Registration Number", 1, 20)), 'The disabled feature must retain legacy matching.');

        SetRegistrationFeatureEnabled(true);
        FeatureDataUpdateStatus.Get(Feature.GetFeatureKey(), CompanyName());
        FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Pending;
        FeatureDataUpdateStatus.Modify();
        Assert.AreEqual('', Helper.FindVendor('', '', '', CopyStr(Vendor."Registration Number", 1, 20)), 'An incomplete company migration must retain legacy matching.');

        SetRegistrationFeatureEnabled(true);
        Vendor."Use Reg. No. in E-Document" := false;
        Vendor.Modify();
        Assert.AreEqual('', Helper.FindVendorByLegalRegistrationNo(Vendor."Registration Number", 'NL'), 'Legal matching must require explicit vendor opt-in.');
    end;

    [Test]
    procedure CountryDisambiguatesLegalRegistrationButMissingCountryDoesNot()
    var
        Vendor: array[2] of Record Vendor;
        CountryRegion: Record "Country/Region";
        Helper: Codeunit "E-Document Import Helper";
    begin
        SetRegistrationFeatureEnabled(true);
        CountryRegion.Init();
        CountryRegion.Code := 'REGNL';
        CountryRegion."ISO Code" := 'NL';
        CountryRegion.Insert();
        CreateLegalVendor(Vendor[1], CountryRegion.Code);
        CreateLegalVendor(Vendor[2], 'BE');
        Vendor[2]."Registration Number" := Vendor[1]."Registration Number";
        Vendor[2].Modify();

        Assert.AreEqual(Vendor[1]."No.", Helper.FindVendorByLegalRegistrationNo(Vendor[1]."Registration Number", 'NL'), 'An ISO code must match the corresponding local country code.');
        Assert.AreEqual(Vendor[2]."No.", Helper.FindVendorByLegalRegistrationNo(Vendor[1]."Registration Number", 'BE'), 'Country context must select the correct registration.');
        asserterror Helper.FindVendorByLegalRegistrationNo(Vendor[1]."Registration Number", '');
        Assert.ExpectedError(MultipleVendorsWithRegistrationNoErr);
    end;

    [Test]
    procedure ConflictingLegalAndTaxIdentitiesAreRejected()
    var
        Vendor: array[2] of Record Vendor;
        Helper: Codeunit "E-Document Import Helper";
    begin
        SetRegistrationFeatureEnabled(true);
        CreateLegalVendor(Vendor[1], 'NL');
        CreateLegalVendor(Vendor[2], 'NL');
        Vendor[1]."VAT Registration No." := 'NL123456789B01';
        Vendor[1].Modify();
        Vendor[2]."VAT Registration No." := 'NL987654321B01';
        Vendor[2].Modify();

        asserterror Helper.FindVendorWithLegalIdentity('', '', Vendor[2]."VAT Registration No.", Vendor[1]."Registration Number", 'NL');
        Assert.ExpectedError('conflict with vendor');
    end;

    [Test]
    procedure ExplicitVendorNumberCannotBypassCountryConflict()
    var
        Vendor: Record Vendor;
        Helper: Codeunit "E-Document Import Helper";
    begin
        SetRegistrationFeatureEnabled(true);
        CreateLegalVendor(Vendor, 'NL');

        asserterror Helper.FindVendorWithLegalIdentity(Vendor."No.", '', '', '', 'BE');
        Assert.ExpectedError('conflict with vendor');
    end;

    [Test]
    procedure EmptyNormalizedVATDoesNotIdentifyAVendor()
    var
        Vendor: Record Vendor;
        Helper: Codeunit "E-Document Import Helper";
    begin
        SetRegistrationFeatureEnabled(true);
        CreateLegalVendor(Vendor, 'NL');
        Vendor."VAT Registration No." := 'NL---';
        Vendor.Modify();

        Assert.AreEqual('', Helper.FindVendorWithLegalIdentity('', '', '---', '', 'NL'), 'Empty normalized VAT values must not identify a vendor.');
    end;

    [Test]
    procedure ConflictingParticipantAndLegalIdentitiesAreRejected()
    var
        Vendor: array[2] of Record Vendor;
        Header: Record "E-Document Purchase Header";
        Participant: Record "Service Participant";
        Helper: Codeunit "E-Document Import Helper";
    begin
        SetRegistrationFeatureEnabled(true);
        CreateLegalVendor(Vendor[1], 'NL');
        CreateLegalVendor(Vendor[2], 'NL');
        Header."Vendor Registration No." := Vendor[1]."Registration Number";
        Header."Vendor Reg. Country/Region" := 'NL';
        Header."Vendor External Id" := '0208:' + Vendor[2]."No.";
        Participant."Participant Type" := Participant."Participant Type"::Vendor;
        Participant.Participant := Vendor[2]."No.";
        Participant."Participant Identifier" := CopyStr(Header."Vendor External Id", 1, MaxStrLen(Participant."Participant Identifier"));
        Participant.Insert();

        asserterror Helper.FindVendorForIncomingIdentity(Header, '');
        Assert.ExpectedError('conflict with vendor');
    end;

    [Test]
    procedure ReceivingLegalIdentityIsCheckedAlongsideVATAndParticipant()
    var
        EDocument: Record "E-Document";
        Service: Record "E-Document Service";
        Participant: Record "Service Participant";
        CompanyInformation: Record "Company Information";
        Helper: Codeunit "E-Document Import Helper";
        ErrorHelper: Codeunit "E-Document Error Helper";
    begin
        SetRegistrationFeatureEnabled(true);
        CompanyInformation.Get();
        CompanyInformation."Registration No." := PadStr('Company 0012-/ ', 50, 'c');
        CompanyInformation."Use Reg. No. in E-Document" := true;
        CompanyInformation."Country/Region Code" := 'NL';
        CompanyInformation."VAT Registration No." := 'NL123456789B01';
        CompanyInformation.Modify();
        LibraryEDoc.CreateTestReceiveServiceForEDoc(Service, Enum::"Service Integration"::"Mock");
        EDocument."Receiving Company Reg. No." := CompanyInformation."Registration No.";
        EDocument."Receiving Reg. Country/Region" := 'NL';
        EDocument."Receiving Company VAT Reg. No." := CompanyInformation."VAT Registration No.";
        EDocument."Receiving Company Id" := '0208:COMPANY';
        EDocument.Insert(true);
        Participant.Service := Service.Code;
        Participant."Participant Type" := Participant."Participant Type"::Company;
        Participant."Participant Identifier" := EDocument."Receiving Company Id";
        Participant.Insert();

        Helper.ValidateReceivingCompanyInfo(EDocument, Service);
        Assert.IsFalse(ErrorHelper.HasErrors(EDocument), 'Matching legal and tax identities must be accepted together.');
        EDocument."Receiving Reg. Country/Region" := 'BE';
        Helper.ValidateReceivingCompanyInfo(EDocument, Service);
        Assert.IsTrue(ErrorHelper.HasErrors(EDocument), 'A participant match must not hide a conflicting legal identity.');
    end;

    [Test]
    procedure InvoiceKeepsLegalTaxAndPayeeIdentitiesSeparate()
    begin
        VerifyIncomingLegalParties(false);
    end;

    [Test]
    procedure CreditNoteKeepsLegalTaxAndPayeeIdentitiesSeparate()
    begin
        VerifyIncomingLegalParties(true);
    end;

    [Test]
    procedure IncomingLegalIdentifierIsNeverTruncated()
    var
        Vendor: Record Vendor;
        Header: Record "E-Document Purchase Header";
        Utility: Codeunit "E-Document PEPPOL Utility";
        Helper: Codeunit "E-Document Import Helper";
        XMLDocument: XmlDocument;
        Namespaces: XmlNamespaceManager;
    begin
        SetRegistrationFeatureEnabled(true);
        CreateLegalVendor(Vendor, 'NL');
        asserterror Helper.FindVendorByLegalRegistrationNo(PadStr(Vendor."Registration Number", 51, 'x'), 'NL');
        Assert.ExpectedError('exceeds the maximum length of 50');

        XmlDocument.ReadFrom(LegalPartyXML(false, PadStr(Vendor."Registration Number", 51, 'x')), XMLDocument);
        Utility.InitializePEPPOL3Namespaces(Namespaces);
        asserterror Utility.PopulateSupplierInfo(XMLDocument, Namespaces, '/inv:Invoice', Header);
        Assert.ExpectedError('exceeds the maximum length of 50');
    end;

    local procedure VerifyIncomingLegalParties(CreditNote: Boolean)
    var
        Vendor: Record Vendor;
        EDocument: Record "E-Document";
        Service: Record "E-Document Service";
        Header: Record "E-Document Purchase Header";
        LegacyImport: Codeunit "EDoc Import PEPPOL BIS 3.0";
        StructuredImport: Codeunit "E-Document PEPPOL Handler";
        Providers: Codeunit "E-Doc. Providers";
        Blob: Codeunit "Temp Blob";
        Stream: OutStream;
    begin
        SetRegistrationFeatureEnabled(true);
        CreateLegalVendor(Vendor, 'NL');
        Vendor."VAT Registration No." := 'NL123456789B01';
        Vendor.Modify();
        LibraryEDoc.CreateTestReceiveServiceForEDoc(Service, Enum::"Service Integration"::"Mock");
        EDocument.Service := Service.Code;
        EDocument.Direction := EDocument.Direction::Incoming;
        EDocument.Insert(true);
        Blob.CreateOutStream(Stream, TextEncoding::UTF8);
        Stream.WriteText(LegalPartyXML(CreditNote, Vendor."Registration Number"));

        LegacyImport.ParseBasicInfo(EDocument, Blob);
        Assert.AreEqual(Vendor."No.", EDocument."Bill-to/Pay-to No.", 'The legacy parser must resolve the supplier by its legal identity.');
        Assert.AreEqual(Vendor."Registration Number", EDocument."Supplier Registration No.", 'The legacy parser must retain all 50 characters.');
        Assert.AreEqual('0208', EDocument."Supplier Reg. Scheme", 'The legal identifier scheme must be retained.');
        Assert.AreEqual('Customer legal 0012-/ ', EDocument."Receiving Company Reg. No.", 'The customer legal identifier must be stored separately.');
        Assert.AreEqual('NL987654321B01', EDocument."Receiving Company VAT Reg. No.", 'Legal and endpoint identifiers must not overwrite VAT.');

        StructuredImport.ReadIntoDraft(EDocument, Blob);
        Header.Get(EDocument."Entry No");
        Assert.AreEqual(Vendor."Registration Number", Header."Vendor Registration No.", 'Structured import must retain the full legal identifier.');
        Assert.AreEqual('Supplier', Header."Vendor Company Name", 'A payee must not replace the accounting supplier.');
        Assert.AreEqual(Vendor."VAT Registration No.", Header."Vendor VAT Id", 'A payee legal identifier must not overwrite supplier VAT.');
        Assert.AreEqual('0208:SUPPLIER-ENDPOINT', Header."Vendor External Id", 'The endpoint identifier must remain separate.');
        Assert.AreEqual('Customer legal 0012-/ ', Header."Customer Registration No.", 'Customer legal identity must be separate from VAT.');
        Assert.AreEqual('0208:CUSTOMER-ENDPOINT', Header."Customer Company Id", 'Customer Company Id must retain its endpoint meaning.');
        Vendor := Providers.GetVendor(EDocument);
        Assert.AreEqual(EDocument."Bill-to/Pay-to No.", Vendor."No.", 'Both import paths must resolve the same supplier.');
    end;

    local procedure LegalPartyXML(CreditNote: Boolean; RegistrationNo: Text): Text
    var
        RootName: Text;
    begin
        RootName := 'Invoice';
        if CreditNote then
            RootName := 'CreditNote';
        exit(StrSubstNo(
            '<%1 xmlns="urn:oasis:names:specification:ubl:schema:xsd:%1-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">' +
            '<cbc:ID>LEGAL-INVOICE</cbc:ID><cbc:IssueDate>2026-11-26</cbc:IssueDate>' +
            '<cac:AccountingSupplierParty><cac:Party><cbc:EndpointID schemeID="0208">SUPPLIER-ENDPOINT</cbc:EndpointID><cac:PartyName><cbc:Name>Supplier</cbc:Name></cac:PartyName>' +
            '<cac:PostalAddress><cac:Country><cbc:IdentificationCode>NL</cbc:IdentificationCode></cac:Country></cac:PostalAddress>' +
            '<cac:PartyTaxScheme><cbc:CompanyID>NL123456789B01</cbc:CompanyID><cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme></cac:PartyTaxScheme>' +
            '<cac:PartyLegalEntity><cbc:CompanyID schemeID="0208">%2</cbc:CompanyID></cac:PartyLegalEntity></cac:Party></cac:AccountingSupplierParty>' +
            '<cac:AccountingCustomerParty><cac:Party><cbc:EndpointID schemeID="0208">CUSTOMER-ENDPOINT</cbc:EndpointID>' +
            '<cac:PostalAddress><cac:Country><cbc:IdentificationCode>NL</cbc:IdentificationCode></cac:Country></cac:PostalAddress>' +
            '<cac:PartyTaxScheme><cbc:CompanyID>NL987654321B01</cbc:CompanyID><cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme></cac:PartyTaxScheme>' +
            '<cac:PartyLegalEntity><cbc:CompanyID schemeID="0208">Customer legal 0012-/ </cbc:CompanyID></cac:PartyLegalEntity></cac:Party></cac:AccountingCustomerParty>' +
            '<cac:PayeeParty><cac:PartyName><cbc:Name>Different payee</cbc:Name></cac:PartyName><cac:PartyLegalEntity><cbc:CompanyID>PAYEE-LEGAL-NOT-VAT</cbc:CompanyID></cac:PartyLegalEntity></cac:PayeeParty>' +
            '<cac:LegalMonetaryTotal><cbc:TaxExclusiveAmount>0</cbc:TaxExclusiveAmount><cbc:PayableAmount>0</cbc:PayableAmount></cac:LegalMonetaryTotal></%1>', RootName, RegistrationNo));
    end;

    local procedure CreateLegalVendor(var Vendor: Record Vendor; CountryCode: Code[10])
    var
        Utility: Codeunit "Library - Utility";
    begin
        CreateVendorForLookup(Vendor);
        Vendor."Registration Number" := PadStr(Utility.GenerateGUID() + ' Ab /- ', 50, 'r');
        Vendor."Country/Region Code" := CountryCode;
        Vendor."Use Reg. No. in E-Document" := true;
        Vendor.Modify();
    end;

    local procedure SetRegistrationFeatureEnabled(Enabled: Boolean)
    begin
        LibraryEDoc.SetRegistrationFeatureEnabled(Enabled);
    end;

    local procedure CreateVendorForLookup(var Vendor: Record Vendor)
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        Vendor.Init();
        Vendor."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Vendor."No."));
        Vendor.Insert();
    end;

}