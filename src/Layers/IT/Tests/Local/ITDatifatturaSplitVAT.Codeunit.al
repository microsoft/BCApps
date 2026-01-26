codeunit 144562 "IT - Datifattura Split VAT"
{
    // // [FEATURE] [Split VAT] [Datifattura] [VAT Report]

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySplitVAT: Codeunit "Library - Split VAT";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        LibraryITDatifattura: Codeunit "Library - IT Datifattura";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySpesometro: Codeunit "Library - Spesometro";
        IsInitialized: Boolean;
        EsigibilitaIVATok: Label 'DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiRiepilogo/EsigibilitaIVA';
        CAPTok: Label 'DTR/CedentePrestatoreDTR/AltriDatiIdentificativi/Sede/CAP';
        CodiceFiscaleTok: Label 'DatiFatturaHeader/Dichiarante/CodiceFiscale';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestPaymentLinesFromSalesInvoiceWithSplitFullVAT()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        VATReportMediator: Codeunit "VAT Report Mediator";
        DotNetXmlNode: DotNet XmlNode;
        FilePath: Text;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Full VAT] [Sales]
        // [SCENARIO 229708] Split Full VAT sales invoice can be declared with amounts and with 'S' in tag 'CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiRiepilogo/EsigibilitaIVA'
        Initialize();

        LibraryITDatifattura.CreateGeneralSetup();
        LibraryITDatifattura.CreateGeneralSetupDatifattura();

        // [GIVEN] Sales Invoice "I" with Sales Line in Split VAT Posting Setup where "VAT %" = 20%
        CreateVATPostingSetupForSplitVATFullVAT(VATPostingSetup);
        LibrarySplitVAT.CreateSalesDoc(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::Invoice);
        UpdateCustomerVatRegNo(SalesHeader."Sell-to Customer No.");

        // [GIVEN] Sales line VAT splited into two lines
        SalesHeader.AddSplitVATLines();

        // [GIVEN] Invoice "I" posted and it is suggested into Datifattura VAT Report "DR" with "Amount" = 1000 and "VAT Amount" = 200
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryVATUtils.CreateVATReportHeader(
          VATReportHeader, VATReportHeader."VAT Report Config. Code"::Datifattura, VATReportHeader."VAT Report Type"::Standard,
          WorkDate(), WorkDate());

        VATReportMediator.GetLines(VATReportHeader);

        FindVATReportLine(VATReportLine, VATReportHeader, VATReportLine."Document Type"::Invoice, DocumentNo);
        DeleteUnrelatedVATReportLines(VATReportLine);

        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindFirst();

        VATReportLine.TestField(Base, VATEntry.Base);
        VATReportLine.TestField(Amount, VATEntry.Amount);

        // [WHEN] "DR" exported to XML file
        FilePath := LibraryITDatifattura.ExportVATReport(VATReportHeader);

        LibraryXPathXMLReader.Initialize(FilePath, '');

        // [THEN]
        LibraryXPathXMLReader.GetNodeByXPath(EsigibilitaIVATok, DotNetXmlNode);
        Assert.AreEqual('S', DotNetXmlNode.InnerText, EsigibilitaIVATok);

        // Cleanup
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestCAPForVendorsFromLocalRegion();
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record "Vendor";
        PurchaseHeader: Record "Purchase Header";
        VATReportMediator: Codeunit "VAT Report Mediator";
        DotNetXmlNode: DotNet XmlNode;
        FilePath: Text;
    begin
        // [FEATURE] [CAP] [Purchase]
        // [SCENARIO 323987] Create Purchase Invoice for Italian vendor. After exporting VAT Report,
        // [SCENARIO 323987] There is Vendor."Post Code" value for vendor with (XML.Node = CAP)
        Initialize();

        LibraryITDatifattura.CreateGeneralSetup();
        LibraryITDatifattura.CreateGeneralSetupDatifattura();

        // [GIVEN] Created Vendor "V" with Italian VAT reg. no. 
        // [GIVEN] Created Purchase invoice "V".
        LibraryITDatifattura.CreateVendor(Vendor);
        UpdateVendorVatRegNo(Vendor, 'IT', LibraryERM.GenerateVATRegistrationNo('IT'));
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [GIVEN] Purchase Invoice was posted. VATReportHeader and VATReportLine was created for it.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVATUtils.CreateVATReportHeader(
            VATReportHeader, VATReportHeader."VAT Report Config. Code"::Datifattura, VATReportHeader."VAT Report Type"::Standard,
            WorkDate(), WorkDate());

        VATReportMediator.GetLines(VATReportHeader);
        FindVATReportLineByVendor(VATReportLine, VATReportHeader, VATReportLine."Document Type"::Invoice, Vendor."No.");
        DeleteUnrelatedVATReportLines(VATReportLine);

        // [WHEN] Export "VATReport" to XML file
        FilePath := LibraryITDatifattura.ExportVATReport(VATReportHeader);
        LibraryXPathXMLReader.Initialize(FilePath, '');
        LibraryXPathXMLReader.GetNodeByXPath(CAPTok, DotNetXmlNode);

        // [THEN] Vendor."Country/Region Code" is equal for 'IT'
        // [THEN] There is Vendor."Post Code" value for vendor with (XML.Node = CAP)
        Assert.AreEqual(Vendor."Country/Region Code", 'IT', 'Vendor."Country/Region Code" <> IT');
        Assert.AreEqual(Vendor."Post Code", DotNetXmlNode.InnerText, CAPTok);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    PROCEDURE SuggestCAPForVendorsFromAnotherRegion();
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record "Vendor";
        PurchaseHeader: Record "Purchase Header";
        CountryRegion: Record "Country/Region";
        VATReportMediator: Codeunit "VAT Report Mediator";
        DotNetXmlNode: DotNet XmlNode;
        FilePath: Text;
    begin
        // [FEATURE] [CAP] [Purchase]
        // [SCENARIO 323987] Create Purchase Invoice for Not Italian vendor. After exporting VAT Report,
        // [SCENARIO 323987] There is '00000' value for vendor with (XML.Node = CAP)
        Initialize();

        LibraryITDatifattura.CreateGeneralSetup();
        LibraryITDatifattura.CreateGeneralSetupDatifattura();

        // [GIVEN] Created Vendor "V" with Italian VAT reg. no. 
        // [GIVEN] Created Purchase invoice "V".
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryITDatifattura.CreateVendor(Vendor);
        UpdateVendorVatRegNo(Vendor, CountryRegion.Code, CountryRegion.Code);
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [GIVEN] Purchase Invoice was posted. VATReportHeader and VATReportLine was created for it.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVATUtils.CreateVATReportHeader(
            VATReportHeader, VATReportHeader."VAT Report Config. Code"::Datifattura, VATReportHeader."VAT Report Type"::Standard,
            WorkDate(), WorkDate());

        VATReportMediator.GetLines(VATReportHeader);
        FindVATReportLineByVendor(VATReportLine, VATReportHeader, VATReportLine."Document Type"::Invoice, Vendor."No.");
        DeleteUnrelatedVATReportLines(VATReportLine);

        // [WHEN] Export "VATReport" to XML file
        FilePath := LibraryITDatifattura.ExportVATReport(VATReportHeader);
        LibraryXPathXMLReader.Initialize(FilePath, '');
        LibraryXPathXMLReader.GetNodeByXPath(CAPTok, DotNetXmlNode);

        // [THEN] Vendor."Country/Region Code" is not equal for 'IT'
        // [THEN] There is '00000' value for vendor with (XML.Node = CAP)
        Assert.AreNotEqual(Vendor."Country/Region Code", 'IT', 'Vendor."Country/Region Code" = IT');
        Assert.AreEqual('00000', DotNetXmlNode.InnerText, CAPTok);
    end;

    [Test]
    [HandlerFunctions('DatifatturaSuggestLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestPaymentLinesCanBeFiltered()
    var
        VATReportHeader: Record "VAT Report Header";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        // [FEATURE]
        // [SCENARIO 331749] Suggest Lines shows request page to filter entries when using 'Filter Datifattura Entries' option in setup
        Initialize();

        // [GIVEN] Filter Datifattura Lines was enabled in VAT Reporting Setup
        LibraryITDatifattura.SetFilterDatifatturaLines(true);

        // [GIVEN] Vendor was created
        LibraryITDatifattura.CreateVendor(Vendor);

        // [GIVEN] Purchase invoice was created and posted for Vendor
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] VATReportHeader was created for the dates of the invoice
        LibraryVATUtils.CreateVATReportHeader(
          VATReportHeader, VATReportHeader."VAT Report Config. Code"::Datifattura, VATReportHeader."VAT Report Type"::Standard,
          WorkDate(), WorkDate());

        Commit();

        // [WHEN] Suggest Lines for Datifattura report
        VATReportMediator.GetLines(VATReportHeader);

        // [THEN] Request page with filters is open
        // UI Handled by DatifatturaSuggestLinesRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestFiscalCodeInHeader()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record "Vendor";
        PurchaseHeader: Record "Purchase Header";
        SpesometroAppointment: Record "Spesometro Appointment";
        VATReportMediator: Codeunit "VAT Report Mediator";
        DotNetXmlNode: DotNet XmlNode;
        FilePath: Text;
    begin
        // [FEATURE] [Fiscal Code] [Purchase]
        // [SCENARIO 389497] Create Purchase Invoice for Italian vendor. After exporting VAT Report,
        // [SCENARIO 389497] There is Vendor."Fiscal Code" value for vendor with (XML.Node = CodiceFiscale)
        Initialize();

        LibraryITDatifattura.CreateGeneralSetup();
        LibraryITDatifattura.CreateGeneralSetupDatifattura();

        // [GIVEN] Created Vendor "V" with "Fiscal Code" and related "Spesometro Appointment"
        Vendor.Get(LibrarySpesometro.CreateVendor(true, Vendor.Resident::Resident, true, true));
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(), Vendor."No.", WorkDate(), WorkDate());

        // [GIVEN] Created Purchase invoice "V".
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [GIVEN] Purchase Invoice was posted. VATReportHeader and VATReportLine was created for it.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVATUtils.CreateVATReportHeader(
          VATReportHeader, VATReportHeader."VAT Report Config. Code"::Datifattura, VATReportHeader."VAT Report Type"::Standard,
          WorkDate(), WorkDate());

        VATReportMediator.GetLines(VATReportHeader);
        FindVATReportLineByVendor(VATReportLine, VATReportHeader, VATReportLine."Document Type"::Invoice, Vendor."No.");
        DeleteUnrelatedVATReportLines(VATReportLine);

        // [WHEN] Export "VATReport" to XML file
        FilePath := LibraryITDatifattura.ExportVATReport(VATReportHeader);
        LibraryXPathXMLReader.Initialize(FilePath, '');
        LibraryXPathXMLReader.GetNodeByXPath(CodiceFiscaleTok, DotNetXmlNode);

        // [THEN] There is Vendor."Fiscal Code" value in "DatiFattura Header" with (XML.Node = CAP)
        Assert.AreEqual(Vendor."Fiscal Code", DotNetXmlNode.InnerText, CodiceFiscaleTok);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateVATPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"VAT Report Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateVATPostingSetupForSplitVATFullVAT(var VATPostingSetup: Record "VAT Posting Setup")
    var
        SplitVATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySplitVAT.CreateVATPostingSetupForSplitVAT(
          VATPostingSetup, SplitVATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        LibrarySplitVAT.UpdateVATPostingSetupFullVAT(SplitVATPostingSetup);
    end;

    local procedure DeleteUnrelatedVATReportLines(var VATReportLine: Record "VAT Report Line")
    begin
        VATReportLine.Reset();
        VATReportLine.SetRecFilter();
        VATReportLine.SetFilter("Line No.", '<>%1', VATReportLine."Line No.");
        VATReportLine.DeleteAll();
    end;

    local procedure FindVATReportLine(var VATReportLine: Record "VAT Report Line"; VATReportHeader: Record "VAT Report Header"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.SetRange("Document No.", DocumentNo);
        VATReportLine.SetRange("Document Type", DocumentType);
        VATReportLine.FindFirst();
    end;

    local procedure TestCleanup()
    var
        SplitVATTest: Record "Split VAT Test";
    begin
        SplitVATTest.DeleteAll(true);
    end;

    local procedure UpdateCustomerVatRegNo(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
    begin
        Customer.Get(CustomerNo);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code));
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Modify(true);
    end;

    local procedure UpdateVendorVatRegNo(VAR Vendor: Record "Vendor"; CountryRegionCode: Code[10]; VATRegistrationCode: Text[20]);
    begin
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Validate("VAT Registration No.", VATRegistrationCode);
        Vendor.Validate("Post Code", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Post Code"), DATABASE::Vendor));
        Vendor.Modify(true);
    end;

    local procedure FindVATReportLineByVendor(VAR VATReportLine: Record "VAT Report Line"; VATReportHeader: Record "VAT Report Header"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]);
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATReportLine.SetRange("Document Type", DocumentType);
        VATReportLine.FindFirst();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageText: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DatifatturaSuggestLinesRequestPageHandler(var DatifatturaSuggestLinesRequestPage: TestRequestPage "Datifattura Suggest Lines")
    begin
        DatifatturaSuggestLinesRequestPage.OK().Invoke();
    end;
}

