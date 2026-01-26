codeunit 144201 "FatturaPA ValidateDocOnPosting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        IsInitialized: Boolean;
        FatturaPATxt: Label 'FATTURAPA', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSetupFieldsUI()
    var
        SalesReceivablesSetupPage: TestPage "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [UI] [Sales] [DEMO]
        // [SCENARIO 259342] Page 459 "Sales & Receivables Setup" has fields "Fattura PA Electronic Format", "Validate Document On Posting"
        Initialize();

        LibraryApplicationArea.EnableFoundationSetup();
        SalesReceivablesSetupPage.OpenEdit();
        Assert.IsTrue(SalesReceivablesSetupPage."Fattura PA Electronic Format".Editable(), '');
        Assert.IsTrue(SalesReceivablesSetupPage."Fattura PA Electronic Format".Visible(), '');
        Assert.IsTrue(SalesReceivablesSetupPage."Validate Document On Posting".Editable(), '');
        Assert.IsTrue(SalesReceivablesSetupPage."Validate Document On Posting".Visible(), '');

        // Default demo data values: "Fattura PA Electronic Format" = "FATTURAPA", "Validate Document On Posting" = FALSE
        SalesReceivablesSetupPage."Fattura PA Electronic Format".AssertEquals(FatturaPATxt);
        SalesReceivablesSetupPage."Validate Document On Posting".AssertEquals(false);
        SalesReceivablesSetupPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceSetupFieldsUI()
    var
        ServiceMgtSetup: TestPage "Service Mgt. Setup";
    begin
        // [FEATURE] [UT] [UI] [Service]
        // [SCENARIO 259342] Page 5919 "Service Mgt. Setup" has field "Validate Document On Posting"
        Initialize();

        LibraryApplicationArea.EnableServiceManagementSetup();
        ServiceMgtSetup.OpenEdit();
        Assert.IsTrue(ServiceMgtSetup."Validate Document On Posting".Editable(), '');
        Assert.IsTrue(ServiceMgtSetup."Validate Document On Posting".Visible(), '');

        // Default demo data value: "Validate Document On Posting" = FALSE
        ServiceMgtSetup."Validate Document On Posting".AssertEquals(false);
        ServiceMgtSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSetup_EnableVerifyDocCheckbox_BlankedFormatCode()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 259342] Enabling checkbox TAB 311 "Sales & Receivables Setup"."Validate Document On Posting" performs TESTFIELD on "Fattura PA Electronic Format"
        Initialize();
        LibraryITLocalization.SetValidateDocumentOnPostingSales(false, '');

        SalesReceivablesSetup.Get();
        asserterror SalesReceivablesSetup.Validate("Validate Document On Posting", true);
        VerifyTestFieldOnFatturaPACode();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSetup_EnableVerifyDocCheckbox_FormatNotSetupForValidate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 259342] Enabling checkbox TAB 311 "Sales & Receivables Setup"."Validate Document On Posting" verifies existing "Fattura PA Electronic Format" with Usage="Sales Validation"
        Initialize();
        LibrarySales.SetFatturaPAElectronicFormat(FatturaPATxt);

        // Remove ElectronicDocumentFormat for Usage="Sales Validation" (but leave for Usage="Sales Invoice")
        if ElectronicDocumentFormat.Get(FatturaPATxt, ElectronicDocumentFormat.Usage::"Sales Validation") then
            ElectronicDocumentFormat.Delete();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Validate Document On Posting", false);
        asserterror SalesReceivablesSetup.Validate("Validate Document On Posting", true);
        VerifyRecordNotFoundSalesValidation();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSetup_MarkUnMarkVerifyDocCheckbox_Positive()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 259342] Mark\UnMark checkbox TAB 311 "Sales & Receivables Setup"."Validate Document On Posting"
        Initialize();
        LibraryITLocalization.SetValidateDocumentOnPostingSales(false, FatturaPATxt);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Validate Document On Posting", true);
        SalesReceivablesSetup.Validate("Validate Document On Posting", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSetup_BlankedFormatCodeAfterMarkVerifyDocCheckbox()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 259342] Blanked TAB 311 "Sales & Receivables Setup"."Fattura PA Electronic Format" doesn't UnMark "Validate Document On Posting"
        Initialize();
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);

        LibrarySales.SetFatturaPAElectronicFormat('');

        SalesReceivablesSetup.Get();
        Assert.IsTrue(SalesReceivablesSetup."Validate Document On Posting", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSetup_UnMarkVerifyDocCheckboxAfterBlankedFormatCode()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 259342] UnMark checkbox TAB 311 "Sales & Receivables Setup"."Validate Document On Posting" after blanked "Fattura PA Electronic Format"
        Initialize();
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);
        LibrarySales.SetFatturaPAElectronicFormat('');

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Validate Document On Posting", true);

        SalesReceivablesSetup.Validate("Validate Document On Posting", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceSetup_EnableVerifyDocCheckbox_BlankedFormatCode()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 259342] Enabling checkbox TAB 5911 "Service Mgt. Setup"."Validate Document On Posting" performs TESTFIELD on "Fattura PA Electronic Format"
        Initialize();
        LibraryITLocalization.SetValidateDocumentOnPostingService(false, '');

        ServiceMgtSetup.Get();
        asserterror ServiceMgtSetup.Validate("Validate Document On Posting", true);
        VerifyTestFieldOnFatturaPACode();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceSetup_EnableVerifyDocCheckbox_FormatNotSetupForValidate()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 259342] Enabling checkbox TAB 5911 "Service Mgt. Setup"."Validate Document On Posting" verifies existing "Fattura PA Electronic Format" with Usage="Service Validation"
        Initialize();
        LibrarySales.SetFatturaPAElectronicFormat(FatturaPATxt);

        // Remove ElectronicDocumentFormat for Usage="Service Validation" (but leave for Usage="Sales Invoice")
        if ElectronicDocumentFormat.Get(FatturaPATxt, ElectronicDocumentFormat.Usage::"Service Validation") then
            ElectronicDocumentFormat.Delete();

        ServiceMgtSetup.Get();
        ServiceMgtSetup.TestField("Validate Document On Posting", false);
        asserterror ServiceMgtSetup.Validate("Validate Document On Posting", true);
        VerifyRecordNotFoundServiceValidation();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceSetup_MarkUnMarkVerifyDocCheckbox_Positive()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 259342] Mark\UnMark checkbox TAB 5911 "Service Mgt. Setup"."Validate Document On Posting"
        Initialize();
        LibraryITLocalization.SetValidateDocumentOnPostingService(false, FatturaPATxt);

        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Validate Document On Posting", true);
        ServiceMgtSetup.Validate("Validate Document On Posting", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceSetup_BlankedFormatCodeAfterMarkVerifyDocCheckbox()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 259342] Blanked TAB 311 "Sales & Receivables Setup"."Fattura PA Electronic Format" doesn't UnMark "Validate Document On Posting"
        Initialize();
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);

        LibrarySales.SetFatturaPAElectronicFormat('');

        ServiceMgtSetup.Get();
        Assert.IsTrue(ServiceMgtSetup."Validate Document On Posting", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceSetup_UnMarkVerifyDocCheckboxAfterBlankedFormatCode()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 259342] UnMark checkbox TAB 5911 "Service Mgt. Setup"."Validate Document On Posting" after blanked "Fattura PA Electronic Format"
        Initialize();
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);
        LibrarySales.SetFatturaPAElectronicFormat('');

        ServiceMgtSetup.Get();
        ServiceMgtSetup.TestField("Validate Document On Posting", true);

        ServiceMgtSetup.Validate("Validate Document On Posting", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_EnabledValidate_TypedPACode_TypedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] No errors on posting sales invoice with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);

        // [GIVEN] Sales invoice for customer with typed "PA Code", typed Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesInvoice_EnabledValidate_TypedPACode_BlankedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] An Error Message Log is shown trying to post sales invoice with typed PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);

        // [GIVEN] Sales invoice for customer with typed "PA Code", blanked Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), '');

        // [WHEN] Post the document
        LibraryErrorMessage.TrapErrorMessages();
        PostSalesInvoiceUI(SalesHeader);

        // [THEN] An Error Message Log is shown with "Payment Method Code" field
        VerifyErrorMessageLog(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_EnabledValidate_BlankedPACode_TypedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] No errors on posting sales invoice with blanked PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);

        // [GIVEN] Sales invoice for customer with blanked "PA Code", typed Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo(''), CreatePaymentMethod());

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_EnabledValidate_BlankedPACode_BlankedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] No errors on posting sales invoice with blanked PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);

        // [GIVEN] Sales invoice for customer with blanked "PA Code", blanked Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo(''), '');

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_EnabledValidate_BlankedFatturaFormatCode()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] TestField error is shown trying to post sales invoice with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE, blanked "Fattura PA Electronic Format"
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = TRUE, "Fattura PA Electronic Format" = ""
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);
        LibrarySales.SetFatturaPAElectronicFormat('');

        // [GIVEN] Sales invoice for customer with typed "PA Code", typed Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There is a TestField error on blanked "Fattura PA Electronic Format"
        VerifyTestFieldOnFatturaPACode();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_EnabledValidate_FormatNotSetupForValidate()
    var
        SalesHeader: Record "Sales Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] Record Not Found error is shown trying to post sales invoice with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE, "Fattura PA Electronic Format" is not setup for Usage="Sales Validation"
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = TRUE, "Fattura PA Electronic Format" is typed but not setup for Usage="Sales Validation"
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);
        if ElectronicDocumentFormat.Get(FatturaPATxt, ElectronicDocumentFormat.Usage::"Sales Validation") then
            ElectronicDocumentFormat.Delete();

        // [GIVEN] Sales invoice for customer with typed "PA Code", typed Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There is a RecordNotFound error on GET Electronic Document Format with Code="Fattura PA Electronic Format", Usage="Sales Validation"
        VerifyRecordNotFoundSalesValidation();

        // Tear Down
        LibraryITLocalization.InsertFatturaElectronicFormats(FatturaPATxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_DisabledValidate_TypedPACode_TypedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] No errors on posting sales invoice with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = FALSE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = FALSE
        LibrarySales.SetValidateDocumentOnPosting(false);

        // [GIVEN] Sales invoice for customer with typed "PA Code", typed Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_DisabledValidate_TypedPACode_BlankedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] No errors on posting sales invoice with typed PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = FALSE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = FALSE
        LibrarySales.SetValidateDocumentOnPosting(false);

        // [GIVEN] Sales invoice for customer with typed "PA Code", blanked Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), '');

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_DisabledValidate_BlankedPACode_TypedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] No errors on posting sales invoice with blanked PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = FALSE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = FALSE
        LibrarySales.SetValidateDocumentOnPosting(false);

        // [GIVEN] Sales invoice for customer with blanked "PA Code", typed Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo(''), CreatePaymentMethod());

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_DisabledValidate_BlankedPACode_BlankedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] No errors on posting sales invoice with blanked PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = FALSE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = FALSE
        LibrarySales.SetValidateDocumentOnPosting(false);

        // [GIVEN] Sales invoice for customer with blanked "PA Code", blanked Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo(''), '');

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemo_EnabledValidate_TypedPACode_TypedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 259342] No errors on posting sales credit memo with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);

        // [GIVEN] Sales credit memo for customer with typed "PA Code", typed Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        SalesCrMemoHeader.Get(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesCrMemo_EnabledValidate_TypedPACode_BlankedPmtMethod()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 259342] An Error Message Log is shown trying to post sales credit memo with typed PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Sales Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingSales(true, FatturaPATxt);

        // [GIVEN] Sales credit memo for customer with typed "PA Code", blanked Payment Method
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerNo('1234567'), '');

        // [WHEN] Post the document
        LibraryErrorMessage.TrapErrorMessages();
        PostSalesCrMemoUI(SalesHeader);

        // [THEN] An Error Message Log is shown with "Payment Method Code" field
        VerifyErrorMessageLog(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_EnabledValidate_TypedPACode_TypedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] No errors on posting service invoice with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);

        // [GIVEN] Service invoice for customer with typed "PA Code", typed Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The document has been posted
        VerifyServiceInvoiceHeaderExists(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoice_EnabledValidate_TypedPACode_BlankedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] An Error Message Log is shown trying to post service invoice with typed PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);

        // [GIVEN] Service invoice for customer with typed "PA Code", blanked Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), '');

        // [WHEN] Post the document
        LibraryErrorMessage.TrapErrorMessages();
        PostServiceInvoiceUI(ServiceHeader);

        // [THEN] An Error Message Log is shown with "Payment Method Code" field
        VerifyErrorMessageLog(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_EnabledValidate_BlankedPACode_TypedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] No errors on posting service invoice with blanked PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);

        // [GIVEN] Service invoice for customer with blanked "PA Code", typed Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo(''), CreatePaymentMethod());

        // [WHEN] Post the document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The document has been posted
        VerifyServiceInvoiceHeaderExists(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_EnabledValidate_BlankedPACode_BlankedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] No errors on posting service invoice with blanked PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);

        // [GIVEN] Service invoice for customer with blanked "PA Code", blanked Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo(''), '');

        // [WHEN] Post the document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The document has been posted
        VerifyServiceInvoiceHeaderExists(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_EnabledValidate_BlankedFatturaFormatCode()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] TestField error is shown trying to post service invoice with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE, blanked "Fattura PA Electronic Format"
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = TRUE, "Fattura PA Electronic Format" = ""
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);
        LibrarySales.SetFatturaPAElectronicFormat('');

        // [GIVEN] Service invoice for customer with typed "PA Code", typed Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] There is a TestField error on blanked "Fattura PA Electronic Format"
        VerifyTestFieldOnFatturaPACode();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_EnabledValidate_FormatNotSetupForValidate()
    var
        ServiceHeader: Record "Service Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] Record Not Found error is shown trying to post service invoice with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE, "Fattura PA Electronic Format" is not setup for Usage="Service Validation"
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = TRUE, "Fattura PA Electronic Format" is typed but not setup for Usage = "Service Validation"
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);
        if ElectronicDocumentFormat.Get(FatturaPATxt, ElectronicDocumentFormat.Usage::"Service Validation") then
            ElectronicDocumentFormat.Delete();

        // [GIVEN] Service invoice for customer with typed "PA Code", typed Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] There is a RecordNotFound error on GET Electronic Document Format with Code="Fattura PA Electronic Format", Usage="Service Validation"
        VerifyRecordNotFoundServiceValidation();

        // Tear Down
        LibraryITLocalization.InsertFatturaElectronicFormats(FatturaPATxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_DisabledValidate_TypedPACode_TypedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] No errors on posting service invoice with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = FALSE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = FALSE
        LibraryService.SetValidateDocumentOnPosting(false);

        // [GIVEN] Service invoice for customer with typed "PA Code", typed Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The document has been posted
        VerifyServiceInvoiceHeaderExists(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_DisabledValidate_TypedPACode_BlankedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] No error on posting service invoice with typed PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = FALSE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = FALSE
        LibraryService.SetValidateDocumentOnPosting(false);

        // [GIVEN] Service invoice for customer with typed "PA Code", blanked Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo('1234567'), '');

        // [WHEN] Post the document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The document has been posted
        VerifyServiceInvoiceHeaderExists(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_DisabledValidate_BlankedPACode_TypedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] No errors on posting service invoice with blanked PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = FALSE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = FALSE
        LibraryService.SetValidateDocumentOnPosting(false);

        // [GIVEN] Service invoice for customer with blanked "PA Code", typed Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo(''), CreatePaymentMethod());

        // [WHEN] Post the document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The document has been posted
        VerifyServiceInvoiceHeaderExists(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoice_DisabledValidate_BlankedPACode_BlankedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 259342] No errors on posting service invoice with blanked PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = FALSE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = FALSE
        LibraryService.SetValidateDocumentOnPosting(false);

        // [GIVEN] Service invoice for customer with blanked "PA Code", blanked Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNo(''), '');

        // [WHEN] Post the document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The document has been posted
        VerifyServiceInvoiceHeaderExists(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemo_EnabledValidate_TypedPACode_TypedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 259342] No errors on posting service credit memo with typed PA Code, typed Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);

        // [GIVEN] Service credit memo for customer with typed "PA Code", typed Payment Method
        CreateServiceDocument(
          ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomerNo('1234567'), CreatePaymentMethod());

        // [WHEN] Post the document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The document has been posted
        VerifyServiceCrMemoHeaderExists(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCrMemo_EnabledValidate_TypedPACode_BlankedPmtMethod()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 259342] An Error Message Log is shown trying to post service credit memo with typed PA Code, blanked Payment Method
        // [SCENARIO 259342] in case of "Validate Document On Posting" = TRUE
        Initialize();

        // [GIVEN] Service Setup "Validate Document On Posting" = TRUE
        LibraryITLocalization.SetValidateDocumentOnPostingService(true, FatturaPATxt);

        // [GIVEN] Service credit memo for customer with typed "PA Code", blanked Payment Method
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomerNo('1234567'), '');

        // [WHEN] Post the document
        LibraryErrorMessage.TrapErrorMessages();
        PostServiceCrMemoUI(ServiceHeader);

        // [THEN] An Error Message Log is shown with "Payment Method Code" field
        VerifyErrorMessageLog(ServiceHeader);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibraryITLocalization.SetupFatturaPA();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PaymentMethodCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; PaymentMethodCode: Code[10])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("Payment Method Code", PaymentMethodCode);
        ServiceHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerNo(PACode: Code[7]): Code[20]
    begin
        exit(LibraryITLocalization.CreateFatturaCustomerNo(PACode));
    end;

    local procedure CreatePaymentMethod(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentMethodCode());
    end;

    local procedure CreatePaymentTerms(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentTermsCode());
    end;

    local procedure PostSalesInvoiceUI(SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Post.Invoke();
    end;

    local procedure PostSalesCrMemoUI(SalesHeader: Record "Sales Header")
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Post.Invoke();
    end;

    local procedure PostServiceInvoiceUI(ServiceHeader: Record "Service Header")
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceInvoice.Post.Invoke();
    end;

    local procedure PostServiceCrMemoUI(ServiceHeader: Record "Service Header")
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo.Post.Invoke();
    end;

    local procedure VerifyTestFieldOnFatturaPACode()
    var
        DummySalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(DummySalesReceivablesSetup.FieldCaption("Fattura PA Electronic Format"));
    end;

    local procedure VerifyRecordNotFoundSalesValidation()
    begin
        Assert.ExpectedErrorCannotFind(Database::"Electronic Document Format");
    end;

    local procedure VerifyRecordNotFoundServiceValidation()
    begin
        Assert.ExpectedErrorCannotFind(Database::"Electronic Document Format");
    end;

    local procedure VerifyServiceInvoiceHeaderExists(ServiceHeader: Record "Service Header")
    var
        DummyServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        DummyServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        DummyServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        Assert.RecordIsNotEmpty(DummyServiceInvoiceHeader);
    end;

    local procedure VerifyServiceCrMemoHeaderExists(ServiceHeader: Record "Service Header")
    var
        DummyServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        DummyServiceCrMemoHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        DummyServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        Assert.RecordIsNotEmpty(DummyServiceCrMemoHeader);
    end;

    local procedure VerifyErrorMessageLog(RecordVariant: Variant)
    var
        DummyErrorMessage: Record "Error Message";
        DummySalesHeader: Record "Sales Header";
    begin
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          RecordVariant, DummySalesHeader.FieldNo("Payment Method Code"), DummyErrorMessage."Message Type"::Error);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

