codeunit 137160 "SCM Prepayment Orders"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Prepayment] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationRed: Record Location;
        LocationSilver: Record Location;
        LocationYellow: Record Location;
        LocationGreen: Record Location;
        LocationOrange: Record Location;
        LocationInTransit: Record Location;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountMustBeEqualErr: Label 'Amount must be equal.';

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndRegisterPutAwayFromPurchaseOrderWithPostPrepaymentInvoice()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisterPutAwayWithPostPrepaymentInvoice(false, false, false);  // WarehouseShipment, PartialWarehouseShipment and RemainingWarehouseShipment as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipmentFromSalesOrderWithPostPrepaymentInvoice()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisterPutAwayWithPostPrepaymentInvoice(true, false, false);  // WarehouseShipment as TRUE. PartialWarehouseShipment and RemainingWarehouseShipment as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickAndPostWarehouseShipmentForPartialQuantityWithPostPrepaymentInvoice()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisterPutAwayWithPostPrepaymentInvoice(true, true, false);  // WarehouseShipment and PartialWarehouseShipment as TRUE. RemainingWarehouseShipment as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickAndPostWarehouseShipmentForRemainingQuantityWithPostPrepaymentInvoice()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisterPutAwayWithPostPrepaymentInvoice(true, true, true);  // WarehouseShipment, PartialWarehouseShipment and RemainingWarehouseShipment as TRUE.
    end;

    local procedure PostWarehouseShipmentAfterRegisterPutAwayWithPostPrepaymentInvoice(WarehouseShipment: Boolean; PartialWarehouseShipment: Boolean; RemainingWarehouseShipment: Boolean)
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        DocumentNo: Code[20];
    begin
        // Create and release Purchase Order with Post Prepayment Invoice. Create and register Put-Away from Purchase Order.
        Quantity := LibraryRandom.RandInt(50);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type");
        CreateItemWithVendorNoAndReorderingPolicy(Item, '', Item."Reordering Policy"::" ");
        UpdateVATProdPostingGroupOnItem(Item, VATPostingSetup."VAT Prod. Posting Group");
        CreateVendorWithVATBusPostingGroup(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        UpdateGLAccount(Item, GeneralPostingSetup."Purch. Prepayments Account");
        CreateCustomerWithVATBusPostingGroup(Customer, VATPostingSetup."VAT Bus. Posting Group");
        CreateAndRegisterPutAwayFromPOWithPostPrepaymentInvoice(
          PurchaseHeader, PurchaseLine, Vendor."No.", Item."No.", Quantity, LocationWhite.Code);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Verify.
        VerifyGLEntry(DocumentNo, VATPostingSetup."Purchase VAT Account", PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);  // Value required for the test.
        VerifyGLEntry(DocumentNo, GeneralPostingSetup."Purch. Prepayments Account", -PurchaseLine."Prepmt. Line Amount");

        if WarehouseShipment then begin
            // Exercise.
            GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
            UpdateGLAccount(Item, GeneralPostingSetup."Sales Prepayments Account");

            CreateAndReleaseSalesOrderWithPostPrepaymentInvoice(
              SalesHeader, SalesLine, Customer."No.", Item."No.", Quantity, LocationWhite.Code);
            CreateWarehouseShipment(SalesHeader);
            DocumentNo := FindPostedSalesInvoice(SalesHeader."Sell-to Customer No.", '', SalesHeader."External Document No.");

            // Verify.
            VerifyGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", -SalesLine."Prepmt. Line Amount" * SalesLine."VAT %" / 100);  // Value required for the test.
            VerifyGLEntry(DocumentNo, GeneralPostingSetup."Sales Prepayments Account", -SalesLine."Prepmt. Line Amount");
        end;

        if PartialWarehouseShipment then begin
            // Exercise.
            CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
            UpdateQuantityToHandleOnWarehousePickLines(SalesHeader."No.", Quantity / 2);  // Value required for Partial Quantity.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            PostWarehouseShipment(
              WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Quantity / 2, true); // Value required for Partial Quantity.
            DocumentNo :=
              FindPostedSalesInvoice(SalesHeader."Sell-to Customer No.", SalesHeader."No.", WarehouseShipmentHeader."External Document No.");

            // Verify.
            VerifyGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", -SalesLine."Line Amount" * SalesLine."VAT %" / 200);  // Value required for the test.
            VerifyGLEntry(DocumentNo, GeneralPostingSetup."Sales Prepayments Account", SalesLine."Prepmt. Line Amount" / 2);  // Value required for the test.
        end;

        if RemainingWarehouseShipment then begin
            // Exercise.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            PostWarehouseShipment(
              WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Quantity / 2, true); // Value required for Partial Quantity.
            DocumentNo :=
              FindPostedSalesInvoice(SalesHeader."Sell-to Customer No.", SalesHeader."No.", WarehouseShipmentHeader."External Document No.");

            // Verify.
            VerifyGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", -SalesLine."Line Amount" * SalesLine."VAT %" / 200);  // Value required for the test.
            VerifyGLEntry(DocumentNo, GeneralPostingSetup."Sales Prepayments Account", SalesLine."Prepmt. Line Amount" / 2);  // Value required for the test.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepaymentInvoiceWithCurrencyCode()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrencyFactor: Decimal;
        ExternalDoNo: Code[35];
    begin
        Initialize();
        CreateItemWithVATProdPostingGroup(Item, VATPostingSetup);
        CreateCustomerWithFCYAndPaymentMethod(Customer, PaymentMethod, CurrencyFactor, VATPostingSetup."VAT Bus. Posting Group");

        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        UpdateGLAccount(Item, GeneralPostingSetup."Sales Prepayments Account");

        ExternalDoNo := CreateAndReleaseSalesOrderWithPostPrepaymentInvoice(
            SalesHeader, SalesLine, Customer."No.", Item."No.", LibraryRandom.RandInt(50), '');

        VerifyGLEntry(
          FindPostedSalesInvoice(Customer."No.", '', ExternalDoNo), PaymentMethod."Bal. Account No.",
          Round(SalesLine."Amount Including VAT" * SalesLine."Prepayment %" * 0.01,
            LibraryERM.GetAmountRoundingPrecision()) / CurrencyFactor); // Value required for the test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchasePrepaymentInvoiceWithCurrencyCode()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        CurrencyFactor: Decimal;
        VendorInvoiceNo: Code[35];
    begin
        Initialize();
        CreateItemWithVATProdPostingGroup(Item, VATPostingSetup);
        CreateVendorWithFCYAndPaymentMethod(Vendor, PaymentMethod, CurrencyFactor, VATPostingSetup."VAT Bus. Posting Group");

        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        UpdateGLAccount(Item, GeneralPostingSetup."Purch. Prepayments Account");

        VendorInvoiceNo := CreateAndReleasePurchaseOrderWithPostPrepaymentInvoice(
            PurchaseHeader, PurchaseLine, Vendor."No.", Item."No.", LibraryRandom.RandInt(50), '');

        VerifyGLEntry(
          FindPostedPurchaseInvoice(Vendor."No.", PurchaseHeader."No.", VendorInvoiceNo), PaymentMethod."Bal. Account No.",
          -Round(PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" * 0.01 * (1 + VATPostingSetup."VAT %" / 100),
            LibraryERM.GetAmountRoundingPrecision()) / CurrencyFactor); // Value required for the test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPrepaymentWhenPostingWhseReceiptWithOverReceipt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [FEATURE] [Prepayment] [Over-Receipt] [Warehouse Receipt]
        // [SCENARIO 483707] Check that the prepayment invoice is posted when posting a warehouse receipt with over-receipt.
        Initialize();

        // [GIVEN] Set up item, vendor, and g/l account for posting prepayment.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type");
        CreateItemWithVendorNoAndReorderingPolicy(Item, '', Item."Reordering Policy"::" ");
        UpdateVATProdPostingGroupOnItem(Item, VATPostingSetup."VAT Prod. Posting Group");
        CreateVendorWithVATBusPostingGroup(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        UpdateGLAccount(Item, GeneralPostingSetup."Purch. Prepayments Account");

        // [GIVEN] Set up location for posting warehouse receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);

        // [GIVEN] Create purchase order, post prepayment invoice, and release the order.
        CreateAndReleasePurchaseOrderWithPostPrepaymentInvoice(PurchaseHeader, PurchaseLine, Vendor."No.", Item."No.", 100, Location.Code);

        // [GIVEN] Create warehouse receipt and set Over-Receipt Quantity on the warehouse receipt line.
        CreateWarehouseReceipt(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", Item."No.");
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 1);
        WarehouseReceiptLine.Modify(true);

        // [WHEN] Post the warehouse receipt.
        // [THEN] Posting fails because of missing prepayment invoice.
        Commit();
        asserterror PostWarehouseReceipt(PurchaseHeader."No.", Item."No.");
        Assert.ExpectedError('prepayment');

        // [THEN] Post the prepayment invoice for the over-receipt quantity.
        PurchaseHeader.Find();
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Now the warehouse receipt can be posted.
        PostWarehouseReceipt(PurchaseHeader."No.", Item."No.");

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckPrepaymentWhenPostingInventoryPutawayWithOverReceipt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [FEATURE] [Prepayment] [Over-Receipt] [Inventory Put-away]
        // [SCENARIO 483707] Check that the prepayment invoice is posted when posting an inventory put-away with over-receipt.
        Initialize();

        // [GIVEN] Set up item, vendor, and g/l account for posting prepayment.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type");
        CreateItemWithVendorNoAndReorderingPolicy(Item, '', Item."Reordering Policy"::" ");
        UpdateVATProdPostingGroupOnItem(Item, VATPostingSetup."VAT Prod. Posting Group");
        CreateVendorWithVATBusPostingGroup(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        UpdateGLAccount(Item, GeneralPostingSetup."Purch. Prepayments Account");

        // [GIVEN] Set up location for posting inventory put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Create purchase order, post prepayment invoice, and release the order.
        CreateAndReleasePurchaseOrderWithPostPrepaymentInvoice(PurchaseHeader, PurchaseLine, Vendor."No.", Item."No.", 100, Location.Code);

        // [GIVEN] Create inventory put-away and set Over-Receipt Quantity on the put-away line.
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 1);
        WarehouseActivityLine.Modify(true);

        // [WHEN] Post the inventory put-away.
        // [THEN] Posting fails because of missing prepayment invoice.
        Commit();
        asserterror PostInventoryActivity(WarehouseActivityLine."Source Document", WarehouseActivityLine."Source No.", WarehouseActivityLine."Activity Type");
        Assert.ExpectedError('prepayment');

        // [THEN] Post the prepayment invoice for the over-receipt quantity.
        PurchaseHeader.Find();
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Now the inventory put-away can be posted.
        PostInventoryActivity(WarehouseActivityLine."Source Document", WarehouseActivityLine."Source No.", WarehouseActivityLine."Activity Type");

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Prepayment Orders");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Prepayment Orders");
        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ItemJournalSetup(ReclassItemJournalTemplate, ReclassItemJournalBatch, ReclassItemJournalTemplate.Type::Transfer);
        LocationSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Prepayment Orders");
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        PostWarehouseReceipt(SourceNo, ItemNo);
        FindPickBin(Bin, LocationCode);
        UpdateBinCodeOnPutAwayLine(Bin, SourceNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndRegisterPutAwayFromPOWithPostPrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateAndReleasePurchaseOrderWithPostPrepaymentInvoice(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, Quantity, LocationCode);
        CreateWarehouseReceipt(PurchaseHeader);
        CreateAndRegisterPutAwayFromPurchaseOrder(PurchaseHeader."No.", ItemNo, LocationCode);
        PurchaseHeader.Find();
    end;

    local procedure CreateAndReleasePurchaseOrderWithPostPrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]): Code[35]
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, Quantity, LocationCode, false);
        UpdatePrepaymentPercentOnPurchaseLine(PurchaseLine);
        UpdateUnitCostOnPurchaseLine(PurchaseLine);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        exit(PurchaseHeader."Vendor Invoice No.");
    end;

    local procedure CreateAndReleaseSalesOrderWithPostPrepaymentInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]): Code[35]
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, false);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::Order, SalesHeader."No.");
        UpdatePrepaymentPercentOnSalesLine(SalesLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        exit(SalesHeader."External Document No.");
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Invoice Rounding Precision" := LibraryERM.GetAmountRoundingPrecision();
        Currency.Modify();

        CreateCurrencyExchangeRate(
          CurrencyExchangeRate, Currency.Code, CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code, WorkDate());
    end;

    local procedure CreateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; StartingDate: Date)
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(50, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCustomerWithFCYAndPaymentMethod(var Customer: Record Customer; var PaymentMethod: Record "Payment Method"; var CurrencyFactor: Decimal; VATBusPostingGroup: Code[20])
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        PaymentMethod.Modify(true);
        CurrencyFactor := CreateCustomerWithCurrencyExchangeRate(Customer);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithVATBusPostingGroup(var Customer: Record Customer; VATBusPostingGroup: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
    end;

    local procedure CreateInTransitLocation()
    begin
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
    end;

    local procedure CreateItemWithVendorNoAndReorderingPolicy(var Item: Record Item; VendorNo: Code[20]; ReorderingPolicy: Enum "Reordering Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateItemWithVATProdPostingGroup(var Item: Record Item; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type");
        UpdateVATProdPostingGroupOnItem(Item, VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        GetWarehouseShipmentHeader(WarehouseShipmentHeader, SourceDocument, SourceNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        if UseTracking then
            PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, ItemTracking);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        if Reserve then
            SalesLine.ShowReservation();
    end;

    local procedure CreateVendorWithCurrencyExchangeRate(var Vendor: Record Vendor): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryPurchase.CreateVendor(Vendor);
        UpdateCurrencyCodeOnVendor(Vendor, CurrencyExchangeRate."Currency Code");
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount"); // Value required for calculating Currency factor.
    end;

    local procedure CreateCustomerWithCurrencyExchangeRate(var Customer: Record Customer): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Customer.Modify(true);
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount"); // Value required for calculating Currency factor.
    end;

    local procedure CreateVendorWithFCYAndPaymentMethod(var Vendor: Record Vendor; var PaymentMethod: Record "Payment Method"; var CurrencyFactor: Decimal; VATBusPostingGroup: Code[20])
    begin
        FindPaymentMethodWithBalanceAccount(PaymentMethod);
        CurrencyFactor := CreateVendorWithCurrencyExchangeRate(Vendor);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithVATBusPostingGroup(var Vendor: Record Vendor; VATBusPostingGroup: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
    end;

    local procedure CreateWarehouseReceipt(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseShipment(var SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure FindPaymentMethodWithBalanceAccount(var PaymentMethod: Record "Payment Method")
    begin
        PaymentMethod.SetRange("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.SetFilter("Bal. Account No.", '<>''''');
        PaymentMethod.FindFirst();
    end;

    local procedure FindPostedSalesInvoice(CustomerNo: Code[20]; OrderNo: Code[20]; ExternalDocumentNo: Code[35]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.SetRange("External Document No.", ExternalDocumentNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindPostedPurchaseInvoice(VendorNo: Code[20]; OrderNo: Code[20]; VendorInvoiceNo: Code[35]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.SetRange("Vendor Invoice No.", VendorInvoiceNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure FindPickBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindPickZone(Zone, LocationCode);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));  // Find Random Bin.
    end;

    local procedure FindPickZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));  // TRUE for Put-away and Pick.
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; ItemNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure GetWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate2: Record "Item Journal Template"; var ItemJournalBatch2: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate2, ItemJournalTemplateType);
        ItemJournalTemplate2.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate2.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch2, ItemJournalTemplate2.Type, ItemJournalTemplate2.Name);
        ItemJournalBatch2.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch2.Modify(true);
    end;

    local procedure LocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        CreateAndUpdateLocation(LocationBlue, true, true, false, false, false);  // Location Blue with Require Put-Away and Require Pick.
        CreateAndUpdateLocation(LocationSilver, true, true, false, false, true);  // Location Silver with Require Put-away, Require Pick and Bin Mandatory.
        CreateAndUpdateLocation(LocationYellow, false, false, false, false, true);  // Location Yellow with Bin Mandatory.
        CreateAndUpdateLocation(LocationRed, false, false, false, false, false);
        CreateAndUpdateLocation(LocationGreen, true, true, true, true, false);  // Location Green with Require Put-Away, Require Pick, Require Receive and Require Shipment.
        CreateAndUpdateLocation(LocationOrange, false, true, false, false, false);  // Location Orange with Require Pick.
        CreateInTransitLocation();
    end;

    local procedure NoSeriesSetup()
    begin
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20]; ItemNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, ItemNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; QuantityToShip: Decimal; Invoice: Boolean)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentLine.Validate("Qty. to Ship", QuantityToShip);
        WarehouseShipmentLine.Modify(true);
        UpdateExternalDocumentNoOnWarehouseShipmentHeader(WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, Invoice);
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PostInventoryActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure UpdateBinCodeOnPutAwayLine(Bin: Record Bin; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateCurrencyCodeOnVendor(var Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
    end;

    local procedure UpdateExternalDocumentNoOnWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseShipmentHeader.Find();
        WarehouseShipmentHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure UpdateGLAccount(Item: Record Item; AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        GLAccount."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        GLAccount."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        GLAccount.Modify(true);
    end;

    local procedure UpdatePrepaymentPercentOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Prepayment %", LibraryRandom.RandInt(50));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePrepaymentPercentOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityToHandleOnWarehousePickLines(SourceNo: Code[20]; QuantityToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.ModifyAll("Qty. to Handle", QuantityToHandle);
        WarehouseActivityLine.ModifyAll("Qty. to Handle (Base)", QuantityToHandle);
    end;

    local procedure UpdateUnitCostOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(50));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateVATProdPostingGroupOnItem(var Item: Record Item; VATProdPostingGroup: Code[20])
    begin
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        if Amount > 0 then
            GLEntry.SetFilter(Amount, '>0')
        else
            GLEntry.SetFilter(Amount, '<0');
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualErr);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

