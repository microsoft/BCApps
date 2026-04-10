codeunit 134652 "O365 Posted Document Subtype"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = tabledata "Sales Shipment Line" = rimd,
                  tabledata "Sales Cr.Memo Line" = rimd,
                  tabledata "Sales Invoice Line" = rimd,
                  tabledata "Purch. Rcpt. Line" = rimd,
                  tabledata "Purch. Inv. Line" = rimd,
                  tabledata "Purch. Cr. Memo Line" = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [Posted Document] [Line Subtype] [UI]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure TypeFieldVisibilityNonSaaS()
    var
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new posted document
        PostedSalesShipment.OpenView();
        PostedSalesInvoice.OpenView();
        PostedSalesCreditMemo.OpenView();
        PostedPurchaseReceipt.OpenView();
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseCreditMemo.OpenView();

        // [THEN] The Type field is visible and the subtype field is not
        Assert.IsFalse(
          PostedSalesShipment.SalesShipmLines.FilteredTypeField.Visible(), 'FilteredTypeField field should not be visible for OnPrem');
        Assert.IsFalse(
          PostedPurchaseCreditMemo.PurchCrMemoLines.FilteredTypeField.Visible(),
          'FilteredTypeField field should not be visible for OnPrem');
        Assert.IsFalse(
          PostedSalesInvoice.SalesInvLines.FilteredTypeField.Visible(), 'FilteredTypeField field should not be visible for OnPrem');
        Assert.IsFalse(
          PostedSalesCreditMemo.SalesCrMemoLines.FilteredTypeField.Visible(), 'FilteredTypeField field should not be visible for OnPrem');
        Assert.IsFalse(
          PostedPurchaseReceipt.PurchReceiptLines.FilteredTypeField.Visible(), 'FilteredTypeField field should not be visible for OnPrem');
        Assert.IsFalse(
          PostedPurchaseInvoice.PurchInvLines.FilteredTypeField.Visible(), 'FilteredTypeField field should not be visible for OnPrem');

        Assert.IsTrue(PostedSalesShipment.SalesShipmLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsTrue(PostedSalesInvoice.SalesInvLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsTrue(PostedSalesCreditMemo.SalesCrMemoLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsTrue(PostedPurchaseReceipt.PurchReceiptLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsTrue(PostedPurchaseInvoice.PurchInvLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsTrue(PostedPurchaseCreditMemo.PurchCrMemoLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypeFieldVisibilitySaaS()
    var
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new posted document
        PostedSalesShipment.OpenView();
        PostedSalesInvoice.OpenView();
        PostedSalesCreditMemo.OpenView();
        PostedPurchaseReceipt.OpenView();
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseCreditMemo.OpenView();

        // [THEN] The Subtype field is visible and the type field is not
        asserterror PostedSalesShipment.SalesShipmLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        asserterror PostedSalesInvoice.SalesInvLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        asserterror PostedSalesCreditMemo.SalesCrMemoLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        asserterror PostedPurchaseReceipt.PurchReceiptLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        asserterror PostedPurchaseInvoice.PurchInvLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        asserterror PostedPurchaseCreditMemo.PurchCrMemoLines.Type.Activate();
        Assert.ExpectedError('not found on the page');

        Assert.IsTrue(
          PostedSalesShipment.SalesShipmLines.FilteredTypeField.Visible(), 'FilteredTypeField field should be visible for SaaS');
        Assert.IsTrue(PostedSalesInvoice.SalesInvLines.FilteredTypeField.Visible(), 'FilteredTypeField field should be visible for SaaS');
        Assert.IsTrue(
          PostedSalesCreditMemo.SalesCrMemoLines.FilteredTypeField.Visible(), 'FilteredTypeField field should be visible for SaaS');
        Assert.IsTrue(
          PostedPurchaseReceipt.PurchReceiptLines.FilteredTypeField.Visible(), 'FilteredTypeField field should be visible for SaaS');
        Assert.IsTrue(
          PostedPurchaseInvoice.PurchInvLines.FilteredTypeField.Visible(), 'FilteredTypeField field should be visible for SaaS');
        Assert.IsTrue(
          PostedPurchaseCreditMemo.PurchCrMemoLines.FilteredTypeField.Visible(), 'FilteredTypeField field should be visible for SaaS');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentFilteredTypeField()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Subtype field on Posted Sales Shipment subform contains correct value

        // [GIVEN] A sales shipment line
        SalesShipmentLine.Init();
        SalesShipmentLine.Insert();

        // [WHEN] Line type is blank
        SalesShipmentLine.Type := SalesShipmentLine.Type::" ";
        // [THEN] Subtype is comment
        VerifySubtypeOnSalesShipmentLine(SalesShipmentLine, SalesLine.FormatType());

        // [WHEN] Line type is Item (and no item is specified)
        SalesShipmentLine.Type := SalesShipmentLine.Type::Item;
        // [THEN] Subtype is Item
        VerifySubtypeOnSalesShipmentLine(SalesShipmentLine, Format(SalesLine.Type::Item));

        // [WHEN] Line type is "G/L Account"
        SalesShipmentLine.Type := SalesShipmentLine.Type::"G/L Account";
        // [THEN] Subtype is "G/L Account"
        VerifySubtypeOnSalesShipmentLine(SalesShipmentLine, Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Line type is "Fixed Asset"
        SalesShipmentLine.Type := SalesShipmentLine.Type::"Fixed Asset";
        // [THEN] Subtype is "Fixed Asset"
        VerifySubtypeOnSalesShipmentLine(SalesShipmentLine, Format(SalesLine.Type::"Fixed Asset"));

        // [WHEN] Line type is "Charge (Item)"
        SalesShipmentLine.Type := SalesShipmentLine.Type::"Charge (Item)";
        // [THEN] Subtype is "Charge (Item)"
        VerifySubtypeOnSalesShipmentLine(SalesShipmentLine, Format(SalesLine.Type::"Charge (Item)"));

        // [WHEN] Line type is Resource
        SalesShipmentLine.Type := SalesShipmentLine.Type::Resource;
        // [THEN] Subtype is Resource
        VerifySubtypeOnSalesShipmentLine(SalesShipmentLine, Format(SalesLine.Type::Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoFilteredTypeField()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Subtype field on Posted Sales Credit Memo subform contains correct value

        // [GIVEN] A sales shipment line
        SalesCrMemoLine.Init();
        SalesCrMemoLine.Insert();

        // [WHEN] Line type is blank
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::" ";
        // [THEN] Subtype is comment
        VerifySubtypeOnSalesCrMemoLine(SalesCrMemoLine, SalesLine.FormatType());

        // [WHEN] Line type is Item (and no item is specified)
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::Item;
        // [THEN] Subtype is Item
        VerifySubtypeOnSalesCrMemoLine(SalesCrMemoLine, Format(SalesLine.Type::Item));

        // [WHEN] Line type is "G/L Account"
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::"G/L Account";
        // [THEN] Subtype is "G/L Account"
        VerifySubtypeOnSalesCrMemoLine(SalesCrMemoLine, Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Line type is "Fixed Asset"
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::"Fixed Asset";
        // [THEN] Subtype is "Fixed Asset"
        VerifySubtypeOnSalesCrMemoLine(SalesCrMemoLine, Format(SalesLine.Type::"Fixed Asset"));

        // [WHEN] Line type is "Charge (Item)"
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::"Charge (Item)";
        // [THEN] Subtype is "Charge (Item)"
        VerifySubtypeOnSalesCrMemoLine(SalesCrMemoLine, Format(SalesLine.Type::"Charge (Item)"));

        // [WHEN] Line type is Resource
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::Resource;
        // [THEN] Subtype is Resource
        VerifySubtypeOnSalesCrMemoLine(SalesCrMemoLine, Format(SalesLine.Type::Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceFilteredTypeField()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Subtype field on Posted Sales Invoice subform contains correct value

        // [GIVEN] A sales shipment line
        SalesInvoiceLine.Init();
        SalesInvoiceLine.Insert();

        // [WHEN] Line type is blank
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::" ";
        // [THEN] Subtype is comment
        VerifySubtypeOnSalesInvoiceLine(SalesInvoiceLine, SalesLine.FormatType());

        // [WHEN] Line type is Item (and no item is specified)
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Item;
        // [THEN] Subtype is Item
        VerifySubtypeOnSalesInvoiceLine(SalesInvoiceLine, Format(SalesLine.Type::Item));

        // [WHEN] Line type is "G/L Account"
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::"G/L Account";
        // [THEN] Subtype is "G/L Account"
        VerifySubtypeOnSalesInvoiceLine(SalesInvoiceLine, Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Line type is "Fixed Asset"
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::"Fixed Asset";
        // [THEN] Subtype is "Fixed Asset"
        VerifySubtypeOnSalesInvoiceLine(SalesInvoiceLine, Format(SalesLine.Type::"Fixed Asset"));

        // [WHEN] Line type is "Charge (Item)"
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::"Charge (Item)";
        // [THEN] Subtype is "Charge (Item)"
        VerifySubtypeOnSalesInvoiceLine(SalesInvoiceLine, Format(SalesLine.Type::"Charge (Item)"));

        // [WHEN] Line type is Resource
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Resource;
        // [THEN] Subtype is Resource
        VerifySubtypeOnSalesInvoiceLine(SalesInvoiceLine, Format(SalesLine.Type::Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchRcptFilteredTypeField()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Subtype field on Posted Purchase Receipt subform contains correct value

        // [GIVEN] A sales shipment line
        PurchRcptLine.Init();
        PurchRcptLine.Insert();

        // [WHEN] Line type is blank
        PurchRcptLine.Type := PurchRcptLine.Type::" ";
        // [THEN] Subtype is comment
        VerifySubtypeOnPurchRcptLine(PurchRcptLine, PurchaseLine.FormatType());

        // [WHEN] Line type is Item (and no item is specified)
        PurchRcptLine.Type := PurchRcptLine.Type::Item;
        // [THEN] Subtype is Item
        VerifySubtypeOnPurchRcptLine(PurchRcptLine, Format(PurchaseLine.Type::Item));

        // [WHEN] Line type is "G/L Account"
        PurchRcptLine.Type := PurchRcptLine.Type::"G/L Account";
        // [THEN] Subtype is "G/L Account"
        VerifySubtypeOnPurchRcptLine(PurchRcptLine, Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Line type is "Fixed Asset"
        PurchRcptLine.Type := PurchRcptLine.Type::"Fixed Asset";
        // [THEN] Subtype is "Fixed Asset"
        VerifySubtypeOnPurchRcptLine(PurchRcptLine, Format(PurchaseLine.Type::"Fixed Asset"));

        // [WHEN] Line type is "Charge (Item)"
        PurchRcptLine.Type := PurchRcptLine.Type::"Charge (Item)";
        // [THEN] Subtype is "Charge (Item)"
        VerifySubtypeOnPurchRcptLine(PurchRcptLine, Format(PurchaseLine.Type::"Charge (Item)"));

        // [WHEN] Line type is "Resource"
        PurchRcptLine.Type := PurchRcptLine.Type::Resource;
        // [THEN] Subtype is "Resource"
        VerifySubtypeOnPurchRcptLine(PurchRcptLine, Format(PurchaseLine.Type::"Resource"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceFilteredTypeField()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Subtype field on Posted Purchase Invoice subform contains correct value

        // [GIVEN] A sales shipment line
        PurchInvLine.Init();
        PurchInvLine.Insert();

        // [WHEN] Line type is blank
        PurchInvLine.Type := PurchInvLine.Type::" ";
        // [THEN] Subtype is comment
        VerifySubtypeOnPurchInvLine(PurchInvLine, PurchaseLine.FormatType());

        // [WHEN] Line type is Item (and no item is specified)
        PurchInvLine.Type := PurchInvLine.Type::Item;
        // [THEN] Subtype is Item
        VerifySubtypeOnPurchInvLine(PurchInvLine, Format(PurchaseLine.Type::Item));

        // [WHEN] Line type is "G/L Account"
        PurchInvLine.Type := PurchInvLine.Type::"G/L Account";
        // [THEN] Subtype is "G/L Account"
        VerifySubtypeOnPurchInvLine(PurchInvLine, Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Line type is "Fixed Asset"
        PurchInvLine.Type := PurchInvLine.Type::"Fixed Asset";
        // [THEN] Subtype is "Fixed Asset"
        VerifySubtypeOnPurchInvLine(PurchInvLine, Format(PurchaseLine.Type::"Fixed Asset"));

        // [WHEN] Line type is "Charge (Item)"
        PurchInvLine.Type := PurchInvLine.Type::"Charge (Item)";
        // [THEN] Subtype is "Charge (Item)"
        VerifySubtypeOnPurchInvLine(PurchInvLine, Format(PurchaseLine.Type::"Charge (Item)"));

        // [WHEN] Line type is "Resource"
        PurchInvLine.Type := PurchInvLine.Type::Resource;
        // [THEN] Subtype is "Resource"
        VerifySubtypeOnPurchInvLine(PurchInvLine, Format(PurchaseLine.Type::"Resource"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoFilteredTypeField()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Subtype field on Posted Purchase Credit Memo subform contains correct value

        // [GIVEN] A sales shipment line
        PurchCrMemoLine.Init();
        PurchCrMemoLine.Insert();

        // [WHEN] Line type is blank
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::" ";
        // [THEN] Subtype is comment
        VerifySubtypeOnPurchCrMemoLine(PurchCrMemoLine, PurchaseLine.FormatType());

        // [WHEN] Line type is Item (and no item is specified)
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::Item;
        // [THEN] Subtype is Item
        VerifySubtypeOnPurchCrMemoLine(PurchCrMemoLine, Format(PurchaseLine.Type::Item));

        // [WHEN] Line type is "G/L Account"
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::"G/L Account";
        // [THEN] Subtype is "G/L Account"
        VerifySubtypeOnPurchCrMemoLine(PurchCrMemoLine, Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Line type is "Fixed Asset"
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::"Fixed Asset";
        // [THEN] Subtype is "Fixed Asset"
        VerifySubtypeOnPurchCrMemoLine(PurchCrMemoLine, Format(PurchaseLine.Type::"Fixed Asset"));

        // [WHEN] Line type is "Charge (Item)"
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::"Charge (Item)";
        // [THEN] Subtype is "Charge (Item)"
        VerifySubtypeOnPurchCrMemoLine(PurchCrMemoLine, Format(PurchaseLine.Type::"Charge (Item)"));

        // [WHEN] Line type is "Resource"
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::Resource;
        // [THEN] Subtype is "Resource"
        VerifySubtypeOnPurchCrMemoLine(PurchCrMemoLine, Format(PurchaseLine.Type::"Resource"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceJobNoField()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [SCENARIO 272496] "Job No." field on Posted Sales Invoice subform is visible for Jobs Application Area.
        Initialize();

        // [GIVEN] Jobs and Suite application area enabled.
        LibraryApplicationArea.EnableJobsAndSuiteSetup();

        // [WHEN] Open a new posted document.
        PostedPurchaseInvoice.OpenView();

        // [THEN] The "Job No." field is visible.
        Assert.IsTrue(PostedPurchaseInvoice.PurchInvLines."Job No.".Visible(), 'Job No. field must be visible.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Posted Document Subtype");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
    end;

    local procedure VerifySubtypeOnSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; ExpectedSubtype: Text)
    var
        PostedSalesShptSubform: TestPage "Posted Sales Shpt. Subform";
    begin
        SalesShipmentLine.Modify();
        PostedSalesShptSubform.OpenView();
        PostedSalesShptSubform.GotoRecord(SalesShipmentLine);
        PostedSalesShptSubform.FilteredTypeField.AssertEquals(ExpectedSubtype);
        PostedSalesShptSubform.Close();
    end;

    local procedure VerifySubtypeOnSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; ExpectedSubtype: Text)
    var
        PostedSalesInvoiceSubform: TestPage "Posted Sales Invoice Subform";
    begin
        SalesInvoiceLine.Modify();
        PostedSalesInvoiceSubform.OpenView();
        PostedSalesInvoiceSubform.GotoRecord(SalesInvoiceLine);
        PostedSalesInvoiceSubform.FilteredTypeField.AssertEquals(ExpectedSubtype);
        PostedSalesInvoiceSubform.Close();
    end;

    local procedure VerifySubtypeOnSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; ExpectedSubtype: Text)
    var
        PostedSalesCrMemoSubform: TestPage "Posted Sales Cr. Memo Subform";
    begin
        SalesCrMemoLine.Modify();
        PostedSalesCrMemoSubform.OpenView();
        PostedSalesCrMemoSubform.GotoRecord(SalesCrMemoLine);
        PostedSalesCrMemoSubform.FilteredTypeField.AssertEquals(ExpectedSubtype);
        PostedSalesCrMemoSubform.Close();
    end;

    local procedure VerifySubtypeOnPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; ExpectedSubtype: Text)
    var
        PostedPurchaseRcptSubform: TestPage "Posted Purchase Rcpt. Subform";
    begin
        PurchRcptLine.Modify();
        PostedPurchaseRcptSubform.OpenView();
        PostedPurchaseRcptSubform.GotoRecord(PurchRcptLine);
        PostedPurchaseRcptSubform.FilteredTypeField.AssertEquals(ExpectedSubtype);
        PostedPurchaseRcptSubform.Close();
    end;

    local procedure VerifySubtypeOnPurchInvLine(var PurchInvLine: Record "Purch. Inv. Line"; ExpectedSubtype: Text)
    var
        PostedPurchInvoiceSubform: TestPage "Posted Purch. Invoice Subform";
    begin
        PurchInvLine.Modify();
        PostedPurchInvoiceSubform.OpenView();
        PostedPurchInvoiceSubform.GotoRecord(PurchInvLine);
        PostedPurchInvoiceSubform.FilteredTypeField.AssertEquals(ExpectedSubtype);
        PostedPurchInvoiceSubform.Close();
    end;

    local procedure VerifySubtypeOnPurchCrMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; ExpectedSubtype: Text)
    var
        PostedPurchCrMemoSubform: TestPage "Posted Purch. Cr. Memo Subform";
    begin
        PurchCrMemoLine.Modify();
        PostedPurchCrMemoSubform.OpenView();
        PostedPurchCrMemoSubform.GotoRecord(PurchCrMemoLine);
        PostedPurchCrMemoSubform.FilteredTypeField.AssertEquals(ExpectedSubtype);
        PostedPurchCrMemoSubform.Close();
    end;
}

