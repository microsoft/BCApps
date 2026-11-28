// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Registration;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.Environment.Configuration;

codeunit 139935 "Registration No. Foundation"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        RegistrationNoMgt: Codeunit "Registration No. Mgt.";
        AppendLegacyCompanySuffix: Boolean;
        ExportRegistrationRequired: Boolean;
        ExportSchemeRequired: Boolean;
        ExportScheme: Text;
        ExportMaximumLength: Integer;

    [Test]
    procedure MastersPreserveFiftyCharacters()
    var
        Customer: Record Customer temporary;
        Vendor: Record Vendor temporary;
        Contact: Record Contact temporary;
        CompanyInformation: Record "Company Information" temporary;
        RegistrationNo: Text[50];
    begin
        SetFeatureEnabled(true);
        RegistrationNo := PadStr('Ab 0012-/ ', 50, 'x');

        Customer.Validate("Registration Number", RegistrationNo);
        Vendor.Validate("Registration Number", RegistrationNo);
        Contact.Validate("Registration Number", RegistrationNo);
        CompanyInformation.Validate("Registration Number", RegistrationNo);

        Assert.AreEqual(RegistrationNo, Customer."Registration Number", 'Customer registration number was changed.');
        Assert.AreEqual(RegistrationNo, Vendor."Registration Number", 'Vendor registration number was changed.');
        Assert.AreEqual(RegistrationNo, Contact."Registration Number", 'Contact registration number was changed.');
        Assert.AreEqual(RegistrationNo, CompanyInformation."Registration Number", 'Company registration number was changed.');
        Assert.AreEqual(RegistrationNo, Customer.GetRegistrationNumber(), 'The customer getter must preserve the current value.');
        Assert.AreEqual(RegistrationNo, Vendor.GetRegistrationNumber(), 'The vendor getter must preserve the current value.');
        Assert.AreEqual(RegistrationNo, Contact.GetRegistrationNumber(), 'The contact getter must preserve the current value.');
    end;

    [Test]
    procedure CompanyRegistrationFieldsRemainIndependent()
    var
        CompanyInformation: Record "Company Information" temporary;
        LegacyRegistrationNo: Text;
        RegistrationNo: Text[50];
    begin
        SetFeatureEnabled(false);
        CompanyInformation."Registration No." := 'LEGACY 0012-/';
        LegacyRegistrationNo := CompanyInformation.GetRegistrationNumber();
        RegistrationNo := PadStr('Global 0012-/ ', 50, 'x');

        CompanyInformation.Validate("Registration Number", RegistrationNo);

        CompanyInformation.TestField("Registration No.", 'LEGACY 0012-/');
        CompanyInformation.TestField("Registration Number", RegistrationNo);
        Assert.AreEqual(LegacyRegistrationNo, CompanyInformation.GetRegistrationNumber(), 'The disabled feature must retain the legacy company identity.');

        SetFeatureEnabled(true);

        Assert.AreEqual(RegistrationNo, CompanyInformation.GetRegistrationNumber(), 'The enabled feature must use the separate 50-character company field.');
        CompanyInformation.TestField("Registration No.", 'LEGACY 0012-/');
    end;

    [Test]
    procedure CompanyLegacyRegistrationRequiresExplicitMigration()
    var
        CompanyInformation: Record "Company Information";
        Migration: Record "Registration No. Migration";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        RegistrationNoFeature: Codeunit "Registration No. Feature";
    begin
        SetFeatureEnabled(false);
        CompanyInformation.Get();
        CompanyInformation."Registration No." := 'LEGACY 0012-/';
        CompanyInformation."Registration Number" := '';
        CompanyInformation.Modify(false);

        RegistrationNoFeature.RefreshMigration();

        Migration.Get(CompanyInformation.RecordId);
        Assert.AreEqual(Migration.Resolution::Pending, Migration.Resolution, 'A legacy company number must require an explicit migration decision.');
        Migration.ModifyAll(Resolution, Migration.Resolution::"Keep W1");
        Migration.Get(CompanyInformation.RecordId);
        Migration.Resolution := Migration.Resolution::"Use Local";
        Migration.Modify();
        FeatureDataUpdateStatus."Feature Key" := RegistrationNoFeature.GetFeatureKey();
        FeatureDataUpdateStatus."Task Id" := CreateGuid();

        RegistrationNoFeature.UpdateData(FeatureDataUpdateStatus);

        CompanyInformation.Get();
        CompanyInformation.TestField("Registration Number", Migration."Local Registration No.");
        CompanyInformation.TestField("Registration No.", 'LEGACY 0012-/');
    end;

    [Test]
    procedure MasterGettersResolveWithoutChangingStorage()
    var
        Customer: Record Customer temporary;
        Vendor: Record Vendor temporary;
        Contact: Record Contact temporary;
        CompanyInformation: Record "Company Information" temporary;
        RegistrationNoFoundation: Codeunit "Registration No. Foundation";
        StoredRegistrationNo: Text[50];
        ResolvedRegistrationNo: Text[50];
        CompanyRegistrationNo: Text;
    begin
        SetFeatureEnabled(true);
        StoredRegistrationNo := PadStr('Stored 0012-/ ', 50, 's');
        ResolvedRegistrationNo := PadStr('Resolved 0012-/ ', 50, 'r');
        Customer."Registration Number" := StoredRegistrationNo;
        Customer."Country/Region Code" := 'ZZ';
        Vendor."Registration Number" := StoredRegistrationNo;
        Vendor."Country/Region Code" := 'ZZ';
        Contact."Registration Number" := StoredRegistrationNo;
        Contact."Country/Region Code" := 'ZZ';
        CompanyInformation."Registration Number" := StoredRegistrationNo;
        CompanyInformation."Country/Region Code" := 'ZZ';
        RegistrationNoFoundation.SetAppendLegacyCompanySuffix(true);
        BindSubscription(RegistrationNoFoundation);

        Assert.AreEqual(ResolvedRegistrationNo, Customer.GetRegistrationNumber(), 'The customer must use the shared resolver.');
        Assert.AreEqual(ResolvedRegistrationNo, Vendor.GetRegistrationNumber(), 'The vendor must use the shared resolver.');
        Assert.AreEqual(ResolvedRegistrationNo, Contact.GetRegistrationNumber(), 'The contact must use the shared resolver.');
        CompanyRegistrationNo := CompanyInformation.GetRegistrationNumber();
        Assert.AreEqual(
            ResolvedRegistrationNo, CopyStr(CompanyRegistrationNo, 1, StrLen(ResolvedRegistrationNo)),
            'The company must use the shared resolver before its existing local after-get behavior.');
        if CompanyRegistrationNo <> ResolvedRegistrationNo then
            Assert.AreEqual(
                ResolvedRegistrationNo + ' legacy suffix', CompanyRegistrationNo,
                'The existing company event must still support more than 50 characters.');
        Assert.AreEqual(StoredRegistrationNo, Customer."Registration Number", 'Resolving must not change customer storage.');
        Assert.AreEqual(StoredRegistrationNo, Vendor."Registration Number", 'Resolving must not change vendor storage.');
        Assert.AreEqual(StoredRegistrationNo, Contact."Registration Number", 'Resolving must not change contact storage.');
        Assert.AreEqual(StoredRegistrationNo, CompanyInformation."Registration Number", 'Resolving must not change company storage.');

        UnbindSubscription(RegistrationNoFoundation);
    end;

    [Test]
    procedure DocumentGettersPreserveStoredAndBlankSnapshots()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
        PurchInvHeader: Record "Purch. Inv. Header" temporary;
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr." temporary;
        RegistrationNoFoundation: Codeunit "Registration No. Foundation";
        SnapshotRegistrationNo: Text[50];
    begin
        SetFeatureEnabled(true);
        CreateCustomer(Customer, 'ZZ', PadStr('Stored 0012-/ ', 50, 's'));
        BindSubscription(RegistrationNoFoundation);
        SnapshotRegistrationNo := Customer.GetRegistrationNumber();
        SalesHeader."Sell-to Customer No." := Customer."No.";
        SalesHeader."Bill-to Customer No." := Customer."No.";
        SalesHeader."Registration Number" := SnapshotRegistrationNo;
        SalesInvoiceHeader."Sell-to Customer No." := Customer."No.";
        SalesInvoiceHeader."Bill-to Customer No." := Customer."No.";
        SalesInvoiceHeader."Registration Number" := SnapshotRegistrationNo;
        SalesCrMemoHeader."Sell-to Customer No." := Customer."No.";
        SalesCrMemoHeader."Bill-to Customer No." := Customer."No.";
        SalesCrMemoHeader."Registration Number" := SnapshotRegistrationNo;

        Customer."Registration Number" := 'Changed after the snapshot';
        Customer.Modify(false);

        Assert.AreEqual(SnapshotRegistrationNo, SalesHeader.GetRegistrationNumber(), 'The sales document must use its snapshot.');
        Assert.AreEqual(SnapshotRegistrationNo, SalesInvoiceHeader.GetRegistrationNumber(), 'The invoice must use its snapshot.');
        Assert.AreEqual(SnapshotRegistrationNo, SalesCrMemoHeader.GetRegistrationNumber(), 'The credit memo must use its snapshot.');

        SalesHeader."Registration Number" := '';
        SalesInvoiceHeader."Registration Number" := '';
        SalesCrMemoHeader."Registration Number" := '';

        Assert.AreEqual('', SalesHeader.GetRegistrationNumber(), 'A blank document snapshot must not resolve current master data.');
        Assert.AreEqual('', SalesInvoiceHeader.GetRegistrationNumber(), 'A blank invoice snapshot must not resolve current master data.');
        Assert.AreEqual('', SalesCrMemoHeader.GetRegistrationNumber(), 'A blank credit memo snapshot must not resolve current master data.');
        Assert.AreEqual('', SalesInvoiceHeader.GetCompanyRegistrationNumber(), 'A missing invoice company snapshot must remain blank.');
        Assert.AreEqual('', SalesCrMemoHeader.GetCompanyRegistrationNumber(), 'A missing credit memo company snapshot must remain blank.');
        Assert.AreEqual('', PurchInvHeader.GetCompanyRegistrationNumber(), 'A missing purchase invoice company snapshot must remain blank.');
        Assert.AreEqual('', PurchCrMemoHeader.GetCompanyRegistrationNumber(), 'A missing purchase credit memo company snapshot must remain blank.');

        UnbindSubscription(RegistrationNoFoundation);
    end;

    [Test]
    procedure PostingTransferPreservesRegistrationRolesAndWidths()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
        SalesShipmentHeader: Record "Sales Shipment Header" temporary;
        ReturnReceiptHeader: Record "Return Receipt Header" temporary;
        PurchaseHeader: Record "Purchase Header" temporary;
        PurchInvHeader: Record "Purch. Inv. Header" temporary;
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr." temporary;
        PurchRcptHeader: Record "Purch. Rcpt. Header" temporary;
        ReturnShipmentHeader: Record "Return Shipment Header" temporary;
        RegistrationNoFoundation: Codeunit "Registration No. Foundation";
    begin
        SetFeatureEnabled(true);
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := 'ZZ';
        CompanyInformation.Modify(false);
        SalesHeader."Registration Number" := PadStr('Counterparty 0012-/ ', 50, 'n');
        SalesHeader."Registration Country/Region" := 'AA';
        PurchaseHeader."Registration Number" := SalesHeader."Registration Number";
        PurchaseHeader."Registration Country/Region" := SalesHeader."Registration Country/Region";
        BindSubscription(RegistrationNoFoundation);

        SalesInvoiceHeader.TransferFields(SalesHeader);
        SalesInvoiceHeader.InitCompanyRegistrationSnapshot();
        SalesCrMemoHeader.TransferFields(SalesHeader);
        SalesCrMemoHeader.InitCompanyRegistrationSnapshot();
        SalesShipmentHeader.TransferFields(SalesHeader);
        SalesShipmentHeader.InitCompanyRegistrationSnapshot();
        ReturnReceiptHeader.TransferFields(SalesHeader);
        ReturnReceiptHeader.InitCompanyRegistrationSnapshot();
        PurchInvHeader.TransferFields(PurchaseHeader);
        PurchInvHeader.InitCompanyRegistrationSnapshot();
        PurchCrMemoHeader.TransferFields(PurchaseHeader);
        PurchCrMemoHeader.InitCompanyRegistrationSnapshot();
        PurchRcptHeader.TransferFields(PurchaseHeader);
        PurchRcptHeader.InitCompanyRegistrationSnapshot();
        ReturnShipmentHeader.TransferFields(PurchaseHeader);
        ReturnShipmentHeader.InitCompanyRegistrationSnapshot();

        AssertPostedRegistrationSnapshot(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Registration Number"));
        AssertPostedRegistrationSnapshot(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Registration Number"));
        AssertPostedRegistrationSnapshot(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Registration Number"));
        AssertPostedRegistrationSnapshot(ReturnReceiptHeader, ReturnReceiptHeader.FieldNo("Registration Number"));
        AssertPostedRegistrationSnapshot(PurchInvHeader, PurchInvHeader.FieldNo("Registration Number"));
        AssertPostedRegistrationSnapshot(PurchCrMemoHeader, PurchCrMemoHeader.FieldNo("Registration Number"));
        AssertPostedRegistrationSnapshot(PurchRcptHeader, PurchRcptHeader.FieldNo("Registration Number"));
        AssertPostedRegistrationSnapshot(ReturnShipmentHeader, ReturnShipmentHeader.FieldNo("Registration Number"));
        UnbindSubscription(RegistrationNoFoundation);

        CompanyInformation."Registration Number" := 'Changed after posting';
        CompanyInformation."Country/Region Code" := 'YY';
        CompanyInformation.Modify(false);
        Assert.AreEqual(PadStr('Resolved 0012-/ ', 50, 'r'), SalesInvoiceHeader.GetCompanyRegistrationNumber(), 'The invoice must not reread company data.');
        Assert.AreEqual('ZZ', SalesInvoiceHeader.GetCompanyRegistrationCountryCode(), 'The invoice company country must remain frozen.');
        Assert.AreEqual(PadStr('Resolved 0012-/ ', 50, 'r'), PurchInvHeader.GetCompanyRegistrationNumber(), 'The purchase invoice must not reread company data.');
        Assert.AreEqual('ZZ', PurchInvHeader.GetCompanyRegistrationCountryCode(), 'The purchase invoice company country must remain frozen.');
    end;

    [Test]
    procedure ArchivesFreezeBothRegistrationParties()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
        RegistrationNoFoundation: Codeunit "Registration No. Foundation";
    begin
        SetFeatureEnabled(true);
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := 'ZZ';
        CompanyInformation.Modify(false);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), Database::"Sales Header");
        SalesHeader."Registration Number" := PadStr('Counterparty 0012-/ ', 50, 'n');
        SalesHeader."Registration Country/Region" := 'AA';
        SalesHeader."Bill-to Registration No." := PadStr('Bill-to 0012-/ ', 50, 'b');
        SalesHeader."Bill-to Reg. Country/Region" := 'BB';
        SalesHeader.Insert(false);
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("No."), Database::"Purchase Header");
        PurchaseHeader."Registration Number" := SalesHeader."Registration Number";
        PurchaseHeader."Registration Country/Region" := SalesHeader."Registration Country/Region";
        PurchaseHeader.Insert(false);
        BindSubscription(RegistrationNoFoundation);

        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);
        UnbindSubscription(RegistrationNoFoundation);

        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst();
        CompanyInformation."Registration Number" := 'Changed after archiving';
        CompanyInformation."Country/Region Code" := 'YY';
        CompanyInformation.Modify(false);

        Assert.AreEqual(SalesHeader."Registration Number", SalesHeaderArchive.GetRegistrationNumber(), 'Archiving must retain all 50 customer characters.');
        Assert.AreEqual('AA', SalesHeaderArchive.GetRegistrationCountryCode(), 'The archived customer country must remain frozen.');
        Assert.AreEqual(SalesHeader."Bill-to Registration No.", SalesHeaderArchive."Bill-to Registration No.", 'Archiving must retain the separate bill-to legal number.');
        Assert.AreEqual('BB', SalesHeaderArchive."Bill-to Reg. Country/Region", 'Archiving must retain the bill-to country.');
        Assert.AreEqual(PurchaseHeader."Registration Number", PurchaseHeaderArchive.GetRegistrationNumber(), 'Archiving must retain all 50 vendor characters.');
        Assert.AreEqual('AA', PurchaseHeaderArchive.GetRegistrationCountryCode(), 'The archived vendor country must remain frozen.');
        Assert.AreEqual(PadStr('Resolved 0012-/ ', 50, 'r'), SalesHeaderArchive.GetCompanyRegistrationNumber(), 'The sales archive must use its company snapshot.');
        Assert.AreEqual('ZZ', SalesHeaderArchive.GetCompanyRegistrationCountryCode(), 'The sales archive company country must remain frozen.');
        Assert.AreEqual(PadStr('Resolved 0012-/ ', 50, 'r'), PurchaseHeaderArchive.GetCompanyRegistrationNumber(), 'The purchase archive must use its company snapshot.');
        Assert.AreEqual('ZZ', PurchaseHeaderArchive.GetCompanyRegistrationCountryCode(), 'The purchase archive company country must remain frozen.');
    end;

    [Test]
    procedure BillToRegistrationSnapshotDoesNotReplaceSellTo()
    var
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        SalesHeaderArchive: Record "Sales Header Archive" temporary;
        BillToRegistrationNo: Text[50];
    begin
        SetFeatureEnabled(true);
        LibrarySales.CreateCustomer(SellToCustomer);
        LibrarySales.CreateCustomer(BillToCustomer);
        SellToCustomer."Registration Number" := 'SELL-TO LEGAL';
        SellToCustomer.Modify();
        BillToRegistrationNo := PadStr('Bill-to 0012-/ ', 50, 'b');
        BillToCustomer."Registration Number" := BillToRegistrationNo;
        BillToCustomer.Modify();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SellToCustomer."No.");

        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        BillToCustomer."Registration Number" := 'Changed after capture';
        BillToCustomer.Modify();
        SalesInvoiceHeader.TransferFields(SalesHeader);
        SalesHeaderArchive.TransferFields(SalesHeader);

        Assert.AreEqual('SELL-TO LEGAL', SalesHeader.GetRegistrationNumber(), 'The existing snapshot must remain sell-to.');
        Assert.AreEqual(BillToRegistrationNo, SalesHeader."Bill-to Registration No.", 'Billing validation must capture the bill-to legal identity.');
        Assert.AreEqual(BillToCustomer."Country/Region Code", SalesHeader."Bill-to Reg. Country/Region", 'Billing validation must capture the bill-to country.');
        Assert.AreEqual(BillToRegistrationNo, SalesInvoiceHeader."Bill-to Registration No.", 'Posting transfer must preserve the bill-to snapshot.');
        Assert.AreEqual(BillToRegistrationNo, SalesHeaderArchive."Bill-to Registration No.", 'Archiving transfer must preserve the bill-to snapshot.');
    end;

    [Test]
    procedure ExportUsesOriginalDocumentAndExplicitPartyRoles()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        PurchInvHeader: Record "Purch. Inv. Header" temporary;
        RegistrationNoExport: Codeunit "Registration No. Export";
        Document: RecordRef;
        Identifier: Text;
        SchemeID: Text;
    begin
        SetFeatureEnabled(true);
        SalesInvoiceHeader."Registration Number" := 'SELL-TO';
        SalesInvoiceHeader."Bill-to Registration No." := PadStr('BILL-TO /- ', 50, 'b');
        SalesInvoiceHeader."Company Registration No." := 'SALES COMPANY SNAPSHOT';
        Document.GetTable(SalesInvoiceHeader);
        RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::"Sales Bill-to", '', Identifier, SchemeID);
        Assert.AreEqual(SalesInvoiceHeader."Bill-to Registration No.", Identifier, 'BT-47 must use bill-to, not sell-to.');
        RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::Company, '', Identifier, SchemeID);
        Assert.AreEqual(SalesInvoiceHeader."Company Registration No.", Identifier, 'BT-30 must use the original company snapshot.');

        PurchInvHeader."Registration Number" := PadStr('BUY-FROM /- ', 50, 'v');
        PurchInvHeader."Company Registration No." := 'PURCHASE COMPANY SNAPSHOT';
        Document.GetTable(PurchInvHeader);
        RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::"Purchase Buy-from", '', Identifier, SchemeID);
        Assert.AreEqual(PurchInvHeader."Registration Number", Identifier, 'A self-billed seller is buy-from, not the company or pay-to.');
        RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::Company, '', Identifier, SchemeID);
        Assert.AreEqual(PurchInvHeader."Company Registration No.", Identifier, 'A self-billed buyer is the company.');
    end;

    [Test]
    procedure ExportOmitsMissingHistoricalSnapshotsAndHonorsMandatoryProfiles()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        CompanyInformation: Record "Company Information";
        RegistrationNoFoundation: Codeunit "Registration No. Foundation";
        RegistrationNoExport: Codeunit "Registration No. Export";
        Document: RecordRef;
        Identifier: Text;
        SchemeID: Text;
    begin
        SetFeatureEnabled(true);
        CompanyInformation.Get();
        CompanyInformation."Registration Number" := 'TODAYS COMPANY';
        CompanyInformation.Modify();
        SalesInvoiceHeader."Registration Number" := 'HISTORICAL SELL-TO';
        Document.GetTable(SalesInvoiceHeader);
        Identifier := 'LEGACY VAT';
        SchemeID := 'VAT SCHEME';
        RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::Company, '', Identifier, SchemeID);
        Assert.AreEqual('', Identifier, 'A historical company snapshot must not be backfilled.');
        Assert.AreEqual('', SchemeID, 'An omitted identifier must not retain a VAT scheme.');
        RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::"Sales Bill-to", '', Identifier, SchemeID);
        Assert.AreEqual('', Identifier, 'A missing bill-to snapshot must not reuse sell-to.');

        RegistrationNoFoundation.SetExportPolicy(true, false, '', 50);
        BindSubscription(RegistrationNoFoundation);
        asserterror RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::Company, 'REGISTRATION-TEST', Identifier, SchemeID);
        Assert.ExpectedError('legal registration snapshot is missing');
        UnbindSubscription(RegistrationNoFoundation);
    end;

    [Test]
    procedure ExportRegistrySchemeAndLengthComeFromTheProfile()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        RegistrationNoFoundation: Codeunit "Registration No. Foundation";
        RegistrationNoExport: Codeunit "Registration No. Export";
        Document: RecordRef;
        Identifier: Text;
        SchemeID: Text;
    begin
        SetFeatureEnabled(true);
        SalesInvoiceHeader."Bill-to Registration No." := PadStr('Raw 0012-/ ', 50, 'r');
        Document.GetTable(SalesInvoiceHeader);
        RegistrationNoFoundation.SetExportPolicy(false, true, '0208', 50);
        BindSubscription(RegistrationNoFoundation);
        RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::"Sales Bill-to", 'REGISTRATION-TEST', Identifier, SchemeID);
        Assert.AreEqual(SalesInvoiceHeader."Bill-to Registration No.", Identifier, 'Export must preserve the original representation.');
        Assert.AreEqual('0208', SchemeID, 'Only the profile/registry resolver may select a legal scheme.');
        RegistrationNoFoundation.SetExportPolicy(false, true, '0208', 20);
        asserterror RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::"Sales Bill-to", 'REGISTRATION-TEST', Identifier, SchemeID);
        Assert.ExpectedError('exceeds the maximum length of 20');
        UnbindSubscription(RegistrationNoFoundation);
    end;

    [Test]
    procedure ExportRetainsLegacyValuesWhenFeatureDisabled()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        RegistrationNoExport: Codeunit "Registration No. Export";
        Document: RecordRef;
        Identifier: Text;
        SchemeID: Text;
    begin
        SetFeatureEnabled(false);
        SalesInvoiceHeader."Bill-to Registration No." := 'NEW SNAPSHOT';
        Document.GetTable(SalesInvoiceHeader);
        Identifier := 'LEGACY VAT';
        SchemeID := 'LEGACY SCHEME';

        RegistrationNoExport.ApplyLegalIdentity(Document, "Registration No. Party Role"::"Sales Bill-to", '', Identifier, SchemeID);

        Assert.AreEqual('LEGACY VAT', Identifier, 'The disabled feature must preserve provider behavior.');
        Assert.AreEqual('LEGACY SCHEME', SchemeID, 'The disabled feature must preserve the existing scheme.');
    end;

    procedure SetExportPolicy(RegistrationRequired: Boolean; SchemeRequired: Boolean; SchemeID: Text; MaximumLength: Integer)
    begin
        ExportRegistrationRequired := RegistrationRequired;
        ExportSchemeRequired := SchemeRequired;
        ExportScheme := SchemeID;
        ExportMaximumLength := MaximumLength;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Registration No. Export", 'OnResolveProfileRequirements', '', false, false)]
    local procedure ResolveExportPolicy(Document: RecordRef; PartyRole: Enum "Registration No. Party Role"; Profile: Text; RegistrationNo: Text[50]; CountryCode: Code[10]; var SchemeID: Text; var RegistrationRequired: Boolean; var SchemeRequired: Boolean; var MaximumLength: Integer)
    begin
        if Profile <> 'REGISTRATION-TEST' then
            exit;
        SchemeID := ExportScheme;
        RegistrationRequired := ExportRegistrationRequired;
        SchemeRequired := ExportSchemeRequired;
        MaximumLength := ExportMaximumLength;
    end;

    [Test]
    procedure MasksSupportUnicodeAndEscapedLiterals()
    var
        UnicodeLetter: Char;
        UnicodeDigit: Char;
    begin
        SetFeatureEnabled(true);
        UnicodeLetter := 233;
        UnicodeDigit := 1633;

        Assert.IsTrue(RegistrationNoMgt.MatchesFormat(Format(UnicodeLetter) + 'b 0012-/', '@@ ####-?'), 'Unicode letters and separators must match.');
        Assert.IsTrue(RegistrationNoMgt.MatchesFormat('#@?\', '\#\@\?\\'), 'Escaped placeholders must be literal characters.');
        Assert.IsFalse(RegistrationNoMgt.MatchesFormat('ab12', 'Ab##'), 'Literal characters must be case-sensitive.');
        Assert.IsFalse(RegistrationNoMgt.MatchesFormat('00123', '####'), 'A pattern must match the complete identifier.');
        Assert.IsFalse(RegistrationNoMgt.MatchesFormat(Format(UnicodeDigit), '#'), 'The digit placeholder must accept ASCII digits only.');

        asserterror RegistrationNoMgt.ValidateFormat('@@\');
        Assert.ExpectedError('must not end with an unescaped backslash');
    end;

    [Test]
    procedure AnyConfiguredFormatMayMatch()
    var
        CountryRegion: Record "Country/Region";
        SourceRecordId: RecordId;
    begin
        SetFeatureEnabled(true);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CreateFormat(CountryRegion.Code, 10000, '####');
        CreateFormat(CountryRegion.Code, 20000, '@@ ####');

        RegistrationNoMgt.ValidateRegistrationNo('0012', CountryRegion.Code, SourceRecordId);
        RegistrationNoMgt.ValidateRegistrationNo('Ab 0012', CountryRegion.Code, SourceRecordId);
        RegistrationNoMgt.ValidateRegistrationNo('', CountryRegion.Code, SourceRecordId);

        asserterror RegistrationNoMgt.ValidateRegistrationNo('Ab-0012', CountryRegion.Code, SourceRecordId);
        Assert.ExpectedError('does not match an accepted format');
    end;

    [Test]
    procedure BlankCountryDoesNotUseCompanyFormats()
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
        SourceRecordId: RecordId;
    begin
        SetFeatureEnabled(true);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryRegion.Code;
        CompanyInformation.Modify(false);
        CreateFormat(CountryRegion.Code, 10000, '####');

        RegistrationNoMgt.ValidateRegistrationNo('Ab-0012', '', SourceRecordId);
    end;

    [Test]
    procedure CountryChangeRevalidatesRegistrationNumber()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer temporary;
    begin
        SetFeatureEnabled(true);
        Customer.Validate("Registration Number", 'Ab 0012');
        LibraryERM.CreateCountryRegion(CountryRegion);
        CreateFormat(CountryRegion.Code, 10000, '####');

        asserterror Customer.Validate("Country/Region Code", CountryRegion.Code);
        Assert.ExpectedError('does not match an accepted format');
    end;

    [Test]
    procedure DuplicateDiscoveryUsesCompleteNumberAndCountry()
    var
        CountryRegion: Record "Country/Region";
        OtherCountryRegion: Record "Country/Region";
        SourceCustomer: Record Customer;
        MatchingCustomer: Record Customer;
        DifferentNumberCustomer: Record Customer;
        ForeignCustomer: Record Customer;
        Duplicates: List of [RecordId];
        RegistrationNo: Text[50];
    begin
        SetFeatureEnabled(true);
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryERM.CreateCountryRegion(OtherCountryRegion);
        RegistrationNo := PadStr('0012-ab/ ', 49, 'x') + 'A';
        CreateCustomer(SourceCustomer, CountryRegion.Code, RegistrationNo);
        CreateCustomer(MatchingCustomer, CountryRegion.Code, RegistrationNo);
        CreateCustomer(DifferentNumberCustomer, CountryRegion.Code, CopyStr(RegistrationNo, 1, 49) + 'B');
        CreateCustomer(ForeignCustomer, OtherCountryRegion.Code, RegistrationNo);

        RegistrationNoMgt.FindDuplicates(RegistrationNo, CountryRegion.Code, SourceCustomer.RecordId, Duplicates);

        Assert.AreEqual(1, Duplicates.Count(), 'Only a complete number in the same country must match.');
        Assert.IsTrue(Duplicates.Contains(MatchingCustomer.RecordId), 'The matching customer was not returned.');

        RegistrationNoMgt.FindDuplicates(RegistrationNo, '', SourceCustomer.RecordId, Duplicates);
        Assert.AreEqual(0, Duplicates.Count(), 'Unknown countries must not trigger duplicate warnings.');
        RegistrationNoMgt.FindDuplicates('', CountryRegion.Code, SourceCustomer.RecordId, Duplicates);
        Assert.AreEqual(0, Duplicates.Count(), 'Blank registration numbers must not match.');
    end;

    [Test]
    procedure LinkedRecordsRepresentOneOrganization()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Duplicates: List of [RecordId];
        EmptySourceRecordId: RecordId;
    begin
        SetFeatureEnabled(true);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CreateCustomer(Customer, CountryRegion.Code, 'Ab 0012');
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), Database::Vendor);
        Vendor."Country/Region Code" := CountryRegion.Code;
        Vendor."Registration Number" := Customer."Registration Number";
        Vendor.Insert(false);
        Contact."No." := LibraryUtility.GenerateRandomCode(Contact.FieldNo("No."), Database::Contact);
        Contact."Country/Region Code" := CountryRegion.Code;
        Contact."Registration Number" := Customer."Registration Number";
        Contact.Insert(false);
        ContactBusinessRelation."Contact No." := Contact."No.";
        ContactBusinessRelation."Business Relation Code" := 'CUSTOMER';
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Customer;
        ContactBusinessRelation."No." := Customer."No.";
        ContactBusinessRelation.Insert(false);
        ContactBusinessRelation."Business Relation Code" := 'VENDOR';
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Vendor;
        ContactBusinessRelation."No." := Vendor."No.";
        ContactBusinessRelation.Insert(false);

        RegistrationNoMgt.FindDuplicates('Ab 0012', CountryRegion.Code, EmptySourceRecordId, Duplicates);
        Assert.AreEqual(1, Duplicates.Count(), 'Linked customer, vendor, and contact must count as one organization.');

        RegistrationNoMgt.FindDuplicates('Ab 0012', CountryRegion.Code, Customer.RecordId, Duplicates);
        Assert.AreEqual(0, Duplicates.Count(), 'All linked representations of the source must be excluded.');
    end;

    [Test]
    procedure DeletingCountryRemovesItsFormats()
    var
        CountryRegion: Record "Country/Region";
        RegistrationNoFormat: Record "Registration No. Format";
    begin
        SetFeatureEnabled(true);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CreateFormat(CountryRegion.Code, 10000, '####');

        CountryRegion.Delete(true);

        RegistrationNoFormat.SetRange("Country/Region Code", CountryRegion.Code);
        Assert.IsTrue(RegistrationNoFormat.IsEmpty(), 'Deleting a country must remove its registration formats.');
    end;

    [Test]
    procedure DisabledFeaturePreservesLegacyResolutionAndValidation()
    var
        Customer: Record Customer temporary;
        CountryRegion: Record "Country/Region";
        RegistrationNoFoundation: Codeunit "Registration No. Foundation";
        StoredRegistrationNo: Text[50];
    begin
        SetFeatureEnabled(false);
        StoredRegistrationNo := PadStr('Stored 0012-/ ', 50, 's');
        Customer."Registration Number" := StoredRegistrationNo;
        Customer."Country/Region Code" := 'ZZ';
        BindSubscription(RegistrationNoFoundation);

        Assert.AreEqual(StoredRegistrationNo, Customer.GetRegistrationNumber(), 'Disabled features must not invoke the new resolver.');
        LibraryERM.CreateCountryRegion(CountryRegion);
        CreateFormat(CountryRegion.Code, 10000, '####');
        RegistrationNoMgt.ValidateRegistrationNo('Not digits', CountryRegion.Code, Customer.RecordId);
        UnbindSubscription(RegistrationNoFoundation);

        SetFeatureEnabled(true);
        asserterror RegistrationNoMgt.ValidateRegistrationNo('Not digits', CountryRegion.Code, Customer.RecordId);
        Assert.ExpectedError('does not match an accepted format');
    end;

    [Test]
    procedure ReportsCutOverOnlyAfterCompanyMigrationCompletes()
    var
        CompanyInformation: Record "Company Information";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        RegistrationNoFeature: Codeunit "Registration No. Feature";
        SnapshotNo: Text[50];
        SnapshotCountry: Code[10];
        LegacyCompanyNo: Text;
    begin
        SetFeatureEnabled(true);
        FeatureDataUpdateStatus.Get(RegistrationNoFeature.GetFeatureKey(), CompanyName());
        FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Pending;
        FeatureDataUpdateStatus.Modify();
        CompanyInformation.Get();
        LegacyCompanyNo := CompanyInformation.GetRegistrationNumber();

        Assert.IsFalse(RegistrationNoFeature.IsEnabled(), 'Enabling the environment key must not bypass company migration.');
        Assert.AreEqual(LegacyCompanyNo, RegistrationNoMgt.GetCompanyRegistrationForReport('Historical', CompanyInformation), 'Pending companies must keep the legacy report behavior.');
        Assert.AreEqual('Local snapshot', RegistrationNoMgt.GetDocumentRegistrationForReport('W1 snapshot', 'Local snapshot'), 'Pending companies must keep localized document values.');
        RegistrationNoMgt.GetCompanyRegistrationSnapshot(SnapshotNo, SnapshotCountry);
        Assert.AreEqual(LegacyCompanyNo, SnapshotNo, 'Snapshot capture must remain active before cutover.');
        Assert.AreEqual(CompanyInformation."Country/Region Code", SnapshotCountry, 'Capture must retain the company country before cutover.');

        SetFeatureEnabled(true);
        Assert.AreEqual('Historical', RegistrationNoMgt.GetCompanyRegistrationForReport('Historical', CompanyInformation), 'Completed companies must use stored company snapshots.');
        Assert.AreEqual('', RegistrationNoMgt.GetCompanyRegistrationForReport('', CompanyInformation), 'An enabled report must not fill a missing historical snapshot.');
        Assert.AreEqual('W1 snapshot', RegistrationNoMgt.GetDocumentRegistrationForReport('W1 snapshot', 'Local snapshot'), 'Completed companies must use global document snapshots.');
    end;

    local procedure SetFeatureEnabled(Enabled: Boolean)
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        RegistrationNoFeature: Codeunit "Registration No. Feature";
    begin
        if not FeatureKey.Get(RegistrationNoFeature.GetFeatureKey()) then begin
            FeatureKey.Init();
            FeatureKey.ID := RegistrationNoFeature.GetFeatureKey();
            FeatureKey.Insert();
        end;
        if Enabled then
            FeatureKey.Enabled := FeatureKey.Enabled::"All Users"
        else
            FeatureKey.Enabled := FeatureKey.Enabled::None;
        FeatureKey."Data Update Required" := true;
        FeatureKey.Modify();
        if not FeatureDataUpdateStatus.Get(FeatureKey.ID, CompanyName()) then begin
            FeatureDataUpdateStatus.Init();
            FeatureDataUpdateStatus."Feature Key" := FeatureKey.ID;
            FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
            FeatureDataUpdateStatus.Insert();
        end;
        FeatureDataUpdateStatus."Data Update Required" := true;
        if Enabled then
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Complete
        else
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled;
        FeatureDataUpdateStatus.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Registration No. Mgt.", 'OnResolveRegistrationNo', '', false, false)]
    local procedure ResolveRegistrationNo(RegistrationNo: Text[50]; CountryCode: Code[10]; SourceRecordId: RecordId; var ResolvedRegistrationNo: Text[50])
    begin
        if SourceRecordId.TableNo <> Database::"Company Information" then
            Assert.AreEqual(PadStr('Stored 0012-/ ', 50, 's'), RegistrationNo, 'The resolver must receive the current stored value.');
        Assert.AreEqual('ZZ', CountryCode, 'The resolver must receive the source country.');
        Assert.IsTrue(
            SourceRecordId.TableNo in [Database::Customer, Database::Vendor, Database::Contact, Database::"Company Information"],
            'Only master records may use live registration resolution.');
        ResolvedRegistrationNo := PadStr('Resolved 0012-/ ', 50, 'r');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnAfterGetRegistrationNumber', '', false, false)]
    local procedure AppendLegacyCompanyRegistrationSuffix(var Result: Text)
    begin
        if not AppendLegacyCompanySuffix then
            exit;
        Assert.AreEqual(PadStr('Resolved 0012-/ ', 50, 'r'), Result, 'The existing company event must run after shared resolution.');
        Result += ' legacy suffix';
    end;

    procedure SetAppendLegacyCompanySuffix(NewAppendLegacyCompanySuffix: Boolean)
    begin
        AppendLegacyCompanySuffix := NewAppendLegacyCompanySuffix;
    end;

    local procedure AssertPostedRegistrationSnapshot(PostedDocument: Variant; RegistrationFieldNo: Integer)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocumentRef: RecordRef;
    begin
        PostedDocumentRef.GetTable(PostedDocument);
        Assert.AreEqual(PadStr('Counterparty 0012-/ ', 50, 'n'), Format(PostedDocumentRef.Field(RegistrationFieldNo).Value), 'The complete counterparty registration must survive posting transfer.');
        Assert.AreEqual('AA', Format(PostedDocumentRef.Field(SalesInvoiceHeader.FieldNo("Registration Country/Region")).Value), 'The counterparty country must survive posting transfer.');
        Assert.AreEqual(PadStr('Resolved 0012-/ ', 50, 'r'), Format(PostedDocumentRef.Field(SalesInvoiceHeader.FieldNo("Company Registration No.")).Value), 'The company snapshot must use the shared resolver.');
        Assert.AreEqual('ZZ', Format(PostedDocumentRef.Field(SalesInvoiceHeader.FieldNo("Company Reg. Country/Region")).Value), 'The company snapshot must use its own country.');
    end;

    local procedure CreateFormat(CountryCode: Code[10]; LineNo: Integer; RegistrationFormat: Text[50])
    var
        RegistrationNoFormat: Record "Registration No. Format";
    begin
        RegistrationNoFormat.Validate("Country/Region Code", CountryCode);
        RegistrationNoFormat."Line No." := LineNo;
        RegistrationNoFormat.Validate(Format, RegistrationFormat);
        RegistrationNoFormat.Insert(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; CountryCode: Code[10]; RegistrationNo: Text[50])
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), Database::Customer);
        Customer."Country/Region Code" := CountryCode;
        Customer."Registration Number" := RegistrationNo;
        Customer.Insert(false);
    end;
}
