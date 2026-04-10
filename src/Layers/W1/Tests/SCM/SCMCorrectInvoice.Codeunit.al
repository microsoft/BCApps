codeunit 137019 "SCM Correct Invoice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Sales]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ItemTrackingMode: Option "Assign Lot","Verify Lot";
        IsInitialized: Boolean;
        WasConfirmShown: Boolean;
        CancelledDocExistsErr: Label 'Cancelled document exists.';
        CannotAssignNumbersAutoErr: Label 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate Default Nos.';
        CommentCountErr: Label 'Wrong Sales Line Count';
        ConfirmDialogErr: Label 'Expected confirm dialog was not shown';

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceCostReversing()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        Vend: Record Vendor;
        SalesHeaderCorrection: Record "Sales Header";
        LastItemLedgEntry: Record "Item Ledger Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        LastItemLedgEntry.FindLast();
        Assert.AreEqual(-1, LastItemLedgEntry."Shipped Qty. Not Returned", '');

        // EXERCISE
        TurnOffExactCostReversing();
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY: The correction must use Exact Cost reversing
        LastItemLedgEntry.Find();
        Assert.AreEqual(
          0, LastItemLedgEntry."Shipped Qty. Not Returned",
          'The quantity on the shipment item ledger should appear as returned');

        CheckEverythingIsReverted(Item, Cust, GLEntry);

        // VERIFY: Check exact reversing work even when new costs are introduced
        LibraryPurch.CreateVendor(Vend);
        CreateAndPostPurchInvForItem(Vend, Item, 1, 1);

        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceGLAccount()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibrarySales: Codeunit "Library - Sales";
    begin
        Initialize();

        CreateSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesHeader, SalesLine);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", 1);
        SalesLine.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate(Type, SalesLine.Type::" ");
        SalesLine.Validate(Description, 'Blank line');
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        GLEntry.FindLast();

        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);

        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingDateInvtBlocked()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        InvtPeriod: Record "Inventory Period";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();

        CreateItemWithPrice(Item, 0);

        LibraryPurch.CreateVendor(Vend);
        CreateAndPostPurchInvForItem(Vend, Item, 1, 1);

        LibrarySales.CreateCustomer(Cust);
        SellItem(Cust, Item, 1, SalesInvoiceHeader);

        LibraryCosting.AdjustCostItemEntries('', '');

        InvtPeriod.Init();
        InvtPeriod."Ending Date" := CalcDate('<+1D>', WorkDate());
        InvtPeriod.Closed := true;
        InvtPeriod.Insert();
        Commit();

        GLEntry.FindLast();

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);
        InvtPeriod.Delete();
        Commit();

        CheckNothingIsCreated(Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetShptInvoiceFromOrder()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        SalesGetShpt: Codeunit "Sales-Get Shipment";
    begin
        Initialize();

        CreateItemWithPrice(Item, 1);
        LibrarySales.CreateCustomer(Cust);

        // It should not be possible to cancel a get shipment invoice that is associated to an order
        CreateSalesOrderForItem(Cust, Item, 1, SalesHeader, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesShptLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShptLine.SetRange("Order Line No.", SalesLine."Line No.");
        SalesShptLine.FindFirst();

        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        SalesGetShpt.SetSalesHeader(SalesHeader);
        SalesGetShpt.CreateInvLines(SalesShptLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        Commit();

        GLEntry.FindLast();

        // EXERCISE (TFS ID: 306797)
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);

        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemTracking()
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Customer: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderCorrection: Record "Sales Header";
        ReservEntry: Record "Reservation Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        InvoiceNo: Code[20];
    begin
        Initialize();

        CreateItemWithPrice(Item, 0);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), Item."No.", 1, '', 0D);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservEntry, PurchaseLine, '', 'LOT1', 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLEntry.FindLast();

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), Item."No.", 1, '', 0D);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, SalesLine, '', 'LOT1', 1);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(InvoiceNo);
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CheckEverythingIsReverted(Item, Customer, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobNo()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Job: Record Job;
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize();

        CreateSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesHeader, SalesLine);

        LibraryJob.CreateJob(Job);
        SalesLine.Validate("Job No.", Job."No.");
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // CHECK IT NOT BE POSSIBLE TO REVERT A JOBS RELATED INVOICE
        GLEntry.FindLast();
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceAfterApplyUnapplyToCreditMemo()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 168492] Corrective Credit Memo is generated when there are other credit memos applied and unapplied to invoice before cancellation

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] Unapplied Credit Memo "B"
        PostApplyUnapplyCreditMemoToInvoice(SalesInvHeader);
        SalesCrMemoHeader.SetRange("Bill-to Customer No.", SalesInvHeader."Bill-to Customer No.");
        SalesCrMemoHeader.FindLast();
        Commit();

        // [WHEN] Cancel Posted Invoice "A"
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);

        // [THEN] Corrective Credit Memo "C" is generated
        NewSalesCrMemoHeader.SetRange("Bill-to Customer No.", SalesInvHeader."Bill-to Customer No.");
        NewSalesCrMemoHeader.FindLast();

        // [THEN] Cancelled Document is generated (Invoice = "A", "Credit Memo" = "C")
        CancelledDocument.Get(DATABASE::"Sales Invoice Header", SalesInvHeader."No.");
        CancelledDocument.TestField("Cancelled By Doc. No.", NewSalesCrMemoHeader."No.");

        // [THEN] No Cancelled Document with "Credit Memo" = "B"
        Assert.IsFalse(
          CancelledDocument.FindSalesCorrectiveCrMemo(SalesCrMemoHeader."No."), CancelledDocExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoInvoiceRoundingWhenCorrectInvoice()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 169199] No invoice rounding is assigned to new Invoice when correct original invoice

        Initialize();
        // [GIVEN] "Invoice Rounding Precision" is 1.00 in "General Ledger Setup" and On in Sales & Receivables Setup
        SetInvoiceRounding();

        // [GIVEN] Posted Invoice "A" with total amount = 100 (Amount Including VAT is 99.98, Invoice Rounding Line is 0.02)
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 99.98, 1, SalesInvHeader);
        LibrarySmallBusiness.UpdateInvRoundingAccountWithSalesSetup(
          SalesInvHeader."Customer Posting Group", SalesInvHeader."Gen. Bus. Posting Group");
        ExpectedAmount := GetAmountInclVATOfSalesInvLine(SalesInvHeader);
        LibraryLowerPermissions.SetSalesDocsPost();
        Commit();

        // [WHEN] Correct Posted Invoice "A" with new Invoice "B"
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvHeader, SalesHeader);

        // [THEN] "Amount Including VAT" of Invoice "B" is 99.98
        SalesHeader.CalcFields("Amount Including VAT");
        SalesHeader.TestField("Amount Including VAT", ExpectedAmount);

        // [THEN] Invoice Rounding Line does not exist in Invoice "B"
        VerifyInvRndLineDoesNotExistInSalesHeader(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveCrMemoIsRoundedWhenCancelInvoice()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 169199] Corrective Credit Memo is rounded according to "Inv. Rounding Precision" when cancel Invoice

        Initialize();
        // [GIVEN] "Invoice Rounding Precision" is 1.00 in "General Ledger Setup" and On in Sales & Receivables Setup
        SetInvoiceRounding();

        // [GIVEN] Posted Invoice "A" with total amount = 100 (Amount Including VAT is 99.98, Invoice Rounding Line is 0.02)
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 99.98, 1, SalesInvHeader);
        LibrarySmallBusiness.UpdateInvRoundingAccountWithSalesSetup(
          SalesInvHeader."Customer Posting Group", SalesInvHeader."Gen. Bus. Posting Group");
        SalesInvHeader.CalcFields("Amount Including VAT");
        LibraryLowerPermissions.SetSalesDocsPost();
        Commit();

        // [WHEN] Cancel Posted Invoice "A" with Corrective Credit Memo "B"
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);

        // [THEN] "Amount Including VAT" of Credit Memo "B" is 100
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        SalesCrMemoHeader.TestField("Amount Including VAT", SalesInvHeader."Amount Including VAT");

        // [THEN] Invoice Rounding Line exists in Invoice "B"
        VerifyInvRndLineExistsInSalesCrMemoHeader(SalesCrMemoHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PossibleToCorrectInvoiceWithManuallyInsertedInvRndAccount()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        InvRndAccountNo: Code[20];
        OldInvRndAccountNo: Code[20];
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 169199] It is possible to correct Invoice with manually inserted "Invoice Rounding Account"

        Initialize();

        // [GIVEN] No automtic invoice rounding, and an invoice with a manually added invoice rounding account
        LibrarySales.SetInvoiceRounding(false);
        LibrarySales.CreateCustomer(Cust);
        CreateSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesHeader, SalesLine);
        InvRndAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        OldInvRndAccountNo :=
          UpdateInvRndAccountInCustPostingGroup(SalesHeader."Customer Posting Group", InvRndAccountNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", InvRndAccountNo, 1);
        SalesLine.Validate("Unit Price", 1);
        SalesLine.Modify(true);
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel Posted Invoice
        LibraryLowerPermissions.SetSalesDocsPost();
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);

        // [THEN] Credit memo of cancelled invoice has same Amount Including VAT
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        SalesInvHeader.CalcFields("Amount Including VAT");
        SalesCrMemoHeader.TestField("Amount Including VAT", SalesInvHeader."Amount Including VAT");

        // [THEN] Invoice Rounding Line exists in Credit Memo
        VerifyInvRndLineExistsInSalesCrMemoHeader(SalesCrMemoHeader);

        // Tear down
        UpdateInvRndAccountInCustPostingGroup(SalesHeader."Customer Posting Group", OldInvRndAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCorrectiveCrMemoFromPostedSalesInvoicePage()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Credit Memo" on page "Posted Sales Invoice" open Corrective Credit Memo when called from canceled Sales Invoice

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] Canceled Posted Invoice "A" with corrective Credit Memo "B"
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Opened page "Posted Sales Invoice" with Invoice "A"
        PostedSalesCreditMemo.Trap();
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Credit Memo"
        PostedSalesInvoice.ShowCreditMemo.Invoke();

        // [THEN] "Posted Sales Credit Memo" page with Credit Memo "B" is opened
        PostedSalesCreditMemo."No.".AssertEquals(SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCorrectiveCrMemoFromPostedSalesInvoicesPage()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Credit Memo" on page "Posted Sales Invoices" open Corrective Credit Memo when called from canceled Sales Invoice

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] Canceled Posted Invoice "A" with corrective Credit Memo "B"
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Opened page "Posted Sales Invoices" with Invoice "A"
        PostedSalesCreditMemo.Trap();
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.FILTER.SetFilter("No.", SalesInvHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Credit Memo"
        PostedSalesInvoices.ShowCreditMemo.Invoke();

        // [THEN] "Posted Sales Credit Memo" page with Credit Memo "B" is opened
        PostedSalesCreditMemo."No.".AssertEquals(SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCanceledInvoiceFromPostedSalesCrMemoPage()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Invoice" on page "Posted Sales Credit Credit Memo" open canceled Invoice when called from corrective Credit Memo

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] Canceled Posted Invoice "A" with corrective Credit Memo "B"
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Opened page "Posted Sales Credit Memo" with Credit Memo "B"
        PostedSalesInvoice.Trap();
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Invoice"
        PostedSalesCreditMemo.ShowInvoice.Invoke();

        // [THEN] "Posted Sales Invoice" page with Invoice "A" is opened
        PostedSalesInvoice."No.".AssertEquals(SalesInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCanceledInvoiceFromPostedSalesCrMemosPage()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Invoice" on page "Posted Sales Credit Memos" open canceled Invoice when called from corrective Credit Memo

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] Canceled Posted Invoice "A" with corrective Credit Memo "B"
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Opened page "Posted Sales Credit Memos" with Credit Memo "B"
        PostedSalesInvoice.Trap();
        PostedSalesCreditMemos.OpenView();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Invoice"
        PostedSalesCreditMemos.ShowInvoice.Invoke();

        // [THEN] "Posted Sales Invoice" page with Invoice "A" is opened
        PostedSalesInvoice."No.".AssertEquals(SalesInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDescriptionLineWithCancelledInvNoInNewInvoice()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 171281] There is no blank line with description about copied-from document when correct Sales Invoice

        Initialize();
        // [GIVEN] Posted Sales Invoice "A"
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [WHEN] Correct Sales Invoice "A" with new Sales Invoice "B"
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvHeader, SalesHeader);

        // [THEN] No description line in Sales Invoice "B"
        VerifyBlankLineDoesNotExist(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithNonDefaultNoSeriesWithRelation()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        RelatedNoSeriesLine: Record "No. Series Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibraryNoSeries: Codeunit "Library - No. Series";
        ExpectedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Corrective Credit Memo] [No. Series]
        // [SCENARIO 210983] Stan can select no. series for Corrective Credit Memo if no. series from "Credit Memo Nos." in Sales Setup is not "Default Nos" and has relations

        Initialize();

        // [GIVEN] Posted Invoice
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] No. Series "Y" with "Default Nos" = Yes and no. series line setup
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(RelatedNoSeriesLine, RelatedNoSeries.Code, '', '');
        LibraryVariableStorage.Enqueue(RelatedNoSeries.Code);
        ExpectedCrMemoNo := LibraryUtility.GetNextNoFromNoSeries(RelatedNoSeries.Code, WorkDate());

        // [GIVEN] No. Series "X" with "Default Nos" = No and related No. series "Y". Next "No." in no. series is "X1"
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);

        // [GIVEN] "Credit Memo Nos." in Sales Setup is "X"
        SetCreditMemoNosInSalesSetup(NoSeries.Code);

        // [WHEN] Create Corrective Credit Memo for Sales Invoice "A" and specify "No. Series" = "Y" from "No. Series" page
        // No. Series selection handles by NoSeriesListModalPageHandler
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvHeader, SalesHeader);

        // [THEN] Corrective Credit Memo created with "No." = "X1"
        SalesHeader.TestField("No.", ExpectedCrMemoNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithDefaultNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        ExpectedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Corrective Credit Memo] [No. Series]
        // [SCENARIO 210983]  Corrective Credit Memo posts with default no. series from "Credit Memo Nos." in Sales Setup

        Initialize();

        // [GIVEN] Posted Invoice
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] Next no. in no. series "Credit Memo Nos." of Sales Setup is "X1"
        SalesReceivablesSetup.Get();
        ExpectedCrMemoNo := LibraryUtility.GetNextNoFromNoSeries(SalesReceivablesSetup."Credit Memo Nos.", WorkDate());

        // [WHEN] Create Corrective Credit Memo for Sales Invoice "A"
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvHeader, SalesHeader);

        // [THEN] Corrective Credit Memo created with "No." = "X1"
        SalesHeader.TestField("No.", ExpectedCrMemoNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithNonDefaultNoSeriesWithoutRelation()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        NoSeries: Record "No. Series";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Corrective Credit Memo] [No. Series]
        // [SCENARIO 210983] Error message is thrown when create Corrective Credit Memo if no. series from "Credit Memo Nos." in Sales Setup is not "Default Nos" and has no relations

        Initialize();

        // [GIVEN] Posted Invoice
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] No. Series "X" with "Default Nos" = No
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);

        // [GIVEN] "Credit Memo Nos." in Sales Setup is "X"
        SetCreditMemoNosInSalesSetup(NoSeries.Code);

        // [WHEN] Create Corrective Credit Memo for Sales Invoice "A"
        asserterror CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvHeader, SalesHeader);

        // [THEN] Error message 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate Default Nos.' is thrown
        Assert.ExpectedError(CannotAssignNumbersAutoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithNonDefaultNoSeriesWithRelationCancelSeriesSelection()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        NoSeries: Record "No. Series";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Corrective Credit Memo] [No. Series]
        // [SCENARIO 210983] Error message is thrown when create Corrective Credit Memo if no. series from "Credit Memo Nos." in Sales Setup is not "Default Nos" and has relations but No. Series is not selected from the list of series.

        Initialize();

        // [GIVEN] Posted Invoice
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] No. Series "X" with "Default Nos" = No and related No. series "Y". Next "No." in no. series is "X1"
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);

        // [GIVEN] "Credit Memo Nos." in Sales Setup is "X"
        SetCreditMemoNosInSalesSetup(NoSeries.Code);

        // [WHEN] Create Corrective Credit Memo for Sales Invoice "A" and do not specify any no. series from "No. Series" page
        // No. Series selection cancellation handles by NoSeriesListSelectNothingModalPageHandler
        asserterror CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvHeader, SalesHeader);

        // [THEN] Error message 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate Default Nos.' is thrown
        Assert.ExpectedError(CannotAssignNumbersAutoErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AssignLotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeLineWithTrackingCopiedToCorrCrMemo()
    var
        SalesHeaderCorrection: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        ItemNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [Corrective Credit Memo] [Item Tracking] [Exact Cost Reversing Mandatory]
        // [SCENARIO 210894] Negative Line of Posted Sales Invoice with Lot Tracking copies to Corrective Credit Memo

        Initialize();

        // [GIVEN] Item with Lot Tracking
        ItemNo := CreateTrackedItem();

        // [GIVEN] Posted Sales Invoice with Quantity = - 1 and "Lot No."
        PostSalesInvWithNegativeLineAndLotNo(InvNo, SalesLine, ItemNo);
        SalesInvoiceHeader.Get(InvNo);

        // [WHEN] Create Corrective Credit Memo for Posted Sales Invoice
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeaderCorrection);

        // [THEN] Credit Memo created with Quantity = -1 and "Lot No."
        VerifySalesLineWithTrackedQty(SalesHeaderCorrection, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('AssignLotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeLineWithTrackingCopiedWithExactCostRevMandatory()
    var
        SalesHeaderCorrection: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Exact Cost Reversing Mandatory]
        // [SCENARIO 210894] Negative Line of Posted Sales Invoice with Lot Tracking copies to Credit Memo when "Exact Cost Reversing Mandatory" is set

        Initialize();

        // [GIVEN] Item with Lot Tracking
        ItemNo := CreateTrackedItem();

        // [GIVEN] Posted Sales Invoice with Quantity = - 1 and "Lot No."
        PostSalesInvWithNegativeLineAndLotNo(InvNo, SalesLine, ItemNo);

        // [GIVEN] "Exact Cost Reversing Mandatory" is set
        LibrarySales.SetExactCostReversingMandatory(true);

        // [GIVEN] Sales Credit Memo
        LibrarySales.CreateSalesHeader(
          SalesHeaderCorrection, SalesHeaderCorrection."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.");

        // [WHEN]  Copy Posted Sales Invoice to Sales Credit Memo
        LibrarySales.CopySalesDocument(SalesHeaderCorrection, "Sales Document Type From"::"Posted Invoice", InvNo, true, false);

        // [THEN] Credit Memo created with Quantity = -1 and "Lot No."
        VerifySalesLineWithTrackedQty(SalesHeaderCorrection, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SetLotItemWithQtyToHandleTrackingPageHandler')]
    procedure CancelSalesInvoiceFromOrderWithItemTracking()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        QtyToShip: Decimal;
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 387956] Item Tracking Lines for the original Sales Order Lines have "Qty. Handled (Base)" and "Qty. Invoiced (Base)" values reverted when canceling Posted Sales Invoice
        Initialize();

        // [GIVEN] Item with Lot Tracking
        Item.Get(CreateTrackedItem());

        //[GIVEN] 15 PCS of Item with Lot No. = "L" in Inventory
        LotNo := LibraryUtility.GenerateGUID();
        QtyToShip := LibraryRandom.RandDec(10, 2);
        PostPositiveAdjmtWithLotNo(Item."No.", LotNo, 3 * QtyToShip);

        // [GIVEN] Sales Order for 15 PCS of the Item, with "Qty. to Ship" = "Qty. to Invoice" = 5 PCS
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrderForItem(Customer, Item, 3 * QtyToShip, SalesHeader, SalesLine);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        // [GIVEN] Item Tracking Line for Lot "L", Quantity = "Qty. to Handle" = 5 PCS
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyToShip);
        LibraryVariableStorage.Enqueue(QtyToShip);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Sales Order posted with Ship and Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel the Posted Sales Invoice 
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Item Tracking for the original Sales Order has "Quantity Handled (Base)" = 0
        SalesLine.Find();
        TrackingSpecification.SetSourceFilter(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.",
            SalesLine."Line No.", false);
        Assert.RecordIsEmpty(TrackingSpecification);

        // [THEN] Item Tracking for the original Sales Order has "Quantity Invoiced (Base)" = 0
        ReservationEntry.SetSourceFilter(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.",
            SalesLine."Line No.", false);
        ReservationEntry.FindFirst();
        Assert.AreEqual(ReservationEntry."Quantity Invoiced (Base)", 0, 'Quantity Invoiced must be 0.');

        // [THEN] The Sales Order can be posted again
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SetLotItemWithQtyToHandleTrackingPageHandler')]
    procedure CancelSalesInvoiceCreatedViaGetShipmentLinesWithItemTracking()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesHeaderInvoice: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LotNos: array[2] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Get Shipment Lines]
        // [SCENARIO 400516] Restore item tracking in the original sales order when the invoice is created via "Get Shipment Lines" and then canceled.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Item.Get(CreateTrackedItem());

        // [GIVEN] Post two lots to inventory.
        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            PostPositiveAdjmtWithLotNo(Item."No.", LotNos[i], LibraryRandom.RandInt(10));
        end;

        // [GIVEN] Sales order.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");

        // [GIVEN] Add two sales lines, quantity = 1, assign lot no.
        for i := 1 to ArrayLen(SalesLine) do begin
            LibrarySales.CreateSalesLineWithUnitPrice(
                SalesLine[i], SalesHeader, Item."No.", LibraryRandom.RandDec(10, 2), 1);
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(SalesLine[i].Quantity);
            LibraryVariableStorage.Enqueue(SalesLine[i].Quantity);
            SalesLine[i].OpenItemTrackingLines();
        end;

        // [GIVEN] Ship the sales order.
        SalesShipmentHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, false));

        // [GIVEN] Create sales invoice using "Get Shipment Lines".
        // [GIVEN] Post the invoice.
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, "Sales Document Type"::Invoice, Customer."No.");
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true));

        // [WHEN] Cancel the posted invoice.
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Item tracking is restored in the original sales order.
        // [THEN] "Quantity Handled" = "Quantity Invoiced" = 0 in item tracking for each sales line.
        for i := 1 to ArrayLen(SalesLine) do begin
            SalesLine[i].Find();
            TrackingSpecification.SetSourceFilter(
                Database::"Sales Line", SalesLine[i]."Document Type".AsInteger(), SalesLine[i]."Document No.",
                SalesLine[i]."Line No.", false);
            Assert.RecordIsEmpty(TrackingSpecification);

            ReservationEntry.SetSourceFilter(
                Database::"Sales Line", SalesLine[i]."Document Type".AsInteger(), SalesLine[i]."Document No.",
                SalesLine[i]."Line No.", false);
            ReservationEntry.FindFirst();
            ReservationEntry.TestField("Quantity Invoiced (Base)", 0);
        end;

        // [THEN] The purchase order can be posted again.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CancelSalesInvoiceCreatedViaGetShipmentLinesWithLocationRequireWhseShipment()
    var
        ItemNo: Code[20];
        LocationCode: Code[10];
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Whse Shipment] [Get Shipment Lines] [Cancel Posted Sales Invoice]
        // [SCENARIO 464072] Post again sales order when the invoice is created via "Get Shipment Lines" and then canceled when Whse. Shipment is mandatory for location.
        Initialize();

        // [GIVEN] Item, available on location with "Require Shipment"
        ItemNo := LibraryInventory.CreateItemNo();
        CreateLocationWithRequireShip(LocationCode);
        PostItemJournalPositiveAdj(ItemNo, LocationCode, LibraryRandom.RandDec(10, 0));

        // [GIVEN] Sales order.        
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, LibrarySales.CreateCustomerNo(), LocationCode);

        // [GIVEN] Add sales line, quantity = 1        
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, ItemNo, LibraryRandom.RandDec(10, 2), 1);

        // [GIVEN] Release sales order        
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create WhseShipment and post (ship only)
        CreateAndPostWhseShipment(SalesHeader, false);

        // [GIVEN] Create sales invoice using "Get Shipment Lines" and post it
        CreateInvoiceWithGetShipmentLineAndPostIt(SalesHeader, SalesInvoiceHeader);

        // [WHEN] Cancel the posted invoice.
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] The sales order can be posted again.
        VerifySalesOrderCouldBeProcessedAgain(SalesHeader, SalesLine);
    end;

    local procedure CreateLocationWithRequireShip(var LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
    end;

    local procedure PostItemJournalPositiveAdj(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJnlLine(
          ItemJournalLine, "Item Ledger Entry Type"::"Positive Adjmt.", Today, ItemNo, Quantity, LocationCode);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJournalLine);
    end;

    local procedure CreateAndPostWhseShipment(var SalesHeader: Record "Sales Header"; DoInvoice: Boolean)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
            LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
                DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, DoInvoice);
    end;

    local procedure CreateInvoiceWithGetShipmentLineAndPostIt(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeaderInvoice: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentHeader.SetCurrentKey("Order No.");
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindLast();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, "Sales Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true));
    end;

    local procedure VerifySalesOrderCouldBeProcessedAgain(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesHeader.Find();
        SalesLine.Find();
        SalesLine.TestField("Qty. to Ship", 0);  //as whse shipment reqired
        CreateAndPostWhseShipment(SalesHeader, false);
    end;

    [Test]
    [HandlerFunctions('SetOrVerifyLotItemTrackingLinesModalPageHandler')]
    procedure CancelInvoiceOneLotFullyShippedPartiallyInvoiced()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LotNo: Code[50];
        Qty: Decimal;
        QtyToInvoice: Decimal;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 432890] Reverting item tracking when cancelling a partial invoice for sales order line.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandIntInRange(11, 20);
        QtyToInvoice := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Post inventory adjustment for 6 pcs of lot "L".
        Item.Get(CreateTrackedItem());
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, '', LotNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order for 6 pcs, select lot "L".
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(10, 2), Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot");
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Post the sales order as "Ship".
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set "Qty. to Invoice" = 5.
        // [GIVEN] Post the sales order as "Invoice".
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
        SalesHeader.Find();
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Cancel the posted sales invoice.
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Check the item tracking for the sales order:
        // [THEN] Quantity = 6, "Qty. to Handle" = 5 (6 shipped and 5 reverted), "Qty. to Invoice" = 6 (6 invoiced and cancelled)
        SalesLine.Find();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Verify Lot");
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(QtyToInvoice);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines();

        // [THEN] The sales order can be shipped and invoiced again.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure NoDuplicateCommentLineWhenUsingCorrectiveCreditMemoOnPostedSalesInv()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        SalesGetShpt: Codeunit "Sales-Get Shipment";
    begin
        // [SCENARIO 456470] Duplicate comment lines in Sales/Purchase Credit Memo when created by Corrective Credit Memo
        Initialize();

        // [GIVEN] Create a Item with a Price
        CreateItemWithPrice(Item, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create a Customer
        LibrarySales.CreateCustomer(Cust);

        // [GIVEN] Create a Sales Order
        CreateSalesOrderForItem(Cust, Item, 1, SalesHeader, SalesLine);

        // [GIVEN] Post a Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Select a Sales Shipment Line
        SalesShptLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShptLine.SetRange("Order Line No.", SalesLine."Line No.");
        SalesShptLine.FindFirst();

        // [GIVEN] Create a Sales Invoice for selected Sales Shipment Line
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        SalesGetShpt.SetSalesHeader(SalesHeader);
        SalesGetShpt.CreateInvLines(SalesShptLine);

        // [GIVEN] Post the Sales Invoice 
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        //Commit();

        // [WHEN] Correct the posted Sales Invoice
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeaderCorrection);

        // [THEN] Two Comments Lines should be created in the Sales Line.
        CheckCommentsOnCreditLine(SalesHeaderCorrection);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CheckCorrectiveCreditMemoConfirmDialogOnPostedSalesInv()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeaderCorrection: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 578461] Message when using "Create corrective Credit Memo" on a partial sales or purchase invoice related to an 
        // existing Order needs to inform that the Order Quantities will be changed.
        Initialize();

        // [GIVEN] Create a Item with a Price
        CreateItemWithPrice(Item, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create a Customer
        LibrarySales.CreateCustomer(Cust);

        // [GIVEN] Create a Sales Order
        CreateSalesOrderForItem(Cust, Item, 10, SalesHeader, SalesLine);
        SalesLine.Validate("Qty. to Ship", 5);
        SalesLine.Modify(true);

        // [GIVEN] Post a Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Get Posted Sales Invoice. 
        GetPostedInvoice(SalesInvoiceHeader, SalesHeader);

        // [WHEN] Correct the posted Sales Invoice.
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeaderCorrection);

        // [THEN] Assert that confirm was called.
        Assert.IsTrue(WasConfirmShown, ConfirmDialogErr);
    end;

    [Test]
    procedure CancelSalesInvoiceWithLocationRequireWhseShipmentHavingZeroQuantity()
    var
        ItemNo: Code[20];
        LocationCode: Code[10];
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 596983] Stan can cancel or correct this Posted Sales Invoice with Warehouse Receive is not required for Line without quantity when canceling Sales Invoice.
        Initialize();

        // [GIVEN] Create an Item.
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Create a Location with "Require Shipment" = true.
        CreateLocationWithRequireShip(LocationCode);

        // [GIVEN] Post positive adjustment for the Item.
        PostItemJournalPositiveAdj(ItemNo, '', LibraryRandom.RandDec(10, 0));

        // [GIVEN]  Create a Sales Order.       
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, LibrarySales.CreateCustomerNo(), '');

        // [GIVEN] Create a Sales Line for an Item.
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, ItemNo, LibraryRandom.RandDec(10, 2), LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Create a Sales Line with Unit Price = 0 and Quantity = 0 and Validate "Location Code".
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, LibraryInventory.CreateItemNo(), 0, 0);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);

        // [GIVEN] Release sales order        
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Post the Sales Order as "Ship" and "Invoice".
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel the Posted Sales Invoice.
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] The Sales Invoice is Cancled without an error.
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesInvoiceHeader."Sell-to Customer No.");
        SalesCrMemoHeader.SetRange(Corrective, true);
        Assert.RecordIsNotEmpty(SalesCrMemoHeader);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Correct Invoice");
        // Initialize setup.
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Correct Invoice");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();

        // fix No. Series setup
        SetGlobalNoSeriesInSetups();

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Correct Invoice");
    end;

    local procedure SetGlobalNoSeriesInSetups()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        MarketingSetup: Record "Marketing Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        //        SalesReceivablesSetup."Posted Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify();

        MarketingSetup.Get();
        MarketingSetup."Contact Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        MarketingSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Vendor Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify();

        WarehouseSetup.Get();
        WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup.Modify();
    end;

    local procedure CreateItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify();
    end;

    local procedure SellItem(SellToCust: Record Customer; Item: Record Item; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesInvoiceForItem(SellToCust, Item, Qty, SalesHeader, SalesLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvForNewItemAndCust(var Item: Record Item; var Cust: Record Customer; UnitPrice: Decimal; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CreateItemWithPrice(Item, UnitPrice);
        LibrarySales.CreateCustomer(Cust);
        SellItem(Cust, Item, Qty, SalesInvoiceHeader);
    end;

    local procedure CreateSalesInvForNewItemAndCust(var Item: Record Item; var Cust: Record Customer; UnitPrice: Decimal; Qty: Decimal; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        CreateItemWithPrice(Item, UnitPrice);
        LibrarySales.CreateCustomer(Cust);
        CreateSalesInvoiceForItem(Cust, Item, Qty, SalesHeader, SalesLine);
    end;

    local procedure CreateSalesInvoiceForItem(Cust: Record Customer; Item: Record Item; Qty: Decimal; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
    end;

    local procedure CreateSalesOrderForItem(Cust: Record Customer; Item: Record Item; Qty: Decimal; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
    end;

    local procedure CreateAndPostPurchInvForItem(Vend: Record Vendor; Item: Record Item; UnitCost: Decimal; Qty: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vend."No.");
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", Qty);
        PurchLine.Validate("Unit Cost", UnitCost);
        PurchLine.Modify(true);
        LibraryPurch.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure PostPositiveAdjmtWithLotNo(ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, ItemNo, '', '', Quantity);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostSalesInvWithNegativeLineAndLotNo(var InvNo: Code[20]; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, -1);
        SalesLine.OpenItemTrackingLines();
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure TurnOffExactCostReversing()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Exact Cost Reversing Mandatory", false);
        SalesSetup.Modify(true);
        Commit();
    end;

    local procedure SetInvoiceRounding()
    begin
        LibraryERM.SetInvRoundingPrecisionLCY(1);
        LibrarySales.SetInvoiceRounding(true);
    end;

    local procedure SetCreditMemoNosInSalesSetup(NoSeriesCode: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Memo Nos.", NoSeriesCode);
        SalesReceivablesSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PostApplyUnapplyCreditMemoToInvoice(SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        InvNo: Code[20];
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Insert(true);
        CopyDocMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", SalesInvHeader."No.", SalesHeader);
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::"Credit Memo", InvNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);
    end;

    local procedure GetAmountInclVATOfSalesInvLine(SalesInvoiceHeader: Record "Sales Invoice Header"): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        exit(SalesInvoiceLine."Amount Including VAT");
    end;

    local procedure UpdateInvRndAccountInCustPostingGroup(CustPostingGroupCode: Code[20]; GLAccNo: Code[20]) OldInvRndAccNo: Code[20]
    var
        CustPostingGroup: Record "Customer Posting Group";
    begin
        CustPostingGroup.Get(CustPostingGroupCode);
        OldInvRndAccNo := CustPostingGroup."Invoice Rounding Account";
        CustPostingGroup.Validate("Invoice Rounding Account", GLAccNo);
        CustPostingGroup.Modify(true);
    end;

    local procedure VerifyInvRndLineDoesNotExistInSalesHeader(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("No.", LibrarySales.GetInvRoundingAccountOfCustPostGroup(SalesHeader."Customer Posting Group"));
        Assert.RecordIsEmpty(SalesLine);
    end;

    local procedure VerifyInvRndLineExistsInSalesCrMemoHeader(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::"G/L Account");
        SalesCrMemoLine.SetRange("No.", LibrarySales.GetInvRoundingAccountOfCustPostGroup(SalesCrMemoHeader."Customer Posting Group"));
        Assert.RecordIsNotEmpty(SalesCrMemoLine);
    end;

    local procedure VerifyBlankLineDoesNotExist(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        Assert.RecordIsEmpty(SalesLine);
    end;

    local procedure CheckSomethingIsPosted(Item: Record Item; Cust: Record Customer)
    begin
        // Inventory should go back to zero
        Item.CalcFields(Inventory);
        Assert.IsTrue(Item.Inventory < 0, '');

        // Customer balance should go back to zero
        Cust.CalcFields(Balance);
        Assert.IsTrue(Cust.Balance > 0, '');
    end;

    local procedure CheckEverythingIsReverted(Item: Record Item; Cust: Record Customer; LastGLEntry: Record "G/L Entry")
    var
        CustPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        ValueEntry: Record "Value Entry";
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalCost: Decimal;
        TotalQty: Decimal;
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.SetRange("Source No.", Cust."No.");
        ValueEntry.FindSet();
        repeat
            TotalQty += ValueEntry."Item Ledger Entry Quantity";
            TotalCost += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreEqual(0, TotalQty, '');
        Assert.AreEqual(0, TotalCost, '');

        // Customer balance should go back to zero
        Cust.CalcFields(Balance);
        Assert.AreEqual(0, Cust.Balance, '');

        CustPostingGroup.Get(Cust."Customer Posting Group");
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntry."Entry No.");
        GLEntry.FindSet();
        repeat
            TotalDebit += GLEntry."Credit Amount";
            TotalCredit += GLEntry."Debit Amount";
        until GLEntry.Next() = 0;

        Assert.AreEqual(TotalDebit, TotalCredit, '');
    end;

    local procedure CheckNothingIsCreated(Cust: Record Customer; LastGLEntry: Record "G/L Entry")
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.IsTrue(LastGLEntry.Next() = 0, 'No new G/L entries are created');
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("Bill-to Customer No.", Cust."No.");
        Assert.IsTrue(SalesHeader.IsEmpty, 'The Credit Memo should not have been created');
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        exit(Item."No.");
    end;

    local procedure VerifySalesLineWithTrackedQty(SalesHeader: Record "Sales Header"; ExpectedQty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.TestField(Quantity, ExpectedQty);
        LibraryInventory.VerifyReservationEntryWithLotExists(
          DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(),
          SalesHeader."No.", SalesLine."Line No.", SalesLine."No.", SalesLine.Quantity);
    end;

    local procedure CheckCommentsOnCreditLine(SalesHeaderCorrection: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesLineCount: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeaderCorrection."No.");
        SalesLine.SetFilter(Type, '%1', SalesLine.Type::" ");
        SalesLineCount := SalesLine.Count();
        Assert.AreEqual(2, SalesLineCount, CommentCountErr);
    end;

    local procedure GetPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        NoSeriesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignLotItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SetLotItemWithQtyToHandleTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SetOrVerifyLotItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::"Assign Lot":
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Qty. to Invoice (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingMode::"Verify Lot":
                begin
                    ItemTrackingLines.Filter.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Qty. to Invoice (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        WasConfirmShown := true;
        Reply := true;
    end;
}

