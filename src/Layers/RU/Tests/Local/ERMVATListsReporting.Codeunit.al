codeunit 147124 "ERM VAT Lists Reporting"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        CannotFindVendLedgEntryErr: Label 'Cannot find Vendor Ledger Entry.';
        IncorrectVendLedgEntryErr: Label '%1 value in Vendor Ledger Entry is incorrect.', Comment = '%1=Entry No.';
        ReportLineExistsErr: Label 'Report has printed line but it should not.';

    local procedure Initialize()
    var
        GLSetup: Record "General Ledger Setup";
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        GLSetup.Get();
        if not GLSetup."Mark Cr. Memos as Corrections" then
            GLSetup."Mark Cr. Memos as Corrections" := true;
        if not GLSetup."Enable Russian Accounting" then
            GLSetup."Enable Russian Accounting" := true;
        GLSetup.Modify();

        InventorySetup.Get();
        if InventorySetup."Prevent Negative Inventory" then begin
            InventorySetup."Prevent Negative Inventory" := false;
            InventorySetup.Modify();
        end;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();

        IsInitialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalReceivedIssuedFactures1()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Period: Record Date;
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        SalesInvoiceNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        OrderDate: Date;
        ShipmentDate: Date;
    begin
        // Create new Customer
        // Create and Post Sales Invoice (01.01.10, 80001, 1500.00)
        Initialize();

        Period."Period Start" := CalcDate('<-CM>', WorkDate());
        Period."Period End" := CalcDate('<+CM>', WorkDate());
        OrderDate := Period."Period Start";
        ShipmentDate := OrderDate + 3;

        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup);
        Customer.Get(CustomerNo);

        ItemNo := CreateItem(VATPostingSetup, Customer."Gen. Bus. Posting Group");

        SalesInvoiceNo := GetSalesPostedInvoiceNo(PostSalesInvoice(CustomerNo, ItemNo, 4, 1500, OrderDate, ShipmentDate, ''));

        GatherReportRecords(VendorLedgerEntry, '', CustomerNo, 1, Period, true);
        VendorLedgerEntry.Init();

        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::Invoice, SalesInvoiceNo,
          7500, ShipmentDate, OrderDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalReceivedIssuedFactures2()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Period: Record Date;
        Customer: Record Customer;
        SalesInvoiceNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        OrderDate: Date;
        ShipmentDate: Date;
    begin
        // Create new Customer
        // Create and Post Sales Invoice (01.01.10, 80001, 1500.00)
        // Create and Post Credit Memo(02.01.10) applied to Invoice Above - full reverse.
        Initialize();

        Period."Period Start" := CalcDate('<-CM>', WorkDate());
        Period."Period End" := CalcDate('<+CM>', WorkDate());
        OrderDate := Period."Period Start";
        ShipmentDate := OrderDate + 3;

        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup);
        Customer.Get(CustomerNo);

        ItemNo := CreateItem(VATPostingSetup, Customer."Gen. Bus. Posting Group");

        SalesInvoiceNo := GetSalesPostedInvoiceNo(PostSalesInvoice(CustomerNo, ItemNo, 4, 1500, OrderDate, ShipmentDate, ''));

        PostSalesCrMemo(SalesInvoiceNo, CustomerNo, OrderDate + 3, 0, false);

        GatherReportRecords(VendorLedgerEntry, '', CustomerNo, 1, Period, true);

        Assert.IsTrue(VendorLedgerEntry.IsEmpty, ReportLineExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalReceivedIssuedFactures3()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Period: Record Date;
        Customer: Record Customer;
        OrderDate: Date;
        ShipmentDate: Date;
        CrMemoDate: Date;
        CustomerNo: Code[20];
        SalesInvoiceNo: Code[20];
        ItemNo: Code[20];
    begin
        // Create new Customer
        // Create and Post Sales Invoice (01.01.10, 80001, 1500.00)
        // Create and Post Credit Memo(02.01.10) applied to Invoice Above - partial reverse.
        Initialize();

        Period."Period Start" := CalcDate('<-CM>', WorkDate());
        Period."Period End" := CalcDate('<+CM>', WorkDate());
        OrderDate := Period."Period Start";
        ShipmentDate := OrderDate + 3;
        CrMemoDate := OrderDate + 2;

        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup);
        Customer.Get(CustomerNo);

        ItemNo := CreateItem(VATPostingSetup, Customer."Gen. Bus. Posting Group");

        SalesInvoiceNo := GetSalesPostedInvoiceNo(PostSalesInvoice(CustomerNo, ItemNo, 4, 1500, OrderDate, ShipmentDate, ''));

        PostSalesCrMemo(SalesInvoiceNo, CustomerNo, CrMemoDate, 1, false);

        GatherReportRecords(VendorLedgerEntry, '', CustomerNo, 1, Period, true);

        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::Invoice, SalesInvoiceNo,
          5625, ShipmentDate, OrderDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalReceivedIssuedFactures4()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Period: Record Date;
        SalesCreditMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        OrderDate: Date;
        ShipmentDate: Date;
        CrMemoDate: Date;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        CrMemoNo: Code[20];
        SalesInvoiceNo: Code[20];
    begin
        // Create new Customer
        // Create and Post Sales Invoice (01.01.10, 80001, 1500.00)
        // Create and Post Credit Memo(02.01.10, Include in Purch. VAT Ledger = True) applied to Invoice Above - full reverse.
        Initialize();

        Period."Period Start" := CalcDate('<-CM>', WorkDate());
        Period."Period End" := CalcDate('<+CM>', WorkDate());
        OrderDate := Period."Period Start";
        ShipmentDate := OrderDate + 3;
        CrMemoDate := OrderDate + 2;

        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup);
        Customer.Get(CustomerNo);

        ItemNo := CreateItem(VATPostingSetup, Customer."Gen. Bus. Posting Group");

        SalesInvoiceNo := GetSalesPostedInvoiceNo(PostSalesInvoice(CustomerNo, ItemNo, 4, 1500, OrderDate, ShipmentDate, ''));

        CrMemoNo := PostSalesCrMemo(SalesInvoiceNo, CustomerNo, CrMemoDate, 0, true);

        SalesCreditMemoHeader.SetRange("Pre-Assigned No.", CrMemoNo);
        SalesCreditMemoHeader.FindFirst();

        GatherReportRecords(VendorLedgerEntry, '-', CustomerNo, 0, Period, true);

        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::"Credit Memo", SalesCreditMemoHeader."No.",
          7500, CrMemoDate, CrMemoDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalReceivedIssuedFactures5()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Period: Record Date;
        SalesCreditMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        OrderDate: Date;
        ShipmentDate: Date;
        CrMemoDate: Date;
        CustomerNo: Code[20];
        CrMemoNo: Code[20];
        SalesInvoiceNo: Code[20];
        ItemNo: Code[20];
    begin
        // Create new Customer
        // Create and Post Sales Invoice (01.01.10, 80001, 1500.00)
        // Create and Post Credit Memo(02.01.10 Include in Purch. VAT Ledger=True ) applied to Invoice Above - partial reverse.
        Initialize();

        Period."Period Start" := CalcDate('<-CM>', WorkDate());
        Period."Period End" := CalcDate('<+CM>', WorkDate());
        OrderDate := Period."Period Start";
        ShipmentDate := OrderDate + 3;
        CrMemoDate := OrderDate + 2;

        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup);
        Customer.Get(CustomerNo);

        ItemNo := CreateItem(VATPostingSetup, Customer."Gen. Bus. Posting Group");

        SalesInvoiceNo := GetSalesPostedInvoiceNo(PostSalesInvoice(CustomerNo, ItemNo, 4, 1500, OrderDate, ShipmentDate, ''));
        CrMemoNo := PostSalesCrMemo(SalesInvoiceNo, CustomerNo, CrMemoDate, 3, true);

        SalesCreditMemoHeader.SetRange("Pre-Assigned No.", CrMemoNo);
        SalesCreditMemoHeader.FindFirst();

        GatherReportRecords(VendorLedgerEntry, '', CustomerNo, 0, Period, true);

        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::"Credit Memo", SalesCreditMemoHeader."No.",
          5625, CrMemoDate, CrMemoDate);

        VendorLedgerEntry.Reset();
        VendorLedgerEntry.DeleteAll();

        GatherReportRecords(VendorLedgerEntry, '', CustomerNo, 1, Period, true);

        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);

        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::Invoice, SalesInvoiceNo,
          7500, ShipmentDate, OrderDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalReceivedIssuedFactures6()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Period: Record Date;
        SalesCreditMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        OrderDate1: Date;
        ShipmentDate1: Date;
        OrderDate2: Date;
        ShipmentDate2: Date;
        CrMemoDate: Date;
        CustomerNo: Code[20];
        CrMemoNo: Code[20];
        ItemNo: Code[20];
        SalesInvoiceNo1: Code[20];
        SalesInvoiceNo2: Code[20];
    begin
        // Create new Customer
        // Create and Post Sales Invoice (01.01.10, 80001, 1500.00)
        // Create and Post Credit Memo(02.01.10 Include in Purch. VAT Ledger=True ) applied to Invoice Above - partial reverse.
        Initialize();

        Period."Period Start" := CalcDate('<-CM>', WorkDate());
        Period."Period End" := CalcDate('<+CM>', WorkDate());
        OrderDate1 := Period."Period Start";
        ShipmentDate1 := OrderDate1 + 3;
        OrderDate2 := OrderDate1 + 4;
        ShipmentDate2 := OrderDate1 + 7;
        CrMemoDate := OrderDate1 + 10;

        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup);
        Customer.Get(CustomerNo);

        ItemNo := CreateItem(VATPostingSetup, Customer."Gen. Bus. Posting Group");

        SalesInvoiceNo1 := GetSalesPostedInvoiceNo(PostSalesInvoice(CustomerNo, ItemNo, 4, 1500, OrderDate1, ShipmentDate1, ''));
        SalesInvoiceNo2 := GetSalesPostedInvoiceNo(PostSalesInvoice(CustomerNo, ItemNo, 4, 1500, OrderDate2, ShipmentDate2, ''));

        CrMemoNo := PostSalesCrMemo(SalesInvoiceNo1, CustomerNo, CrMemoDate, 5, true);

        SalesCreditMemoHeader.SetRange("Pre-Assigned No.", CrMemoNo);
        SalesCreditMemoHeader.FindFirst();

        ApplyCustomerCreditMemoToInvoice(SalesCreditMemoHeader."No.", SalesInvoiceNo2);

        GatherReportRecords(VendorLedgerEntry, '', CustomerNo, 0, Period, true);

        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::"Credit Memo", SalesCreditMemoHeader."No.",
          9375, CrMemoDate, CrMemoDate);

        GatherReportRecords(VendorLedgerEntry, '', CustomerNo, 1, Period, true);
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::Invoice, SalesInvoiceNo1,
          7500, ShipmentDate1, OrderDate1);

        VendorLedgerEntry.SetRange("Document No.", SalesInvoiceNo2);
        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::Invoice, SalesInvoiceNo2,
          7500, ShipmentDate2, OrderDate2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalReceivedIssuedFactures7()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Period: Record Date;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        SalesRelease: Codeunit "Release Sales Document";
        LibraryERM: Codeunit "Library - ERM";
        OrderDate: Date;
        ShipmentDate: Date;
        PrepaymentDate: Date;
        SalesInvoiceNo1: Code[20];
        SalesInvoiceNo2: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        CurrencyCode: Code[10];
        DocNo: Code[20];
    begin
        // Create new Customer
        // Create and Post Sales Invoice (01.01.10, 80001, 1500.00), Currency = EUR(1:35,9332)
        // Create and post Prepayment, Apply to Posted Invoice
        // clear VAT reinstatement journal
        Initialize();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Create Prepayment Invoice" := true;
        SalesReceivablesSetup.Validate("Posted Prepayment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted PD Doc. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify();

        Period."Period Start" := CalcDate('<-CM>', WorkDate());
        Period."Period End" := CalcDate('<+CM>', WorkDate());
        OrderDate := Period."Period Start" + 10;
        ShipmentDate := OrderDate + 3;
        PrepaymentDate := Period."Period Start";

        CreateVATPostingSetup(VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup);
        Customer.Get(CustomerNo);

        ItemNo := CreateItem(VATPostingSetup, Customer."Gen. Bus. Posting Group");

        CurrencyCode := CreateCurrWithExch(PrepaymentDate, 10);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        CreateSalesInvoice(SalesHeader, SalesLine, CustomerNo, ItemNo, 4, 100, OrderDate, ShipmentDate, CurrencyCode);
        SalesInvoiceNo1 := SalesHeader."No.";
        SalesRelease.PerformManualRelease(SalesHeader);

        LibraryERM.CreateCustomerPrepmtGenJnlLineFCY(GenJournalLine, CustomerNo, PrepaymentDate, SalesHeader."No.", -250, CurrencyCode);
        GenJournalLine."VAT %" := VATPostingSetup."VAT %";
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ApplyCustomerPaymentToInvoice(GenJournalLine."Document No.", DocNo);

        SalesInvoiceHeader.SetRange("Order No.", SalesInvoiceNo1);
        SalesInvoiceHeader.SetRange("Posting Date", PrepaymentDate);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceNo2 := SalesInvoiceHeader."No.";

        SalesInvoiceNo1 := GetSalesPostedInvoiceNo(SalesInvoiceNo1);

        GatherReportRecords(VendorLedgerEntry, '', CustomerNo, 1, Period, true);

        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::Invoice, SalesInvoiceNo2,
          2500, 0D, PrepaymentDate);

        VendorLedgerEntry.SetRange("Document No.", SalesInvoiceNo1);
        ValidateVendorLedgerEntry(
          VendorLedgerEntry, CustomerNo,
          VendorLedgerEntry."Document Type"::Invoice, SalesInvoiceNo1,
          5000, ShipmentDate, OrderDate);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateUnrealizedVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("VAT %", 25);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Integer; UnitPrice: Decimal; OrderDate: Date; ShipmentDate: Date; CurrencyCode: Code[10])
    var
        Item: Record Item;
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Order Date", OrderDate);
        SalesHeader.Validate("Posting Date", OrderDate);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Validate("Document Date", OrderDate);
        if CurrencyCode <> '' then
            SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        Item.Get(ItemNo);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();
        SalesLine.SetHideValidationDialog(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Location Code", InventoryPostingSetup."Location Code");
        SalesLine.Modify(true);
    end;

    local procedure PostSalesInvoice(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Integer; UnitPrice: Decimal; OrderDate: Date; ShipmentDate: Date; CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesInvoice(
          SalesHeader,
          SalesLine,
          CustomerNo,
          ItemNo,
          Quantity,
          UnitPrice,
          OrderDate,
          ShipmentDate,
          CurrencyCode);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        exit(SalesHeader."No.");
    end;

    local procedure GetSalesPostedInvoiceNo(SalesInvoiceNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesInvoiceNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure PostSalesCrMemo(SalesInvoiceNo: Code[20]; CustomerNo: Code[20]; PostingDate: Date; Qty: Integer; IncludeInPurchVATLedger: Boolean): Code[20]
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        temp1: Integer;
        temp2: Boolean;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", PostingDate);
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", SalesInvoiceNo);
        SalesHeader.Validate("Include In Purch. VAT Ledger", IncludeInPurchVATLedger);
        SalesHeader.Modify(true);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceNo);
        SalesInvoiceLine.FindFirst();
        temp1 := 0;
        temp2 := false;
        CopyDocMgt.CopySalesInvLinesToDoc(SalesHeader, SalesInvoiceLine, temp1, temp2);

        if Qty > 0 then begin
            SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange("Sell-to Customer No.", CustomerNo);
            SalesLine.FindFirst();
            SalesLine.Validate(Quantity, Qty);
            SalesLine.Modify(true);
        end;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        exit(SalesHeader."No.");
    end;

    local procedure CreateItem(VATPostingSetup: Record "VAT Posting Setup"; GenBusPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryLib: Codeunit "Library - Inventory";
    begin
        InventoryLib.CreateItem(Item);

        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        GeneralPostingSetup.FindFirst();

        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        Item.Modify();

        exit(Item."No.");
    end;

    local procedure CreateCustomer(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate(
          "Prepayment Account", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale));
        CustomerPostingGroup.Modify(true);

        exit(Customer."No.");
    end;

    local procedure CreateCurrExchRate(Date: Date; CurrencyCode: Code[10]; MultiplicationFactor: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, Date);
        // Validate any random Exchange Rate Amount greater than 10.
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDecInRange(10, 1000, 2));
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount",
          CurrencyExchangeRate."Exchange Rate Amount" * MultiplicationFactor);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCurrWithExch(ExchDate: Date; MultiplicationFactor: Decimal): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateCurrency(Currency);
        CreateCurrExchRate(ExchDate, Currency.Code, MultiplicationFactor);
        exit(Currency.Code);
    end;

    local procedure GatherReportRecords(var VendLedgEntry: Record "Vendor Ledger Entry"; VendNoFilter: Text; CustNoFilter: Text; ReportType: Option; DatePeriod: Record Date; ShowCorrection: Boolean)
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        VATInvJnlMgt: Codeunit "VAT Invoice Journal Management";
    begin
        if VendNoFilter <> '' then
            Vendor.SetFilter("No.", VendNoFilter);
        if CustNoFilter <> '' then
            Customer.SetFilter("No.", CustNoFilter);
        VATInvJnlMgt.GetVendVATList(VendLedgEntry, Vendor, ReportType, DatePeriod, ShowCorrection);
        VATInvJnlMgt.GetCustVATList(VendLedgEntry, Customer, ReportType, DatePeriod, ShowCorrection);
    end;

    local procedure ApplyCustomerCreditMemoToInvoice(CreditMemoDocNo: Code[20]; InvoiceDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgEntry."Document Type"::"Credit Memo", CreditMemoDocNo,
          CustLedgEntry."Document Type"::Invoice, InvoiceDocNo);
    end;

    local procedure ApplyCustomerPaymentToInvoice(PaymentDocNo: Code[20]; InvoiceDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgEntry."Document Type"::Payment, PaymentDocNo,
          CustLedgEntry."Document Type"::Invoice, InvoiceDocNo);
    end;

    local procedure ValidateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; VendVATInvDate: Date; VendVATInvRcvdDate: Date)
    begin
        Assert.IsTrue(
          VendorLedgerEntry.FindFirst(),
          CannotFindVendLedgEntryErr);
        Assert.IsTrue(
          VendorLedgerEntry."Vendor No." = VendorNo,
          StrSubstNo(IncorrectVendLedgEntryErr, VendorLedgerEntry.FieldCaption("Vendor No.")));
        Assert.IsTrue(
          VendorLedgerEntry."Document Type" = DocumentType,
          StrSubstNo(IncorrectVendLedgEntryErr, VendorLedgerEntry.FieldCaption("Document Type")));
        Assert.IsTrue(
          VendorLedgerEntry."Document No." = DocumentNo,
          StrSubstNo(IncorrectVendLedgEntryErr, VendorLedgerEntry.FieldCaption("Document No.")));
        Assert.IsTrue(
          VendorLedgerEntry."Purchase (LCY)" = Amount,
          StrSubstNo(IncorrectVendLedgEntryErr, VendorLedgerEntry.FieldCaption("Purchase (LCY)")));
        Assert.IsTrue(
          VendorLedgerEntry."Vendor VAT Invoice Date" = VendVATInvDate,
          StrSubstNo(IncorrectVendLedgEntryErr, VendorLedgerEntry.FieldCaption("Vendor VAT Invoice Date")));
        Assert.IsTrue(
          VendorLedgerEntry."Vendor VAT Invoice Rcvd Date" = VendVATInvRcvdDate,
          StrSubstNo(IncorrectVendLedgEntryErr, VendorLedgerEntry.FieldCaption("Vendor VAT Invoice Rcvd Date")));
    end;
}

