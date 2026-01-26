codeunit 138000 "O365 Simplify UI Sales Invoice"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SMB] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTemplates: Codeunit "Library - Templates";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        SelectCustErr: Label 'You must select an existing customer.';
        CannotBeZeroEmptyErr: Label 'It cannot be zero or empty.';
        SelectVendorErr: Label 'You must select an existing vendor.';
        SellToCustomerName4HandlerFunction: Text[100];
        LeaveDocWithoutPostingTxt: Label 'This document is not posted.';
        CopyItemsOption: Option "None",All,Selected;
        ControlShouldBeDisabledErr: Label 'Control should be disabled';
        ControlShouldBeEnabledErr: Label 'Control should be enabled';
        CannotCreatePurchaseOrderWithoutVendorErr: Label 'You cannot create purchase orders without specifying a vendor for all lines.';
        EntireOrderIsAvailableTxt: Label 'All items on the sales order are available.';
        NoPurchaseOrdersCreatedErr: Label 'No purchase orders are created.';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceFromCard()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        AddRandomNumberOfLinesToSalesHeader(SalesHeader, Item);

        PostedSalesInvoice.Trap();

        // Exercise
        SalesInvoice.OpenView();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        LibrarySales.EnableConfirmOnPostingDoc();
        SalesInvoice.Post.Invoke();

        // Verify - The document was posted and opened in the Posted Sales Invoice page
        PostedSalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceFromList()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesInvoiceList: TestPage "Sales Invoice List";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        AddRandomNumberOfLinesToSalesHeader(SalesHeader, Item);

        PostedSalesInvoice.Trap();

        // Exercise
        SalesInvoiceList.OpenView();
        SalesInvoiceList.Filter.SetFilter("No.", SalesHeader."No.");
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        SalesInvoiceList.Post.Invoke();

        // Verify
        PostedSalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceFromCard()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        Initialize();

        // Setup
        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, LibraryRandom.RandDecInRange(1, 100, 2));

        PostedPurchaseInvoice.Trap();

        // Exercise
        PurchaseInvoice.OpenView();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        LibrarySales.EnableConfirmOnPostingDoc();
        PurchaseInvoice.Post.Invoke();

        // Verify - The document was posted and opened in the Posted Purchase Invoice page
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPurcahseInvoiceFromList()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoices: TestPage "Purchase Invoices";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        Initialize();

        // Setup
        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, LibraryRandom.RandDecInRange(1, 100, 2));

        PostedPurchaseInvoice.Trap();

        // Exercise
        PurchaseInvoices.OpenView();
        PurchaseInvoices.Filter.SetFilter("No.", PurchaseHeader."No.");
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        PurchaseInvoices.PostSelected.Invoke();

        // Verify - The document was posted and opened in the Posted Purchase Invoice page
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('QuoteReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunQuoteReport()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesQuote: TestPage "Sales Quote";
    begin
        // This will test that report runs. Other existing tests are checking the content
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(1);
        SalesQuote.SalesLines.Next();
        Commit();

        // Exercise
        SalesQuote.Print.Invoke();
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('QuoteReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunQuoteReportFromList()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesQuote: TestPage "Sales Quote";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // This will test that report runs. Other existing tests are checking the content
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);
        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(1);
        SalesQuote.Close();

        SalesQuotes.OpenView();
        SalesQuotes.First();
        Commit();

        // Exercise
        SalesQuotes.Print.Invoke();
        SalesQuotes.Close();
    end;

    [Test]
    [HandlerFunctions('CurrencyHandler')]
    [Scope('OnPrem')]
    procedure Currency()
    var
        Cust: Record Customer;
        Item: Record Item;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        if CurrencyExchangeRate.FindFirst() then;

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);
        SalesInvoice."Currency Code".AssistEdit();
        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('CurrencyHandler')]
    [Scope('OnPrem')]
    procedure CurrencyQuote()
    var
        Cust: Record Customer;
        Item: Record Item;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        if CurrencyExchangeRate.FindFirst() then;

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);
        SalesQuote."Currency Code".AssistEdit();
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('CurrencyHandler')]
    [Scope('OnPrem')]
    procedure CurrencyPurchase()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        if CurrencyExchangeRate.FindFirst() then;

        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Name := Vendor."No.";
        Vendor.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Vendor.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseInvoice."Currency Code".AssistEdit();
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenters()
    var
        Cust: Record Customer;
        Item: Record Item;
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        UserSetup.Reset();
        UserSetup.SetRange("User ID", UserId);
        UserSetup.FindFirst();

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);
        SalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        SalesHeader.FindFirst();
        SalesInvoice.Close();

        Assert.AreEqual(UserSetup."Sales Resp. Ctr. Filter", SalesHeader."Responsibility Center", '');

        LibrarySmallBusiness.CreateResponsabilityCenter(ResponsibilityCenter);

        UserSetup.Validate("Sales Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify();

        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice."No.".AssertEquals('');
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectCustomerWithSpecialCharacters()
    var
        Cust: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        CreateCustomerWithName(Cust, '(XXXX)');

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);
        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyNumberOfCustomersAndClosePage')]
    [Scope('OnPrem')]
    procedure SelectFromMultipleCustomersWithSpecialCharacters()
    var
        Cust: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        CreateCustomerWithName(Cust, '(XYXX)');
        CreateCustomerWithName(Cust, '((XYXX) 2');

        LibraryVariableStorage.Enqueue(2);
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue('XYXX');

        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectVendorWithSpecialCharacters()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        CreateVendorWithName(Vendor, '(YYYY)');

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyNumberOfVendorsAndClosePage')]
    [Scope('OnPrem')]
    procedure SelectFromMultipleVendorsWithSpecialCharacters()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        CreateVendorWithName(Vendor, '(YXYY)');
        CreateVendorWithName(Vendor, '(YXYY) 2');

        LibraryVariableStorage.Enqueue(2);
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue('YXYY');

        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCentersPurchase()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Name := Vendor."No.";
        Vendor.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        UserSetup.Reset();
        UserSetup.SetRange("User ID", UserId);
        UserSetup.FindFirst();

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseInvoice.Close();

        Assert.AreEqual(UserSetup."Purchase Resp. Ctr. Filter", PurchaseHeader."Responsibility Center",
          'Responsibility centers don''t match.');

        LibrarySmallBusiness.CreateResponsabilityCenter(ResponsibilityCenter);

        UserSetup.Validate("Purchase Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify();

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice."No.".AssertEquals('');
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateInvoiceForCustomerWithCreditLimit()
    var
        Cust: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        OldCreditWarning: Option;
    begin
        Initialize();
        SetCreditWarning(OldCreditWarning, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust."Credit Limit (LCY)" := -1;
        Cust.Name := Cust."No.";
        Cust.Modify();

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);
        SalesInvoice.Close();

        SetCreditWarning(OldCreditWarning, OldCreditWarning);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvoiceForCustomerWithoutCreditLimit()
    var
        Cust: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesInvoice: TestPage "Sales Invoice";
        OldCreditWarning: Option;
    begin
        Initialize();
        SetCreditWarning(OldCreditWarning, SalesReceivablesSetup."Credit Warnings"::"No Warning");

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust."Credit Limit (LCY)" := 0;
        Cust.Name := Cust."No.";
        Cust.Modify();

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);
        SalesInvoice.Close();

        SetCreditWarning(OldCreditWarning, OldCreditWarning);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateInvoiceForCustomerWithoutCreditLimitAndChangeCust()
    var
        Cust: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustWithLimit: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        OldCreditWarning: Option;
    begin
        Initialize();
        SetCreditWarning(OldCreditWarning, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust."Credit Limit (LCY)" := 0;
        Cust.Name := Cust."No.";
        Cust.Modify();

        LibrarySmallBusiness.CreateCustomer(CustWithLimit);
        CustWithLimit."Credit Limit (LCY)" := -1;
        CustWithLimit.Name := CustWithLimit."No.";
        CustWithLimit.Modify();

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);
        SalesInvoice."Sell-to Customer Name".SetValue(CustWithLimit.Name);
        SalesInvoice.Close();

        SetCreditWarning(OldCreditWarning, OldCreditWarning);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedText()
    var
        Cust: Record Customer;
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateExtendedTextHeader(ExtendedTextHeader, "Extended Text Table Name"::Item, Item."No.");
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);

        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.InsertExtTexts.Invoke();
        SalesInvoice.Close();

        ExtendedTextLine.Delete();
        ExtendedTextHeader.Delete();
        Item.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextPurchase()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Name := Vendor."No.";
        Vendor.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateExtendedTextHeader(ExtendedTextHeader, "Extended Text Table Name"::Item, Item."No.");
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.PurchLines.InsertExtTexts.Invoke();
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLookup()
    var
        Cust: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        LibraryVariableStorage.Enqueue(Cust."No.");
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".Lookup();
        Assert.AreEqual(Cust.Name, SalesInvoice."Sell-to Customer Name".Value, 'Wrong Customer Name');
    end;

    [Test]
    [HandlerFunctions('CustomerPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteLookup()
    var
        Cust: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();
        LibrarySmallBusiness.CreateCustomer(Cust);
        LibraryVariableStorage.Enqueue(Cust."No.");
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".Lookup();
        Assert.AreEqual(Cust.Name, SalesQuote."Sell-to Customer Name".Value, 'Wrong Customer Name');
    end;

    [Test]
    [HandlerFunctions('VendorPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceLookup()
    var
        Vend: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();
        LibrarySmallBusiness.CreateVendor(Vend);
        LibraryVariableStorage.Enqueue(Vend."No.");
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".Lookup();
        Assert.AreEqual(Vend.Name, PurchaseInvoice."Buy-from Vendor Name".Value, 'Wrong Vendor Name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Comments()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);
        CreateCommentForItem(Item);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);

        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentsPurchase()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Name := Vendor."No.";
        Vendor.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);
        CreateCommentForItem(Item);

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelectNoWhenMakingInvoiceFromQuote()
    var
        Cust: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);

        LibraryVariableStorage.Enqueue(false);
        SalesQuote.MakeInvoice.Invoke();
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelectNoWhenMakingInvoiceFromQuoteList()
    var
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        Initialize();

        LibraryApplicationArea.DisableApplicationAreaSetup();
        CreateCustomerWithNumberAsName(Cust);

        LibrarySmallBusiness.CreateSalesQuoteHeader(SalesHeader, Cust);

        SalesQuotes.OpenView();
        SalesQuotes.FILTER.SetFilter("No.", SalesHeader."No.");
        LibraryVariableStorage.Enqueue(false);
        SalesQuotes.MakeInvoice.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteSetsSameFieldsAsCreatingInvoiceWithSameData()
    var
        ReferenceInvoiceSalesHeader: Record "Sales Header";
        ReferenceSalesLine: Record "Sales Line";
        InvoiceSalesHeader: Record "Sales Header";
        InvoiceSalesLine: Record "Sales Line";
        Item: Record Item;
        Cust: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
        ItemQuantity: Integer;
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Cust.Name);

        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesInvoice.Close();

        ReferenceInvoiceSalesHeader.SetRange("Document Type", ReferenceInvoiceSalesHeader."Document Type"::Invoice);
        ReferenceInvoiceSalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        ReferenceInvoiceSalesHeader.FindFirst();

        ReferenceSalesLine.SetRange("Document Type", ReferenceInvoiceSalesHeader."Document Type");
        ReferenceSalesLine.SetRange("Document No.", ReferenceInvoiceSalesHeader."No.");
        ReferenceSalesLine.FindFirst();

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);

        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(ItemQuantity);

        Clear(SalesInvoice);
        SalesInvoice.Trap();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SalesQuote.MakeInvoice.Invoke();

        SalesInvoice.Close();

        InvoiceSalesHeader.SetRange("Document Type", InvoiceSalesHeader."Document Type"::Invoice);
        InvoiceSalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        InvoiceSalesHeader.SetFilter("No.", '<>%1', ReferenceInvoiceSalesHeader."No.");
        InvoiceSalesHeader.FindFirst();

        InvoiceSalesLine.SetRange("Document Type", InvoiceSalesHeader."Document Type");
        InvoiceSalesLine.SetRange("Document No.", InvoiceSalesHeader."No.");
        InvoiceSalesLine.FindFirst();

        VerifySalesDocumentsMatch(ReferenceInvoiceSalesHeader, InvoiceSalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersAllFields()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        MakeInvoiceFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersAllFieldsWithPctDisc()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        DiscPct: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);
        SetupDataForDiscountTypePct(Item, ItemQuantity, Cust, DiscPct);

        MakeInvoiceFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersAllFieldsWithAmountDisc()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        InvDiscAmt: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Cust, InvDiscAmt);

        MakeInvoiceFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersAllFieldsStandard()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
    begin
        Initialize();
        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Res. Ledger Entry");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        MakeInvoiceFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersAllFieldsWithPctDiscStandard()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        DiscPct: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Res. Ledger Entry");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);
        SetupDataForDiscountTypePct(Item, ItemQuantity, Cust, DiscPct);

        MakeInvoiceFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersAllFieldsWithAmountDiscStandard()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        InvDiscAmt: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Res. Ledger Entry");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Cust, InvDiscAmt);

        MakeInvoiceFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersComments()
    var
        QuoteSalesHeader: Record "Sales Header";
        InvoiceSalesHeader: Record "Sales Header";
        Item: Record Item;
        Cust: Record Customer;
        TempSalesCommentLine: Record "Sales Comment Line" temporary;
        SalesCommentLine: Record "Sales Comment Line";
        InvoiceSalesCommentLine: Record "Sales Comment Line";
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        MakeQuoteTransfersComments(QuoteSalesHeader, Item, Cust, TempSalesCommentLine, SalesCommentLine);

        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", QuoteSalesHeader."No.");

        SalesInvoice.Trap();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SalesQuote.MakeInvoice.Invoke();

        SalesInvoice.Close();

        InvoiceSalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        InvoiceSalesHeader.SetRange("Document Type", InvoiceSalesHeader."Document Type"::Invoice);
        Assert.AreEqual(1, InvoiceSalesHeader.Count, 'Only one header record should be present');
        InvoiceSalesHeader.FindFirst();

        InvoiceSalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::Invoice);
        InvoiceSalesCommentLine.SetRange("No.", InvoiceSalesHeader."No.");
        Assert.AreEqual(1, InvoiceSalesCommentLine.Count, 'Only one Comment line should be present');
        InvoiceSalesCommentLine.FindFirst();

        Assert.AreEqual(InvoiceSalesCommentLine.Date, TempSalesCommentLine.Date, 'Date was not set');
        Assert.AreEqual(InvoiceSalesCommentLine.Comment, TempSalesCommentLine.Comment, 'Comment text was not transfered');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteKeepsUserEnteredInformation()
    var
        QuoteSalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
        NewShipToAddress: Text[100];
        NewShipToName: Text[100];
    begin
        Initialize();

        MakeQuoteKeepsUserEnteredInformation(QuoteSalesHeader);

        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", QuoteSalesHeader."No.");

        NewShipToAddress := LibraryUtility.GenerateRandomCode(QuoteSalesHeader.FieldNo("Ship-to Address"), DATABASE::"Sales Header");
        NewShipToName := LibraryUtility.GenerateRandomCode(QuoteSalesHeader.FieldNo("Ship-to Name"), DATABASE::"Sales Header");
        SalesQuote."Ship-to Name".SetValue(NewShipToName);
        SalesQuote."Ship-to Address".SetValue(NewShipToAddress);

        SalesInvoice.Trap();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SalesQuote.MakeInvoice.Invoke();

        Assert.AreEqual(SalesInvoice."Ship-to Name".Value, NewShipToName, 'Validation has overrided value set by user');
        Assert.AreEqual(SalesInvoice."Ship-to Address".Value, NewShipToAddress, 'Validation has overrided value set by user');
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteAndPost()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesQuoteToInvoice: Codeunit "Sales-Quote to Invoice";
    begin
        ClearLastError();
        Initialize();

        // Setup
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(SalesHeader, Customer, Item, 1, 1); // 1 line, Qty 1
        SalesQuoteToInvoice.Run(SalesHeader);
        SalesQuoteToInvoice.GetSalesInvoiceHeader(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        Assert.AreEqual('', GetLastErrorText, 'No error expected')
    end;

    local procedure MakeQuote(Cust: Record Customer; Item: Record Item; ItemQuantity: Integer; var QuoteSalesHeader: Record "Sales Header"; var ReferenceQuoteSalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
        NoOfLines: Integer;
    begin
        NoOfLines := LibraryRandom.RandIntInRange(2, 10);

        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(QuoteSalesHeader, Cust, Item, ItemQuantity, NoOfLines);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(ReferenceQuoteSalesHeader, Cust, Item, ItemQuantity, NoOfLines);
        ReferenceQuoteSalesHeader.Validate("External Document No.", QuoteSalesHeader."External Document No.");
        ReferenceQuoteSalesHeader.Modify(true);

        // Open both in the quote page to ensure they look the same
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", QuoteSalesHeader."No.");
        SalesQuote.Filter.SetFilter("No.", ReferenceQuoteSalesHeader."No.");
        SalesQuote.Close();
    end;

    local procedure ConvertQuotetoInvoice(QuoteSalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", QuoteSalesHeader."No.");

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);

        SalesInvoice.Trap();
        SalesQuote.MakeInvoice.Invoke();
    end;

    local procedure ConvertQuoteToOrder(QuoteSalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", QuoteSalesHeader."No.");

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);

        SalesOrder.Trap();
        SalesQuote.MakeOrder.Invoke();
    end;

    local procedure VerifyConvertedDocument(ReferenceQuoteSalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        ConvertedSalesHeader: Record "Sales Header";
    begin
        ConvertedSalesHeader.SetRange("Sell-to Customer No.", ReferenceQuoteSalesHeader."Sell-to Customer No.");
        ConvertedSalesHeader.SetRange("Document Type", DocumentType);
        Assert.RecordCount(ConvertedSalesHeader, 1);
        ConvertedSalesHeader.FindFirst();

        VerifySalesDocumentsMatch(ReferenceQuoteSalesHeader, ConvertedSalesHeader);
        ConvertedSalesHeader.TestField("Posting Date", WorkDate());
    end;

    local procedure VerifyInvoice(ReferenceQuoteSalesHeader: Record "Sales Header")
    var
        DummySalesHeader: Record "Sales Header";
    begin
        VerifyConvertedDocument(ReferenceQuoteSalesHeader, DummySalesHeader."Document Type"::Invoice);
    end;

    local procedure VerifyOrder(ReferenceQuoteSalesHeader: Record "Sales Header")
    var
        DummySalesHeader: Record "Sales Header";
    begin
        VerifyConvertedDocument(ReferenceQuoteSalesHeader, DummySalesHeader."Document Type"::Order);
    end;

    local procedure MakeInvoiceFromQuoteAndVerify(Cust: Record Customer; Item: Record Item; ItemQuantity: Integer)
    var
        QuoteSalesHeader: Record "Sales Header";
        ReferenceQuoteSalesHeader: Record "Sales Header";
    begin
        MakeQuote(Cust, Item, ItemQuantity, QuoteSalesHeader, ReferenceQuoteSalesHeader);
        ConvertQuotetoInvoice(QuoteSalesHeader);
        VerifyInvoice(ReferenceQuoteSalesHeader);
    end;

    local procedure MakeOrderFromQuoteAndVerify(Cust: Record Customer; Item: Record Item; ItemQuantity: Integer)
    var
        QuoteSalesHeader: Record "Sales Header";
        ReferenceQuoteSalesHeader: Record "Sales Header";
    begin
        MakeQuote(Cust, Item, ItemQuantity, QuoteSalesHeader, ReferenceQuoteSalesHeader);
        ConvertQuoteToOrder(QuoteSalesHeader);
        VerifyOrder(ReferenceQuoteSalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelectNoWhenMakingOrderFromQuote()
    var
        Cust: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);

        LibraryVariableStorage.Enqueue(false);
        SalesQuote.MakeOrder.Invoke();
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelectNoWhenMakingOrderFromQuoteList()
    var
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        Initialize();

        LibraryApplicationArea.DisableApplicationAreaSetup();
        CreateCustomerWithNumberAsName(Cust);

        LibrarySmallBusiness.CreateSalesQuoteHeader(SalesHeader, Cust);

        SalesQuotes.OpenView();
        SalesQuotes.FILTER.SetFilter("No.", SalesHeader."No.");
        LibraryVariableStorage.Enqueue(false);
        SalesQuotes.MakeOrder.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteSetsSameFieldsAsCreatingInvoiceWithSameData()
    var
        ReferenceOrderSalesHeader: Record "Sales Header";
        ReferenceSalesLine: Record "Sales Line";
        OrderSalesHeader: Record "Sales Header";
        OrderSalesLine: Record "Sales Line";
        Item: Record Item;
        Cust: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
        ItemQuantity: Integer;
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Cust.Name);

        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines."No.".SetValue(Item."No.");
        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);
        SalesOrder.Close();

        ReferenceOrderSalesHeader.SetRange("Document Type", ReferenceOrderSalesHeader."Document Type"::Order);
        ReferenceOrderSalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        ReferenceOrderSalesHeader.FindFirst();

        ReferenceSalesLine.SetRange("Document Type", ReferenceOrderSalesHeader."Document Type");
        ReferenceSalesLine.SetRange("Document No.", ReferenceOrderSalesHeader."No.");
        ReferenceSalesLine.FindFirst();

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);

        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(ItemQuantity);

        SalesOrder.Trap();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SalesQuote.MakeOrder.Invoke();

        SalesOrder.Close();

        OrderSalesHeader.SetRange("Document Type", OrderSalesHeader."Document Type"::Order);
        OrderSalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        OrderSalesHeader.SetFilter("No.", '<>%1', ReferenceOrderSalesHeader."No.");
        OrderSalesHeader.FindFirst();

        OrderSalesLine.SetRange("Document Type", OrderSalesHeader."Document Type");
        OrderSalesLine.SetRange("Document No.", OrderSalesHeader."No.");
        OrderSalesLine.FindFirst();

        VerifySalesDocumentsMatch(ReferenceOrderSalesHeader, OrderSalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteWithAssembleToOrderItemThrowsError()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        ItemQuantity: Integer;
        CannotConvertAssembleToOrderItemErr: Label 'You can not convert sales quote to sales invoice';
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);
        Item."Assembly Policy" := Item."Assembly Policy"::"Assemble-to-Order";
        item.Modify(true);

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);

        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(ItemQuantity);

        asserterror SalesQuote.MakeInvoice.Invoke();

        Assert.ExpectedError(CannotConvertAssembleToOrderItemErr);

    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteTransfersAllFields()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        MakeOrderFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteTransfersAllFieldsWithPctDisc()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        DiscPct: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);
        SetupDataForDiscountTypePct(Item, ItemQuantity, Cust, DiscPct);

        MakeOrderFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteTransfersAllFieldsWithAmountDisc()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        InvDiscAmt: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Cust, InvDiscAmt);

        MakeOrderFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteTransfersAllFieldsStandard()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
    begin
        Initialize();
        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Res. Ledger Entry");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        MakeOrderFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteTransfersAllFieldsWithPctDiscStandard()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        DiscPct: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Res. Ledger Entry");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);
        SetupDataForDiscountTypePct(Item, ItemQuantity, Cust, DiscPct);

        MakeOrderFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteTransfersAllFieldsWithAmountDiscStandard()
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        InvDiscAmt: Decimal;
    begin
        Initialize();
        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Res. Ledger Entry");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);
        SetupDataForDiscountTypeAmt(Item, ItemQuantity, Cust, InvDiscAmt);

        MakeOrderFromQuoteAndVerify(Cust, Item, ItemQuantity + 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteTransfersComments()
    var
        QuoteSalesHeader: Record "Sales Header";
        OrderSalesHeader: Record "Sales Header";
        Item: Record Item;
        Cust: Record Customer;
        TempSalesCommentLine: Record "Sales Comment Line" temporary;
        SalesCommentLine: Record "Sales Comment Line";
        OrderSalesCommentLine: Record "Sales Comment Line";
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        MakeQuoteTransfersComments(QuoteSalesHeader, Item, Cust, TempSalesCommentLine, SalesCommentLine);

        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", QuoteSalesHeader."No.");

        SalesOrder.Trap();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SalesQuote.MakeOrder.Invoke();

        SalesOrder.Close();

        OrderSalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        OrderSalesHeader.SetRange("Document Type", OrderSalesHeader."Document Type"::Order);
        Assert.AreEqual(1, OrderSalesHeader.Count, 'Only one header record should be present');
        OrderSalesHeader.FindFirst();

        OrderSalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::Order);
        OrderSalesCommentLine.SetRange("No.", OrderSalesHeader."No.");
        Assert.AreEqual(1, OrderSalesCommentLine.Count, 'Only one Comment line should be present');
        OrderSalesCommentLine.FindFirst();

        Assert.AreEqual(OrderSalesCommentLine.Date, TempSalesCommentLine.Date, 'Date was not set');
        Assert.AreEqual(OrderSalesCommentLine.Comment, TempSalesCommentLine.Comment, 'Comment text was not transfered');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuoteKeepsUserEnteredInformation()
    var
        QuoteSalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
        NewShipToAddress: Text[100];
        NewShipToName: Text[100];
    begin
        Initialize();

        MakeQuoteKeepsUserEnteredInformation(QuoteSalesHeader);

        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", QuoteSalesHeader."No.");

        NewShipToAddress := LibraryUtility.GenerateRandomCode(QuoteSalesHeader.FieldNo("Ship-to Address"), DATABASE::"Sales Header");
        NewShipToName := LibraryUtility.GenerateRandomCode(QuoteSalesHeader.FieldNo("Ship-to Name"), DATABASE::"Sales Header");
        SalesQuote."Ship-to Name".SetValue(NewShipToName);
        SalesQuote."Ship-to Address".SetValue(NewShipToAddress);

        SalesOrder.Trap();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SalesQuote.MakeOrder.Invoke();

        Assert.AreEqual(SalesOrder."Ship-to Name".Value, NewShipToName, 'Validation has overrided value set by user');
        Assert.AreEqual(SalesOrder."Ship-to Address".Value, NewShipToAddress, 'Validation has overrided value set by user');
        SalesOrder.Close();
    end;

    local procedure MakeQuoteTransfersComments(var QuoteSalesHeader: Record "Sales Header"; var Item: Record Item; var Cust: Record Customer; var TempSalesCommentLine: Record "Sales Comment Line" temporary; var SalesCommentLine: Record "Sales Comment Line")
    var
        QuoteSalesLine: Record "Sales Line";
        ItemQuantity: Integer;
        NoOfLines: Integer;
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);

        NoOfLines := LibraryRandom.RandIntInRange(2, 10);
        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(QuoteSalesHeader, Cust, Item, ItemQuantity, NoOfLines);
        QuoteSalesLine.SetRange("Document Type", QuoteSalesLine."Document Type"::Quote);
        QuoteSalesLine.SetRange("Document No.", QuoteSalesHeader."No.");
        QuoteSalesLine.FindFirst();
        LibrarySmallBusiness.CreateSalesCommentLine(SalesCommentLine, QuoteSalesLine);
        TempSalesCommentLine := SalesCommentLine;
    end;

    local procedure MakeQuoteKeepsUserEnteredInformation(var QuoteSalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        Cust: Record Customer;
        ItemQuantity: Integer;
        NoOfLines: Integer;
    begin
        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Address := LibraryUtility.GenerateRandomCode(Cust.FieldNo(Address), DATABASE::Customer);

        Cust.Modify(true);
        LibrarySmallBusiness.CreateItem(Item);

        NoOfLines := LibraryRandom.RandIntInRange(2, 10);
        ItemQuantity := LibraryRandom.RandIntInRange(2, 100);

        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(QuoteSalesHeader, Cust, Item, ItemQuantity, NoOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCentersQuote()
    var
        Cust: Record Customer;
        Item: Record Item;
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);
        UserSetup.Reset();
        UserSetup.SetRange("User ID", UserId);
        UserSetup.FindFirst();

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);

        SalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        SalesHeader.FindFirst();
        SalesQuote.Close();

        Assert.AreEqual(UserSetup."Sales Resp. Ctr. Filter", SalesHeader."Responsibility Center", '');

        LibrarySmallBusiness.CreateResponsabilityCenter(ResponsibilityCenter);

        UserSetup.Validate("Sales Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify();

        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");
        SalesQuote."No.".AssertEquals('');
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextQuote()
    var
        Cust: Record Customer;
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateExtendedTextHeader(ExtendedTextHeader, "Extended Text Table Name"::Item, Item."No.");
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);

        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.InsertExtTexts.Invoke();
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentsQuote()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);
        CreateCommentForItem(Item);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Cust.Name);

        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistingCustomerQuote()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        CreateCustomer(Customer);

        // Exercise: Select existing customer.
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);

        // Verify.
        VerifySalesQuoteAgainstCustomer(SalesQuote, Customer);
        VerifySalesQuoteAgainstBillToCustomer(SalesQuote, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistingCustomer()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        CreateCustomer(Customer);

        // Exercise: Select existing customer.
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        // Verify.
        VerifySalesInvoiceAgainstCustomer(SalesInvoice, Customer);
        VerifySalesInvoiceAgainstBillToCustomer(SalesInvoice, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistingVendorPurchase()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();
        CreateVendor(Vendor);

        // Exercise: Select existing customer.
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        // Verify.
        VerifyPurchaseInvoiceAgainstVendor(PurchaseInvoice, Vendor);
        VerifyPurchaseInvoiceAgainstPayToVendor(PurchaseInvoice, Vendor);
    end;

    [Test]
    [HandlerFunctions('CopyDocRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteFromInvoiceCopyDocument()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        // Create Sales Invoice and copy to another Sales Quote
        CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, LibraryRandom.RandDec(100, 2));

        // Create the quote
        SalesHeader2.Init();
        SalesHeader2.Validate("Document Type", SalesHeader2."Document Type"::Quote);
        SalesHeader2.Insert(true);
        Commit();
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader2."No.");
        SalesQuote.SalesLines.First();

        // Enqueue for the request page handler
        LibraryVariableStorage.Enqueue(3); // doc type on the request page
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        SalesQuote.CopyDocument.Invoke();
        SalesQuote.Close();

        // Verify
        SalesHeader2.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        VerifySalesDocumentsMatch(SalesHeader, SalesHeader2);
    end;

    [Test]
    [HandlerFunctions('CopyDocRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceFromInvoiceCopyDocument()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        // Create Sales Invoice and copy to another Sales Quote
        CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, LibraryRandom.RandDec(100, 2));

        SalesHeader2.Init();
        SalesHeader2.Validate("Document Type", SalesHeader2."Document Type"::Invoice);
        SalesHeader2.Insert(true);
        Commit();
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader2."No.");
        SalesInvoice.SalesLines.First();

        // Enqueue for the request page handler
        LibraryVariableStorage.Enqueue(3); // doc type on the request page
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        SalesInvoice.CopyDocument.Invoke();
        SalesInvoice.Close();

        // Verify
        SalesHeader2.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        VerifySalesDocumentsMatch(SalesHeader, SalesHeader2);
    end;

    [Test]
    [HandlerFunctions('PurchaseCopyDocRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceFromInvoiceCopyDocument()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        // Create Sales Invoice and copy to another Sales Quote
        CreateVendor(Vendor);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, LibraryRandom.RandDec(100, 2));

        PurchaseHeader2.Init();
        PurchaseHeader2.Validate("Document Type", PurchaseHeader2."Document Type"::Invoice);
        PurchaseHeader2.Insert(true);
        Commit();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader2."No.");
        PurchaseInvoice.PurchLines.First();

        // Enqueue for the request page handler
        LibraryVariableStorage.Enqueue(3); // doc type on the request page
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        PurchaseInvoice.CopyDocument.Invoke();
        PurchaseInvoice.Close();

        // Verify
        PurchaseHeader2.Get(PurchaseHeader2."Document Type", PurchaseHeader2."No.");
        VerifyPurchaseDocumentsMatch(PurchaseHeader, PurchaseHeader2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateCustomerNameWithExistingCustomerName()
    var
        Customer1: Record Customer;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        CreateCustomer(Customer);
        CreateCustomer(Customer1);

        // Exercise: Select existing customer.
        SalesInvoice.OpenNew();
        SalesInvoice.SalesLines.First();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        SalesInvoice."Sell-to Customer Name".SetValue(Customer1.Name);

        // Verify.
        VerifySalesInvoiceAgainstCustomer(SalesInvoice, Customer1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateCustomerNameWithExistingCustomerNameQuote()
    var
        Customer1: Record Customer;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        CreateCustomer(Customer);
        CreateCustomer(Customer1);

        // Exercise: Select existing customer.
        SalesQuote.OpenNew();
        SalesQuote.SalesLines.First();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        SalesQuote."Sell-to Customer Name".SetValue(Customer1.Name);

        // Verify.
        VerifySalesQuoteAgainstCustomer(SalesQuote, Customer1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,ConfirmHandler,CustomerCardTemplatePageHandler')]
    [Scope('OnPrem')]
    procedure NewBillToCustomerDefaultTemplate()
    var
        Customer: Record Customer;
        BillToCustomer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        BillToCustomerNo: Variant;
        BillToCustomerName: Text[100];
    begin
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        ClearTable(DATABASE::"Res. Ledger Entry");

        CreateCustomer(Customer);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);

        // Exercise.
        BillToCustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));
        LibraryVariableStorage.Enqueue(true); // for the confirm handler when asking whether you want to change the bill-to customer no.

        SalesInvoice.OpenNew();
        SalesInvoice.SalesLines.First();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        SalesInvoice."Bill-to Name".SetValue(BillToCustomerName);

        // Verify.
        LibraryVariableStorage.Dequeue(BillToCustomerNo);
        BillToCustomer.Get(BillToCustomerNo);
        VerifyCustomerAgainstTemplate(BillToCustomer, CustomerTempl);
        VerifySalesInvoiceAgainstBillToCustomer(SalesInvoice, BillToCustomer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,CustomerCardTemplatePageHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerDefaultTemplate()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        SalesInvoice: TestPage "Sales Invoice";
        CustomerNo: Variant;
        CustomerName: Text[100];
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);

        // Exercise.
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));

        SalesInvoice.OpenNew();
        SalesInvoice.SalesLines.First();
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerName);

        // Verify.
        LibraryVariableStorage.Dequeue(CustomerNo);
        Customer.Get(CustomerNo);
        VerifyCustomerAgainstTemplate(Customer, CustomerTempl);
        VerifySalesInvoiceAgainstCustomer(SalesInvoice, Customer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,CustomerCardTemplatePageHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerDefaultTemplateQuote()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        SalesQuote: TestPage "Sales Quote";
        CustomerNo: Variant;
        CustomerName: Text[100];
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);

        // Exercise.
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));

        SalesQuote.OpenNew();
        SalesQuote.SalesLines.First();
        SalesQuote."Sell-to Customer Name".SetValue(CustomerName);

        // Verify.
        LibraryVariableStorage.Dequeue(CustomerNo);
        Customer.Get(CustomerNo);
        VerifyCustomerAgainstTemplate(Customer, CustomerTempl);
        VerifySalesQuoteAgainstCustomer(SalesQuote, Customer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,SelectCustomerTemplListHandler,CustomerCardTemplatePageHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerSelectTemplate()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTempl1: Record "Customer Templ.";
        SalesInvoice: TestPage "Sales Invoice";
        CustomerNo: Variant;
        CustomerName: Text[100];
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl1);

        // Exercise.
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));
        LibraryVariableStorage.Enqueue(CustomerTempl1.Code); // for the customer card page handler
        LibraryVariableStorage.Enqueue(true); // for the new customer confirm handler

        SalesInvoice.OpenNew();
        SalesInvoice.SalesLines.First();
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerName);

        // Verify.
        LibraryVariableStorage.Dequeue(CustomerNo);
        Customer.Get(CustomerNo);
        VerifyCustomerAgainstTemplate(Customer, CustomerTempl1);
        VerifySalesInvoiceAgainstCustomer(SalesInvoice, Customer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,SelectCustomerTemplListHandler,CustomerCardTemplatePageHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerSelectTemplateQuote()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        CustomerTempl1: Record "Customer Templ.";
        SalesQuote: TestPage "Sales Quote";
        CustomerNo: Variant;
        CustomerName: Text[100];
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl1);

        // Exercise.
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));
        LibraryVariableStorage.Enqueue(CustomerTempl1.Code); // for the customer card page handler
        LibraryVariableStorage.Enqueue(true);

        SalesQuote.OpenNew();
        SalesQuote.SalesLines.First();
        SalesQuote."Sell-to Customer Name".SetValue(CustomerName);

        // Verify.
        LibraryVariableStorage.Dequeue(CustomerNo);
        Customer.Get(CustomerNo);
        VerifyCustomerAgainstTemplate(Customer, CustomerTempl1);
        VerifySalesQuoteAgainstCustomer(SalesQuote, Customer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,CustomerCardPageHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerWithNoTemplate()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        CustomerNo: Variant;
        CustomerName: Text[100];
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        // Exercise.
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));
        LibraryVariableStorage.Enqueue(CustomerName); // for the customer card page handler
        SalesInvoice.OpenNew();
        SalesInvoice.SalesLines.First();
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerName);

        // Verify.
        LibraryVariableStorage.Dequeue(CustomerNo);
        Customer.Get(CustomerNo);
        VerifySalesInvoiceAgainstCustomer(SalesInvoice, Customer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,CustomerCardPageHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerWithNoTemplateQuote()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        CustomerNo: Variant;
        CustomerName: Text[100];
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        // Exercise.
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));
        LibraryVariableStorage.Enqueue(CustomerName); // for the customer card page handler
        SalesQuote.OpenNew();
        SalesQuote.SalesLines.First();
        SalesQuote."Sell-to Customer Name".SetValue(CustomerName);

        // Verify.
        LibraryVariableStorage.Dequeue(CustomerNo);
        Customer.Get(CustomerNo);
        VerifySalesQuoteAgainstCustomer(SalesQuote, Customer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,ConfirmHandler,VendorCardTemplatePageHandler')]
    [Scope('OnPrem')]
    procedure NewPayToVendorDefaultTemplate()
    var
        Vendor: Record Vendor;
        PayToVendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PayToVendorNo: Variant;
        PayToVendorName: Text[100];
    begin
        Initialize();
        CreateVendor(Vendor);
        LibraryTemplates.CreateVendorTemplateWithData(VendorTempl);

        // Exercise.
        PayToVendorName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name));
        LibraryVariableStorage.Enqueue(true); // for the confirm handler when asking whether you want to change the pay-to vendor no.

        PurchaseInvoice.OpenNew();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseInvoice."Pay-to Name".SetValue(PayToVendorName);

        // Verify.
        LibraryVariableStorage.Dequeue(PayToVendorNo);
        PayToVendor.Get(PayToVendorNo);
        VerifyVendorAgainstTemplate(PayToVendor, VendorTempl);
        VerifyPurchaseInvoiceAgainstPayToVendor(PurchaseInvoice, PayToVendor);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,VendorCardTemplatePageHandler')]
    [Scope('OnPrem')]
    procedure NewVendorDefaultTemplate()
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Variant;
        VendorName: Text[100];
    begin
        Initialize();

        LibraryTemplates.CreateVendorTemplateWithData(VendorTempl);

        // Exercise.
        VendorName := LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Vendor);

        PurchaseInvoice.OpenNew();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(VendorName);

        // Verify.
        LibraryVariableStorage.Dequeue(VendorNo);
        Vendor.Get(VendorNo);
        VerifyVendorAgainstTemplate(Vendor, VendorTempl);
        VerifyPurchaseInvoiceAgainstVendor(PurchaseInvoice, Vendor);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerCancel')]
    [Scope('OnPrem')]
    procedure CancelCreatingNewCustomer()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        CustomerName: Text;
    begin
        Initialize();

        // Exercise: New customer name.
        CustomerName := LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name));
        SalesInvoice.OpenNew();
        asserterror SalesInvoice."Sell-to Customer Name".SetValue(CustomerName);
        Assert.ExpectedError(SelectCustErr);

        // Verify.
        Customer.SetRange(Name, CustomerName);
        asserterror Customer.FindFirst();
        Assert.AssertNothingInsideFilter();

        VerifySellToEmptyOnSalesInvoice(SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerCancel')]
    [Scope('OnPrem')]
    procedure CancelCreatingNewCustomerQuote()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        CustomerName: Text;
    begin
        Initialize();

        // Exercise: New customer name.
        CustomerName := LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name));
        SalesQuote.OpenNew();
        asserterror SalesQuote."Sell-to Customer Name".SetValue(CustomerName);
        Assert.ExpectedError(SelectCustErr);

        // Verify.
        Customer.SetRange(Name, CustomerName);
        asserterror Customer.FindFirst();
        Assert.AssertNothingInsideFilter();

        VerifySellToEmptyOnSalesQuote(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,SelectCustomerTemplListHandler,CustomerCardPageHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerCancelSelectTemplate()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        SalesInvoice: TestPage "Sales Invoice";
        CustomerName: Text;
    begin
        Initialize();

        // Create 2 template headers and use only the second
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);

        // Exercise.
        CustomerName := LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name));
        LibraryVariableStorage.Enqueue(CustomerTempl.Code);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CustomerName);
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerName);

        // Verify.
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst();
        VerifySalesInvoiceAgainstCustomer(SalesInvoice, Customer);
        VerifySalesInvoiceAgainstBillToCustomer(SalesInvoice, Customer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,SelectCustomerTemplListHandler,CustomerCardPageHandler')]
    [Scope('OnPrem')]
    procedure NewCustomerCancelSelectTemplateQuote()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        SalesQuote: TestPage "Sales Quote";
        CustomerName: Text;
    begin
        Initialize();

        // Create 2 template headers and use only the second
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);

        // Exercise.
        CustomerName := LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name));
        LibraryVariableStorage.Enqueue(CustomerTempl.Code);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CustomerName);
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(CustomerName);

        // Verify.
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst();
        VerifySalesQuoteAgainstCustomer(SalesQuote, Customer);
        VerifySalesQuoteAgainstBillToCustomer(SalesQuote, Customer);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,CustomerCardCancelEditPageHandler')]
    [Scope('OnPrem')]
    procedure CancelEditNewCustomerQuote()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        CustomerName: Text;
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        // Exercise: New customer name.
        CustomerName := LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name));
        LibraryVariableStorage.Enqueue(CustomerName); // for the customer card page handler
        SalesQuote.OpenNew();
        asserterror SalesQuote."Sell-to Customer Name".SetValue(CustomerName);
        Assert.ExpectedError(CannotBeZeroEmptyErr);

        // Verify customer still created even if not fully edited
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst();

        VerifySellToEmptyOnSalesQuote(SalesQuote);
    end;

    [Test]
    [HandlerFunctions('CustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure CustomersWithSameName()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        CreateTwoCustomersSameName(Customer);

        // Exercise: Select existing customer - second one in the page handler
        LibraryVariableStorage.Enqueue(Customer.Name); // for the customer list page handler
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(CopyStr(Customer.Name, 2, StrLen(Customer.Name) - 1));

        // Verify.
        VerifySalesInvoiceAgainstCustomer(SalesInvoice, Customer);
    end;

    [Test]
    [HandlerFunctions('VerifyNumberOfCustomersAndClosePage')]
    [Scope('OnPrem')]
    procedure TestSelectCustomerWithSpecifyingMiddleOfName()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        Identifier: Code[10];
        NameBeginning: Text[10];
        NameMiddle: Text[10];
        NameEnd: Text[10];
    begin
        Initialize();
        ClearTable(DATABASE::Job);

        Identifier := CreateSelectCustomerSetup(NameBeginning, NameMiddle, NameEnd, Customer);

        SalesInvoice.OpenNew();

        // Test entering middle of the name
        LibraryVariableStorage.Enqueue(2);
        SalesInvoice."Sell-to Customer Name".SetValue(NameMiddle);

        SalesInvoice.Close();

        // Teardown
        Customer.SetFilter(Name, '*' + Identifier);
        Customer.DeleteAll(true);
    end;

    [Test]
    [HandlerFunctions('VerifyNumberOfCustomersAndClosePage')]
    [Scope('OnPrem')]
    procedure TestSelectCustomerWithSpecifyingEndOfName()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        Identifier: Code[10];
        NameBeginning: Text[10];
        NameMiddle: Text[10];
        NameEnd: Text[10];
    begin
        Initialize();
        ClearTable(DATABASE::Job);

        Identifier := CreateSelectCustomerSetup(NameBeginning, NameMiddle, NameEnd, Customer);

        SalesInvoice.OpenNew();

        // Test entering middle of the name
        LibraryVariableStorage.Enqueue(2);
        SalesInvoice."Sell-to Customer Name".SetValue(NameEnd);

        SalesInvoice.Close();

        // Teardown
        Customer.SetFilter(Name, '*' + Identifier);
        Customer.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectCustomerWithSpecifyingExactName()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        CreateCustomer(Customer);
        Customer.Validate(Name, 'Customer Name');
        Customer.Modify(true);

        CreateCustomer(Customer2);
        Customer2.Validate(Name, Customer.Name + ' 2');
        Customer2.Modify(true);

        // Entering full name should match to first customer
        SalesInvoice.OpenNew();
        LibraryVariableStorage.Enqueue(2);
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        VerifySalesInvoiceAgainstCustomer(SalesInvoice, Customer);

        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyNumberOfVendorsAndClosePage')]
    [Scope('OnPrem')]
    procedure TestSelectVendorWithSpecifyingMiddleOfName()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        Identifier: Code[10];
        NameBeginning: Text[10];
        NameMiddle: Text[10];
        NameEnd: Text[10];
    begin
        Initialize();

        Identifier := CreateSelectVendorSetup(NameBeginning, NameMiddle, NameEnd, Vendor);

        PurchaseInvoice.OpenNew();

        // Test entering middle of the name
        LibraryVariableStorage.Enqueue(2);
        PurchaseInvoice."Buy-from Vendor Name".SetValue(NameMiddle);

        PurchaseInvoice.Close();

        // Teardown
        Vendor.SetFilter(Name, '*' + Identifier);
        Vendor.DeleteAll(true);
    end;

    [Test]
    [HandlerFunctions('VerifyNumberOfVendorsAndClosePage')]
    [Scope('OnPrem')]
    procedure TestSelectVendorWithSpecifyingEndOfName()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        Identifier: Code[10];
        NameBeginning: Text[10];
        NameMiddle: Text[10];
        NameEnd: Text[10];
    begin
        Initialize();

        Identifier := CreateSelectVendorSetup(NameBeginning, NameMiddle, NameEnd, Vendor);

        PurchaseInvoice.OpenNew();

        // Test entering end of the name
        LibraryVariableStorage.Enqueue(2);
        PurchaseInvoice."Buy-from Vendor Name".SetValue(NameEnd);

        PurchaseInvoice.Close();

        // Teardown
        Vendor.SetFilter(Name, '*' + Identifier);
        Vendor.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectVendorWithSpecifyingExactName()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        CreateVendor(Vendor);
        Vendor.Validate(Name, 'Vendor Name');
        Vendor.Modify(true);

        CreateVendor(Vendor2);
        Vendor2.Validate(Name, Vendor.Name + ' 2');
        Vendor2.Modify(true);

        // Setting exact name should select vendor 1
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        VerifyPurchaseInvoiceAgainstVendor(PurchaseInvoice, Vendor);
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure CustomersWithSameNameQuote()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        CreateTwoCustomersSameName(Customer);

        // Exercise: Select existing customer - second one in the page handler
        LibraryVariableStorage.Enqueue(Customer.Name); // for the customer list page handler
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(CopyStr(Customer.Name, 2, StrLen(Customer.Name) - 1));

        // Verify.
        VerifySalesQuoteAgainstCustomer(SalesQuote, Customer);
    end;

    [Test]
    [HandlerFunctions('CustomerListCancelPageHandler')]
    [Scope('OnPrem')]
    procedure CustomersWithSameNameCancelSelect()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        CreateTwoCustomersSameName(Customer);

        // Exercise: Select existing customer - second one in the page handler
        LibraryVariableStorage.Enqueue(Customer.Name); // for the customer list page handler
        SalesInvoice.OpenNew();
        asserterror SalesInvoice."Sell-to Customer Name".SetValue(CopyStr(Customer.Name, 2, StrLen(Customer.Name) - 1));
        Assert.ExpectedError(SelectCustErr);
    end;

    [Test]
    [HandlerFunctions('CustomerListCancelPageHandler')]
    [Scope('OnPrem')]
    procedure CustomersWithSameNameCancelSelectQuote()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        CreateTwoCustomersSameName(Customer);

        // Exercise: Select existing customer - second one in the page handler
        LibraryVariableStorage.Enqueue(Customer.Name); // for the customer list page handler
        SalesQuote.OpenNew();
        asserterror SalesQuote."Sell-to Customer Name".SetValue(CopyStr(Customer.Name, 2, StrLen(Customer.Name) - 1));
        Assert.ExpectedError(SelectCustErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCustomerCardFromSortedCustomerList()
    var
        Customer: Record Customer;
        TestItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerList: TestPage "Customer List";
    begin
        // [FEATURE] [Customer Card]
        // [SCENARIO] Customer Card should be open for Customer that is sorted by "Balance Due" and has different Balance and "Balance Due"
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        // [GIVEN] Create Customer which Balance and "Balance Due" are different by posting 2 sales invoices:
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(TestItem);
        // [GIVEN] Sales Invoice posted on WORKDATE
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, TestItem, LibraryRandom.RandInt(100));
        LibrarySmallBusiness.PostSalesInvoice(SalesHeader);
        // [GIVEN] Sales Invoice posted on (WorkDate() + 1)
        WorkDate := WorkDate() + 1;
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, TestItem, LibraryRandom.RandInt(100));
        LibrarySmallBusiness.PostSalesInvoice(SalesHeader);
        WorkDate := WorkDate() - 1;

        // [GIVEN] Sort Customers by "Balance Due" in the Customer List
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", Customer."No."); // decrease number of shown customers
        CustomerList.FILTER.SetCurrentKey("Balance Due");

        // [WHEN] Run action View to open the Mini Customer Card
        // [THEN] The Card is open and shows Customers data
        VerifySortedCustomerList(CustomerList);
    end;

    [Test]
    [HandlerFunctions('ChangeBuyFromPayToVendorConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVendorNameWithExistingVendorName()
    var
        Vendor1: Record Vendor;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();
        CreateVendor(Vendor);
        CreateVendor(Vendor1);

        // Exercise: Select existing Vendor.
        PurchaseInvoice.OpenNew();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        // Enqueue for ChangeSellToBillToVendorConfirmHandler that is called twice
        // for sell-to and bill-to
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor1.Name);

        // Verify.
        VerifyPurchaseInvoiceAgainstVendor(PurchaseInvoice, Vendor1);
    end;

    [Test]
    [HandlerFunctions('VendorListPageHandler')]
    [Scope('OnPrem')]
    procedure VendorsWithSameName()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        CreateTwoVendorsSameName(Vendor);

        // Exercise: Select existing Vendor - second one in the page handler
        LibraryVariableStorage.Enqueue(Vendor.Name); // for the Vendor list page handler
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(CopyStr(Vendor.Name, 2, StrLen(Vendor.Name) - 1));

        // Verify.
        VerifyPurchaseInvoiceAgainstVendor(PurchaseInvoice, Vendor);
    end;

    [Test]
    [HandlerFunctions('VendorListCancelPageHandler')]
    [Scope('OnPrem')]
    procedure VendorsWithSameNameCancelSelect()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        CreateTwoVendorsSameName(Vendor);

        // Exercise: Select existing Vendor - second one in the page handler
        LibraryVariableStorage.Enqueue(Vendor.Name); // for the Vendor list page handler
        PurchaseInvoice.OpenNew();
        asserterror PurchaseInvoice."Buy-from Vendor Name".SetValue(CopyStr(Vendor.Name, 2, StrLen(Vendor.Name) - 1));
        Assert.ExpectedError(SelectVendorErr);
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseCodeCardPageHandler')]
    [Scope('OnPrem')]
    procedure CreateInvoiceFromStandardPurchaseCodes()
    begin
        Initialize();

        RunCreateInvoiceFromStandardPurchaseCodes();
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseCodeCardPageHandler')]
    [Scope('OnPrem')]
    procedure CreateInvoiceFromStandardPurchaseCodesStandard()
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        RunCreateInvoiceFromStandardPurchaseCodes();
    end;

    local procedure RunCreateInvoiceFromStandardPurchaseCodes()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Create data
        LibrarySmallBusiness.CreateItem(Item);
        CreateVendor(Vendor);
        LibrarySmallBusiness.CreateStandardPurchaseCode(StandardPurchaseCode);
        LibrarySmallBusiness.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseCode.Code);
        CreatePurchaseStandardCodeWithItemAndDescr(StandardPurchaseCode, Item);

        // Exercise
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.GetRecurringPurchaseLines.Invoke();

        // Verify
        VerifyPurchaseInvoiceLinesFromStandardCodes(PurchaseHeader, StandardPurchaseCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStandardCodeCreationPurchase()
    begin
        Initialize();

        RunCheckStandardCodeCreationPurchase();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStandardCodeCreationPurchaseStandard()
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        RunCheckStandardCodeCreationPurchase();
    end;

    local procedure RunCheckStandardCodeCreationPurchase()
    var
        Item: Record Item;
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        // Create data
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateStandardPurchaseCode(StandardPurchaseCode);

        // Exercise
        CreatePurchaseStandardCodeWithItemAndDescr(StandardPurchaseCode, Item);

        // Verify
        VerifyStandardPurchaseCodes(StandardPurchaseCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemListShowsTypeColumn()
    var
        Item: Record Item;
        ItemAsService: Record Item;
        ItemList: TestPage "Item List";
    begin
        Initialize();
        ClearTable(DATABASE::"Production BOM Line");
        LibraryLowerPermissions.AddItemCreate();

        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateItemAsService(ItemAsService);

        LibraryLowerPermissions.SetOutsideO365Scope();
        ItemList.OpenView();
        ItemList.Filter.SetFilter("No.", ItemAsService."No.");
        ItemList.Type.AssertEquals(ItemAsService.Type);
        ItemList.Filter.SetFilter("No.", Item."No.");
        ItemList.Type.AssertEquals(Item.Type);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCardControls()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();
        ClearTable(DATABASE::"Production BOM Line");
        ClearTable(DATABASE::"Troubleshooting Setup");
        ClearTable(DATABASE::"Resource Skill");
        ClearTable(DATABASE::"Item Identifier");
        ClearTable(DATABASE::"Service Item Component");
        ClearTable(Database::"Item Templ.");

        LibraryLowerPermissions.AddItemCreate();

        ItemCard.OpenNew();
        ItemCard.Description.SetValue(
          LibraryUtility.GenerateRandomCode(Item.FieldNo(Description),
            DATABASE::Item));

        Assert.IsTrue(ItemCard."Unit Cost".Editable(),
          Format('Unit Cost should be enabled when Type is %1 and no ILEs exists', Item.Type::Service.AsInteger()));

        ItemCard.Type.SetValue(Format(Item.Type::Service));
        Assert.IsFalse(ItemCard."Inventory Posting Group".Editable(),
          Format('Inventory Posting Group should be disabled when Type is %1.', Item.Type::Service.AsInteger()));
        Assert.IsFalse(ItemCard.Inventory.Editable(),
          Format('Inventory should be disabled when Type is %1.', Item.Type::Service.AsInteger()));
        Assert.IsTrue(ItemCard."Unit Cost".Editable(),
          Format('Unit Cost should be enabled when Type is %1.', Item.Type::Service.AsInteger()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardAndListControls()
    var
        Vendor: Record Vendor;
        PostCode: Record "Post Code";
        VendorCard: TestPage "Vendor Card";
        VendorList: TestPage "Vendor List";
        RandomContact: Code[30];
        PhoneNumber: Text;
    begin
        Initialize();
        LibrarySmallBusiness.CreateVendor(Vendor);

        // invoke Edit on the created vendor, from the vendor list
        VendorList.OpenView();
        VendorList.Filter.SetFilter("No.", Vendor."No.");
        VendorCard.Trap();
        VendorList.Edit().Invoke();

        // modify some fields on the vendor card
        VendorCard.Address.SetValue(LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        VendorCard."Address 2".SetValue(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Address 2"), DATABASE::Vendor));
        LibraryERM.CreatePostCode(PostCode);
        VendorCard.City.SetValue(PostCode.City);
        VendorCard."Post Code".SetValue(PostCode.Code);
        RandomContact := LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Contact), DATABASE::Vendor);
        VendorCard.Control16.SetValue(RandomContact);
        PhoneNumber := '+4544444444';
        VendorCard."Phone No.".SetValue(PhoneNumber);
        VendorCard.OK().Invoke();

        // verify vendor card modifications on the vendor list controls
        VendorList.Filter.SetFilter("No.", Vendor."No.");
        Assert.AreEqual(Vendor.Name, VendorList.Name.Value, 'Unexpected vendor name.');
        Assert.AreEqual(PhoneNumber, VendorList."Phone No.".Value, 'Unexpected vendor phone number.');
        Assert.AreEqual(RandomContact, VendorList.Contact.Value, 'Unexpected vendor contact.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromVendorList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();
        LibrarySmallBusiness.CreateVendor(Vendor);
        VendorList.OpenView();
        VendorList.Filter.SetFilter("No.", Vendor."No.");
        PurchaseInvoice.Trap();
        VendorList.NewPurchaseInvoice.Invoke();
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        PurchaseInvoice.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromVendorCard()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();
        LibrarySmallBusiness.CreateVendor(Vendor);
        VendorCard.OpenView();
        VendorCard.Filter.SetFilter("No.", Vendor."No.");
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        PurchaseInvoice.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCreditMemoFromVendorList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
    begin
        Initialize();
        LibrarySmallBusiness.CreateVendor(Vendor);
        VendorList.OpenView();
        VendorList.Filter.SetFilter("No.", Vendor."No.");
        LibraryVariableStorage.Enqueue(Vendor.Name);
        VendorList.NewPurchaseCrMemo.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseCreditMemoFromVendorCard()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();
        LibrarySmallBusiness.CreateVendor(Vendor);
        VendorCard.OpenView();
        VendorCard.Filter.SetFilter("No.", Vendor."No.");
        LibraryVariableStorage.Enqueue(Vendor.Name);
        VendorCard.NewPurchaseCrMemo.Invoke();
    end;

    [Test]
    [HandlerFunctions('LookupCancelVendorPurchOrderFromSalesOrderModalPageHandler,VendorLookupCancelPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderFromSalesOrderLookupVendorList()
    var
        SalesHeader: Record "Sales Header";
        ItemVendor: Record "Item Vendor";
        DummyPurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] User creates Purchase Order from Sales Order, use lookup for vendor field, shows vendor list
        Initialize();

        // [GIVEN] Sales Order with lines, no Item Vendor
        CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);
        ItemVendor.DeleteAll();

        // [WHEN] Create Purchase Order From Sales Order, user picks vendor through lookup, lookup shows vendor list, user cancels.
        SalesOrderCreatePurchaseOrder(SalesHeader, DummyPurchaseOrder);
    end;

    [Test]
    [HandlerFunctions('UserAcceptsWithoutChangesPurchOrderFromSalesOrderModalPageHandler,AssertMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderFromSalesOrderErrorIfNoVendorSelected()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DummyPurchaseOrder: TestPage "Purchase Order";
        VendorNo: Code[20];
    begin
        // [SCENARIO] User creates Purchase Order from Sales Order and forgets to specify a vendor.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Sales Order with lines, no default vendors for items.
        VendorNo := CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Create Purchase Order From Sales Order, user doesn't pick a vendor
        LibraryVariableStorage.Enqueue(CannotCreatePurchaseOrderWithoutVendorErr);
        SalesOrderCreatePurchaseOrder(SalesHeader, DummyPurchaseOrder);
        asserterror DummyPurchaseOrder.Close();
        Assert.ExpectedError('The TestPage is not open');

        // [THEN] Purchase Order for Vendor."No." doesn't exist.
        VerifyPurchaseDocumentCreationFromSalesDocumentCanceled(VendorNo, PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('EmptyPurchOrderFromSalesOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderFromSalesOrderWithNonPurchaseReplenishment()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        DummyPurchaseOrder: TestPage "Purchase Order";
        VendorNo: Code[20];
    begin
        // [SCENARIO] User creates Purchase Order from Sales Order where the Item has replenishment system Assembly
        Initialize();

        // [GIVEN] Sales Order with lines, Item has replenishment type Assembly
        VendorNo := CreateSalesHeaderAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);

        // Add item with Assembly replenishment
        LibrarySmallBusiness.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Modify(true);
        AddRandomNumberOfLinesToSalesHeader(SalesHeader, Item);

        // [WHEN] Create Purchase Order From Sales Order
        SalesOrderCreatePurchaseOrder(SalesHeader, DummyPurchaseOrder);

        // [THEN] Empty SalesOrderToPurchaseOrder page is opened. Verified in handler.
    end;

    [Test]
    [HandlerFunctions('UserCancelsPurchOrderFromSalesOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderFromSalesOrderCancel()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DummyPurchaseOrder: TestPage "Purchase Order";
        VendorNo: Code[20];
    begin
        // [SCENARIO] User cancels to create Purchase Order from Sales Order.
        Initialize();

        // [GIVEN] Sales Order with lines, no default vendors for items
        VendorNo := CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Create Purchase Order From Sales Order, user cancels
        SalesOrderCreatePurchaseOrder(SalesHeader, DummyPurchaseOrder);
        asserterror DummyPurchaseOrder.Close();
        Assert.ExpectedError('The TestPage is not open');

        // [THEN] Purchase Order for Vendor."No." doesn't exist.
        VerifyPurchaseDocumentCreationFromSalesDocumentCanceled(VendorNo, PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('UserAcceptsWithoutChangesPurchOrderFromSalesOrderModalPageHandler,AllItemsAreAvailableNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseOrderFromSalesOrderWithAllAvailable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AvailableItem: Record Item;
        DummyPurchaseOrder: TestPage "Purchase Order";
        VendorNo: Code[20];
        AvailableQuantity: Integer;
    begin
        // [SCENARIO] User creates Purchase Order from Sales Order, Item is already available
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Sales Order with 1 items, fully available
        VendorNo := CreateSalesHeaderAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);

        LibrarySmallBusiness.CreateItem(AvailableItem);
        CreateDefaultVendorForItem(AvailableItem);

        AvailableQuantity := LibraryRandom.RandIntInRange(1, 100);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, AvailableItem."No.", AvailableQuantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, AvailableItem, AvailableQuantity);

        // [WHEN] Create Purchase Order From Sales Order
        asserterror SalesOrderCreatePurchaseOrder(SalesHeader, DummyPurchaseOrder);
        Assert.ExpectedError(NoPurchaseOrdersCreatedErr);
        asserterror DummyPurchaseOrder.Close();
        Assert.ExpectedError('The TestPage is not open');

        // [THEN] Purchase Order for Vendor."No." is created
        VerifyPurchaseDocumentCreationFromSalesDocumentCanceled(VendorNo, PurchaseHeader."Document Type"::Order);
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesInvoiceAllLines()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Invoice, choses all lines, no default vendors for items.
        Initialize();

        // [GIVEN] Sales Invoice with lines, no default vendors for items, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateNewSalesLineWithDescription(SalesHeader);

        // [WHEN] Create Purchase Invoice From Sales Invoice, user choses all lines, Vendor."No".
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for Vendor."No." contains all the same lines as Sales Invoice.
        VerifyPurchaseDocumentCreatedFromSalesDocument(VendorNo, PurchaseHeader."Document Type"::Invoice, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesInvoiceSelectedLines()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Invoice, selects one line, no default vendors for items.
        Initialize();

        // [GIVEN] Sales Invoice with lines, no default vendors for items, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Create Purchase Invoice From Sales Invoice, user selects one line, Vendor."No.".
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::Selected, VendorNo, false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for Vendor."No." contains only one line, corresponding first line of Sales Invoice.
        VerifyPurchaseDocumentCreatedFromSelectedLineOfSalesDocument(
          VendorNo, SalesHeader, GetSalesLineNo(1, SalesHeader), PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesInvoiceNoLines()
    var
        SalesHeader: Record "Sales Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Invoice which contains no lines.
        Initialize();

        // [GIVEN] Sales Invoice without lines, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Create Purchase Invoice From Sales Invoice, user choses all lines, Vendor."No".
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for Vendor."No." contains no lines.
        VerifyPurchaseInvoiceCreatedFromSalesDocumentNoLines(VendorNo);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesInvoiceCancelScenarios()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User cancels to create Purchase Invoice from Sales Invoice.
        Initialize();

        // [GIVEN] Sales Invoice with lines, no default vendors for items, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] User cancels to create Purchase Invoice from Sales Invoice.
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::None, '', false);

        // [THEN] Purchase Invoice for VendorNo doesn't exist.
        VerifyPurchaseDocumentCreationFromSalesDocumentCanceled(VendorNo, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Creating Purchase Invoice from Sales Invoice, user choses all lines and Vendor."No.", cancels action in Vendor list
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, true);

        // [THEN] Purchase Invoice for Vendor."No." doesn't exist.
        VerifyPurchaseDocumentCreationFromSalesDocumentCanceled(VendorNo, PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesInvoiceAndPost()
    var
        SalesHeader: Record "Sales Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Invoice and posts this Purchase Invoice.
        Initialize();

        // [GIVEN] Sales Invoice with lines, no default vendors for items, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Create Purchase Invoice From Sales Invoice, user choses all lines, VendorNo and posts this Purchase Invoice.
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, false);
        PostPurchaseInvoice(PurchaseInvoice);

        // [THEN] Last Posted Purchase Invoice for Vendor."No." contains all the same lines as Sales Invoice.
        VerifyPostedPurchaseDocumentCreatedFromSalesDocument(VendorNo, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesOrderAllLines()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Order, choses all lines, no default vendors for items.
        Initialize();

        // [GIVEN] Sales Order with lines, no default vendors for items, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);
        CreateNewSalesLineWithDescription(SalesHeader);

        // [WHEN] Create Purchase Invoice From Sales Order, user choses all lines, Vendor."No".
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for Vendor."No." contains all the same lines as Sales Order.
        VerifyPurchaseDocumentCreatedFromSalesDocument(VendorNo, PurchaseHeader."Document Type"::Invoice, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesOrderSelectedLines()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Order, selects one line, no default vendors for items.
        Initialize();

        // [GIVEN] Sales Order with lines, no default vendors for items, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Create Purchase Invoice From Sales Order, user selects one line, Vendor."No.".
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::Selected, VendorNo, false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for VendorNo contains only one line, corresponding first line of Sales Order.
        VerifyPurchaseDocumentCreatedFromSelectedLineOfSalesDocument(
          VendorNo, SalesHeader, GetSalesLineNo(1, SalesHeader), PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesOrderNoLines()
    var
        SalesHeader: Record "Sales Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Order which contains no lines.
        Initialize();

        // [GIVEN] Sales Order without lines, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Create Purchase Invoice From Sales Order, user choses all lines, Vendor."No".
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for Vendor."No." contains no lines.
        VerifyPurchaseInvoiceCreatedFromSalesDocumentNoLines(VendorNo);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesOrderCancelScenarios()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User cancels to create Purchase Invoice from Sales Order.
        Initialize();

        // [GIVEN] Sales Order with lines, no default vendors for items, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] User cancels to create Purchase Invoice from Sales Order.
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::None, '', false);

        // [THEN] Purchase Invoice for Vendor."No." doesn't exist.
        VerifyPurchaseDocumentCreationFromSalesDocumentCanceled(VendorNo, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Creating Purchase Invoice from Sales Order, user choses all lines and Vendor."No.", but cancels action in Vendor list.
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, true);

        // [THEN] Purchase Invoice for Vendor."No." doesn't exist.
        VerifyPurchaseDocumentCreationFromSalesDocumentCanceled(VendorNo, PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesOrderAndPost()
    var
        SalesHeader: Record "Sales Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Order and posts this Purchase Invoice.
        Initialize();

        // [GIVEN] Sales Order with lines, no default vendors for items, Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderWithLinesAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Create Purchase Invoice From Sales Order, user choses all lines, Vendor."No." and posts this Purchase Invoice.
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, false);
        PostPurchaseInvoice(PurchaseInvoice);

        // [THEN] Last Posted Purchase Invoice for Vendor."No." contains all the same lines as Sales Order.
        VerifyPostedPurchaseDocumentCreatedFromSalesDocument(VendorNo, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesInvoiceWithSameItemVendor()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Vendor]
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Invoice, choses all lines, same default vendor for all items.
        Initialize();

        // [GIVEN] Sales Invoice with lines, same default vendor for all items and his "No.".
        VendorNo := CreateSalesHeaderWithLinesForOneDefaultVendor(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateNewSalesLineWithDescription(SalesHeader);

        // [WHEN] Create Purchase Invoice From Sales Invoice, user choses all lines, no Vendor."No.".
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, '', false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for Vendor."No." contains all the same lines as Sales Invoice.
        VerifyPurchaseDocumentCreatedFromSalesDocument(VendorNo, PurchaseHeader."Document Type"::Invoice, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesInvoiceWithDifferentItemVendors()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Vendor]
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Invoice, choses all lines, two items with different default vendors
        Initialize();

        // [GIVEN] Sales Invoice with lines, two default vendors for all items and Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderWithLinesForTwoDefaultVendorsAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateNewSalesLineWithDescription(SalesHeader);

        // [WHEN] Create Purchase Invoice From Sales Invoice, user choses all lines and VendorNo.
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for Vendor."No." contains all the same lines as Sales Invoice.
        VerifyPurchaseDocumentCreatedFromSalesDocument(VendorNo, PurchaseHeader."Document Type"::Invoice, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesOrderWithSameItemVendor()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Vendor]
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Order, choses all lines, same default vendor for all items.
        Initialize();

        // [GIVEN] Sales Order with lines, same default vendor for all items and his "No.".
        VendorNo := CreateSalesHeaderWithLinesForOneDefaultVendor(SalesHeader, SalesHeader."Document Type"::Order);
        CreateNewSalesLineWithDescription(SalesHeader);

        // [WHEN] Create Purchase Invoice From Sales Order, user choses all lines, no VendorNo.
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, '', false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for VendorNo contains all the same lines as Sales Invoice.
        VerifyPurchaseDocumentCreatedFromSalesDocument(VendorNo, PurchaseHeader."Document Type"::Invoice, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreatePurchaseInvoiceHandler,SelectVendorHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceFromSalesOrderWithDifferentItemVendors()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Vendor]
        // [SCENARIO 163013] User creates Purchase Invoice from Sales Order, choses all lines, two items with different default vendors
        Initialize();

        // [GIVEN] Sales Order with lines, two default vendors for all items and Vendor."No." will be chosen by user.
        VendorNo := CreateSalesHeaderWithLinesForTwoDefaultVendorsAndSelectVendor(SalesHeader, SalesHeader."Document Type"::Order);
        CreateNewSalesLineWithDescription(SalesHeader);

        // [WHEN] Create Purchase Invoice From Sales Order, user choses all lines and VendorNo.
        CreatePurchaseInvoiceFromSalesDocument(PurchaseInvoice, SalesHeader, CopyItemsOption::All, VendorNo, false);
        PurchaseInvoice.Close();

        // [THEN] Last Purchase Invoice for Vendor."No." contains all the same lines as Sales Invoice.
        VerifyPurchaseDocumentCreatedFromSalesDocument(VendorNo, PurchaseHeader."Document Type"::Invoice, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreateSQuoteHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteFromCustomerCard()
    var
        Cust: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();
        ClearTable(DATABASE::"Res. Ledger Entry");

        MakeQuoteNoSeriesNotManual();
        LibrarySmallBusiness.CreateCustomer(Cust);

        CustomerCard.OpenView();
        CustomerCard.Filter.SetFilter("No.", Cust."No.");
        SellToCustomerName4HandlerFunction := Cust.Name;

        CustomerCard.NewSalesQuote.Invoke();

        CustomerCard.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CreateSQuoteHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteFromCustomerList()
    var
        Cust: Record Customer;
        CustomerList: TestPage "Customer List";
    begin
        Initialize();

        MakeQuoteNoSeriesNotManual();
        LibrarySmallBusiness.CreateCustomer(Cust);

        CustomerList.OpenView();
        CustomerList.Filter.SetFilter("No.", Cust."No.");
        SellToCustomerName4HandlerFunction := Cust.Name;

        CustomerList.NewSalesQuote.Invoke();

        CustomerList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CreateSQuoteHandler(var SalesQuote: TestPage "Sales Quote")
    begin
        Assert.AreEqual(SellToCustomerName4HandlerFunction, SalesQuote."Sell-to Customer Name".Value, 'Wrong Customer selected');

        SalesQuote.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLinesControlsItem()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateItem(Item);
        CreateCustomer(Customer);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        // Set item on line - if no errors than is ok
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(100, 2));

        LibraryVariableStorage.Enqueue(true); // for the posting confirm handler
        LibrarySales.DisableConfirmOnPostingDoc();
        SalesInvoice.Post.Invoke();

        VerifyUnitCostOnItemCard(Item, false); // ILEs exist and control should be non - editable
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLinesControlsService()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();
        ClearTable(DATABASE::"Production BOM Line");

        LibrarySmallBusiness.CreateItemAsService(Item);
        CreateCustomer(Customer);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        // Set item as service on line - if no errors than is ok
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(100, 2));

        LibraryVariableStorage.Enqueue(true); // for the posting confirm handler
        LibrarySales.DisableConfirmOnPostingDoc();
        SalesInvoice.Post.Invoke();

        VerifyUnitCostOnItemCard(Item, true); // ILEs exist and control should be editable
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateAutoFilled()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        CreateCustomer(Customer);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        Assert.AreEqual(SalesInvoice."Payment Terms Code".Value,
          Customer."Payment Terms Code", 'Payment Terms Code should be empty by default');
        Assert.AreEqual(SalesInvoice."Due Date".AsDate(), SalesInvoice."Document Date".AsDate(), 'Due Date incorrectly calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateUpdatedWithPaymentTermsChange()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        SalesInvoice: TestPage "Sales Invoice";
        ExpectedDueDate: Date;
    begin
        Initialize();

        CreateCustomer(Customer);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        PaymentTerms.FindLast();
        SalesInvoice."Payment Terms Code".SetValue(PaymentTerms.Code);
        ExpectedDueDate := CalcDate(PaymentTerms."Due Date Calculation", SalesInvoice."Document Date".AsDate());
        Assert.AreEqual(SalesInvoice."Due Date".AsDate(), ExpectedDueDate, 'Due Date incorrectly calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentDatePresentOnSalesInvoice()
    var
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        SalesInvoice.OpenNew();
        Assert.IsTrue(SalesInvoice."Shipment Date".Enabled(),
          Format('Shipment Date should be present on Sales Invoice'));

        PostedSalesInvoice.OpenView();
        Assert.IsTrue(SalesInvoice."Shipment Date".Enabled(),
          Format('Shipment Date should be present on Posted Sales Invoice'));
    end;

    [Test]
    [HandlerFunctions('StandardSalesCodeCardPageHandler')]
    [Scope('OnPrem')]
    procedure CreateInvoiceFromStandardSalesCodes()
    begin
        Initialize();

        RunCreateInvoiceFromStandardSalesCodes();
    end;

    [Test]
    [HandlerFunctions('StandardSalesCodeCardPageHandler')]
    [Scope('OnPrem')]
    procedure CreateInvoiceFromStandardSalesCodesStandard()
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        RunCreateInvoiceFromStandardSalesCodes();
    end;

    local procedure RunCreateInvoiceFromStandardSalesCodes()
    var
        Item: Record Item;
        Customer: Record Customer;
        StandardSalesCode: Record "Standard Sales Code";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Create data
        LibrarySmallBusiness.CreateItem(Item);
        CreateCustomer(Customer);
        LibrarySmallBusiness.CreateStandardSalesCode(StandardSalesCode);
        LibrarySmallBusiness.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesCode.Code);
        CreateStandardCodeWithItemAndDescr(StandardSalesCode, Item);

        // Exercise
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.GetRecurringSalesLines.Invoke();

        // Verify
        VerifyInvoiceLinesFromStandardCodes(SalesHeader, StandardSalesCode);
    end;

    [Test]
    [HandlerFunctions('StandardSalesCodeCardPageHandler')]
    [Scope('OnPrem')]
    procedure CreateQuoteFromStandardSalesCodes()
    begin
        Initialize();

        RunCreateQuoteFromStandardSalesCodes();
    end;

    [Test]
    [HandlerFunctions('StandardSalesCodeCardPageHandler')]
    [Scope('OnPrem')]
    procedure CreateQuoteFromStandardSalesCodesStandard()
    begin
        Initialize();
        ClearTable(DATABASE::"Job Planning Line");

        LibraryApplicationArea.DisableApplicationAreaSetup();

        RunCreateQuoteFromStandardSalesCodes();
    end;

    local procedure RunCreateQuoteFromStandardSalesCodes()
    var
        Item: Record Item;
        Customer: Record Customer;
        StandardSalesCode: Record "Standard Sales Code";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // Create data
        LibrarySmallBusiness.CreateItem(Item);
        CreateCustomer(Customer);
        LibrarySmallBusiness.CreateStandardSalesCode(StandardSalesCode);
        LibrarySmallBusiness.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesCode.Code);
        CreateStandardCodeWithItemAndDescr(StandardSalesCode, Item);

        // Exercise
        LibrarySmallBusiness.CreateSalesQuoteHeader(SalesHeader, Customer);
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");
        SalesQuote.GetRecurringSalesLines.Invoke();

        // Verify
        VerifyInvoiceLinesFromStandardCodes(SalesHeader, StandardSalesCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStandardCodeCreation()
    var
        Item: Record Item;
        StandardSalesCode: Record "Standard Sales Code";
    begin
        Initialize();

        // Create data
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateStandardSalesCode(StandardSalesCode);

        // Exercise
        CreateStandardCodeWithItemAndDescr(StandardSalesCode, Item);

        // Verify
        VerifyStandardCodes(StandardSalesCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceExternalDocNoFieldIsVisibleUnderBasicExperience()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Application Area] [Invoice]
        // [SCENARIO 207959] Sales Invoice's "External Document No." field must be visible in Basic application area setup

        // [GIVEN] Setup "Experience" = "Basic"
        LibraryApplicationArea.EnableBasicSetup();

        // [WHEN] Open Sales Invoice page
        SalesInvoice.OpenNew();

        // [THEN] Field "External Document No." is visible
        Assert.IsTrue(SalesInvoice."External Document No.".Visible(), '');

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesHeaderSellToName()
    var
        SalesHeader: Record "Sales Header";
        NewName: Text[100];
    begin
        // [SCENARIO 288843] User is able to change document Sell-to Customer Name after sell-to customer had been specified when Customer has "Disable Search by Name" = TRUE
        Initialize();

        // [GIVEN] Create sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [GIVEN] Customer has "Disable Search by Name" = TRUE
        SetCustomerDisableSearchByName(SalesHeader."Sell-to Customer No.");

        // [WHEN] "Sell-to Customer Name" is being changed to 'XXX'
        NewName := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Sell-to Customer Name"), DATABASE::"Sales Header");
        SalesHeader.Validate("Sell-to Customer Name", NewName);

        // [THEN] Field "Sell-to Customer Name" value changed to 'XXX'
        SalesHeader.TestField("Sell-to Customer Name", NewName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesHeaderBillToName()
    var
        SalesHeader: Record "Sales Header";
        NewName: Text[100];
    begin
        // [SCENARIO 288843] User is able to change document Bill-to Name after bill-to customer had been specified when Customer has "Disable Search by Name" = TRUE
        Initialize();

        // [GIVEN] Create sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [GIVEN] Customer has "Disable Search by Name" = TRUE
        SetCustomerDisableSearchByName(SalesHeader."Bill-to Customer No.");

        // [WHEN] "Bill-to Name" is being changed to 'XXX'
        NewName := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Bill-to Name"), DATABASE::"Sales Header");
        SalesHeader.Validate("Bill-to Name", NewName);

        // [THEN] Field "Bill-to Name" value changed to 'XXX'
        SalesHeader.TestField("Bill-to Name", NewName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesHeaderSellToNameSalesSetupDisableSearchByName()
    var
        SalesHeader: Record "Sales Header";
        NewName: Text[100];
    begin
        // [SCENARIO 362012] User is able to change document Sell-to Customer Name after sell-to customer had been specified when SalesSetup has "Disable Search by Name" = TRUE
        Initialize();

        // [GIVEN] Create sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [GIVEN] SalesSetup has "Disable Search by Name" = TRUE
        SetSalesSetupDisableSearchByName(true);

        // [WHEN] "Sell-to Customer Name" is being changed to 'XXX'
        NewName := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Sell-to Customer Name"), DATABASE::"Sales Header");
        SalesHeader.Validate("Sell-to Customer Name", NewName);

        // [THEN] Field "Sell-to Customer Name" value changed to 'XXX'
        SalesHeader.TestField("Sell-to Customer Name", NewName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesOrderSellToNameDisableSearchByName()
    var
        SalesHeader: Record "Sales Header";
        NewName: Text[100];
        SalesOrder: TestPage "Sales Order";
        BillToOptions: Option "Default (Customer)","Another Customer","Custom Address";
    begin
        // [SCENARIO 424124] Bill-to Name should be editable when Sales Order created for Customer with Disable Search By Name = true
        Initialize();

        // [GIVEN] Create Sales Order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [GIVEN] Customer has "Disable Search by Name" = TRUE
        SetCustomerDisableSearchByName(SalesHeader."Sell-to Customer No.");

        // [GIVEN] "Sell-to Customer Name" is being changed to 'Test'
        NewName := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Sell-to Customer Name"), DATABASE::"Sales Header");

        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder."Sell-to Customer Name".SetValue(NewName);

        // [WHEN] Bill-to = "Custom Address"
        SalesOrder.BillToOptions.SetValue(BillToOptions::"Custom Address");

        // [THEN] "Bill-to Name" field is editable and the value can be changed
        Assert.IsTrue(SalesOrder."Bill-to Name".Editable(), 'Bill-to Name is not editable');
        SalesOrder."Bill-to Name".SetValue(NewName);
        SalesOrder."Bill-to Name".AssertEquals(NewName);
    end;

    local procedure Initialize()
    var
        CustomerTempl: Record "Customer Templ.";
        VendorTempl: Record "Vendor Templ.";
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        MarketingSetup: Record "Marketing Setup";
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        AssemblySetup: Record "Assembly Setup";
        SalesHeader: Record "Sales Header";
        MyNotifications: Record "My Notifications";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryAssembly: Codeunit "Library - Assembly";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Simplify UI Sales Invoice");
        LibraryVariableStorage.Clear();
        CustomerTempl.DeleteAll();
        VendorTempl.DeleteAll();
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());

        Customer.DeleteAll();
        Vendor.DeleteAll();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Simplify UI Sales Invoice");
        LibrarySetupStorage.Restore();
        LibraryTemplates.EnableTemplatesFeature();
        ClearTable(DATABASE::Resource);

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();
        LibrarySmallBusiness.CreateResponsabilityCenter(ResponsibilityCenter);

        Clear(UserSetup);
        UserSetup.DeleteAll();
        UserSetup."User ID" := UserId;
        UserSetup.Validate("Sales Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Validate("Purchase Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Insert(true);

        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibrarySales.SetStockoutWarning(false);

        CompanyInformation.Get();
        CompanyInformation."Bank Account No." := 'A';
        CompanyInformation.Modify();

        // Required for full DK (not mini)
        MarketingSetup.Get();
        MarketingSetup.Validate("Maintain Dupl. Search Strings", false);
        MarketingSetup.Modify(true);

        // Assembly Setup
        if not AssemblySetup.Get() then
            AssemblySetup.Insert();
        LibraryAssembly.CreateAssemblySetup(AssemblySetup, '', 0, LibraryUtility.GetGlobalNoSeriesCode());
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        // Disable notifications
        if MyNotifications.Get(UserId, SalesHeader.GetShowExternalDocAlreadyExistNotificationId()) then
            MyNotifications.Delete();
        SalesHeader.SetShowExternalDocAlreadyExistNotificationDefaultState(false);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Simplify UI Sales Invoice");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        ProductionBOMLine: Record "Production BOM Line";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        Resource: Record Resource;
        ResourceSkill: Record "Resource Skill";
        ItemIdentifier: Record "Item Identifier";
        ServiceItemComponent: Record "Service Item Component";
        ItemTempl: Record "Item Templ.";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Res. Ledger Entry":
                ResLedgerEntry.DeleteAll();
            DATABASE::"Job Planning Line":
                JobPlanningLine.DeleteAll();
            DATABASE::Job:
                Job.DeleteAll();
            DATABASE::"Production BOM Line":
                ProductionBOMLine.DeleteAll();
            DATABASE::"Troubleshooting Setup":
                TroubleshootingSetup.DeleteAll();
            DATABASE::Resource:
                Resource.DeleteAll();
            DATABASE::"Resource Skill":
                ResourceSkill.DeleteAll();
            DATABASE::"Item Identifier":
                ItemIdentifier.DeleteAll();
            DATABASE::"Service Item Component":
                ServiceItemComponent.DeleteAll();
            Database::"Item Templ.":
                ItemTempl.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer));
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate("Address 2", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Address 2"), DATABASE::Customer));
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Validate("Post Code", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Post Code"), DATABASE::Customer));
        Customer.Modify();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Vendor));
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate("Address 2", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Address 2"), DATABASE::Vendor));
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Validate("Post Code", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Post Code"), DATABASE::Vendor));
        Vendor.Modify();
    end;

    local procedure CreateTwoCustomersSameName(var Customer: Record Customer)
    var
        Customer1: Record Customer;
    begin
        CreateCustomer(Customer1);
        CreateCustomer(Customer);
        Customer.Validate(Name, Customer1.Name);
        Customer.Modify(true);
    end;

    local procedure CreateTwoVendorsSameName(var Vendor: Record Vendor)
    var
        Vendor1: Record Vendor;
    begin
        CreateVendor(Vendor1);
        CreateVendor(Vendor);
        Vendor.Validate(Name, Vendor1.Name);
        Vendor.Modify(true);
    end;

    local procedure CreateCommentForItem(var Item: Record Item)
    var
        CommentLine: Record "Comment Line";
    begin
        LibrarySmallBusiness.CreateCommentLine(CommentLine, CommentLine."Table Name"::Item, Item."No.");
        CommentLine.Validate(Code, LibraryUtility.GenerateRandomCode(CommentLine.FieldNo(Code),
            DATABASE::"Comment Line"));
        CommentLine.Validate(Comment, LibraryUtility.GenerateRandomCode(CommentLine.FieldNo(Comment),
            DATABASE::"Comment Line"));
        CommentLine.Modify(true);
    end;

    local procedure VerifyCustomerAgainstTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        Customer.TestField("Gen. Bus. Posting Group", CustomerTempl."Gen. Bus. Posting Group");
        Customer.TestField("VAT Bus. Posting Group", CustomerTempl."VAT Bus. Posting Group");
        Customer.TestField("Customer Posting Group", CustomerTempl."Customer Posting Group");
    end;

    local procedure VerifyVendorAgainstTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
        Vendor.TestField("Gen. Bus. Posting Group", VendorTempl."Gen. Bus. Posting Group");
        Vendor.TestField("VAT Bus. Posting Group", VendorTempl."VAT Bus. Posting Group");
        Vendor.TestField("Vendor Posting Group", VendorTempl."Vendor Posting Group");
    end;

    local procedure VerifySalesInvoiceAgainstCustomer(SalesInvoice: TestPage "Sales Invoice"; Customer: Record Customer)
    begin
        SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
        SalesInvoice."Sell-to Address".AssertEquals(Customer.Address);
        SalesInvoice."Sell-to City".AssertEquals(Customer.City);
        SalesInvoice."Sell-to Post Code".AssertEquals(Customer."Post Code");
    end;

    local procedure VerifySalesInvoiceAgainstBillToCustomer(SalesInvoice: TestPage "Sales Invoice"; Customer: Record Customer)
    begin
        SalesInvoice."Bill-to Name".AssertEquals(Customer.Name);
        SalesInvoice."Bill-to Address".AssertEquals(Customer.Address);
        SalesInvoice."Bill-to City".AssertEquals(Customer.City);
        SalesInvoice."Bill-to Post Code".AssertEquals(Customer."Post Code");
    end;

    local procedure VerifySellToEmptyOnSalesInvoice(SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice."Sell-to Customer Name".AssertEquals('');
        SalesInvoice."Sell-to Address".AssertEquals('');
        SalesInvoice."Sell-to City".AssertEquals('');
        SalesInvoice."Sell-to Post Code".AssertEquals('');
    end;

    local procedure VerifySalesQuoteAgainstCustomer(SalesQuote: TestPage "Sales Quote"; Customer: Record Customer)
    begin
        SalesQuote."Sell-to Customer Name".AssertEquals(Customer.Name);
        SalesQuote."Sell-to Address".AssertEquals(Customer.Address);
        SalesQuote."Sell-to City".AssertEquals(Customer.City);
        SalesQuote."Sell-to Post Code".AssertEquals(Customer."Post Code");
    end;

    local procedure VerifySalesQuoteAgainstBillToCustomer(SalesQuote: TestPage "Sales Quote"; Customer: Record Customer)
    begin
        SalesQuote."Bill-to Name".AssertEquals(Customer.Name);
        SalesQuote."Bill-to Address".AssertEquals(Customer.Address);
        SalesQuote."Bill-to City".AssertEquals(Customer.City);
        SalesQuote."Bill-to Post Code".AssertEquals(Customer."Post Code");
    end;

    local procedure VerifySellToEmptyOnSalesQuote(SalesQuote: TestPage "Sales Quote")
    begin
        SalesQuote."Sell-to Customer Name".AssertEquals('');
        SalesQuote."Sell-to Address".AssertEquals('');
        SalesQuote."Sell-to City".AssertEquals('');
        SalesQuote."Sell-to Post Code".AssertEquals('');
    end;

    local procedure VerifyPurchaseInvoiceAgainstVendor(PurchaseInvoice: TestPage "Purchase Invoice"; Vendor: Record Vendor)
    begin
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        PurchaseInvoice."Buy-from Address".AssertEquals(Vendor.Address);
        PurchaseInvoice."Buy-from City".AssertEquals(Vendor.City);
        PurchaseInvoice."Buy-from Post Code".AssertEquals(Vendor."Post Code");
    end;

    local procedure VerifyPurchaseInvoiceAgainstPayToVendor(PurchaseInvoice: TestPage "Purchase Invoice"; Vendor: Record Vendor)
    begin
        PurchaseInvoice."Pay-to Name".AssertEquals(Vendor.Name);
        PurchaseInvoice."Pay-to Address".AssertEquals(Vendor.Address);
        PurchaseInvoice."Pay-to City".AssertEquals(Vendor.City);
        PurchaseInvoice."Pay-to Post Code".AssertEquals(Vendor."Post Code");
    end;

    local procedure VerifyUnitCostOnItemCard(Item: Record Item; Editable: Boolean)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");
        Assert.IsTrue(ItemCard."Unit Cost".Editable() = Editable,
          'Editable property for Unit cost field should be: ' + Format(Editable));
    end;

    local procedure VerifyInvoiceLinesFromStandardCodes(SalesHeader: Record "Sales Header"; StandardSalesCode: Record "Standard Sales Code")
    var
        SalesLine: Record "Sales Line";
        StandardSalesLine: Record "Standard Sales Line";
    begin
        StandardSalesLine.SetRange("Standard Sales Code", StandardSalesCode.Code);
        if StandardSalesLine.FindSet() then
            repeat
                SalesLine.Reset();
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.SetRange("No.", StandardSalesLine."No.");
                SalesLine.SetRange(Description, StandardSalesLine.Description);
                SalesLine.SetRange(Quantity, StandardSalesLine.Quantity);
                SalesLine.SetRange(Type, StandardSalesLine.Type);

                Assert.IsTrue(SalesLine.FindFirst(), 'No lines with filter ' + SalesLine.GetFilters);
            until StandardSalesLine.Next() = 0;
    end;

    local procedure VerifyPurchaseInvoiceLinesFromStandardCodes(PurchaseHeader: Record "Purchase Header"; StandardPurchaseCode: Record "Standard Purchase Code")
    var
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
    begin
        StandardPurchaseLine.SetRange("Standard Purchase Code", StandardPurchaseCode.Code);
        if StandardPurchaseLine.FindSet() then
            repeat
                PurchaseLine.Reset();
                PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                PurchaseLine.SetRange("No.", StandardPurchaseLine."No.");
                PurchaseLine.SetRange(Description, StandardPurchaseLine.Description);
                PurchaseLine.SetRange(Quantity, StandardPurchaseLine.Quantity);
                PurchaseLine.SetRange(Type, StandardPurchaseLine.Type);

                Assert.IsTrue(PurchaseLine.FindFirst(), 'No lines with filter ' + PurchaseLine.GetFilters);
            until StandardPurchaseLine.Next() = 0;
    end;

    local procedure VerifyStandardCodes(StandardSalesCode: Record "Standard Sales Code")
    var
        StandardSalesLine: Record "Standard Sales Line";
    begin
        StandardSalesLine.SetRange("Standard Sales Code", StandardSalesCode.Code);
        if StandardSalesLine.FindSet() then
            repeat
                if StandardSalesLine."No." <> '' then
                    Assert.IsTrue(StandardSalesLine.Type = StandardSalesLine.Type::Item, 'Type should be ' +
                      Format(StandardSalesLine.Type::Item))
                else
                    if StandardSalesLine.Description <> '' then
                        Assert.IsTrue(StandardSalesLine.Type = StandardSalesLine.Type::" ", 'Type should be Empty');
            until StandardSalesLine.Next() = 0;
    end;

    local procedure VerifyStandardPurchaseCodes(StandardPurchaseCode: Record "Standard Purchase Code")
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
    begin
        StandardPurchaseLine.SetRange("Standard Purchase Code", StandardPurchaseCode.Code);
        if StandardPurchaseLine.FindSet() then
            repeat
                if StandardPurchaseLine."No." <> '' then
                    Assert.IsTrue(StandardPurchaseLine.Type = StandardPurchaseLine.Type::Item, 'Type should be ' +
                      Format(StandardPurchaseLine.Type::Item))
                else
                    if StandardPurchaseLine.Description <> '' then
                        Assert.IsTrue(StandardPurchaseLine.Type = StandardPurchaseLine.Type::" ", 'Type should be Empty');
            until StandardPurchaseLine.Next() = 0;
    end;

    local procedure FillSalesHeaderExcludedFieldList(var FieldListToExclude: List of [Text])
    begin
        LibraryERM.FillSalesHeaderExcludedFieldList(FieldListToExclude);
    end;

    local procedure FillSalesLineExcludedFieldList(var FieldListToExclude: List of [Text])
    var
        SalesLineRef: Record "Sales Line";
    begin
        FieldListToExclude.Add(SalesLineRef.FieldName("Document Type"));
        FieldListToExclude.Add(SalesLineRef.FieldName("Document No."));
        FieldListToExclude.Add(SalesLineRef.FieldName(Type));
        FieldListToExclude.Add(SalesLineRef.FieldName("Posting Date"));
        FieldListToExclude.Add(SalesLineRef.FieldName("Recalculate Invoice Disc."));
        FieldListToExclude.Add(SalesLineRef.FieldName(Subtype));

        OnAfterFillSalesLineExcludedFieldList(FieldListToExclude);
    end;

    local procedure FillPurchaseHeaderExcludedFieldList(var FieldListToExclude: List of [Text])
    var
        PurchaseHeaderRef: Record "Purchase Header";
    begin
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Document Type"));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Quote No."));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("No."));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Posting Date"));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Posting Description"));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("No. Series"));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Transaction Specification"));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Vendor Invoice No."));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Vendor Order No."));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Vendor Cr. Memo No."));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Vendor Shipment No."));
        FieldListToExclude.Add(PurchaseHeaderRef.FieldName("Recalculate Invoice Disc."));

        OnAfterFillPurchaseHeaderExcludedFieldList(FieldListToExclude);
    end;

    local procedure FillPurchaseLineExcludedFieldList(var FieldListToExclude: List of [Text])
    var
        PurchaseLineRef: Record "Purchase Line";
    begin
        FieldListToExclude.Add(PurchaseLineRef.FieldName("Document Type"));
        FieldListToExclude.Add(PurchaseLineRef.FieldName("Document No."));
        FieldListToExclude.Add(PurchaseLineRef.FieldName("Transaction Specification"));

        OnAfterFillPurchaseLineExcludedFieldList(FieldListToExclude);
    end;

    local procedure VerifySalesDocumentsMatch(SalesHeader1: Record "Sales Header"; SalesHeader2: Record "Sales Header")
    var
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        RecordRef1: RecordRef;
        RecordRef2: RecordRef;
        SalesHeaderExcludedFieldList: List of [Text];
        SalesLineExcludedFieldList: List of [Text];
        I: Integer;
    begin
        RecordRef1.GetTable(SalesHeader1);
        RecordRef2.GetTable(SalesHeader2);

        FillSalesHeaderExcludedFieldList(SalesHeaderExcludedFieldList);

        VerifyRecordRefsMatch(RecordRef1, RecordRef2, SalesHeaderExcludedFieldList);

        SalesLine1.SetRange("Document Type", SalesHeader1."Document Type");
        SalesLine1.SetRange("Document No.", SalesHeader1."No.");
        SalesLine2.SetRange("Document Type", SalesHeader2."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader2."No.");
        Assert.AreEqual(SalesLine1.Count, SalesLine2.Count, 'Both documents should have same number of lines');

        Clear(RecordRef1);
        RecordRef1.Open(DATABASE::"Sales Line");
        FillSalesLineExcludedFieldList(SalesLineExcludedFieldList);

        for I := 1 to SalesLine1.Count do begin
            SalesLine1.Next();
            SalesLine2.Next();
            RecordRef1.GetTable(SalesLine1);
            RecordRef2.GetTable(SalesLine2);
            VerifyRecordRefsMatch(RecordRef1, RecordRef2, SalesLineExcludedFieldList);
        end;
    end;

    local procedure VerifySortedCustomerList(var CustomerList: TestPage "Customer List")
    var
        CustomerCard: TestPage "Customer Card";
        CurrentCustomerNo: Code[20];
    begin
        CustomerList.First();
        repeat
            CurrentCustomerNo := CustomerList."No.".Value();
            CustomerCard.Trap();
            CustomerList.View().Invoke();
            Assert.AreEqual(CustomerCard."No.".Value, CurrentCustomerNo, 'Unexpected customer opened.');
        until not CustomerList.Next();
    end;

    local procedure VerifyPurchaseDocumentsMatch(PurchaseHeader1: Record "Purchase Header"; PurchaseHeader2: Record "Purchase Header")
    var
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        RecordRef1: RecordRef;
        RecordRef2: RecordRef;
        PurchaseHeaderExcludedFieldList: List of [Text];
        PurchaseLineExcludedFieldList: List of [Text];
        I: Integer;
    begin
        RecordRef1.GetTable(PurchaseHeader1);
        RecordRef2.GetTable(PurchaseHeader2);
        FillPurchaseHeaderExcludedFieldList(PurchaseHeaderExcludedFieldList);

        VerifyRecordRefsMatch(RecordRef1, RecordRef2, PurchaseHeaderExcludedFieldList);

        PurchaseLine1.SetRange("Document Type", PurchaseHeader1."Document Type");
        PurchaseLine1.SetRange("Document No.", PurchaseHeader1."No.");
        PurchaseLine2.SetRange("Document Type", PurchaseHeader2."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseHeader2."No.");
        Assert.AreEqual(PurchaseLine1.Count, PurchaseLine2.Count, 'Both documents should have same number of lines');

        Clear(RecordRef1);
        RecordRef1.Open(DATABASE::"Purchase Line");
        FillPurchaseLineExcludedFieldList(PurchaseLineExcludedFieldList);

        for I := 1 to PurchaseLine1.Count do begin
            PurchaseLine1.Next();
            PurchaseLine2.Next();
            RecordRef1.GetTable(PurchaseLine1);
            RecordRef2.GetTable(PurchaseLine2);
            VerifyRecordRefsMatch(RecordRef1, RecordRef2, PurchaseLineExcludedFieldList);
        end;
    end;

    [Scope('OnPrem')]
    procedure MakeQuoteNoSeriesNotManual()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        DocumentNoVisiblity: Codeunit DocumentNoVisibility;
    begin
        SalesSetup.Get();
        NoSeries.Get(SalesSetup."Quote Nos.");
        NoSeries.Validate("Manual Nos.", false);
        NoSeries.Modify(true);
        Clear(DocumentNoVisiblity); // to clear caching
    end;

    local procedure ExcludeFromComparisment(FieldRef: FieldRef; FieldListToExclude: List of [Text]): Boolean
    var
        ExcludedFieldName: Text;
    begin
        foreach ExcludedFieldName in FieldListToExclude do
            if FieldRef.Name = ExcludedFieldName then
                exit(true);

        exit(false);
    end;

    local procedure VerifyRecordRefsMatch(RecordRef1: RecordRef; RecordRef2: RecordRef; FieldListToExclude: List of [Text])
    var
        FieldRef1: FieldRef;
        FieldRef2: FieldRef;
        I: Integer;
    begin
        for I := 1 to RecordRef1.FieldCount do begin
            FieldRef1 := RecordRef1.FieldIndex(I);
            FieldRef2 := RecordRef2.FieldIndex(I);

            if not ExcludeFromComparisment(FieldRef1, FieldListToExclude) and Assert.IsDataTypeSupported(FieldRef1.Value) then
                Assert.AreEqual(FieldRef1.Value, FieldRef2.Value, StrSubstNo('Field values for field %1 do not match', FieldRef1.Caption));
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        VarReply: Variant;
    begin
        if StrPos(Question, LeaveDocWithoutPostingTxt) > 0 then begin
            Reply := true;
            exit;
        end;
        LibraryVariableStorage.Dequeue(VarReply);
        Reply := VarReply;
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer; DiscPct: Decimal; MinimumAmount: Decimal)
    begin
        CreateCustomer(Customer);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscPct, MinimumAmount, '');
    end;

    local procedure CreateItem(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify();
    end;

    local procedure SetupDataForDiscountTypePct(var Item: Record Item; var ItemQuantity: Integer; var Customer: Record Customer; var DiscPct: Decimal)
    var
        MinAmt: Decimal;
        ItemUnitPrice: Decimal;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        CreateItem(Item, ItemUnitPrice);
        CreateCustomerWithDiscount(Customer, DiscPct, MinAmt);
    end;

    local procedure SetupDataForDiscountTypeAmt(var Item: Record Item; var ItemQuantity: Integer; var Customer: Record Customer; var InvoiceDiscountAmount: Decimal)
    var
        DiscPct: Decimal;
    begin
        SetupDataForDiscountTypePct(Item, ItemQuantity, Customer, DiscPct);
        InvoiceDiscountAmount := LibraryRandom.RandDecInRange(1, Round(Item."Unit Price" * ItemQuantity, 1, '<'), 2);
    end;

    local procedure CreateSalesHeaderWithLinesAndSelectVendor(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type") VendorNo: Code[20]
    var
        Item: Record Item;
    begin
        VendorNo := CreateSalesHeaderAndSelectVendor(SalesHeader, DocumentType);
        LibrarySmallBusiness.CreateItem(Item);
        AddRandomNumberOfLinesToSalesHeader(SalesHeader, Item);
    end;

    local procedure CreateSalesHeaderWithLinesForOneDefaultVendor(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type") VendorNo: Code[20]
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySmallBusiness.CreateItem(Item);
        VendorNo := CreateDefaultVendorForItem(Item);
        AddRandomNumberOfLinesToSalesHeader(SalesHeader, Item);
    end;

    local procedure CreateSalesHeaderWithLinesForTwoDefaultVendorsAndSelectVendor(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type") VendorNo: Code[20]
    var
        Item1: Record Item;
        Item2: Record Item;
    begin
        VendorNo := CreateSalesHeaderAndSelectVendor(SalesHeader, DocumentType);
        LibrarySmallBusiness.CreateItem(Item1);
        CreateDefaultVendorForItem(Item1);
        LibrarySmallBusiness.CreateItem(Item2);
        CreateDefaultVendorForItem(Item2);
        AddRandomNumberOfLinesToSalesHeader(SalesHeader, Item1);
        AddRandomNumberOfLinesToSalesHeader(SalesHeader, Item2);
    end;

    local procedure CreateDefaultVendorForItem(var Item: Record Item): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        Vendor.Modify(true);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesHeaderAndSelectVendor(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateNewSalesLineWithDescription(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Description := LibraryUtility.GenerateGUID();
        SalesLine.Insert();
    end;

    local procedure EnqueueForCreatePurchaseInvoiceHandlers(CopyItemsOpt: Option; VendorNo: Code[20]; ConfirmOnVendorSelection: Boolean)
    begin
        LibraryVariableStorage.Enqueue(CopyItemsOpt); // Enqueue for CreatePurchaseInvoiceHandler
        if (CopyItemsOpt = CopyItemsOption::None) or (VendorNo = '') then
            exit;

        LibraryVariableStorage.Enqueue(VendorNo); // Enqueue for SelectVendorHandler
        LibraryVariableStorage.Enqueue(ConfirmOnVendorSelection); // Enqueue for SelectVendorHandler
    end;

    local procedure CreateStandardCodeWithItemAndDescr(StandardSalesCode: Record "Standard Sales Code"; Item: Record Item)
    var
        StandardSalesLine: Record "Standard Sales Line";
        StandardSalesCodeCard: TestPage "Standard Sales Code Card";
    begin
        // Create Standard Code lines with one item and one description line
        StandardSalesCodeCard.OpenEdit();
        StandardSalesCodeCard.Filter.SetFilter(Code, StandardSalesCode.Code);
        StandardSalesCodeCard.StdSalesLines.New();
        StandardSalesCodeCard.StdSalesLines.Description.SetValue(
          LibraryUtility.GenerateRandomCode(StandardSalesLine.FieldNo(Description), DATABASE::"Standard Sales Line"));
        StandardSalesCodeCard.StdSalesLines.New();
        if not LibraryApplicationArea.FoundationSetupExists() then
            StandardSalesCodeCard.StdSalesLines.Type.SetValue(StandardSalesLine.Type::Item);
        StandardSalesCodeCard.StdSalesLines."No.".SetValue(Item."No.");
        StandardSalesCodeCard.StdSalesLines.Quantity.SetValue(LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreatePurchaseStandardCodeWithItemAndDescr(StandardPurchaseCode: Record "Standard Purchase Code"; Item: Record Item)
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // Create Standard Code lines with one item and one description line
        StandardPurchaseCodeCard.OpenEdit();
        StandardPurchaseCodeCard.Filter.SetFilter(Code, StandardPurchaseCode.Code);
        StandardPurchaseCodeCard.StdPurchaseLines.New();
        StandardPurchaseCodeCard.StdPurchaseLines.Description.SetValue(
          LibraryUtility.GenerateRandomCode(StandardPurchaseLine.FieldNo(Description), DATABASE::"Standard Purchase Line"));
        StandardPurchaseCodeCard.StdPurchaseLines.New();
        if not LibraryApplicationArea.FoundationSetupExists() then
            StandardPurchaseCodeCard.StdPurchaseLines.Type.SetValue(StandardPurchaseLine.Type::Item);
        StandardPurchaseCodeCard.StdPurchaseLines."No.".SetValue(Item."No.");
        StandardPurchaseCodeCard.StdPurchaseLines.Quantity.SetValue(LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateSelectCustomerSetup(var NameStart: Text[10]; var NameMiddle: Text[10]; var NameEnd: Text[10]; var Customer: Record Customer) Identifier: Code[10]
    var
        Customer2: Record Customer;
        NewCustomer1Name: Text[100];
        NewCustomer2Name: Text[100];
    begin
        CreateCustomer(Customer);
        CreateCustomer(Customer2);

        // Unique identifier to prevent data dependency
        Identifier := LibraryUtility.GenerateGUID();

        // Make beginning of the names the same
        NameStart := 'XXX Start ';

        // Make middle of the names match
        NameMiddle := 'YYY Middle';

        // Make endign of the names match
        NameEnd := ' ZZZ End';

        NewCustomer1Name := NameStart + '1' + NameMiddle + NameEnd + ' ' + Identifier;
        NewCustomer2Name := NameStart + '2' + NameMiddle + NameEnd + ' ' + Identifier;

        Customer.Validate(Name, NewCustomer1Name);
        Customer2.Validate(Name, NewCustomer2Name);
        Customer.Modify(true);
        Customer2.Modify(true);
    end;

    local procedure CreateSelectVendorSetup(var NameStart: Text[10]; var NameMiddle: Text[10]; var NameEnd: Text[10]; var Vendor: Record Vendor) Identifier: Code[10]
    var
        Vendor2: Record Vendor;
        NewVendor1Name: Text[100];
        NewVendor2Name: Text[100];
    begin
        CreateVendor(Vendor);
        CreateVendor(Vendor2);

        // Unique identifier to prevent data dependency
        Identifier := LibraryUtility.GenerateGUID();

        // Make beginning of the names the same
        NameStart := 'XXX Start';

        // Make middle of the names match
        NameMiddle := 'YYY Middle';

        // Make ending of the names match
        NameEnd := 'ZZZ End';

        NewVendor1Name := NameStart + '1' + NameMiddle + NameEnd + ' ' + Identifier;
        NewVendor2Name := NameStart + '2' + NameMiddle + NameEnd + ' ' + Identifier;

        Vendor.Validate(Name, NewVendor1Name);
        Vendor2.Validate(Name, NewVendor2Name);
        Vendor.Modify(true);
        Vendor2.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceFromSalesDocument(var PurchaseInvoice: TestPage "Purchase Invoice"; var SalesHeader: Record "Sales Header"; CopyItemsOpt: Option; VendorNo: Code[20]; ConfirmOnVendorSelection: Boolean)
    begin
        EnqueueForCreatePurchaseInvoiceHandlers(CopyItemsOpt, VendorNo, ConfirmOnVendorSelection);
        PurchaseInvoice.Trap();
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                SalesInvoiceCreatePurchaseInvoice(SalesHeader);
            SalesHeader."Document Type"::Order:
                SalesOrderCreatePurchaseInvoice(SalesHeader);
        end;
    end;

    local procedure SalesInvoiceCreatePurchaseInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.CreatePurchaseInvoice.Invoke();
    end;

    local procedure SalesOrderCreatePurchaseInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.CreatePurchaseInvoice.Invoke();
    end;

    local procedure SalesOrderCreatePurchaseOrder(var SalesHeader: Record "Sales Header"; PurchaseOrder: TestPage "Purchase Order")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        PurchaseOrder.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.CreatePurchaseOrder.Invoke();
    end;

    local procedure PostPurchaseInvoice(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        PurchaseInvoice."Vendor Invoice No.".SetValue(LibraryRandom.RandInt(1000));
        LibraryVariableStorage.Enqueue(true); // Enqueue for ConfirmHandler
        LibrarySales.DisableConfirmOnPostingDoc();

        PurchaseInvoice.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListPageHandler(var CustomerList: TestPage "Customer List")
    var
        CustomerName: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerName);
        CustomerList.FILTER.SetFilter(Name, CustomerName);
        CustomerList.Last();
        CustomerList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorListPageHandler(var VendorList: TestPage "Vendor List")
    var
        VendorName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorName);
        VendorList.FILTER.SetFilter(Name, VendorName);
        VendorList.Last();
        VendorList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListCancelPageHandler(var CustomerList: TestPage "Customer List")
    begin
        CustomerList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorListCancelPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLookupCancelPageHandler(var VendorLookup: TestPage "Vendor Lookup")
    begin
        VendorLookup.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerCardPageHandler(var CustomerCard: TestPage "Customer Card")
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        PostCode: Record "Post Code";
        PaymentMethod: Record "Payment Method";
        CustomerName: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerName);
        CustomerCard.Name.AssertEquals(CustomerName);
        CustomerCard.Address.SetValue(LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        CustomerCard."Address 2".SetValue(LibraryUtility.GenerateRandomCode(Customer.FieldNo("Address 2"), DATABASE::Customer));
        LibraryERM.CreatePostCode(PostCode);
        CustomerCard.City.SetValue(PostCode.City);
        CustomerCard."Post Code".SetValue(PostCode.Code);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        CustomerCard."Payment Method Code".SetValue(PaymentMethod.Code);
        CustomerCard."Payment Terms Code".SetValue(LibraryERM.FindPaymentTermsCode());
        LibrarySales.CreateCustomer(Customer2);
        CustomerCard."Gen. Bus. Posting Group".SetValue(Customer2."Gen. Bus. Posting Group");
        CustomerCard."Customer Posting Group".SetValue(Customer2."Customer Posting Group");

        LibraryVariableStorage.Enqueue(CustomerCard."No.".Value);
        CustomerCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerCardTemplatePageHandler(var CustomerCard: TestPage "Customer Card")
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        // Set other fields on customer card
        CustomerCard.Address.SetValue(LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        CustomerCard."Address 2".SetValue(LibraryUtility.GenerateRandomCode(Customer.FieldNo("Address 2"), DATABASE::Customer));
        LibraryERM.CreatePostCode(PostCode);
        CustomerCard.City.SetValue(PostCode.City);
        CustomerCard."Post Code".SetValue(PostCode.Code);

        LibraryVariableStorage.Enqueue(CustomerCard."No.".Value);
        CustomerCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerCardCancelEditPageHandler(var CustomerCard: TestPage "Customer Card")
    var
        CustomerName: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerName);
        CustomerCard.Name.AssertEquals(CustomerName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorCardTemplatePageHandler(var VendorCard: TestPage "Vendor Card")
    var
        Vendor: Record Vendor;
        PostCode: Record "Post Code";
    begin
        // Set other fields on Vendor card
        VendorCard.Address.SetValue(LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        VendorCard."Address 2".SetValue(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Address 2"), DATABASE::Vendor));
        LibraryERM.CreatePostCode(PostCode);
        VendorCard.City.SetValue(PostCode.City);
        VendorCard."Post Code".SetValue(PostCode.Code);

        LibraryVariableStorage.Enqueue(VendorCard."No.".Value);
        VendorCard.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeBuyFromPayToVendorConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        VarReply: Variant;
    begin
        LibraryVariableStorage.Dequeue(VarReply);
        Reply := VarReply;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesCodeCardPageHandler(var StandardCustomerSalesCodes: TestPage "Standard Customer Sales Codes")
    begin
        StandardCustomerSalesCodes.First();
        StandardCustomerSalesCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodeCardPageHandler(var StandardVendorPurchaseCodes: TestPage "Standard Vendor Purchase Codes")
    begin
        StandardVendorPurchaseCodes.First();
        StandardVendorPurchaseCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CurrencyHandler(var ChangeExchRate: TestPage "Change Exchange Rate")
    begin
        ChangeExchRate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerPageHandler(var CustomerLookup: TestPage "Customer Lookup")
    var
        Cust: Record Customer;
        CustNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustNo);
        Cust.Get(CustNo);
        CustomerLookup.Filter.SetFilter("No.", Cust."No.");
        CustomerLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorPageHandler(var VendorLookup: TestPage "Vendor Lookup")
    var
        Vendor: Record Vendor;
        VendNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendNo);
        Vendor.Get(VendNo);
        VendorLookup.Filter.SetFilter("No.", Vendor."No.");
        VendorLookup.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure QuoteReportRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyDocRequestPageHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    var
        ValueFromQueue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ValueFromQueue); // Doc type
        CopySalesDocument.DocumentType.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Doc no
        CopySalesDocument.DocumentNo.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Sell-to no
        CopySalesDocument.SellToCustNo.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Sell-to name
        CopySalesDocument.SellToCustName.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Include header
        CopySalesDocument.IncludeHeader_Options.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Recalc lines
        CopySalesDocument.RecalculateLines.SetValue(ValueFromQueue);

        CopySalesDocument.OK().Invoke();
    end;

    local procedure AddRandomNumberOfLinesToSalesHeader(SalesHeader: Record "Sales Header"; Item: Record Item)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
        ItemQuantity: Integer;
        NumberOfLines: Integer;
    begin
        NumberOfLines := LibraryRandom.RandIntInRange(1, 30);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 30);

        for I := 1 to NumberOfLines do
            LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, ItemQuantity);
    end;

    [StrMenuHandler]
    [HandlerFunctions('CreatePurchaseInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchaseInvoiceHandler(Options: Text; var Choice: Integer; InstructionText: Text)
    var
        ChoiceToSelect: Variant;
    begin
        LibraryVariableStorage.Dequeue(ChoiceToSelect);
        Choice := ChoiceToSelect;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorHandler(var VendorList: TestPage "Vendor List")
    var
        VendorNo: Variant;
        CancelVariant: Variant;
        Cancel: Boolean;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        VendorList.FILTER.SetFilter("No.", VendorNo);
        LibraryVariableStorage.Dequeue(CancelVariant);
        Cancel := CancelVariant;

        if Cancel then
            VendorList.Cancel().Invoke()
        else
            VendorList.OK().Invoke();
    end;


    local procedure VerifyPurchaseDocumentCreatedFromSalesDocument(VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        VerifyPurchaseDocumentHeaderCreatedFromSalesDocument(PurchaseHeader, DocumentType, VendorNo);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader, SalesLine);
    end;

    local procedure VerifyPurchaseInvoiceCreatedFromSalesDocumentNoLines(VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyPurchaseDocumentHeaderCreatedFromSalesDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseLine.SetFilter("Document Type", '=%1', PurchaseHeader."Document Type");
        PurchaseLine.SetFilter("Document No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(PurchaseLine);
    end;

    local procedure VerifyPurchaseDocumentCreationFromSalesDocumentCanceled(VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    local procedure VerifyPurchaseDocumentCreatedFromSelectedLineOfSalesDocument(VendorNo: Code[20]; var SalesHeader: Record "Sales Header"; SalesLineNo: Integer; DocumentType: Enum "Purchase Document Type")
    var
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        VerifyPurchaseDocumentHeaderCreatedFromSalesDocument(PurchaseHeader, DocumentType, VendorNo);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Line No.", SalesLineNo);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader, SalesLine);
    end;

    local procedure VerifyPurchaseDocumentHeaderCreatedFromSalesDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        Assert.RecordIsNotEmpty(PurchaseHeader);
        PurchaseHeader.FindLast();
    end;

    local procedure VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader: Record "Purchase Header"; var SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetFilter("Document Type", '=%1', PurchaseHeader."Document Type");
        PurchaseLine.SetFilter("Document No.", PurchaseHeader."No.");

        Assert.AreEqual(SalesLine.Count, PurchaseLine.Count, 'Number of records is not the same, not all lines were transfered');

        PurchaseLine.FindSet();
        SalesLine.FindSet();
        repeat
            case SalesLine.Type of
                SalesLine.Type::" ":
                    Assert.AreEqual(PurchaseLine.Type, PurchaseLine.Type::" ", 'Type does not match');
                SalesLine.Type::Item:
                    Assert.AreEqual(PurchaseLine.Type, PurchaseLine.Type::Item, 'Type does not match');
                else
                    Assert.Fail('Unsupported case found');
            end;

            Assert.AreEqual(PurchaseLine."No.", SalesLine."No.", 'No. does not match');
            Assert.AreEqual(PurchaseLine.Description, SalesLine.Description, 'Description does not match');
            Assert.AreEqual(PurchaseLine.Quantity, SalesLine.Quantity, 'Quantity does not match');
            Assert.AreEqual(PurchaseLine."Unit of Measure Code", SalesLine."Unit of Measure Code", 'UOM Code does not match');
            SalesLine.Next();
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyPostedPurchaseDocumentCreatedFromSalesDocument(VendorNo: Code[20]; var SalesHeader: Record "Sales Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        SalesLine: Record "Sales Line";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.FindLast();

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        PurchInvLine.SetFilter("Document No.", PurchInvHeader."No.");

        Assert.AreEqual(SalesLine.Count, PurchInvLine.Count, 'Number of records is not the same, not all lines were transfered');

        SalesLine.FindSet();
        PurchInvLine.FindSet();
        repeat
            case SalesLine.Type of
                SalesLine.Type::" ":
                    Assert.AreEqual(PurchInvLine.Type, PurchInvLine.Type::" ", 'Type does not match');
                SalesLine.Type::Item:
                    Assert.AreEqual(PurchInvLine.Type, PurchInvLine.Type::Item, 'Type does not match');
                else
                    Assert.Fail('Unsupported case found');
            end;

            Assert.AreEqual(PurchInvLine."No.", SalesLine."No.", 'No. does not match');
            Assert.AreEqual(PurchInvLine.Description, SalesLine.Description, 'Description does not match');
            Assert.AreEqual(PurchInvLine.Quantity, SalesLine.Quantity, 'Quantity does not match');
            Assert.AreEqual(PurchInvLine."Unit of Measure Code", SalesLine."Unit of Measure Code", 'UOM Code does not match');
            SalesLine.Next();
        until PurchInvLine.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCopyDocRequestPageHandler(var CopyPurchaseDocument: TestRequestPage "Copy Purchase Document")
    var
        ValueFromQueue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ValueFromQueue); // Doc type
        CopyPurchaseDocument.DocumentType.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Doc no
        CopyPurchaseDocument.DocumentNo.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Sell-to no
        CopyPurchaseDocument.BuyfromVendorNo.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Sell-to name
        CopyPurchaseDocument.BuyfromVendorName.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Include header
        CopyPurchaseDocument.IncludeHeader_Options.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Recalc lines
        CopyPurchaseDocument.RecalculateLines.SetValue(ValueFromQueue);

        CopyPurchaseDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyNumberOfCustomersAndClosePage(var CustomerList: TestPage "Customer List")
    var
        ExpectedNoOfUsers: Variant;
        NumberOfRows: Integer;
    begin
        LibraryVariableStorage.Dequeue(ExpectedNoOfUsers);

        NumberOfRows := 0;

        if CustomerList.First() then begin
            NumberOfRows := 1;
            while CustomerList.Next() do
                NumberOfRows += 1;
        end;

        Assert.AreEqual(ExpectedNoOfUsers, NumberOfRows, 'Wrong number of users on select customer page');
        CustomerList.First();
        CustomerList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyNumberOfVendorsAndClosePage(var VendorList: TestPage "Vendor List")
    var
        ExpectedNoOfUsers: Variant;
        NumberOfRows: Integer;
    begin
        LibraryVariableStorage.Dequeue(ExpectedNoOfUsers);

        NumberOfRows := 0;

        if VendorList.First() then begin
            NumberOfRows := 1;
            while VendorList.Next() do
                NumberOfRows += 1;
        end;

        Assert.AreEqual(ExpectedNoOfUsers, NumberOfRows, 'Wrong number of users on select vendor page');
        VendorList.First();
        VendorList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        CustomerTempl.Get(LibraryVariableStorage.DequeueText());
        SelectCustomerTemplList.Filter.SetFilter(Code, CustomerTempl.Code);
        if LibraryVariableStorage.DequeueBoolean() then
            SelectCustomerTemplList.OK().Invoke()
        else
            SelectCustomerTemplList.Cancel().Invoke();
    end;

    local procedure SetCreditWarning(var OldCreditWarning: Option; NewCreditWarning: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if NewCreditWarning <> SalesReceivablesSetup."Credit Warnings" then begin
            OldCreditWarning := SalesReceivablesSetup."Credit Warnings";
            SalesReceivablesSetup."Credit Warnings" := NewCreditWarning;
            SalesReceivablesSetup.Modify();
        end;
    end;

    local procedure SetCustomerDisableSearchByName(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Disable Search by Name", true);
        Customer.Modify();
    end;

    local procedure SetSalesSetupDisableSearchByName(NewDisableSearchByName: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Disable Search by Name", NewDisableSearchByName);
        SalesSetup.Modify();
    end;

    local procedure CreateVendorWithName(var Vendor: Record Vendor; Name: Text[100])
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Name := Name;
        Vendor.Modify(true);
    end;

    local procedure CreateCustomerWithName(var Customer: Record Customer; Name: Text[100])
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        Customer.Name := Name;
        Customer.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandlerCancel(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandlerOK(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    local procedure CreateCustomerWithNumberAsName(var Cust: Record Customer)
    begin
        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Name := Cust."No.";
        Cust.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceControlsDisabledBeforeCustomerSelected()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Actions on Sales Invoice Page not enabled if no customer selected
        Initialize();

        // [WHEN] Sales Invoice page is opened on SaaS
        SalesInvoice.OpenNew();

        // [THEN] All controls related to customer (and on SaaS) are disabled
        Assert.IsFalse(SalesInvoice.GetRecurringSalesLines.Enabled(), ControlShouldBeDisabledErr);
#if not CLEAN26
        Assert.IsFalse(SalesInvoice.Statistics.Enabled(), ControlShouldBeDisabledErr);
#endif
        Assert.IsFalse(SalesInvoice.SalesStatistics.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesInvoice.CalculateInvoiceDiscount.Enabled(), ControlShouldBeDisabledErr);
        Assert.IsFalse(SalesInvoice.CopyDocument.Enabled(), ControlShouldBeDisabledErr);

        SalesInvoice.Close();

        // [WHEN] Sales invoice page is opened with no application area
        LibraryApplicationArea.DisableApplicationAreaSetup();
        SalesInvoice.OpenNew();

        // [THEN] All controls related to customer (and not on SaaS) are disabled
        Assert.IsFalse(SalesInvoice.Release.Enabled(), ControlShouldBeDisabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceControlsEnabledAfterCustomerSelected()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Actions on Sales Invoice Page are enabled if customer is selected
        Initialize();

        // [GIVEN] A sample sales invoice
        LibrarySales.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);

        // [WHEN] Sales invoice page is opened on SaaS
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] All controls related to customer (and on SaaS) are enabled
        Assert.IsTrue(SalesInvoice.GetRecurringSalesLines.Enabled(), ControlShouldBeEnabledErr);
#if not CLEAN26
        Assert.IsTrue(SalesInvoice.Statistics.Enabled(), ControlShouldBeEnabledErr);
#endif
        Assert.IsTrue(SalesInvoice.SalesStatistics.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesInvoice.CalculateInvoiceDiscount.Enabled(), ControlShouldBeEnabledErr);
        Assert.IsTrue(SalesInvoice.CopyDocument.Enabled(), ControlShouldBeEnabledErr);

        SalesInvoice.Close();

        LibraryApplicationArea.DisableApplicationAreaSetup();

        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] All controls related to customer (and not on SaaS) are disabled
        Assert.IsTrue(SalesInvoice.Release.Enabled(), ControlShouldBeEnabledErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmptyPurchOrderFromSalesOrderModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        Assert.IsFalse(PurchOrderFromSalesOrder.First(), 'PurchaseOrderFr4omSalesOrder page is not empty.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LookupCancelVendorPurchOrderFromSalesOrderModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.Vendor.Lookup();
        PurchOrderFromSalesOrder.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserCancelsPurchOrderFromSalesOrderModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserAcceptsWithoutChangesPurchOrderFromSalesOrderModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.OK().Invoke();
    end;

    local procedure GetSalesLineNo(LineIndex: Integer; var SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindSet();
        while LineIndex > 1 do begin
            Assert.AreEqual(1, SalesLine.Next(), 'Expected more sales lines');
            LineIndex -= 1;
        end;
        exit(SalesLine."Line No.");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure AssertMessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure AllItemsAreAvailableNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(EntireOrderIsAvailableTxt, Notification.Message);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillSalesLineExcludedFieldList(var FieldListToExclude: List of [Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillPurchaseHeaderExcludedFieldList(var FieldListToExclude: List of [Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillPurchaseLineExcludedFieldList(var FieldListToExclude: List of [Text])
    begin
    end;
}
