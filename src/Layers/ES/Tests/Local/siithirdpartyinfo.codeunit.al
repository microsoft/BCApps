codeunit 147561 "SII Third Party Info"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        ChangeFieldMsg: Label 'Do you want to change';
        XPathSalesContraparteTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:Contraparte/';
        XPathPurchaseContraparteTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiLR:IDFactura/sii:IDEmisorFactura/';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BillToCustExportsInSalesInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Bill-To Customer" of Sales Invoice exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Bill-to/Pay-to No."

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Bill-to/Pay-to No." in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Sales Invoice has "Sell-To Customer" = Local customer with "VAT Registration No." = "X" and "Bill-To Customer" = Foreign customer with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostSalesDocWithDiffBillToCust(CustLedgerEntry, "Sales Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "X" of the local customer
        Customer.Get(CustLedgerEntry."Customer No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:NIF', Customer."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SellToCustExportsInSalesInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Sell-To Customer" of Sales Invoice exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Sell-to/Buy-from No"

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Sell-to/Buy-from No" in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Sales Invoice has "Sell-To Customer" = Local customer with "VAT Registration No." = "X" and "Bill-To Customer" = Foreign customer with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostSalesDocWithDiffBillToCust(CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "Y" of the foreign customer
        Customer.Get(CustLedgerEntry."Sell-to Customer No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:IDOtro/sii:ID', Customer."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BillToCustExportsInSalesCrMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Bill-To Customer" of Sales Credit Memo exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Bill-to/Pay-to No."

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Bill-to/Pay-to No." in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Sales Credit Memo has "Sell-To Customer" = Local customer with "VAT Registration No." = "X" and "Bill-To Customer" = Foreign customer with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostSalesDocWithDiffBillToCust(CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "X" of the local customer
        Customer.Get(CustLedgerEntry."Customer No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:NIF', Customer."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SellToCustExportsInSalesCrMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Sell-To Customer" of Sales Credit Memo exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Sell-to/Buy-from No"

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Sell-to/Buy-from No" in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Sales Credit Memo has "Sell-To Customer" = Local customer with "VAT Registration No." = "X" and "Bill-To Customer" = Foreign customer with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostSalesDocWithDiffBillToCust(CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "Y" of the foreign customer
        Customer.Get(CustLedgerEntry."Sell-to Customer No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:IDOtro/sii:ID', Customer."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BillToCustExportsInRemovalSalesCrMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Bill-To Customer" of Removal Sales Credit Memo exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Bill-to/Pay-to No."

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Bill-to/Pay-to No." in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Removal Sales Credit Memo has "Sell-To Customer" = Local customer with "VAT Registration No." = "X" and "Bill-To Customer" = Foreign customer with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostSalesDocWithDiffBillToCust(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Removal);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "X" of the local customer
        Customer.Get(CustLedgerEntry."Customer No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:NIF', Customer."VAT Registration No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SellToCustExportsInRemovalSalesCrMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Sell-To Customer" of Removal Sales Credit Memo exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Sell-to/Buy-from No"

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Sell-to/Buy-from No" in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Removal Sales Credit Memo has "Sell-To Customer" = Local customer with "VAT Registration No." = "X" and "Bill-To Customer" = Foreign customer with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostSalesDocWithDiffBillToCust(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Removal);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "Y" of the foreign customer
        Customer.Get(CustLedgerEntry."Sell-to Customer No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:IDOtro/sii:ID', Customer."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BillToCustExportsInPurchInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Bill-To Customer" of Purchase Invoice exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Bill-to/Pay-to No."

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Bill-to/Pay-to No." in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Purchase Invoice has "Sell-To Customer" = Local customer with "VAT Registration No." = "X" and "Bill-To Customer" = Foreign customer with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostPurchaseDocWithDiffBillToCust(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "X" of the local customer
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchaseContraparteTok, 'sii:NIF', Vendor."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SellToCustExportsInPurchInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Sell-To Vendor" of Purchase Invoice exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Sell-to/Buy-from No"

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Sell-to/Buy-from No" in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Purchase Invoice has "Buy-From Vendor" = Local Vendor with "VAT Registration No." = "X" and "Pay-To Vendor" = Foreign Vendor with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostPurchaseDocWithDiffBillToCust(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "Y" of the foreign Vendor
        Vendor.Get(VendorLedgerEntry."Buy-from Vendor No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchaseContraparteTok, 'sii:IDOtro/sii:ID', Vendor."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BillToCustExportsInPurchCrMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Bill-To Vendor" of Purchase Credit Memo exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Bill-to/Pay-to No."

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Bill-to/Pay-to No." in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Purchase Credit Memo has "Buy-From Vendor" = Local Vendor with "VAT Registration No." = "X" and "Pay-To Vendor" = Foreign Vendor with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostPurchaseDocWithDiffBillToCust(VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "X" of the local Vendor
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchaseContraparteTok, 'sii:NIF', Vendor."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SellToCustExportsInPurchCrMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Sell-To Vendor" of Purchase Credit Memo exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Sell-to/Buy-from No"

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Sell-to/Buy-from No" in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Purchase Credit Memo has "Buy-From Vendor" = Local Vendor with "VAT Registration No." = "X" and "Pay-To Vendor" = Foreign Vendor with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostPurchaseDocWithDiffBillToCust(VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "Y" of the foreign Vendor
        Vendor.Get(VendorLedgerEntry."Buy-from Vendor No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchaseContraparteTok, 'sii:IDOtro/sii:ID', Vendor."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BillToCustExportsInRemovalPurchCrMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Bill-To Vendor" of Removal Purchase Credit Memo exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Bill-to/Pay-to No."

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Bill-to/Pay-to No." in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Purchase Removal Credit Memo has "Buy-From Vendor" = Local Vendor with "VAT Registration No." = "X" and "Pay-To Vendor" = Foreign Vendor with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostPurchaseDocWithDiffBillToCust(
          VendorLedgerEntry, "Purchase Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Removal);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "X" of the local Vendor
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchaseContraparteTok, 'sii:NIF', Vendor."VAT Registration No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SellToCustExportsInRemovalPurchCrMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 327263] The information about "Sell-To Vendor" of Removal Purchase Credit Memo exports to SII XML file
        // [SCENARIO 327263] when "Bill-to/Sell-to VAT Calc." field of General Ledger Setup has value "Sell-to/Buy-from No"

        Initialize();

        // [GIVEN] "Bill-to/Sell-to VAT Calc." option has value "Sell-to/Buy-from No" in General Ledger Setup
        SetBillToSellToVATCalcInGenLedgSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Purchase Removal Credit Memo has "Buy-From Vendor" = Local Vendor with "VAT Registration No." = "X" and "Pay-To Vendor" = Foreign Vendor with "VAT Registration No." = "X"
        LibraryVariableStorage.Enqueue(ChangeFieldMsg);
        PostPurchaseDocWithDiffBillToCust(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Removal);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has value about VAT Registration No. "Y" of the foreign Vendor
        Vendor.Get(VendorLedgerEntry."Buy-from Vendor No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchaseContraparteTok, 'sii:IDOtro/sii:ID', Vendor."VAT Registration No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();

        IsInitialized := true;
    end;

    local procedure SetBillToSellToVATCalcInGenLedgSetup(NewBillToSellToVATCalcType: Enum "G/L Setup VAT Calculation")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", NewBillToSellToVATCalcType);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure PostSalesDocWithDiffBillToCust(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        ForeignCustomer: Record Customer;
        LocalCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        LibrarySII.CreateForeignCustWithVATSetup(ForeignCustomer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, ForeignCustomer."No.");
        LibrarySII.CreateCustWithVATSetup(LocalCustomer);
        LocalCustomer.Validate("VAT Bus. Posting Group", ForeignCustomer."VAT Bus. Posting Group");
        LocalCustomer.Modify(true);

        SalesHeader.Validate("Bill-to Customer No.", LocalCustomer."No.");
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(LocalCustomer."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchaseDocWithDiffBillToCust(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    var
        ForeignVendor: Record Vendor;
        LocalVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ItemNo: Code[20];
    begin
        LibrarySII.CreateForeignVendWithVATSetup(ForeignVendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, ForeignVendor."No.");
        LocalVendor.Get(LibrarySII.CreateVendWithVATSetup(ForeignVendor."VAT Bus. Posting Group"));

        PurchaseHeader.Validate("Pay-to Vendor No.", LocalVendor."No.");
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(LocalVendor."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, ItemNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;
}

