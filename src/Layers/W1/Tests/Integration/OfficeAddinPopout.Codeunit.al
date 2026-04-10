codeunit 139053 "Office Addin Popout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Add-in] [Sales]
        IsInitialized := false;
    end;

    var
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        OfficeHostType: DotNet OfficeHostType;
        BusRelCodeForCustomers: Code[10];
        BusRelCodeForVendors: Code[10];
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('CustomerActionPageHandlerForQuote')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageCreateQuotePopOut()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 156484] Stan can initiate tasks from the Sales Quote page
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode);

        // [WHEN] Outlook Main Engine finds email and contact/customer it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Customer card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Customers in Marketing Setup.
        ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers);
    end;

    [Test]
    [HandlerFunctions('CustomerActionPageHandlerForInvoice')]
    [Scope('OnPrem')]
    procedure MailEngineCustomerPageCreateInvoicePopOut()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 156492] Stan can initiate tasks from the Sales Invoice page
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode);

        // [WHEN] Outlook Main Engine finds email and contact/customer it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Customer card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Customers in Marketing Setup.
        ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers);
    end;

    [Test]
    [HandlerFunctions('VendorActionPageHandlerForInvoice')]
    [Scope('OnPrem')]
    procedure MailEngineVendorPageCreateInvoicePopOut()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 156495] Stan can initiate tasks from the Purchase Invoice page
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode);

        // [WHEN] Outlook Main Engine finds email and contact/vendor it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Vendor card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Vendors in Marketing Setup.
        ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineApplyVendorEntries()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        AppliesVendorEntries: TestPage "Apply Vendor Entries";
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 156496] Navigate action should not be visible on the "Apply Vendor Entries" page
        Initialize();

        // [GIVEN] Vendor Ledger Entry is create
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.FindFirst();

        // [WHEN] The applies entry opens to expose the actions on the page
        AppliesVendorEntries.Trap();
        PAGE.Run(PAGE::"Apply Vendor Entries", VendLedgEntry);

        // [THEN] Navigate action is not visible on the Apply Vendor Entries page
        Assert.IsFalse(AppliesVendorEntries.Navigate.Visible(), 'Navigate should not be visible.');
    end;

    local procedure Initialize()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Office Addin Popout");

        LibraryVariableStorage.Clear();
        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(OfficeHostType.OutlookItemRead);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Office Addin Popout");

        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        SetupSales();
        SetupMarketing();

        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Office Addin Popout");
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();

        SetOfficeHostProvider(CODEUNIT::"Library - Office Host Provider");

        OfficeManagement.InitializeHost(OfficeHost, HostType);
    end;

    local procedure SetOfficeHostUnAvailable()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // Test Providers checks whether we have registered Host in NameValueBuffer or not
        if NameValueBuffer.Get(SessionId()) then begin
            NameValueBuffer.Delete();
            Commit();
        end;
    end;

    local procedure SetOfficeHostProvider(ProviderId: Integer)
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        OfficeAddinSetup.Get();
        OfficeAddinSetup."Office Host Codeunit ID" := ProviderId;
        OfficeAddinSetup.Modify();
    end;

    local procedure RandomEmail(): Text[80]
    begin
        exit(StrSubstNo('%1@%2', CreateGuid(), 'example.com'));
    end;

    local procedure SetupSales()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Stockout Warning" := false;
        if SalesReceivablesSetup."Blanket Order Nos." = '' then
            SalesReceivablesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesReceivablesSetup."Return Order Nos." = '' then
            SalesReceivablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesReceivablesSetup."Order Nos." = '' then
            SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesReceivablesSetup."Quote Nos." = '' then
            SalesReceivablesSetup.Validate("Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesReceivablesSetup."Customer Nos." = '' then
            SalesReceivablesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify();
    end;

    local procedure SetupMarketing()
    var
        MarketingSetup: Record "Marketing Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        MarketingSetup.Get();
        if MarketingSetup."Contact Nos." = '' then
            MarketingSetup.Validate("Contact Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        MarketingSetup.Modify();
    end;

    local procedure CreateContactFromCustomer(Email: Text[80]; var ContactNo: Code[20]; var NewBusinessRelationCode: Code[10]): Code[20]
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        CreateContsFromCustomers: Report "Create Conts. from Customers";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForCustomers := ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
        NewBusinessRelationCode := BusinessRelation.Code;
        LibrarySales.CreateCustomer(Customer);

        // Create Contact from Customer by running the report Create Conts. from Customers.
        CreateContsFromCustomers.UseRequestPage(false);
        CreateContsFromCustomers.SetTableView(Customer);
        CreateContsFromCustomers.Run();

        ContactNo := UpdateContactEmail(BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Customer, Customer."No.", Email);
        exit(Customer."No.");
    end;

    local procedure ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers: Code[10]) OriginalBusRelCodeForCustomers: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        OriginalBusRelCodeForCustomers := MarketingSetup."Bus. Rel. Code for Customers";
        MarketingSetup.Validate("Bus. Rel. Code for Customers", BusRelCodeForCustomers);
        MarketingSetup.Modify(true);
    end;

    local procedure ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors: Code[10]) OriginalBusRelCodeForVendors: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        OriginalBusRelCodeForVendors := MarketingSetup."Bus. Rel. Code for Vendors";
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusRelCodeForVendors);
        MarketingSetup.Modify(true);
    end;

    local procedure CreateContactFromVendor(Email: Text[80]; var ContactNo: Code[20]; var NewBusinessRelationCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        CreateContsFromVendors: Report "Create Conts. from Vendors";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForVendors := ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        NewBusinessRelationCode := BusinessRelation.Code;
        LibraryPurchase.CreateVendor(Vendor);

        // Create Contact from Vendor by running the report Create Conts. from Vendors.
        CreateContsFromVendors.UseRequestPage(false);
        CreateContsFromVendors.SetTableView(Vendor);
        CreateContsFromVendors.Run();

        ContactNo := UpdateContactEmail(BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.", Email);
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdateContactEmail(BusinessRelationCode: Code[10]; LinkToTable: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]; Email: Text[80]) ContactNo: Code[20]
    var
        Contact: Record Contact;
    begin
        ContactNo := FindContactNo(BusinessRelationCode, LinkToTable, LinkNo);
        Contact.Get(ContactNo);
        Contact."E-Mail" := Email;
        Contact."Search E-Mail" := UpperCase(Email);

        // Need to set the type to person, default of company will cause issues...
        Contact.Type := Contact.Type::Person;

        Contact.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure RunMailEngine(var OfficeAddinContext: Record "Office Add-in Context")
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OutlookMailEngine: TestPage "Outlook Mail Engine";
    begin
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType.OutlookItemRead);
        OfficeAddinContext.SetRange(Version, OfficeAddin.Version);

        OutlookMailEngine.Trap();
        PAGE.Run(PAGE::"Outlook Mail Engine", OfficeAddinContext);
    end;

    [Scope('OnPrem')]
    procedure FindContactNo(BusinessRelationCode: Code[10]; LinkToTable: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelationCode);
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", LinkNo);
        ContactBusinessRelation.FindFirst();
        exit(ContactBusinessRelation."Contact No.");
    end;

    [Scope('OnPrem')]
    procedure ExtractComponent(var String: Text; var Component: Text)
    var
        DelimiterPos: Integer;
    begin
        DelimiterPos := StrPos(String, '|');
        Component := CopyStr(String, 1, DelimiterPos - 1);
        String := CopyStr(String, DelimiterPos + 1);
    end;

    [Scope('OnPrem')]
    procedure CheckActionParameter(ExpectedText: Text; ActualText: Text)
    begin
        case LowerCase(ExpectedText) of
            'any':
                Assert.AreNotEqual('', ActualText, 'Blank parameter passed to JavaScript function.');
            else
                Assert.AreEqual(ExpectedText, ActualText, 'Incorrect parameter passed to JavaScript function.');
        end;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure GetPopOutUrl(PageNo: Integer; DocNo: Code[20]): Text
    var
        BaseURL: Text;
        CompanyQueryPos: Integer;
    begin
        BaseURL := GetUrl(CLIENTTYPE::Web, CompanyName);
        CompanyQueryPos := StrPos(LowerCase(BaseURL), '?');
        BaseURL := InsStr(BaseURL, '/OfficePopOut.aspx', CompanyQueryPos) + '&';
        exit(StrSubstNo('%1mode=edit&page=%2&filter=''No.'' IS ''%3''', BaseURL, PageNo, DocNo));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerActionPageHandlerForQuote(var CustomerCard: TestPage "Customer Card")
    begin
        // Verify "New Sales Quote" action is visible.
        Assert.IsTrue(CustomerCard.NewSalesQuoteAddin.Visible(), 'New Sales Quote (add-in) should be visible');
        Assert.IsFalse(CustomerCard.NewSalesQuote.Visible(), 'New Sales Quote shouldn''t be visible.');
        CustomerCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerActionPageHandlerForInvoice(var CustomerCard: TestPage "Customer Card")
    begin
        // Verify "New Sales Invoice" action is visible.
        Assert.IsTrue(CustomerCard.NewSalesInvoiceAddin.Visible(), 'New Sales Invoice (add-in) should be visible.');
        Assert.IsFalse(CustomerCard.NewSalesInvoice.Visible(), 'New Sales Invoice shouldn''t be visible.');
        CustomerCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerActionPageHandlerForCreditMemo(var CustomerCard: TestPage "Customer Card")
    begin
        // Verify "New Sales Credit Memo" action is visible.
        Assert.IsTrue(CustomerCard.NewSalesCreditMemoAddin.Visible(), 'New Sales Credit Memo (add-in) should be visible.');
        Assert.IsFalse(CustomerCard.NewSalesCreditMemo.Visible(), 'New Sales Credit Memo shoudln''t be visible.');
        CustomerCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorActionPageHandlerForInvoice(var VendorCard: TestPage "Vendor Card")
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Verify "New Purchase Invoice" action is visible.
        Assert.IsTrue(VendorCard.NewPurchaseInvoiceAddin.Visible(), 'New Purchase Invoice (add-in) should be visible');
        Assert.IsFalse(VendorCard.NewPurchaseInvoice.Visible(), 'New Purchase Invoice shouldn''t be visible');
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // Validate Vendor Name is copied over to new Purchase Invoice
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(VendorCard.Name.Value);

        // Validate Vendor Address is copied over to new Purchase Invoice
        PurchaseInvoice."Buy-from Address".AssertEquals(VendorCard.Address.Value);

        VendorCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorActionPageHandlerForCreditMemo(var VendorCard: TestPage "Vendor Card")
    begin
        // Verify "New Purchase Credit Memo" action is visible.
        Assert.IsTrue(VendorCard.NewPurchaseCrMemoAddin.Visible(), 'New Purchase Credit memo (add-in) should be visible');
        Assert.IsFalse(VendorCard.NewPurchaseCrMemo.Visible(), 'New Purchase Credit memo should not be visible');
        LibraryVariableStorage.Enqueue(VendorCard.Name.Value);
        LibraryVariableStorage.Enqueue(VendorCard.Address.Value);
        VendorCard.NewPurchaseCrMemo.Invoke();

        VendorCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NewPurchaseCreditMemoPageHandler(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        // Validate Vendor Name is copied over to new Purchase Credit Memo
        PurchaseCreditMemo."Buy-from Vendor Name".AssertEquals(LibraryVariableStorage.DequeueText());

        // Validate Vendor Address is copied over to new Purchase Credit Memo
        PurchaseCreditMemo."Buy-from Address".AssertEquals(LibraryVariableStorage.DequeueText());
    end;
}

