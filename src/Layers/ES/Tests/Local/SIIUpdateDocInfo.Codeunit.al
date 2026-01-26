codeunit 147552 "SII Update Doc. Info"
{
    // // [FEATURE] [SII] [UT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathSalesFacturaExpedidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/';
        XPathSalesIDOtroTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:Contraparte/sii:IDOtro/';
        XPathPurchIdOtroTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:Contraparte/sii:IDOtro/';
        XPathPurchFacturaRecibidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/';
        UploadTypeGlb: Option Regular,Intracommunity,RetryAccepted;
        ChangeQst: Label 'Do you want to change';

    [Test]
    [Scope('OnPrem')]
    procedure GetSIIDocUploadStateBySalesInvoice()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 232565] Function GetSIIDocUploadStateByCustLedgEntry return associated SII Doc. Upload State record by Customer Ledger Entry with Invoice

        Initialize();
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo();
        CustLedgerEntry.Insert();
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.TestField("Document No.", CustLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSIIDocUploadStateBySalesCrMemo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 232565] Function GetSIIDocUploadStateByCustLedgEntry return associated SII Doc. Upload State record by Customer Ledger Entry with Credit Memo

        Initialize();
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::"Credit Memo";
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo();
        CustLedgerEntry.Insert();
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.TestField("Document No.", CustLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSIIDocUploadStateByPurchInvoice()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 232565] Function GetSIIDocUploadStateByVendLedgEntry return associated SII Doc. Upload State record by Vendor Ledger Entry with Invoice

        Initialize();
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendorLedgerEntry.Insert();
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.TestField("Document No.", VendorLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSIIDocUploadStateByPurchCrMemo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 232565] Function GetSIIDocUploadStateByVendLedgEntry return associated SII Doc. Upload State record by Vendor Ledger Entry with Credit Memo

        Initialize();
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::"Credit Memo";
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendorLedgerEntry.Insert();
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.TestField("Document No.", VendorLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangeDocInfoOnAcceptedStatus()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [SCENARIO 232565] Stan cannot change "Sales Invoice Type" in SII. Doc. Upload State with status "Accepted"

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::Invoice);
        SIIDocUploadState.Validate(Status, SIIDocUploadState.Status::Accepted);
        SIIDocUploadState.Insert();
        SIIDocUploadState."Sales Invoice Type" := SIIDocUploadState."Sales Invoice Type"::"F1 Invoice";

        asserterror SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Invoice Type"));

        Assert.ExpectedError('Status must not be Accepted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDocInfoOnIncorrectStatus()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [SCENARIO 232565] Stan can change "Sales Invoice Type" in SII. Doc. Upload State with status "Incorrect"

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::Invoice);
        SIIDocUploadState.Validate(Status, SIIDocUploadState.Status::Incorrect);
        SIIDocUploadState.Insert();
        SIIDocUploadState."Sales Invoice Type" := SIIDocUploadState."Sales Invoice Type"::"F1 Invoice";

        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Invoice Type"));

        SIIDocUploadState.Find();
        SIIDocUploadState.TestField("Sales Invoice Type", SIIDocUploadState."Sales Invoice Type"::"F1 Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDocInfoOnPendingStatus()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [SCENARIO 261095] Stan can change "Sales Invoice Type" in SII. Doc. Upload State with status "Pending"

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::Invoice);
        SIIDocUploadState.Validate(Status, SIIDocUploadState.Status::Pending);
        SIIDocUploadState.Insert(true);
        SIIDocUploadState."Sales Invoice Type" := SIIDocUploadState."Sales Invoice Type"::"F1 Invoice";

        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Invoice Type"));

        SIIDocUploadState.Find();
        SIIDocUploadState.TestField("Sales Invoice Type", SIIDocUploadState."Sales Invoice Type"::"F1 Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangeSalesCrMemoTypeForSalesInvSIIDocUploadState()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 232565] Stan cannot change "Sales Cr. Memo Type" in SII. Doc. Upload State of Sales Invoice
        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::Invoice);

        asserterror SIIDocUploadState.Validate(
            "Sales Cr. Memo Type", SIIDocUploadState."Sales Cr. Memo Type"::"R1 Corrected Invoice");

        VerifyError(SIIDocUploadState.FieldName("Document Type"), Format(SIIDocUploadState."Document Type"::"Credit Memo"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangeSalesInTypeForSalesCrMemoSIIDocUploadState()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 232565] Stan cannot change "Sales Invoice Type" in SII. Doc. Upload State of Sales Credit Memo

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::"Credit Memo");

        asserterror SIIDocUploadState.Validate(
            "Sales Invoice Type", SIIDocUploadState."Sales Invoice Type"::"F1 Invoice");

        VerifyError(SIIDocUploadState.FieldName("Document Type"), Format(SIIDocUploadState."Document Type"::Invoice));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangeSalesCrMemoTypeForPurchCrMemoSIIDocUploadState()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 232565] Stan cannot change "Sales Cr. Memo Type" in SII. Doc. Upload State of Purchase Credit Memo

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Vendor Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::"Credit Memo");

        asserterror SIIDocUploadState.Validate(
            "Sales Cr. Memo Type", SIIDocUploadState."Sales Cr. Memo Type"::"R1 Corrected Invoice");

        VerifyError(SIIDocUploadState.FieldName("Document Source"), Format(SIIDocUploadState."Document Source"::"Customer Ledger"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangeSalesInTypeForPurchInvSIIDocUploadState()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 232565] Stan cannot change "Sales Invoice Type" in SII. Doc. Upload State of Purchase Invoice

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Vendor Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::Invoice);

        asserterror SIIDocUploadState.Validate(
            "Sales Invoice Type", SIIDocUploadState."Sales Invoice Type"::"F1 Invoice");

        VerifyError(SIIDocUploadState.FieldName("Document Source"), Format(SIIDocUploadState."Document Source"::"Customer Ledger"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangePurchCrMemoTypeForPurchInvSIIDocUploadState()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 232565] Stan cannot change "Purch. Cr. Memo Type" in SII. Doc. Upload State of Purchase Invoice
        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Vendor Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::Invoice);

        asserterror SIIDocUploadState.Validate(
            "Purch. Cr. Memo Type", SIIDocUploadState."Purch. Cr. Memo Type"::"R1 Corrected Invoice");

        VerifyError(SIIDocUploadState.FieldName("Document Type"), Format(SIIDocUploadState."Document Type"::"Credit Memo"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangePurchInTypeForPurchCrMemoSIIDocUploadState()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 232565] Stan cannot change "Purch. Invoice Type" in SII. Doc. Upload State of Purchase Credit Memo

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Vendor Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::"Credit Memo");

        asserterror SIIDocUploadState.Validate(
            "Purch. Invoice Type", SIIDocUploadState."Purch. Invoice Type"::"F1 Invoice");

        VerifyError(SIIDocUploadState.FieldName("Document Type"), Format(SIIDocUploadState."Document Type"::Invoice));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangePurchCrMemoTypeForSalesCrMemoSIIDocUploadState()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 232565] Stan cannot change "Purch. Cr. Memo Type" in SII. Doc. Upload State of Sales Credit Memo

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::"Credit Memo");

        asserterror SIIDocUploadState.Validate(
            "Purch. Cr. Memo Type", SIIDocUploadState."Purch. Cr. Memo Type"::"R1 Corrected Invoice");

        VerifyError(SIIDocUploadState.FieldName("Document Source"), Format(SIIDocUploadState."Document Source"::"Vendor Ledger"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangePurchInTypeForSalesInvSIIDocUploadState()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 232565] Stan cannot change "Purch. Invoice Type" in SII. Doc. Upload State of Sales Invoice

        Initialize();
        SIIDocUploadState.Init();
        SIIDocUploadState.Validate("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
        SIIDocUploadState.Validate("Document Type", SIIDocUploadState."Document Type"::Invoice);

        asserterror SIIDocUploadState.Validate(
            "Purch. Invoice Type", SIIDocUploadState."Purch. Invoice Type"::"F1 Invoice");

        VerifyError(SIIDocUploadState.FieldName("Document Source"), Format(SIIDocUploadState."Document Source"::"Vendor Ledger"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithUpdatedDocInfo()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 232565] XML has nodes with updated information from SII Doc. Upload State for Sales Invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with regular "Invoice Type" and "Special Scheme Code"
        PostSalesDocWithInvOrCrMemoType(CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0);

        // [GIVEN] Change "Invoice Type" to "F2 Simplified Invoice" and "Special Scheme Code" to "02 Export" on SII Doc. Upload State related to Customer Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.Validate("Sales Invoice Type", SIIDocUploadState."Sales Invoice Type"::"F2 Simplified Invoice");
        SIIDocUploadState.Validate("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoWithWithUpdatedDocInfo()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 232565] XML has nodes with updated information from SII Doc. Upload State for Sales Credit Memo with Type "Difference"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo type "Difference"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Difference);

        // [GIVEN] Change "Cr. Memo Type" to "R2 Corrected Invoice" and "Special Scheme Code" to "02 Export" on SII Doc. Upload State related to Customer Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.Validate("Sales Cr. Memo Type", SIIDocUploadState."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        SIIDocUploadState.Validate("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "R2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementWithWithUpdatedDocInfo()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 232565] XML has nodes with updated information from SII Doc. Upload State for Sales Credit Memo with Type "Replacement"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo type "Replacement"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [GIVEN] Change "Cr. Memo Type" to "R2 Corrected Invoice" and "Special Scheme Code" to "02 Export" on SII Doc. Upload State related to Customer Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.Validate("Sales Cr. Memo Type", SIIDocUploadState."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        SIIDocUploadState.Validate("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "R2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithWithUpdatedDocInfo()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 232565] XML has nodes with updated information from SII Doc. Upload State for Purchase Invoice
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PostPurchDocWithInvOrCrMemoType(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [GIVEN] Change "Invoice Type" to "F2 Simplified Invoice" and "Special Scheme Code" to "02 Special System Activities" on SII Doc. Upload State related to Vendor Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.Validate("Purch. Invoice Type", SIIDocUploadState."Purch. Invoice Type"::"F2 Simplified Invoice");
        SIIDocUploadState.Validate("Purch. Special Scheme Code",
          SIIDocUploadState."Purch. Special Scheme Code"::"02 Special System Activities");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDiffCrMemoWithWithUpdatedDocInfo()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 232565] XML has nodes with updated information from SII Doc. Upload State for Purchase Credit Memo with Type "Difference"

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo type "Difference"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Difference);

        // [GIVEN] Change "Cr. Memo Type" to "R2 Corrected Invoice" and "Special Scheme Code" to "02 Special System Activities" on SII Doc. Upload State related to Vendor Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.Validate("Purch. Cr. Memo Type", SIIDocUploadState."Purch. Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        SIIDocUploadState.Validate("Purch. Special Scheme Code",
          SIIDocUploadState."Purch. Special Scheme Code"::"02 Special System Activities");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReplacementWithWithUpdatedDocInfo()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 232565] XML has nodes with updated information from SII Doc. Upload State for Purchase Credit Memo with Type "Replacement"

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo type "Replacement"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement);

        // [GIVEN] Change "Cr. Memo Type" to "R2 Corrected Invoice" and "Special Scheme Code" to "02 Special System Activities" on SII Doc. Upload State related to Vendor Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.Validate("Purch. Cr. Memo Type", SIIDocUploadState."Purch. Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        SIIDocUploadState.Validate("Purch. Special Scheme Code",
          SIIDocUploadState."Purch. Special Scheme Code"::"02 Special System Activities");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvNoWithUpdatedDocInfo()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 232565] XML has nodes with updated information from SII Doc. Upload State for Service Invoice

        Initialize();

        // [GIVEN] Posted Service Invoice with "Non Taxable Type" = "Non Taxable Art 7-14 and others"
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry, PostServiceDocWithDocInfo(ServiceHeader."Document Type"::Invoice));

        // [GIVEN] Change "Invoice Type" to "F2 Simplified Invoice" and "Special Scheme Code" to "02 Export" on SII Doc. Upload State related to Customer Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.Validate("Sales Invoice Type", SIIDocUploadState."Sales Invoice Type"::"F2 Simplified Invoice");
        SIIDocUploadState.Validate("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoNoWithUpdatedDocInfo()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 232565] XML has nodes with updated information from SII Doc. Upload State for Service Credit Memo

        Initialize();

        // [GIVEN] Posted Service Credit Memo
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry, PostServiceDocWithDocInfo(ServiceHeader."Document Type"::"Credit Memo"));

        // [GIVEN] Change "Cr. Memo Type" to "R2 Corrected Invoice" and "Special Scheme Code" to "02 Export" on SII Doc. Upload State related to Customer Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.Validate("Sales Cr. Memo Type", SIIDocUploadState."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        SIIDocUploadState.Validate("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Service Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "R2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithUpdatedIDType()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 288410] XML has nodes with updated ID Type from SII Doc. Upload State for Sales Invoice

        Initialize();

        // [GIVEN] Posted Sales Invoice with regular "ID Type"
        PostSalesInvIntracommunitary(CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0);

        // [GIVEN] Change "ID Type" to "04" on SII Doc. Upload State related to Customer Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.Validate(IDType, SIIDocUploadState.IDType::"04-ID Document");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] IDType is "04" in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithWithUpdatedIDType()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 232565] XML has nodes with updated ID Type from SII Doc. Upload State for Purchase Invoice
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PostPurchInvIntracommunitary(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [GIVEN] Change "Invoice Type" to "F2 Simplified Invoice", "Special Scheme Code" to "02 Special System Activities", "ID Type" to "04" on SII Doc. Upload State related to Vendor Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.Validate(IDType, SIIDocUploadState.IDType::"04-ID Document");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] IDType is "04" in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchIdOtroTok, 'sii:IDType', '04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvNoWithUpdatedIDType()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 232565] XML has nodes with updated ID Type from SII Doc. Upload State for Service Invoice

        Initialize();

        // [GIVEN] Posted Service Invoice with "Non Taxable Type" = "Non Taxable Art 7-14 and others"
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry, PostServiceDocIntracommunitary(ServiceHeader."Document Type"::Invoice, 0));

        // [GIVEN] Change "Invoice Type" to "F2 Simplified Invoice", "Special Scheme Code" to "02 Export", "ID Type" to "04" on SII Doc. Upload State related to Customer Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.Validate(IDType, SIIDocUploadState.IDType::"04-ID Document");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] IDType is "04" in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemovalSalesCrMemoIDType()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 311013] Exported XML file has no ID Type xml node for Sales Credit Memo with "Correction Type" = Removal

        Initialize();

        // [GIVEN] Posted Removal Sales Credit Memo with regular "ID Type"
        PostSalesInvIntracommunitary(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Removal);

        // [WHEN] Create xml for Posted Removal Sales Credit Removal
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] No IDType in exported SII file
        LibrarySII.VerifyNodeCountWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '04', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemovalPurchCrMemoWithWithUpdatedIDType()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 311013] XML has nodes with updated ID Type from SII Doc. Upload State for Purchase Credit Memo with "Correction Type" = Removal

        Initialize();

        // [GIVEN] Posted Removal Purchase Credit Memo with regular "ID Type"
        PostPurchInvIntracommunitary(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Removal);

        // [GIVEN] Change "ID Type" to "04" on SII Doc. Upload State related to Vendor Ledger Entry
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.TestField(IDType, SIIDocUploadState.IDType::"02-VAT Registration No.");
        SIIDocUploadState.Validate(IDType, SIIDocUploadState.IDType::"04-ID Document");
        SIIDocUploadState.Modify(true);

        // [WHEN] Create xml for Posted Removal Purchase Credit Memo with regular "ID Type"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] IDType is "04" in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchIdOtroTok, 'sii:IDType', '04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemovalServCrMemoWithIDType()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 311013] Exported XML file has no ID Type xml node for Service Credit Memo with "Correction Type" = Removal

        Initialize();

        // [GIVEN] Posted Removal Service Credit Memo with regular "ID Type"
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry, PostServiceDocIntracommunitary(
            ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Correction Type"::Removal));

        // [WHEN] Create xml for Posted Service Credit Memo with regular "ID Type"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), IncorrectXMLDocErr);

        // [THEN] No IDType in exported SII file
        LibrarySII.VerifyNodeCountWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '04', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIDocUploadStateGetsUpdatedOnSalesInvoiceUpdate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        CompanyName: Text[10];
        VATRegistrationNo: Text[10];
    begin
        // [FEAUTURE] [Sales] [Invoice]
        // [SCENARIO 333224] Changes introduced in posted Sales Invoice reflects on the related SII Document Upload State record

        Initialize();

        // [GIVEN] Posted sales invoice with default values for Invoice Type, Special Scheme Code, IDType
        PostSalesDocument(CustLedgerEntry, "Sales Document Type"::Invoice, LibrarySales.CreateCustomerNo(), 0);
        SalesInvoiceHeader.Get(CustLedgerEntry."Document No.");

        // [GIVEN] Default values gets changed in posted document
        SalesInvoiceHeader."Invoice Type" := SalesInvoiceHeader."Invoice Type"::"F2 Simplified Invoice";
        SalesInvoiceHeader."Special Scheme Code" := SalesInvoiceHeader."Special Scheme Code"::"02 Export";
        SalesInvoiceHeader."ID Type" := SalesInvoiceHeader."ID Type"::"02-VAT Registration No.";
        CompanyName := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Succeeded Company Name" := CompanyName;
        VATRegistrationNo := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Succeeded VAT Registration No." := VATRegistrationNo;

        // [WHEN] Run codeunit "Sales Invoice Header - Edit" against posted document
        CODEUNIT.Run(CODEUNIT::"Sales Invoice Header - Edit", SalesInvoiceHeader);

        // [THEN] SII Document Upload State of the posted document has updated values
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.TestField(
          "Sales Invoice Type", SIIDocUploadState."Sales Invoice Type"::"F2 Simplified Invoice");
        SIIDocUploadState.TestField(
          "Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
        SIIDocUploadState.TestField(IDType, SIIDocUploadState.IDType::"02-VAT Registration No.");
        SIIDocUploadState.TestField("Succeeded Company Name", CompanyName);
        SIIDocUploadState.TestField("Succeeded VAT Registration No.", VATRegistrationNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIDocUploadStateGetsUpdatedOnSalesCrMemoUpdate()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChangedSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEAUTURE] [Sales] [Credit Memo]
        // [SCENARIO 333224] Changes introduced in posted Sales Credit Memo reflects on the related SII Document Upload State record

        Initialize();

        // [GIVEN] Posted sales credit memo with default values for Invoice Type and Special Scheme Code
        PostSalesDocument(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo(), 0);
        SalesCrMemoHeader.Get(CustLedgerEntry."Document No.");

        // [GIVEN] Default values gets changed in posted document
        ChangedSalesCrMemoHeader := SalesCrMemoHeader;
        ChangedSalesCrMemoHeader."Cr. Memo Type" := ChangedSalesCrMemoHeader."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)";
        ChangedSalesCrMemoHeader."Special Scheme Code" := ChangedSalesCrMemoHeader."Special Scheme Code"::"02 Export";
        ChangedSalesCrMemoHeader."ID Type" := ChangedSalesCrMemoHeader."ID Type"::"02-VAT Registration No.";
        ChangedSalesCrMemoHeader."Succeeded Company Name" := LibraryUtility.GenerateGUID();
        ChangedSalesCrMemoHeader."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID();

        // [WHEN] Run codeunit "Sales Cr.Memo Header - Edit" against posted document
        CODEUNIT.Run(CODEUNIT::"Sales Credit Memo Hdr. - Edit", ChangedSalesCrMemoHeader);

        // [THEN] SII Document Upload State of the posted document has updated values
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.TestField(
          "Sales Cr. Memo Type", SIIDocUploadState."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        SIIDocUploadState.TestField("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
        SIIDocUploadState.TestField(IDType, SIIDocUploadState.IDType::"02-VAT Registration No.");
        SIIDocUploadState.TestField("Succeeded Company Name", ChangedSalesCrMemoHeader."Succeeded Company Name");
        SIIDocUploadState.TestField("Succeeded VAT Registration No.", ChangedSalesCrMemoHeader."Succeeded VAT Registration No.");

        // [THEN] The changes in Sales Credit Memo Header have been saved (Bug id 452979: Fields added to the posted sales/purchase credit memo page)
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.TestField("Cr. Memo Type", ChangedSalesCrMemoHeader."Cr. Memo Type");
        SalesCrMemoHeader.TestField("Special Scheme Code", ChangedSalesCrMemoHeader."Special Scheme Code");
        SalesCrMemoHeader.TestField("Succeeded Company Name", ChangedSalesCrMemoHeader."Succeeded Company Name");
        SalesCrMemoHeader.TestField("Succeeded VAT Registration No.", ChangedSalesCrMemoHeader."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIDocUploadStateGetsUpdatedOnPurchInvoiceUpdate()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        CompanyName: Text[10];
        VATRegistrationNo: Text[10];
    begin
        // [FEAUTURE] [Purchase] [Invoice]
        // [SCENARIO 333224] Changes introduced in posted Purchase Invoice reflects on the related SII Document Upload State record

        Initialize();

        // [GIVEN] Posted purchase invoice with default values for Invoice Type, Special Scheme Code, IDType
        PostPurchaseDocument(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), 0);
        PurchInvHeader.Get(VendorLedgerEntry."Document No.");

        // [GIVEN] Default values gets changed in posted document
        PurchInvHeader."Invoice Type" := PurchInvHeader."Invoice Type"::"F2 Simplified Invoice";
        PurchInvHeader."Special Scheme Code" := PurchInvHeader."Special Scheme Code"::"02 Special System Activities";
        PurchInvHeader."ID Type" := PurchInvHeader."ID Type"::"02-VAT Registration No.";
        CompanyName := LibraryUtility.GenerateGUID();
        PurchInvHeader."Succeeded Company Name" := CompanyName;
        VATRegistrationNo := LibraryUtility.GenerateGUID();
        PurchInvHeader."Succeeded VAT Registration No." := VATRegistrationNo;

        // [WHEN] Run codeunit "Purch. Inv. Header - Edit" against posted document
        CODEUNIT.Run(CODEUNIT::"Purch. Inv. Header - Edit", PurchInvHeader);

        // [THEN] SII Document Upload State of the posted document has updated values
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.TestField("Purch. Invoice Type", SIIDocUploadState."Purch. Invoice Type"::"F2 Simplified Invoice");
        SIIDocUploadState.TestField(
          "Purch. Special Scheme Code", SIIDocUploadState."Purch. Special Scheme Code"::"02 Special System Activities");
        SIIDocUploadState.TestField(IDType, SIIDocUploadState.IDType::"02-VAT Registration No.");
        SIIDocUploadState.TestField("Succeeded Company Name", CompanyName);
        SIIDocUploadState.TestField("Succeeded VAT Registration No.", VATRegistrationNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIDocUploadStateGetsUpdatedOnPurchCrMemoUpdate()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ChangedPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEAUTURE] [Purchase] [Credit Memo]
        // [SCENARIO 333224] Changes introduced in posted Purchase Credit Memo reflects on the related SII Document Upload State record

        Initialize();

        // [GIVEN] Posted purchase purchase memo with default values for Invoice Type and Special Scheme Code
        PostPurchaseDocument(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo(), 0);
        PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.");

        // [GIVEN] Default values gets changed in posted document
        ChangedPurchCrMemoHdr := PurchCrMemoHdr;
        ChangedPurchCrMemoHdr."Cr. Memo Type" := ChangedPurchCrMemoHdr."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)";
        ChangedPurchCrMemoHdr."Special Scheme Code" := ChangedPurchCrMemoHdr."Special Scheme Code"::"02 Special System Activities";
        ChangedPurchCrMemoHdr."ID Type" := ChangedPurchCrMemoHdr."ID Type"::"02-VAT Registration No.";
        ChangedPurchCrMemoHdr."Succeeded Company Name" := LibraryUtility.GenerateGUID();
        ChangedPurchCrMemoHdr."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID();

        // [WHEN] Run codeunit "Purch. Cr.Memo Header - Edit" against posted document
        CODEUNIT.Run(CODEUNIT::"Purch. Cr. Memo Hdr. - Edit", ChangedPurchCrMemoHdr);

        // [THEN] SII Document Upload State of the posted document has updated values
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIDocUploadState.TestField(
          "Purch. Cr. Memo Type", SIIDocUploadState."Purch. Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        SIIDocUploadState.TestField(
          "Purch. Special Scheme Code", SIIDocUploadState."Purch. Special Scheme Code"::"02 Special System Activities");
        SIIDocUploadState.TestField(IDType, SIIDocUploadState.IDType::"02-VAT Registration No.");
        SIIDocUploadState.TestField("Succeeded Company Name", ChangedPurchCrMemoHdr."Succeeded Company Name");
        SIIDocUploadState.TestField("Succeeded VAT Registration No.", ChangedPurchCrMemoHdr."Succeeded VAT Registration No.");

        // [THEN] The changes in Purchase Credit Memo Header have been saved (Bug id 452979: Fields added to the posted sales/purchase credit memo page)
        PurchCrMemoHdr.Find();
        PurchCrMemoHdr.TestField("Cr. Memo Type", PurchCrMemoHdr."Cr. Memo Type");
        PurchCrMemoHdr.TestField("Special Scheme Code", PurchCrMemoHdr."Special Scheme Code");
        PurchCrMemoHdr.TestField("Succeeded Company Name", PurchCrMemoHdr."Succeeded Company Name");
        PurchCrMemoHdr.TestField("Succeeded VAT Registration No.", PurchCrMemoHdr."Succeeded VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodeChangesOnBillToCustValidationSales()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Special Scheme Code] [UT]
        // [SCENARIO 352810] "Special Scheme Code" changes when different "Bill-To Customer No." selects in the sales document

        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(ChangeQst);
        SalesHeader.Validate("Bill-to Customer No.", CreateForeignCustomer());
        SalesHeader.TestField("Special Scheme Code", SalesHeader."Special Scheme Code"::"02 Export");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodeChangesOnBillToCustValidationService()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Special Scheme Code] [UT]
        // [SCENARIO 352810] "Special Scheme Code" changes when different "Bill-To Customer No." selects in the service document

        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(ChangeQst);
        ServiceHeader.Validate("Bill-to Customer No.", CreateForeignCustomer());
        ServiceHeader.TestField("Special Scheme Code", ServiceHeader."Special Scheme Code"::"02 Export");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodeChangesOnPayToVendValidation()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Special Scheme Code] [UT]
        // [SCENARIO 352810] "Special Scheme Code" changes when different "Pay-To Vendor No." selects in the purchase document

        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryVariableStorage.Enqueue(ChangeQst);
        PurchaseHeader.Validate("Pay-to Vendor No.", CreateIntracommunityVendor());
        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"09 Intra-Community Acquisition");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIDocUploadStateGetsUpdatedOnServiceInvoiceUpdate()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        ServiceHeader: Record "Service Header";
        CompanyName: Text[10];
        VATRegistrationNo: Text[10];
    begin
        // [FEAUTURE] [Service] [Invoice]
        // [SCENARIO 373682] Changes introduced in posted Service Invoice reflects on the related SII Document Upload State record.
        Initialize();

        // [GIVEN] Posted Service Invoice with default values for Invoice Type, Special Scheme Code, IDType.
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
            CustLedgerEntry, PostServiceDocWithDocInfo(ServiceHeader."Document Type"::Invoice));
        ServiceInvoiceHeader.Get(CustLedgerEntry."Document No.");

        // [GIVEN] Default values gets changed in posted document.
        ServiceInvoiceHeader."Invoice Type" := ServiceInvoiceHeader."Invoice Type"::"F2 Simplified Invoice";
        ServiceInvoiceHeader."Special Scheme Code" := ServiceInvoiceHeader."Special Scheme Code"::"02 Export";
        ServiceInvoiceHeader."ID Type" := ServiceInvoiceHeader."ID Type"::"02-VAT Registration No.";
        CompanyName := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Succeeded Company Name" := CompanyName;
        VATRegistrationNo := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Succeeded VAT Registration No." := VATRegistrationNo;

        // [WHEN] Run codeunit "Service Invoice Header - Edit" against posted document.
        Codeunit.Run(Codeunit::"Service Inv. Header - Edit", ServiceInvoiceHeader);

        // [THEN] SII Document Upload State of the posted document has updated values.
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.TestField(
            "Sales Invoice Type", SIIDocUploadState."Sales Invoice Type"::"F2 Simplified Invoice");
        SIIDocUploadState.TestField(
            "Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
        SIIDocUploadState.TestField(IDType, SIIDocUploadState.IDType::"02-VAT Registration No.");
        SIIDocUploadState.TestField("Succeeded Company Name", CompanyName);
        SIIDocUploadState.TestField("Succeeded VAT Registration No.", VATRegistrationNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIDocUploadStateGetsUpdatedOnServiceCrMemoUpdate()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        ServiceHeader: Record "Service Header";
    begin
        // [FEAUTURE] [Service] [Credit Memo]
        // [SCENARIO 373682] Changes introduced in posted Service Credit Memo reflects on the related SII Document Upload State record.
        Initialize();

        // [GIVEN] Posted Service Credit Memo with default values for Cr. Memo Type and Special Scheme Code.
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
            CustLedgerEntry, PostServiceDocWithDocInfo(ServiceHeader."Document Type"::"Credit Memo"));
        ServiceCrMemoHeader.Get(CustLedgerEntry."Document No.");

        // [GIVEN] Default values gets changed in posted document.
        ServiceCrMemoHeader."Cr. Memo Type" := ServiceCrMemoHeader."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)";
        ServiceCrMemoHeader."Special Scheme Code" := ServiceCrMemoHeader."Special Scheme Code"::"02 Export";

        // [WHEN] Run codeunit "Service Cr. Memo Header - Edit" against posted document.
        Codeunit.Run(Codeunit::"Service Cr. Memo Header - Edit", ServiceCrMemoHeader);

        // [THEN] SII Document Upload State of the posted document has updated values.
        SIIDocUploadState.GetSIIDocUploadStateByCustLedgEntry(CustLedgerEntry);
        SIIDocUploadState.TestField(
            "Sales Cr. Memo Type", SIIDocUploadState."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        SIIDocUploadState.TestField("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();

        IsInitialized := true;
    end;

    local procedure CreateForeignCustomer(): Code[20]
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateIntracommunityVendor(): Code[20]
    var
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure PostSalesDocWithInvOrCrMemoType(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrType: Option)
    begin
        PostSalesDocument(CustLedgerEntry, DocType, LibrarySales.CreateCustomerNo(), CorrType);
    end;

    local procedure PostSalesInvIntracommunitary(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    begin
        PostSalesDocument(CustLedgerEntry, DocType, CreateIntracommunityCustomer(), CorrectionType);
    end;

    local procedure PostSalesDocument(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; CorrType: Option)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchDocWithInvOrCrMemoType(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    begin
        PostPurchaseDocument(VendorLedgerEntry, DocType, LibraryPurchase.CreateVendorNo(), CorrType);
    end;

    local procedure PostPurchInvIntracommunitary(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; CorrectionType: Option)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CreateEUCountryRegion());
        Vendor.Modify(true);
        PostPurchaseDocument(VendorLedgerEntry, DocType, Vendor."No.", CorrectionType);
    end;

    local procedure PostPurchaseDocument(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; VendNo: Code[20]; CorrType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostServiceDocWithDocInfo(DocType: Enum "Service Document Type"): Code[20]
    begin
        exit(PostServiceDocument(DocType, LibrarySales.CreateCustomerNo(), 0));
    end;

    local procedure PostServiceDocIntracommunitary(DocType: Enum "Service Document Type"; CorrectionType: Option): Code[20]
    begin
        exit(PostServiceDocument(DocType, CreateIntracommunityCustomer(), CorrectionType));
    end;

    local procedure PostServiceDocument(DocType: Enum "Service Document Type"; CustNo: Code[20]; CorrectionType: Option): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibrarySII.CreateServiceHeader(ServiceHeader, DocType, CustNo, '');
        ServiceHeader.Validate("Correction Type", CorrectionType);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          LibrarySII.CreateItemWithSpecificVATSetup(ServiceHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)),
          LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateEUCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateIntracommunityCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CreateEUCountryRegion());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure VerifyError(FieldName: Text; Value: Text)
    begin
        Assert.ExpectedTestFieldError(FieldName, Value);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, LibraryVariableStorage.DequeueText()) <> 0, 'Incorrect text');
        Reply := true;
    end;
}

