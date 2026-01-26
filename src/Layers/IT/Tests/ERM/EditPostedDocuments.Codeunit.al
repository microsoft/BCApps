codeunit 134658 "Edit Posted Documents"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = tabledata "Sales Cr.Memo Header" = imd,
                  tabledata "Sales Shipment Header" = m;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Update Document]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        UnexpectedQtyErr: Label 'Unexpected Quantity shown.';
        UnexpectedNetWeightErr: Label 'Unexpected Net Weight shown.';
        UnexpectedGrossWeightErr: Label 'Unexpected Gross Weight shown.';
        UnexpectedVolumeErr: Label 'Unexpected Volume shown.';
        CashFlowWorkSheetLineMustNotBeFoundErr: Label 'Cash Flow Worksheet Line must not be found.';

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentEditableFields()
    var
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] Editable and non-editable fields on page "Posted Sales Shipment - Update".
        Initialize();

        // [WHEN] Open "Posted Sales Shipment - Update" page.
        PostedSalesShipment.OpenView();
        PostedSalesShipment."Update Document".Invoke();

        // [THEN] Fields "No.", "Sell-to Customer Name", "Posting Date" are not editable.
        // [THEN] Fields "Shipping Agent Code", "Shipping Agent Service Code", "Package Tracking No." are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Sell-to Customer Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Shipping Agent Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Shipping Agent Service Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Package Tracking No. must be editable');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateSetValuesCancel()
    var
        SalesShptHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Sales Shipment - Update" modal page.
        Initialize();
        SalesShptHeader.Get(CreateAndPostSalesOrderGetShipmentNo());
        PrepareEnqueueValuesForEditableFieldsPostedSalesShipment(SalesShptHeader);

        // [GIVEN] Opened "Posted Sales Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedSalesShipment.OpenView();
        PostedSalesShipment.GoToRecord(SalesShptHeader);
        PostedSalesShipment."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Sales Invoice Header were not changed.
        Assert.AreNotEqual(SalesShptHeader."Shipping Agent Code", PostedSalesShipment."Shipping Agent Code".Value, SalesShptHeader.FieldCaption("Shipping Agent Code"));
        Assert.AreNotEqual(SalesShptHeader."Shipping Agent Service Code", PostedSalesShipment."Shipping Agent Service Code".Value, SalesShptHeader.FieldCaption("Shipping Agent Service Code"));
        Assert.AreNotEqual(SalesShptHeader."Package Tracking No.", PostedSalesShipment."Package Tracking No.".Value, SalesShptHeader.FieldCaption("Package Tracking No."));
        Assert.AreNotEqual(SalesShptHeader."Additional Information", PostedSalesShipment."Additional Information".Value, '');
        Assert.AreNotEqual(SalesShptHeader."Additional Notes", PostedSalesShipment."Additional Notes".Value, '');
        Assert.AreNotEqual(SalesShptHeader."Additional Instructions", PostedSalesShipment."Additional Instructions".Value, '');
        Assert.AreNotEqual(SalesShptHeader."TDD Prepared By", PostedSalesShipment."TDD Prepared By".Value, '');
        Assert.AreNotEqual(Format(SalesShptHeader."3rd Party Loader Type"), PostedSalesShipment."3rd Party Loader Type".Value, '');
        Assert.AreNotEqual(SalesShptHeader."3rd Party Loader No.", PostedSalesShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateSetValuesOK()
    var
        SalesShptHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Sales Shipment - Update" modal page.
        Initialize();
        SalesShptHeader.Get(CreateAndPostSalesOrderGetShipmentNo());
        PrepareEnqueueValuesForEditableFieldsPostedSalesShipment(SalesShptHeader);

        // [GIVEN] Opened "Posted Sales Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedSalesShipment.OpenView();
        PostedSalesShipment.GoToRecord(SalesShptHeader);
        PostedSalesShipment."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Sales Invoice Header were changed.
        Assert.AreEqual(SalesShptHeader."Shipping Agent Code", PostedSalesShipment."Shipping Agent Code".Value, SalesShptHeader.FieldCaption("Shipping Agent Code"));
        Assert.AreEqual(SalesShptHeader."Shipping Agent Service Code", PostedSalesShipment."Shipping Agent Service Code".Value, SalesShptHeader.FieldCaption("Shipping Agent Service Code"));
        Assert.AreEqual(SalesShptHeader."Package Tracking No.", PostedSalesShipment."Package Tracking No.".Value, SalesShptHeader.FieldCaption("Package Tracking No."));
        Assert.AreEqual(SalesShptHeader."Additional Information", PostedSalesShipment."Additional Information".Value, '');
        Assert.AreEqual(SalesShptHeader."Additional Notes", PostedSalesShipment."Additional Notes".Value, '');
        Assert.AreEqual(SalesShptHeader."Additional Instructions", PostedSalesShipment."Additional Instructions".Value, '');
        Assert.AreEqual(SalesShptHeader."TDD Prepared By", PostedSalesShipment."TDD Prepared By".Value, '');
        Assert.AreEqual(Format(SalesShptHeader."3rd Party Loader Type"), PostedSalesShipment."3rd Party Loader Type".Value, '');
        Assert.AreEqual(SalesShptHeader."3rd Party Loader No.", PostedSalesShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateEditableFields()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] Editable and non-editable fields on page "Posted Purch. Invoice - Update".
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [WHEN] Open "Posted Purch. Invoice - Update" page via PostedReturnShptUpdateGetEditablelModalPageHandler
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice."Update Document".Invoke();

        // [THEN] Fields "No.", "Buy-from Vendor Name", "Posting Date" are not editable.
        // [THEN] Fields "Payment Reference", "Payment Method Code", "Creditor No.", "Ship-to Code" are editable.
        // [THEN] Field "Posting Description" is editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Buy-from Vendor Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Payment Reference must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Payment Method Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Creditor No. must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Ship-to Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Posting Description must be editable');

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateSetValuesCancel()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvHeaderNew: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Purch. Invoice - Update" modal page.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        PurchInvHeader.Get(CreateAndPostPurchaseInvoiceWithSellToCustomer(LibrarySales.CreateCustomerNo()));
        PurchInvHeaderNew := PurchInvHeader;
        PrepareEnqueueValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeaderNew);

        // [GIVEN] Opened "Posted Purch. Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GoToRecord(PurchInvHeaderNew);
        PostedPurchaseInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page via PostedPurchInvoiceUpdateCancelModalPageHandler

        // [THEN] Values of these fields in Purch. Inv. Header were not changed to new values.
        PostedPurchaseInvoice.Close();
        PurchInvHeader.Get(PurchInvHeader."No.");
        Assert.AreNotEqual(PurchInvHeaderNew."Payment Reference", PurchInvHeader."Payment Reference", PurchInvHeader.FieldCaption("Payment Reference"));
        Assert.AreNotEqual(PurchInvHeaderNew."Payment Method Code", PurchInvHeader."Payment Method Code", PurchInvHeader.FieldCaption("Payment Method Code"));
        Assert.AreNotEqual(PurchInvHeaderNew."Creditor No.", PurchInvHeader."Creditor No.", PurchInvHeader.FieldCaption("Creditor No."));
        Assert.AreNotEqual(PurchInvHeaderNew."Posting Description", PurchInvHeader."Posting Description", PurchInvHeader.FieldCaption("Posting Description"));

        // [THEN] Values at the associated vendor ledger entry were not changed
        VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.");
        Assert.AreEqual(PurchInvHeader."Payment Reference", VendorLedgerEntry."Payment Reference", PurchInvHeader.FieldCaption("Payment Reference"));
        Assert.AreEqual(PurchInvHeader."Payment Method Code", VendorLedgerEntry."Payment Method Code", PurchInvHeader.FieldCaption("Payment Method Code"));
        Assert.AreEqual(PurchInvHeader."Creditor No.", VendorLedgerEntry."Creditor No.", PurchInvHeader.FieldCaption("Creditor No."));
        Assert.AreEqual(PurchInvHeader."Posting Description", VendorLedgerEntry.Description, PurchInvHeader.FieldCaption("Posting Description"));

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateSetValuesOK()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvHeaderNew: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Purch. Invoice - Update" modal page.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        PurchInvHeader.Get(CreateAndPostPurchaseInvoiceWithSellToCustomer(LibrarySales.CreateCustomerNo()));
        PurchInvHeaderNew := PurchInvHeader;
        PrepareEnqueueValuesForEditableFieldsPostedPurchaseInvoice(PurchInvHeaderNew);

        // [GIVEN] Opened "Posted Purch. Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GoToRecord(PurchInvHeaderNew);
        PostedPurchaseInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page via PostedPurchInvoiceUpdateOKModalPageHandler

        // [THEN] Values of these fields in Purch. Inv. Header were changed to new values.
        Assert.AreEqual(PurchInvHeaderNew."Payment Reference", PostedPurchaseInvoice."Payment Reference".Value, PurchInvHeaderNew.FieldCaption("Payment Reference"));
        Assert.AreEqual(PurchInvHeaderNew."Creditor No.", PostedPurchaseInvoice."Creditor No.".Value, PurchInvHeaderNew.FieldCaption("Creditor No."));
        Assert.AreEqual(PurchInvHeaderNew."Ship-to Code", PostedPurchaseInvoice."Ship-to Code".Value, PurchInvHeaderNew.FieldCaption("Posting Description"));

        PostedPurchaseInvoice.Close();
        PurchInvHeader.Get(PurchInvHeader."No.");
        PurchInvHeader.TestField("Payment Reference", PurchInvHeaderNew."Payment Reference");
        PurchInvHeader.TestField("Payment Method Code", PurchInvHeaderNew."Payment Method Code");
        PurchInvHeader.TestField("Creditor No.", PurchInvHeaderNew."Creditor No.");
        PurchInvHeader.TestField("Ship-to Code", PurchInvHeaderNew."Ship-to Code");
        PurchInvHeader.TestField("Posting Description", PurchInvHeaderNew."Posting Description");

        // [THEN] Values at the associated vendor ledger entry were changed
        VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.");
        Assert.AreEqual(PurchInvHeaderNew."Payment Reference", VendorLedgerEntry."Payment Reference", PurchInvHeaderNew.FieldCaption("Payment Reference"));
        Assert.AreEqual(PurchInvHeaderNew."Payment Method Code", VendorLedgerEntry."Payment Method Code", PurchInvHeaderNew.FieldCaption("Payment Method Code"));
        Assert.AreEqual(PurchInvHeaderNew."Creditor No.", VendorLedgerEntry."Creditor No.", PurchInvHeaderNew.FieldCaption("Creditor No."));
        Assert.AreEqual(PurchInvHeaderNew."Posting Description", VendorLedgerEntry.Description, PurchInvHeaderNew.FieldCaption("Posting Description"));

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateEditableFields()
    var
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase Credit memo]
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [WHEN] Open "Pstd. Purch. Cr.Memo - Update" page via PostedPurchCrMemoUpdateGetEditablelModalPageHandler
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [THEN] Fields "No.", "Buy-from Vendor Name", "Posting Date" are not editable.
        // [THEN] Field "Posting Description" is editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Buy-from Vendor Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Posting Description must be editable');

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateSetValuesCancel()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoHdrNew: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase Credit memo]
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        PurchCrMemoHdr.Get(CreateAndPostPurchaseCreditMemo());
        PurchCrMemoHdrNew := PurchCrMemoHdr;
        PrepareEnqueueValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdrNew);

        // [GIVEN] Opened "Pstd. Purch. Cr.Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GoToRecord(PurchCrMemoHdrNew);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page via PostedPurchCrMemoUpdateCancelModalPageHandler

        // [THEN] Values of these fields in Purch. Cr. Memo Header were not changed to new values.
        PostedPurchaseCreditMemo.Close();
        PurchCrMemoHdr.Get(PurchCrMemoHdr."No.");
        Assert.AreNotEqual(PurchCrMemoHdrNew."Posting Description", PurchCrMemoHdr."Posting Description", PurchCrMemoHdr.FieldCaption("Posting Description"));

        // [THEN] Values at the associated vendor ledger entry were not changed
        VendorLedgerEntry.Get(PurchCrMemoHdr."Vendor Ledger Entry No.");
        Assert.AreEqual(PurchCrMemoHdr."Posting Description", VendorLedgerEntry.Description, PurchCrMemoHdr.FieldCaption("Posting Description"));

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedPurchCrMemoUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateSetValuesOK()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoHdrNew: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase Credit memo]
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        PurchCrMemoHdr.Get(CreateAndPostPurchaseCreditMemo());
        PurchCrMemoHdrNew := PurchCrMemoHdr;
        PrepareEnqueueValuesForEditableFieldsPostedPurchaseCreditMemo(PurchCrMemoHdrNew);

        // [GIVEN] Opened "Pstd. Purch. Cr.Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GoToRecord(PurchCrMemoHdrNew);
        PostedPurchaseCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page via PostedPurchCrMemoUpdateOKModalPageHandler

        // [THEN] Values of these fields in Purch. Cr. Memo Header were changed to new values.
        PostedPurchaseCreditMemo.Close();
        PurchCrMemoHdr.Get(PurchCrMemoHdr."No.");
        PurchCrMemoHdr.TestField("Posting Description", PurchCrMemoHdrNew."Posting Description");

        // [THEN] Values at the associated vendor ledger entry were changed
        VendorLedgerEntry.Get(PurchCrMemoHdr."Vendor Ledger Entry No.");
        Assert.AreEqual(PurchCrMemoHdrNew."Posting Description", VendorLedgerEntry.Description, PurchCrMemoHdrNew.FieldCaption("Posting Description"));

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedReturnShptUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateEditableFields()
    var
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 308913] Editable and non-editable fields on page "Posted Return Shpt. - Update".
        Initialize();

        // [WHEN] Open "Posted Return Shpt. - Update" page.
        PostedReturnShipment.OpenView();
        PostedReturnShipment."Update Document".Invoke();

        // [THEN] Fields "No.", "Buy-from Vendor Name", "Posting Date" are not editable.
        // [THEN] Fields "Ship-to County", "Ship-to Country/Region Code" are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Buy-from Vendor Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Ship-to County must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Ship-to Country/Region Code must be editable');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedReturnShptUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateSetValuesCancel()
    var
        ReturnShptHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Return Shpt. - Update" modal page.
        Initialize();
        ReturnShptHeader.Get(CreateAndPostPurchaseReturnOrderGetReturnShipmentNo());
        PrepareEnqueueValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader);

        // [GIVEN] Opened "Posted Return Shpt. - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedReturnShipment.OpenView();
        PostedReturnShipment.GoToRecord(ReturnShptHeader);
        PostedReturnShipment."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Return Shipment Header were not changed.
        Assert.AreNotEqual(ReturnShptHeader."Ship-to County", PostedReturnShipment."Ship-to County".Value, ReturnShptHeader.FieldCaption("Ship-to County"));
        Assert.AreNotEqual(ReturnShptHeader."Ship-to Country/Region Code", PostedReturnShipment."Ship-to Country/Region Code".Value, ReturnShptHeader.FieldCaption("Ship-to Country/Region Code"));
        Assert.AreNotEqual(ReturnShptHeader."Additional Information", PostedReturnShipment."Additional Information".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."Additional Notes", PostedReturnShipment."Additional Notes".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."Additional Instructions", PostedReturnShipment."Additional Instructions".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."TDD Prepared By", PostedReturnShipment."TDD Prepared By".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."Shipment Method Code", PostedReturnShipment."Shipment Method Code".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."Shipping Agent Code", PostedReturnShipment."Shipping Agent Code".Value, '');
        Assert.AreNotEqual(Format(ReturnShptHeader."3rd Party Loader Type"), PostedReturnShipment."3rd Party Loader Type".Value, '');
        Assert.AreNotEqual(ReturnShptHeader."3rd Party Loader No.", PostedReturnShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedReturnShptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateSetValuesOK()
    var
        ReturnShptHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Return Shpt. - Update" modal page.
        Initialize();
        ReturnShptHeader.Get(CreateAndPostPurchaseReturnOrderGetReturnShipmentNo());
        PrepareEnqueueValuesForEditableFieldsPostedReturnShipment(ReturnShptHeader);

        // [GIVEN] Opened "Posted Return Shpt. - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedReturnShipment.OpenView();
        PostedReturnShipment.GoToRecord(ReturnShptHeader);
        PostedReturnShipment."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Return Shipment Header were changed.
        Assert.AreEqual(ReturnShptHeader."Ship-to County", PostedReturnShipment."Ship-to County".Value, ReturnShptHeader.FieldCaption("Ship-to County"));
        Assert.AreEqual(ReturnShptHeader."Ship-to Country/Region Code", PostedReturnShipment."Ship-to Country/Region Code".Value, ReturnShptHeader.FieldCaption("Ship-to Country/Region Code"));
        Assert.AreEqual(ReturnShptHeader."Additional Information", PostedReturnShipment."Additional Information".Value, '');
        Assert.AreEqual(ReturnShptHeader."Additional Notes", PostedReturnShipment."Additional Notes".Value, '');
        Assert.AreEqual(ReturnShptHeader."Additional Instructions", PostedReturnShipment."Additional Instructions".Value, '');
        Assert.AreEqual(ReturnShptHeader."TDD Prepared By", PostedReturnShipment."TDD Prepared By".Value, '');
        Assert.AreEqual(ReturnShptHeader."Shipment Method Code", PostedReturnShipment."Shipment Method Code".Value, '');
        Assert.AreEqual(ReturnShptHeader."Shipping Agent Code", PostedReturnShipment."Shipping Agent Code".Value, '');
        Assert.AreEqual(Format(ReturnShptHeader."3rd Party Loader Type"), PostedReturnShipment."3rd Party Loader Type".Value, '');
        Assert.AreEqual(ReturnShptHeader."3rd Party Loader No.", PostedReturnShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateEditableFields()
    var
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] Editable and non-editable fields on page "Posted Return Receipt - Update".
        Initialize();

        // [WHEN] Open "Posted Return Receipt - Update" page.
        PostedReturnReceipt.OpenView();
        PostedReturnReceipt."Update Document".Invoke();

        // [THEN] Fields "No.", "Sell-to Customer Name", "Posting Date" are not editable.
        // [THEN] Fields "Bill-to County", "Bill-to Country/Region Code", "Shipping Agent Code", "Package Tracking No." are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Sell-to Customer Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Bill-to County must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Bill-to Country/Region Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Shipping Agent Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Package Tracking No. must be editable');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateSetValuesCancel()
    var
        ReturnRcptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Return Receipt - Update" modal page.
        Initialize();
        ReturnRcptHeader.Get(CreateAndPostSalesReturnOrderGetReturnReceiptNo());
        PrepareEnqueueValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader);

        // [GIVEN] Opened "Posted Return Receipt - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.GoToRecord(ReturnRcptHeader);
        PostedReturnReceipt."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Return Receipt Header were not changed.
        Assert.AreNotEqual(ReturnRcptHeader."Bill-to County", PostedReturnReceipt."Bill-to County".Value, ReturnRcptHeader.FieldCaption("Bill-to County"));
        Assert.AreNotEqual(ReturnRcptHeader."Bill-to Country/Region Code", PostedReturnReceipt."Bill-to Country/Region Code".Value, ReturnRcptHeader.FieldCaption("Bill-to Country/Region Code"));
        Assert.AreNotEqual(ReturnRcptHeader."Shipping Agent Code", PostedReturnReceipt."Shipping Agent Code".Value, ReturnRcptHeader.FieldCaption("Shipping Agent Code"));
        Assert.AreNotEqual(ReturnRcptHeader."Package Tracking No.", PostedReturnReceipt."Package Tracking No.".Value, ReturnRcptHeader.FieldCaption("Package Tracking No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateSetValuesOK()
    var
        ReturnRcptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Return Receipt - Update" modal page.
        Initialize();
        ReturnRcptHeader.Get(CreateAndPostSalesReturnOrderGetReturnReceiptNo());
        PrepareEnqueueValuesForEditableFieldsPostedReturnReceipt(ReturnRcptHeader);

        // [GIVEN] Opened "Posted Return Receipt - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.GoToRecord(ReturnRcptHeader);
        PostedReturnReceipt."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Return Receipt Header were changed.
        Assert.AreEqual(ReturnRcptHeader."Bill-to County", PostedReturnReceipt."Bill-to County".Value, ReturnRcptHeader.FieldCaption("Bill-to County"));
        Assert.AreEqual(ReturnRcptHeader."Bill-to Country/Region Code", PostedReturnReceipt."Bill-to Country/Region Code".Value, ReturnRcptHeader.FieldCaption("Bill-to Country/Region Code"));
        Assert.AreEqual(ReturnRcptHeader."Shipping Agent Code", PostedReturnReceipt."Shipping Agent Code".Value, ReturnRcptHeader.FieldCaption("Shipping Agent Code"));
        Assert.AreEqual(ReturnRcptHeader."Package Tracking No.", PostedReturnReceipt."Package Tracking No.".Value, ReturnRcptHeader.FieldCaption("Package Tracking No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedTransferShipmentUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentUpdateSetValuesCancel()
    var
        TransferShptHeader: Record "Transfer Shipment Header";
        PostedTransferShipment: TestPage "Posted Transfer Shipment";
    begin
        // [FEATURE] [Transfer Shipment]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Transfer Shipment - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedTransferShipment(TransferShptHeader);

        // [GIVEN] Opened "Posted Transfer Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedTransferShipment(TransferShptHeader);
        PostedTransferShipment.OpenView();
        PostedTransferShipment."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Transfer Shipment Header were not changed.
        Assert.AreNotEqual(TransferShptHeader."Transport Reason Code", PostedTransferShipment."Transport Reason Code".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Goods Appearance", PostedTransferShipment."Goods Appearance".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Gross Weight", PostedTransferShipment."Gross Weight".AsDecimal(), '');
        Assert.AreNotEqual(TransferShptHeader."Net Weight", PostedTransferShipment."Net Weight".AsDecimal(), '');
        Assert.AreNotEqual(TransferShptHeader."Parcel Units", PostedTransferShipment."Parcel Units".AsDecimal(), '');
        Assert.AreNotEqual(TransferShptHeader.Volume, PostedTransferShipment.Volume.AsDecimal(), '');
        Assert.AreNotEqual(TransferShptHeader."Shipping Notes", PostedTransferShipment."Shipping Notes".Value, '');
        Assert.AreNotEqual(Format(TransferShptHeader."3rd Party Loader Type"), PostedTransferShipment."3rd Party Loader Type".Value, '');
        Assert.AreNotEqual(TransferShptHeader."3rd Party Loader No.", PostedTransferShipment."3rd Party Loader No.".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Shipping Starting Date", PostedTransferShipment."Shipping Starting Date".AsDate(), '');
        Assert.AreNotEqual(TransferShptHeader."Shipping Starting Time", PostedTransferShipment."Shipping Starting Time".AsTime(), '');
        Assert.AreNotEqual(TransferShptHeader."Package Tracking No.", PostedTransferShipment."Package Tracking No.".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Additional Information", PostedTransferShipment."Additional Information".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Additional Notes", PostedTransferShipment."Additional Notes".Value, '');
        Assert.AreNotEqual(TransferShptHeader."Additional Instructions", PostedTransferShipment."Additional Instructions".Value, '');
        Assert.AreNotEqual(TransferShptHeader."TDD Prepared By", PostedTransferShipment."TDD Prepared By".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedTransferShipmentUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentUpdateSetValuesOK()
    var
        TransferShptHeader: Record "Transfer Shipment Header";
        PostedTransferShipment: TestPage "Posted Transfer Shipment";
    begin
        // [FEATURE] [Transfer Shipment]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Transfer Shipment - Update" modal page.
        Initialize();
        PrepareValuesForEditableFieldsPostedTransferShipment(TransferShptHeader);

        // [GIVEN] Opened "Posted Transfer Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedTransferShipment(TransferShptHeader);
        PostedTransferShipment.OpenView();
        PostedTransferShipment."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Transfer Shipment Header were changed.
        Assert.AreEqual(TransferShptHeader."Transport Reason Code", PostedTransferShipment."Transport Reason Code".Value, '');
        Assert.AreEqual(TransferShptHeader."Goods Appearance", PostedTransferShipment."Goods Appearance".Value, '');
        Assert.AreEqual(TransferShptHeader."Gross Weight", PostedTransferShipment."Gross Weight".AsDecimal(), '');
        Assert.AreEqual(TransferShptHeader."Net Weight", PostedTransferShipment."Net Weight".AsDecimal(), '');
        Assert.AreEqual(TransferShptHeader."Parcel Units", PostedTransferShipment."Parcel Units".AsDecimal(), '');
        Assert.AreEqual(TransferShptHeader.Volume, PostedTransferShipment.Volume.AsDecimal(), '');
        Assert.AreEqual(TransferShptHeader."Shipping Notes", PostedTransferShipment."Shipping Notes".Value, '');
        Assert.AreEqual(Format(TransferShptHeader."3rd Party Loader Type"), PostedTransferShipment."3rd Party Loader Type".Value, '');
        Assert.AreEqual(TransferShptHeader."3rd Party Loader No.", PostedTransferShipment."3rd Party Loader No.".Value, '');
        Assert.AreEqual(TransferShptHeader."Shipping Starting Date", PostedTransferShipment."Shipping Starting Date".AsDate(), '');
        Assert.AreEqual(TransferShptHeader."Shipping Starting Time", PostedTransferShipment."Shipping Starting Time".AsTime(), '');
        Assert.AreEqual(TransferShptHeader."Package Tracking No.", PostedTransferShipment."Package Tracking No.".Value, '');
        Assert.AreEqual(TransferShptHeader."Additional Information", PostedTransferShipment."Additional Information".Value, '');
        Assert.AreEqual(TransferShptHeader."Additional Notes", PostedTransferShipment."Additional Notes".Value, '');
        Assert.AreEqual(TransferShptHeader."Additional Instructions", PostedTransferShipment."Additional Instructions".Value, '');
        Assert.AreEqual(TransferShptHeader."TDD Prepared By", PostedTransferShipment."TDD Prepared By".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceShipmentUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentUpdateSetValuesCancel()
    var
        ServiceShptHeader: Record "Service Shipment Header";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        OrderNo: Code[20];
    begin
        // [FEATURE] [Service Shipment]
        // [SCENARIO 308913] New values for editable fields are not set in case Stan presses Cancel on "Posted Service Shipment - Update" modal page.
        Initialize();
        OrderNo := CreateAndPostServiceOrder();
        PrepareValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader);

        // [GIVEN] Opened "Posted Service Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader);
        PostedServiceShipment.OpenView();
        PostedServiceShipment.FILTER.SetFilter("Order No.", OrderNo);
        PostedServiceShipment."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Service Shipment Header were not changed.
        Assert.AreNotEqual(ServiceShptHeader."Additional Information", PostedServiceShipment."Additional Information".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."Additional Notes", PostedServiceShipment."Additional Notes".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."Additional Instructions", PostedServiceShipment."Additional Instructions".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."TDD Prepared By", PostedServiceShipment."TDD Prepared By".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."Shipment Method Code", PostedServiceShipment."Shipment Method Code".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."Shipping Agent Code", PostedServiceShipment."Shipping Agent Code".Value, '');
        Assert.AreNotEqual(Format(ServiceShptHeader."3rd Party Loader Type"), PostedServiceShipment."3rd Party Loader Type".Value, '');
        Assert.AreNotEqual(ServiceShptHeader."3rd Party Loader No.", PostedServiceShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceShipmentUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentUpdateSetValuesOK()
    var
        ServiceShptHeader: Record "Service Shipment Header";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        OrderNo: Code[20];
    begin
        // [FEATURE] [Service Shipment]
        // [SCENARIO 308913] New values for editable fields are set in case Stan presses OK on "Posted Service Shipment - Update" modal page.
        Initialize();
        OrderNo := CreateAndPostServiceOrder();
        PrepareValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader);

        // [GIVEN] Opened "Posted Service Shipment - Update" page.
        // [GIVEN] New values are set for editable fields.
        EnqueValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader);
        PostedServiceShipment.OpenView();
        PostedServiceShipment.FILTER.SetFilter("Order No.", OrderNo);
        PostedServiceShipment."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Service Shipment Header were changed.
        Assert.AreEqual(ServiceShptHeader."Additional Information", PostedServiceShipment."Additional Information".Value, '');
        Assert.AreEqual(ServiceShptHeader."Additional Notes", PostedServiceShipment."Additional Notes".Value, '');
        Assert.AreEqual(ServiceShptHeader."Additional Instructions", PostedServiceShipment."Additional Instructions".Value, '');
        Assert.AreEqual(ServiceShptHeader."TDD Prepared By", PostedServiceShipment."TDD Prepared By".Value, '');
        Assert.AreEqual(ServiceShptHeader."Shipment Method Code", PostedServiceShipment."Shipment Method Code".Value, '');
        Assert.AreEqual(ServiceShptHeader."Shipping Agent Code", PostedServiceShipment."Shipping Agent Code".Value, '');
        Assert.AreEqual(Format(ServiceShptHeader."3rd Party Loader Type"), PostedServiceShipment."3rd Party Loader Type".Value, '');
        Assert.AreEqual(ServiceShptHeader."3rd Party Loader No.", PostedServiceShipment."3rd Party Loader No.".Value, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoEditableFields()
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 328798] Editable and non-editable fields on page "Posted Sales Credit Memo - Update".
        Initialize();

        // [WHEN] Open "Posted Sales Credit Memo - Update" page.
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo."Update Document".Invoke();

        // [THEN] Fields "No.", "Sell-to Customer Name", "Posting Date" are not editable.
        // [THEN] Fields "Shipping Agent Code", "Shipping Agent Service Code", "Package Tracking No." are editable.
        // [THEN] Field "Posting Description" is editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Sell-to Customer Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Shipping Agent Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Shipping Agent Service Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Package Tracking No. must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Posting Description must be editable');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoUpdateSetValuesCancel()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SavedSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 328798] New values for editable fields are not set in case Stan presses Cancel on "Posted Sales Credit Memo - Update" modal page.
        Initialize();
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());
        SavedSalesCrMemoHeader := SalesCrMemoHeader;
        PrepareEnqueueValuesForEditableFieldsPostedSalesCrMemo(SalesCrMemoHeader);

        // [GIVEN] Opened "Posted Sales Credit Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GoToRecord(SalesCrMemoHeader);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press Cancel on the page.

        // [THEN] Values of these fields in Sales Credit Memo Header were not changed.
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.TestField("Shipping Agent Code", SavedSalesCrMemoHeader."Shipping Agent Code");
        SalesCrMemoHeader.TestField("Shipping Agent Service Code", SavedSalesCrMemoHeader."Shipping Agent Service Code");
        SalesCrMemoHeader.TestField("Package Tracking No.", SavedSalesCrMemoHeader."Package Tracking No.");
        SalesCrMemoHeader.TestField("Posting Description", SavedSalesCrMemoHeader."Posting Description");

        // [THEN] Values at the associated customer ledger entry were not changed
        CustLedgerEntry.Get(SalesCrMemoHeader."Cust. Ledger Entry No.");
        Assert.AreEqual(SalesCrMemoHeader."Posting Description", CustLedgerEntry.Description, SalesCrMemoHeader.FieldCaption("Posting Description"));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesCrMemoUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoUpdateSetValuesOK()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 328798] New values for editable fields are set in case Stan presses OK on "Posted Sales Credit Memo - Update" modal page.
        Initialize();

        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());
        NewSalesCrMemoHeader := SalesCrMemoHeader;
        PrepareEnqueueValuesForEditableFieldsPostedSalesCrMemo(NewSalesCrMemoHeader);

        // [GIVEN] Opened "Posted Sales Credit Memo - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GoToRecord(NewSalesCrMemoHeader);
        PostedSalesCreditMemo."Update Document".Invoke();

        // [WHEN] Press OK on the page.

        // [THEN] Values of these fields in Sales Credit Memo Header were changed.
        PostedSalesCreditMemo.Close();
        SalesCrMemoHeader.Get(SalesCrMemoHeader."No.");
        SalesCrMemoHeader.TestField("Shipping Agent Code", NewSalesCrMemoHeader."Shipping Agent Code");
        SalesCrMemoHeader.TestField("Shipping Agent Service Code", NewSalesCrMemoHeader."Shipping Agent Service Code");
        SalesCrMemoHeader.TestField("Package Tracking No.", NewSalesCrMemoHeader."Package Tracking No.");
        SalesCrMemoHeader.TestField("Posting Description", NewSalesCrMemoHeader."Posting Description");

        // [THEN] Values at the associated customer ledger entry were changed
        CustLedgerEntry.Get(SalesCrMemoHeader."Cust. Ledger Entry No.");
        Assert.AreEqual(NewSalesCrMemoHeader."Posting Description", CustLedgerEntry.Description, SalesCrMemoHeader.FieldCaption("Posting Description"));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPostedReturnReceiptStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
        ReturnReceiptStatistics: TestPage "Return Receipt Statistics";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 433838] The Return Receipt Statistics are reported in the Posted Return Receipt document.
        Initialize();

        // [GIVEN] Create and post sales return order.
        LibrarySales.CreateSalesDocumentWithItem(
                    SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
                    LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Click on statistics from opened "Posted Return Receipt" page.
        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.Filter.SetFilter("No.", DocumentNo);
        ReturnReceiptStatistics.Trap();
        PostedReturnReceipt.Statistics.Invoke();

        // [THEN] Verify data available on "Return Receipt Statistics" page
        Assert.AreEqual(ReturnReceiptStatistics.LineQty.AsDecimal(), SalesLine.Quantity, UnexpectedQtyErr);
        Assert.AreEqual(ReturnReceiptStatistics.TotalNetWeight.AsDecimal(), SalesLine.Quantity * SalesLine."Net Weight", UnexpectedNetWeightErr);
        Assert.AreEqual(ReturnReceiptStatistics.TotalGrossWeight.AsDecimal(), SalesLine.Quantity * SalesLine."Gross Weight", UnexpectedGrossWeightErr);
        Assert.AreEqual(ReturnReceiptStatistics.TotalVolume.AsDecimal(), SalesLine.Quantity * SalesLine."Unit Volume", UnexpectedVolumeErr);
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesReqPageHandler,ConfirmHandlerTrue')]
    procedure CashFlowWorkSheetLineIsNotCreatedForPOIfPrepmtAndInvAreCompletelyPosted()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        PurchaseInvoice: TestPage "Purchase Invoice";
        CashFlowWorksheet: TestPage "Cash Flow Worksheet";
    begin
        // [SCENARIO 544391] When Stan runs Suggest Worksheet Lines action from Cash Flow Worksheet page
        // Then Cash Flow Worksheet Line is not created for a Purchase Order if Prepayment
        // And Purchase Invoice are completely posted.
        Initialize();

        // [GIVEN] Create a General Posting Setup and Validate Purch. Prepayments Account and Direct Cost Applied Account.
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Prepayments Account", GeneralPostingSetup."Inventory Adjmt. Account");
        GeneralPostingSetup.Validate("Direct Cost Applied Account", GeneralPostingSetup."COGS Account");
        GeneralPostingSetup.Modify(true);

        // [GIVEN] Create a VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup,
            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
            0);

        // [GIVEN] Validate Purch. Prepayments Account in VAT Posting Setup. // IT
        VATPostingSetup.Validate("Purch. Prepayments Account", GeneralPostingSetup."Purch. Prepayments Account");
        VATPostingSetup.Modify(true);

        // [GIVEN] Validate Gen. and VAT Posting Groups in Purch. Prepayments Account.
        ValidateGenAndVATPostingGrpsInPurchPrepymtAcc(GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create an Item and Validate Gen. Prod. Posting Group and VAT Prod. Posting Group.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Create a Vendor and Validate Gen. Bus. Posting Group and VAT Bus. Posting Group.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        // [GIVEN] Create a Purchase Header and Validate Prepayment % and Prepayment Due Date.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order, Vendor."No.");
        PurchaseHeader[1].Validate("Prepayment %", LibraryRandom.RandIntInRange(20, 20));
        PurchaseHeader[1].Validate("Prepayment Due Date", WorkDate());
        PurchaseHeader[1].Modify(true);

        // [GIVEN] Create a Purchase Line and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader[1], PurchaseLine[1].Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10));
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine[1].Modify(true);

        // [GIVEN] Valdiate Check Total in Purchase Header. // IT
        PurchaseHeader[1].CalcFields("Amount Including VAT");
        PurchaseHeader[1].Validate("Check Total", Round(PurchaseLine[1]."Amount Including VAT" * PurchaseLine[1]."Prepayment %" / 100));
        PurchaseHeader[1].Modify(true);

        // [GIVEN] Post Purchase Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader[1]);

        // [GIVEN] Post Purchase Receipt.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        // [GIVEN] Create another Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Get Receipt Lines.
        GetReceiptLines(PurchaseHeader[1], PurchaseHeader[2]);

        // [GIVEN] Validate Check Total in Purchase Header. // IT
        PurchaseHeader[1].Validate("Check Total", Round(PurchaseLine[1]."Amount Including VAT" * PurchaseLine[1]."Prepayment %" / 100));
        PurchaseHeader[1].Modify(true);

        // [GIVEN] Open Purchase Invoice page and run Post action.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader[2]);
        PurchaseInvoice."Check Total".SetValue(PurchaseLine[1].Amount - PurchaseHeader[1]."Check Total");
        PurchaseInvoice.Post.Invoke();

        // [GIVEN] Create a Cash Flow Forecast.
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // [GIVEN] Open Cash Flow Journal page and run Suggest Worksheet Lines action.
        LibraryVariableStorage.Enqueue(CashFlowForecast."No.");
        CashFlowWorksheet.OpenEdit();
        CashFlowWorksheet.SuggestWorksheetLines.Invoke();
        CashFlowWorksheet.Close();

        // [WHEN] Find Cash Flow Worksheet Line.
        CashFlowWorksheetLine.SetRange("Source No.", PurchaseHeader[1]."No.");

        // [THEN] Cash Flow Worksheet Line is not found.
        Assert.IsTrue(CashFlowWorksheetLine.IsEmpty(), CashFlowWorkSheetLineMustNotBeFoundErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Edit Posted Documents");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Edit Posted Documents");

        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Edit Posted Documents");
    end;

    local procedure CreateAndPostPurchaseInvoiceWithSellToCustomer(CustomerNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Sell-to Customer No.", CustomerNo);
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseCreditMemo(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrderGetShipmentNo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndPostSalesCreditMemo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndPostSalesReturnOrderGetReturnReceiptNo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
            LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndPostPurchaseReturnOrderGetReturnShipmentNo(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreateAndPostServiceOrder() OrderNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Modify(true);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        OrderNo := ServiceHeader."No.";
    end;

    local procedure CreateShipmentMethodWith3rdPartyLoader(var ShipmentMethod: Record "Shipment Method")
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateGUID();
        ShipmentMethod."3rd-Party Loader" := true;
        ShipmentMethod.Insert();
    end;

    local procedure CreateTransportReasonCode(var TransportReasonCode: Record "Transport Reason Code")
    begin
        TransportReasonCode.Init();
        TransportReasonCode.Code := LibraryUtility.GenerateGUID();
        TransportReasonCode.Insert();
    end;

    local procedure CreateGoodsAppearance(var GoodsAppearance: Record "Goods Appearance")
    begin
        GoodsAppearance.Init();
        GoodsAppearance.Code := LibraryUtility.GenerateGUID();
        GoodsAppearance.Insert();
    end;

    local procedure PrepareEnqueueValuesForEditableFieldsPostedSalesShipment(var SalesShptHeader: Record "Sales Shipment Header")
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShipmentMethod: Record "Shipment Method";
        DateFormula: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent."Shipping Agent Type" := ShippingAgent."Shipping Agent Type"::Vendor;
        ShippingAgent."Shipping Agent No." := LibraryPurchase.CreateVendorNo();
        ShippingAgent.Modify();

        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);
        CreateShipmentMethodWith3rdPartyLoader(ShipmentMethod);
        SalesShptHeader.FindFirst();
        SalesShptHeader."Shipment Method Code" := ShipmentMethod.Code;
        SalesShptHeader.Modify();
        SalesShptHeader."Shipping Agent Code" := ShippingAgent.Code;
        SalesShptHeader."Shipping Agent Service Code" := ShippingAgentServices.Code;
        SalesShptHeader."Package Tracking No." := LibraryUtility.GenerateGUID();
        SalesShptHeader."Additional Information" := LibraryUtility.GenerateGUID();
        SalesShptHeader."Additional Notes" := LibraryUtility.GenerateGUID();
        SalesShptHeader."Additional Instructions" := LibraryUtility.GenerateGUID();
        SalesShptHeader."TDD Prepared By" := LibraryUtility.GenerateGUID();
        SalesShptHeader."3rd Party Loader Type" := SalesShptHeader."3rd Party Loader Type"::Vendor;
        SalesShptHeader."3rd Party Loader No." := LibraryPurchase.CreateVendorNo();

        LibraryVariableStorage.Enqueue(SalesShptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Shipping Agent Service Code");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Package Tracking No.");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Additional Information");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Additional Notes");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Additional Instructions");
        LibraryVariableStorage.Enqueue(SalesShptHeader."TDD Prepared By");
        LibraryVariableStorage.Enqueue(SalesShptHeader."3rd Party Loader Type");
        LibraryVariableStorage.Enqueue(SalesShptHeader."3rd Party Loader No.");
    end;

    local procedure PrepareEnqueueValuesForEditableFieldsPostedSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        DateFormula: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);
        SalesCrMemoHeader."Shipping Agent Code" := ShippingAgent.Code;
        SalesCrMemoHeader."Shipping Agent Service Code" := ShippingAgentServices.Code;
        SalesCrMemoHeader."Package Tracking No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader."Posting Description" := LibraryRandom.RandText(25);

        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Shipping Agent Service Code");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Package Tracking No.");
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."Posting Description");
    end;

    local procedure PrepareEnqueueValuesForEditableFieldsPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        ShipToAddress: Record "Ship-to Address";
        PaymentMethod: Record "Payment Method";
        PaymentReference: Code[50];
    begin
        PaymentReference :=
          CopyStr(
            LibraryUtility.GenerateRandomNumericText(MaxStrLen(PurchInvHeader."Payment Reference")), 1,
            MaxStrLen(PurchInvHeader."Payment Reference"));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibrarySales.CreateShipToAddress(ShipToAddress, PurchInvHeader."Sell-to Customer No.");
        PurchInvHeader."Payment Reference" := PaymentReference;
        PurchInvHeader."Payment Method Code" := PaymentMethod.Code;
        PurchInvHeader."Creditor No." := LibraryUtility.GenerateGUID();
        PurchInvHeader."Ship-to Code" := ShipToAddress.Code;
        PurchInvHeader."Posting Description" := LibraryRandom.RandText(25);

        LibraryVariableStorage.Enqueue(PurchInvHeader."Payment Reference");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Payment Method Code");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Creditor No.");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Ship-to Code");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Posting Description");
    end;

    local procedure PrepareEnqueueValuesForEditableFieldsPostedPurchaseCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        PurchCrMemoHdr."Posting Description" := LibraryRandom.RandText(25);

        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Posting Description");
    end;

    local procedure PrepareEnqueueValuesForEditableFieldsPostedReturnShipment(var ReturnShptHeader: Record "Return Shipment Header")
    var
        CountryRegion: Record "Country/Region";
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CreateShipmentMethodWith3rdPartyLoader(ShipmentMethod);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent."Shipping Agent Type" := ShippingAgent."Shipping Agent Type"::Vendor;
        ShippingAgent."Shipping Agent No." := LibraryPurchase.CreateVendorNo();
        ShippingAgent.Modify();

        ReturnShptHeader."Ship-to County" := LibraryUtility.GenerateGUID();
        ReturnShptHeader."Ship-to Country/Region Code" := CountryRegion.Code;
        ReturnShptHeader."Additional Information" := LibraryUtility.GenerateGUID();
        ReturnShptHeader."Additional Notes" := LibraryUtility.GenerateGUID();
        ReturnShptHeader."Additional Instructions" := LibraryUtility.GenerateGUID();
        ReturnShptHeader."TDD Prepared By" := LibraryUtility.GenerateGUID();
        ReturnShptHeader."Shipment Method Code" := ShipmentMethod.Code;
        ReturnShptHeader."Shipping Agent Code" := ShippingAgent.Code;
        ReturnShptHeader."3rd Party Loader Type" := ReturnShptHeader."3rd Party Loader Type"::Vendor;
        ReturnShptHeader."3rd Party Loader No." := LibraryPurchase.CreateVendorNo();

        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to County");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to Country/Region Code");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Additional Information");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Additional Notes");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Additional Instructions");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."TDD Prepared By");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Shipment Method Code");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."3rd Party Loader Type");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."3rd Party Loader No.");
    end;

    local procedure PrepareEnqueueValuesForEditableFieldsPostedReturnReceipt(var ReturnRcptHeader: Record "Return Receipt Header")
    var
        CountryRegion: Record "Country/Region";
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ReturnRcptHeader."Bill-to County" := LibraryUtility.GenerateGUID();
        ReturnRcptHeader."Bill-to Country/Region Code" := CountryRegion.Code;
        ReturnRcptHeader."Shipping Agent Code" := ShippingAgent.Code;
        ReturnRcptHeader."Package Tracking No." := LibraryUtility.GenerateGUID();

        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Bill-to County");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Bill-to Country/Region Code");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(ReturnRcptHeader."Package Tracking No.");
    end;

    local procedure EnqueValuesForEditableFieldsPostedTransferShipment(TransferShptHeader: Record "Transfer Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(TransferShptHeader."Transport Reason Code");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Goods Appearance");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Gross Weight");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Net Weight");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Parcel Units");
        LibraryVariableStorage.Enqueue(TransferShptHeader.Volume);
        LibraryVariableStorage.Enqueue(TransferShptHeader."Shipping Notes");
        LibraryVariableStorage.Enqueue(TransferShptHeader."3rd Party Loader Type");
        LibraryVariableStorage.Enqueue(TransferShptHeader."3rd Party Loader No.");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Shipping Starting Date");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Shipping Starting Time");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Package Tracking No.");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Additional Information");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Additional Notes");
        LibraryVariableStorage.Enqueue(TransferShptHeader."Additional Instructions");
        LibraryVariableStorage.Enqueue(TransferShptHeader."TDD Prepared By");
    end;

    local procedure EnqueValuesForEditableFieldsPostedServiceShipment(ServiceShptHeader: Record "Service Shipment Header")
    begin
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Additional Information");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Additional Notes");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Additional Instructions");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."TDD Prepared By");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Shipment Method Code");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."3rd Party Loader Type");
        LibraryVariableStorage.Enqueue(ServiceShptHeader."3rd Party Loader No.");
    end;

    local procedure PrepareValuesForEditableFieldsPostedTransferShipment(var TransferShptHeader: Record "Transfer Shipment Header")
    var
        ShipmentMethod: Record "Shipment Method";
        GoodsAppearance: Record "Goods Appearance";
        TransportReasonCode: Record "Transport Reason Code";
    begin
        CreateTransportReasonCode(TransportReasonCode);
        CreateGoodsAppearance(GoodsAppearance);
        CreateShipmentMethodWith3rdPartyLoader(ShipmentMethod);
        TransferShptHeader.FindFirst();
        TransferShptHeader."Shipment Method Code" := ShipmentMethod.Code;
        TransferShptHeader.Modify();

        TransferShptHeader.Init();
        TransferShptHeader."Transport Reason Code" := TransportReasonCode.Code;
        TransferShptHeader."Goods Appearance" := GoodsAppearance.Code;
        TransferShptHeader."Gross Weight" := LibraryRandom.RandDecInRange(100, 200, 2);
        TransferShptHeader."Net Weight" := LibraryRandom.RandDecInRange(100, 200, 2);
        TransferShptHeader."Parcel Units" := LibraryRandom.RandDecInRange(100, 200, 2);
        TransferShptHeader.Volume := LibraryRandom.RandDecInRange(100, 200, 2);
        TransferShptHeader."Shipping Notes" := LibraryUtility.GenerateGUID();
        TransferShptHeader."3rd Party Loader Type" := TransferShptHeader."3rd Party Loader Type"::Vendor;
        TransferShptHeader."3rd Party Loader No." := LibraryPurchase.CreateVendorNo();
        TransferShptHeader."Shipping Starting Date" := LibraryRandom.RandDate(1000);
        TransferShptHeader."Shipping Starting Time" := 123456T;
        TransferShptHeader."Package Tracking No." := LibraryUtility.GenerateGUID();
        TransferShptHeader."Additional Information" := LibraryUtility.GenerateGUID();
        TransferShptHeader."Additional Notes" := LibraryUtility.GenerateGUID();
        TransferShptHeader."Additional Instructions" := LibraryUtility.GenerateGUID();
        TransferShptHeader."TDD Prepared By" := LibraryUtility.GenerateGUID();
    end;

    local procedure PrepareValuesForEditableFieldsPostedServiceShipment(var ServiceShptHeader: Record "Service Shipment Header")
    var
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
    begin
        CreateShipmentMethodWith3rdPartyLoader(ShipmentMethod);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent."Shipping Agent Type" := ShippingAgent."Shipping Agent Type"::Vendor;
        ShippingAgent."Shipping Agent No." := LibraryPurchase.CreateVendorNo();
        ShippingAgent.Modify();

        ServiceShptHeader.Init();
        ServiceShptHeader."Additional Information" := LibraryUtility.GenerateGUID();
        ServiceShptHeader."Additional Notes" := LibraryUtility.GenerateGUID();
        ServiceShptHeader."Additional Instructions" := LibraryUtility.GenerateGUID();
        ServiceShptHeader."TDD Prepared By" := LibraryUtility.GenerateGUID();
        ServiceShptHeader."Shipment Method Code" := ShipmentMethod.Code;
        ServiceShptHeader."Shipping Agent Code" := ShippingAgent.Code;
        ServiceShptHeader."3rd Party Loader Type" := ServiceShptHeader."3rd Party Loader Type"::Vendor;
        ServiceShptHeader."3rd Party Loader No." := LibraryPurchase.CreateVendorNo();
    end;

    local procedure GetReceiptLines(PurchaseHeader: Record "Purchase Header"; PurchaseHeader2: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader2);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure ValidateGenAndVATPostingGrpsInPurchPrepymtAcc(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.Get(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateOKModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdatePackageTrackingNo_MPH(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateCancelModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateGetEditablelModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Sell-to Customer Name".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Shipping Agent Code".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Shipping Agent Service Code".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesShipmentUpdate."Package Tracking No.".Editable());
        PostedSalesShipmentUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateOKModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Posting Description".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateCancelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Shipping Agent Service Code".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate."Posting Description".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdateGetEditablelModalPageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Sell-to Customer Name".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Shipping Agent Code".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Shipping Agent Service Code".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Package Tracking No.".Editable());
        LibraryVariableStorage.Enqueue(PstdSalesCrMemoUpdate."Posting Description".Editable());
        PstdSalesCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateOKModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate."Creditor No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate."Ship-to Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate."Posting Description".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateCancelModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate."Creditor No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate."Ship-to Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate."Posting Description".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateGetEditablelModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Buy-from Vendor Name".Editable());
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Payment Reference".Editable());
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Payment Method Code".Editable());
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Creditor No.".Editable());
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Ship-to Code".Editable());
        LibraryVariableStorage.Enqueue(PostedPurchInvoiceUpdate."Posting Description".Editable());
        PostedPurchInvoiceUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateOKModalPageHandler(var PstdPurchCrMemoUpdate: TestPage "Pstd. Purch. Cr.Memo - Update")
    begin
        PstdPurchCrMemoUpdate."Posting Description".SetValue(LibraryVariableStorage.DequeueText());
        PstdPurchCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateCancelModalPageHandler(var PstdPurchCrMemoUpdate: TestPage "Pstd. Purch. Cr.Memo - Update")
    begin
        PstdPurchCrMemoUpdate."Posting Description".SetValue(LibraryVariableStorage.DequeueText());
        PstdPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUpdateGetEditablelModalPageHandler(var PstdPurchCrMemoUpdate: TestPage "Pstd. Purch. Cr.Memo - Update")
    begin
        LibraryVariableStorage.Enqueue(PstdPurchCrMemoUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PstdPurchCrMemoUpdate."Buy-from Vendor Name".Editable());
        LibraryVariableStorage.Enqueue(PstdPurchCrMemoUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PstdPurchCrMemoUpdate."Posting Description".Editable());
        PstdPurchCrMemoUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateOKModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        PostedReturnShptUpdate."Ship-to County".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Shipment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateCancelModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        PostedReturnShptUpdate."Ship-to County".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Shipment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateGetEditablelModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."Buy-from Vendor Name".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."Ship-to County".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnShptUpdate."Ship-to Country/Region Code".Editable());
        PostedReturnShptUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateOKModalPageHandler(var PostedReturnReceiptUpdate: TestPage "Posted Return Receipt - Update")
    begin
        PostedReturnReceiptUpdate."Bill-to County".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateCancelModalPageHandler(var PostedReturnReceiptUpdate: TestPage "Posted Return Receipt - Update")
    begin
        PostedReturnReceiptUpdate."Bill-to County".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate."Bill-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateGetEditablelModalPageHandler(var PostedReturnReceiptUpdate: TestPage "Posted Return Receipt - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Sell-to Customer Name".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Bill-to County".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Bill-to Country/Region Code".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Shipping Agent Code".Editable());
        LibraryVariableStorage.Enqueue(PostedReturnReceiptUpdate."Package Tracking No.".Editable());
        PostedReturnReceiptUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentUpdateOKModalPageHandler(var PostedTransferShptUpdate: TestPage "Posted Transfer Shpt. - Update")
    begin
        PostedTransferShptUpdate."Transport Reason Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Goods Appearance".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Gross Weight".SetValue(LibraryVariableStorage.DequeueDecimal());
        PostedTransferShptUpdate."Net Weight".SetValue(LibraryVariableStorage.DequeueDecimal());
        PostedTransferShptUpdate."Parcel Units".SetValue(LibraryVariableStorage.DequeueDecimal());
        PostedTransferShptUpdate.Volume.SetValue(LibraryVariableStorage.DequeueDecimal());
        PostedTransferShptUpdate."Shipping Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Shipping Starting Date".SetValue(LibraryVariableStorage.DequeueDate());
        PostedTransferShptUpdate."Shipping Starting Time".SetValue(LibraryVariableStorage.DequeueTime());
        PostedTransferShptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentUpdateCancelModalPageHandler(var PostedTransferShptUpdate: TestPage "Posted Transfer Shpt. - Update")
    begin
        PostedTransferShptUpdate."Transport Reason Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Goods Appearance".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Gross Weight".SetValue(LibraryVariableStorage.DequeueDecimal());
        PostedTransferShptUpdate."Net Weight".SetValue(LibraryVariableStorage.DequeueDecimal());
        PostedTransferShptUpdate."Parcel Units".SetValue(LibraryVariableStorage.DequeueDecimal());
        PostedTransferShptUpdate.Volume.SetValue(LibraryVariableStorage.DequeueDecimal());
        PostedTransferShptUpdate."Shipping Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Shipping Starting Date".SetValue(LibraryVariableStorage.DequeueDate());
        PostedTransferShptUpdate."Shipping Starting Time".SetValue(LibraryVariableStorage.DequeueTime());
        PostedTransferShptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText());
        PostedTransferShptUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentUpdateOKModalPageHandler(var PostedServiceShptUpdate: TestPage "Posted Service Ship. - Update")
    begin
        PostedServiceShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."Shipment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceShipmentUpdateCancelModalPageHandler(var PostedServiceShptUpdate: TestPage "Posted Service Ship. - Update")
    begin
        PostedServiceShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."Additional Notes".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."Additional Instructions".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."TDD Prepared By".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."Shipment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."Shipping Agent Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."3rd Party Loader Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate."3rd Party Loader No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestWorksheetLinesReqPageHandler(var SuggestWorksheetLines: TestRequestPage "Suggest Worksheet Lines")
    var
        CashFlowNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowNo);
        SuggestWorksheetLines.CashFlowNo.SetValue(CashFlowNo);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Liquid Funds""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Service Orders""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::Receivables]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::Payables]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Purchase Order""]".SetValue(true);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Revenue""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sales Order""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Budgeted Fixed Asset""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Expense""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sale of Fixed Asset""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::""G/L Budget""]".SetValue(false);
        SuggestWorksheetLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}