codeunit 134658 "Edit Posted Documents"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = tabledata "Sales Cr.Memo Header" = imd;

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
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        UnexpectedQtyErr: Label 'Unexpected Quantity shown.';
        UnexpectedNetWeightErr: Label 'Unexpected Net Weight shown.';
        UnexpectedGrossWeightErr: Label 'Unexpected Gross Weight shown.';
        UnexpectedVolumeErr: Label 'Unexpected Volume shown.';
        CashFlowWorkSheetLineMustNotBeFoundErr: Label 'Cash Flow Worksheet Line must not be found.';
        YourReferenceErr: Label 'Your reference must be editable';
        SalesInvoiceYourReferenceErr: Label 'Sales Invoice Your Reference not updated';
        CustLedgerEntryYourReferenceErr: Label 'Customer Ledger Entry Your Reference not updated';

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
    [HandlerFunctions('PostedSalesInvoiceUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateEditableFields()
    var
        PostedPurchaseInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 393512] Editable and non-editable fields on page "Posted Sales Invoice - Update".
        Initialize();
        LibraryLowerPermissions.SetO365Setup();

        // [WHEN] Open "Posted Sales Invoice - Update" page
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice."Update Document".Invoke();

        // [THEN] Fields "No.", "Sell-to Customer Name", "Posting Date" are not editable.
        // [THEN] Fields "Payment Reference", "Payment Method Code" are editable.
        // [THEN] Field "Posting Description" is editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Sell-to Customer Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Payment Reference must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Payment Method Code must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Posting Description must be editable');

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSetValuesCancel()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeaderNew: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 393512] New values for editable fields are not set in case Stan presses Cancel on "Posted Sales Invoice - Update" modal page.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        SalesInvoiceHeader.Get(CreateAndPostSalesOrderGetInvoiceNo());
        SalesInvoiceHeaderNew := SalesInvoiceHeader;
        PrepareEnqueueValuesForPostedSalesInvoice(SalesInvoiceHeaderNew);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GoToRecord(SalesInvoiceHeaderNew);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page via PostedSalesInvoiceUpdateCancelModalPageHandler

        // [THEN] Values of these fields in Sales Invoice Header were not changed to new values.
        PostedSalesInvoice.Close();
        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        Assert.AreNotEqual(SalesInvoiceHeaderNew."Payment Reference", SalesInvoiceHeader."Payment Reference", SalesInvoiceHeader.FieldCaption("Payment Reference"));
        Assert.AreNotEqual(SalesInvoiceHeaderNew."Payment Method Code", SalesInvoiceHeader."Payment Method Code", SalesInvoiceHeader.FieldCaption("Payment Method Code"));
        Assert.AreNotEqual(SalesInvoiceHeaderNew."Posting Description", SalesInvoiceHeader."Posting Description", SalesInvoiceHeader.FieldCaption("Posting Description"));

        // [THEN] Values at the associated customer ledger entry were not changed
        CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.");
        Assert.AreEqual(SalesInvoiceHeader."Payment Reference", CustLedgerEntry."Payment Reference", SalesInvoiceHeader.FieldCaption("Payment Reference"));
        Assert.AreEqual(SalesInvoiceHeader."Payment Method Code", CustLedgerEntry."Payment Method Code", SalesInvoiceHeader.FieldCaption("Payment Method Code"));
        Assert.AreEqual(SalesInvoiceHeader."Posting Description", CustLedgerEntry.Description, SalesInvoiceHeader.FieldCaption("Posting Description"));

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateSetValuesOK()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeaderNew: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 393512] New values for editable fields are set in case Stan presses OK on "Posted Sales Invoice - Update" modal page.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        SalesInvoiceHeader.Get(CreateAndPostSalesOrderGetInvoiceNo());
        SalesInvoiceHeaderNew := SalesInvoiceHeader;
        PrepareEnqueueValuesForPostedSalesInvoice(SalesInvoiceHeaderNew);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GoToRecord(SalesInvoiceHeaderNew);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page via PostedSalesInvoiceUpdateOkModalPageHandler

        // [THEN] Values of these fields in Sales Invoice Header were changed to new values.
        PostedSalesInvoice.Close();
        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        SalesInvoiceHeader.TestField("Payment Reference", SalesInvoiceHeaderNew."Payment Reference");
        SalesInvoiceHeader.TestField("Payment Method Code", SalesInvoiceHeaderNew."Payment Method Code");
        SalesInvoiceHeader.TestField("Posting Description", SalesInvoiceHeaderNew."Posting Description");

        // [THEN] Values at the associated customer ledger entry were changed
        CustLedgerEntry.Get(SalesInvoiceHeaderNew."Cust. Ledger Entry No.");
        Assert.AreEqual(SalesInvoiceHeaderNew."Payment Reference", CustLedgerEntry."Payment Reference", SalesInvoiceHeader.FieldCaption("Payment Reference"));
        Assert.AreEqual(SalesInvoiceHeaderNew."Payment Method Code", CustLedgerEntry."Payment Method Code", SalesInvoiceHeader.FieldCaption("Payment Method Code"));
        Assert.AreEqual(SalesInvoiceHeaderNew."Posting Description", CustLedgerEntry.Description, SalesInvoiceHeader.FieldCaption("Posting Description"));

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateGetEditablelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateEditableFields()
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 393512] Editable and non-editable fields on page "Posted Service Inv. - Update".
        Initialize();

        // [WHEN] Open "Posted Service Inv. - Update" page
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice."Update Document".Invoke();

        // [THEN] Fields "No.", "Bill-to Name", "Posting Date" are not editable.
        // [THEN] Fields "Payment Reference", "Payment Method Code" are editable.
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'No. must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Bill-to Name must be not editable');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Posting Date must be not editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Payment Reference must be editable');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Payment Method Code must be editable');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateSetValuesCancel()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceHeaderNew: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 393512] New values for editable fields are not set in case Stan presses Cancel on "Posted Service Invoice - Update" modal page.
        Initialize();

        MockServiceInvoice(ServiceInvoiceHeader);
        ServiceInvoiceHeaderNew := ServiceInvoiceHeader;
        PrepareEnqueueValuesForPostedServiceInvoice(ServiceInvoiceHeaderNew);

        // [GIVEN] Opened "Posted Service Invoice - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.GoToRecord(ServiceInvoiceHeaderNew);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press Cancel on the page via PostedServiceInvoiceUpdateCancelModalPageHandler

        // [THEN] Values of these fields in Service Invoice Header were not changed to new values.
        PostedServiceInvoice.Close();
        ServiceInvoiceHeader.Get(ServiceInvoiceHeader."No.");
        Assert.AreNotEqual(ServiceInvoiceHeaderNew."Payment Reference", ServiceInvoiceHeader."Payment Reference", ServiceInvoiceHeader.FieldCaption("Payment Reference"));
        Assert.AreNotEqual(ServiceInvoiceHeaderNew."Payment Method Code", ServiceInvoiceHeader."Payment Method Code", ServiceInvoiceHeader.FieldCaption("Payment Method Code"));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateSetValuesOK()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceHeaderNew: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 393512] New values for editable fields are set in case Stan presses OK on "Posted Service Invoice - Update" modal page.
        Initialize();

        MockServiceInvoice(ServiceInvoiceHeader);
        ServiceInvoiceHeaderNew := ServiceInvoiceHeader;
        PrepareEnqueueValuesForPostedServiceInvoice(ServiceInvoiceHeaderNew);

        // [GIVEN] Opened "Posted Service - Update" page.
        // [GIVEN] New values are set for editable fields.
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.GoToRecord(ServiceInvoiceHeaderNew);
        PostedServiceInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page via PostedServiceInvoiceUpdateOkModalPageHandler

        // [THEN] Values of these fields in Service Invoice Header were changed to new values.
        PostedServiceInvoice.Close();
        ServiceInvoiceHeader.Get(ServiceInvoiceHeader."No.");
        ServiceInvoiceHeader.TestField("Payment Reference", ServiceInvoiceHeaderNew."Payment Reference");
        ServiceInvoiceHeader.TestField("Payment Method Code", ServiceInvoiceHeaderNew."Payment Method Code");

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
            LibraryRandom.RandIntInRange(5, 5));

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

        // [GIVEN] Create a Purchase Header and Validate Prepayment %.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order, Vendor."No.");
        PurchaseHeader[1].Validate("Prepayment %", LibraryRandom.RandIntInRange(20, 20));
        PurchaseHeader[1].Modify(true);

        // [GIVEN] Create a Purchase Line and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader[1], PurchaseLine[1].Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10));
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine[1].Modify(true);

        // [GIVEN] Post Purchase Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader[1]);

        // [GIVEN] Post Purchase Receipt.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        // [GIVEN] Create another Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Get Receipt Lines.
        GetReceiptLines(PurchaseHeader[1], PurchaseHeader[2]);

        // [GIVEN] Open Purchase Invoice page and run Post action.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader[2]);
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

    [Test]
    [HandlerFunctions('PostedSalesInvoiceUpdateYourReferenceModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateYourReferenceInPostedSalesInvoice()
    var
        PostedPurchaseInvoice: TestPage "Posted Sales Invoice";
    begin
        // [SCENARIO 559776] Your Reference field is Editable on the Posted Sales Invoice
        Initialize();

        // [GIVEN] Lower the permission
        LibraryLowerPermissions.SetO365Setup();

        // [WHEN] Open "Posted Sales Invoice - Update" page
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice."Update Document".Invoke();

        // [THEN] Verify the Your Reference field is editable
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), YourReferenceErr);

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceYourReferenceModalPageHandler')]
    procedure VerifyYourReferenceUpdatedInCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        YourReference: Text[35];
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [SCENARIO 595854] Verify Your Reference Field updated in Customer Ledger Entries,
        // when changed with Update document on Posted Sales Invoice.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        // [GIVEN] Create and post a Sales Order.
        SalesInvoiceHeader.Get(CreateAndPostSalesOrderGetInvoiceNo());
        YourReference := LibraryRandom.RandText(35);
        LibraryVariableStorage.Enqueue(YourReference);

        // [GIVEN] Opened "Posted Sales Invoice - Update" page.
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GoToRecord(SalesInvoiceHeader);
        PostedSalesInvoice."Update Document".Invoke();

        // [WHEN] Press OK on the page via PostedSalesInvoiceYourReferenceModalPageHandler.

        // [THEN] Verify Your Reference field updated on Sales Invoice Header and Customer Ledger Entry.
        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        Assert.AreEqual(YourReference, SalesInvoiceHeader."Your Reference", SalesInvoiceYourReferenceErr);

        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();
        Assert.AreEqual(YourReference, CustLedgerEntry."Your Reference", CustLedgerEntryYourReferenceErr);

        LibraryVariableStorage.AssertEmpty();
        LibraryLowerPermissions.SetOutsideO365Scope();
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

    local procedure CreateAndPostSalesOrderGetInvoiceNo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
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

    local procedure MockServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Posting Date" := WorkDate();
        ServiceInvoiceHeader."Bill-to Name" := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader.Insert();
    end;

    local procedure PrepareEnqueueValuesForEditableFieldsPostedSalesShipment(var SalesShptHeader: Record "Sales Shipment Header")
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        DateFormula: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);
        SalesShptHeader."Shipping Agent Code" := ShippingAgent.Code;
        SalesShptHeader."Shipping Agent Service Code" := ShippingAgentServices.Code;
        SalesShptHeader."Package Tracking No." := LibraryUtility.GenerateGUID();

        LibraryVariableStorage.Enqueue(SalesShptHeader."Shipping Agent Code");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Shipping Agent Service Code");
        LibraryVariableStorage.Enqueue(SalesShptHeader."Package Tracking No.");
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
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        ReturnShptHeader."Ship-to County" := LibraryUtility.GenerateGUID();
        ReturnShptHeader."Ship-to Country/Region Code" := CountryRegion.Code;

        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to County");
        LibraryVariableStorage.Enqueue(ReturnShptHeader."Ship-to Country/Region Code");
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

    local procedure PrepareEnqueueValuesForPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        SalesInvoiceHeader."Payment Reference" := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Payment Method Code" := PaymentMethod.Code;
        SalesInvoiceHeader."Posting Description" := LibraryRandom.RandText(25);

        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Payment Reference");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Payment Method Code");
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Posting Description");
    end;

    local procedure PrepareEnqueueValuesForPostedServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        ServiceInvoiceHeader."Payment Reference" := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Payment Method Code" := PaymentMethod.Code;

        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Payment Reference");
        LibraryVariableStorage.Enqueue(ServiceInvoiceHeader."Payment Method Code");
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
        PostedReturnShptUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateCancelModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        PostedReturnShptUpdate."Ship-to County".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnShptUpdate."Ship-to Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
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
    procedure PostedSalesInvoiceUpdateGetEditablelModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Sell-to Customer Name".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Payment Reference".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Payment Method Code".Editable());
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Posting Description".Editable());
        PostedSalesInvUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateOKModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        PostedSalesInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdate."Posting Description".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateCancelModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        PostedSalesInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdate."Posting Description".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateGetEditablelModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."No.".Editable());
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."Bill-to Name".Editable());
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."Posting Date".Editable());
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."Payment Reference".Editable());
        LibraryVariableStorage.Enqueue(PostedServiceInvUpdate."Payment Method Code".Editable());
        PostedServiceInvUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateOKModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUpdateCancelModalPageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate."Payment Method Code".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate.Cancel().Invoke();
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdateYourReferenceModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvUpdate."Your Reference".Editable());
        PostedSalesInvUpdate.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceYourReferenceModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        PostedSalesInvUpdate."Your Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdate.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
