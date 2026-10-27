namespace Microsoft.Finance.VAT.Reporting.Test;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System.IO;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;
codeunit 144064 "INTERVAT XML Output"
{
    // [FEATURE] [INTERVAT] [XML]
    // Pins the exact serialized INTERVAT files (byte for byte) produced by
    // report 11307 "VAT - Form", report 11309 "VAT Annual Listing - Disk" and report 11315 "VAT-VIES Declaration Disk BE".

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        TestYear: Integer;
        EnterpriseNoTok: Label '0123456749', Locked = true;
        RepresentativeIDTok: Label 'INTVATREP', Locked = true;
        BECustomer1Tok: Label 'INTVAT01', Locked = true;
        BECustomer2Tok: Label 'INTVAT02', Locked = true;
        DECustomerTok: Label 'INTVAT03', Locked = true;
        FRCustomerTok: Label 'INTVAT04', Locked = true;
        NLCustomerTok: Label 'INTVAT05', Locked = true;
        XmlDeclarationTok: Label '<?xml version="1.0" encoding="UTF-8"?>', Locked = true;
        VATConsignmentNsTok: Label 'http://www.minfin.fgov.be/VATConsignment', Locked = true;
        ClientListingNsTok: Label 'http://www.minfin.fgov.be/ClientListingConsignment', Locked = true;
        IntraConsignmentNsTok: Label 'http://www.minfin.fgov.be/IntraConsignment', Locked = true;
        InputCommonNsTok: Label 'http://www.minfin.fgov.be/InputCommon', Locked = true;
        XsiNsTok: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        UnexpectedFileErr: Label 'The INTERVAT file content is not as expected.';

    [Test]
    [HandlerFunctions('VATFormRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATFormXmlOutput()
    var
        FileName: Text;
        Xml: TextBuilder;
    begin
        // [FEATURE] [VAT - Form]
        // [SCENARIO] VAT - Form writes the INTERVAT VAT declaration without a representative exactly as expected
        Initialize();
        SetSequenceNumbers(5, 0, 0);

        // [WHEN] VAT - Form runs for November without representative, correction or comment
        FileName := RunVATForm(11, 2, false, true, false, false, false, 0, '');

        // [THEN] The file is UTF-8 without a byte order mark and matches the expected INTERVAT content
        AppendLine(Xml, 0, XmlDeclarationTok);
        AppendLine(Xml, 0, '<VATConsignment VATDeclarationsNbr="1" xmlns="' + VATConsignmentNsTok + '" xmlns:common="' + InputCommonNsTok + '" xmlns:xsi="' + XsiNsTok + '" xsi:schemaLocation="' + VATConsignmentNsTok + ' NewTVA-in_v0_9.xsd">');
        AppendLine(Xml, 1, '<VATDeclaration SequenceNumber="1" DeclarantReference="' + EnterpriseNoTok + '0006" xmlns="' + VATConsignmentNsTok + '">');
        AppendDeclarant(Xml, 2);
        AppendPeriod(Xml, 2, 'Period', 'Month', 11);
        AppendLine(Xml, 2, '<Data>');
        AppendLine(Xml, 3, '<Amount GridNumber="71">0.00</Amount>');
        AppendLine(Xml, 2, '</Data>');
        AppendLine(Xml, 2, '<ClientListingNihil>NO</ClientListingNihil>');
        AppendLine(Xml, 2, '<Ask Restitution="NO" Payment="YES" />');
        AppendLine(Xml, 2, '<Comment />');
        AppendLine(Xml, 1, '</VATDeclaration>');
        Xml.Append('</VATConsignment>');
        VerifyFileContent(FileName, Xml.ToText());
    end;

    [Test]
    [HandlerFunctions('VATFormRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATFormXmlOutputWithRepresentative()
    var
        FileName: Text;
        Xml: TextBuilder;
    begin
        // [FEATURE] [VAT - Form] [Representative]
        // [SCENARIO] VAT - Form writes the INTERVAT VAT correction declaration with a representative exactly as expected
        Initialize();
        SetSequenceNumbers(6, 0, 0);

        // [WHEN] VAT - Form runs for December with representative, correction of declaration 42, "Print Zero" prepayment and a comment
        FileName := RunVATForm(12, 1, true, true, true, true, true, 42, 'Line1 & <x>');

        // [THEN] The file matches the expected INTERVAT content, including the representative and the default namespace on the root children
        AppendLine(Xml, 0, XmlDeclarationTok);
        AppendLine(Xml, 0, '<VATConsignment VATDeclarationsNbr="1" xmlns="' + VATConsignmentNsTok + '" xmlns:common="' + InputCommonNsTok + '" xmlns:xsi="' + XsiNsTok + '" xsi:schemaLocation="' + VATConsignmentNsTok + ' NewTVA-in_v0_9.xsd">');
        AppendRepresentative(Xml, VATConsignmentNsTok, '0007');
        AppendLine(Xml, 1, '<VATDeclaration SequenceNumber="1" DeclarantReference="' + EnterpriseNoTok + '0007" xmlns="' + VATConsignmentNsTok + '">');
        AppendLine(Xml, 2, '<ReplacedVATDeclaration>42-' + EnterpriseNoTok + '-' + Format(TestYear) + '12</ReplacedVATDeclaration>');
        AppendDeclarant(Xml, 2);
        AppendPeriod(Xml, 2, 'Period', 'Month', 12);
        AppendLine(Xml, 2, '<Data>');
        AppendLine(Xml, 3, '<Amount GridNumber="71">0.00</Amount>');
        AppendLine(Xml, 3, '<Amount GridNumber="91">0.00</Amount>');
        AppendLine(Xml, 2, '</Data>');
        AppendLine(Xml, 2, '<ClientListingNihil>YES</ClientListingNihil>');
        AppendLine(Xml, 2, '<Ask Restitution="YES" Payment="YES" />');
        AppendLine(Xml, 2, '<Comment>Line1 &amp; &lt;x&gt;</Comment>');
        AppendLine(Xml, 1, '</VATDeclaration>');
        Xml.Append('</VATConsignment>');
        VerifyFileContent(FileName, Xml.ToText());
    end;

    [Test]
    [HandlerFunctions('AnnualListingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnnualListingXmlOutput()
    var
        FileName: Text;
        Xml: TextBuilder;
    begin
        // [FEATURE] [VAT Annual Listing - Disk]
        // [SCENARIO] VAT Annual Listing - Disk writes the INTERVAT client listing without a representative exactly as expected
        Initialize();
        SetSequenceNumbers(0, 1, 0);

        // [WHEN] VAT Annual Listing - Disk runs for the test year without representative
        FileName := RunAnnualListing(false);

        // [THEN] The file matches the expected INTERVAT content
        AppendLine(Xml, 0, XmlDeclarationTok);
        AppendAnnualListingRoot(Xml);
        AppendAnnualListingBody(Xml, '0002');
        Xml.Append('</ClientListingConsignment>');
        VerifyFileContent(FileName, Xml.ToText());
    end;

    [Test]
    [HandlerFunctions('AnnualListingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnnualListingXmlOutputWithRepresentative()
    var
        FileName: Text;
        Xml: TextBuilder;
    begin
        // [FEATURE] [VAT Annual Listing - Disk] [Representative]
        // [SCENARIO] VAT Annual Listing - Disk writes the INTERVAT client listing with a representative exactly as expected
        Initialize();
        SetSequenceNumbers(0, 2, 0);

        // [WHEN] VAT Annual Listing - Disk runs for the test year with representative
        FileName := RunAnnualListing(true);

        // [THEN] The file matches the expected INTERVAT content, including the representative
        AppendLine(Xml, 0, XmlDeclarationTok);
        AppendAnnualListingRoot(Xml);
        AppendRepresentative(Xml, ClientListingNsTok, '0003');
        AppendAnnualListingBody(Xml, '0003');
        Xml.Append('</ClientListingConsignment>');
        VerifyFileContent(FileName, Xml.ToText());
    end;

    [Test]
    [HandlerFunctions('VATVIESRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESXmlOutput()
    var
        FileName: Text;
        Xml: TextBuilder;
    begin
        // [FEATURE] [VAT-VIES Declaration Disk BE]
        // [SCENARIO] VAT-VIES Declaration Disk BE writes the INTERVAT intra-community listing without a representative exactly as expected
        Initialize();
        SetSequenceNumbers(0, 0, 12);

        // [WHEN] VAT-VIES Declaration Disk BE runs for March without representative
        FileName := RunVATVIES(3, false);

        // [THEN] The file matches the expected INTERVAT content
        AppendLine(Xml, 0, XmlDeclarationTok);
        AppendVATVIESRoot(Xml);
        AppendVATVIESBody(Xml, '0013');
        Xml.Append('</IntraConsignment>');
        VerifyFileContent(FileName, Xml.ToText());
    end;

    [Test]
    [HandlerFunctions('VATVIESRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESXmlOutputWithRepresentative()
    var
        FileName: Text;
        Xml: TextBuilder;
    begin
        // [FEATURE] [VAT-VIES Declaration Disk BE] [Representative]
        // [SCENARIO] VAT-VIES Declaration Disk BE writes the INTERVAT intra-community listing with a representative exactly as expected
        Initialize();
        SetSequenceNumbers(0, 0, 13);

        // [WHEN] VAT-VIES Declaration Disk BE runs for March with representative
        FileName := RunVATVIES(3, true);

        // [THEN] The file matches the expected INTERVAT content, including the representative
        AppendLine(Xml, 0, XmlDeclarationTok);
        AppendVATVIESRoot(Xml);
        AppendRepresentative(Xml, IntraConsignmentNsTok, '0014');
        AppendVATVIESBody(Xml, '0014');
        Xml.Append('</IntraConsignment>');
        VerifyFileContent(FileName, Xml.ToText());
    end;

    [Test]
    [HandlerFunctions('VATVIESRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESClientsAfterCorrectingPeriodAreNested()
    var
        XmlDoc: XmlDocument;
        NamespaceManager: XmlNamespaceManager;
        Nodes: XmlNodeList;
        Node: XmlNode;
        FileName: Text;
    begin
        // [FEATURE] [VAT-VIES Declaration Disk BE] [VIES Correction]
        // [SCENARIO] Pins the existing structure of the VIES file: every IntraClient that follows an IntraClient with a CorrectingPeriod
        // is written inside that IntraClient instead of directly under IntraListing.
        // This is a long-standing defect kept for compatibility; fixing it is a separate, behavior-changing change that must update this test.
        Initialize();
        SetSequenceNumbers(0, 0, 20);

        // [GIVEN] April: a sale to the DE customer, a VIES correction for the DE customer with a correction period, and a service to the NL customer
        InsertVATEntry(DECustomerTok, 'DE', DMY2Date(10, 4, TestYear), -500, false, false);
        InsertVATEntry(NLCustomerTok, 'NL', DMY2Date(10, 4, TestYear), -700.25, true, false);
        InsertVIESCorrection(DECustomerTok, 'DE', 'DE123456789', 4, 1, TestYear, 100);

        // [WHEN] VAT-VIES Declaration Disk BE runs for April
        FileName := RunVATVIES(4, false);

        // [THEN] IntraListing directly contains the DE client (1) and the DE correction client (2) only
        LoadXmlDocument(FileName, XmlDoc, NamespaceManager);
        XmlDoc.SelectNodes('/ns:IntraConsignment/ns:IntraListing/ns:IntraClient', NamespaceManager, Nodes);
        Assert.AreEqual(2, Nodes.Count(), 'Number of IntraClient elements directly under IntraListing');
        // [THEN] The DE correction client (2) has the CorrectingPeriod
        Assert.IsTrue(
          XmlDoc.SelectSingleNode('/ns:IntraConsignment/ns:IntraListing/ns:IntraClient[@SequenceNumber="2"]/ns:CorrectingPeriod', NamespaceManager, Node),
          'CorrectingPeriod of IntraClient 2');
        // [THEN] The NL client (3) that follows it is nested inside the DE correction client (2)
        XmlDoc.SelectNodes('/ns:IntraConsignment/ns:IntraListing/ns:IntraClient[@SequenceNumber="2"]/ns:IntraClient', NamespaceManager, Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'Number of IntraClient elements nested in IntraClient 2');
        Nodes.Get(1, Node);
        Assert.AreEqual('3', GetAttributeValue(Node, 'SequenceNumber'), 'SequenceNumber of the nested IntraClient');
        Assert.IsTrue(XmlDoc.SelectSingleNode('/ns:IntraConsignment/ns:IntraListing', NamespaceManager, Node), 'IntraListing');
        Assert.AreEqual('3', GetAttributeValue(Node, 'ClientsNbr'), 'ClientsNbr of IntraListing');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"INTERVAT XML Output");
        LibraryVariableStorage.Clear();
        TestYear := 2049;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"INTERVAT XML Output");

        UpdateCountryRegion('BE');
        UpdateCountryRegion('DE');
        UpdateCountryRegion('FR');
        UpdateCountryRegion('NL');

        CompanyInformation.Get();
        CompanyInformation.Name := 'INTERVAT & Co <BE> "test"';
        CompanyInformation.Address := 'Rue de l''Eglise 1';
        CompanyInformation."Post Code" := '1000';
        CompanyInformation.City := 'Bruxelles';
        CompanyInformation."Country/Region Code" := 'BE';
        CompanyInformation."E-Mail" := 'info@intervat.be';
        CompanyInformation."Phone No." := '+32 (2) 123.45.67';
        CompanyInformation."Enterprise No." := EnterpriseNoTok;
        CompanyInformation.Modify();

        CreateRepresentative();

        // Belgian customers for the annual listing (July), EU customers for the VIES declaration (March)
        CreateCustomer(BECustomer1Tok, 'BE', '8765432120', '');
        CreateCustomer(BECustomer2Tok, 'BE', '1122334441', '');
        CreateCustomer(DECustomerTok, 'DE', '', 'DE123456789');
        CreateCustomer(FRCustomerTok, 'FR', '', 'FR12345678901');
        CreateCustomer(NLCustomerTok, 'NL', '', 'NL123456789B01');
        InsertVATEntry(BECustomer1Tok, 'BE', DMY2Date(15, 7, TestYear), -1500.75, -315.17, false, false);
        InsertVATEntry(BECustomer2Tok, 'BE', DMY2Date(15, 7, TestYear), -375, -78.75, false, false);
        InsertVATEntry(DECustomerTok, 'DE', DMY2Date(10, 3, TestYear), -500, false, false);
        InsertVATEntry(FRCustomerTok, 'FR', DMY2Date(10, 3, TestYear), -300, false, true);
        InsertVATEntry(NLCustomerTok, 'NL', DMY2Date(10, 3, TestYear), -700.25, true, false);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"INTERVAT XML Output");
    end;

    local procedure UpdateCountryRegion(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryRegionCode) then begin
            CountryRegion.Init();
            CountryRegion.Code := CountryRegionCode;
            CountryRegion.Insert();
        end;
        CountryRegion."ISO Code" := CopyStr(CountryRegionCode, 1, MaxStrLen(CountryRegion."ISO Code"));
        CountryRegion."EU Country/Region Code" := CountryRegionCode;
        CountryRegion.Modify();
    end;

    local procedure CreateRepresentative()
    var
        Representative: Record Representative;
    begin
        Representative.Init();
        Representative.ID := RepresentativeIDTok;
        Representative.Name := 'Rep & Partners';
        Representative."E-Mail" := 'rep@partners.be';
        Representative.Phone := '+32 9 876 54 32';
        Representative."Issued by" := 'BE';
        Representative."Identification Type" := Representative."Identification Type"::NVAT;
        Representative.Address := 'Avenue 2';
        Representative.City := 'Gent';
        Representative."Post Code" := '9000';
        Representative."Country/Region Code" := 'BE';
        Representative.Insert();
    end;

    local procedure CreateCustomer(CustomerNo: Code[20]; CountryRegionCode: Code[10]; EnterpriseNo: Text[50]; VATRegistrationNo: Text[20])
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Name := CustomerNo;
        Customer."Country/Region Code" := CountryRegionCode;
        Customer."Enterprise No." := CopyStr(EnterpriseNo, 1, MaxStrLen(Customer."Enterprise No."));
        Customer."VAT Registration No." := VATRegistrationNo;
        Customer."VAT Liable" := EnterpriseNo <> '';
        Customer.Insert();
    end;

    local procedure InsertVATEntry(CustomerNo: Code[20]; CountryRegionCode: Code[10]; VATReportingDate: Date; VATBase: Decimal; EUService: Boolean; EU3PartyTrade: Boolean)
    begin
        InsertVATEntry(CustomerNo, CountryRegionCode, VATReportingDate, VATBase, 0, EUService, EU3PartyTrade);
    end;

    local procedure InsertVATEntry(CustomerNo: Code[20]; CountryRegionCode: Code[10]; VATReportingDate: Date; VATBase: Decimal; VATAmount: Decimal; EUService: Boolean; EU3PartyTrade: Boolean)
    var
        VATEntry: Record "VAT Entry";
        EntryNo: Integer;
    begin
        if VATEntry.FindLast() then
            EntryNo := VATEntry."Entry No.";
        VATEntry.Init();
        VATEntry."Entry No." := EntryNo + 1;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Bill-to/Pay-to No." := CustomerNo;
        VATEntry."Country/Region Code" := CountryRegionCode;
        VATEntry."Posting Date" := VATReportingDate;
        VATEntry."VAT Reporting Date" := VATReportingDate;
        VATEntry."Document Date" := VATReportingDate;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Document No." := CopyStr(CustomerNo + Format(VATEntry."Entry No."), 1, MaxStrLen(VATEntry."Document No."));
        VATEntry.Base := VATBase;
        VATEntry.Amount := VATAmount;
        VATEntry."EU Service" := EUService;
        VATEntry."EU 3-Party Trade" := EU3PartyTrade;
        VATEntry.Insert();
    end;

    local procedure InsertVIESCorrection(CustomerNo: Code[20]; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]; DeclarationMonth: Integer; CorrectionMonth: Integer; CorrectionYear: Integer; CorrectionAmount: Decimal)
    var
        VATVIESCorrection: Record "VAT VIES Correction";
        LineNo: Integer;
    begin
        if VATVIESCorrection.FindLast() then
            LineNo := VATVIESCorrection."Line No.";
        VATVIESCorrection.Init();
        VATVIESCorrection."Period Type" := VATVIESCorrection."Period Type"::Month;
        VATVIESCorrection."Declaration Period No." := DeclarationMonth;
        VATVIESCorrection."Declaration Period Year" := TestYear;
        VATVIESCorrection."Line No." := LineNo + 10000;
        VATVIESCorrection."Customer No." := CustomerNo;
        VATVIESCorrection.Amount := CorrectionAmount;
        VATVIESCorrection."Correction Date" := DMY2Date(1, DeclarationMonth, TestYear);
        VATVIESCorrection."VAT Registration No." := VATRegistrationNo;
        VATVIESCorrection."Country/Region Code" := CountryRegionCode;
        VATVIESCorrection."Correction Period No." := CorrectionMonth;
        VATVIESCorrection."Correction Period Year" := CorrectionYear;
        VATVIESCorrection.Insert();
    end;

    local procedure SetSequenceNumbers(VATDeclarationSeqNo: Integer; AnnualListingSeqNo: Integer; EUSalesListSeqNo: Integer)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."XML Seq. No. VAT Declaration" := VATDeclarationSeqNo;
        CompanyInformation."XML Seq. No. Annual Listing" := AnnualListingSeqNo;
        CompanyInformation."XML Seq. No. EU Sales List" := EUSalesListSeqNo;
        CompanyInformation.Modify();
    end;

    local procedure RunVATForm(Month: Integer; PrintPrepayment: Integer; Reimbursement: Boolean; PaymentForms: Boolean; NoAnnualListing: Boolean; AddRepresentative: Boolean; IsCorrection: Boolean; PrevSequenceNo: Integer; Comment: Text) FileName: Text
    var
        VATForm: Report "VAT - Form";
        FileManagement: Codeunit "File Management";
    begin
        LibraryVariableStorage.Enqueue(Month);
        LibraryVariableStorage.Enqueue(PrintPrepayment);
        LibraryVariableStorage.Enqueue(Reimbursement);
        LibraryVariableStorage.Enqueue(PaymentForms);
        LibraryVariableStorage.Enqueue(NoAnnualListing);
        LibraryVariableStorage.Enqueue(AddRepresentative);
        LibraryVariableStorage.Enqueue(IsCorrection);
        LibraryVariableStorage.Enqueue(PrevSequenceNo);
        LibraryVariableStorage.Enqueue(Comment);
        Commit();

        FileName := FileManagement.ServerTempFileName('xml');
        VATForm.SetFileName(FileName);
        VATForm.Run();
    end;

    local procedure RunAnnualListing(AddRepresentative: Boolean) FileName: Text
    var
        VATAnnualListingDisk: Report "VAT Annual Listing - Disk";
        FileManagement: Codeunit "File Management";
    begin
        LibraryVariableStorage.Enqueue(AddRepresentative);
        Commit();

        FileName := FileManagement.ServerTempFileName('xml');
        VATAnnualListingDisk.SetFileName(FileName);
        VATAnnualListingDisk.Run();
    end;

    local procedure RunVATVIES(Month: Integer; AddRepresentative: Boolean) FileName: Text
    var
        VATVIESDeclarationDiskBE: Report "VAT-VIES Declaration Disk BE";
        FileManagement: Codeunit "File Management";
    begin
        LibraryVariableStorage.Enqueue(Month);
        LibraryVariableStorage.Enqueue(AddRepresentative);
        Commit();

        FileName := FileManagement.ServerTempFileName('xml');
        VATVIESDeclarationDiskBE.SetFileName(FileName);
        VATVIESDeclarationDiskBE.Run();
    end;

    local procedure AppendLine(var Xml: TextBuilder; IndentLevel: Integer; Line: Text)
    var
        CR: Char;
        LF: Char;
    begin
        CR := 13;
        LF := 10;
        Xml.Append(PadStr('', IndentLevel * 2, ' ') + Line + Format(CR) + Format(LF));
    end;

    local procedure AppendDeclarant(var Xml: TextBuilder; IndentLevel: Integer)
    begin
        AppendLine(Xml, IndentLevel, '<Declarant>');
        AppendLine(Xml, IndentLevel + 1, '<common:VATNumber>' + EnterpriseNoTok + '</common:VATNumber>');
        AppendLine(Xml, IndentLevel + 1, '<common:Name>INTERVAT &amp; Co &lt;BE&gt; "test"</common:Name>');
        AppendLine(Xml, IndentLevel + 1, '<common:Street>Rue de l''Eglise 1</common:Street>');
        AppendLine(Xml, IndentLevel + 1, '<common:PostCode>1000</common:PostCode>');
        AppendLine(Xml, IndentLevel + 1, '<common:City>Bruxelles</common:City>');
        AppendLine(Xml, IndentLevel + 1, '<common:CountryCode>BE</common:CountryCode>');
        AppendLine(Xml, IndentLevel + 1, '<common:EmailAddress>info@intervat.be</common:EmailAddress>');
        AppendLine(Xml, IndentLevel + 1, '<common:Phone>+3221234567</common:Phone>');
        AppendLine(Xml, IndentLevel, '</Declarant>');
    end;

    local procedure AppendPeriod(var Xml: TextBuilder; IndentLevel: Integer; PeriodName: Text; PeriodTypeName: Text; Period: Integer)
    begin
        AppendLine(Xml, IndentLevel, '<' + PeriodName + '>');
        AppendLine(Xml, IndentLevel + 1, '<' + PeriodTypeName + '>' + Format(Period) + '</' + PeriodTypeName + '>');
        AppendLine(Xml, IndentLevel + 1, '<Year>' + Format(TestYear) + '</Year>');
        AppendLine(Xml, IndentLevel, '</' + PeriodName + '>');
    end;

    local procedure AppendRepresentative(var Xml: TextBuilder; DocumentNamespace: Text; RepresentativeReference: Text)
    begin
        AppendLine(Xml, 1, '<Representative xmlns="' + DocumentNamespace + '">');
        AppendLine(Xml, 2, '<common:RepresentativeID issuedBy="BE" identificationType="NVAT">' + RepresentativeIDTok + '</common:RepresentativeID>');
        AppendLine(Xml, 2, '<common:Name>Rep &amp; Partners</common:Name>');
        AppendLine(Xml, 2, '<common:Street>Avenue 2</common:Street>');
        AppendLine(Xml, 2, '<common:PostCode>9000</common:PostCode>');
        AppendLine(Xml, 2, '<common:City>Gent</common:City>');
        AppendLine(Xml, 2, '<common:CountryCode>BE</common:CountryCode>');
        AppendLine(Xml, 2, '<common:EmailAddress>rep@partners.be</common:EmailAddress>');
        AppendLine(Xml, 2, '<common:Phone>+3298765432</common:Phone>');
        AppendLine(Xml, 1, '</Representative>');
        AppendLine(Xml, 1, '<RepresentativeReference xmlns="' + DocumentNamespace + '">' + RepresentativeReference + '</RepresentativeReference>');
    end;

    local procedure AppendAnnualListingRoot(var Xml: TextBuilder)
    begin
        AppendLine(Xml, 0, '<ClientListingConsignment ClientListingsNbr="1" xmlns="' + ClientListingNsTok + '" xmlns:common="' + InputCommonNsTok + '" xmlns:xsi="' + XsiNsTok + '" xsi:schemaLocation="' + ClientListingNsTok + ' NewLK-in_v0_7.xsd">');
    end;

    local procedure AppendAnnualListingBody(var Xml: TextBuilder; SequenceNo: Text)
    begin
        AppendLine(Xml, 1, '<ClientListing SequenceNumber="1" ClientsNbr="2" TurnOverSum="1875.75" VATAmountSum="393.92" DeclarantReference="' + EnterpriseNoTok + SequenceNo + '" xmlns="' + ClientListingNsTok + '">');
        AppendDeclarant(Xml, 2);
        AppendLine(Xml, 2, '<Period>' + Format(TestYear) + '</Period>');
        AppendLine(Xml, 2, '<Client SequenceNumber="1">');
        AppendLine(Xml, 3, '<CompanyVATNumber issuedBy="BE">8765432120</CompanyVATNumber>');
        AppendLine(Xml, 3, '<TurnOver>1500.75</TurnOver>');
        AppendLine(Xml, 3, '<VATAmount>315.17</VATAmount>');
        AppendLine(Xml, 2, '</Client>');
        AppendLine(Xml, 2, '<Client SequenceNumber="2">');
        AppendLine(Xml, 3, '<CompanyVATNumber issuedBy="BE">1122334441</CompanyVATNumber>');
        AppendLine(Xml, 3, '<TurnOver>375.00</TurnOver>');
        AppendLine(Xml, 3, '<VATAmount>78.75</VATAmount>');
        AppendLine(Xml, 2, '</Client>');
        AppendLine(Xml, 1, '</ClientListing>');
    end;

    local procedure AppendVATVIESRoot(var Xml: TextBuilder)
    begin
        AppendLine(Xml, 0, '<IntraConsignment IntraListingsNbr="1" xmlns="' + IntraConsignmentNsTok + '" xmlns:common="' + InputCommonNsTok + '" xmlns:xsi="' + XsiNsTok + '" xsi:schemaLocation="' + IntraConsignmentNsTok + ' NewICO-in_v0_7.xsd">');
    end;

    local procedure AppendVATVIESBody(var Xml: TextBuilder; SequenceNo: Text)
    begin
        AppendLine(Xml, 1, '<IntraListing SequenceNumber="1" ClientsNbr="3" DeclarantReference="' + EnterpriseNoTok + SequenceNo + '" AmountSum="1500.25" xmlns="' + IntraConsignmentNsTok + '">');
        AppendDeclarant(Xml, 2);
        AppendPeriod(Xml, 2, 'Period', 'Month', 3);
        AppendIntraClient(Xml, 1, 'DE', '123456789', 'L', '500.00');
        AppendIntraClient(Xml, 2, 'FR', '12345678901', 'T', '300.00');
        AppendIntraClient(Xml, 3, 'NL', '123456789B01', 'S', '700.25');
        AppendLine(Xml, 1, '</IntraListing>');
    end;

    local procedure AppendIntraClient(var Xml: TextBuilder; SequenceNo: Integer; IssuedBy: Text; VATNumber: Text; CodeLetter: Text; Amount: Text)
    begin
        AppendLine(Xml, 2, '<IntraClient SequenceNumber="' + Format(SequenceNo) + '">');
        AppendLine(Xml, 3, '<CompanyVATNumber issuedBy="' + IssuedBy + '">' + VATNumber + '</CompanyVATNumber>');
        AppendLine(Xml, 3, '<Code>' + CodeLetter + '</Code>');
        AppendLine(Xml, 3, '<Amount>' + Amount + '</Amount>');
        AppendLine(Xml, 2, '</IntraClient>');
    end;

    local procedure VerifyFileContent(FileName: Text; ExpectedContent: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        ActualBase64: Text;
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);
        TempBlob.CreateInStream(FileInStream);
        ActualBase64 := Base64Convert.ToBase64(FileInStream);
        FileManagement.DeleteServerFile(FileName);

        // Compare the decoded text first for a readable message, then the raw bytes (UTF-8 without byte order mark).
        Assert.AreEqual(ExpectedContent, Base64Convert.FromBase64(ActualBase64), UnexpectedFileErr);
        Assert.AreEqual(Base64Convert.ToBase64(ExpectedContent, TextEncoding::UTF8), ActualBase64, UnexpectedFileErr);
    end;

    local procedure LoadXmlDocument(FileName: Text; var XmlDoc: XmlDocument; var NamespaceManager: XmlNamespaceManager)
    var
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);
        FileManagement.DeleteServerFile(FileName);
        TempBlob.CreateInStream(FileInStream);
        XmlDocument.ReadFrom(FileInStream, XmlDoc);
        NamespaceManager.NameTable(XmlDoc.NameTable());
        NamespaceManager.AddNamespace('ns', IntraConsignmentNsTok);
    end;

    local procedure GetAttributeValue(Node: XmlNode; AttributeName: Text): Text
    var
        Attribute: XmlAttribute;
    begin
        Node.AsXmlElement().Attributes().Get(AttributeName, Attribute);
        exit(Attribute.Value());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATFormRequestPageHandler(var VATForm: TestRequestPage "VAT - Form")
    var
        AddRepresentative: Boolean;
        IsCorrection: Boolean;
    begin
        // Period 1 is valid for both declaration types, so the saved request page values cannot fail the validation.
        VATForm.Vperiod.SetValue(1);
        VATForm.ChoicePeriodType.SetValue(0);
        VATForm.Vperiod.SetValue(LibraryVariableStorage.DequeueInteger());
        VATForm.Vyear.SetValue(TestYear);
        VATForm.IncludeVatEntries.SetValue(0);
        VATForm.PrintPrepayment.SetValue(LibraryVariableStorage.DequeueInteger());
        VATForm.Reimbursement.SetValue(LibraryVariableStorage.DequeueBoolean());
        VATForm.PaymForms.SetValue(LibraryVariableStorage.DequeueBoolean());
        VATForm.Annuallist.SetValue(LibraryVariableStorage.DequeueBoolean());
        AddRepresentative := LibraryVariableStorage.DequeueBoolean();
        VATForm.AddRepresentative.SetValue(AddRepresentative);
        if AddRepresentative then
            VATForm.ID.SetValue(RepresentativeIDTok);
        IsCorrection := LibraryVariableStorage.DequeueBoolean();
        VATForm.IsCorrectionControl.SetValue(IsCorrection);
        if IsCorrection then
            VATForm.PrevSequenceNoControl.SetValue(LibraryVariableStorage.DequeueInteger())
        else
            LibraryVariableStorage.DequeueInteger();
        VATForm.CommentControl.SetValue(LibraryVariableStorage.DequeueText());
        VATForm.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AnnualListingRequestPageHandler(var VATAnnualListingDisk: TestRequestPage "VAT Annual Listing - Disk")
    var
        AddRepresentative: Boolean;
        IncludeCountry: Option All,Specific;
    begin
        VATAnnualListingDisk.VYear.SetValue(TestYear);
        VATAnnualListingDisk.Minimum.SetValue(0.01);
        VATAnnualListingDisk.TestDeclaration.SetValue(false);
        AddRepresentative := LibraryVariableStorage.DequeueBoolean();
        VATAnnualListingDisk.AddRepresentative.SetValue(AddRepresentative);
        if AddRepresentative then
            VATAnnualListingDisk.ID.SetValue(RepresentativeIDTok);
        VATAnnualListingDisk.IncludeCountry.SetValue(IncludeCountry::All);
        VATAnnualListingDisk.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESRequestPageHandler(var VATVIESDeclarationDiskBE: TestRequestPage "VAT-VIES Declaration Disk BE")
    var
        AddRepresentative: Boolean;
    begin
        // Period 1 is valid for both declaration types, so the saved request page values cannot fail the validation.
        VATVIESDeclarationDiskBE.Vquarter.SetValue(1);
        VATVIESDeclarationDiskBE.Choice.SetValue(0);
        VATVIESDeclarationDiskBE.Vquarter.SetValue(LibraryVariableStorage.DequeueInteger());
        VATVIESDeclarationDiskBE.Vyear.SetValue(TestYear);
        VATVIESDeclarationDiskBE.TestDeclaration.SetValue(false);
        AddRepresentative := LibraryVariableStorage.DequeueBoolean();
        VATVIESDeclarationDiskBE.AddRepresentative.SetValue(AddRepresentative);
        if AddRepresentative then
            VATVIESDeclarationDiskBE.ID.SetValue(RepresentativeIDTok);
        VATVIESDeclarationDiskBE.OK().Invoke();
    end;
}
