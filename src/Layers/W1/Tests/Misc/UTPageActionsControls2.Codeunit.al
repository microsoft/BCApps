codeunit 134348 "UT Page Actions & Controls - 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
    end;

    var
        Assert: Codeunit Assert;
        FilterHasBeenChangedErr: Label 'Filter has been changed.';
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        PageFieldVisibleErr: Label '%1 must be visible.';
        PageFieldEditableErr: Label '%1 must be editable.';
        CustomerCardTxt: Label 'Customer Card';
        VendorCardTxt: Label 'Vendor Card';

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesDrillDowns()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Sales Invoices" page
        Initialize();

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedSalesInvoices.Next();

        PostedSalesInvoice.Trap();
        PostedSalesInvoices.Amount.DrillDown();
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesInvoice.Next();
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesInvoice.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedSalesInvoice.Trap();
        PostedSalesInvoices."Amount Including VAT".DrillDown();
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesInvoice.Next();
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesInvoice.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedCustLedgEntries.Trap();
        PostedSalesInvoices."Remaining Amount".DrillDown();
        DetailedCustLedgEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        CustomerLedgerEntries.Trap();
        PostedSalesInvoices.Closed.DrillDown();
        CustomerLedgerEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemosDrillDown()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Sales Credit Memos" page
        Initialize();

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        PostedSalesCreditMemos.OpenView();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedSalesCreditMemos.Next();

        PostedSalesCreditMemo.Trap();
        PostedSalesCreditMemos.Amount.DrillDown();
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesCreditMemo.Next();
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesCreditMemo.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedSalesCreditMemo.Trap();
        PostedSalesCreditMemos."Amount Including VAT".DrillDown();
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesCreditMemo.Next();
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesCreditMemo.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedCustLedgEntries.Trap();
        PostedSalesCreditMemos."Remaining Amount".DrillDown();
        DetailedCustLedgEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        CustomerLedgerEntries.Trap();
        PostedSalesCreditMemos.Paid.DrillDown();
        CustomerLedgerEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicesDrillDowns()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Purchases] [Invoice]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Purchase Invoices" page
        Initialize();

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedPurchaseInvoices.Next();

        PostedPurchaseInvoice.Trap();
        PostedPurchaseInvoices.Amount.DrillDown();
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseInvoice.Next();
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseInvoice.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedPurchaseInvoice.Trap();
        PostedPurchaseInvoices."Amount Including VAT".DrillDown();
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseInvoice.Next();
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseInvoice.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedVendorLedgEntries.Trap();
        PostedPurchaseInvoices."Remaining Amount".DrillDown();
        DetailedVendorLedgEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        VendorLedgerEntries.Trap();
        PostedPurchaseInvoices.Closed.DrillDown();
        VendorLedgerEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemosDrillDown()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Purchases] [Credit Memo]
        // [SCENARIO 315881]"Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Purchase Credit Memos" page
        Initialize();

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        PostedPurchaseCreditMemos.OpenView();
        PostedPurchaseCreditMemos.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedPurchaseCreditMemos.Next();

        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseCreditMemos.Amount.DrillDown();
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseCreditMemo.Next();
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseCreditMemo.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseCreditMemos."Amount Including VAT".DrillDown();
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseCreditMemo.Next();
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseCreditMemo.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedVendorLedgEntries.Trap();
        PostedPurchaseCreditMemos."Remaining Amount".DrillDown();
        DetailedVendorLedgEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        VendorLedgerEntries.Trap();
        PostedPurchaseCreditMemos.Paid.DrillDown();
        VendorLedgerEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SepaSetupFieldSEPANonEuroExport()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 327227] On page General Ledger Setup field "SEPANonEuroExport" is visible and editable.
        Initialize();

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(
          GeneralLedgerSetup.SEPANonEuroExport.Visible(),
          StrSubstNo(PageFieldVisibleErr, GeneralLedgerSetup.SEPANonEuroExport.Caption));
        Assert.IsTrue(
          GeneralLedgerSetup.SEPANonEuroExport.Editable(),
          StrSubstNo(PageFieldEditableErr, GeneralLedgerSetup.SEPANonEuroExport.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SepaSetupFieldSEPANonEuroExportSaas()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 327227] On page General Ledger Setup field "SEPANonEuroExport" is visible and editable.

        Initialize();

        LibraryPermissions.SetTestabilitySoftwareAsAService(true);

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(
          GeneralLedgerSetup.SEPANonEuroExport.Visible(),
          StrSubstNo(PageFieldVisibleErr, GeneralLedgerSetup.SEPANonEuroExport.Caption));
        Assert.IsTrue(
          GeneralLedgerSetup.SEPANonEuroExport.Editable(),
          StrSubstNo(PageFieldEditableErr, GeneralLedgerSetup.SEPANonEuroExport.Caption));

        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SepaSetupFieldSEPAExportWoBankAccData()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 327227] On page General Ledger Setup field "SEPAExportWoBankAccData" is visible and editable.
        Initialize();

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(
          GeneralLedgerSetup.SEPAExportWoBankAccData.Visible(),
          StrSubstNo(PageFieldVisibleErr, GeneralLedgerSetup.SEPAExportWoBankAccData.Caption));
        Assert.IsTrue(
          GeneralLedgerSetup.SEPAExportWoBankAccData.Editable(),
          StrSubstNo(PageFieldEditableErr, GeneralLedgerSetup.SEPAExportWoBankAccData.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SepaSetupFieldSEPAExportWoBankAccDataSaas()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 327227] On page General Ledger Setup field "SEPAExportWoBankAccData" is visible and editable.
        Initialize();

        LibraryPermissions.SetTestabilitySoftwareAsAService(true);

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(
          GeneralLedgerSetup.SEPAExportWoBankAccData.Visible(),
          StrSubstNo(PageFieldVisibleErr, GeneralLedgerSetup.SEPAExportWoBankAccData.Caption));
        Assert.IsTrue(
          GeneralLedgerSetup.SEPAExportWoBankAccData.Editable(),
          StrSubstNo(PageFieldEditableErr, GeneralLedgerSetup.SEPAExportWoBankAccData.Caption));

        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_CustomerNo_Visible_OnPrem()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 338236] "Customer No." field must be visible by default on Sales Invoice card page
        Initialize();

        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
        SalesInvoice.OpenView();
        Assert.IsTrue(SalesInvoice."Sell-to Customer No.".Visible(), '');
        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_CustomerNo_Visible_SaaS()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 338236] "Customer No." field must be visible by default on Sales Invoice card page
        Initialize();

        LibraryPermissions.SetTestabilitySoftwareAsAService(true);
        SalesInvoice.OpenView();
        Assert.IsTrue(SalesInvoice."Sell-to Customer No.".Visible(), '');
        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromCustomerListDateFilter()
    var
        CustomerList: TestPage "Customer List";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        CustomerList.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerList.FILTER.GetFilter("Date Filter"), 'Customer List');

        CustomerCard.Trap();
        CustomerList.Edit().Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        CustomerList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesOrderDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesOrder(SalesHeader);

        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesOrder.FILTER.GetFilter("Date Filter"), 'Sales Order');

        CustomerCard.Trap();
        SalesOrder.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesOrderListDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderList: TestPage "Sales Order List";
    begin
        Initialize();

        LibrarySales.CreateSalesOrder(SalesHeader);

        SalesOrderList.OpenView();
        SalesOrderList.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesOrderList.FILTER.GetFilter("Date Filter"), 'Sales Order List');

        // There is not Customer Card action on Sales Order List.

        SalesOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesInvoiceDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesInvoice(SalesHeader);

        SalesInvoice.OpenView();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesInvoice.FILTER.GetFilter("Date Filter"), 'Sales Invoice');

        CustomerCard.Trap();
        SalesInvoice.Function_CustomerCard.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesInvoiceListDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesInvoice(SalesHeader);

        SalesInvoiceList.OpenView();
        SalesInvoiceList.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesInvoiceList.FILTER.GetFilter("Date Filter"), 'Sales Invoice List');

        CustomerCard.Trap();
        SalesInvoiceList.CustomerAction.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesInvoiceList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesCreditMemoDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesCreditMemo(SalesHeader);

        SalesCreditMemo.OpenView();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesCreditMemo.FILTER.GetFilter("Date Filter"), 'Sales Credit Memo');

        CustomerCard.Trap();
        SalesCreditMemo.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);
        CustomerCard.Close();

        CustomerCard.Trap();
        SalesCreditMemo.CreditMemo_CustomerCard.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);
        CustomerCard.Close();

        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesCreditMemoListDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesCreditMemos.OpenView();
        SalesCreditMemos.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesCreditMemos.FILTER.GetFilter("Date Filter"), 'Sales Credit Memos');

        CustomerCard.Trap();
        SalesCreditMemos.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesCreditMemos.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesQuoteDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());

        SalesQuote.OpenView();
        SalesQuote.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesQuote.FILTER.GetFilter("Date Filter"), 'Sales Quote');

        CustomerCard.Trap();
        SalesQuote.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesQuoteListDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesQuotes: TestPage "Sales Quotes";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());

        SalesQuotes.OpenView();
        SalesQuotes.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesQuotes.FILTER.GetFilter("Date Filter"), 'Sales Quotes');

        CustomerCard.Trap();
        SalesQuotes.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesQuotes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromVendorListDateFilter()
    var
        VendorList: TestPage "Vendor List";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreateVendorNo();

        VendorList.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), VendorList.FILTER.GetFilter("Date Filter"), 'Vendor List');

        VendorCard.Trap();
        VendorList.Edit().Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        VendorList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseOrderDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        PurchaseOrder.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseOrder.FILTER.GetFilter("Date Filter"), 'Purchase Order');

        VendorCard.Trap();
        PurchaseOrder.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseOrderListDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseOrderList.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseOrderList.FILTER.GetFilter("Date Filter"), 'Purchase Order List');

        // There is not Vendord Card action on Purchase Order List.
        PurchaseOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseInvoiceDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchaseInvoice.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseInvoice.FILTER.GetFilter("Date Filter"), 'Purchase Invoice');

        VendorCard.Trap();
        PurchaseInvoice.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseInvoiceListDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchaseInvoices.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseInvoices.FILTER.GetFilter("Date Filter"), 'Purchase Invoices');

        VendorCard.Trap();
        PurchaseInvoices.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseInvoices.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseCreditMemoDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        PurchaseCreditMemo.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseCreditMemo.FILTER.GetFilter("Date Filter"), 'Purchase Credit Memo');

        VendorCard.Trap();
        PurchaseCreditMemo.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseCreditMemoListDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        PurchaseCreditMemos.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseCreditMemos.FILTER.GetFilter("Date Filter"), 'Purchase Credit Memos');

        VendorCard.Trap();
        PurchaseCreditMemos.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseCreditMemos.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseQuoteDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        PurchaseQuote.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseQuote.FILTER.GetFilter("Date Filter"), 'Purchase Quote');

        VendorCard.Trap();
        PurchaseQuote.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseQuoteListDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        PurchaseQuotes.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseQuotes.FILTER.GetFilter("Date Filter"), 'Purchase Quotes');

        // There is not Vendor Card action on Purchase Quotes
        PurchaseQuotes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteSalesLineFactboxNewLineItemNoEntered()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Quote] [Sales]
        // [SCENARIO 346194] "Sales Line Details" factbox updates when item's "No." is specified on Sales Quote's line
        Initialize();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote);
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesQuote.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        SalesQuote.Control1906127307.ItemNo.AssertEquals(SalesQuote.SalesLines."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSalesLineFactboxNewLineItemNoEntered()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Order] [Sales]
        // [SCENARIO 346194] "Sales Line Details" factbox updates when item's "No." is specified on Sales Order's line
        Initialize();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        SalesOrder.Control1906127307.ItemNo.AssertEquals(SalesOrder.SalesLines."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSalesLineFactboxNewLineItemNoEntered()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Invoice] [Sales]
        // [SCENARIO 346194] "Sales Line Details" factbox updates when item's "No." is specified on Sales Invoice's line
        Initialize();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesInvoice.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        asserterror SalesInvoice.Control1906127307.ItemNo.AssertEquals(SalesInvoice.SalesLines."No.");
        Assert.ExpectedError('The part with ID = 1255971699 was not found on the page.'); // VISIBLE FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoSalesLineFactboxNewLineItemNoEntered()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Credit Memo] [Sales]
        // [SCENARIO 346194] "Sales Line Details" factbox updates when item's "No." is specified on Sales Credit Memo's line
        Initialize();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesCreditMemo.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        asserterror SalesCreditMemo.Control1906127307.ItemNo.AssertEquals(SalesCreditMemo.SalesLines."No.");
        Assert.ExpectedError('The part with ID = 1528634028 was not found on the page.'); // VISIBLE FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderSalesLineFactboxNewLineItemNoEntered()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [UI] [Blanket Order] [Sales]
        // [SCENARIO 346194] "Sales Line Details" factbox updates when item's "No." is specified on Sales Blanket Order's line
        Initialize();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Blanket Order");
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        BlanketSalesOrder.SalesLines.New();
        BlanketSalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        BlanketSalesOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        asserterror BlanketSalesOrder.Control1906127307.ItemNo.AssertEquals(BlanketSalesOrder.SalesLines."No.");
        Assert.ExpectedError('The part with ID = 1073894834 was not found on the page.'); // VISIBLE FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderSalesLineFactboxNewLineItemNoEntered()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [UI] [Return Order] [Sales]
        // [SCENARIO 346194] "Sales Line Details" factbox updates when item's "No." is specified on Sales Return Order's line
        Initialize();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesReturnOrder.SalesLines.New();
        SalesReturnOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesReturnOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        asserterror SalesReturnOrder.Control1906127307.ItemNo.AssertEquals(SalesReturnOrder.SalesLines."No.");
        Assert.ExpectedError('The part with ID = 250218575 was not found on the page.'); // VISIBLE FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuotePurchaseLineFactboxNewLineItemNoEntered()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Quote] [Purchase]
        // [SCENARIO 346194] "Purchase Line Details" factbox updates when item's "No." is specified on Purchase Quote's line
        Initialize();

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseQuote.PurchLines.New();
        PurchaseQuote.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseQuote.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseQuote.Control5."No.".AssertEquals(PurchaseQuote.PurchLines."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPurchaseLineFactboxNewLineItemNoEntered()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Order] [Purchase]
        // [SCENARIO 346194] "Purchase Line Details" factbox updates when item's "No." is specified on Purchase Order's line
        Initialize();

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.New();
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseOrder.Control3."No.".AssertEquals(PurchaseOrder.PurchLines."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePurchaseLineFactboxNewLineItemNoEntered()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Invoice] [Purchase]
        // [SCENARIO 346194] "Purchase Line Details" factbox updates when item's "No." is specified on Purchase Invoice's line
        Initialize();

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseInvoice.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        asserterror PurchaseInvoice.Control3."No.".AssertEquals(PurchaseInvoice.PurchLines."No.");
        Assert.ExpectedError('The part with ID = 1331326981 was not found on the page.'); // VISIBLE FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoPurchaseLineFactboxNewLineItemNoEntered()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Credit Memo] [Purchase]
        // [SCENARIO 346194] "Purchase Line Details" factbox updates when item's "No." is specified on Purchase Credit Memo's line
        Initialize();

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseCreditMemo.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        asserterror PurchaseCreditMemo.Control5."No.".AssertEquals(PurchaseCreditMemo.PurchLines."No.");
        Assert.ExpectedError('The part with ID = 2115167912 was not found on the page.'); // VISIBLE FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderPurchaseLineFactboxNewLineItemNoEntered()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI] [Blanket Order] [Purchase]
        // [SCENARIO 346194] "Purchase Line Details" factbox updates when item's "No." is specified on Purchase Blanket Order's line
        Initialize();

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order");
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        BlanketPurchaseOrder.PurchLines.New();
        BlanketPurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        BlanketPurchaseOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        asserterror BlanketPurchaseOrder.Control3."No.".AssertEquals(BlanketPurchaseOrder.PurchLines."No.");
        Assert.ExpectedError('The part with ID = 109000829 was not found on the page.'); // VISIBLE FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderPurchaseLineFactboxNewLineItemNoEntered()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI] [Return Order] [Purchase]
        // [SCENARIO 346194] "Purchase Line Details" factbox updates when item's "No." is specified on Purchase Return Order's line
        Initialize();

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrder.PurchLines.New();
        PurchaseReturnOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseReturnOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseReturnOrder.Control3."No.".AssertEquals(PurchaseReturnOrder.PurchLines."No.");
    end;

    [Test]
    [HandlerFunctions('GLAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure GenPostingSetupPageSalesCreditMemoAccountLookUpViewAllFalse()
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GenPostingSetupPage: TestPage "General Posting Setup";
        AccountCategory: Option;
        AccountType: Enum "G/L Account Type";
        AccSubcategoryFilter: Text;
        EntryNoFilter: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 369459] "Sales Credit Memo Account" lookup opens G/L Account List with multiple filters when "View All Accounts on Lookup" = False.
        Initialize();

        CreateGenPostingSetupWithViewAllAccountsOnLookUp(GenPostingSetup, false);
        AccountCategory := GLAccountCategory."Account Category"::Income;
        CreateGLAccountCategory(GLAccountCategory, AccountCategory, GLAccountCategoryMgt.GetIncomeProdSales());
        AccountType := GLAccount."Account Type"::Posting;
        CreateGLAccount(GLAccount, AccountType, AccountCategory, GLAccountCategory."Entry No.");

        OpenEditGenPostingSetup(
            GenPostingSetupPage, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
        GenPostingSetupPage."Sales Credit Memo Account".Lookup();

        Assert.AreEqual(AccountType, LibraryVariableStorage.DequeueInteger(), '');
        Assert.AreEqual(AccountCategory, LibraryVariableStorage.DequeueInteger(), '');
        AccSubcategoryFilter := StrSubstNo('%1|%2', GLAccountCategoryMgt.GetIncomeProdSales(), GLAccountCategoryMgt.GetIncomeService());
        GetAccSubcategoryEntryNoFilter(EntryNoFilter, AccountCategory, AccSubcategoryFilter);
        Assert.AreEqual(EntryNoFilter, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure GenPostingSetupPageSalesCreditMemoAccountLookUpViewAllTrue()
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        GenPostingSetupPage: TestPage "General Posting Setup";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 369459] "Sales Credit Memo Account" lookup opens G/L Account List with "Account Type" = Posting filter when "View All Accounts on Lookup" = True.
        Initialize();

        CreateGenPostingSetupWithViewAllAccountsOnLookUp(GenPostingSetup, true);

        OpenEditGenPostingSetup(
            GenPostingSetupPage, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
        GenPostingSetupPage."Sales Credit Memo Account".Lookup();

        Assert.AreEqual(GLAccount."Account Type"::Posting, LibraryVariableStorage.DequeueInteger(), '');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure GenPostingSetupPagePurchaseCreditMemoAccountLookUpViewAllFalse()
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GenPostingSetupPage: TestPage "General Posting Setup";
        AccountCategory: Option;
        AccountType: Enum "G/L Account Type";
        AccSubcategoryFilter: Text;
        EntryNoFilter: Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 369459] "Purchase Credit Memo Account" lookup opens G/L Account List with multiple filters when "View All Accounts on Lookup" = False.
        Initialize();

        CreateGenPostingSetupWithViewAllAccountsOnLookUp(GenPostingSetup, false);
        AccountCategory := GLAccountCategory."Account Category"::"Cost of Goods Sold";
        CreateGLAccountCategory(GLAccountCategory, AccountCategory, GLAccountCategoryMgt.GetCOGSMaterials());
        AccountType := GLAccount."Account Type"::Posting;
        CreateGLAccount(GLAccount, AccountType, AccountCategory, GLAccountCategory."Entry No.");
        AccSubcategoryFilter := StrSubstNo('%1|%2', GLAccountCategoryMgt.GetCOGSMaterials(), GLAccountCategoryMgt.GetCOGSLabor());
        GetAccSubcategoryEntryNoFilter(EntryNoFilter, AccountCategory, AccSubcategoryFilter);

        OpenEditGenPostingSetup(
            GenPostingSetupPage, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
        GenPostingSetupPage."Purch. Credit Memo Account".Lookup();

        Assert.AreEqual(AccountType, LibraryVariableStorage.DequeueInteger(), '');
        Assert.AreEqual(AccountCategory, LibraryVariableStorage.DequeueInteger(), '');
        Assert.AreEqual(EntryNoFilter, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure GenPostingSetupPagePurchaseCreditMemoAccountLookUpViewAllTrue()
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        GenPostingSetupPage: TestPage "General Posting Setup";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 369459] "Purchase Credit Memo Account" lookup opens G/L Account List with "Account Type" = Posting filter when "View All Accounts on Lookup" = True.
        Initialize();

        CreateGenPostingSetupWithViewAllAccountsOnLookUp(GenPostingSetup, true);

        OpenEditGenPostingSetup(
            GenPostingSetupPage, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
        GenPostingSetupPage."Purch. Credit Memo Account".Lookup();

        Assert.AreEqual(GLAccount."Account Type"::Posting, LibraryVariableStorage.DequeueInteger(), '');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLAccountListAccountNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookupGLAccountWithoutCategorySelectsProperRecord()
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 374833] LookupGLAccountWithoutCategory opens G/L Account List with G/L Account selected.
        Initialize();

        GLAccountNo := LibraryERM.CreateGLAccountNo();
        GLAccountCategoryMgt.LookupGLAccountWithoutCategory(GLAccountNo);

        Assert.AreEqual(GLAccountNo, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLAccountListAccountNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookupGLAccountSelectsProperRecord()
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 374833] LookupGLAccount opens G/L Account List with G/L Account selected.
        Initialize();

        GLAccountNo := LibraryERM.CreateGLAccountNo();
        GLAccountCategoryMgt.LookupGLAccount(GLAccountNo, LibraryRandom.RandInt(5), LibraryRandom.RandText(10));

        Assert.AreEqual(GLAccountNo, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT Page Actions & Controls - 2");

        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        IsInitialized := true;

        UpdateNoSeriesOnPurchaseSetup();
        UpdateNoSeriesOnSalesSetup();

        LibraryERM.DisableClosingUnreleasedOrdersMsg();

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
    end;

    local procedure CreateGenPostingSetupWithViewAllAccountsOnLookUp(var GenPostingSetup: Record "General Posting Setup"; ViewAllAccountsOnLookup: Boolean)
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GenPostingSetup);
        GenPostingSetup.Validate("View All Accounts on Lookup", ViewAllAccountsOnLookup);
        GenPostingSetup.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; AccountType: Enum "G/L Account Type"; AccountCategory: Option; AccountCategoryEntryNo: Integer)
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := AccountType;
        GLAccount."Account Category" := "G/L Account Category".FromInteger(AccountCategory);
        GLAccount."Account Subcategory Entry No." := AccountCategoryEntryNo;
        GLAccount.Modify();
    end;

    local procedure CreateGLAccountCategory(var GLAccountCategory: Record "G/L Account Category"; AccountCategory: Option; Description: Text)
    begin
        GLAccountCategory.FindLast();
        GLAccountCategory."Entry No." += 1;
        GLAccountCategory.Init();
        GLAccountCategory."Account Category" := AccountCategory;
        GLAccountCategory.Description := CopyStr(Description, 1, MaxStrLen(GLAccountCategory.Description));
        GLAccountCategory.Insert();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        Commit();
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Purchase Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        Commit();
    end;

    local procedure GetAccSubcategoryEntryNoFilter(var EntryNoFilter: Text; AccountCategory: Option; AccountSubcategoryFilter: Text): Boolean
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Account Category", AccountCategory);
        GLAccountCategory.SetFilter(Description, AccountSubcategoryFilter);
        if GLAccountCategory.IsEmpty() then
            exit(false);
        EntryNoFilter := '';
        GLAccountCategory.FindSet();
        repeat
            EntryNoFilter := EntryNoFilter + Format(GLAccountCategory."Entry No.") + '|';
        until GLAccountCategory.Next() = 0;
        EntryNoFilter := CopyStr(EntryNoFilter, 1, StrLen(EntryNoFilter) - 1);
        exit(true);
    end;

    local procedure OpenEditGenPostingSetup(var GenPostingSetupPage: TestPage "General Posting Setup"; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        GenPostingSetupPage.OpenEdit();
        GenPostingSetupPage.FILTER.SetFilter("Gen. Bus. Posting Group", GenBusPostingGroup);
        GenPostingSetupPage.FILTER.SetFilter("Gen. Prod. Posting Group", GenProdPostingGroup);
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandDecInRange(100, 200, 2));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader,
          SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandDecInRange(100, 200, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure GetDocNofilter(DocumentNo: array[3] of Code[20]): Text
    begin
        exit(StrSubstNo('%1..%2', DocumentNo[1], DocumentNo[3]));
    end;

    local procedure GetExpectedDateFilter(): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Date Filter", 0D, WorkDate());
        exit(SalesHeader.GetFilter("Date Filter"));
    end;

    local procedure UpdateNoSeriesOnSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateNoSeriesOnPurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountListModalPageHandler(var GLAccountList: TestPage "G/L Account List")
    begin
        LibraryVariableStorage.Enqueue(GLAccountList.FILTER.GetFilter("Account Type"));
        LibraryVariableStorage.Enqueue(GLAccountList.FILTER.GetFilter("Account Category"));
        LibraryVariableStorage.Enqueue(GLAccountList.FILTER.GetFilter("Account Subcategory Entry No."));
        GLAccountList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountListAccountNoModalPageHandler(var GLAccountList: TestPage "G/L Account List")
    begin
        LibraryVariableStorage.Enqueue(GLAccountList."No.".Value);
        GLAccountList.Cancel().Invoke();
    end;
}

