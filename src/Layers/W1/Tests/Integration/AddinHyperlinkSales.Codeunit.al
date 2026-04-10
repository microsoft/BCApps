codeunit 139051 "Add-in Hyperlink Sales"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Hyperlink] [Sales]
        isInitialized := false;
    end;

    var
        SMBOfficePages: Codeunit "SMB Office Pages";
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        OfficeHostType: DotNet OfficeHostType;
        DocNo: Code[20];
        SalesQuoteErr: Label 'Unexpected document number opened on the sales quote card.';
        SalesInvErr: Label 'Unexpected document number opened on the sales invoice card.';
        SalesCrMemoErr: Label 'Unexpected document number opened on the sales credit memo card.';
        PostSalesInvErr: Label 'Unexpected document number opened on the posted sales invoice card.';
        PostSalesCrMemoErr: Label 'Unexpected document number opened on the posted sales credit memo card.';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('SalesQuotePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteDocType()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // Setup
        Initialize();

        // [FEATURE] [Quote]
        // [SCENARIO 147201] Stan can view Sales Quote from a hyperlink where the doc type and doc number were derived from the Outlook email.

        // [GIVEN] Sales Quote has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Quote, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, SalesHeader."No.");

        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales quote is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesQuotePageHandler will verify the Sales Quote window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('SalesQuotePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteTitle()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Quote]
        // [SCENARIO 147201] Stan can view Sales Quote from a hyperlink in the Outlook email that contained the Document Window Title
        Initialize();

        // [GIVEN] Sales Quote has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Quote, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the Sales Quote window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForSalesQuote() + '# ' + SalesHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales quote is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesQuotePageHandler will verify the Sales Quote window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('SalesQuotePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteKeyword()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
        KeyWord: Text[20];
    begin
        // [FEATURE] [Quote]
        // [SCENARIO 147201] Stan can view Sales Quote from a hyperlink in the Outlook email that contained the 'quote' keyword
        Initialize();

        // [GIVEN] Sales Quote has been created
        KeyWord := UpperCase(Format(DocType::Quote));
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Quote, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the quote keyword and document number
        ExpressionMatch := KeyWord + ': ' + SalesHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales quote is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesQuotePageHandler will verify the Sales Quote window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('SalesOrderPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesOrderDocType()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 147201] Stan can view Sales Order from a hyperlink where the doc type and doc number were derived from the Outlook email.
        Initialize();

        // [GIVEN] Sales Order has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, SalesHeader."No.");
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales order is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesOrderPageHandler will verify the Sales Order window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('SalesOrderPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesOrderTitle()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Order]
        // [SCENARIO 147201] Stan can view Sales Order from a hyperlink in the Outlook email that contained the Document Window Title
        Initialize();

        // [GIVEN] Sales Order has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the Sales Order window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForSalesOrder() + '# ' + SalesHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales order is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesOrderPageHandler will verify the Sales Order window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('SalesOrderPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesOrderKeyword()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
        KeyWord: Text[20];
    begin
        // [FEATURE] [Order]
        // [SCENARIO 147201] Stan can view Sales Order from a hyperlink in the Outlook email that contained the 'order' keyword

        // [GIVEN] Sales Order has been created
        KeyWord := UpperCase(Format(DocType::Order));
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the order keyword and document number
        ExpressionMatch := KeyWord + ': ' + SalesHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales order is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesOrderPageHandler will verify the Sales Order window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('SalesInvoicePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceDocType()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Sales Invoice from a hyperlink where the doc type and doc number were derived from the Outlook email.
        Initialize();

        // [GIVEN] Sales Invoice has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, SalesHeader."No.");
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesInvoicePageHandler will verify the Sales Invoice window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('SalesInvoicePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceTitle()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Sales Invoice from a hyperlink in the Outlook email that contained the Document Window Title
        Initialize();

        // [GIVEN] Sales Invoice has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the Sales Invoice window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForSalesInvoice() + '# ' + SalesHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesInvoicePageHandler will verify the Sales Invoice window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('SalesInvoicePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceKeyword()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
        KeyWord: Text[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Sales Invoice from a hyperlink in the Outlook email that contained the 'invoice' keyword
        Initialize();

        // [GIVEN] Sales Invoice has been created
        KeyWord := UpperCase(Format(DocType::Invoice));
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the invoice keyword and document number
        ExpressionMatch := KeyWord + ': ' + SalesHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesInvoicePageHandler will verify the Sales Invoice window opens, with the correct document number.
        SalesHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceKeywordMultiple()
    var
        GLAccount: Record "G/L Account";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeDocumentSelection: TestPage "Office Document Selection";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view sales invoices from a hyperlink in the Outlook email that contained the 'invoice' keyword
        Initialize();

        // [GIVEN] Three sales invoices have been created.
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader1, SalesLine,
          SalesHeader1."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);
        CreateSalesDocWithLine(SalesHeader2, SalesLine,
          SalesHeader2."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);
        CreateSalesDocWithLine(SalesHeader3, SalesLine,
          SalesHeader3."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the invoice keyword and document number
        ExpressionMatch := StrSubstNo('%1: %2|%1: %3|%1:%4', 'invoice', SalesHeader1."No.", SalesHeader2."No.", SalesHeader3."No.");

        // [WHEN] OfficeAddinContext filters are set up to simulate the hyperlink add-in with all three invoices in the email body.
        SetOfficeAddinContextFilter(TempOfficeAddinContext);
        TempOfficeAddinContext.SetRange("Regular Expression Match", ExpressionMatch);

        // [WHEN] Outlook Mail Engine is run with the OfficeAddinContext record.
        OfficeDocumentSelection.Trap();
        RunMailEngine(TempOfficeAddinContext);

        // [THEN] Office document selection page is opened with the three documents in the list
        OfficeDocumentSelection.First();
        OfficeDocumentSelection."Document No.".AssertEquals(SalesHeader1."No.");
        OfficeDocumentSelection.Next();
        OfficeDocumentSelection."Document No.".AssertEquals(SalesHeader2."No.");
        OfficeDocumentSelection.Next();
        OfficeDocumentSelection."Document No.".AssertEquals(SalesHeader3."No.");

        SalesHeader1.Delete();
        SalesHeader2.Delete();
        SalesHeader3.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceNoSeriesMultiple()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: array[10] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        OfficeDocumentSelection: TestPage "Office Document Selection";
        DocNos: Text;
        "Count": Integer;
        i: Integer;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view sales invoices from a hyperlink in the Outlook email that contained only the document no. based on no. series.
        Initialize();

        // [GIVEN] Several sales invoices have been created.
        CreateGLAccount(GLAccount);
        Count := LibraryRandom.RandInt(8) + 2;
        for i := 1 to Count do begin
            CreateSalesDocWithLine(SalesHeader[i], SalesLine, SalesHeader[i]."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);
            DocNos += SalesHeader[i]."No." + '|';
        end;
        DocNos := DelChr(DocNos, '>', '|');

        // [WHEN] OfficeAddinContext filters are set up to simulate the hyperlink add-in with all invoice nos in the email body.
        SetOfficeAddinContextFilter(TempOfficeAddinContext);
        TempOfficeAddinContext.SetRange("Document No.", DocNos);

        // [WHEN] Outlook Mail Engine is run with the OfficeAddinContext record.
        OfficeDocumentSelection.Trap();
        RunMailEngine(TempOfficeAddinContext);

        // [THEN] Office document selection page is opened with all documents in the list
        OfficeDocumentSelection.First();
        for i := 1 to Count do begin
            OfficeDocumentSelection."Document No.".AssertEquals(SalesHeader[i]."No.");
            OfficeDocumentSelection.Next();
            SalesHeader[i].Delete();
        end;
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedSalesInvoiceDocType()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Posted Sales Invoice from a hyperlink where the doc type and doc number were derived from the Outlook email.

        // Setup
        Initialize();

        // [GIVEN] Create and post the Sales Invoice
        CreateandPostSalesInvoice(SalesInvoiceHeader);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, SalesInvoiceHeader."No.");

        // [WHEN] Hyperlink for sales invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedSalesInvoicePageHandler will verify the Sales Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedSalesInvoiceTitle()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Posted Sales Invoice from a hyperlink in the Outlook email that contained the Document Window Title

        // Setup
        Initialize();

        // [GIVEN] Create and post the Sales Invoice
        CreateandPostSalesInvoice(SalesInvoiceHeader);

        // Need to create the regular expression that contains both the Sales Invoice window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForSalesInvoice() + '# ' + SalesInvoiceHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for sales invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedSalesInvoicePageHandler will verify the Sales Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicePageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedSalesInvoiceKeyword()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Posted Sales Invoice from a hyperlink in the Outlook email that contained the 'invoice' keyword

        // Setup
        Initialize();

        // [GIVEN] Create and post the Sales Invoice
        CreateandPostSalesInvoice(SalesInvoiceHeader);

        // Need to create the regular expression that contains both the invoice keyword and document number
        ExpressionMatch := UpperCase(Format(DocType::Invoice)) + ': ' + SalesInvoiceHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for sales invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedSalesInvoicePageHandler will verify the Sales Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesCreditMemoDocType()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Sales Credit Memo from a hyperlink where the doc type and doc number were derived from the Outlook email.

        // Setup
        Initialize();

        // [GIVEN] Sales Credit Memo has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, SalesHeader."No.");
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesCreditMemoPageHandler will verify the Sales Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesCreditMemoTitle()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Sales Credit Memo from a hyperlink in the Outlook email that contained the Document Window Title

        // Setup
        Initialize();

        // [GIVEN] Sales Credit Memo has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the Sales Credit Memo window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForSalesCrMemo() + '# ' + SalesHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesCreditMemoPageHandler will verify the Sales Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesCreditMemoKeyword()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
        KeyWord: Text[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Sales Credit Memo from a hyperlink in the Outlook email that contained the 'credit memo' keyword

        // Setup
        Initialize();

        // [GIVEN] Sales Credit Memo has been created
        KeyWord := UpperCase(Format(DocType::"Credit Memo"));
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // Need to create the regular expression that contains both the credit memo keyword and document number
        ExpressionMatch := KeyWord + ': ' + SalesHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);
        DocNo := SalesHeader."No.";

        // [WHEN] Hyperlink for sales credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] SalesCreditMemoPageHandler will verify the Sales Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedSalesCreditMemoPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedSalesCreditMemoDocType()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Posted Sales Credit Memo from a hyperlink where the doc type and doc number were derived from the Outlook email.

        // Setup
        Initialize();

        // [GIVEN] Create and post the Sales Credit Memo
        CreateandPostSalesCrMemo(SalesCrMemoHeader);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, SalesCrMemoHeader."No.");

        // [WHEN] Hyperlink for sales credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedSalesCreditMemoPageHandler will verify the Sales Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedSalesCreditMemoPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedSalesCreditMemoTitle()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Posted Sales Credit Memo from a hyperlink in the Outlook email that contained the Document Window Title

        // Setup
        Initialize();

        // [GIVEN] Create and post the Sales Credit Memo
        CreateandPostSalesCrMemo(SalesCrMemoHeader);

        // Need to create the regular expression that contains both the Sales Credit Memo window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForSalesCrMemo() + '# ' + SalesCrMemoHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for sales credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedSalesCreditMemoPageHandler will verify the Sales Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedSalesCreditMemoPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedSalesCreditMemoKeyword()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Posted Sales Credit Memo from a hyperlink in the Outlook email that contained the 'credit memo' keyword

        // Setup
        Initialize();

        // [GIVEN] Create and post the Sales Credit Memo
        CreateandPostSalesCrMemo(SalesCrMemoHeader);

        // Need to create the regular expression that contains both the credit memo keyword and document number
        ExpressionMatch := UpperCase(Format(DocType::"Credit Memo")) + ': ' + SalesCrMemoHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for sales credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedSalesCreditMemoPageHandler will verify the Sales Credit Memo window opens, with the correct document number.
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        LibraryERM: Codeunit "Library - ERM";
        No: Code[20];
    begin
        No := LibraryERM.CreateGLAccountWithSalesSetup();
        GLAccount.Get(No);
    end;

    [Normal]
    local procedure RunMailEngine(var OfficeAddinContext: Record "Office Add-in Context")
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OutlookMailEngine: TestPage "Outlook Mail Engine";
    begin
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType.OutlookHyperlink);
        OfficeAddinContext.SetRange(Version, OfficeAddin.Version);

        OutlookMailEngine.Trap();
        PAGE.Run(PAGE::"Outlook Mail Engine", OfficeAddinContext);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesQuotePageHandler(var SalesQuote: TestPage "Sales Quote")
    begin
        if StrPos(UpperCase(SalesQuote.Caption), UpperCase(DocNo)) = 0 then
            Error(SalesQuoteErr);
        SalesQuote.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    var
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(SalesOrder."No.".Value, DocNo, 'Unexpected document number opened on the sales order card.');
        SalesOrder.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePageHandler(var SalesInvoice: TestPage "Sales Invoice")
    begin
        if StrPos(UpperCase(SalesInvoice.Caption), UpperCase(DocNo)) = 0 then
            Error(SalesInvErr);
        SalesInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoPageHandler(var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        if StrPos(UpperCase(SalesCreditMemo.Caption), UpperCase(DocNo)) = 0 then
            Error(SalesCrMemoErr);
        SalesCreditMemo.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        if StrPos(UpperCase(PostedSalesInvoice.Caption), UpperCase(DocNo)) = 0 then
            Error(PostSalesInvErr);
        PostedSalesInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoPageHandler(var PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo")
    begin
        if StrPos(UpperCase(PostedSalesCreditMemo.Caption), UpperCase(DocNo)) = 0 then
            Error(PostSalesCrMemoErr);
        PostedSalesCreditMemo.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateSalesDocWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; SalesLineType: Enum "Sales Line Type"; No: Code[20]; PostingDate: Date)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        CreateSalesHeaderWithDocNo(SalesHeader, DocumentType);
        if PostingDate <> 0D then begin
            SalesHeader.Validate("Posting Date", PostingDate);
            SalesHeader.Modify(true);
        end else begin
            SalesHeader."Due Date" := PostingDate;
            SalesHeader.Modify();
        end;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, 2);
    end;

    local procedure SetDateDay(Day: Integer; StartDate: Date): Date
    begin
        // Use the workdate but set to a specific day of that month
        exit(DMY2Date(Day, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3)));
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure SetNoSeries(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNoSeries: Codeunit "Library - No. Series";
    begin
        case DocType of
            DocType::"Credit Memo":
                begin
                    SalesReceivablesSetup.Get();
                    LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'SCRM-0000', 'SCRM-1999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    SalesReceivablesSetup."Credit Memo Nos." := NoSeries.Code;

                    LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'SPCRM2000', 'SPCRM3999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    SalesReceivablesSetup."Posted Credit Memo Nos." := NoSeries.Code;
                    SalesReceivablesSetup.Modify();
                end;
            DocType::Invoice:
                begin
                    SalesReceivablesSetup.Get();
                    LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'S-INV4000', 'S-INV5999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    SalesReceivablesSetup."Invoice Nos." := NoSeries.Code;

                    LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'SPINV6000', 'SPINV7999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    SalesReceivablesSetup."Posted Invoice Nos." := NoSeries.Code;
                    SalesReceivablesSetup.Modify();
                end;
            DocType::Order:
                begin
                    SalesReceivablesSetup.Get();
                    LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'SORD0000', 'SORD1999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    SalesReceivablesSetup."Order Nos." := NoSeries.Code;
                    SalesReceivablesSetup.Modify();
                end;
            DocType::Quote:
                begin
                    SalesReceivablesSetup.Get();
                    LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'SQUO-0000', 'SQUO-1999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    SalesReceivablesSetup."Quote Nos." := NoSeries.Code;
                    SalesReceivablesSetup.Modify();
                end;
        end;
        Commit();
    end;

    local procedure CreateSalesHeaderWithDocNo(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        Clear(SalesHeader);
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);
    end;

    local procedure SetOfficeAddinContextFilter(var OfficeAddinContext: Record "Office Add-in Context")
    begin
        OfficeAddinContext.SetRange(Email, 'bob@bob.com');
        OfficeAddinContext.SetRange(Name, 'Bob Roberts');
    end;

    local procedure CreateandPostSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
    begin
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));

        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(DocNo);
    end;

    local procedure CreateandPostSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
    begin
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));

        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesCrMemoHeader.Get(DocNo);
    end;

    local procedure Initialize()
    var
        OfficeAddin: Record "Office Add-in";
        SalesHeader: Record "Sales Header";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Add-in Hyperlink Sales");

        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryRandom.Init();
        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(OfficeHostType.OutlookHyperlink);
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Add-in Hyperlink Sales");

        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        SetNoSeries(DocType::Invoice);
        SetNoSeries(DocType::"Credit Memo");
        SetNoSeries(DocType::Quote);
        SetNoSeries(DocType::Order);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        SalesHeader.DeleteAll(); // tests do not expect existing Sales Header
        SMBOfficePages.SetupMarketing();
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Add-in Hyperlink Sales");
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();

        SetOfficeHostProvider(CODEUNIT::"Library - Office Host Provider");

        OfficeManagement.InitializeHost(OfficeHost, HostType);
    end;

    local procedure SetOfficeHostUnAvailable()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // Test Providers checks whether we have registered Host in NameValueBuffer or not
        if NameValueBuffer.Get(SessionId()) then begin
            NameValueBuffer.Delete();
            Commit();
        end;
    end;

    local procedure SetOfficeHostProvider(ProviderId: Integer)
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        OfficeAddinSetup.Get();
        OfficeAddinSetup."Office Host Codeunit ID" := ProviderId;
        OfficeAddinSetup.Modify();
    end;

    [Normal]
    local procedure SetupDocumentNoMatch(var OfficeAddinContext: Record "Office Add-in Context"; DocumentNo: Code[20])
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeAddinContextFilter(OfficeAddinContext);
        OfficeAddinContext.SetFilter("Document No.", '=%1', DocumentNo);
    end;

    [Normal]
    local procedure SetupRegExMatch(var OfficeAddinContext: Record "Office Add-in Context"; RegularExpressionText: Text)
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeAddinContextFilter(OfficeAddinContext);
        OfficeAddinContext.SetFilter("Regular Expression Match", '=%1', RegularExpressionText);
    end;
}

