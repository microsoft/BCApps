codeunit 147330 "Edit Posted Documents ES"
{
    Permissions = TableData "Sales Invoice Header" = ri,
                  TableData "Purch. Inv. Header" = ri;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSetValuesCancel()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Sales Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader);
        PostedDocNo := CreateAndPostSalesInvoice();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Sales Invoice Header were not changed.
        Assert.AreNotEqual(Format(SalesInvoiceHeader."Special Scheme Code"), PostedSalesInvoice."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(SalesInvoiceHeader."Invoice Type"), PostedSalesInvoice."Invoice Type".Value, '');
        Assert.AreNotEqual(Format(SalesInvoiceHeader."ID Type"), PostedSalesInvoice."ID Type".Value, '');
        Assert.AreNotEqual(SalesInvoiceHeader."Succeeded Company Name", PostedSalesInvoice."Succeeded Company Name".Value, '');
        Assert.AreNotEqual(
          SalesInvoiceHeader."Succeeded VAT Registration No.", PostedSalesInvoice."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSetValuesOK()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice] [Permissions]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Sales Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page. A user with "D365 Sales Doc, Post" permission set.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader);
        PostedDocNo := CreateAndPostSalesInvoice();
        LibraryLowerPermissions.SetSalesDocsPost();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Sales Invoice Header were changed.
        Assert.AreEqual(Format(SalesInvoiceHeader."Special Scheme Code"), PostedSalesInvoice."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(SalesInvoiceHeader."Invoice Type"), PostedSalesInvoice."Invoice Type".Value, '');
        Assert.AreEqual(Format(SalesInvoiceHeader."ID Type"), PostedSalesInvoice."ID Type".Value, '');
        Assert.AreEqual(SalesInvoiceHeader."Succeeded Company Name", PostedSalesInvoice."Succeeded Company Name".Value, '');
        Assert.AreEqual(
          SalesInvoiceHeader."Succeeded VAT Registration No.", PostedSalesInvoice."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateInvDetailsCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateSetValuesCancel()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Pstd. Sales Cr. Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Pstd. Sales Cr. Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);
        PostedDocNo := CreateAndPostSalesCreditMemo();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Sales Cr.Memo Header were not changed.
        Assert.AreNotEqual(Format(SalesCrMemoHeader."Special Scheme Code"), PostedSalesCreditMemo."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(SalesCrMemoHeader."Cr. Memo Type"), PostedSalesCreditMemo."Cr. Memo Type".Value, '');
        Assert.AreNotEqual(Format(SalesCrMemoHeader."Correction Type"), PostedSalesCreditMemo."Correction Type".Value, '');
        // Bug id 452979: Fields added to the posted sales/purchase credit memo page
        Assert.AreNotEqual(Format(SalesCrMemoHeader."ID Type"), PostedSalesCreditMemo."ID Type".Value, '');
        Assert.AreNotEqual(
          Format(SalesCrMemoHeader."Succeeded Company Name"), PostedSalesCreditMemo."Succeeded Company Name".Value, '');
        Assert.AreNotEqual(
          Format(SalesCrMemoHeader."Succeeded VAT Registration No."), PostedSalesCreditMemo."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateInvDetailsOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateSetValuesOK()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        SIIDocUploadState: Record "SII Doc. Upload State";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo] [Permissions]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Pstd. Sales Cr. Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);
        MockSIIDocUploadState(
            SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger",
            SIIDocUploadState."Document Type"::"Credit Memo", SalesCrMemoHeader."Posting Date", SalesCrMemoHeader."No.");

        // [GIVEN] Opened "Pstd. Sales Cr. Memo - Update" page. A user with "D365 Sales Doc, Post" permission set.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);
        PostedDocNo := CreateAndPostSalesCreditMemo();
        LibraryLowerPermissions.SetSalesDocsPost();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Sales Cr.Memo Header were changed.
        Assert.AreEqual(Format(SalesCrMemoHeader."Special Scheme Code"), PostedSalesCreditMemo."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(SalesCrMemoHeader."Cr. Memo Type"), PostedSalesCreditMemo."Cr. Memo Type".Value, '');
        Assert.AreEqual(Format(SalesCrMemoHeader."Correction Type"::Difference), PostedSalesCreditMemo."Correction Type".Value, '');
        // Bug id 452979: Fields added to the posted sales/purchase credit memo page
        Assert.AreEqual(Format(SalesCrMemoHeader."ID Type"), PostedSalesCreditMemo."ID Type".Value, '');
        Assert.AreEqual(
          Format(SalesCrMemoHeader."Succeeded Company Name"), PostedSalesCreditMemo."Succeeded Company Name".Value, '');
        Assert.AreEqual(
          Format(SalesCrMemoHeader."Succeeded VAT Registration No."), PostedSalesCreditMemo."Succeeded VAT Registration No.".Value, '');

        // [THEN] "Is Credit Memo Removal" is disabled in the SII Doc. Upload State
        // Bug 440952: "Is Credit Memo Removal" is disabled when user changeed the correction type from Removal to Difference
        SIIDocUploadState.Find();
        SIIDocUploadState.TestField("Is Credit Memo Removal", false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateSetValuesCancel()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Purch. Cr.Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Opened "Posted Purch. Cr.Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);
        PostedDocNo := CreateAndPostPurchaseCreditMemo();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Purch. Cr. Memo Hdr. were not changed.
        Assert.AreNotEqual(Format(PurchCrMemoHdr."Special Scheme Code"), PostedPurchaseCreditMemo."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(PurchCrMemoHdr."Cr. Memo Type"), PostedPurchaseCreditMemo."Cr. Memo Type".Value, '');
        Assert.AreNotEqual(Format(PurchCrMemoHdr."Correction Type"), PostedPurchaseCreditMemo."Correction Type".Value, '');
        // Bug id 452979: Fields added to the posted sales/purchase credit memo page
        Assert.AreNotEqual(Format(PurchCrMemoHdr."ID Type"), PostedPurchaseCreditMemo."ID Type".Value, '');
        Assert.AreNotEqual(
          Format(PurchCrMemoHdr."Succeeded Company Name"), PostedPurchaseCreditMemo."Succeeded Company Name".Value, '');
        Assert.AreNotEqual(
          Format(PurchCrMemoHdr."Succeeded VAT Registration No."), PostedPurchaseCreditMemo."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateSetValuesOK()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SIIDocUploadState: Record "SII Doc. Upload State";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo] [Permissions]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Purch. Cr.Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);
        MockSIIDocUploadState(
            SIIDocUploadState, SIIDocUploadState."Document Source"::"Vendor Ledger",
            SIIDocUploadState."Document Type"::"Credit Memo", PurchCrMemoHdr."Posting Date", PurchCrMemoHdr."No.");

        // [GIVEN] Opened "Posted Purch. Cr.Memo - Update" page. A user with "D365 Purch Doc, Post" permission set.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);
        PostedDocNo := CreateAndPostPurchaseCreditMemo();
        LibraryLowerPermissions.SetPurchDocsPost();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Purch. Cr. Memo Hdr. were changed.
        Assert.AreEqual(Format(PurchCrMemoHdr."Special Scheme Code"), PostedPurchaseCreditMemo."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(PurchCrMemoHdr."Cr. Memo Type"), PostedPurchaseCreditMemo."Cr. Memo Type".Value, '');
        Assert.AreEqual(Format(PurchCrMemoHdr."Correction Type"::Difference), PostedPurchaseCreditMemo."Correction Type".Value, '');
        // Bug id 452979: Fields added to the posted sales/purchase credit memo page
        Assert.AreEqual(Format(PurchCrMemoHdr."ID Type"), PostedPurchaseCreditMemo."ID Type".Value, '');
        Assert.AreEqual(
          Format(PurchCrMemoHdr."Succeeded Company Name"), PostedPurchaseCreditMemo."Succeeded Company Name".Value, '');
        Assert.AreEqual(
          Format(PurchCrMemoHdr."Succeeded VAT Registration No."), PostedPurchaseCreditMemo."Succeeded VAT Registration No.".Value, '');

        // [THEN] "Is Credit Memo Removal" is disabled in the SII Doc. Upload State
        // Bug 440952: "Is Credit Memo Removal" is disabled when user changeed the correction type from Removal to Difference
        SIIDocUploadState.Find();
        SIIDocUploadState.TestField("Is Credit Memo Removal", false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateCancelModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateSetValuesCancel()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 373682] New values for editable fields are not set in case Stan presses Cancel on "Posted Service Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader);

        // [GIVEN] Posted Service Invoice. Opened "Posted Service Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader);
        PostedDocNo := CreateAndPostServiceInvoice();

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Service Invoice Header were not changed.
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Country/Region Code"), PostedServiceInvoice."Country/Region Code".Value, '');
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Bill-to Country/Region Code"), PostedServiceInvoice."Bill-to Country/Region Code".Value, '');
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Ship-to Country/Region Code"), PostedServiceInvoice."Ship-to Country/Region Code".Value, '');

        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Special Scheme Code"), PostedServiceInvoice."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."Invoice Type"), PostedServiceInvoice."Invoice Type".Value, '');
        Assert.AreNotEqual(Format(ServiceInvoiceHeader."ID Type"), PostedServiceInvoice."ID Type".Value, '');
        Assert.AreNotEqual(ServiceInvoiceHeader."Succeeded Company Name", PostedServiceInvoice."Succeeded Company Name".Value, '');
        Assert.AreNotEqual(
          ServiceInvoiceHeader."Succeeded VAT Registration No.", PostedServiceInvoice."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateSetValuesOK()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Invoice] [Permissions]
        // [SCENARIO 373682] New values for editable fields are set in case Stan presses OK on "Posted Service Invoice - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader);

        // [GIVEN] Posted Service Invoice. Opened "Posted Service Invoice - Update" page.
        // [GIVEN] A user with "D365PREM SMG, VIEW" permission set. This set allows user to Modify all service related tables.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader);
        PostedDocNo := CreateAndPostServiceInvoice();
        LibraryLowerPermissions.SetO365ServiceMgtRead();

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Service Invoice Header were changed.
        Assert.AreEqual(Format(ServiceInvoiceHeader."Country/Region Code"), PostedServiceInvoice."Country/Region Code".Value, '');
        Assert.AreEqual(Format(ServiceInvoiceHeader."Bill-to Country/Region Code"), PostedServiceInvoice."Bill-to Country/Region Code".Value, '');
        Assert.AreEqual(Format(ServiceInvoiceHeader."Ship-to Country/Region Code"), PostedServiceInvoice."Ship-to Country/Region Code".Value, '');

        Assert.AreEqual(Format(ServiceInvoiceHeader."Special Scheme Code"), PostedServiceInvoice."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(ServiceInvoiceHeader."Invoice Type"), PostedServiceInvoice."Invoice Type".Value, '');
        Assert.AreEqual(Format(ServiceInvoiceHeader."ID Type"), PostedServiceInvoice."ID Type".Value, '');
        Assert.AreEqual(ServiceInvoiceHeader."Succeeded Company Name", PostedServiceInvoice."Succeeded Company Name".Value, '');
        Assert.AreEqual(
          ServiceInvoiceHeader."Succeeded VAT Registration No.", PostedServiceInvoice."Succeeded VAT Registration No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceCreditMemoUpdateCancelModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateSetValuesCancel()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 373682] New values for editable fields are not set in case Stan presses Cancel on "Posted Service Credit Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader);

        // [GIVEN] Posted Service Credit Memo. Opened "Posted Service Credit Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader);
        PostedDocNo := CreateAndPostServiceCreditMemo();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Service Credit Memo Header were not changed.
        Assert.AreNotEqual(Format(ServiceCrMemoHeader."Special Scheme Code"), PostedServiceCreditMemo."Special Scheme Code".Value, '');
        Assert.AreNotEqual(Format(ServiceCrMemoHeader."Cr. Memo Type"), PostedServiceCreditMemo."Cr. Memo Type".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceCreditMemoUpdateOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateSetValuesOK()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Credit Memo] [Permissions]
        // [SCENARIO 373682] New values for editable fields are set in case Stan presses OK on "Posted Service Credit Memo - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader);

        // [GIVEN] Posted Service Credit Memo. Opened "Posted Service Credit Memo - Update" page.
        // [GIVEN] A user with "D365PREM SMG, VIEW" permission set. This set allows user to Modify all service related tables.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader);
        PostedDocNo := CreateAndPostServiceCreditMemo();
        LibraryLowerPermissions.SetO365ServiceMgtRead();
        LibraryLowerPermissions.AddSalesDocsPost();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Service Credit Memo Header were changed.
        Assert.AreEqual(Format(ServiceCrMemoHeader."Special Scheme Code"), PostedServiceCreditMemo."Special Scheme Code".Value, '');
        Assert.AreEqual(Format(ServiceCrMemoHeader."Cr. Memo Type"), PostedServiceCreditMemo."Cr. Memo Type".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateOperationDescrCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOperationDescriptionCancel()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Sales Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Sales Invoice. Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostSalesInvoice();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Sales Invoice Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedSalesInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateOperationDescrOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOperationDescriptionOK()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Sales Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Sales Invoice. Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostSalesInvoice();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Sales Invoice Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedSalesInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateOperationDescrCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOperationDescriptionCancel()
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Sales Cr. Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Sales Credit Memo. Opened "Posted Sales Cr. Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostSalesCreditMemo();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Sales Credit Memo Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedSalesCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateOperationDescrOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOperationDescriptionOK()
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Sales Cr. Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Sales Credit Memo. Opened "Posted Sales Cr. Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostSalesCreditMemo();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Sales Credit Memo Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedSalesCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOperationDescrCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceUpdateOperationDescriptionCancel()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Purchase Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Purchase Invoice. Opened "Posted Purchase Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostPurchaseInvoice();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Purchase Invoice Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedPurchaseInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOperationDescrOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceUpdateOperationDescriptionOK()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Purchase Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Purchase Invoice. Opened "Posted Purchase Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostPurchaseInvoice();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Purchase Invoice Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedPurchaseInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateOperationDescrCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoUpdateOperationDescriptionCancel()
    var
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Purchase Credit Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Purchase Credit Memo. Opened "Posted Purchase Credit Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostPurchaseCreditMemo();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Purchase Credit Memo Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedPurchaseCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateOperationDescrOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoUpdateOperationDescriptionOK()
    var
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Purchase Credit Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Purchase Credit Memo. Opened "Posted Purchase Credit Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostPurchaseCreditMemo();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Purchase Credit Memo Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedPurchaseCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateOperationDescrCancelModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOperationDescriptionCancel()
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Service Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Service Invoice. Opened "Posted Service Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostServiceInvoice();

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Service Invoice Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedServiceInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateOperationDescrOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOperationDescriptionOK()
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Service Invoice - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Service Invoice. Opened "Posted Service Invoice - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostServiceInvoice();

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Service Invoice Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedServiceInvoice.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceCreditMemoUpdateOperationDescrCancelModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoUpdateOperationDescriptionCancel()
    var
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is not set in case Stan presses Cancel on "Posted Service Credit Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Service Credit Memo. Opened "Posted Service Credit Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostServiceCreditMemo();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Value of Operation Description field in Service Credit Memo Header was not changed.
        Assert.AreNotEqual(OperationDescriptionTxt, PostedServiceCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceCreditMemoUpdateOperationDescrOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoUpdateOperationDescriptionOK()
    var
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        PostedDocNo: Code[20];
        OperationDescriptionTxt: Text[500];
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 374194] New value for Operation Description field is set in case Stan presses OK on "Posted Service Credit Memo - Update" modal page.
        Initialize();
        OperationDescriptionTxt :=
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(OperationDescriptionTxt)), 1, MaxStrLen(OperationDescriptionTxt));

        // [GIVEN] Posted Service Credit Memo. Opened "Posted Service Credit Memo - Update" page.
        // [GIVEN] New value is set for Operation Description field.
        LibraryVariableStorage.Enqueue(OperationDescriptionTxt);
        PostedDocNo := CreateAndPostServiceCreditMemo();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Value of Operation Description field in Service Credit Memo Header was changed.
        Assert.AreEqual(OperationDescriptionTxt, PostedServiceCreditMemo.OperationDescription.Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateLookupCorrInvNolModalPageHandler,PostedSalesInvoicesCheckLookupValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookupCorrectedInvoiceNoFromPostedSalesCreditMemoPage()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 405655] Stan can lookup posted sales invoices from the "Corrected Invoice No." field of the "Posted Sales Credit Memo - Edit"chec page

        Initialize();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemoForCustomer(SalesInvoiceHeader."Bill-to Customer No."));

        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");
        PostedSalesCreditMemo."Update Document".Invoke();

        // Verification performs withing handlers: PostedSalesCrMemoUpdateLookupCorrInvNolModalPageHandler,PostedSalesInvoicesCheckLookupValueModalPageHandler
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateLookupCorrInvNolModalPageHandler,PostedPurchInvoicesCheckLookupValueModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookupCorrectedInvoiceNoFromPostedPurchCreditMemoPage()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 405655] Stan can lookup posted purchase invoices from the "Corrected Invoice No." field of the "Posted Purchase Credit Memo - Edit" page

        Initialize();
        PurchInvHeader.Get(CreateAndPostPurchaseInvoice());
        PurchCrMemoHdr.Get(CreateAndPostPurchaseCreditMemoForVendor(PurchInvHeader."Pay-to Vendor No."));

        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // Verification performs withing handlers: PostedPurchCrMemoUpdateLookupCorrInvNolModalPageHandler,PostedPurchInvoicesCheckLookupValueModalPageHandler
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateCorrInvNoCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCorrInvNoCancel()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 405655] Corrected Invoice No. is not set in case Stan presses Cancel on "Pstd. Sales Cr. Memo - Update" modal page.

        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Pstd. Sales Cr. Memo - Update" page.
        // [GIVEN] "Corrected Invoice No." is set
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Corrected Invoice No.");
        PostedDocNo := CreateAndPostSalesCreditMemo();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.
        // [THEN] Corrected Invoice No. is not changed
        Assert.AreNotEqual(SalesCrMemoHeader."Corrected Invoice No.", PostedSalesCreditMemo."Corrected Invoice No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateCorrInvNoOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCorrInvNoOK()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo] [Permissions]
        // [SCENARIO 405655] Corrected Invoice No. is set in case Stan presses OK on "Pstd. Sales Cr. Memo - Update" modal page.

        Initialize();
        PrepareValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Pstd. Sales Cr. Memo - Update" page. A user with "D365 Sales Doc, Post" permission set.
        // [GIVEN] "Corrected Invoice No." is set
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Corrected Invoice No.");
        PostedDocNo := CreateAndPostSalesCreditMemo();
        LibraryLowerPermissions.SetSalesDocsPost();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.
        // [THEN] Corrected Invoice No. is changed
        Assert.AreEqual(SalesCrMemoHeader."Corrected Invoice No.", PostedSalesCreditMemo."Corrected Invoice No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateCorrInvNoCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCorrInvNoCancel()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 405655] Corrected Invoice No. not set in case Stan presses Cancel on "Posted Purch. Cr.Memo - Update" modal page.

        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Opened "Posted Purch. Cr.Memo - Update" page.
        // [GIVEN] "Corrected Invoice No." is set
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Corrected Invoice No.");
        PostedDocNo := CreateAndPostPurchaseCreditMemo();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.
        // [THEN] Corrected Invoice No. is not changed
        Assert.AreNotEqual(PurchCrMemoHdr."Corrected Invoice No.", PostedPurchaseCreditMemo."Corrected Invoice No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateCorrInvNoOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCorrInvNoOK()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo] [Permissions]
        // [SCENARIO 405655] Corrected Invoice No. is set in case Stan presses OK on "Posted Purch. Cr.Memo - Update" modal page.

        Initialize();
        PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Opened "Posted Purch. Cr.Memo - Update" page. A user with "D365 Purch Doc, Post" permission set.
        // [GIVEN] "Corrected Invoice No." is set
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Corrected Invoice No.");
        PostedDocNo := CreateAndPostPurchaseCreditMemo();
        LibraryLowerPermissions.SetPurchDocsPost();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.Filter.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.
        // [THEN] Corrected Invoice No. is changed
        Assert.AreEqual(PurchCrMemoHdr."Corrected Invoice No.", PostedPurchaseCreditMemo."Corrected Invoice No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateSpecSchemeCodeOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateSpecialSchemeCodeTakenFromVATPostingSetupInPostedSalesInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        SalesDocType: Enum "Sales Document Type";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 423069] Special Scheme updated for the posted sales invoice with VAT Posting Setup with scheme code specified

        Initialize();

        // [GIVEN] VAT Posting Setup with "Special Scheme Code" = "02 Export"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"02 Export");
        VATPostingSetup.Modify(true);

        // [GIVEN] Posted sales invoice with this VAT Posting Setup
        PostedDocNo := CreateAndPostSalesDocWithVATPostingSetup(SalesDocType::Invoice, VATPostingSetup);
        LibraryVariableStorage.Enqueue(Format(VATPostingSetup."Sales Special Scheme Code"::"01 General"));
        LibraryLowerPermissions.SetSalesDocsPost();

        // [GIVEN] Opened "Posted Sales Invoice - Update" page.
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", PostedDocNo);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Change "Special Scheme Code" to "01 General" and click OK
        // [THEN] Special Scheme Code is "01 General" in "SII Sales Document Scheme Code"
        SIISalesDocumentSchemeCode.Get(
          SIISalesDocumentSchemeCode."Entry Type"::Sales, SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice",
          PostedDocNo, VATPostingSetup."Sales Special Scheme Code"::"01 General");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateSpecSchemeCodeOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateSpecialSchemeCodeTakenFromVATPostingSetupInPostedSalesCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        SalesDocType: Enum "Sales Document Type";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 423069] Special Scheme updated for the posted sales credit memo with VAT Posting Setup with scheme code specified

        Initialize();

        // [GIVEN] VAT Posting Setup with "Special Scheme Code" = "02 Export"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"02 Export");
        VATPostingSetup.Modify(true);

        // [GIVEN] Posted sales credit memo with this VAT Posting Setup
        PostedDocNo := CreateAndPostSalesDocWithVATPostingSetup(SalesDocType::"Credit Memo", VATPostingSetup);
        LibraryVariableStorage.Enqueue(Format(VATPostingSetup."Sales Special Scheme Code"::"01 General"));
        LibraryLowerPermissions.SetSalesDocsPost();

        // [GIVEN] Opened "Posted Credit Memo - Update" page.
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", PostedDocNo);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Change "Special Scheme Code" to "01 General" and click OK
        // [THEN] Special Scheme Code is "01 General" in "SII Sales Document Scheme Code"
        SIISalesDocumentSchemeCode.Get(
          SIISalesDocumentSchemeCode."Entry Type"::Sales, SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo",
          PostedDocNo, VATPostingSetup."Sales Special Scheme Code"::"01 General");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateSpecSchemeCodeOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateSpecialSchemeCodeTakenFromVATPostingSetupInPostedPurchInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchDocType: Enum "Purchase Document Type";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 423069] Special Scheme updated for the posted purchase invoice with VAT Posting Setup with scheme code specified

        Initialize();

        // [GIVEN] VAT Posting Setup with "Special Scheme Code" = "02 Export"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate(
          "Purch. Special Scheme Code", VATPostingSetup."Purch. Special Scheme Code"::"02 Special System Activities");
        VATPostingSetup.Modify(true);

        // [GIVEN] Posted purchase invoice with this VAT Posting Setup
        PostedDocNo := CreateAndPostPurchDocWithVATPostingSetup(PurchDocType::Invoice, VATPostingSetup);
        LibraryVariableStorage.Enqueue(Format(VATPostingSetup."Purch. Special Scheme Code"::"01 General"));
        LibraryLowerPermissions.SetPurchDocsPost();

        // [GIVEN] Opened "Posted Purchase Invoice - Update" page.
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PostedDocNo);
        PostedPurchaseInvoice."Update Document".Invoke();

        // [WHEN] Change "Special Scheme Code" to "01 General" and click OK
        // [THEN] Special Scheme Code is "01 General" in "SII Purchse Document Scheme Code"
        SIIPurchDocSchemeCode.Get(
          SIIPurchDocSchemeCode."Document Type"::"Posted Invoice",
          PostedDocNo, VATPostingSetup."Purch. Special Scheme Code"::"01 General");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateSpecSchemeCodeOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateSpecialSchemeCodeTakenFromVATPostingSetupInPostedPurchCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PurchDocType: Enum "Purchase Document Type";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 423069] Special Scheme updated for the posted purchase credit memo with VAT Posting Setup with scheme code specified

        Initialize();

        // [GIVEN] VAT Posting Setup with "Special Scheme Code" = "02 Export"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate(
          "Purch. Special Scheme Code", VATPostingSetup."Purch. Special Scheme Code"::"02 Special System Activities");
        VATPostingSetup.Modify(true);

        // [GIVEN] Posted purchase credit memo with this VAT Posting Setup
        PostedDocNo := CreateAndPostPurchDocWithVATPostingSetup(PurchDocType::"Credit Memo", VATPostingSetup);
        LibraryVariableStorage.Enqueue(Format(VATPostingSetup."Purch. Special Scheme Code"::"01 General"));
        LibraryLowerPermissions.SetPurchDocsPost();

        // [GIVEN] Opened "Posted Purchase Cr. Memo - Update" page.
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", PostedDocNo);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Change "Special Scheme Code" to "01 General" and click OK
        // [THEN] Special Scheme Code is "01 General" in "SII Purchse Document Scheme Code"
        SIIPurchDocSchemeCode.Get(
          SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo",
          PostedDocNo, VATPostingSetup."Purch. Special Scheme Code"::"01 General");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServInvoiceUpdateSpecSchemeCodeOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateSpecialSchemeCodeTakenFromVATPostingSetupInPostedServInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        ServDocType: Enum "Service Document Type";
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 423069] Special Scheme updated for the posted service invoice with VAT Posting Setup with scheme code specified

        Initialize();

        // [GIVEN] VAT Posting Setup with "Special Scheme Code" = "02 Export"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"02 Export");
        VATPostingSetup.Modify(true);

        // [GIVEN] Posted service invoice with this VAT Posting Setup
        LibraryService.FindServiceInvoiceHeader(
          ServiceInvoiceHeader,
          CreateAndPostServiceDocWithVATPostingSetup(ServDocType::Invoice, VATPostingSetup));
        LibraryVariableStorage.Enqueue(Format(VATPostingSetup."Sales Special Scheme Code"::"01 General"));

        // [GIVEN] Opened "Posted Service Invoice - Update" page.
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Change "Special Scheme Code" to "01 General" and click OK
        // [THEN] Special Scheme Code is "01 General" in "SII Sales Document Scheme Code"
        SIISalesDocumentSchemeCode.Get(
          SIISalesDocumentSchemeCode."Entry Type"::Service, SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice",
          ServiceInvoiceHeader."No.", VATPostingSetup."Sales Special Scheme Code"::"01 General");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServCrMemoUpdateSpecSchemeCodeOKModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateSpecialSchemeCodeTakenFromVATPostingSetupInPostedServCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        ServDocType: Enum "Service Document Type";
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 423069] Special Scheme updated for the posted service credit memo with VAT Posting Setup with scheme code specified

        Initialize();

        // [GIVEN] VAT Posting Setup with "Special Scheme Code" = "02 Export"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"02 Export");
        VATPostingSetup.Modify(true);

        // [GIVEN] Posted service credit memo with this VAT Posting Setup
        LibraryService.FindServiceCrMemoHeader(
          ServiceCrMemoHeader,
          CreateAndPostServiceDocWithVATPostingSetup(ServDocType::"Credit Memo", VATPostingSetup));
        LibraryVariableStorage.Enqueue(Format(VATPostingSetup."Sales Special Scheme Code"::"01 General"));

        // [GIVEN] Opened "Posted Service Cr. Memo - Update" page.
        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", ServiceCrMemoHeader."No.");
        PostedServiceCreditMemo."Update Document".Invoke();

        // [WHEN] Change "Special Scheme Code" to "01 General" and click OK
        // [THEN] Special Scheme Code is "01 General" in "SII Sales Document Scheme Code"
        SIISalesDocumentSchemeCode.Get(
          SIISalesDocumentSchemeCode."Entry Type"::Service, SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo",
          ServiceCrMemoHeader."No.", VATPostingSetup."Sales Special Scheme Code"::"01 General");

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Edit Posted Documents ES");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Edit Posted Documents ES");

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Edit Posted Documents ES");
    end;

    local procedure CreateAndPostSalesInvoice() PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateAndPostSalesCreditMemo() PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateAndPostSalesCreditMemoForCustomer(CustNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, CustNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateAndPostPurchaseInvoice() PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndPostPurchaseCreditMemo() PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndPostPurchaseCreditMemoForVendor(VendNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseCreditMemoForVendorNo(PurchaseHeader, VendNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure CreateAndPostServiceInvoice() PostedDocNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        ServPostYesNo.PostDocument(ServiceHeader);
        LibraryService.FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        PostedDocNo := ServiceInvoiceHeader."No.";
    end;

    local procedure CreateAndPostServiceCreditMemo() PostedDocNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader."Posting No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        ServiceHeader.Modify();
        ServPostYesNo.PostDocument(ServiceHeader);
        LibraryService.FindServiceCrMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        PostedDocNo := ServiceCrMemoHeader."No.";
    end;

    local procedure CreateAndPostSalesDocWithVATPostingSetup(DocType: Enum "Sales Document Type"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchDocWithVATPostingSetup(DocType: Enum "Purchase Document Type"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostServiceDocWithVATPostingSetup(DocType: Enum "Service Document Type"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, LibrarySales.CreateCustomerNo());
        ServiceHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Bill-to Customer No.");
        ServiceItem.Validate("Response Time (Hours)", LibraryRandom.RandDecInRange(5, 10, 2));
        ServiceItem.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItem."Item No.", LibraryRandom.RandIntInRange(5, 10));
        ServiceLine.Validate("Service Item Line No.", 0);
        ServiceLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ServiceLine.Validate("Unit Price", LibraryRandom.RandIntInRange(3, 5));
        ServiceLine.Modify(true);

        ServicePostYesNo.PostDocument(ServiceHeader);
        exit(ServiceHeader."No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Invoice Type");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."ID Type");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Succeeded Company Name");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Succeeded VAT Registration No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Cr. Memo Type");
        LibraryVariableStorage.Enqueue(Format(SalesCrMemoHeader."Correction Type"::Difference));
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."ID Type");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Succeeded Company Name");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Succeeded VAT Registration No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Special Scheme Code");
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Cr. Memo Type");
        LibraryVariableStorage.Enqueue(Format(PurchCrMemoHdr."Correction Type"::Difference));
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."ID Type");
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Succeeded Company Name");
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Succeeded VAT Registration No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Country/Region Code");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Bill-to Country/Region Code");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Ship-to Country/Region Code");

        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Invoice Type");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."ID Type");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Succeeded Company Name");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Succeeded VAT Registration No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."Special Scheme Code");
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."Cr. Memo Type");
    end;

    local procedure PrepareValuesForEditableFieldsPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."Special Scheme Code" := "SII Sales Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        SalesInvoiceHeader."Invoice Type" := "SII Sales Invoice Type".FromInteger(LibraryRandom.RandIntInRange(1, 3));
        SalesInvoiceHeader."ID Type" := "SII ID Type".FromInteger(LibraryRandom.RandIntInRange(1, 5));
        SalesInvoiceHeader."Succeeded Company Name" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID();
    end;

    local procedure PrepareValuesForEditableFieldsPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."Special Scheme Code" := "SII Sales Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        SalesCrMemoHeader."Cr. Memo Type" := "SII Sales Credit Memo Type".FromInteger(LibraryRandom.RandIntInRange(1, 5));
        SalesCrMemoHeader."Correction Type" := SalesCrMemoHeader."Correction Type"::Removal;
        SalesCrMemoHeader."ID Type" := "SII ID Type".FromInteger(LibraryRandom.RandIntInRange(1, 3));
        SalesCrMemoHeader."Succeeded Company Name" := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." :=
          LibraryUtility.GenerateRandomCode(SalesInvoiceHeader.FieldNo("No."), DATABASE::"Sales Invoice Header");
        SalesInvoiceHeader.Insert();
        SalesCrMemoHeader."Corrected Invoice No." := SalesInvoiceHeader."No.";
    end;

    local procedure PrepareValuesForEditableFieldsPostedPurchaseCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."Special Scheme Code" := "SII Purch. Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        PurchCrMemoHdr."Cr. Memo Type" := "SII Purch. Credit Memo Type".FromInteger(LibraryRandom.RandIntInRange(1, 5));
        PurchCrMemoHdr."Correction Type" := PurchCrMemoHdr."Correction Type"::Removal;
        PurchCrMemoHdr."ID Type" := "SII ID Type".FromInteger(LibraryRandom.RandIntInRange(1, 3));
        PurchCrMemoHdr."Succeeded Company Name" := LibraryUtility.GenerateGUID();
        PurchCrMemoHdr."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID();
        PurchInvHeader.Init();
        PurchInvHeader."No." :=
          LibraryUtility.GenerateRandomCode(PurchInvHeader.FieldNo("No."), DATABASE::"Purch. Inv. Header");
        PurchInvHeader.Insert();
        PurchCrMemoHdr."Corrected Invoice No." := PurchInvHeader."No.";
    end;

    local procedure PrepareValuesForEditableFieldsPostedServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        CountryRegion: Record "Country/Region";
        BillToCountryRegion: Record "Country/Region";
        ShipToCountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryERM.CreateCountryRegion(BillToCountryRegion);
        LibraryERM.CreateCountryRegion(ShipToCountryRegion);

        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."Country/Region Code" := CountryRegion.Code;
        ServiceInvoiceHeader."Bill-to Country/Region Code" := BillToCountryRegion.Code;
        ServiceInvoiceHeader."Ship-to Country/Region Code" := ShipToCountryRegion.Code;

        ServiceInvoiceHeader."Special Scheme Code" := "SII Sales Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        ServiceInvoiceHeader."Invoice Type" := "SII Sales Invoice Type".FromInteger(LibraryRandom.RandIntInRange(1, 3));
        ServiceInvoiceHeader."ID Type" := "SII ID Type".FromInteger(LibraryRandom.RandIntInRange(1, 5));
        ServiceInvoiceHeader."Succeeded Company Name" := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Succeeded VAT Registration No." := LibraryUtility.GenerateGUID();
    end;

    local procedure PrepareValuesForEditableFieldsPostedServiceCreditMemo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."Special Scheme Code" := "SII Sales Special Scheme Code".FromInteger(LibraryRandom.RandIntInRange(1, 10));
        ServiceCrMemoHeader."Cr. Memo Type" := "SII Sales Credit Memo Type".FromInteger(LibraryRandom.RandIntInRange(1, 3));
    end;

    local procedure MockSIIDocUploadState(var SIIDocUploadState: Record "SII Doc. Upload State"; DocSource: Enum "SII Doc. Upload State Document Source"; DocType: Enum "SII Doc. Upload State Document Type"; PostingDate: Date; DocNo: Code[20])
    begin
        SIIDocUploadState.Init();
        SIIDocUploadState."Document Source" := DocSource;
        SIIDocUploadState."Document Type" := DocType;
        SIIDocUploadState."Posting Date" := PostingDate;
        SIIDocUploadState."Document No." := DocNo;
        SIIDocUploadState.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOKModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateCancelModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateInvDetailsOKModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Correction Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCorrInvNoOKModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Corrected Invoice No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateInvDetailsCancelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Correction Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCorrInvNoCancelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Corrected Invoice No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateOKModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Correction Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCorrInvNoOKModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Corrected Invoice No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCancelModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Correction Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCorrInvNoCancelModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Corrected Invoice No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOKModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate."Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());

        PostedServiceInvUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateCancelModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate."Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());

        PostedServiceInvUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Invoice Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."ID Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Succeeded Company Name".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Succeeded VAT Registration No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateOKModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateCancelModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate."Cr. Memo Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOperationDescrOKModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOperationDescrCancelModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOperationDescrOKModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOperationDescrCancelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateLookupCorrInvNolModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Corrected Invoice No.".Lookup();
        PstdSalesCrMemoUpdate."Corrected Invoice No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateOperationDescrOKModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateOperationDescrCancelModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateOperationDescrOKModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateOperationDescrCancelModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateLookupCorrInvNolModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Corrected Invoice No.".Lookup();
        PostedPurchCrMemoUpdate."Corrected Invoice No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOperationDescrOKModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOperationDescrCancelModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateOperationDescrOKModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoUpdateOperationDescrCancelModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate.OperationDescription.SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesCheckLookupValueModalPageHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    var
        InvNo: Text;
    begin
        InvNo := LibraryVariableStorage.PeekText(1);
        PostedSalesInvoices."No.".AssertEquals(InvNo);
        PostedSalesInvoices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicesCheckLookupValueModalPageHandler(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    var
        InvNo: Text;
    begin
        InvNo := LibraryVariableStorage.PeekText(1);
        PostedPurchaseInvoices."No.".AssertEquals(InvNo);
        PostedPurchaseInvoices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSpecSchemeCodeOKModalPageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateSpecSchemeCodeOKModalPageHandler(var PostedSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PostedSalesCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateSpecSchemeCodeOKModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateSpecSchemeCodeOKModalPageHandler(var PostedPurchCrMemoUpdate: TestPage "Posted Purch. Cr.Memo - Update")
    begin
        PostedPurchCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServInvoiceUpdateSpecSchemeCodeOKModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServCrMemoUpdateSpecSchemeCodeOKModalPageHandler(var PostedServCrMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PostedServCrMemoUpdate."Special Scheme Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServCrMemoUpdate.OK().Invoke();
    end;
}
