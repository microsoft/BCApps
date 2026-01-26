codeunit 144204 "FatturaPA Discount"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [Export]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Invoice] [Invoice Discount]
        // [SCENARIO 298793] Invoice Discount Amount of Sales Invoice exports to multiple nodes in FatturaPA file

        Initialize();

        // [GIVEN] Posted Sales Invoice with Quantity = 5, "Line Amount" = 100, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer();
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 1 / LibraryRandom.RandIntInRange(3, 10), 0);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali has value 20
        // TFS ID: 308856
        // TFS ID 375065: PrezzoTotale has a value without invoice discount
        // [THEN] Prezzo Totale node has value 96 (100 - 4)
        // [THEN] Importo node under DettaglioLinee has value 4 (Invoice Discount Amount / Quantity)
        // [THEN] An invoice discount amount under ScontoMaggiorazione xml node has eight decimal places
        // TFS ID 348540: Changes in the format of Italian electronic invoices
        VerifyInvDiscAmount(
          TempBlob, SalesLine."Line Amount" - Round(SalesLine."Inv. Discount Amount" / SalesLine.Quantity),
          SalesLine."Inv. Discount Amount", SalesLine."Unit Price", SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Invoice Discount]
        // [SCENARIO 298793] Invoice Discount Amount of Sales Credit Memo exports to multiple nodes in FatturaPA file

        Initialize();

        // [GIVEN] Posted Sales Invoice with Quantity = 5, "Line Amount" = 100, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer();
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 1 / LibraryRandom.RandIntInRange(3, 10), 0);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali has value 20
        // TFS ID: 308856
        // TFS ID 375065: PrezzoTotale has a value without invoice discount
        // [THEN] Prezzo Totale node has value 96 (100 - 4)
        // [THEN] Importo node under DettaglioLinee has value 4 (Invoice Discount Amount / Quantity)
        // [THEN] An invoice discount amount under ScontoMaggiorazione xml node has eight decimal places
        // TFS ID 348540: Changes in the format of Italian electronic invoices
        VerifyInvDiscAmount(
          TempBlob, SalesLine."Line Amount" - Round(SalesLine."Inv. Discount Amount" / SalesLine.Quantity),
          SalesLine."Inv. Discount Amount", SalesLine."Unit Price", SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithInvoiceDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Service] [Invoice] [Invoice Discount]
        // [SCENARIO 298066] Invoice Discount Amount of Service Invoice exports to multiple nodes in FatturaPA file

        Initialize();

        // [GIVEN] Posted Service Invoice with Quantity = 5, "Line Amount" = 100, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer();
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::Invoice);
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 1 / LibraryRandom.RandIntInRange(3, 10), 0);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali has value 20
        // TFS ID: 308856
        // TFS ID 375065: PrezzoTotale has a value without invoice discount
        // [THEN] Prezzo Totale node has value 96 (100 - 4)
        // [THEN] Importo node under DettaglioLinee has value 4 (Invoice Discount Amount / Quantity)
        // [THEN] An invoice discount amount under ScontoMaggiorazione xml node has eight decimal places
        // TFS ID 348540: Changes in the format of Italian electronic invoices
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        VerifyInvDiscAmount(
          TempBlob, ServiceLine."Line Amount" - Round(ServiceLine."Inv. Discount Amount" / ServiceLine.Quantity),
          ServiceLine."Inv. Discount Amount", ServiceLine."Unit Price", ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoInvoiceDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Service] [Credit Memo] [Invoice Discount]
        // [SCENARIO 298066] Invoice Discount Amount of Service Credit Memo exports to multiple nodes in FatturaPA file

        Initialize();

        // [GIVEN] Posted Service Invoice with Quantity = 5, "Line Amount" = 100, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer();
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 1 / LibraryRandom.RandIntInRange(3, 10), 0);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali has value 20
        // TFS ID: 308856
        // TFS ID 375065: PrezzoTotale has a value without invoice discount
        // [THEN] Prezzo Totale node has value 96 (100 - 4)
        // [THEN] Importo node under DettaglioLinee has value 4 (Invoice Discount Amount / Quantity)
        // [THEN] An invoice discount amount under ScontoMaggiorazione xml node has eight decimal places
        // TFS ID 348540: Changes in the format of Italian electronic invoices
        ServiceCrMemoHeader.FindFirst();
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.FindFirst();
        VerifyInvDiscAmount(
          TempBlob, ServiceLine."Line Amount" - Round(ServiceLine."Inv. Discount Amount" / ServiceLine.Quantity),
          ServiceLine."Inv. Discount Amount", ServiceLine."Unit Price", ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Invoice] [Line Discount]
        // [SCENARIO 298793] Line Discount Percent of Sales Invoice must be exported to Percentuale node

        Initialize();

        // [GIVEN] Posted Sales Invoice with "Line Discount %" = 5
        CustomerNo := CreateCustomer();
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(TempBlob, SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoLineDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Line Discount]
        // [SCENARIO 298793] Line Discount Percent of Sales Credit Memo must be exported to Percentuale node

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "Line Discount %" = 5
        CustomerNo := CreateCustomer();
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(TempBlob, SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceLineDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Service] [Invoice] [Line Discount]
        // [SCENARIO 298066] Line Discount Percent of Service Invoice must be exported to Percentuale node

        Initialize();

        // [GIVEN] Posted Service Invoice with "Line Discount %" = 5
        CustomerNo := CreateCustomer();
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::Invoice);
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(TempBlob, ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoLineDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Service] [Credit Memo] [Line Discount]
        // [SCENARIO 298066] Line Discount Percent of Service Credit Memo must be exported to Percentuale node

        Initialize();

        // [GIVEN] Posted Service Credit Memo with "Line Discount %" = 5
        CustomerNo := CreateCustomer();
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(TempBlob, ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceBothDiscounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Invoice] [Line Discount] [Invoice Discount]
        // [SCENARIO 298793] Line Discount Percent and Invoice Discount Amount of Sales Invoice must be exported to specific nodes of FatturaPA file

        Initialize();

        // [GIVEN] Posted Sales Invoice with "Line Discount %" = 5
        CustomerNo := CreateCustomer();
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(TempBlob, SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoBothDiscounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Line Discount] [Invoice Discount]
        // [SCENARIO 298793] Line Discount Percent and Invoice Discount Amount of Sales Credit Memo must be exported to specific nodes of FatturaPA file

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "Line Discount %" = 5
        CustomerNo := CreateCustomer();
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(TempBlob, SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceBothDiscounts()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Service] [Invoice] [Line Discount] [Invoice Discount]
        // [SCENARIO 298066] Line Discount Percent and Invoice Discount Amount of Service Invoice must be exported to specific nodes of FatturaPA file

        Initialize();

        // [GIVEN] Posted Service Invoice with "Line Discount %" = 5
        CustomerNo := CreateCustomer();
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::Invoice);
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(TempBlob, ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoBothDiscounts()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Service] [Credit Memo] [Line Discount] [Invoice Discount]
        // [SCENARIO 298066] Line Discount Percent and Invoice Discount Amount of Service Credit Memo must be exported to specific nodes of FatturaPA file

        Initialize();

        // [GIVEN] Posted Service Credit Memo with "Line Discount %" = 5
        CustomerNo := CreateCustomer();
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(TempBlob, ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineNodesExistsWithHundredPctDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Line Discount]
        // [SCENARIO 300725] FatturaPA file has line XML nodes if Line Amount is zero because of hundred percent line discount

        Initialize();

        // [GIVEN] Posted sales invoice with "Line Amount" = 0 and "Line Discount %" = 100
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CreateCustomer(), SalesHeader."Document Type"::Invoice);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Line Discount %", 100);
        SalesLine.Modify(true);
        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Line node PrezzoTotale exists and the value is zero
        VerifyLineAmount(TempBlob, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithPricesIncludingVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Item: Record Item;
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Invoice] [Prices Including VAT] [Line Discount]
        // [SCENARIO 323459] PrezzoUnitario and PrezzoTotale get exported correctly when Document uses "Prices Including VAT" and Line Discount
        Initialize();

        // [GIVEN] Item with unit price = "100"
        CreateItemWithPrice(Item, LibraryRandom.RandDec(100, 2));

        // [GIVEN] Sales Invoice with Quantity = 5, Unit Price = "120", "Line Discount Percent" = "20", Amount = "400"
        CreateFatturaSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateFatturaCustomerNoWithPricesIncludingVAT());
        CreateSalesLinesForItemNoWithLineDiscount(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(20));

        // [GIVEN] Sales Invoice was posted
        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] PrezzoUnitario = "100" and PrezzoTotale = "400"
        VerifyLineAndUnitPriceAmount(TempBlob, SalesLine.Amount, Item."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithLineDiscPctAndInvDiscAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 422467] PrezzoTotale considers both line discount and invoice discount of sales invoice

        Initialize();

        // [GIVEN] Posted Sales Invoice with Quantity = 5, "Line Amount" = 100, "Line Discount %" = 10, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer();
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscAmountInSalesLine(
          SalesLine, SalesHeader, 1 / LibraryRandom.RandIntInRange(3, 10), LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Import node has value of 20
        // [THEN] PrezzoTotale node has value 86 (100 - 10 - 20/5)
        VerifyLineAmountWithInvDisc(
          TempBlob, SalesLine."Line Amount" - Round(SalesLine."Inv. Discount Amount" / SalesLine.Quantity),
          SalesLine."Inv. Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvWithLineDiscPctAndInvDiscAmount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 422467] PrezzoTotale considers both line discount and invoice discount of service invoice

        Initialize();

        // [GIVEN] Posted Sales Invoice with Quantity = 5, "Line Amount" = 100, "Line Discount %" = 10, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer();
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::Invoice);
        UpdateDiscAmountInServiceLine(
          ServiceLine, ServiceHeader, 1 / LibraryRandom.RandIntInRange(3, 10), LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Import node has value of 20
        // [THEN] PrezzoTotale node has value 86 (100 - 10 - 20/5)
        VerifyLineAmountWithInvDisc(
          TempBlob,
          ServiceLine."Line Amount" - Round(ServiceLine."Inv. Discount Amount" / ServiceLine.Quantity),
          ServiceLine."Inv. Discount Amount");
    end;

    [Test]
    procedure CheckUnitInvoiceDiscountWhenSalesInvoiceWithInvoiceDiscountPactmorethen2Decimal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 571852] Check Invoice Discount Amount in FatturaPA file while Sales Invoice have Invoice Discount Percentage more Then 
        // 2 Decimal and Quantity more then 1.
        Initialize();

        // [GIVEN] Create New Customer.
        CustomerNo := CreateCustomer();

        // [GIVEN] Create and Post New Sales Invoice with Line Discount.
        CreateSalesDocument(SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscInSalesLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 5), LibraryRandom.RandIntInRange(5, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Check Sales Invoice Discount Amount Tag 'Importo'.
        VerifyInvDiscAmount(TempBlob, SalesLine."Unit Price", SalesLine."Line Discount %");
    end;

    [Test]
    procedure CheckUnitInvoiceDiscountWhenSalesInvoiceWithInvoiceDiscountPactmorethen2DecimalQty1()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 571852] Check Invoice Discount Amount in FatturaPA file while Sales Invoice have Invoice Discount Percentage more Then 
        // 2 Decimal and Quantity 1.
        Initialize();

        // [GIVEN] Create New Customer.
        CustomerNo := CreateCustomer();

        // [GIVEN] Create and Post New Sales Invoice with Line Discount.
        CreateSalesDocument(SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscInSalesLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 5), 1);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Check Sales Invoice Discount Amount Tag 'Importo'.
        VerifyInvDiscAmount(TempBlob, SalesLine."Unit Price", SalesLine."Line Discount %");
    end;

    [Test]
    procedure CheckUnitInvoiceDiscountWhenSalesInvoiceWithSimpleInvoiceDiscountPact()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 571852] Check Invoice Discount Amount in FatturaPA file while Sales Invoice have Single Digit Invoice Discount Percentage.
        Initialize();

        // [GIVEN] Create New Customer.
        CustomerNo := CreateCustomer();

        // [GIVEN] Create and Post New Sales Invoice with Line Discount.
        CreateSalesDocument(SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscInSalesLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(1, 10, 0), LibraryRandom.RandIntInRange(5, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Check Sales Invoice Discount Amount Tag 'Importo'.
        VerifyInvDiscAmount(TempBlob, SalesLine."Unit Price", SalesLine."Line Discount %");
    end;

    [Test]
    procedure CheckUnitInvoiceDiscountWhenSalesInvoiceWithZeroInvoiceDiscountPact()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 571852] Check Invoice Discount Amount in FatturaPA file while Sales Invoice have 0 Invoice Discount Percentage.
        Initialize();

        // [GIVEN] Create New Customer.
        CustomerNo := CreateCustomer();

        // [GIVEN] Create and Post New Sales Invoice with Line Discount.
        CreateSalesDocument(SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(5, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Check Sales Invoice Discount Amount Tag 'Importo'.
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/ScontoMaggiorazione/Importo', '');
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryITLocalization.SetupFatturaPA();
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, CustomerNo, '', LibraryRandom.RandIntInRange(5, 10), '', 0D);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateFatturaSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", LibraryITLocalization.CreateFatturaPaymentTermsCode());
        SalesHeader.Validate("Payment Method Code", LibraryITLocalization.CreateFatturaPaymentMethodCode());
        SalesHeader.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; DocumentType: Enum "Service Document Type")
    var
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem, '');
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        exit(
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 6)));
    end;

    local procedure CreateFatturaCustomerNoWithPricesIncludingVAT(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item.Modify(true);
    end;

    local procedure CreateSalesLinesForItemNoWithLineDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LineDiscountPct: Integer)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Line Discount %", LineDiscountPct);
        SalesLine.Modify(true);
    end;

    local procedure CreatePaymentMethod(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentMethodCode());
    end;

    local procedure CreatePaymentTerms(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentTermsCode());
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type"; CustomerNo: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, CustomerNo);
        ServiceHeader.Validate("Order Date", WorkDate());
        ServiceHeader.Validate("Payment Method Code", CreatePaymentMethod());
        ServiceHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item"; ItemNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure FormatAmount(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure FormatAmountEightDecimalPlaces(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Sign><Integer><Decimals,8><Comma,.>'))
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    local procedure UpdateDiscAmountInSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; InvDiscFactor: Decimal; LineDiscPct: Decimal)
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Line Discount %", LineDiscPct);
        SalesLine.Validate("Inv. Discount Amount", Round(SalesLine.Amount * InvDiscFactor));
        SalesLine.Modify(true);
    end;

    local procedure UpdateDiscAmountInServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; InvDiscFactor: Decimal; LineDiscPct: Decimal)
    begin
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Line Discount %", LineDiscPct);
        ServiceLine.Validate("Inv. Discount Amount", Round(ServiceLine.Amount * InvDiscFactor));
        ServiceLine.Modify(true);
    end;

    local procedure VerifyInvDiscAmount(TempBlob: Codeunit "Temp Blob"; LineAmount: Decimal; InvDiscAmount: Decimal; UnitPrice: Decimal; DiscPerc: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/ScontoMaggiorazione/Importo',
          FormatAmountEightDecimalPlaces(InvDiscAmount));
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale',
          FormatAmount(LineAmount));
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/ScontoMaggiorazione/Importo',
          FormatAmountEightDecimalPlaces((UnitPrice * DiscPerc) / 100));
    end;

    local procedure VerifyLineAmountWithInvDisc(TempBlob: Codeunit "Temp Blob"; LineAmount: Decimal; InvDiscAmount: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/ScontoMaggiorazione/Importo',
          FormatAmountEightDecimalPlaces(InvDiscAmount));
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale',
          FormatAmount(LineAmount));
    end;

    local procedure VerifyLineAmount(TempBlob: Codeunit "Temp Blob"; LineAmount: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale',
          FormatAmount(LineAmount));
    end;

    local procedure VerifyLineDiscPct(TempBlob: Codeunit "Temp Blob"; LineDiscPct: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertElementDoesNotExist(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/ScontoMaggiorazione/Importo');
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/ScontoMaggiorazione/Percentuale',
          FormatAmount(LineDiscPct));
    end;

    local procedure VerifyLineAndUnitPriceAmount(TempBlob: Codeunit "Temp Blob"; LineAmount: Decimal; UnitPrice: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);

        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoUnitario',
          FormatAmount(UnitPrice));
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale',
          FormatAmount(LineAmount));
    end;

    local procedure AssertCurrentElementValue(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text; ExpectedValue: Text)
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        Assert.AreEqual(ExpectedValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, TempXMLBuffer.GetElementName(), ExpectedValue, TempXMLBuffer.Value));
    end;

    local procedure AssertElementDoesNotExist(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text)
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        Assert.RecordCount(TempXMLBuffer, 0);
    end;

    local procedure UpdateDiscInSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineDiscPct: Decimal; Qty: Decimal)
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Line Discount %", LineDiscPct);
        SalesLine.Modify(true);
    end;

    local procedure VerifyInvDiscAmount(TempBlob: Codeunit "Temp Blob"; UnitPrice: Decimal; DiscPerc: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/ScontoMaggiorazione/Importo',
          FormatAmountEightDecimalPlaces((UnitPrice * DiscPerc) / 100));
    end;
}

