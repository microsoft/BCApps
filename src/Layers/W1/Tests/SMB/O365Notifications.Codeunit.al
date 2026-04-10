codeunit 138030 "O365 Notifications"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Quantity] [SMB]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        InstructionMgt: Codeunit "Instruction Mgt.";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        DontShowAgain: Integer;
        LinesMissingQuantityErr: Label 'One or more document lines with a value in the No. field do not have a quantity specified.';

    local procedure Initialize()
    var
        UserPreference: Record "User Preference";
        SalesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Notifications");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
        UserPreference.DeleteAll();

        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Notifications");

        ClearTable(DATABASE::Resource);

        LibraryERMCountryData.CreateVATData();

        SalesSetup.Get();
        SalesSetup."Stockout Warning" := false;
        SalesSetup.Modify();

        DontShowAgain := 2;
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Notifications");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Resource: Record Resource;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::Resource:
                Resource.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTestPostingWithoutQuantitySpecified()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        Initialize();

        // Test posting on card
        CreateSalesInvoiceForPosting(SalesInvoice, SalesHeader);
        asserterror SalesInvoice.Post.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesInvoice.Close();

        CreateSalesInvoiceForPosting(SalesInvoice, SalesHeader);
        asserterror SalesInvoice.PostAndSend.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesInvoice.Close();

        // Test posting on List
        CreateSalesInvoiceForPosting(SalesInvoice, SalesHeader);
        SalesInvoiceList.OpenView();
        SalesInvoiceList.GotoRecord(SalesHeader);
        asserterror SalesInvoiceList.PostAndSend.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesInvoiceList.Close();
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteTestPostingWithoutQuantitySpecified()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        Initialize();

        // Test posting on card
        CreateSalesQuoteForPosting(SalesQuote, SalesHeader);
        asserterror SalesQuote.MakeInvoice.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesQuote.Close();

        CreateSalesQuoteForPosting(SalesQuote, SalesHeader);
        asserterror SalesQuote.Print.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesQuote.Close();

        CreateSalesQuoteForPosting(SalesQuote, SalesHeader);
        asserterror SalesQuote.Email.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesQuote.Close();

        // Test posting on List
        CreateSalesQuoteForPosting(SalesQuote, SalesHeader);
        // Disable application area while opening the sales quote to make sure MakeInvoice is visible.
        LibraryApplicationArea.DisableApplicationAreaSetup();
        SalesQuotes.OpenView();
        LibraryApplicationArea.EnableFoundationSetup();
        SalesQuotes.GotoRecord(SalesHeader);
        asserterror SalesQuotes.MakeInvoice.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesQuotes.Close();
        SalesQuote.Close();

        CreateSalesQuoteForPosting(SalesQuote, SalesHeader);
        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        asserterror SalesQuotes.Print.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesQuotes.Close();
        SalesQuote.Close();

        CreateSalesQuoteForPosting(SalesQuote, SalesHeader);
        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        asserterror SalesQuotes.Email.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesQuotes.Close();
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoTestPostingWithEmptyList()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        Initialize();

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.DeleteAll();
        SalesCreditMemos.OpenView();
        ErrorMessagesPage.Trap();
        SalesCreditMemos.Post.Invoke();
        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoTestPostAndSendWithEmptyList()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        Initialize();

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.DeleteAll();
        SalesCreditMemos.OpenView();
        ErrorMessagesPage.Trap();
        SalesCreditMemos.PostAndSend.Invoke();
        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoTestPostingWithoutQuantitySpecified()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        Initialize();

        // Test posting on card
        CreateSalesCreditMemoForPosting(SalesCreditMemo, SalesHeader);
        asserterror SalesCreditMemo.Post.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesCreditMemo.Close();

        CreateSalesCreditMemoForPosting(SalesCreditMemo, SalesHeader);
        asserterror SalesCreditMemo.PostAndSend.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesCreditMemo.Close();

        // Test posting on List
        CreateSalesCreditMemoForPosting(SalesCreditMemo, SalesHeader);
        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        asserterror SalesCreditMemos.Post.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesCreditMemos.Close();
        SalesCreditMemo.Close();

        CreateSalesCreditMemoForPosting(SalesCreditMemo, SalesHeader);
        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        asserterror SalesCreditMemos.PostAndSend.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        SalesCreditMemos.Close();
        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTestPostingWithoutQuantitySpecified()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        Initialize();

        // Test posting on card
        CreatePurchaseInvoiceForPosting(PurchaseInvoice, PurchaseHeader);
        asserterror PurchaseInvoice.Post.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        PurchaseInvoice.Close();

        // Test posting on List
        CreatePurchaseInvoiceForPosting(PurchaseInvoice, PurchaseHeader);
        PurchaseInvoices.OpenView();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoices.PostSelected.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        PurchaseInvoices.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoTestPostingWithoutQuantitySpecified()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        Initialize();

        // Test posting on card
        CreatePurchaseCreditMemoForPosting(PurchaseCreditMemo, PurchaseHeader);
        asserterror PurchaseCreditMemo.Post.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        PurchaseCreditMemo.Close();

        CreatePurchaseCreditMemoForPosting(PurchaseCreditMemo, PurchaseHeader);
        asserterror PurchaseCreditMemo.PostAndPrint.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        PurchaseCreditMemo.Close();

        // Test posting on List
        CreatePurchaseCreditMemoForPosting(PurchaseCreditMemo, PurchaseHeader);
        PurchaseCreditMemos.OpenView();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemos.Post.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        PurchaseCreditMemos.Close();
        PurchaseCreditMemo.Close();

        CreatePurchaseCreditMemoForPosting(PurchaseCreditMemo, PurchaseHeader);
        PurchaseCreditMemos.OpenView();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemos.PostAndPrint.Invoke();
        Assert.ExpectedError(LinesMissingQuantityErr);
        PurchaseCreditMemos.Close();
        PurchaseCreditMemo.Close();
    end;

    local procedure CreateSalesInvoiceForPosting(var SalesInvoice: TestPage "Sales Invoice"; var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));

        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");

        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");

        FindSalesHeader(Customer, SalesHeader);
    end;

    local procedure CreateSalesQuoteForPosting(var SalesQuote: TestPage "Sales Quote"; var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);

        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));

        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");

        SalesQuote.SalesLines.New();
        SalesQuote.SalesLines."No.".SetValue(Item."No.");

        FindSalesHeader(Customer, SalesHeader);
    end;

    local procedure CreateSalesCreditMemoForPosting(var SalesCreditMemo: TestPage "Sales Credit Memo"; var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));

        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");

        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");

        FindSalesHeader(Customer, SalesHeader);
    end;

    local procedure CreatePurchaseInvoiceForPosting(var PurchaseInvoice: TestPage "Purchase Invoice"; var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.CreateItem(Item);

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        LibraryVariableStorage.Enqueue(DontShowAgain);

        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));

        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");

        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");

        FindPurchaseHeader(Vendor, PurchaseHeader);
    end;

    local procedure CreatePurchaseCreditMemoForPosting(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.CreateItem(Item);

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);

        LibraryVariableStorage.Enqueue(DontShowAgain);

        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));

        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");

        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");

        FindPurchaseHeader(Vendor, PurchaseHeader);
    end;

    local procedure FindSalesHeader(Customer: Record Customer; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        Assert.AreEqual(SalesHeader.Count, 1, 'Could not find the document or more documents were found');
        SalesHeader.FindFirst();
    end;

    local procedure FindPurchaseHeader(Vendor: Record Vendor; var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.AreEqual(PurchaseHeader.Count, 1, 'Could not find the document or more documents were found');
        PurchaseHeader.FindFirst();
    end;
}

