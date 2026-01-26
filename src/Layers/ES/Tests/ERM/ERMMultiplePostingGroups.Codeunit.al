codeunit 134195 "ERM Multiple Posting Groups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Posting Group]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        PostingGroupNonEditableErr: Label 'Posting Group is not editable in General Journal page';
        VendorPostingGroupMatchErr: Label 'G/L Entry Bill Account Not Matching with Purchase Invoice Vendor Posting Group Bill Account';
        VendorPostingGroupErr: Label 'Vendor Posting Group must be %1 in %2.', Comment = '%1= Value ,%2=Table Name';
        AltPostingGroupNotFilledInErr: Label 'You cannot change the value %1 to %2 because Alternative Employee Posting Group has not been filled in.', Comment = '%1 = posting group, %2 = alt. posting group';

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesOrderCustomerPostingGroupIsNotEditableIfFeatureDisabled()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        SalesOrder.OpenNew();
        Assert.IsFalse(SalesOrder."Customer Posting Group".Editable(), 'Customer Posting Group is editable in Sales Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesOrderCustomerPostingGroupIsEditableIfAllowedForCustomer()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer No.".SetValue(Customer."No.");
        Assert.IsTrue(SalesOrder."Customer Posting Group".Editable(), 'Customer Posting Group is not editable in Sales Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesInvoiceCustomerPostingGroupIsNotEditableIfFeatureDisabled()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        SalesInvoice.OpenNew();
        Assert.IsFalse(SalesInvoice."Customer Posting Group".Editable(), 'Customer Posting Group is editable in Sales Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesInvoiceCustomerPostingGroupIsEditableIfAllowedForCustomer()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer No.".SetValue(Customer."No.");
        Assert.IsTrue(SalesInvoice."Customer Posting Group".Editable(), 'Customer Posting Group is not editable in Sales Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesCreditMemoCustomerPostingGroupIsNotEditableIfFeatureDisabled()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        SalesCreditMemo.OpenNew();
        Assert.IsFalse(SalesCreditMemo."Customer Posting Group".Editable(), 'Customer Posting Group is editable in Sales Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesCreditMemoCustomerPostingGroupIsEditableIfAllowedForCustomer()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer No.".SetValue(Customer."No.");
        Assert.IsTrue(SalesCreditMemo."Customer Posting Group".Editable(), 'Customer Posting Group is not editable in Sales Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesReturnOrderCustomerPostingGroupIsNotEditableIfFeatureDisabled()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        SalesReturnOrder.OpenNew();
        Assert.IsFalse(SalesReturnOrder."Customer Posting Group".Editable(), 'Customer Posting Group is editable in Sales Return Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesReturnOrderCustomerPostingGroupIsEditableIfAllowedForCustomer()
    var
        Customer: Record Customer;
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer No.".SetValue(Customer."No.");
        Assert.IsTrue(SalesReturnOrder."Customer Posting Group".Editable(), 'Customer Posting Group is not editable in Sales Return Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderVendorPostingGroupIsNotEditableIfFeatureDisabled()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        PurchaseOrder.OpenNew();
        Assert.IsFalse(PurchaseOrder."Vendor Posting Group".Editable(), 'Vendor Posting Group is editable in Purchase Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderVendorPostingGroupIsEditableIfAllowedForVendor()
    var
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();

        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor No.".SetValue(Vendor."No.");
        Assert.IsTrue(PurchaseOrder."Vendor Posting Group".Editable(), 'Vendor Posting Group is not editable in Purchase Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseInvoiceVendorPostingGroupIsNotEditableIfFeatureDisabled()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        PurchaseInvoice.OpenNew();
        Assert.IsFalse(PurchaseInvoice."Vendor Posting Group".Editable(), 'Vendor Posting Group is editable in Purchase Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseInvoiceVendorPostingGroupIsEditableIfAllowedForVendor()
    var
        Vendor: Record vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor No.".SetValue(Vendor."No.");
        Assert.IsTrue(PurchaseInvoice."Vendor Posting Group".Editable(), 'Vendor Posting Group is not editable in Purchase Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseCreditMemoVendorPostingGroupIsNotEditableIfFeatureDisabled()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        PurchaseCreditMemo.OpenNew();
        Assert.IsFalse(PurchaseCreditMemo."Vendor Posting Group".Editable(), 'Vendor Posting Group is editable in Purchase Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseCreditMemoVendorPostingGroupIsEditableIfAllowedForVendor()
    var
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor No.".SetValue(Vendor."No.");
        Assert.IsTrue(PurchaseCreditMemo."Vendor Posting Group".Editable(), 'Vendor Posting Group is not editable in Purchase Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseReturnOrderCustomerPostingGroupIsNotEditableIfFeatureDisabled()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        PurchaseReturnOrder.OpenNew();
        Assert.IsFalse(PurchaseReturnOrder."Vendor Posting Group".Editable(), 'Customer Posting Group is editable in Purchase Return Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseReturnOrderCustomerPostingGroupIsEditableIfAllowedForVendor()
    var
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();

        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor No.".SetValue(Vendor."No.");
        Assert.IsTrue(PurchaseReturnOrder."Vendor Posting Group".Editable(), 'Vendor Posting Group is not editable in Purchase Return Order page');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceCustomerPostingGroupIsNotEditableIfFeatureDisabled()
    var
        ServiceInvoice: TestPage "Service Invoice";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        UpdateServiceDocumentNos(0, NoSeriesCode, false);

        SetServiceAllowMultiplePostingGroups(false);

        ServiceInvoice.OpenNew();
        Assert.IsFalse(ServiceInvoice."Customer Posting Group".Editable(), 'Customer Posting Group is editable in Service Invoice page');
        if NoSeriesCode <> '' then
            UpdateServiceDocumentNos(0, NoSeriesCode, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceCustomerPostingGroupIsEditableIfAllowedForCustomer()
    var
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
    begin
        Initialize();

        SetServiceAllowMultiplePostingGroups(true);
        LibraryService.SetupServiceMgtNoSeries();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        ServiceInvoice.OpenNew();
        ServiceInvoice."Bill-to Customer No.".SetValue(Customer."No.");
        Assert.IsTrue(ServiceInvoice."Customer Posting Group".Editable(), 'Customer Posting Group is not editable in Service Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceCreditMemoCustomerPostingGroupIsNotEditableIfFeatureDisabled()
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
        NoSeriesCode: Code[20];
    begin
        Initialize();
        UpdateServiceDocumentNos(1, NoSeriesCode, false);

        SetServiceAllowMultiplePostingGroups(false);

        ServiceCreditMemo.OpenNew();
        Assert.IsFalse(ServiceCreditMemo."Customer Posting Group".Editable(), 'Customer Posting Group is editable in Service Credit Memo page');
        if NoSeriesCode <> '' then
            UpdateServiceDocumentNos(1, NoSeriesCode, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceCreditMemoCustomerPostingGroupIsEditableIfAllowedForCustomer()
    var
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        Initialize();

        SetServiceAllowMultiplePostingGroups(true);
        LibraryService.SetupServiceMgtNoSeries();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        ServiceCreditMemo.OpenNew();
        ServiceCreditMemo."Bill-to Customer No.".SetValue(Customer."No.");
        Assert.IsTrue(ServiceCreditMemo."Customer Posting Group".Editable(), 'Customer Posting Group is not editable in Service Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFinanceChargeMemoCustomerPostingGroupIsNotEditableIfFeatureDisabled()
    var
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        FinanceChargeMemo.OpenNew();
        Assert.IsFalse(FinanceChargeMemo."Customer Posting Group".Editable(), 'Customer Posting Group is editable in Finance Charge Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFinanceChargeMemoCustomerPostingGroupIsEditableIfAllowedForCustomer()
    var
        Customer: Record Customer;
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        FinanceChargeMemo.OpenNew();
        FinanceChargeMemo."Customer No.".SetValue(Customer."No.");
        Assert.IsTrue(FinanceChargeMemo."Customer Posting Group".Editable(), 'Customer Posting Group is not editable in Finance Charge Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckChangePostingGroupInSalesInvoiceIfFeatureDisabled()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        // Create sales invoice, change customer posting group and post
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Invoice, Customer."No.", '', 1, '', 0D);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckChangePostingGroupInPurchaseInvoiceIfFeatureDisabled()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        // Create sales invoice, change customer posting group and post
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesInvoiceIfAnotherCustomerPostingGroupCannotBeUsed()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        // Create sales invoice, change customer posting group and post
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Invoice, Customer."No.", '', 1, '', 0D);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);

        // Verify another posting group cannot be assigned
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostSalesInvoiceWithAnotherCustomerPostingGroup()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        // Create sales invoice, change customer posting group and post
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Invoice, Customer."No.", '', 1, '', 0D);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateAltCustomerPostingGroup(Customer."Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Modify();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Check customer posting group code in posted records
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindFirst();
        Assert.AreEqual(
            CustLedgerEntry."Customer Posting Group", CustomerPostingGroup.Code,
            'Customer Posting Group in Customer Ledger Entry is not correct.');

        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindFirst();
        Assert.AreEqual(
            SalesInvoiceHeader."Customer Posting Group", CustomerPostingGroup.Code,
            'Customer Posting Group in Sales Invoice Header is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesInvoiceApplyUnapplyMultiplePostingGroups()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerPostingGroup2: Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLRegister: Record "G/L Register";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        TotalAmount: Decimal;
        LastGLRegNo: Integer;
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        // Create sales invoice, change customer posting group and post
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Invoice, Customer."No.", '', 1, '', 0D);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup2);
        LibrarySales.CreateAltCustomerPostingGroup(Customer."Customer Posting Group", CustomerPostingGroup2.Code);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup2.Code);
        SalesHeader.Modify();
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify();
        SalesHeader.CalcFields("Amount Including VAT");
        TotalAmount := SalesHeader."Amount Including VAT";

        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        GLRegister.FindLast();
        LastGLRegNo := GLRegister."No.";

        // Create payment with default customer posting group and post
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, Customer."No.", -TotalAmount);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Modify();
        PaymentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLRegister.FindLast();
        LastGLRegNo := GLRegister."No.";

        // Apply payment to invoice - should post 2 G/L entries between Receivables accounts
        ApplyAndPostCustomerEntry(PaymentNo, InvoiceNo, -TotalAmount, "Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice);

        // Unapply payment - should post 2 reversal G/L entries between Receivables accounts
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, "Gen. Journal Document Type"::Payment, PaymentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // Verify posted unapply G/L entries - currently not possible for ES due to Cartera
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithAlternativeCustomerPostingGroup()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Invoice, Post and Verify Sales Invoice Header and Line.

        // Setup: Create Sales Invoice.
        Initialize();
        SetSalesAllowMultiplePostingGroups(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Invoice, Customer."No.", '', 1, '', 0D);

        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateAltCustomerPostingGroup(Customer."Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Modify();

        // Exercise: Post Sales Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SetSalesAllowMultiplePostingGroups(false);

        // Verify customer posting group in posted document and ledger entries
        VerifySalesInvoiceCustPostingGroup(GetSalesInvoiceHeaderNo(SalesHeader."No."), CustomerPostingGroup);
    end;

    [Test]
    procedure PostSalesPrepaymentInvoiceWithAlternativeCustomerPostingGroup()
    var
        LineGLAccount: Record "G/L Account";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // Create Sales Invoice, Post Prepayment and Verify Sales Invoice Header

        // Setup: Create Sales Invoice.
        Initialize();
        SetSalesAllowMultiplePostingGroups(true);
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);

        CreateSalesDocument(SalesHeader, SalesLine, Customer."No.", LineGLAccount);

        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateAltCustomerPostingGroup(Customer."Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesHeader.Modify();

        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify();

        // Exercise: Post Sales Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SetSalesAllowMultiplePostingGroups(false);

        // Verify customer posting group in posted document and ledger entries
        VerifySalesPrepaymentInvoiceCustPostingGroup(SalesHeader."Last Prepayment No.", CustomerPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseInvoiceAnotherVendorPostingGroupCannotBeUsed()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        // Create sales invoice, change customer posting group
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);

        // Verify another posting group cannot be assigned
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchInvoiceApplyUnapplyMultiplePostingGroups()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLRegister: Record "G/L Register";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        TotalAmount: Decimal;
        LastGLRegNo: Integer;
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        // Create purchase invoice, change vendor posting group and post
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Modify();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify();
        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmount := PurchaseHeader."Amount Including VAT";

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        GLRegister.FindLast();
        LastGLRegNo := GLRegister."No.";

        // Create payment with default vendor posting group and post
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.", TotalAmount);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Modify();
        PaymentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLRegister.FindLast();
        LastGLRegNo := GLRegister."No.";

        // Apply payment to invoice - should post 2 G/L entries between Payables accounts
        ApplyAndPostVendorEntry(PaymentNo, InvoiceNo, TotalAmount, "Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice);

        // Unapply payment - should post 2 reversal G/L entries between Payables accounts
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Payment, PaymentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // Verify posted unapply G/L entries - currently not possible for ES due to Cartera
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFCYPurchInvoiceApplyUnapplyMultiplePostingGroups()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo, CurrencyCode : Code[20];
        PaymentNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [SCENARIO 550230] CONSISTENCY error if you try to apply a Payment and a Bill using Multiple Posting Groups with foreign currencies in the Spanish version.
        Initialize();

        // [GIVEN] Allowed multiple vendor posting groups
        SetPurchAllowMultiplePostingGroups(true);

        // [WHEN] Posting invoice for a FCY vendor with multiple posting groups
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify();
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        LibraryPurchase.CreateFCYPurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D, CurrencyCode);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Modify();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify();
        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmount := PurchaseHeader."Amount Including VAT";

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Payment is posted with default vendor posting group
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.", TotalAmount);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Modify();
        PaymentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Applying payment to invoice - should post 2 G/L entries between Payables accounts
        ApplyAndPostVendorEntry(PaymentNo, InvoiceNo, TotalAmount, "Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice);

        // [THEN] Unapplying payment - should post 2 reversal G/L entries between Payables accounts
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Payment, PaymentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostPurchaseInvoiceWithAnotherVendorPostingGroup()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        // Create purchase invoice, change vendor posting group and post
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup.Code);
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        PurchaseHeader.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Check vendor posting group code in posted records
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(
            VendorLedgerEntry."Vendor Posting Group", VendorPostingGroup.Code,
            'Vendor Posting Group in Vendor Ledger Entry is not correct.');

        PurchInvHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst();
        Assert.AreEqual(
            PurchInvHeader."Vendor Posting Group", VendorPostingGroup.Code,
            'Vendor Posting Group in Purchase Invoice Header is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchInvoiceApplyUnapplyPmtWithAlternativePostingGroup()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [SCENARIO 550235] [24.x] Unbalanced G/L Entries if you post Invoice and Payment using Multiple Posting Groups in the Spanish version.
        Initialize();

        // [GIVEN] Allowed multiple vendor posting groups
        SetPurchAllowMultiplePostingGroups(true);

        // [WHEN] Posting invoice a vendor with multiple posting groups
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Modify();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify();
        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmount := PurchaseHeader."Amount Including VAT";

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Payment is posted for that vendor with alternative posting group
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.", TotalAmount);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Validate("Posting Group", VendorPostingGroup2.Code);
        GenJournalLine.Modify();
        PaymentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Applying payment to invoice
        // [THEN] This should post 2 G/L entries between Payables accounts
        ApplyAndPostVendorEntry(PaymentNo, InvoiceNo, TotalAmount, "Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice);

        // [WHEN] Unapplying payment from invoice
        // [THEN] This should post 2 reversal G/L entries between Payables accounts
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Payment, PaymentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMultiplePurchInvoiceApplyUnapplyPmtWithMainPostingGroup()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader, PurchaseHeader2 : Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry, VendorLedgerEntry2 : Record "Vendor Ledger Entry";
        InvoiceNo, Invoice2No : Code[20];
        PaymentNo, Payment2No : Code[20];
        TotalAmount, TotalAmount2, SumOfAmountLCY : Decimal;
        PayablesAccountCodes: List of [Code[20]];
    begin
        // [SCENARIO 551376] [24.x] Wrong vendor posting group used when posting payment application to two purchase invoices with multiple posting groups
        Initialize();

        // [GIVEN] Allowed multiple vendor posting groups
        SetPurchAllowMultiplePostingGroups(true);

        // [GIVEN] Posting two invoices for a vendor with multiple posting groups (invoices have different posting groups)
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Modify();
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Modify();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify();
        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmount := PurchaseHeader."Amount Including VAT";
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader2, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        PurchaseHeader2.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        PurchaseHeader2.Modify();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify();
        PurchaseHeader2.CalcFields("Amount Including VAT");
        TotalAmount2 := PurchaseHeader2."Amount Including VAT";
        Invoice2No := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // [GIVEN] Two payments are entered in journal for that vendor with main posting group, pointing to two invoices with 'Applies-to Doc. No'
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.", TotalAmount);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Validate("Posting Group", VendorPostingGroup.Code);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify();
        PaymentNo := GenJournalLine."Document No.";
        // [WHEN] Posting of the journal line (it doesn't fail saying that bills account must be specified)
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, Vendor."No.", TotalAmount2);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Validate("Posting Group", VendorPostingGroup.Code);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", Invoice2No);
        GenJournalLine.Modify();
        Payment2No := GenJournalLine."Document No.";
        // [WHEN] Posting of the journal line (it doesn't fail saying that bills account must be specified)
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The two vendor ledger entries should be closed (applied)
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Payment, PaymentNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, "Gen. Journal Document Type"::Payment, Payment2No);
        Assert.IsFalse(VendorLedgerEntry.Open, '');
        Assert.IsFalse(VendorLedgerEntry2.Open, '');

        // [THEN] The Amount on G/L Entries for payables accounts of the two posting groups should balance out
        PayablesAccountCodes.Add(VendorPostingGroup."Payables Account");
        PayablesAccountCodes.Add(VendorPostingGroup2."Payables Account");
        SumOfAmountLCY := SumGLEntryAmountsForPayablesAccounts(PayablesAccountCodes);
        Assert.AreEqual(0, SumOfAmountLCY, '');

        // [WHEN] Unapplying the ledger entries
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry2);

        // [THEN] The two vendor ledger entries should be open (unapplied)
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry2.Get(VendorLedgerEntry2."Entry No.");
        Assert.IsTrue(VendorLedgerEntry.Open, '');
        Assert.IsTrue(VendorLedgerEntry2.Open, '');

        // [THEN] The Amount on G/L Entries for payables accounts of the two posting groups should balance out
        SumOfAmountLCY := SumGLEntryAmountsForPayablesAccounts(PayablesAccountCodes);
        Assert.AreEqual(0, SumOfAmountLCY, '');
    end;

    local procedure SumGLEntryAmountsForPayablesAccounts(var PayablesAccountCodes: List of [Code[20]]): Decimal
    var
        GLEntry: Record "G/L Entry";
        AccountCode: Code[20];
        Started: Boolean;
        FilterString: Text;
    begin
        foreach AccountCode in PayablesAccountCodes do begin
            if Started then
                FilterString += '|'
            else
                Started := true;
            FilterString += Format(AccountCode);
        end;
        GLEntry.SetFilter("G/L Account No.", FilterString);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"G/L Account");
        GLEntry.CalcSums(Amount);
        exit(GLEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostServiceInvoiceIfAnotherCustomerPostingGroupCannotBeUsed()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        Initialize();

        SetServiceAllowMultiplePostingGroups(false);
        LibraryService.SetupServiceMgtNoSeries();

        // Create sales invoice, change customer posting group and post
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        ServiceHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostServiceInvoiceWithAnotherCustomerPostingGroup()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        SetServiceAllowMultiplePostingGroups(true);
        LibraryService.SetupServiceMgtNoSeries();

        // Create sales invoice, change customer posting group and post
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItemLine."Item No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");
        ServiceLine.Modify(true);

        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateAltCustomerPostingGroup(Customer."Customer Posting Group", CustomerPostingGroup.Code);
        ServiceHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        ServiceHeader.Modify();

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Check customer posting group code in posted records
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindFirst();

        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGeneralJournalPostingGroupIsEditableIfAllowedForCustomer()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalPage: TestPage "General Journal";
    begin
        // [SCENARIO 542829] Allow Multiple Posting Groups not usable in General Journal because Posting Group field cannot be made Editable for Customer
        Initialize();

        // [GIVEN] Enable Allow Multiple Posting Group on Sales & Receivables Setup
        SetSalesAllowMultiplePostingGroups(true);

        // [GIVEN] Create new customer with Allow Multiple Posting Groups
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        // [WHEN] Create General Journal line
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.");

        // [THEN] Open General Journal page and verify field "Posting Group" is editable
        GenJournalPage.OpenEdit();
        GenJournalPage.GoToRecord(GenJournalLine);
        Assert.IsTrue(GenJournalPage."Posting Group".Editable(), PostingGroupNonEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGeneralJournalPostingGroupIsEditableIfAllowedForVendor()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalPage: TestPage "General Journal";
    begin
        // [SCENARIO 542829] Allow Multiple Posting Groups not usable in General Journal because Posting Group field cannot be made Editable for Vendor
        Initialize();

        // [GIVEN] Enable Allow Multiple Posting Group on Purchases & Payables Setup
        SetPurchAllowMultiplePostingGroups(true);

        // [GIVEN] Create new vendor with Allow Multiple Posting Groups
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();

        // [WHEN] Create General Journal line
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.");

        // [THEN] Open General Journal page and verify field "Posting Group" is editable
        GenJournalPage.OpenEdit();
        GenJournalPage.GoToRecord(GenJournalLine);
        Assert.IsTrue(GenJournalPage."Posting Group".Editable(), PostingGroupNonEditableErr);
    end;

    [Test]
    procedure CheckPurchInvoicewithMultipleVendorPostingGroup()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        GLEntry: Record "G/L Entry";
        LibraryInventory: Codeunit "Library - Inventory";
        InvoiceNo: Code[20];
        CheckGLEntry: Boolean;
    begin
        // [SCENARIO 563038] The Bills Account is incorrectly taken from the main Vendor Posting Group even if an Alternative Vendor Posting Group 
        //is used causing unbalance G/L Accounts posted in the Spanish version.
        Initialize();

        // [GIVEN] Allowed multiple vendor posting groups
        SetPurchAllowMultiplePostingGroups(true);

        // [GIVEN] Created Vendor Posting Group-1
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);

        // [GIVEN] Created Payment Terms for Proportional VAT distribution
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        PaymentTerms.Validate("VAT distribution", PaymentTerms."VAT distribution"::Proportional);
        PaymentTerms.Modify(true);

        // [GIVEN] Created Payment Method
        LibraryInventory.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.Validate("Create Bills", true);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::"Bill of Exchange");
        PaymentMethod.Validate("Collection Agent", PaymentMethod."Collection Agent"::Bank);
        PaymentMethod.Modify(true);

        // [GIVEN] Created Vendor for Allow Multiple Posting Groups
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);

        // [GIVEN] Create Purchase invoices for a vendor with multiple posting groups 
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);

        // [GIVEN] Created Vendor Posting Group-2
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);

        // [GIVEN] Setup Vendor Posting Group-2 as Alternative Posting Group for Vendor Posting Group-1
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup2.Code);

        // [GIVEN] Modify Vendor Posting Group on Purchase Invoice
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Exercise: Posting purchase Document and find G/L Entrys for Bill
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CheckGLEntry := FindGLEntry(GLEntry, VendorPostingGroup2."Bills Account", InvoiceNo);

        // [THEN] For Bill G/l Entry's G/L Account Should be match with Modified Invoice Vendor Posting Group Bill Account.
        Assert.AreEqual(True, CheckGLEntry, VendorPostingGroupMatchErr);

    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGeneralJournalPostingGroupIsEditableIfAllowedForEmployee()
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalPage: TestPage "General Journal";
    begin
        // [SCENARIO 590692] Allow Multiple Posting Groups not usable in General Journal because Posting Group field cannot be made Editable for Employee
        Initialize();

        // [GIVEN] Enable Allow Multiple Posting Group on Human Resources Setup
        SetHRAllowMultiplePostingGroups(true);

        // [GIVEN] Create new employee with Allow Multiple Posting Groups
        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Allow Multiple Posting Groups", true);
        Employee.Modify();

        // [WHEN] Create General Journal line
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Employee, Employee."No.");

        // [THEN] Open General Journal page and verify field "Posting Group" is editable
        GenJournalPage.OpenEdit();
        GenJournalPage.GoToRecord(GenJournalLine);
        Assert.IsTrue(GenJournalPage."Posting Group".Editable(), PostingGroupNonEditableErr);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    procedure CheckVoidCheckVendLdgerEntryWithMultiplePostingGroups()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // [SCENARIO 575576] Verify Voided Check in the Vendor Ledger entries when Allow Multiple Posting Groups is enabled.
        Initialize();

        // [GIVEN] Set Allow Multiple Posting Groups on Purchases & Payable Setup.
        SetPurchAllowMultiplePostingGroups(true);

        // [GIVEN] Create Vendor with Allow Multiple Posting Groups as True.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Modify();
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");

        // [GIVEN] Create new Vendor Posting Group and assigned as Alternative Groups.
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        LibraryPurchase.CreateAltVendorPostingGroup(Vendor."Vendor Posting Group", VendorPostingGroup2.Code);
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup2.Code, Vendor."Vendor Posting Group");

        // [GIVEN] Create and Post Payment Journal with VendorPostingGroup2.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CreateCurrencyCode());
        BankAccount.Modify(true);
        PostPaymentJournalLineWithVendorPostingGroup(GenJournalLine, WorkDate(), Vendor."No.", BankAccount."No.", VendorPostingGroup2.Code);

        // [GIVEN] Find Check Ledger Entry.
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.FindFirst();

        // [WHEN] Void Check on Check Ledger Entry.
        LibraryVariableStorage.Enqueue(VoidType::"Void check only");
        VoidCheck(CheckLedgerEntry."Document No.");

        // Verify Vendor Posting Group on Vendor Ledger Entry. 
        VerifyPostingGroupOnVendorLedgerEntry(GenJournalLine."Document No.", VendorPostingGroup2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckChangePostingGroupInGeneralJournalToNonAltPostingGroup()
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 590692] Check the change of posting group in general journal to an posting group that is not set as alternative
        Initialize();

        // [GIVEN] Enable Allow Multiple Posting Group on Human Resources Setup
        SetHRAllowMultiplePostingGroups(true);

        // [GIVEN] Create new Employee with Allow Multiple Posting Groups
        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Allow Multiple Posting Groups", true);
        Employee.Modify();

        // [GIVEN] Create new Employee Posting Group
        LibraryHumanResource.CreateEmployeePostingGroup(EmployeePostingGroup);

        // [GIVEN] Create General Journal Line with Employee
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Employee, Employee."No.");

        // [WHEN] Change the Posting Group to created Employee Posting Group
        asserterror GenJournalLine.Validate("Posting Group", EmployeePostingGroup.Code);

        // [THEN] The error occur
        Assert.ExpectedError(StrSubstNo(AltPostingGroupNotFilledInErr, GenJournalLine."Posting Group", EmployeePostingGroup.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckChangePostingGroupInGeneralJournalToAltPostingGroup()
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 590692] Check the change of posting group in general journal to an alternative posting group
        Initialize();

        // [GIVEN] Enable Allow Multiple Posting Group on Human Resources Setup
        SetHRAllowMultiplePostingGroups(true);

        // [GIVEN] Create new Employee with Allow Multiple Posting Groups
        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Allow Multiple Posting Groups", true);
        Employee.Modify();

        // [GIVEN] Create new Employee Posting Group
        LibraryHumanResource.CreateEmployeePostingGroup(EmployeePostingGroup);

        // [GIVEN] Create Alternative Employee Posting Group
        LibraryHumanResource.CreateAltEmployeePostingGroup(Employee."Employee Posting Group", EmployeePostingGroup.Code);

        // [GIVEN] Create General Journal Line with Employee
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Employee, Employee."No.");

        // [WHEN] Change the Posting Group to created Employee Posting Group
        GenJournalLine.Validate("Posting Group", EmployeePostingGroup.Code);

        // [THEN] The posting group will be changed without any error
        Assert.AreEqual(EmployeePostingGroup.Code, GenJournalLine."Posting Group", 'The posting group was not changed as expected.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Multiple Posting Groups");

        LibraryERMCountryData.UpdatePrepaymentAccounts();

        // Lazy Setup.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Multiple Posting Groups");

        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        UpdateSalesPrepmtInvNos();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Human Resources Setup");
        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Multiple Posting Groups");
    end;

    local procedure SetSalesAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        SalesReceivablesSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        SalesReceivablesSetup.Modify();
    end;

    local procedure SetServiceAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        ServiceMgtSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        ServiceMgtSetup.Modify();
    end;

    local procedure SetPurchAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        PurchasesPayablesSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SetHRAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        HumanResourcesSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        HumanResourcesSetup.Modify();
    end;

    local procedure UpdateServiceLineWithRandomQtyAndPrice(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer)
    begin
        UpdateServiceLine(
          ServiceLine, ServiceItemLineNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; Quantity: Decimal; UnitPrice: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure VerifySalesInvoiceCustPostingGroup(DocumentNo: Code[20]; CustomerPostingGroup: Record "Customer Posting Group")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.TestField("Customer Posting Group", CustomerPostingGroup.Code);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Customer Posting Group", CustomerPostingGroup.Code);

        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Receivables Account");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, SalesInvoiceHeader."Amount Including VAT");
    end;

    local procedure VerifySalesPrepaymentInvoiceCustPostingGroup(DocumentNo: Code[20]; CustomerPostingGroup: Record "Customer Posting Group")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.TestField("Customer Posting Group", CustomerPostingGroup.Code);

        CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Customer Posting Group", CustomerPostingGroup.Code);
    end;

    local procedure GetSalesInvoiceHeaderNo(DocumentNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", DocumentNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, DocumentType2, DocumentNo2);
        VendorLedgerEntry2.FindSet();
        repeat
            VendorLedgerEntry2.CalcFields("Remaining Amount");
            VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
            VendorLedgerEntry2.Modify(true);
        until VendorLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure UpdateServiceDocumentNos(DocType: Option Invoice,CreditMemo; var OldValue: Code[20]; ReturnOldValue: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        ServiceMgtSetup.Get();

        if ReturnOldValue then begin
            case
                DocType of
                DocType::Invoice:
                    ServiceMgtSetup."Service Invoice Nos." := OldValue;
                DocType::CreditMemo:
                    ServiceMgtSetup."Service Credit Memo Nos." := OldValue;
            end;
            ServiceMgtSetup.Modify();
            exit;
        end;

        case DocType of
            DocType::Invoice:
                if not NoSeries.Get(ServiceMgtSetup."Service Invoice Nos.") then begin
                    OldValue := ServiceMgtSetup."Service Invoice Nos.";
                    LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
                    ServiceMgtSetup."Service Invoice Nos." := NoSeries.Code;
                    ServiceMgtSetup.Modify();
                end;
            DocType::CreditMemo:
                if not NoSeries.Get(ServiceMgtSetup."Service Credit Memo Nos.") then begin
                    OldValue := ServiceMgtSetup."Service Credit Memo Nos.";
                    LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
                    LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
                    ServiceMgtSetup."Service Credit Memo Nos." := NoSeries.Code;
                    ServiceMgtSetup.Modify();
                end;
        end;
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomeNo: Code[20]; LineGLAccount: Record "G/L Account") PrepmtGLAccountNo: Code[20]
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustomeNo);

        LibrarySales.CreateSalesLine(
          SalesLine,
          SalesHeader,
          SalesLine.Type::Item,
          CreateItemWithPostingSetup(LineGLAccount), LibraryRandom.RandInt(10));
        exit(PrepmtGLAccountNo);
    end;

    local procedure CreateItemWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        GenProdPostingGroupInItem(Item, LineGLAccount);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", 10 * LibraryRandom.RandDec(99, 5)); // Using RANDOM value for Unit Price.
        Item.Modify(true);
    end;

    local procedure GenProdPostingGroupInItem(var Item: Record Item; LineGLAccount: Record "G/L Account")
    begin
        Item.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Item.Modify(true);
    end;

    local procedure UpdateSalesPrepmtInvNos()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Posted Prepmt. Inv. Nos." := LibraryERM.CreateNoSeriesCode();
        SalesSetup.Modify();
    end;

    local procedure CreateGeneralJournalLine(
        var GenJournalLine: Record "Gen. Journal Line";
        AccountType: Enum "Gen. Journal Account Type";
        AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", AccountType, AccountNo, LibraryRandom.RandDec(100, 2));
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; DocNo: Code[20]): Boolean
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Bill);
        GLEntry.SetRange("Document No.", DocNo);
        if GLEntry.FindFirst() then
            exit(true)
        Else
            exit(false);
    end;

    local procedure VerifyPostingGroupOnVendorLedgerEntry(DocumentNo: Code[20]; VendorPostingGroup: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        if VendorLedgerEntry.FindSet() then
            repeat
                Assert.AreEqual(VendorPostingGroup, VendorLedgerEntry."Vendor Posting Group",
                    StrSubstNo(
                        VendorPostingGroupErr,
                        VendorPostingGroup,
                        VendorLedgerEntry.TableCaption()));
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VoidCheck(DocumentNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckManagement: Codeunit CheckManagement;
        ConfirmFinancialVoid: Page "Confirm Financial Void";
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
        ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgerEntry);
    end;

    local procedure PostPaymentJournalLineWithVendorPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; AccountNo: Code[20]; BankAccountNo: Code[20]; VendorPostingGroup: Code[20])
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, "Gen. Journal Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo,
          LibraryRandom.RandIntInRange(1000, 2000));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Posting Group", VendorPostingGroup);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        GeneralLedgerSetup.Get();

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Validate("EMU Currency", true);
        Currency.Validate("Conv. LCY Rndg. Debit Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        exit(Currency.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VoidCheckPageHandler(var ConfirmFinancialVoid: Page "Confirm Financial Void"; var Response: Action)
    var
        VoidTypeVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(VoidTypeVariant);
        ConfirmFinancialVoid.InitializeRequest(WorkDate(), VoidTypeVariant);
        Response := ACTION::Yes
    end;
}