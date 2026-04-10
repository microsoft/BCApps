codeunit 137511 "SMB Cancel Sales/Purch. Inv."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Correct Posted Invoice] [SMB]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesGetShptInvoiceFromOrder()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        LibrarySales: Codeunit "Library - Sales";
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

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        SalesGetShpt.SetSalesHeader(SalesHeader);
        SalesGetShpt.CreateInvLines(SalesShptLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        Commit();

        GLEntry.FindLast();

        // EXERCISE (TFS ID: 306797)
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        SalesCheckCreditMemoCreated(Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectSalesInvoiceFromOrder()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize();

        CreateItemWithPrice(Item, 1);
        LibrarySales.CreateCustomer(Cust);

        // It should not be possible to cancel invoice that are associated to an order
        CreateSalesOrderForItem(Cust, Item, 1, SalesHeader, SalesLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        GLEntry.FindLast();

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);

        // VERIFY
        SalesCheckCreditMemoCreated(Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelSalesInvoiceFromOrder()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize();

        CreateItemWithPrice(Item, 1);
        LibrarySales.CreateCustomer(Cust);

        // It should not be possible to cancel invoice that are associated to an order
        CreateSalesOrderForItem(Cust, Item, 1, SalesHeader, SalesLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        GLEntry.FindLast();

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        SalesCheckCreditMemoCreated(Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchGetRcptInvoiceFromOrder()
    var
        PurchHeader: Record "Purchase Header";
        Vend: Record Vendor;
        Item: Record Item;
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeaderTmp: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        LibraryPurch: Codeunit "Library - Purchase";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PurchGetRcpt: Codeunit "Purch.-Get Receipt";
    begin
        Initialize();

        CreateItemWithCost(Item, 1);
        LibraryPurch.CreateVendor(Vend);

        // It should not be possible to cancel a get receipt invoice that is associated to an order
        CreatePurchOrderForItem(Vend, Item, 1, PurchHeader, PurchLine);
        LibraryPurch.PostPurchaseDocument(PurchHeader, true, false);

        PurchRcptLine.SetRange("Order No.", PurchLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchLine."Line No.");
        PurchRcptLine.FindFirst();

        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchHeader, Vend);
        PurchGetRcpt.SetPurchHeader(PurchHeader);
        PurchGetRcpt.CreateInvLines(PurchRcptLine);
        PurchInvHeader.Get(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
        Commit();

        GLEntry.FindLast();

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeaderTmp);
        PurchaseCheckCreditMemoCreated(Vend, GLEntry);
    end;

    local procedure CreateItemWithCost(var Item: Record Item; UnitCost: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item."Last Direct Cost" := UnitCost;
        Item.Modify();
    end;

    local procedure CreatePurchOrderForItem(Vend: Record Vendor; Item: Record Item; Qty: Decimal; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vend."No.");
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", Qty);
    end;

    local procedure CreateItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify();
    end;

    local procedure CreateSalesOrderForItem(Cust: Record Customer; Item: Record Item; Qty: Decimal; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
    end;

    local procedure SalesCheckCreditMemoCreated(Cust: Record Customer; LastGLEntry: Record "G/L Entry")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        Assert.IsFalse(LastGLEntry.Next() = 0, 'No new G/L entries are created');
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", Cust."No.");
        Assert.RecordIsNotEmpty(SalesCrMemoHeader);
    end;

    local procedure PurchaseCheckCreditMemoCreated(Vendor: Record Vendor; LastGLEntry: Record "G/L Entry")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        Assert.IsFalse(LastGLEntry.Next() = 0, 'No new G/L entries are created');
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.RecordIsNotEmpty(PurchCrMemoHdr);
    end;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SMB Cancel Sales/Purch. Inv.");
        // Initialize setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SMB Cancel Sales/Purch. Inv.");

        IsInitialized := true;

        SetGlobalNoSeriesInSetups();

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SMB Cancel Sales/Purch. Inv.");
    end;

    local procedure SetGlobalNoSeriesInSetups()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        MarketingSetup: Record "Marketing Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify();

        MarketingSetup.Get();
        MarketingSetup."Contact Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        MarketingSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Vendor Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify();
    end;
}
