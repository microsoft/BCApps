codeunit 139009 "Performance Profiler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Performance Profiler]
        TestsBuffer := 10;
        TestsBufferPercentage := 5;
        LibraryPerformanceProfiler.SetProfilerIdentification('139009 - Performance Profiler Tests')
    end;

    var
        GlobalCustLedgEntry: Record "Cust. Ledger Entry";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPerformanceProfiler: Codeunit "Library - Performance Profiler";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;
        BankRecIsInitialized: Boolean;
        TestsBuffer: Integer;
        TestsBufferPercentage: Integer;
        TraceDumpFilePath: Text;
        DateFormulaTxt: Label '<2D>', Locked = true;
        OpenBankStatementPageQst: Label 'Do you want to open the bank account statement?';

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderProcessorRoleCentertPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        OrderProcessorRoleCenter: TestPage "Order Processor Role Center";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        OrderProcessorRoleCenter.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestSalesOrderProcessorRoleCentertPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"SO Processor Activities", true);
        OrderProcessorRoleCenter.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenItemListPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        Item: Record Item;
        ItemList: TestPage "Item List";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        if Item.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        ItemList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenItemListPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Item List", true);
        ItemList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenItemListAndNavigatePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        Item: Record Item;
        ItemList: TestPage "Item List";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        if Item.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        ItemList.OpenView();
        ItemList.Next();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenItemListAndNavigatePerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Item List", true);
        ItemList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenItemCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        ItemCard: TestPage "Item Card";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryNotificationMgt.DisableAllNotifications();
        LibraryPerformanceProfiler.StartProfiler(true);
        ItemCard.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenItemCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Item Card", true);
        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenItemCardAndNavigatePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        ItemCard: TestPage "Item Card";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryNotificationMgt.DisableAllNotifications();
        LibraryPerformanceProfiler.StartProfiler(true);
        ItemCard.OpenView();
        ItemCard.Next();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenItemCardAndNavigatePerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Item Card", true);
        ItemCard.Close();
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TestNewItemCreationPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTemplates: Codeunit "Library - Templates";
        ItemCard: TestPage "Item Card";
    begin
        LibraryTemplates.EnableTemplatesFeature();
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryNotificationMgt.DisableAllNotifications();
        LibraryPerformanceProfiler.StartProfiler(true);
        ItemCard.OpenNew();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestNewItemCreationPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Item Card", true);
        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenCustomerListPerformance()
    var
        Customer: Record Customer;
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        CustomerList: TestPage "Customer List";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        if Customer.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        CustomerList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenCustomerListPerformance',
            PerfProfilerEventsTest."Object Type"::Page, 22, true);
        CustomerList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenCustomerListAndNavigatePerformance()
    var
        Customer: Record Customer;
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        CustomerList: TestPage "Customer List";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        if Customer.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        CustomerList.OpenView();
        CustomerList.Next();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenCustomerListAndNavigatePerformance',
            PerfProfilerEventsTest."Object Type"::Page, 22, true);
        CustomerList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenCustomerCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        CustomerCard.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenCustomerCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Customer Card", true);
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenCustomerCardAndNavigatePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        CustomerCard.OpenView();
        CustomerCard.Next();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenCustomerCardAndNavigatePerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Customer Card", true);
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenCustomerExistingCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibrarySales.CreateCustomer(Customer);
        LibraryPerformanceProfiler.StartProfiler(true);
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenCustomerExistingCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Customer Card", true);
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenCustomerCardSalesPricesAndDiscountPerformance()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerCard: TestPage "Customer Card";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);

        //Add customer discount group
        CreateCustomerDiscountGroupWithSalesLineDiscount(CustomerDiscountGroup, SalesLineDiscount, Item);
        Customer."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer.Modify(true);

        //Add customer specific discount
        CreateCustomerDiscountWithSalesLineDiscount(Customer, SalesLineDiscount, Item);

        //Add discount for all customer
        CreateAllCustomerDiscountWithSalesLineDiscount(SalesLineDiscount, Item);

        CustomerCard.OpenView();
        LibraryPerformanceProfiler.StartProfiler(true);
        CustomerCard.GotoRecord(Customer);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenCustomerCardSalesPricesAndDiscountPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Customer Card", true);
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenVendorListPerformance()
    var
        Vendor: Record Vendor;
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        VendorList: TestPage "Vendor List";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        if Vendor.IsEmpty() then
            exit;
        LibraryPerformanceProfiler.StartProfiler(true);
        VendorList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenVendorListPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Vendor List", true);
        VendorList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenVendorCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        VendorCard: TestPage "Vendor Card";
        ExpectedUniqueQuery: Integer;
        ExpectedTotalQuery: Integer;
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        ExpectedUniqueQuery := GetThreshold(82);
        ExpectedTotalQuery := GetThreshold(131);
        LibraryPerformanceProfiler.StartProfiler(true);
        VendorCard.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenVendorCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Vendor Card", true);
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenVendorCardAndNavigatePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        VendorCard: TestPage "Vendor Card";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        VendorCard.OpenView();
        VendorCard.Next();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenVendorCardAndNavigatePerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Vendor Card", true);
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesOrderCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesOrder.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenSalesOrderCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Order", true);
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesOrderListPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesOrderList: TestPage "Sales Order List";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesOrderList.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenSalesOrderListPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Order List", true);
        SalesOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesInvoiceCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesInvoice.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenSalesInvoiceCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Invoice", true);
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesInvoiceExistingCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibraryPerformanceProfiler.StartProfiler(true);
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
        PerfProfilerEventsTest, 'TestOpenSalesInvoiceExistingCardPerformance',
        PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Invoice", true);
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseOrderCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        PurchaseOrder.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenPurchaseOrderCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Purchase Order", true);
        PurchaseOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseInvoiceCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        PurchaseInvoice.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenPurchaseInvoiceCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Purchase Invoice", true);
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenPostedPurchaseInvoiceCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        ExpectedUniqueQuery: Integer;
        ExpectedTotalQuery: Integer;
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        ExpectedUniqueQuery := GetThreshold(40);
        ExpectedTotalQuery := GetThreshold(45);
        LibraryPerformanceProfiler.StartProfiler(true);
        PostedPurchaseInvoice.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenPostedPurchaseInvoiceCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Posted Purchase Invoice", true);
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenMySettingsPagePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        UserSettings: TestPage "User Settings";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        UserSettings.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenMySettingsPagePerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"User Settings", true);
        UserSettings.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenAllowedCompaniesCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        AccessibleCompanies: TestPage "Accessible Companies";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        AccessibleCompanies.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenAllowedCompaniesCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Accessible Companies", true);
        AccessibleCompanies.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenJobCardPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        JobCard: TestPage "Job Card";
    begin
        LibraryPerformanceProfiler.StartProfiler(true);
        JobCard.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenJobCardPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Job Card", true);
        JobCard.Close();
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOpportunityToQuotePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        ContactPerson: Record Contact;
        Opportunity: Record Opportunity;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        CustomerTempl: Record "Customer Templ.";
        LibraryTemplates: Codeunit "Library - Templates";
        SalesQuotes: TestPage "Sales Quote";
    begin
        LibraryTemplates.EnableTemplatesFeature();
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryMarketing.CreateCompanyContact(ContactPerson);
        CreateCustomerFromContact(Customer, ContactPerson, CustomerTempl.Code);
        LibraryMarketing.CreateActivity(Activity);
        CreateActivityStep(Activity.Code, ActivityStep.Type::Meeting, ActivityStep.Priority::High, DateFormulaTxt);
        LibraryMarketing.CreateOpportunity(Opportunity, ContactPerson."No.");
        LibraryPerformanceProfiler.StartProfiler(true);
        CreateSalesQuoteWithContact(SalesHeader, ContactPerson."No.", CustomerTempl.Code);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpportunityToQuotePerformance',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Library - Marketing", true);
        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        Commit();
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesQuotes.Print.Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpportunityToQuotePRINTPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Quote", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenBusinessManagerRoleCenterPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        BusinessManagerRoleCenter: TestPage "Business Manager Role Center";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        BusinessManagerRoleCenter.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenBusinessManagerRoleCenterPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Business Manager Role Center", true);
        BusinessManagerRoleCenter.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenO365ActivitiesPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        O365Activities: TestPage "O365 Activities";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryPerformanceProfiler.StartProfiler(true);
        O365Activities.OpenView();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestOpenO365ActivitiesPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"O365 Activities", true);
        O365Activities.Close();
    end;

    local procedure CreateActivityStep(ActivityCode: Code[10]; Type: Enum "Task Type"; Priority: Option; DateFormula: Text[30])
    var
        ActivityStep: Record "Activity Step";
    begin
        LibraryMarketing.CreateActivityStep(ActivityStep, ActivityCode);
        ActivityStep.Validate(Type, Type);
        ActivityStep.Validate(Priority, Priority);
        Evaluate(ActivityStep."Date Formula", DateFormula);
        ActivityStep.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPostPaymentForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PostedDocNo: Code[20];
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        SetupBalAccountAsBankAccount();
        PostedDocNo := CreateAndPostSalesInvoice(SalesHeader);
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo);
        LibraryPerformanceProfiler.StartProfiler(true);
        PostPayments(TempPaymentRegistrationBuffer);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostPaymentForSalesInvoice',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Payment Registration Mgt.", true);
    end;

    [Test]
    [HandlerFunctions('StandardStatementRequestHandler')]
    [Scope('OnPrem')]
    procedure TestReportCustomerStatementPerformance()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        LibraryPerformanceProfiler.StartProfiler(true);
        CustomerCard."Report Statement".Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestReportCustomerStatementPerformance',
            PerfProfilerEventsTest."Object Type"::Report, REPORT::"Standard Statement", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectPostedPurchaseInvoicePerformance()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedInvoiceNumber: Code[20];
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PostedInvoiceNumber := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchInvHeader.Get(PostedInvoiceNumber);
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        PostedPurchaseInvoice.CorrectInvoice.Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestCorrectPostedPurchaseInvoicePerformance',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Correct PstdPurchInv (Yes/No)", true);
    end;

    [Test]
    [HandlerFunctions('CancelPostedInvoiceConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCancelPostedPurchaseInvoicePerformance()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedInvoiceNumber: Code[20];
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PostedInvoiceNumber := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchInvHeader.Get(PostedInvoiceNumber);
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        PostedPurchaseInvoice.CancelInvoice.Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestCancelPostedPurchaseInvoicePerformance',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Cancel PstdPurchInv (Yes/No)", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPaymentForPurchaseInvoice()
    var
        Vendor: Record Vendor;
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        LibraryPerformanceProfiler.StartProfiler(true);
        PostPaymentToPurchaseInvoice(Vendor);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostPaymentForPurchaseInvoice',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Gen. Jnl.-Post", true);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSuggestVendorPaymentsPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PaymentJournal: TestPage "Payment Journal";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        PaymentJournal.OpenEdit();
        Commit();
        LibraryPerformanceProfiler.StartProfiler(true);
        PaymentJournal.SuggestVendorPayments.Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestSuggestVendorPaymentsPerformance',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Payment Journal", true);
        PaymentJournal.Close();
    end;

    [Test]
    [HandlerFunctions('BalanceToDateRequestHandler')]
    [Scope('OnPrem')]
    procedure TestVendorBalanceToDatePerformance()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        VendorCard: TestPage "Vendor Card";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        Commit();
        LibraryPerformanceProfiler.StartProfiler(true);
        VendorCard."Vendor - Balance to Date".Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestVendorBalanceToDatePerformance',
            PerfProfilerEventsTest."Object Type"::Report, REPORT::"Vendor - Balance to Date", true);
    end;

    [Test]
    [HandlerFunctions('PostStrShipAndInvoiceMenuHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderPostPerformance()
    var
        SalesHeader: Record "Sales Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        CreateSaleDocumentWithLines(SalesHeader, SalesHeader."Document Type"::Order, 10, 0);
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesOrder.Post.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestSalesOrderPostPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Order", true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('PostStrShipMenuHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderShipmentPerformance()
    var
        SalesHeader: Record "Sales Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        CreateSaleDocumentWithLines(SalesHeader, SalesHeader."Document Type"::Order, 10, 1);
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesOrder.Post.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestSalesOrderShipmentPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Order", true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestUndoPostedSalesShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryInventory.CreateItem(Item);
        CreateSaleDocumentWithLines(SalesHeader, SalesHeader."Document Type"::Order, 10, 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindSalesShipmentHeader(SalesShipmentHeader, SalesHeader."No.");
        PostedSalesShipment.OpenEdit();
        PostedSalesShipment.FILTER.SetFilter("No.", SalesShipmentHeader."No.");
        LibraryPerformanceProfiler.StartProfiler(true);
        PostedSalesShipment.SalesShipmLines.UndoShipment.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestUndoPostedSalesShipment',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Posted Sales Shpt. Subform", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderReleasePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        CreateSaleDocumentWithLines(SalesHeader, SalesHeader."Document Type"::Order, 10, 0);
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesOrder.Release.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestSalesOrderReleasePerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Order", true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderReopenPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        CreateSaleDocumentWithLines(SalesHeader, SalesHeader."Document Type"::Order, 10, 0);
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Release.Invoke();
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesOrder.Reopen.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestSalesOrderReopenPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Order", true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('PostStrShipAndInvoiceMenuHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderPostPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        CreatePurchDocumentWithLines(PurchaseHeader, PurchaseHeader."Document Type"::Order, 10);
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        PurchaseOrder.Post.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestPurchaseOrderPostPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Purchase Order", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderReleasePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        CreatePurchDocumentWithLines(PurchaseHeader, PurchaseHeader."Document Type"::Order, 10);
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        PurchaseOrder.Release.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestPurchaseOrderReleasePerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Purchase Order", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderReopenPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        CreatePurchDocumentWithLines(PurchaseHeader, PurchaseHeader."Document Type"::Order, 10);
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Release.Invoke();
        LibraryPerformanceProfiler.StartProfiler(true);
        PurchaseOrder.Reopen.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestPurchaseOrderReopenPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Purchase Order", true);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceGetShipmentLinesPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        PartiallyPostSalesOrder(SalesHeader);
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesInvoice.SalesLines.GetShipmentLines.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestSalesInvoiceGetShipmentLinesPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Invoice Subform", true);
    end;

    [Test]
    [HandlerFunctions('QuantityOnGetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure TestGetReceiptLinesAfterPartialPostingPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        PartiallyPostPurchaseOrder(PurchaseHeader);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        LibraryPerformanceProfiler.StartProfiler(true);
        PurchaseInvoice.PurchLines.GetReceiptLines.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestGetReceiptLinesAfterPartialPostingPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Purch. Invoice Subform", true);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure TestPostedSalesInvoicePrintPerformance()
    var
        SalesHeader: Record "Sales Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        CreateSaleDocumentWithLines(SalesHeader, SalesHeader."Document Type"::Invoice, 1, 0);
        OpenNewPostedSalesInvoice(
          PostedSalesInvoice,
          LibrarySales.PostSalesDocument(SalesHeader, false, true));
        LibraryPerformanceProfiler.StartProfiler(true);
        PostedSalesInvoice.Print.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestPostedSalesInvoicePrintPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Posted Sales Invoice", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderCreateApprovalWorkflowPerformance()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        WorkflowInitialize();
        PrepareSalesOrderForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesOrder.SendApprovalRequest.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestSalesOrderCreateApprovalWorkflowPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Order", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderApproveWorkflowPerformance()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesOrder: TestPage "Sales Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        WorkflowInitialize();
        PrepareSalesOrderForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);
        SendSalesOrderForApproval(SalesHeader);
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        SalesOrder.Approve.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestSalesOrderApproveWorkflowPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Sales Order", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderCreateApprovalWorkflowPerformance()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        WorkflowInitialize();
        PreparePurchaseOrderForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        PurchaseOrder.SendApprovalRequest.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestPurchaseOrderCreateApprovalWorkflowPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Purchase Order", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderApproveWorkflowPerformance()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        WorkflowInitialize();
        PreparePurchaseOrderForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);
        SendPurchaseOrderForApproval(PurchHeader);
        UpdatePurchaseApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchHeader);
        LibraryPerformanceProfiler.StartProfiler(true);
        PurchaseOrder.Approve.Invoke();
        LibraryPerformanceProfiler.StopProfiler(
          PerfProfilerEventsTest, 'TestPurchaseOrderApproveWorkflowPerformance',
          PerfProfilerEventsTest."Object Type"::Page, PAGE::"Purchase Order", true);
    end;

    local procedure BankRecInitialize()
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        if BankRecIsInitialized then
            exit;

        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryVariableStorage.Clear();
        BankRecIsInitialized := true;
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBankRecMatchAutomaticallyPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        BankRecInitialize();
        SetupBankAccRecEntries(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);
        Commit();

        LibraryPerformanceProfiler.StartProfiler(true);
        BankAccReconciliationPage.MatchAutomatically.Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestBankRecMatchAutomaticallyPerformance',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Library - Sales", true);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestBankRecPostPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        BankRecInitialize();
        SetupBankAccRecEntries(BankAccReconciliation, BankAccReconciliationPage, Amount, 1);
        Commit();

        BankAccReconciliationPage.MatchAutomatically.Invoke();
        BankAccReconciliationPage.StatementEndingBalance.SetValue(BankAccReconciliationPage.StmtLine.TotalBalance.AsDecimal());

        LibraryPerformanceProfiler.StartProfiler(true);
        BankAccReconciliationPage.Post.Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestBankRecPostPerformance',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Library - Sales", true);
    end;

    [Test]
    [HandlerFunctions('TransferToGenJnlReqPageHandler,GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TestBankRecTransferToGenJnlPerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        Amount: Decimal;
    begin
        BankRecInitialize();

        SetupBankAccRecEntries(BankAccReconciliation, BankAccReconciliationPage, Amount, 1.5);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccReconciliation."Bank Account No.";
        GenJournalBatch.Modify();

        // For TransferToGenJnlReqPageHandler:
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        Commit();

        LibraryPerformanceProfiler.StartProfiler(true);
        BankAccReconciliationPage."Transfer to General Journal".Invoke();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestBankRecTransferToGenJnlPerformance',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Library - Sales", true);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('LowLevelCodeConfirmHandler')]
    procedure TestCalcLowLevelCodePerformance()
    var
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryPerformanceProfiler.StartProfiler(true);
        Codeunit.Run(Codeunit::"Low-Level Code Calculator");
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestCalcLowLevelCodePerformance',
            PerfProfilerEventsTest."Object Type"::Codeunit, Codeunit::"Low-Level Code Calculator", true);
    end;












    local procedure CreateBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation.Validate("Bank Account No.", BankAccountNo);
        BankAccReconciliation.Validate("Statement No.",
          LibraryUtility.GenerateRandomCode(BankAccReconciliation.FieldNo("Statement No."), DATABASE::"Bank Acc. Reconciliation"));
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Insert(true);
    end;

    local procedure SetupBankAccRecEntries(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation"; var ExpectedAmount: Decimal; MatchFactor: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        "count": Integer;
    begin
        ExpectedAmount := LibraryRandom.RandDec(100, 2);

        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        for count := 1 to 2 do begin
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
              GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -ExpectedAmount);
            GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
            GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
            GenJournalLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");
        for count := 1 to 2 do begin
            LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
            BankAccReconciliationLine.Validate("Statement Amount", MatchFactor * ExpectedAmount);
            BankAccReconciliationLine.Modify(true);
        end;

        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.StmtLine.First();
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
    end;

    local procedure GetThreshold(ExpectedValue: Integer): Integer
    var
        Threshold: Integer;
    begin
        Threshold := Round(ExpectedValue * TestsBufferPercentage / 100, 1, '=');
        if (Threshold > TestsBuffer) then
            exit(ExpectedValue + Threshold);
        exit(ExpectedValue + TestsBuffer);

    end;

    local procedure WorkflowInitialize()
    var
        UserSetup: Record "User Setup";
        VATEntry: Record "VAT Entry";
    begin
        LibraryVariableStorage.Clear();
        VATEntry.DeleteAll();
        Commit();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure PostPayments(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        PaymentRegistrationMgt.ConfirmPost(TempPaymentRegistrationBuffer)
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure MarkDocumentAsPaid(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; CustomerNo: Code[20]; DocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocNo);
        TempPaymentRegistrationBuffer.Get(CustLedgerEntry."Entry No.");
        TempPaymentRegistrationBuffer.Validate("Payment Made", true);
        TempPaymentRegistrationBuffer.Validate("Date Received", WorkDate());
        TempPaymentRegistrationBuffer.Modify(true);
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocNo: Code[20]): Integer
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocNo);
        CustLedgerEntry.FindLast();
        exit(CustLedgerEntry."Entry No.")
    end;

    local procedure PostPaymentToPurchaseInvoice(Vendor: Record Vendor)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal."Document No.".SetValue('123');
        PaymentJournal."Account Type".SetValue(GenJournalLine."Account Type"::Vendor);
        PaymentJournal."Account No.".SetValue(Vendor."No.");
        PaymentJournal.Amount.SetValue(123);
        PaymentJournal.Post.Invoke();
    end;

    local procedure CreateCustomerDiscountWithSalesLineDiscount(var Customer: Record "Customer"; var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item)
    begin
        CreateSalesLineDiscount(
          SalesLineDiscount, Item, SalesLineDiscount."Sales Type"::Customer, Customer."No.", WorkDate(),
          LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateAllCustomerDiscountWithSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item)
    begin
        CreateSalesLineDiscount(
          SalesLineDiscount, Item, SalesLineDiscount."Sales Type"::"All Customers", '', WorkDate(),
          LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateCustomerDiscountGroupWithSalesLineDiscount(var CustomerDiscountGroup: Record "Customer Discount Group"; var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item)
    begin
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        CreateSalesLineDiscount(
          SalesLineDiscount, Item, SalesLineDiscount."Sales Type"::"Customer Disc. Group", CustomerDiscountGroup.Code, WorkDate(),
          LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item; SalesType: Option; SalesCode: Code[20]; StartingDate: Date; Quantity: Decimal)
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesType, SalesCode, StartingDate, '', '', Item."Base Unit of Measure",
          Quantity);
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        if (Question.Contains(OpenBankStatementPageQst)) then
            Reply := false
        else
            Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // This is a dummy Handler
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePageHandler(var SalesInvoicePage: TestPage "Sales Invoice")
    begin
        SalesInvoicePage.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CancelPostedInvoiceConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintSalesCreditMemoRequestPageHandler(var SalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        SalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePageHandler(var PurchaseInvoicePage: TestPage "Purchase Invoice")
    begin
        PurchaseInvoicePage.Close();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintPurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintPostedSalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.StartingDocumentNo.Value := '1';
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementRequestHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement."Start Date".Value := Format(CalcDate('<-1Y>', WorkDate()));
        StandardStatement."End Date".Value := Format(CalcDate('<+1Y>', WorkDate()));
        StandardStatement.ReportOutput.Value := 'XML - RDLC layouts only';
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BalanceToDateRequestHandler(var VendorBalancetoDate: TestRequestPage "Vendor - Balance to Date")
    begin
        VendorBalancetoDate.Vendor.SetFilter("Date Filter", Format(CalcDate('<+1Y>', WorkDate())));
        VendorBalancetoDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendConfirmationModalPageHandler(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectionPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnToCustHandler(var PmtAppln: TestPage "Payment Application")
    begin
        // Remove Entry is not the same customer
        if PmtAppln.AppliedAmount.AsDecimal() <> 0 then
            if PmtAppln."Account No.".Value <> GlobalCustLedgEntry."Customer No." then begin
                PmtAppln.Applied.SetValue(false);
                PmtAppln.Next();
            end;
        // Go to the first and check that it is the customer and scroll down to find the entry
        if PmtAppln.Applied.AsBoolean() then begin
            PmtAppln.RelatedPartyOpenEntries.Invoke();
            while PmtAppln.Next() and (PmtAppln.TotalRemainingAmount.AsDecimal() <> 0) do begin
                PmtAppln.Applied.SetValue(true);
                PmtAppln.RemainingAmountAfterPosting.AssertEquals(0);
            end;
        end;

        PmtAppln.OK().Invoke();
    end;

    local procedure SetupBalAccountAsBankAccount()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        SetupBalAccount(PaymentRegistrationSetup."Bal. Account Type"::"Bank Account", BankAccount."No.", UserId);
    end;

    local procedure SetupBalAccount(AccountType: Integer; AccountNo: Code[20]; SetUserID: Code[50])
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.SetRange("User ID", SetUserID);
        PaymentRegistrationSetup.DeleteAll();
        PaymentRegistrationSetup.SetRange("User ID");

        PaymentRegistrationSetup.Get();
        PaymentRegistrationSetup."User ID" := SetUserID;
        PaymentRegistrationSetup.Validate("Bal. Account Type", AccountType);
        PaymentRegistrationSetup.Validate("Bal. Account No.", AccountNo);
        PaymentRegistrationSetup."Use this Account as Def." := true;
        PaymentRegistrationSetup."Auto Fill Date Received" := true;

        PaymentRegistrationSetup.Insert(true);
    end;

    local procedure PrepareSalesOrderForApproval(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; var SalesHeader: Record "Sales Header")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        CreateSaleDocumentWithLines(SalesHeader, SalesHeader."Document Type"::Order, 1, 0);

        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");
    end;

    local procedure PreparePurchaseOrderForApproval(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; var PurchHeader: Record "Purchase Header")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        CreatePurchDocumentWithLines(PurchHeader, PurchHeader."Document Type"::Order, 1);
    end;

    local procedure UpdatePurchaseApprovalEntryWithTempUser(UserSetup: Record "User Setup"; PurchaseHeader: Record "Purchase Header")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure CreateUserSetupsAndChainOfApprovers(var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        CurrentUserSetup.Get(UserId);
        SetPurchaseAmountApprovalLimits(CurrentUserSetup, LibraryRandom.RandIntInRange(1, 100));
        SetLimitedPurchaseApprovalLimits(CurrentUserSetup);

        SetPurchaseAmountApprovalLimits(IntermediateApproverUserSetup, LibraryRandom.RandIntInRange(101, 1000));
        SetLimitedPurchaseApprovalLimits(IntermediateApproverUserSetup);

        FinalApproverUserSetup.Get(IntermediateApproverUserSetup."Approver ID");
        SetPurchaseAmountApprovalLimits(FinalApproverUserSetup, 0);
        SetUnlimitedPurchaseApprovalLimits(FinalApproverUserSetup);
    end;

    local procedure CreateSaleDocumentWithLines(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; NumberOfLines: Integer; QuantityToShip: Integer)
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        for Counter := 1 to NumberOfLines do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
            if QuantityToShip > 0 then
                SalesLine.Validate("Qty. to Ship", QuantityToShip);
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreatePurchDocumentWithLines(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; NumberOfLines: Integer)
    var
        PurchLine: Record "Purchase Line";
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '', 1);
        for Counter := 1 to NumberOfLines do begin
            PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
            PurchLine.Modify(true);
        end;
    end;

    local procedure SendSalesOrderForApproval(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SendApprovalRequest.Invoke();
        SalesOrder.Close();
    end;

    local procedure SendPurchaseOrderForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.SendApprovalRequest.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure SetSalesDocSalespersonCode(SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    begin
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure SetPurchaseAmountApprovalLimits(var UserSetup: Record "User Setup"; PurchaseApprovalLimit: Integer)
    begin
        UserSetup."Purchase Amount Approval Limit" := PurchaseApprovalLimit;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedPurchaseApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Purchase Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure SetLimitedPurchaseApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Purchase Approval" := false;
        UserSetup.Modify(true);
    end;

    local procedure PartiallyPostSalesOrder(var SalesHeader: Record "Sales Header")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        PartiallyShipSalesDocument(SalesHeader, CustomerNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
    end;

    local procedure PartiallyPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        VendorNo: Code[20];
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        VendorNo := CreateAndModifyVendor(Currency.Code, VATPostingSetup."VAT Bus. Posting Group");
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, VendorNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostStrShipAndInvoiceMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostStrShipMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.First();
        GetShipmentLines.OK().Invoke();
    end;

    local procedure PartiallyShipSalesDocument(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandDec(10, 2));  // Taking Random values for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
        SalesLine.Modify(true);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure CreateAndModifyVendor(CurrencyCode: Code[10]; VATBusinessPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendorWithCurrencyCode(CurrencyCode));
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, 0);
    end;

    local procedure CreateVendorWithCurrencyCode(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithLastDirectCost(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; InvDiscountAmount: Decimal)
    var
        QtyToReceive: Decimal;
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithLastDirectCost(), 2 * LibraryRandom.RandInt(20));
        QtyToReceive := PurchaseLine.Quantity / 2; // Taking here 2 for partial posting.
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Direct Unit Cost", 100 + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Inv. Discount Amount", InvDiscountAmount);
        PurchaseLine.Modify(true);
    end;

    local procedure OpenNewPostedSalesInvoice(var PostedSalesInvoice: TestPage "Posted Sales Invoice"; PostedDocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PostedDocNo);
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
    end;

    local procedure CreateSalesQuoteWithContact(var SalesHeader: Record "Sales Header"; SellToContactNo: Code[20]; CustomerTemplCode: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader.Insert(true);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Validate("Sell-to Contact No.", SellToContactNo);
        SalesHeader.Validate("Sell-to Customer Templ. Code", CustomerTemplCode);
        SalesHeader.Modify(true);
    end;

    procedure CreateCustomerFromContact(var Customer: Record Customer; Contact: Record Contact; CustomerTemplateCode: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        Contact.SetHideValidationDialog(true);
        Contact.CreateCustomerFromTemplate(CustomerTemplateCode);

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.FindFirst();

        Customer.Get(ContactBusinessRelation."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityOnGetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.First();
        GetReceiptLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestHandler(var StandardPurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        StandardPurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure FindSalesShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; OrderNo: Code[20])
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestPageHandler(var SalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MatchRecLinesReqPageHandler(var MatchBankAccReconciliation: TestRequestPage "Match Bank Entries")
    begin
        MatchBankAccReconciliation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToGenJnlReqPageHandler(var TransBankRecToGenJnl: TestRequestPage "Trans. Bank Rec. to Gen. Jnl.")
    var
        TemplateName: Variant;
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        LibraryVariableStorage.Dequeue(BatchName);
        TransBankRecToGenJnl."GenJnlLine.""Journal Template Name""".SetValue(TemplateName);
        TransBankRecToGenJnl."GenJnlLine.""Journal Batch Name""".SetValue(BatchName);
        TransBankRecToGenJnl.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GenJnlPageHandler(var GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure LowLevelCodeConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
