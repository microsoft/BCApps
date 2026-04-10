codeunit 137503 "SCM Qty on Comb. Invoice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Quantity] [Unit Of Measure] [SCM]
        isInitialized := false;
    end;

    var
        Text001: Label 'must have the same sign as';
        Text002: Label 'The quantity that you are trying to invoice is greater than the quantity';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    local procedure CreateItem(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Qty on Comb. Invoice");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Qty on Comb. Invoice");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Qty on Comb. Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoice()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();
        CreateItem(Item, ItemUnitOfMeasure);
        CreatePurchaseOrder(PurchaseHeader, Item."No.");
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLine.SetCurrentKey("Order No.", "Order Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");

        InvoiceNo := CreatePurchaseInvoice(PurchRcptLine, VendorNo);

        Commit();

        PurchaseLineVerify(PurchaseLine."Document Type"::Invoice, InvoiceNo, ItemUnitOfMeasure.Code);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Quantity: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        Quantity := 10;
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, -Quantity);
    end;

    local procedure CreatePurchaseInvoice(var PurchRcptLine: Record "Purch. Rcpt. Line"; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, VendorNo);

        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        exit(PurchaseHeaderInvoice."No.");
    end;

    local procedure PurchaseLineVerify(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; AlternateUOMCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindSet();

        // Test first the positive quantity line, then the negative quantity line
        repeat
            // Exercise
            if PurchaseLine.Quantity < 0 then
                asserterror PurchaseLine.Validate(Quantity, PurchaseLine.Quantity - 0.00001)
            else
                asserterror PurchaseLine.Validate(Quantity, PurchaseLine.Quantity + 0.00001);

            // Verify
            Assert.ExpectedError(Text002);

            // Exercise
            asserterror PurchaseLine.Validate(Quantity, -PurchaseLine.Quantity);

            // Verify
            Assert.ExpectedError(Text001);

            // Exercise
            asserterror PurchaseLine.Validate("Unit of Measure Code", AlternateUOMCode);

            // Verify
            if DocumentType = PurchaseLine."Document Type"::Invoice then
                Assert.ExpectedError(PurchaseLine.FieldCaption("Receipt No."))
            else
                Assert.ExpectedError(PurchaseLine.FieldCaption("Return Shipment No."));

            // Exercise + Positive Test
            if PurchaseLine.Quantity < 0 then
                PurchaseLine.Validate(Quantity, PurchaseLine.Quantity + 1)
            else
                PurchaseLine.Validate(Quantity, PurchaseLine.Quantity - 1);
        until PurchaseLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseCrMemo()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShptLine: Record "Return Shipment Line";
        CrMemoNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();
        CreateItem(Item, ItemUnitOfMeasure);
        CreatePurchaseRetOrder(PurchaseHeader, Item."No.");
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        ReturnShptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
        ReturnShptLine.SetRange("Return Order No.", PurchaseHeader."No.");

        CrMemoNo := CreatePurchaseCreditMemo(ReturnShptLine, VendorNo);

        Commit();

        PurchaseLineVerify(PurchaseLine."Document Type"::"Credit Memo", CrMemoNo, ItemUnitOfMeasure.Code);
    end;

    local procedure CreatePurchaseRetOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');

        Quantity := 10;
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, -Quantity);
    end;

    local procedure CreatePurchaseCreditMemo(var ReturnShptLine: Record "Return Shipment Line"; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderCrMemo, PurchaseHeaderCrMemo."Document Type"::"Credit Memo", VendorNo);

        PurchGetReturnShipments.SetPurchHeader(PurchaseHeaderCrMemo);
        PurchGetReturnShipments.CreateInvLines(ReturnShptLine);

        exit(PurchaseHeaderCrMemo."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoice()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Customer: Record Customer;
        SalesHdrOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        InvoiceNo: Code[20];
    begin
        Initialize();
        CreateItem(Item, ItemUnitOfMeasure);
        LibrarySales.CreateCustomer(Customer);

        CreateSalesOrder(SalesHdrOrder, Customer."No.", Item."No.");

        LibrarySales.PostSalesDocument(SalesHdrOrder, true, false);
        SalesShptLine.SetCurrentKey("Order No.", "Order Line No.");
        SalesShptLine.SetRange("Order No.", SalesHdrOrder."No.");

        InvoiceNo := CreateSalesInvoice(SalesShptLine, Customer."No.");

        Commit();

        SalesLineVerify(SalesLine."Document Type"::Invoice, InvoiceNo, ItemUnitOfMeasure.Code);
    end;

    local procedure CreateSalesOrder(var SalesHdrOrder: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesLineOrder: Record "Sales Line";
        Quantity: Decimal;
    begin
        LibrarySales.CreateSalesHeader(SalesHdrOrder, SalesHdrOrder."Document Type"::Order, CustomerNo);

        Quantity := 10;
        LibrarySales.CreateSalesLine(SalesLineOrder, SalesHdrOrder, SalesLineOrder.Type::Item, ItemNo, Quantity);
        LibrarySales.CreateSalesLine(SalesLineOrder, SalesHdrOrder, SalesLineOrder.Type::Item, ItemNo, -Quantity);
    end;

    local procedure CreateSalesInvoice(var SalesShptLine: Record "Sales Shipment Line"; CustomerNo: Code[20]): Code[20]
    var
        SalesHeaderInvoice: Record "Sales Header";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, CustomerNo);

        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShptLine);

        exit(SalesHeaderInvoice."No.");
    end;

    local procedure SalesLineVerify(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; AlternateUOMCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindSet();
        // Test first the positive quantity line, then the negative quantity line
        repeat
            // Exercise
            if SalesLine.Quantity < 0 then
                asserterror SalesLine.Validate(Quantity, SalesLine.Quantity - 0.00001)
            else
                asserterror SalesLine.Validate(Quantity, SalesLine.Quantity + 0.00001);

            // Verify
            Assert.ExpectedError(Text002);

            // Exercise
            asserterror SalesLine.Validate(Quantity, -SalesLine.Quantity);

            // Verify
            Assert.ExpectedError(Text001);

            // Exercise
            asserterror SalesLine.Validate("Unit of Measure Code", AlternateUOMCode);

            // Verify
            if DocumentType = SalesLine."Document Type"::Invoice then
                Assert.ExpectedError(SalesLine.FieldCaption("Shipment No."))
            else
                Assert.ExpectedError(SalesLine.FieldCaption("Return Receipt No."));

            // Exercise + Positive Test
            if SalesLine.Quantity < 0 then
                SalesLine.Validate(Quantity, SalesLine.Quantity + 1)
            else
                SalesLine.Validate(Quantity, SalesLine.Quantity - 1);
        until SalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCrMemo()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Customer: Record Customer;
        SalesHdrRetOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnRcptLine: Record "Return Receipt Line";
        CrMemoNo: Code[20];
    begin
        Initialize();
        CreateItem(Item, ItemUnitOfMeasure);
        LibrarySales.CreateCustomer(Customer);

        CreateSalesRetOrder(SalesHdrRetOrder, Customer."No.", Item."No.");

        LibrarySales.PostSalesDocument(SalesHdrRetOrder, true, false);
        ReturnRcptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
        ReturnRcptLine.SetRange("Return Order No.", SalesHdrRetOrder."No.");

        CrMemoNo := CreateSalesCreditMemo(ReturnRcptLine, Customer."No.");

        Commit();

        SalesLineVerify(SalesLine."Document Type"::"Credit Memo", CrMemoNo, ItemUnitOfMeasure.Code);
    end;

    local procedure CreateSalesRetOrder(var SalesHdrRetOrder: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesLineRetOrder: Record "Sales Line";
        Quantity: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHdrRetOrder, SalesHdrRetOrder."Document Type"::"Return Order", CustomerNo);

        Quantity := 10;
        LibrarySales.CreateSalesLine(SalesLineRetOrder, SalesHdrRetOrder, SalesLineRetOrder.Type::Item, ItemNo, Quantity);
        LibrarySales.CreateSalesLine(SalesLineRetOrder, SalesHdrRetOrder, SalesLineRetOrder.Type::Item, ItemNo, -Quantity);
    end;

    local procedure CreateSalesCreditMemo(var ReturnRcptLine: Record "Return Receipt Line"; CustomerNo: Code[20]): Code[20]
    var
        SalesHeaderCrMemo: Record "Sales Header";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        LibrarySales.CreateSalesHeader(SalesHeaderCrMemo, SalesHeaderCrMemo."Document Type"::"Credit Memo", CustomerNo);

        SalesGetReturnReceipts.SetSalesHeader(SalesHeaderCrMemo);
        SalesGetReturnReceipts.CreateInvLines(ReturnRcptLine);

        exit(SalesHeaderCrMemo."No.");
    end;
}

