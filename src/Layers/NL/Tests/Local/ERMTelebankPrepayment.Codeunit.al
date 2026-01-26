codeunit 144056 "ERM Telebank Prepayment"
{
    // 
    //  1. Test to verify that Transaction Mode Code is updated on Sales Invoice Header after posting Sales Prepayment Invoice.
    //  2. Test to verify that Transaction Mode Code is updated on Purchase Invoice Header after posting Purchase Prepayment Invoice.
    // 
    //  Covers Test Cases for WI - 343903
    //  --------------------------------------------------------------------------------------
    //  Test Function Name                                                             TFS ID
    //  --------------------------------------------------------------------------------------
    //  TransactionModeOnSalesPrepaymentInvoice
    //  TransactionModeOnPurchasePrepaymentInvoice

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TransactionModeOnPurchasePrepaymentInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Setup: Create Vendor, create Purchase Order.
        Initialize();
        CreateVendor(Vendor);
        CreatePurchaseDocument(PurchaseHeader, Vendor."No.");
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Posting No. Series");

        // Exercise.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Verify: Verify the Transaction Mode Code is updated on Purchase Invoice Header after posting Prepayment Invoice.
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Transaction Mode", Vendor."Transaction Mode Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransactionModeOnSalesPrepaymentInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // Setup: Create Customer, create Sales Order.
        Initialize();
        CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, Customer."No.");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify: Verify the Transaction Mode Code is updated on Sales Invoice Header after posting Prepayment Invoice.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.TestField("Transaction Mode", Customer."Transaction Mode Code");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Telebank Prepayment");
        LibraryERMCountryData.UpdatePrepaymentAccounts();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Telebank Prepayment");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Telebank Prepayment");
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        TransactionMode: Record "Transaction Mode";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Transaction Mode Code", CreateTransactionMode(TransactionMode."Account Type"::Customer));
        Customer.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // Using random for Quantity, Direct Unit Cost and Prepayment Pct.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, BuyFromVendorNo);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Using random for Quantity, Unit Price and Prepayment Pct.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateTransactionMode(AccountType: Option): Code[20]
    var
        TransactionMode: Record "Transaction Mode";
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, AccountType);
        exit(TransactionMode.Code);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    var
        TransactionMode: Record "Transaction Mode";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Transaction Mode Code", CreateTransactionMode(TransactionMode."Account Type"::Vendor));
        Vendor.Modify(true);
    end;

    local procedure GetPostedDocumentNo(NoSeries: Code[20]): Code[20]
    var
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        exit(NoSeriesCodeunit.PeekNextNo(NoSeries));
    end;
}

