codeunit 142058 "UT PAG Sales Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [UI]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;

#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsServiceOrders()
    var
        ServiceLine: Record "Service Line";
        TaxDetail: Record "Tax Detail";
        ServiceOrders: TestPage "Service Orders";
        TaxAmount: Decimal;
        TaxArea: Code[20];
    begin
        // [FEATURE] [Service] [Statistics]
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9318 Service Orders.

        // Setup: Create Service Order with Tax Area Code.
        Initialize();
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order, TaxArea, TaxDetail."Tax Group Code");
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceOrderStatsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Order and verified Tax Amount on ServiceOrderStatsPageHandler.
        ServiceOrders.OpenEdit();
        ServiceOrders.FILTER.SetFilter("No.", ServiceLine."Document No.");
        ServiceOrders.Statistics.Invoke();  // Opens ServiceOrderStatsPageHandlerr.
        ServiceOrders.Close();
    end;

    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsServiceQuotes()
    var
        ServiceLine: Record "Service Line";
        TaxDetail: Record "Tax Detail";
        ServiceQuotes: TestPage "Service Quotes";
        TaxAmount: Decimal;
        TaxArea: Code[20];
    begin
        // [FEATURE] [Service] [Statistics]
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9317 Service Quotes.

        // Setup: Create Service Quote with Tax Area Code.
        Initialize();
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Quote, TaxArea, TaxDetail."Tax Group Code");
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceStatsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Quotes and verified Tax Amount on ServiceStatsPageHandler.
        ServiceQuotes.OpenEdit();
        ServiceQuotes.FILTER.SetFilter("No.", ServiceLine."Document No.");
        ServiceQuotes.Statistics.Invoke();  // Opens ServiceStatsPageHandler.
        ServiceQuotes.Close();
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsServiceInvoices()
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        TaxDetail: Record "Tax Detail";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        TaxAmount: Decimal;
        TaxArea: Code[20];
    begin
        // [FEATURE] [Service] [Statistics]
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9319 Service Invoices.

        // Setup: Create Service Invoice with Tax Area Code.
        Initialize();
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreatePostedServiceInvoice(ServiceInvoiceLine, TaxArea, TaxDetail."Tax Group Code");
        TaxAmount := ServiceInvoiceLine."Unit Price" * ServiceInvoiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceInvoiceStatsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Invoices and verified Tax Amount on ServiceInvoiceStatsPageHandler.
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceLine."Document No.");
        PostedServiceInvoice.Statistics.Invoke();  // Opens ServiceInvoiceStatsPageHandler.
        PostedServiceInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoStatsPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsServiceCreditMemo()
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        TaxDetail: Record "Tax Detail";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        TaxAmount: Decimal;
        TaxArea: Code[20];
    begin
        // [FEATURE] [Service] [Statistics]
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9320 Service Credit Memos.

        // Setup: Create Service Credit Memo with Tax Area Code.
        Initialize();
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreatePostedServiceCreditMemo(ServiceCrMemoLine, TaxArea, TaxDetail."Tax Group Code");
        TaxAmount := ServiceCrMemoLine."Unit Price" * ServiceCrMemoLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceCreditMemoStatsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Credit Memos and verified Tax Amount on ServiceCreditMemoStatsPageHandler.
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", ServiceCrMemoLine."Document No.");
        PostedServiceCreditMemo.Statistics.Invoke();  // Opens ServiceCreditMemoStatsPageHandler.
        PostedServiceCreditMemo.Close();
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsServiceOrdersNM()
    var
        ServiceLine: Record "Service Line";
        TaxDetail: Record "Tax Detail";
        ServiceOrders: TestPage "Service Orders";
        TaxAmount: Decimal;
        TaxArea: Code[20];
    begin
        // [FEATURE] [Service] [Statistics]
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9318 Service Orders.

        // Setup: Create Service Order with Tax Area Code.
        Initialize();
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order, TaxArea, TaxDetail."Tax Group Code");
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceOrderStatsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Order and verified Tax Amount on ServiceOrderStatsPageHandler.
        ServiceOrders.OpenEdit();
        ServiceOrders.FILTER.SetFilter("No.", ServiceLine."Document No.");
        ServiceOrders.ServiceOrderStats.Invoke();  // Opens ServiceOrderStatsPageHandlerr.
        ServiceOrders.Close();
    end;

    [Test]
    [HandlerFunctions('ServiceStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsServiceQuotesNM()
    var
        ServiceLine: Record "Service Line";
        TaxDetail: Record "Tax Detail";
        ServiceQuotes: TestPage "Service Quotes";
        TaxAmount: Decimal;
        TaxArea: Code[20];
    begin
        // [FEATURE] [Service] [Statistics]
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9317 Service Quotes.

        // Setup: Create Service Quote with Tax Area Code.
        Initialize();
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Quote, TaxArea, TaxDetail."Tax Group Code");
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceStatsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Quotes and verified Tax Amount on ServiceStatsPageHandler.
        ServiceQuotes.OpenEdit();
        ServiceQuotes.FILTER.SetFilter("No.", ServiceLine."Document No.");
        ServiceQuotes.ServiceStats.Invoke();  // Opens ServiceStatsPageHandler.
        ServiceQuotes.Close();
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsServiceInvoicesNM()
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        TaxDetail: Record "Tax Detail";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        TaxAmount: Decimal;
        TaxArea: Code[20];
    begin
        // [FEATURE] [Service] [Statistics]
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9319 Service Invoices.

        // Setup: Create Service Invoice with Tax Area Code.
        Initialize();
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreatePostedServiceInvoice(ServiceInvoiceLine, TaxArea, TaxDetail."Tax Group Code");
        TaxAmount := ServiceInvoiceLine."Unit Price" * ServiceInvoiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceInvoiceStatsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Invoices and verified Tax Amount on ServiceInvoiceStatsPageHandler.
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceLine."Document No.");
        PostedServiceInvoice.ServiceStats.Invoke();  // Opens ServiceInvoiceStatsPageHandler.
        PostedServiceInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsServiceCreditMemoNM()
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        TaxDetail: Record "Tax Detail";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        TaxAmount: Decimal;
        TaxArea: Code[20];
    begin
        // [FEATURE] [Service] [Statistics]
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9320 Service Credit Memos.

        // Setup: Create Service Credit Memo with Tax Area Code.
        Initialize();
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreatePostedServiceCreditMemo(ServiceCrMemoLine, TaxArea, TaxDetail."Tax Group Code");
        TaxAmount := ServiceCrMemoLine."Unit Price" * ServiceCrMemoLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceCreditMemoStatsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Credit Memos and verified Tax Amount on ServiceCreditMemoStatsPageHandler.
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", ServiceCrMemoLine."Document No.");
        PostedServiceCreditMemo.ServiceStats.Invoke();  // Opens ServiceCreditMemoStatsPageHandler.
        PostedServiceCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure OnRunSetSalesApplyCustomerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LibrarySales: Codeunit "Library - Sales";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Apply]
        // Purpose of the test is to  ApplyEntries on SetSales function of Page ID - 232 Apply Customer Entries.

        // Setup: Create Sales Credit Memo with Tax Area Code.
        Initialize();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        CreateCustomerLedgerEntry(CustLedgerEntry);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Document No.");  // ApplyCustomerEntriesPageHandler
        CreateDetailedCustomerLedgerEntries(CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.");
        DocumentNo := CreateSalesCreditMemo(CustLedgerEntry."Customer No.");

        // Exercise and verify: Invokes Action - ApplyEntries on Page Sales Credit Memo and verified Apply Entries on ApplyCustomerEntriesPageHandler.
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", DocumentNo);
        SalesCreditMemo.ApplyEntries.Invoke();  // ApplyCustomerEntriesPageHandler
        SalesCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure OnRunSetPurchApplyVendorEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LibraryPurchase: Codeunit "Library - Purchase";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Apply]
        // Purpose of the test is to  ApplyEntries on SetPurch function of Page ID - 233 Apply Vendor Entries.

        // Setup: Create Purchase Credit Memo with Tax Area Code.
        Initialize();
        LibraryPurchase.DisableWarningOnCloseUnpostedDoc();
        CreateVendorLedgerEntry(VendorLedgerEntry);
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Document No.");  // ApplyVendorEntriesPageHandler
        CreateDetailedVendorLedgerEntries(VendorLedgerEntry."Entry No.", VendorLedgerEntry."Vendor No.");
        DocumentNo := CreatePurchaseCreditMemo(VendorLedgerEntry."Vendor No.");

        // Exercise and verify: Invokes Action - ApplyEntries on Page Purchase Credit Memo and verified Apply Entries on ApplyVendorEntriesPageHandler.
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", DocumentNo);
        PurchaseCreditMemo.ApplyEntries.Invoke();  // ApplyVendorEntriesPageHandler
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLinesTaxLiableAreaCodeEditableVisible()
    var
        TaxDetail: Record "Tax Detail";
        ServiceLine: Record "Service Line";
        ServiceLines: TestPage "Service Lines";
        TaxArea: Code[20];
    begin
        // [SCENARIO 422332] Tax Liable and Tax Area Code should be visible and editable on Service Lines page
        Initialize();

        // [GIVEN] Service Document with Service Lines
        TaxArea := CreateTaxAreaWithTaxDetail(TaxDetail);
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order, TaxArea, TaxDetail."Tax Group Code");

        // [WHEN] Service Lines page is opened
        ServiceLines.OpenEdit();
        ServiceLines.FILTER.SetFilter("Document No.", ServiceLine."Document No.");

        // [THEN] "Tax Liable" and "Tax Area Code" fields are visible and editable
        Assert.IsTrue(ServiceLines."Tax Liable".Visible(), 'Tax Liable should be visible');
        Assert.IsTrue(ServiceLines."Tax Liable".Editable(), 'Tax Liable should be editable');
        Assert.IsTrue(ServiceLines."Tax Area Code".Visible(), 'Tax Area Code should be visible');
        Assert.IsTrue(ServiceLines."Tax Area Code".Editable(), 'Tax Area Code should be editable');
        ServiceLines.Close();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        CustomerPostingGroup.Insert();
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Customer Posting Group" := CustomerPostingGroup.Code;
        Customer.Insert();
        exit(Customer."No.")
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry.Open := true;
        CustLedgerEntry."Customer No." := CreateCustomer();
        CustLedgerEntry.Insert();
    end;

    local procedure CreateDetailedCustomerLedgerEntries(CustomerLedgerEntryNo: Integer; CustomerNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry2.FindLast();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustomerLedgerEntryNo;
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(DetailedCustLedgEntry.Amount);  // ApplyCustomerEntriesPageHandler
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateDetailedVendorLedgerEntries(VendorLedgerEntryNo: Integer; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(DetailedVendorLedgEntry.Amount);  // ApplyVendorEntriesPageHandler
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreatePurchaseCreditMemo(BuyfromVendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := BuyfromVendorNo;
        PurchaseHeader."Pay-to Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        PurchaseHeader."Tax Area Code" := CreateTaxAreaWithTaxDetail(TaxDetail);
        PurchaseHeader."Tax Liable" := true;
        PurchaseHeader.Insert();

        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine.Quantity := LibraryRandom.RandInt(10);
        PurchaseLine."Tax Area Code" := PurchaseHeader."Tax Area Code";
        PurchaseLine."Tax Group Code" := TaxDetail."Tax Group Code";
        PurchaseLine."Tax Liable" := true;
        PurchaseLine.Insert();
        exit(PurchaseLine."Document No.");
    end;

    local procedure CreatePostedServiceInvoice(var ServiceInvoiceLine: Record "Service Invoice Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceInvoiceHeader."Customer No." := CreateCustomer();
        ServiceInvoiceHeader."Bill-to Customer No." := ServiceInvoiceHeader."Customer No.";
        ServiceInvoiceHeader."Tax Area Code" := TaxAreaCode;
        ServiceInvoiceHeader.Insert();

        ServiceInvoiceLine."Document No." := ServiceInvoiceHeader."No.";
        ServiceInvoiceLine.Type := ServiceInvoiceLine.Type::Item;
        ServiceInvoiceLine.Quantity := LibraryRandom.RandInt(10);
        ServiceInvoiceLine."Tax Area Code" := TaxAreaCode;
        ServiceInvoiceLine."Tax Group Code" := TaxGroupCode;
        ServiceInvoiceLine."Tax Liable" := true;
        ServiceInvoiceLine.Insert();
    end;

    local procedure CreatePostedServiceCreditMemo(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceCrMemoHeader."Customer No." := CreateCustomer();
        ServiceCrMemoHeader."Bill-to Customer No." := ServiceCrMemoHeader."Customer No.";
        ServiceCrMemoHeader."Tax Area Code" := TaxAreaCode;
        ServiceCrMemoHeader.Insert();

        ServiceCrMemoLine."Document No." := ServiceCrMemoHeader."No.";
        ServiceCrMemoLine.Type := ServiceCrMemoLine.Type::Item;
        ServiceCrMemoLine.Quantity := LibraryRandom.RandInt(10);
        ServiceCrMemoLine."Tax Area Code" := TaxAreaCode;
        ServiceCrMemoLine."Tax Group Code" := TaxGroupCode;
        ServiceCrMemoLine."Tax Liable" := true;
        ServiceCrMemoLine.Insert();
    end;

    local procedure CreateSalesCreditMemo(SellToCustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := SellToCustomerNo;
        SalesHeader."Bill-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesHeader."Tax Area Code" := CreateTaxAreaWithTaxDetail(TaxDetail);
        SalesHeader."Tax Liable" := true;
        SalesHeader.Insert();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Quantity := LibraryRandom.RandInt(10);
        SalesLine."Tax Area Code" := SalesHeader."Tax Area Code";
        SalesLine."Tax Group Code" := TaxDetail."Tax Group Code";
        SalesLine."Tax Liable" := true;
        SalesLine.Insert();
        exit(SalesLine."Document No.");
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Customer No." := CreateCustomer();
        ServiceHeader."Bill-to Customer No." := ServiceHeader."Customer No.";
        ServiceHeader."Tax Area Code" := TaxAreaCode;
        ServiceHeader.Insert();

        ServiceLine."Document Type" := ServiceLine."Document Type"::Order;
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine.Quantity := LibraryRandom.RandInt(10);
        ServiceLine."Tax Area Code" := TaxAreaCode;
        ServiceLine."Tax Group Code" := TaxGroupCode;
        ServiceLine."Tax Liable" := true;
        ServiceLine.Insert();
    end;

    local procedure CreateTaxArea(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea.Insert();
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaWithTaxDetail(var TaxDetail: Record "Tax Detail"): Code[20]
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxDetail."Tax Jurisdiction Code" := CreateTaxJurisdiction();
        TaxDetail."Tax Group Code" := CreateTaxGroup();
        TaxDetail."Tax Below Maximum" := LibraryRandom.RandInt(10);
        TaxDetail.Insert();

        TaxAreaLine."Tax Area" := CreateTaxArea();
        TaxAreaLine."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";
        TaxAreaLine.Insert();
        exit(TaxAreaLine."Tax Area");
    end;

    local procedure CreateTaxGroup(): Code[10]
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.Code := LibraryUTUtility.GetNewCode10();
        TaxGroup.Insert();
        exit(TaxGroup.Code);
    end;

    local procedure CreateTaxJurisdiction(): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Code := LibraryUTUtility.GetNewCode10();
        TaxJurisdiction."Report-to Jurisdiction" := TaxJurisdiction.Code;
        TaxJurisdiction.Insert();
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VendorPostingGroup.Insert();
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        Vendor.Insert();
        exit(Vendor."No.")
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Vendor No." := CreateVendor();
        VendorLedgerEntry.Insert();
    end;

#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsPageHandler(var ServiceOrderStats: TestPage "Service Order Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceOrderStats."VATAmount[2]".AssertEquals(TaxAmount);
        ServiceOrderStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatsPageHandler(var ServiceStats: TestPage "Service Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceStats.VATAmount.AssertEquals(TaxAmount);
        ServiceStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceStatsPageHandler(var ServiceInvoiceStats: TestPage "Service Invoice Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceInvoiceStats.TaxAmount.AssertEquals(TaxAmount);
        ServiceInvoiceStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoStatsPageHandler(var ServiceCreditMemoStats: TestPage "Service Credit Memo Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceCreditMemoStats.TaxAmount.AssertEquals(TaxAmount);
        ServiceCreditMemoStats.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsPageHandlerNM(var ServiceOrderStats: TestPage "Service Order Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceOrderStats."VATAmount[2]".AssertEquals(TaxAmount);
        ServiceOrderStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatsPageHandlerNM(var ServiceStats: TestPage "Service Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceStats.VATAmount.AssertEquals(TaxAmount);
        ServiceStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceStatsPageHandlerNM(var ServiceInvoiceStats: TestPage "Service Invoice Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceInvoiceStats.TaxAmount.AssertEquals(TaxAmount);
        ServiceInvoiceStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoStatsPageHandlerNM(var ServiceCreditMemoStats: TestPage "Service Credit Memo Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceCreditMemoStats.TaxAmount.AssertEquals(TaxAmount);
        ServiceCreditMemoStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliesToID: Variant;
        RemainingAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AppliesToID);
        LibraryVariableStorage.Dequeue(RemainingAmount);
        ApplyCustomerEntries.AppliesToID.SetValue(AppliesToID);
        ApplyCustomerEntries."Remaining Amount".AssertEquals(RemainingAmount);
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        AppliesToID: Variant;
        RemainingAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AppliesToID);
        LibraryVariableStorage.Dequeue(RemainingAmount);
        ApplyVendorEntries.AppliesToID.SetValue(AppliesToID);
        ApplyVendorEntries."Remaining Amount".AssertEquals(RemainingAmount);
        ApplyVendorEntries.OK().Invoke();
    end;
}
