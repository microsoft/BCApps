codeunit 138033 "O365 Navigate"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Navigate] [SMB]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibrarySales: Codeunit "Library - Sales";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;
        PostInvoice: Boolean;
        DoNotShowPostedDocument: Boolean;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Navigate");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        PostInvoice := true;
        DoNotShowPostedDocument := false;

        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Navigate");

        ClearTable(DATABASE::Resource);

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        SalesSetup.Get();
        SalesSetup."Stockout Warning" := false;
        SalesSetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Navigate");
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
    [HandlerFunctions('HandleConfirmationDialog')]
    [Scope('OnPrem')]
    procedure TestNavigatePageOpensPage()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        Navigate: TestPage Navigate;
        PreAssignedNo: Code[20];
    begin
        Initialize();
        PostSalesInvoice(PreAssignedNo);
        PostedSalesInvoices.OpenView();
        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();
        PostedSalesInvoices.GotoRecord(SalesInvoiceHeader);

        Navigate.Trap();
        PostedSalesInvoices.Navigate.Invoke();

        Assert.AreEqual(1, Navigate."No. of Records".AsInteger(), 'There should be only one record on the first row');

        PostedSalesInvoice.Trap();
        Navigate."No. of Records".DrillDown();
        Assert.AreEqual(PostedSalesInvoice."Pre-Assigned No.".Value, PreAssignedNo, 'Wrong document was opened');
        PostedSalesInvoice.Close();

        PostedSalesInvoice.Trap();
        Navigate.Show.Invoke();
        PostedSalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('HandleConfirmationDialog')]
    [Scope('OnPrem')]
    procedure TestFindByDocument()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Navigate: TestPage Navigate;
        PreAssignedNo: Code[20];
    begin
        Initialize();

        PostSalesInvoice(PreAssignedNo);

        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();

        Navigate.OpenView();
        Navigate.FindByItemReference.Invoke();
        Navigate.FindByDocument.Invoke();

        Navigate.DocNoFilter.Value(SalesInvoiceHeader."No.");
        Navigate.Find.Invoke();
        Assert.AreEqual(1, Navigate."No. of Records".AsInteger(), 'There should be only one record on the first row');

        Navigate.DocNoFilter.Value('');
        Navigate.PostingDateFilter.Value(Format(SalesInvoiceHeader."Posting Date"));
        Navigate.Find.Invoke();

        Assert.IsTrue(Navigate."No. of Records".AsInteger() > 1, 'At least two records should be shown');
        Navigate.Close();
    end;

    [Test]
    [HandlerFunctions('HandleConfirmationDialog')]
    [Scope('OnPrem')]
    procedure TestFindByExternalDocumentSales()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Navigate: TestPage Navigate;
        PreAssignedNo: Code[20];
    begin
        Initialize();

        PostSalesInvoice(PreAssignedNo);

        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();

        Navigate.OpenView();
        Navigate.FindByDocument.Invoke();

        Navigate.ExtDocNo2.Value(SalesInvoiceHeader."External Document No.");
        Navigate.Find.Invoke();
        Assert.AreEqual(1, Navigate."No. of Records".AsInteger(), 'There should be only one record on the first row');

        Navigate.Close();
    end;


    [Test]
    [HandlerFunctions('HandleConfirmationDialog')]
    [Scope('OnPrem')]
    procedure TestFindByExternalDocumentPurchase()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        Navigate: TestPage Navigate;
        PreAssignedNo: Code[20];
    begin
        Initialize();

        PostPurchaseInvoice(PreAssignedNo);

        PurchInvHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();

        Navigate.OpenView();
        Navigate.FindByDocument.Invoke();

        Navigate.ExtDocNo2.Value(PurchInvHeader."Vendor Invoice No.");
        Navigate.Find.Invoke();
        Assert.AreEqual(1, Navigate."No. of Records".AsInteger(), 'There should be only one record on the first row');

        Navigate.Close();
    end;

    [Test]
    [HandlerFunctions('HandleConfirmationDialog')]
    [Scope('OnPrem')]
    procedure TestFindByContact()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Navigate: TestPage Navigate;
        PreAssignedNo: Code[20];
        ContactType: Option " ",Vendor,Customer;
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(true);

        PostSalesInvoice(PreAssignedNo);

        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();

        Navigate.OpenView();
        Navigate.FindByBusinessContact.Invoke();

        Navigate.ContactType.SetValue(ContactType::Customer);
        Navigate.ContactNo.SetValue(SalesInvoiceHeader."Sell-to Customer No.");
        Navigate.Find.Invoke();

        Assert.AreEqual(1, Navigate."No. of Records".AsInteger(), 'There should be only one record on the first row');
        Navigate.Close();
    end;

    [Test]
    [HandlerFunctions('HandleConfirmationDialog')]
    [Scope('OnPrem')]
    procedure TestFindByVendor()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        Navigate: TestPage Navigate;
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PreAssignedNo: Code[20];
        ContactType: Option " ",Vendor,Customer;
    begin
        Initialize();

        PostPurchaseInvoice(PreAssignedNo);

        PurchInvHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();

        Navigate.OpenView();
        Navigate.FindByBusinessContact.Invoke();

        Navigate.ContactType.SetValue(ContactType::Vendor);
        Navigate.ContactNo.SetValue(PurchInvHeader."Buy-from Vendor No.");
        Navigate.ExtDocNo.SetValue(PurchInvHeader."Vendor Invoice No.");
        Navigate.Find.Invoke();

        Assert.AreEqual(1, Navigate."No. of Records".AsInteger(), 'There should be only one record on the first row');

        PostedPurchaseInvoice.Trap();
        Navigate.Show.Invoke();
        PostedPurchaseInvoice.Close();

        Navigate.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestShowUnpostedDocuments()
    var
        OneSalesInvoiceCustomer: Record Customer;
        MultipleSalesInvoicesCustomer: Record Customer;
        OneCreditMemoCustomer: Record Customer;
        MultipleCreditMemoCustomer: Record Customer;
        SalesInvoiceList: TestPage "Sales Invoice List";
        SalesInvoice: TestPage "Sales Invoice";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        Navigate: TestPage Navigate;
        ContactType: Option " ",Vendor,Customer;
    begin
        Initialize();
        LibrarySmallBusiness.CreateCustomer(OneSalesInvoiceCustomer);

        CreateSalesInvoice(OneSalesInvoiceCustomer);

        LibrarySmallBusiness.CreateCustomer(MultipleSalesInvoicesCustomer);
        CreateSalesInvoice(MultipleSalesInvoicesCustomer);
        CreateSalesInvoice(MultipleSalesInvoicesCustomer);

        LibrarySmallBusiness.CreateCustomer(OneCreditMemoCustomer);

        CreateCreditMemo(OneCreditMemoCustomer);

        LibrarySmallBusiness.CreateCustomer(MultipleCreditMemoCustomer);
        CreateCreditMemo(MultipleCreditMemoCustomer);
        CreateCreditMemo(MultipleCreditMemoCustomer);

        Navigate.OpenView();
        Navigate.FindByBusinessContact.Invoke();
        Navigate.ContactType.SetValue(ContactType::Customer);

        // Test opening one sales invoice
        Navigate.ContactNo.SetValue(OneSalesInvoiceCustomer."No.");
        Navigate.Find.Invoke();

        Assert.AreEqual(1, Navigate."No. of Records".AsInteger(), 'There should be only one record on the first row');

        SalesInvoice.Trap();
        Navigate.Show.Invoke();
        SalesInvoice.Close();

        // Test opening multiple sales invoices
        Navigate.ContactNo.SetValue(MultipleSalesInvoicesCustomer."No.");
        Navigate.Find.Invoke();
        Assert.AreEqual(2, Navigate."No. of Records".AsInteger(), 'There should be only two record on the first row');

        SalesInvoiceList.Trap();
        Navigate.Show.Invoke();
        SalesInvoiceList.Close();

        // Test opening one credit memo
        Navigate.ContactNo.SetValue(OneCreditMemoCustomer."No.");
        Navigate.Find.Invoke();

        Assert.AreEqual(1, Navigate."No. of Records".AsInteger(), 'There should be only one record on the first row');

        SalesCreditMemo.Trap();
        Navigate.Show.Invoke();
        SalesCreditMemo.Close();

        // Test opening multiple sales credit memos
        Navigate.ContactNo.SetValue(MultipleCreditMemoCustomer."No.");
        Navigate.Find.Invoke();
        Assert.AreEqual(2, Navigate."No. of Records".AsInteger(), 'There should be only two record on the first row');

        SalesCreditMemos.Trap();
        Navigate.Show.Invoke();
        SalesCreditMemos.Close();

        Navigate.Close();
    end;

    local procedure PostSalesInvoice(var SalesInvoiceNo: Code[20])
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);
        SalesInvoice."External Document No.".SetValue(SalesInvoice."No.");
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));
        SalesInvoice.SalesLines.New();
        FindSalesHeader(Customer, SalesHeader);
        SalesInvoiceNo := SalesHeader."No.";

        LibraryVariableStorage.Enqueue(PostInvoice);
        if PostInvoice then
            LibraryVariableStorage.Enqueue(true);

        PostedSalesInvoice.Trap();
        LibrarySales.EnableConfirmOnPostingDoc();
        SalesInvoice.Post.Invoke();
        PostedSalesInvoice.Close();
    end;

    local procedure PostPurchaseInvoice(var PurchaseInvoiceNo: Code[20])
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.CreateItem(Item);

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseInvoice."Vendor Invoice No.".SetValue(
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));

        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));
        PurchaseInvoice.PurchLines.New();

        FindPurchaseHeader(Vendor, PurchaseHeader);
        PurchaseInvoiceNo := PurchaseHeader."No.";

        LibraryVariableStorage.Enqueue(PostInvoice);
        LibraryVariableStorage.Enqueue(DoNotShowPostedDocument);
        PurchaseInvoice.Post.Invoke();
    end;

    local procedure CreateSalesInvoice(Customer: Record Customer)
    var
        Item: Record Item;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        LibrarySmallBusiness.CreateItem(Item);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer.Name);

        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));
        SalesInvoice.SalesLines.New();

        SalesInvoice.Close();
    end;

    local procedure CreateCreditMemo(Customer: Record Customer)
    var
        Item: Record Item;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        LibrarySmallBusiness.CreateItem(Item);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 20));
        SalesCreditMemo.SalesLines.New();

        SalesCreditMemo.Close();
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirmationDialog(Question: Text; var Reply: Boolean)
    var
        SelectedReply: Variant;
    begin
        LibraryVariableStorage.Dequeue(SelectedReply);
        Reply := SelectedReply;
    end;
}

