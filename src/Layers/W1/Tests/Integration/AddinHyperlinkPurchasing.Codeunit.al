codeunit 139050 "Add-in Hyperlink Purchasing"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Hyperlink] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OfficeHostType: DotNet OfficeHostType;
        DocNo: Code[20];
        DocNotExistErr: Label 'This document number should not exist for this test.';
        PurchInvErr: Label 'Unexpected document number opened on the purchase invoice card.';
        PurchCrMemoErr: Label 'Unexpected document number opened on the purchase credit memo card.';
        PurchOrderErr: Label 'Unexpected document number opened on the purchase order card.';
        PostPurchInvErr: Label 'Unexpected document number opened on the posted purchase invoice card.';
        PostPurchCrMemoErr: Label 'Unexpected document number opened on the posted purchase credit memo card.';
        VendorNo: Code[20];
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('NoDocumentAvailablePageHandler')]
    [Scope('OnPrem')]
    procedure CreateInvalidDocNumber()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        No: Code[20];
    begin
        // [SCENARIO 147201] Stan will get a message that a document does not exist when clicking on a hyperlink for a document number that does not exist.
        // Setup
        Initialize();

        // [WHEN] Purchase Invoice has been proven to not exist
        No := 'ZZZQUOTE001';
        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, No) then
            Error(DocNotExistErr);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, No);

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] NoDocumentAvailablePageHandler indicates invalid document page should appear.
    end;

    [Test]
    [HandlerFunctions('DocumentSelectorPageHandler')]
    [Scope('OnPrem')]
    procedure CreateMultipleDocTypes()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [SCENARIO 147201] Stan will get a window to select a doc number when clicking on a hyperlink for a doc number that exists for multiple doc types.
        Initialize();

        // [GIVEN] Purchase Invoice has been created
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(), 'PDOC0001');
        // [GIVEN] Purchase Credit Memo has been created
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor(), 'PDOC0001');

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, PurchaseHeader."No.");

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] DocumentSelectorPageHandler will verify the Document Selector window opens.
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateMultipleDocTypesRegExMatch()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [SCENARIO 147201] Stan will get a Purchase Invoice window when clicking on a hyperlink for a doc number includes the document name and a number
        Initialize();

        // [GIVEN] Purchase Invoice has been created
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(), '9990001');

        // [GIVEN] Purchase Credit Memo has been created
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor(), '9990001');

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, 'invoice 9990001');

        DocNo := '9990001';

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseInvoicePageHandler will verify the purchase invoice window opens.
    end;

    [Test]
    [HandlerFunctions('DocumentSelectorPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchAndSalesDocTypes()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 147201] Stan will get a window to select a doc number when clicking on a hyperlink for a doc number that exists for the same doc type in Sales and Purchasing
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        // [GIVEN] Purchase Invoice has been created
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(), 'DOC0001');

        // [GIVEN] Sales Quote has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine, 'DOC0001',
          SalesHeader."Document Type"::Quote, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, 'DOC0001');

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] DocumentSelectorPageHandler will verify the purchase invoice window opens.
    end;

    [Test]
    [HandlerFunctions('DocumentSelectorPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchAndSalesDocTypesRegExMatch()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 147201] Stan will get a window to select a doc number when clicking on a hyperlink for a doc number that exists for the same doc type in Sales and Purchasing
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        // [GIVEN] Purchase Invoice has been created
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(), '9990002');

        // [GIVEN] Sales Invoice has been created
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine, '9990002',
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", 0D);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, 'invoice 9990002');
        DocNo := PurchaseHeader."No.";

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] DocumentSelectorPageHandler will verify the purchase invoice window opens.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderDocType()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [FEATURE] [ORDER]
        // [SCENARIO] Stan can view Purchase Order from a hyperlink where the doc type and doc number were derived from the Outlook email.
        Initialize();

        // [GIVEN] Purchase Order has been created
        CreatePurchaseOrder(PurchaseHeader);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do
        SetupDocumentNoMatch(OfficeAddinContext, PurchaseHeader."No.");

        DocNo := PurchaseHeader."No.";

        // [WHEN] Hyperlink for purchase order is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseOrderPageHandler will verify the Purchase Order window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderTitle()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [ORDER]
        // [SCENARIO] Stan can view Purchase Order from a hyperlink in the Outlook email that contained the Document Window Title
        Initialize();

        // [GIVEN] Purchase Order has been created
        CreatePurchaseOrder(PurchaseHeader);

        DocNo := PurchaseHeader."No.";

        // Need to create the regular expression that contains both the Purchase Order window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForPurchaseOrder() + '# ' + DocNo;

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseOrderPageHandler will verify the Purchase Order window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderAcronym()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [ORDER]
        // [SCENARIO] Stan can view Purchase Order from a hyperlink in the Outlook email that contained the Purchase Order acronym (PO)
        Initialize();

        // [GIVEN] Purchase Order has been created
        CreatePurchaseOrder(PurchaseHeader);

        DocNo := PurchaseHeader."No.";

        // Need to create the regular expression that contains both the Purchase Order acronym and document number
        ExpressionMatch := HyperlinkManifest.GetAcronymForPurchaseOrder() + DocNo;

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseOrderPageHandler will verify the Purchase Order window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderKeyword()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [ORDER]
        // [SCENARIO] Stan can view Purchase Order from a hyperlink in the Outlook email that contained the 'order' keyword
        Initialize();

        // [GIVEN] Purchase Order has been created
        CreatePurchaseOrder(PurchaseHeader);

        DocNo := PurchaseHeader."No.";

        // Need to create the regular expression that contains both the Purchase Order acronym and document number
        ExpressionMatch := UpperCase(Format(PurchaseHeader."Document Type"::Order)) + ': ' + DocNo;

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseOrderPageHandler will verify the Purchase Order window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceDocType()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Purchase Invoice from a hyperlink where the doc type and doc number were derived from the Outlook email.
        Initialize();

        // [GIVEN] Purchase Invoice has been created
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(), 'PINVOICE001');

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, PurchaseHeader."No.");

        DocNo := PurchaseHeader."No.";

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseInvoicePageHandler will verify the Purchase Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceTitle()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
        No: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Purchase Invoice from a hyperlink in the Outlook email that contained the Document Window Title
        Initialize();

        // [GIVEN] Purchase Invoice has been created
        No := 'PINVOICE002';
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(), No);

        // Need to create the regular expression that contains both the Purchase Invoice window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForPurchaseInvoice() + '# ' + No;

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        DocNo := PurchaseHeader."No.";

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseInvoicePageHandler will verify the Purchase Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceKeyword()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
        No: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
        KeyWord: Text[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Purchase Invoice from a hyperlink in the Outlook email that contained the 'invoice' keyword

        // Setup
        Initialize();

        // [GIVEN] Purchase Invoice has been created
        No := 'PINVOICE003';
        KeyWord := UpperCase(Format(DocType::Invoice));
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(), No);

        // Need to create the regular expression that contains both the invoice keyword and document number
        ExpressionMatch := KeyWord + ': ' + No;

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        DocNo := PurchaseHeader."No.";

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseInvoicePageHandler will verify the Purchase Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedPurchaseInvoiceDocType()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Posted Purchase Invoice from a hyperlink where the doc type and doc number were derived from the Outlook email.

        // Setup
        Initialize();

        // [GIVEN] Create and post the Purchase Invoice
        CreateandPostPurchInvoice(PurchInvHeader, 'PINVOICE004', 2);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, PurchInvHeader."No.");

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedPurchaseInvoicePageHandler will verify the Posted Purchase Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedPurchaseInvoiceTitle()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        PurchInvHeader: Record "Purch. Inv. Header";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Posted Purchase Invoice from a hyperlink in the Outlook email that contained the Document Window Title

        // Setup
        Initialize();

        // [GIVEN] Create and post the Purchase Invoice
        CreateandPostPurchInvoice(PurchInvHeader, 'PINVOICE005', 2);

        // Need to create the regular expression that contains both the Purchase Invoice window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForPurchaseInvoice() + '# ' + PurchInvHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedPurchaseInvoicePageHandler will verify the Posted Purchase Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedPurchaseInvoiceKeyword()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        PurchInvHeader: Record "Purch. Inv. Header";
        ExpressionMatch: Text;
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 147201] Stan can view Posted Purchase Invoice from a hyperlink in the Outlook email that contained the 'invoice' keyword

        // Setup
        Initialize();

        // [GIVEN] Create and post the Purchase Invoice
        CreateandPostPurchInvoice(PurchInvHeader, 'PINVOICE006', 3);

        // Need to create the regular expression that contains both the invoice keyword and document number
        ExpressionMatch := UpperCase(Format(DocType::Invoice)) + ': ' + PurchInvHeader."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for purchase invoice is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedPurchaseInvoicePageHandler will verify the Posted Purchase Invoice window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseCreditMemoDocType()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Purchase Credit Memo from a hyperlink where the doc type and doc number were derived from the Outlook email.

        // Setup
        Initialize();

        // [GIVEN] Purchase Credit Memo has been created
        LibraryPurchase.CreatePurchHeaderWithDocNo(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, 'PCRMEMO001');

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, PurchaseHeader."No.");

        DocNo := PurchaseHeader."No.";

        // [WHEN] Hyperlink for purchase credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseCreditMemoPageHandler will verify the Purchase Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseCreditMemoTitle()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
        No: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Purchase Credit Memo from a hyperlink in the Outlook email that contained the Document Window Title

        // Setup
        Initialize();

        // [GIVEN] Purchase Credit Memo has been created
        No := 'PCRMEMO002';
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, No);

        // Need to create the regular expression that contains both the Purchase Credit Memo window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForPurchaseCrMemo() + '# ' + No;

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        DocNo := PurchaseHeader."No.";

        // [WHEN] Hyperlink for purchase credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseCreditMemoPageHandler will verify the Purchase Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseCreditMemoKeyword()
    var
        PurchaseHeader: Record "Purchase Header";
        OfficeAddinContext: Record "Office Add-in Context";
        ExpressionMatch: Text;
        No: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
        KeyWord: Text[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Purchase Credit Memo from a hyperlink in the Outlook email that contained the 'credit memo' keyword

        // Setup
        Initialize();

        // [GIVEN] Purchase Credit Memo has been created
        No := 'PCRMEMO003';
        KeyWord := UpperCase(Format(DocType::"Credit Memo"));
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, No);

        // Need to create the regular expression that contains both the credit memo keyword and document number
        ExpressionMatch := KeyWord + ': ' + No;

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        DocNo := PurchaseHeader."No.";

        // [WHEN] Hyperlink for purchase credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PurchaseCreditMemoPageHandler will verify the Purchase Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedPurchaseCreditMemoDocType()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Posted Purchase Credit Memo from a hyperlink where the doc type and doc number were derived from the Outlook email.

        // Setup
        Initialize();

        // [GIVEN] Create and post the Purchase Credit Memo
        CreateandPostPurchCrMemo(PurchCrMemoHdr, 'PCRMEMO004', 2);

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupDocumentNoMatch(OfficeAddinContext, PurchCrMemoHdr."No.");

        // [WHEN] Hyperlink for purchase credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedPurchaseCreditMemoPageHandler will verify the Posted Purchase Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedPurchaseCreditMemoTitle()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        HyperlinkManifest: Codeunit "Hyperlink Manifest";
        ExpressionMatch: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Posted Purchase Credit Memo from a hyperlink in the Outlook email that contained the Document Window Title

        // Setup
        Initialize();

        // [GIVEN] Create and post the Purchase Credit Memo
        CreateandPostPurchCrMemo(PurchCrMemoHdr, 'PCRMEMO005', 2);

        // Need to create the regular expression that contains both the Purchase Credit Memo window title and document number
        ExpressionMatch := HyperlinkManifest.GetNameForPurchaseCrMemo() + '# ' + PurchCrMemoHdr."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for purchase credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedPurchaseCreditMemoPageHandler will verify the Posted Purchase Credit Memo window opens, with the correct document number.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePostedPurchaseCreditMemoKeyword()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ExpressionMatch: Text;
        DocType: Option Quote,"Order",Invoice,"Credit Memo";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 147201] Stan can view Posted Purchase Credit Memo from a hyperlink in the Outlook email that contained the 'credit memo' keyword

        // Setup
        Initialize();

        // [GIVEN] Create and post the Purchase Credit Memo
        CreateandPostPurchCrMemo(PurchCrMemoHdr, 'PCRMEMO006', 3);

        // Need to create the regular expression that contains both the credit memo keyword and document number
        ExpressionMatch := UpperCase(Format(DocType::"Credit Memo")) + ': ' + PurchCrMemoHdr."No.";

        // [WHEN] OfficeAddinContext table's filter has been set to what hyperlink add-in would do.
        SetupRegExMatch(OfficeAddinContext, ExpressionMatch);

        // [WHEN] Hyperlink for purchase credit memo is selected
        RunMailEngine(OfficeAddinContext);

        // [THEN] PostedPurchaseCreditMemoPageHandler will verify the Posted Purchase Credit Memo window opens, with the correct document number.
    end;

    local procedure UpdatePurchaseHeaderForCreditMemo(var PurchaseHeader: Record "Purchase Header")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
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

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DocumentSelectorPageHandler(var OfficeAddinDocSelection: TestPage "Office Document Selection")
    begin
        OfficeAddinDocSelection.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NoDocumentAvailablePageHandler(var OfficeDocSelectionDlg: TestPage "Office Doc Selection Dlg")
    begin
        OfficeDocSelectionDlg.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePageHandler(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        if StrPos(UpperCase(PurchaseInvoice.Caption), UpperCase(DocNo)) = 0 then
            Error(PurchInvErr);
        PurchaseInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoPageHandler(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        if StrPos(UpperCase(PurchaseCreditMemo.Caption), UpperCase(DocNo)) = 0 then
            Error(PurchCrMemoErr);
        PurchaseCreditMemo.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderPageHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
        if StrPos(UpperCase(PurchaseOrder.Caption), UpperCase(DocNo)) = 0 then
            Error(PurchOrderErr);
        PurchaseOrder.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicePageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    var
        Assert: Codeunit Assert;
    begin
        if StrPos(UpperCase(PostedPurchaseInvoice.Caption), UpperCase(DocNo)) = 0 then
            Error(PostPurchInvErr);

        // Test to ensure the Print action is not visible when in add-in mode.
        Assert.AreEqual(false, PostedPurchaseInvoice.Print.Visible(), 'Print action should not be visible');
        // Test to ensure the Navigate action is not visible when in add-in mode.
        Assert.AreEqual(false, PostedPurchaseInvoice.Navigate.Visible(), 'Navigate action should not be visible');

        PostedPurchaseInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemoPageHandler(var PostedPurchCreditMemo: TestPage "Posted Purchase Credit Memo")
    var
        Assert: Codeunit Assert;
    begin
        if StrPos(UpperCase(PostedPurchCreditMemo.Caption), UpperCase(DocNo)) = 0 then
            Error(PostPurchCrMemoErr);

        // Test to ensure the Print action is not visible when in add-in mode.
        Assert.AreEqual(false, PostedPurchCreditMemo."&Print".Visible(), 'Print action should not be visible');
        // Test to ensure the Navigate action is not visible when in add-in mode.
        Assert.AreEqual(false, PostedPurchCreditMemo."&Navigate".Visible(), 'Navigate action should not be visible');

        PostedPurchCreditMemo.Close();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        LibraryERM: Codeunit "Library - ERM";
        No: Code[20];
    begin
        No := LibraryERM.CreateGLAccountWithPurchSetup();
        GLAccount.Get(No);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure SetNoSeries(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNoSeries: Codeunit "Library - No. Series";
    begin
        case DocType of
            DocType::"Credit Memo":
                begin
                    PurchasesPayablesSetup.Get();
                    LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'PCRM0000', 'PCRM9999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    PurchasesPayablesSetup."Credit Memo Nos." := NoSeries.Code;

                    LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'PPCRM0000', 'PPCRM9999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    PurchasesPayablesSetup."Posted Credit Memo Nos." := NoSeries.Code;
                    PurchasesPayablesSetup.Modify();
                end;
            DocType::Invoice:
                begin
                    PurchasesPayablesSetup.Get();
                    LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'PINV0000', 'PINV9999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    PurchasesPayablesSetup."Invoice Nos." := NoSeries.Code;

                    LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'PPINV0000', 'PPINV9999');
                    LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeriesLine."Series Code");
                    PurchasesPayablesSetup."Posted Invoice Nos." := NoSeries.Code;
                    PurchasesPayablesSetup.Modify();
                end;
        end;
        Commit();
    end;

    local procedure SetOfficeAddinContextFilter(var OfficeAddinContext: Record "Office Add-in Context")
    begin
        OfficeAddinContext.SetFilter(Email, '=%1', 'bob@bob.com');
        OfficeAddinContext.SetFilter(Name, '=%1', 'Bob Roberts');
    end;

    local procedure CreateandPostPurchInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; InvoiceNo: Code[20]; Quantity: Integer)
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, InvoiceNo);
        CreateGLAccount(GLAccount);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", Quantity);

        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(DocNo);
    end;

    local procedure CreateandPostPurchCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; CrMemoNo: Code[20]; Quantity: Integer)
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeaderWithDocNo(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, CrMemoNo);
        UpdatePurchaseHeaderForCreditMemo(PurchaseHeader);
        CreateGLAccount(GLAccount);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", Quantity);

        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchCrMemoHdr.Get(DocNo);
    end;

    local procedure Initialize()
    var
        OfficeAddin: Record "Office Add-in";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        SMBOfficePages: Codeunit "SMB Office Pages";
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Add-in Hyperlink Purchasing");

        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(OfficeHostType.OutlookHyperlink);

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Add-in Hyperlink Purchasing");

        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        SalesHeader.DeleteAll();
        SalesInvoiceHeader.DeleteAll();
        SalesCrMemoHeader.DeleteAll();

        SetNoSeries(DocType::Invoice);
        SetNoSeries(DocType::"Credit Memo");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        VendorNo := CreateVendor();
        SMBOfficePages.SetupMarketing();
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Add-in Hyperlink Purchasing");
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

    local procedure CreateSalesDocWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocNo: Code[20]; DocumentType: Enum "Sales Document Type"; SalesLineType: Enum "Sales Line Type"; No: Code[20]; PostingDate: Date)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        CreateSalesHeaderWithDocNo(SalesHeader, DocumentType, DocNo);
        if PostingDate <> 0D then begin
            SalesHeader.Validate("Posting Date", PostingDate);
            SalesHeader.Modify(true);
        end else begin
            SalesHeader."Due Date" := PostingDate;
            SalesHeader.Modify();
        end;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, 2);
    end;

    local procedure CreateSalesHeaderWithDocNo(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DocNo: Code[20])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        SetOfficeHostUnAvailable();
        Clear(SalesHeader);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader."No." := DocNo;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);
        InitializeOfficeHostProvider(OfficeHostType.OutlookHyperlink);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;
}

