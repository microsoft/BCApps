codeunit 144055 "Test CH Posting Description"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test CH Posting Description");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test CH Posting Description");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test CH Posting Description");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderTwice()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandDecInDecimalRange(1, SalesLine.Quantity, 2));
        SalesLine.Modify(true);

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        SalesInvoiceHeader.Get(DocNo);
        Assert.IsTrue(StrPos(SalesInvoiceHeader."Posting Description", SalesHeader."No." + '/' + Customer.Name) > 0,
          'Wrong description:' + SalesInvoiceHeader."Posting Description");

        SalesShipmentHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShipmentHeader.FindLast();
        Assert.IsTrue(StrPos(SalesShipmentHeader."Posting Description", SalesHeader."No." + '/' + Customer.Name) > 0,
          'Wrong description:' + SalesShipmentHeader."Posting Description");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderTwice()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Return Qty. to Receive", LibraryRandom.RandDecInDecimalRange(1, SalesLine.Quantity, 2));
        SalesLine.Modify(true);

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        SalesCrMemoHeader.Get(DocNo);
        Assert.IsTrue(StrPos(SalesCrMemoHeader."Posting Description", SalesHeader."No." + '/' + Customer.Name) > 0,
          'Wrong description:' + SalesCrMemoHeader."Posting Description");

        ReturnReceiptHeader.SetRange("Sell-to Customer No.", Customer."No.");
        ReturnReceiptHeader.FindLast();
        Assert.IsTrue(StrPos(ReturnReceiptHeader."Posting Description", SalesHeader."No." + '/' + Customer.Name) > 0,
          'Wrong description:' + ReturnReceiptHeader."Posting Description");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderTwice()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandDecInDecimalRange(1, PurchaseLine.Quantity, 2));
        PurchaseLine.Modify(true);

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchaseHeader.Validate("Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        PurchInvHeader.Get(DocNo);
        Assert.IsTrue(StrPos(PurchInvHeader."Posting Description", PurchaseHeader."Vendor Invoice No." + '/' + Vendor.Name) > 0,
          'Wrong description:' + PurchInvHeader."Posting Description");

        PurchRcptHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchRcptHeader.FindLast();
        Assert.IsTrue(StrPos(PurchRcptHeader."Posting Description", PurchaseHeader."Vendor Invoice No." + '/' + Vendor.Name) > 0,
          'Wrong description:' + PurchRcptHeader."Posting Description");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderTwice()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Cr. Memo No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Return Qty. to Ship", LibraryRandom.RandDecInDecimalRange(1, PurchaseLine.Quantity, 2));
        PurchaseLine.Modify(true);

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchaseHeader.Validate("Vendor Cr. Memo No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Cr. Memo No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        PurchCrMemoHdr.Get(DocNo);
        Assert.IsTrue(StrPos(PurchCrMemoHdr."Posting Description", PurchaseHeader."Vendor Cr. Memo No." + '/' + Vendor.Name) > 0,
          'Wrong description:' + PurchCrMemoHdr."Posting Description");

        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        ReturnShipmentHeader.FindLast();
        Assert.IsTrue(StrPos(ReturnShipmentHeader."Posting Description", PurchaseHeader."Vendor Cr. Memo No." + '/' + Vendor.Name) > 0,
          'Wrong description:' + ReturnShipmentHeader."Posting Description");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoice()
    var
        Item: Record Item;
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify.
        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst();
        Assert.IsTrue(StrPos(ServiceInvoiceHeader."Posting Description", ServiceInvoiceHeader."No." + '/' + Customer.Name) > 0,
          'Wrong description:' + ServiceInvoiceHeader."Posting Description");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderInDiffLanguage()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocNo: Code[20];
    begin
        Initialize();

        // Setup
        UpdatePurchPayablesSetup();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandDec(100, 2));
        GlobalLanguage(GlobalLanguage + 1);

        // Exercise.
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", DocNo);
        VendorLedgerEntry.FindFirst();
        Assert.IsTrue(StrPos(VendorLedgerEntry.Description, PurchaseHeader."Vendor Invoice No." + '/' + Vendor.Name) > 0,
          'Wrong description:' + VendorLedgerEntry.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnterDescriptionForSalesLineTypeWithoutReference()
    var
        SalesLine: Record "Sales Line";
        SalesLineDescr: Text;
        Type: Option;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 233233] Description in sales line should be accepted without triggering the search for a related record if the type is one of the following: Title, Begin-Total, End-Total, New Page

        for Type := SalesLine.Type::Title.AsInteger() to SalesLine.Type::"New Page".AsInteger() do begin
            SalesLineDescr := LibraryUtility.GenerateRandomText(MaxStrLen(SalesLine.Description));
            SalesLine.Init();
            SalesLine.Type := "Sales Line Type".FromInteger(Type);
            SalesLine.Validate(Description, CopyStr(SalesLineDescr, 1, MaxStrLen(SalesLine.Description)));

            SalesLine.TestField(Description, SalesLineDescr);
        end;
    end;

    local procedure UpdatePurchPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify(true);
    end;
}

