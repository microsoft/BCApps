codeunit 137156 "SCM Orders IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationRed: Record Location;
        LocationGreen: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryJob: Codeunit "Library - Job";
        LibraryAccountSchedule: Codeunit "Library - Account Schedule";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        isInitialized: Boolean;
        ReserveItemsManuallyConfirmQst: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        ShipmentDateBeforeWorkDateMsg: Label '%1 %2 is before work date %3', Comment = '%1 = Shipment Date, %2 = Shipment Date value, %3 = Work Date value';
        InventoryPutAwayCreatedMsg: Label 'Number of Invt. Put-away activities created';
        OrderMustBeCompleteShipmentErr: Label 'This document cannot be shipped completely. Change the value in the Shipping Advice field to Partial.';
        UndoShipmentMsg: Label 'Do you really want to undo the selected Shipment lines?';
        UndoReturnReceiptMsg: Label 'Do you really want to undo the selected Return Receipt lines?';
        RecordMustBeDeletedTxt: Label 'Order must be deleted.';
        SalesLineDiscountMustBeDeletedErr: Label 'Sales Line Discount must be deleted.';
        ConfirmTextForChangeOfSellToCustomerOrBuyFromVendorQst: Label 'Do you want to change';
        DiscountErr: Label 'The Discount Amount is not correct.';
        NothingToHandleErr: Label 'Nothing to handle.';
        QtyOnWhseActivLineErr: Label 'Quantity on Warehouse Activity Lines are not correct.';
        WrongAmountValueErr: Label 'Wrong Amount value in column %1.';
        PeriodTxt: Label 'Period';
        NonInvtblCostTxt: Label 'Non-Invtbl. Costs (LCY)';
        DimColumnOption: Option Location,Period;
        WrongValueErr: Label 'Wrong %1 value';
        ExtendedTextErr: Label 'No Line should be created for Extended Text attached to Line with positive Quantity';
        ServiceNoMismatchErr: Label 'Values are mismatched in Service Line List and in Service Order.';
        ShipmemtDateErr: Label 'Shipment Date error should not appear.';
        ApplFromItemEntryBlankErr: Label 'Appl.-from Item Entry must have a value in Sales Line';
        ApplToItemEntryBlankErr: Label 'Appl.-to Item Entry must have a value in Purchase Line';
        DocumentCountErr: label 'Expected %1 purchase invoice lines but found %2.', Comment = '%1 = Expected Count, %2 = Actual Count';
        DocumentLineQuantityErr: label 'Expected quantity of 1 on line line but found %1.', Comment = '%1 = Actual Quantity';
        DocumentLineSourceNoErr: label 'Expected source on document line is %1 but found %2.', Comment = '%1 = Expected Source No., %2 = Actual Source No.';
        ReservationFromStockErr: Label 'Reservation from Stock must be %1 in %2.', Comment = '%1= Field Value, %2 =Table Caption.';
        PurchasingCodeOnSalesInvoiceErr: Label 'The Purchasing Code should be blank for item %1 on the sales invoice because it is used only for the drop shipment process.', Comment = '%1= Item No.';
        ShipToAddressErr: Label 'Ship-to Address on Return Order should be company address';
        DropShipmentErr: Label 'The Drop Shipment field should be blank for item %1 on the sales invoice.', Comment = '%1= Item No.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueOfSalesTypeOnSalesPricesPage()
    var
        SalesPrices: TestPage "Sales Prices";
        SalesTypeFilter: Integer;
    begin
        // Setup: Open Sales Prices Page.
        Initialize();
        SalesTypeFilter := LibraryRandom.RandInt(3);
        SalesPrices.OpenEdit();

        // Exercise: Set the value of Sales Prices Type filter on Page.
        SalesPrices.SalesTypeFilter.SetValue(SalesTypeFilter);

        // Verify: Verify Sales Prices Type filter on Lines.
        SalesPrices."Sales Type".AssertEquals(SalesTypeFilter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueOfSalesTypeOnSalesLineDiscounts()
    var
        SalesLineDiscounts: TestPage "Sales Line Discounts";
        SalesTypeFilter: Integer;
    begin
        // [FEATURE] [UI] [Discount] [Line Discount]
        Initialize();

        // [GIVEN] "Sales Line Discounts" page
        SalesTypeFilter := LibraryRandom.RandInt(3);
        SalesLineDiscounts.OpenEdit();

        // [WHEN] Set "Sales Type Filter" = "Customer"
        SalesLineDiscounts.SalesTypeFilter.SetValue(SalesTypeFilter);

        // [THEN] The page field "Sales Type" = "Customer"
        SalesLineDiscounts."Sales Type".AssertEquals(SalesTypeFilter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueOfSalesTypeWithFilterOnSalesPricesPage()
    var
        SalesPrice: Record "Sales Price";
        SalesPrices: TestPage "Sales Prices";
        SalesTypeFilter: Integer;
    begin
        // Setup: Open Sales Prices Page.
        Initialize();
        SalesTypeFilter := LibraryRandom.RandInt(2);
        SalesPrices.OpenEdit();

        // Exercise: Set the value of Sales Prices Type filter on Page and applying filter.
        SalesPrices.SalesTypeFilter.SetValue(SalesTypeFilter);
        SalesPrices.FILTER.SetFilter("Sales Type", Format(SalesPrice."Sales Type"::Campaign));

        // Verify: Verify Sales Prices Type filter on Lines and Prices Type filter field.
        SalesPrices."Sales Type".AssertEquals(Format(SalesPrice."Sales Type"::Campaign));
        SalesPrices.SalesTypeFilter.AssertEquals(Format(SalesPrice."Sales Type"::Campaign));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueOfSalesTypeOnWithFilterSalesLineDiscounts()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        SalesLineDiscounts: TestPage "Sales Line Discounts";
        SalesTypeFilter: Integer;
    begin
        // [FEATURE] [UI] [Discount] [Line Discount]
        Initialize();

        // [GIVEN] "Sales Line Discounts" page
        SalesTypeFilter := LibraryRandom.RandInt(2);
        SalesLineDiscounts.OpenEdit();
        // [GIVEN] Set "Sales Type Filter" = "Customer"
        SalesLineDiscounts.SalesTypeFilter.SetValue(SalesTypeFilter);

        // [WHEN] Set the filter on "Sales Type" = "Campaign"
        SalesLineDiscounts.FILTER.SetFilter("Sales Type", Format(SalesLineDiscount."Sales Type"::Campaign));

        // [THEN] The page field "Sales Type" = "Campaign"
        // [THEN] The page field "Sales Type Filter" = "Campaign"
        SalesLineDiscounts."Sales Type".AssertEquals(Format(SalesLineDiscount."Sales Type"::Campaign));
        SalesLineDiscounts.SalesTypeFilter.AssertEquals(Format(SalesLineDiscount."Sales Type"::Campaign));
    end;

    [Test]
    [HandlerFunctions('CheckPurchaseInvoiceLinesModalPageHandler')]
    procedure PurchaseReceiptForMultipleInvoices_GetInvoiceLines()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [408480 Tune Base App: Fix top X repeat patterns with Query Objects]
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Purchase Receipt] [Item Invoice Lines]
        // [SCENARIO] Check that correct Purchase Invoice Lines are found from Purchase Receipt Line
        Initialize();

        // [GIVEN] Purchase Order with one line of given Quantity
        QuantityToProcess := LibraryRandom.RandIntInRange(2, 4);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, Vendor."No.", Item."No.", QuantityToProcess);

        // [GIVEN] Order is received once, creating one Receipt with one line
        PurchaseLine.Validate("Qty. to Receive", QuantityToProcess);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Order is invoiced partially in 'Quantity' iterations, creating 'Quantity' Purchase Invoice Lines
        for Counter := 1 to QuantityToProcess do begin
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
            PurchaseHeader.Modify();
            PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
            PurchaseLine.Validate("Qty. to Invoice", 1);
            PurchaseLine.Modify();
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        end;

        // [GIVEN] Find Posted Purchase Receipt
        PurchRcptHeader.SetFilter("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.GoToRecord(PurchRcptHeader);

        // [WHEN] Run "Item Invoice Lines" action
        PostedPurchaseReceipt.PurchReceiptLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        PostedPurchaseReceipt.PurchReceiptLines.ItemInvoiceLines.Invoke();

        // [THEN] Verify Purchase Invoice Lines
        // Handled by CheckPurchaseInvoiceLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckPurchaseReceiptLinesModalPageHandler')]
    procedure PurchaseInvoiceForMultipleReceipts_GetReceiptLines()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Purchase Invoice] [Item Receipt Lines]
        // [SCENARIO] Check that correct Purchase Receipt Lines are found from Purchase Invoice Line
        Initialize();

        // [GIVEN] Purchase Order with one line of given Quantity
        QuantityToProcess := LibraryRandom.RandIntInRange(2, 4);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, Vendor."No.", Item."No.", QuantityToProcess);

        // [GIVEN] Order is received partially in 'Quantity' iterations, creating 'Quantity' Purchase Receipt Lines
        for Counter := 1 to QuantityToProcess do begin
            PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
            PurchaseLine.Validate("Qty. to Receive", 1);
            PurchaseLine.Modify();
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        end;

        // [GIVEN] Order is invoiced once, creating one Invoice with one line
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
        PurchaseLine.Validate("Qty. to Invoice", QuantityToProcess);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Find Posted Purchase Invoice
        PurchInvHeader.SetFilter("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GoToRecord(PurchInvHeader);

        // [WHEN] Run "Item Receipt Lines" action
        PostedPurchaseInvoice.PurchInvLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        PostedPurchaseInvoice.PurchInvLines.ItemReceiptLines.Invoke();

        // [THEN] Verify Purchase Receipt Lines
        // Handled by CheckPurchaseReceiptLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckPurchaseCreditMemoLinesModalPageHandler')]
    procedure PurchaseReturnShipmentForMultipleCreditMemos_GetCreditMemoLines()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Purchase Return Shipment] [Item Credit Memo Lines]
        // [SCENARIO] Check that correct Purchase Credit Memo Lines are found from Purchase Return Shipment Line
        Initialize();

        // [GIVEN] Purchase Order with one line of given Quantity
        QuantityToProcess := LibraryRandom.RandIntInRange(2, 4);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, Vendor."No.", Item."No.", QuantityToProcess);

        // [GIVEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Purchase Return Order with one line of given Quantity
        Clear(PurchaseHeader);
        Clear(PurchaseLine);
        CreatePurchaseReturnOrder(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, Vendor."No.", Item."No.", QuantityToProcess);

        // [GIVEN] Return Order is shipped once, creating one Return Shipment with one line
        PurchaseLine.Validate("Return Qty. to Ship", QuantityToProcess);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Return Order is invoiced partially in 'Quantity' iterations, creating 'Quantity' Purchase Credit Memo Lines
        for Counter := 1 to QuantityToProcess do begin
            PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
            PurchaseHeader.Modify();
            PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
            PurchaseLine.Validate("Qty. to Invoice", 1);
            PurchaseLine.Modify();
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        end;

        // [GIVEN] Find Posted Purchase Return Shipment
        ReturnShipmentHeader.SetFilter("Return Order No.", PurchaseHeader."No.");
        ReturnShipmentHeader.FindFirst();
        PostedReturnShipment.OpenView();
        PostedReturnShipment.GoToRecord(ReturnShipmentHeader);

        // [WHEN] Run "Item Credit Memo Lines" action
        PostedReturnShipment.ReturnShptLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        PostedReturnShipment.ReturnShptLines.ItemCreditMemoLines.Invoke();

        // [THEN] Verify Purchase Credit Memo Lines
        // Handled by CheckPurchaseCreditMemoLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckPurchaseReturnShipmentLinesModalPageHandler')]
    procedure PurchaseCreditMemoForMultipleReturnShipments_GetReturnShipmentLines()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Purchase Credit Memo] [Item Return Shipment Lines]
        // [SCENARIO] Check that correct Purchase Return Shipment Lines are found from Purchase Credit Memo Line
        Initialize();

        // [GIVEN] Purchase Order with one line of given Quantity
        QuantityToProcess := LibraryRandom.RandIntInRange(2, 4);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, Vendor."No.", Item."No.", QuantityToProcess);

        // [GIVEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Purchase Return Order with one line of given Quantity
        Clear(PurchaseHeader);
        Clear(PurchaseLine);
        CreatePurchaseReturnOrder(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, Vendor."No.", Item."No.", QuantityToProcess);

        // [GIVEN] Return Order is shipped partially in 'Quantity' iterations, creating 'Quantity' Purchase Return Shipment Lines
        for Counter := 1 to QuantityToProcess do begin
            PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
            PurchaseLine.Validate("Return Qty. to Ship", 1);
            PurchaseLine.Modify();
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        end;

        // [GIVEN] Return Order is invoiced once, creating one Credit Memo with one line
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
        PurchaseLine.Validate("Qty. to Invoice", QuantityToProcess);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Find Posted Purchase Credit Memo
        PurchCrMemoHdr.SetFilter("Return Order No.", PurchaseHeader."No.");
        PurchCrMemoHdr.FindFirst();
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GoToRecord(PurchCrMemoHdr);

        // [WHEN] Run "Item Return Shipment Lines" action
        PostedPurchaseCreditMemo.PurchCrMemoLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        PostedPurchaseCreditMemo.PurchCrMemoLines.ItemReturnShipmentLines.Invoke();

        // [THEN] Verify Purchase Return Shipment Lines
        // Handled by CheckPurchaseReturnShipmentLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckSalesInvoiceLinesModalPageHandler')]
    procedure SalesShipmentForMultipleInvoices_GetInvoiceLines()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Sales Shipment] [Item Invoice Lines]
        // [SCENARIO] Check that correct Sales Invoice Lines are found from Sales Shipment Line
        Initialize();

        // [GIVEN] Item with given Inventory
        QuantityToProcess := LibraryRandom.RandIntInRange(2, 4);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", QuantityToProcess, '', 0);

        // [GIVEN] Sales Order with one line of given Quantity
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, "Sales Line Type"::Item, Customer."No.", Item."No.", QuantityToProcess, '');

        // [GIVEN] Order is received once, creating one Shipment with one line
        SalesLine.Validate("Qty. to Ship", QuantityToProcess);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Order is invoiced partially in 'Quantity' iterations, creating 'Quantity' Sales Invoice Lines
        for Counter := 1 to QuantityToProcess do begin
            SalesLine.GetBySystemId(SalesLine.SystemId);
            SalesLine.Validate("Qty. to Invoice", 1);
            SalesLine.Modify();
            SalesHeader.GetBySystemId(SalesHeader.SystemId);
            LibrarySales.PostSalesDocument(SalesHeader, false, true);
        end;

        // [GIVEN] Find Posted Sales Shipment
        SalesShipmentHeader.SetFilter("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        PostedSalesShipment.OpenView();
        PostedSalesShipment.GoToRecord(SalesShipmentHeader);

        // [WHEN] Run "Item Invoice Lines" action
        PostedSalesShipment.SalesShipmLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(Customer."No.");
        PostedSalesShipment.SalesShipmLines.ItemInvoiceLines.Invoke();

        // [THEN] Verify Sales Invoice Lines
        // Handled by CheckSalesInvoiceLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckSalesShipmentLinesModalPageHandler')]
    procedure SalesInvoiceForMultipleShipments_GetShipmentLines()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Sales Invoice] [Item Shipment Lines]
        // [SCENARIO] Check that correct Sales Shipment Lines are found from Sales Invoice Line
        Initialize();

        // [GIVEN] Item with given Inventory
        QuantityToProcess := LibraryRandom.RandIntInRange(2, 4);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", QuantityToProcess, '', 0);

        // [GIVEN] Sales Order with one line of given Quantity
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, "Sales Line Type"::Item, Customer."No.", Item."No.", QuantityToProcess, '');

        // [GIVEN] Order is received partially in 'Quantity' iterations, creating 'Quantity' Sales Shipment Lines
        for Counter := 1 to QuantityToProcess do begin
            SalesLine.GetBySystemId(SalesLine.SystemId);
            SalesLine.Validate("Qty. to Ship", 1);
            SalesLine.Modify();
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        // [GIVEN] Order is invoiced once, creating one Invoice with one line
        SalesLine.GetBySystemId(SalesLine.SystemId);
        SalesLine.Validate("Qty. to Invoice", QuantityToProcess);
        SalesLine.Modify();
        SalesHeader.GetBySystemId(SalesHeader.SystemId);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Find Posted Sales Invoice
        SalesInvoiceHeader.SetFilter("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GoToRecord(SalesInvoiceHeader);

        // [WHEN] Run "Item Shipment Lines" action
        PostedSalesInvoice.SalesInvLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(Customer."No.");
        PostedSalesInvoice.SalesInvLines.ItemShipmentLines.Invoke();

        // [THEN] Verify Sales Shipment Lines
        // Handled by CheckSalesShipmentLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckSalesCreditMemoLinesModalPageHandler')]
    procedure SalesReturnReceiptForMultipleCreditMemos_GetCreditMemoLines()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Sales Return Receipt] [Item Credit Memo Lines]
        // [SCENARIO] Check that correct Sales Credit Memo Lines are found from Sales Return Receipt Line
        Initialize();

        // [GIVEN] Item with given Inventory
        QuantityToProcess := LibraryRandom.RandIntInRange(2, 4);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", QuantityToProcess, '', 0);

        // [GIVEN] Sales Order with one line of given Quantity
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, "Sales Line Type"::Item, Customer."No.", Item."No.", QuantityToProcess, '');

        // [GIVEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales Return Order with one line of given Quantity
        Clear(SalesHeader);
        Clear(SalesLine);
        CreateSalesReturnOrder(SalesHeader, SalesLine, "Sales Line Type"::Item, Customer."No.", Item."No.", QuantityToProcess, '');

        // [GIVEN] Return Order is shipped once, creating one Return Receipt with one line
        SalesLine.Validate("Return Qty. to Receive", QuantityToProcess);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Return Order is invoiced partially in 'Quantity' iterations, creating 'Quantity' Sales Credit Memo Lines
        for Counter := 1 to QuantityToProcess do begin
            SalesLine.GetBySystemId(SalesLine.SystemId);
            SalesLine.Validate("Qty. to Invoice", 1);
            SalesLine.Modify();
            SalesHeader.GetBySystemId(SalesHeader.SystemId);
            LibrarySales.PostSalesDocument(SalesHeader, false, true);
        end;

        // [GIVEN] Find Posted Sales Return Receipt
        ReturnReceiptHeader.SetFilter("Return Order No.", SalesHeader."No.");
        ReturnReceiptHeader.FindFirst();
        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.GoToRecord(ReturnReceiptHeader);

        // [WHEN] Run "Item Credit Memo Lines" action
        PostedReturnReceipt.ReturnRcptLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(Customer."No.");
        PostedReturnReceipt.ReturnRcptLines.ItemCreditMemoLines.Invoke();

        // [THEN] Verify Sales Credit Memo Lines
        // Handled by CheckSalesCreditMemoLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckSalesReturnReceiptLinesModalPageHandler')]
    procedure SalesCreditMemoForMultipleReturnReceipts_GetReturnReceiptLines()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Sales Credit Memo] [Item Return Receipt Lines]
        // [SCENARIO] Check that correct Sales Return Receipt Lines are found from Sales Credit Memo Line
        Initialize();

        // [GIVEN] Item with given Inventory
        QuantityToProcess := LibraryRandom.RandIntInRange(2, 4);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", QuantityToProcess, '', 0);

        // [GIVEN] Sales Order with one line of given Quantity
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, "Sales Line Type"::Item, Customer."No.", Item."No.", QuantityToProcess, '');

        // [GIVEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales Return Order with one line of given Quantity
        Clear(SalesHeader);
        Clear(SalesLine);
        CreateSalesReturnOrder(SalesHeader, SalesLine, "Sales Line Type"::Item, Customer."No.", Item."No.", QuantityToProcess, '');

        // [GIVEN] Return Order is shipped partially in 'Quantity' iterations, creating 'Quantity' Sales Return Receipt Lines
        for Counter := 1 to QuantityToProcess do begin
            SalesLine.GetBySystemId(SalesLine.SystemId);
            SalesLine.Validate("Return Qty. to Receive", 1);
            SalesLine.Modify();
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        // [GIVEN] Return Order is invoiced once, creating one Credit Memo with one line
        SalesLine.GetBySystemId(SalesLine.SystemId);
        SalesLine.Validate("Qty. to Invoice", QuantityToProcess);
        SalesLine.Modify();
        SalesHeader.GetBySystemId(SalesHeader.SystemId);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Find Posted Sales Credit Memo
        SalesCrMemoHeader.SetFilter("Return Order No.", SalesHeader."No.");
        SalesCrMemoHeader.FindFirst();
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GoToRecord(SalesCrMemoHeader);

        // [WHEN] Run "Item Return Receipt Lines" action
        PostedSalesCreditMemo.SalesCrMemoLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(Customer."No.");
        PostedSalesCreditMemo.SalesCrMemoLines.ItemReturnReceiptLines.Invoke();

        // [THEN] Verify Sales Return Receipt Lines
        // Handled by CheckSalesReturnReceiptLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('ServiceShipmentLinesModalPageHandler_RunItemInvoiceLines,CheckServiceInvoiceLinesModalPageHandler')]
    procedure ServiceShipmentForMultipleInvoices_GetInvoiceLines()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Service Shipment] [Item Invoice Lines]
        // [SCENARIO] Check that correct Service Invoice Lines are found from Service Shipment Line
        Initialize();

        // [GIVEN] Service Order with one line of given Quantity
        CreateRealeasedServiceOrder(ServiceHeader, '');
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();

        // [GIVEN] Item with given Inventory
        QuantityToProcess := ServiceLine.Quantity;
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", QuantityToProcess, '', 0);

        // [GIVEN] Order is received once, creating one Shipment with one line
        ServiceLine.Validate("Qty. to Ship", QuantityToProcess);
        ServiceLine.Modify();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [GIVEN] Order is invoiced partially in 'Quantity' iterations, creating 'Quantity' Service Invoice Lines
        for Counter := 1 to QuantityToProcess do begin
            ServiceLine.GetBySystemId(ServiceLine.SystemId);
            ServiceLine.Validate("Qty. to Invoice", 1);
            ServiceLine.Modify();
            ServiceHeader.GetBySystemId(ServiceHeader.SystemId);
            LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
        end;

        // [GIVEN] Find Posted Service Shipment
        ServiceShipmentHeader.SetFilter("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        PostedServiceShipment.OpenView();
        PostedServiceShipment.GoToRecord(ServiceShipmentHeader);

        // [WHEN] Run "Item Invoice Lines" action
        PostedServiceShipment.ServShipmentItemLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(ServiceHeader."Customer No.");
        PostedServiceShipment.ServShipmentItemLines.ServiceShipmentLines.Invoke();

        // [THEN] Verify Service Invoice Lines
        // Handled by ServiceShipmentLinesModalPageHandler_RunItemInvoiceLines, CheckServiceInvoiceLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckServiceShipmentLinesModalPageHandler')]
    procedure ServiceInvoiceForMultipleShipments_GetShipmentLines()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        QuantityToProcess: Decimal;
        Counter: Integer;
    begin
        // [SLICE] [555144 Refactor GetPostedDocumentLines methods to use query object]
        // [FEATURE] [Service Invoice] [Item Shipment Lines]
        // [SCENARIO] Check that correct Service Shipment Lines are found from Service Invoice Line
        Initialize();

        // [GIVEN] Service Order with one line of given Quantity
        CreateRealeasedServiceOrder(ServiceHeader, '');
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();

        // [GIVEN] Item with given Inventory
        QuantityToProcess := ServiceLine.Quantity;
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", QuantityToProcess, '', 0);

        // [GIVEN] Order is received partially in 'Quantity' iterations, creating 'Quantity' Service Shipment Lines
        for Counter := 1 to QuantityToProcess do begin
            ServiceLine.GetBySystemId(ServiceLine.SystemId);
            ServiceLine.Validate("Qty. to Ship", 1);
            ServiceLine.Modify();
            LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        end;

        // [GIVEN] Order is invoiced once, creating one Invoice with one line
        ServiceLine.GetBySystemId(ServiceLine.SystemId);
        ServiceLine.Validate("Qty. to Invoice", QuantityToProcess);
        ServiceLine.Modify();
        ServiceHeader.GetBySystemId(ServiceHeader.SystemId);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // [GIVEN] Find Posted Service Invoice
        ServiceInvoiceHeader.SetFilter("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.GoToRecord(ServiceInvoiceHeader);

        // [WHEN] Run "Item Shipment Lines" action
        PostedServiceInvoice.ServInvLines.First();
        LibraryVariableStorage.Enqueue(QuantityToProcess);
        LibraryVariableStorage.Enqueue(ServiceHeader."Customer No.");
        PostedServiceInvoice.ServInvLines.ItemShipmentLines.Invoke();

        // [THEN] Verify Service Shipment Lines
        // Handled by CheckServiceShipmentLinesModalPageHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ReserveItemsManuallyConfirmOnSalesOrderAfterPurchaseOrderWithDifferentLocation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup: Create Item with Reserve as Always. Open Sales Order page.
        Initialize();
        CreateItemWithReserveAsAlways(Item);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
          LibraryRandom.RandDec(10, 2));
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationBlue.Code);
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", 0, '');  // Taking Quantity as 0.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");

        // Exercise.
        LibraryVariableStorage.Enqueue(ReserveItemsManuallyConfirmQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(false);  // Enqueue for ConfirmHandler.
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));

        // Verify: Verification is done by ConfirmHandlerNo.

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentDateBeforeWorkDateMessageOnSalesOrderWithRequestedDeliveryDate()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequestedDeliveryDate: Date;
        OldStockOutWarning: Boolean;
    begin
        // Setup: Update Stock Out Warning on Sales Receivables Setup. Create Sales Order.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnSalesReceivablesSetup(false);
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(
          SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", LibraryRandom.RandDec(10, 2), '');
        RequestedDeliveryDate := CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'D>', WorkDate());

        // Exercise.
        LibraryVariableStorage.Enqueue(
          StrSubstNo(ShipmentDateBeforeWorkDateMsg, SalesHeader.FieldCaption("Shipment Date"), RequestedDeliveryDate, WorkDate()));  // Enqueue for MessageHandler.
        SalesLine.Validate("Requested Delivery Date", RequestedDeliveryDate);

        // Verify: Verification is done by MessageHandler.

        // Tear Down.
        UpdateStockOutWarningOnSalesReceivablesSetup(OldStockOutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemStatisticsMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure PostMultipleSalesOrdersWithItemStatisticsMatrixPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Quantity: Decimal;
        UnitPrice: Decimal;
        UnitPrice2: Decimal;
        CustomerNo: Code[20];
    begin
        // Setup: Create and Post Item Journal line. Create and Post two Sales Orders.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(10);
        UnitPrice := LibraryRandom.RandInt(10);
        UnitPrice2 := UnitPrice + LibraryRandom.RandInt(10);  // Value required for the test.
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationBlue.Code, UnitPrice);
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateAndPostSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CustomerNo, Item."No.", Quantity / 2, WorkDate(),
          LocationBlue.Code, UnitPrice, true);  // Value required for the test.
        CreateAndPostSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CustomerNo, Item."No.", Quantity / 2,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), LocationBlue.Code, UnitPrice2, true);  // Value required for the test.

        // Exercise:
        LibraryVariableStorage.Enqueue(Quantity / 2 * UnitPrice + Quantity / 2 * UnitPrice2);  // Value required for the test. Enqueue for ItemStatisticsMatrixPageHandler.
        InvokeShowMatrixOnItemStatisticsPage(Item."No.", DimColumnOption::Period);

        // Verify: Verification is done in ItemStatisticsMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPutAwayFromSalesOrderWithPartialQuantity()
    begin
        // Setup.
        Initialize();
        CreateAndPostInventoryPutAwayAndPickFromSalesOrderWithShippingAdviceComplete(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickFromSalesOrderWithPartialQuantityError()
    begin
        // Setup.
        Initialize();
        CreateAndPostInventoryPutAwayAndPickFromSalesOrderWithShippingAdviceComplete(true);  // TRUE for Show Error.
    end;

    [Test]
    [HandlerFunctions('ErrorMessagePageHandler')]
    procedure WhenSalesPostHaveAnIssueWhsRequestShouldNotBeSaved()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
        SuccessfullPost: Boolean;
        InventorySetupUpdated: Boolean;
    begin
        Initialize();

        //[GIVEN] Set Inventory Setup
        InventorySetup.Get();
        if not InventorySetup."Prevent Negative Inventory" then begin
            InventorySetup."Prevent Negative Inventory" := true;
            InventorySetup.Modify();
            InventorySetupUpdated := true;
        end;

        //[GIVEN] Create Locations with pick required and bin mandatory
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        //[GIVEN] Create an Item and post qty increase via Item Journal.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, Location.Code, Bin.Code, Quantity);

        //[GIVEN] Create Sales Order with more qty then available on inventory (not releases)
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", Quantity * 2, Location.Code);

        //[WHEN] try to Post shipment Sales Order
        SalesHeader.Ship := true;
        SuccessfullPost := SalesHeader.SendToPosting(Codeunit::"Sales-Post");

        //[THEN] Sales Order should not be posted
        Assert.IsFalse(SuccessfullPost, 'Sales Order should not be posted');

        //[THEN] Warehouse Request should not be saved
        WarehouseRequest.SetRange("Source Type", Database::"Sales Line");
        WarehouseRequest.SetRange("Source Subtype", SalesHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", SalesHeader."No.");
        Assert.IsTrue(WarehouseRequest.IsEmpty, 'Warehouse Request should not be saved');

        if InventorySetupUpdated then begin
            InventorySetup.Get();
            InventorySetup."Prevent Negative Inventory" := false;
            InventorySetup.Modify();
        end;
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,SalesShipmentLinePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentAfterSalesInvoiceWithItemCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and post Sales Order. Create Sales Invoice with Item Charge.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);  // Quantity Used for Item Charge.
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostSalesDocument(
            SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.",
            Quantity, WorkDate(), '', LibraryRandom.RandDec(50, 2), false);
        CreateSalesDocumentWithItemChargeAssignment(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, PostedDocumentNo, SalesHeader."Sell-to Customer No.", Quantity);

        // Exercise: Undo Sales Shipment.
        UndoSalesShipmentLine(PostedDocumentNo);

        // Verify: Undo Sales Shipment line.
        VerifySalesShipmentLine(PostedDocumentNo, Item."No.", Quantity, false);
        VerifySalesShipmentLine(PostedDocumentNo, Item."No.", -Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAfterUndoShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and Post Sales Order. Undo Sales Shipment.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostSalesDocument(
            SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.",
            Quantity, WorkDate(), '', LibraryRandom.RandDec(50, 2), false);  // Value required for the test.
        UndoSalesShipmentLine(PostedDocumentNo);

        // Exercise: Post Sales Order After Undo Shipment.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.

        // Verify: Undo Sales Shipment line.
        VerifySalesShipmentLine(PostedDocumentNo, Item."No.", Quantity, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoSalesShipmentForReservedQuantity()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        CannotUndoSalesDocumentWithReservation(SalesHeader."Document Type"::Order, -1);  // Undo Sales Shipment for Reserved Quantity.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoReturnReceiptForReservedQuantity()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        CannotUndoSalesDocumentWithReservation(SalesHeader."Document Type"::"Return Order", 1);  // Undo Return Receipt for Reserved Quantity.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,ReturnReceiptLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnReceiptAfterSalesInvoiceWithItemCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
        ItemChargeAssignment: Option " ",GetShipmentLines,GetReturnReceiptLines;
    begin
        // Setup: Create and post Sales Return Order. Create Sales Invoice with Charge Item and Return Receipt Lines.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);  // Quantity Used for Item Charge.
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo := CreateAndPostSalesDocument(
            SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, LibrarySales.CreateCustomerNo(),
            Item."No.", Quantity, WorkDate(), '', LibraryRandom.RandDec(50, 2), false);  // Value required for the test.
        EnqueueValuesForItemCharge(ItemChargeAssignment::GetReturnReceiptLines, PostedDocumentNo);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, SalesLine.Type::"Charge (Item)",
          SalesHeader."Sell-to Customer No.", LibraryInventory.CreateItemChargeNo(), Quantity, '');
        SalesLine.ShowItemChargeAssgnt();

        // Exercise: Undo Return Receipt Line.
        UndoReturnReceiptLine(PostedDocumentNo);

        // Verify: Undo Receipt lines.
        VerifyReturnReceiptLine(PostedDocumentNo, Item."No.", Quantity, false);
        VerifyReturnReceiptLine(PostedDocumentNo, Item."No.", -Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnReceiptWithNegativeQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and post Sales Return Order with Negative Quantity.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostSalesDocument(
            SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, LibrarySales.CreateCustomerNo(),
            Item."No.", -Quantity, WorkDate(), '', 0, false);  // Value required for the test.

        // Exercise: Undo Return Receipt Line.
        UndoReturnReceiptLine(PostedDocumentNo);

        // Verify: Undo Receipt Line for Negative Line.
        VerifyReturnReceiptLine(PostedDocumentNo, Item."No.", -Quantity, false);
        VerifyReturnReceiptLine(PostedDocumentNo, Item."No.", Quantity, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithBlockedItemError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Block Item.
        Initialize();
        CreateBlockedItem(Item);

        // Exercise: Create Sales Order.
        asserterror CreateSalesOrder(
            SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", LibraryRandom.RandDec(10, 2), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountDeletedAfterDeletingCustomerDiscountGroup()
    var
        Item: Record Item;
        CustomerDiscountGroup: Record "Customer Discount Group";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Setup: Create Item, Customer Discount Group with Sales Line Discount.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateCustomerDiscountGroupWithSalesLineDiscount(CustomerDiscountGroup, SalesLineDiscount, Item);

        // Exercise: Delete Customer Discount Group.
        CustomerDiscountGroup.Delete(true);

        // Verify: Verify Sales Line Discount must be deleted.
        FilterSalesLineDiscount(SalesLineDiscount, CustomerDiscountGroup.Code);
        Assert.IsTrue(SalesLineDiscount.IsEmpty, SalesLineDiscountMustBeDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithCustomerDiscountGroup()
    var
        Item: Record Item;
        CustomerDiscountGroup: Record "Customer Discount Group";
        SalesLineDiscount: Record "Sales Line Discount";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item, Customer Discount Group with Sales Line Discount. Create Customer with Customer Discount Group.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateCustomerDiscountGroupWithSalesLineDiscount(CustomerDiscountGroup, SalesLineDiscount, Item);

        // Exercise: Create Sales Order.
        CopyAllSalesPriceToPriceListLine();
        CreateSalesOrder(
          SalesHeader, SalesLine, SalesLine.Type::Item, CreateCustomerWithCustomerDiscountGroup(CustomerDiscountGroup.Code), Item."No.",
          SalesLineDiscount."Minimum Quantity", '');

        // Verify: Verify Sales Line for Line Discount Amount.
        VerifySalesLineForLineDiscount(SalesLine, SalesLineDiscount);
    end;

    local procedure CopyAllSalesPriceToPriceListLine()
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
    end;

    local procedure CopyAllPurchPriceToPriceListLine()
    var
        PurchPrice: Record "Purchase Price";
        PurchLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        CopyFromToPriceListLine.CopyFrom(PurchPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(PurchLineDiscount, PriceListLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentDateWarningOnRoundingAmount()
    var
        Item: Record Item;
        SalesLine: array[2] of Record "Sales Line";
        SalesOrderSubform: TestPage "Sales Order Subform";
    begin
        // [FEATURE] [Sales Order] [Rounding]
        // [SCENARIO 379798] "Shipment date XX is before work date YY" message should not be displayed on going from one sales line to another.
        Initialize();
        ClearLastError();

        // [GIVEN] Set Inventory Rounding Precision > 1.
        LibraryERM.SetInvRoundingPrecisionLCY(LibraryUtility.GenerateRandomFraction() + 1);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Order with Shipment Date before work date and two lines with rounding amount <> 0.
        CreateSalesOrderWithTwoLines(SalesLine, Item."No.", CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // [GIVEN] Run Sales Order Subform.
        SalesOrderSubform.Trap();
        PAGE.Run(PAGE::"Sales Order Subform", SalesLine[1]);

        // [WHEN] Go from one Sales Line to another.
        SalesOrderSubform.GotoRecord(SalesLine[1]);
        SalesOrderSubform.GotoRecord(SalesLine[2]);

        // [THEN] "Shipment date XX is before work date YY" message should not be displayed.
        Assert.AreEqual('', GetLastErrorText, ShipmemtDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesQuoteWithResponsibilityCenter()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldCreditWarning: Integer;
        OldStockOutWarning: Boolean;
    begin
        // Setup: Update Stock Out Warning and Credit Warning on Sales Receivables Setup. Create Item and Sales Quote with Responsibility Center.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarningOnSalesReceivablesSetup(false);
        OldCreditWarning := UpdateCreditWarningOnSalesAndReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        LibraryInventory.CreateItem(Item);
        CreateSalesQuoteWithResponsibilityCenter(SalesHeader, SalesLine, Item."No.");

        // Exercise: Create Sales Order from Sales Quote.
        LibrarySales.QuoteMakeOrder(SalesHeader);

        // Verify: Verify Sales Order created from Sales Quote.
        VerifySalesOrder(SalesHeader, SalesLine);

        // Tear Down.
        UpdateStockOutWarningOnSalesReceivablesSetup(OldStockOutWarning);
        UpdateCreditWarningOnSalesAndReceivablesSetup(OldCreditWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithSpecialOrderAndCarryOutActionMsg()
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageOnRequisitionWorksheet(true);  // Special Order as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithDropShipmentAndCarryOutActionMsg()
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageOnRequisitionWorksheet(false);  // Special Order as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderWithExactCostReversingMandatoryTrue()
    begin
        // Setup.
        Initialize();
        PostSalesReturnOrderWithExactCostReversingMandatory(true);  // ExactCostReversingMandatory as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderWithExactCostReversingMandatoryFalse()
    begin
        // Setup.
        Initialize();
        PostSalesReturnOrderWithExactCostReversingMandatory(false);  // ExactCostReversingMandatory as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayFromSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create and release Sales Return Order. Create and Post Warehouse Receipt.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesReturnOrder(SalesHeader, Item."No.", '', Quantity, LocationGreen.Code);
        CreateAndPostWarehouseReceiptFromSalesReturnOrder(SalesHeader);

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          Item."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyRegisteredPutAwayLine(SalesHeader."No.", Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInvoicedSalesReturnOrdersReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Item: Record Item;
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Return Order. Create and Post Sales Credit Memo with Get Return Receipt Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateAndReleaseSalesReturnOrder(SalesHeader, Item."No.", Customer."No.", LibraryRandom.RandDec(50, 2), '');
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as SHIP.
        CreateAndPostSalesCreditMemoAfterGetReturnReceiptLine(SalesHeader2, PostedDocumentNo, SalesHeader."Sell-to Customer No.", 0);

        // Exercise.
        SalesHeader.SetRange("No.", SalesHeader."No.");
        RunDeleteInvoicedSalesReturnOrdersReport(SalesHeader);

        // Verify.
        FilterSalesHeader(SalesHeader);
        Assert.IsTrue(SalesHeader.IsEmpty, RecordMustBeDeletedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoShipmentOfAppliedNegativeQuantity()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        UndoSalesDocumentForAppliedQuantity(SalesHeader."Document Type"::Order, -1);  // Undo Sales Shipment for Applied Quantity.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoReturnReceiptWithAppliedQuantity()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        UndoSalesDocumentForAppliedQuantity(SalesHeader."Document Type"::"Return Order", 1);  // Undo Return Receipt for Applied Quantity.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeSellToCustomerNoOnSalesOrderPage()
    var
        Customer: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        OldCreditWarning: Option;
        SalesOrderNo: Code[20];
    begin
        // Setup: Create Customer. Create Sales Order By Page.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        OldCreditWarning := UpdateCreditWarningOnSalesAndReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrderByPage(SalesOrder);

        // Exercise: Change Sell To Customer No. on Sales Order.
        SalesOrderNo := SalesOrder."No.".Value();
        EnqueueForChangeOfSellToCustomerOrBuyFromVendor();
        EnqueueForChangeOfSellToCustomerOrBuyFromVendor();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // Verify: Sell to Customer No. is Changed on Sales Order.
        SalesOrder."No.".AssertEquals(SalesOrderNo);
        SalesOrder."Sell-to Customer Name".AssertEquals(Customer.Name);

        // Tear Down.
        UpdateCreditWarningOnSalesAndReceivablesSetup(OldCreditWarning);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeCustomerNoOnServiceOrderPage()
    var
        Customer: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceOrder: TestPage "Service Order";
        OldCreditWarning: Option;
        ServiceOrderNo: Code[20];
    begin
        // Setup: Create Customer. Create Service Order By Page.
        Initialize();
        OldCreditWarning := UpdateCreditWarningOnSalesAndReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        LibrarySales.CreateCustomer(Customer);
        CreateServiceOrderByPage(ServiceOrder);

        // Exercise: Change Customer No. on Service Order.
        ServiceOrderNo := ServiceOrder."No.".Value();
        ServiceOrder."Customer No.".SetValue(Customer."No.");

        // Verify: Customer No. is Changed on Sales Order.
        ServiceOrder."No.".AssertEquals(ServiceOrderNo);
        ServiceOrder."Customer No.".AssertEquals(Customer."No.");

        // Tear Down.
        UpdateCreditWarningOnSalesAndReceivablesSetup(OldCreditWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesLineDiscountForTypeItem()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();
        CreateSalesLineDiscountWithType(SalesLineDiscount.Type::"Item Disc. Group");  // Sales Line Discount for Type Item Discount Group.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesLineDiscountForTypeItemDiscountGroup()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        Initialize();
        CreateSalesLineDiscountWithType(SalesLineDiscount.Type::Item);  // Sales Line Discount for Type Item.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithItemChargeAssignmentWithoutPartialInvoice()
    begin
        // Setup.
        Initialize();
        PostSalesOrderWithItemChargeAssignment(false);  // Partial Invoice as false.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithItemChargeAssignmentWithPartialInvoice()
    begin
        // Setup.
        Initialize();
        PostSalesOrderWithItemChargeAssignment(true);  // Partial Invoice as true.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,SalesShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentAfterPostShipment()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup2: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        PostedDocumentNo: Code[20];
        PostedDocumentNo2: Code[20];
    begin
        // Setup: Create and post Sales Order. Create another Sales Order and Apply Item charge to Posted Sales Shipment.
        Initialize();
        PostedDocumentNo := CreateAndPostSalesOrderAsShip(SalesHeader, SalesLine, Customer);
        CreateSalesDocumentWithItemChargeAssignment(
          SalesHeader2, SalesLine2, SalesHeader2."Document Type"::Order, PostedDocumentNo, SalesHeader."Sell-to Customer No.",
          SalesLine.Quantity);

        // Exercise.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);  // Post as Ship and Invoice.
        PostedDocumentNo2 := LibrarySales.PostSalesDocument(SalesHeader, false, true);  // Post as Invoice.

        // Verify.
        GeneralPostingSetup2.Get(SalesLine2."Gen. Bus. Posting Group", SalesLine2."Gen. Prod. Posting Group");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedDocumentNo, GeneralPostingSetup2."Sales Account", -SalesLine2."Line Amount");
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedDocumentNo, CustomerPostingGroup."Receivables Account",
          SalesLine2."Amount Including VAT");
        GeneralPostingSetup2.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedDocumentNo2, GeneralPostingSetup2."Sales Account", -SalesLine."Line Amount");
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedDocumentNo2, CustomerPostingGroup."Receivables Account",
          SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSeriesOnPostedWarehouseReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
    begin
        // Setup: Create Item. Create and release Purchase Order.
        Initialize();
        WarehouseSetup.Get();
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationWhite.Code);

        // Exercise.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader);

        // Verify.
        VerifyNoSeriesOnPostedWhseReceipt(Item."No.", WarehouseSetup."Posted Whse. Receipt Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSeriesOnRegisteredPutAway()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Bin: Record Bin;
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
    begin
        // Setup: Create Item. Create and release Purchase Order. Create and post Warehouse Receipt from Purchase Order.
        Initialize();
        WarehouseSetup.Get();
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationWhite.Code);
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader);

        // Exercise.
        FindBinForPickZone(Bin, LocationWhite.Code, true);
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Bin.Code, Bin."Zone Code");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyNoSeriesOnRegisteredWhseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseSetup."Registered Whse. Put-away Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSeriesOnRegisteredPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
    begin
        // Setup: Create Item. Create and release Purchase Order. Create and register Put Away after post Warehouse Receipt from Purchase Order.
        Initialize();
        WarehouseSetup.Get();
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationWhite.Code);
        RegisterPutAwayAfterPostWarehouseReceiptFromPO(PurchaseLine);

        // Exercise.
        CreateAndRegisterPickFromSalesOrder(SalesHeader, PurchaseLine);

        // Verify.
        VerifyNoSeriesOnRegisteredWhseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick, WarehouseSetup."Registered Whse. Pick Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSeriesOnPostedWarehouseShipment()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
    begin
        // Setup: Create Item. Create and release Purchase Order. Create and register Put Away after post Warehouse Receipt from Purchase Order. Create and register Pick from Sales Order.
        Initialize();
        WarehouseSetup.Get();
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationWhite.Code);
        RegisterPutAwayAfterPostWarehouseReceiptFromPO(PurchaseLine);
        CreateAndRegisterPickFromSalesOrder(SalesHeader, PurchaseLine);

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify.
        VerifyNoSeriesOnPostedWhseShipment(Item."No.", WarehouseSetup."Posted Whse. Shipment Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSeriesOnRegisteredMovement()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Update Inventory using Warehouse Journal. Create Movement from Movement Worksheet Line. Find Bin.
        Initialize();
        WarehouseSetup.Get();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        FindBinForPickZone(Bin, LocationWhite.Code, true);
        FindBinForPickZone(Bin2, LocationWhite.Code, false);
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity);
        CreateMovementFromMovementWorksheetLine(Bin, Bin2, Item."No.", Quantity);

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::" ", '', Item."No.", WarehouseActivityLine."Activity Type"::Movement);

        // Verify.
        VerifyNoSeriesOnRegisteredWhseActivityLine(
          WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::Movement,
          WarehouseSetup."Registered Whse. Movement Nos.");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,ItemChargeAssignmentMenuHandler,SalesShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithItemChargeWithPricesIncludingVATUnchecked()
    var
        SalesHeader: Record "Sales Header";
        GeneralPostingSetup: Record "General Posting Setup";
        ExpdTotalDisAmt: Decimal;
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 339745] Check total Discount Amount after posting Sales Invoice with Item Charge

        // [GIVEN] Sales Invoice with Charge Item with line discount and invoice discount.
        Initialize();

        UpdateDiscountOnSalesReceivableSetup(true);

        ExpdTotalDisAmt :=
          CreateSalesInvoiceWithItemChargeWithLnDiscAndInvDisc(
            SalesHeader, GeneralPostingSetup, false); // Prices Including VAT is disabled.

        // [WHEN] Post sales invoice.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify the total Discount Amount in Value Entry and G/L Entry.
        VerifyDiscountAmountInValueEntry(PostedDocNo, ExpdTotalDisAmt);
        VerifyDiscountAmountInGLEntry(
          PostedDocNo, GeneralPostingSetup."Sales Line Disc. Account", GeneralPostingSetup."Sales Inv. Disc. Account", ExpdTotalDisAmt);

        UpdateDiscountOnSalesReceivableSetup(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,ItemChargeAssignmentMenuHandler,SalesShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithItemChargeWithPricesIncludingVATChecked()
    var
        SalesHeader: Record "Sales Header";
        GeneralPostingSetup: Record "General Posting Setup";
        ExpdTotalDisAmt: Decimal;
        PostedDocNo: Code[20];
    begin
        // Setup: Create customer, item, create and post sales order with item.
        // Create sales invoice with charge item with line discount and invoice discount.
        Initialize();

        ExpdTotalDisAmt :=
          CreateSalesInvoiceWithItemChargeWithLnDiscAndInvDisc(
            SalesHeader, GeneralPostingSetup, true); // Prices Including VAT is enabled.

        // Exercise: Post sales invoice.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify the total Discount Amount in Value Entry.
        VerifyDiscountAmountInValueEntry(PostedDocNo, ExpdTotalDisAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActMsgForSpclOrdLinesOnReqWkshWithLocation()
    begin
        // Test when Sales Order has both Special Order and Drop Shipment lines with Loation, all Special Order lines
        // of same vendor should be created into single Purchase Order when carried out via Req. Worksheet.
        Initialize();
        CarryOutActMsgForSpclOrdLinesOnReqWksh(LocationBlue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActMsgForSpclOrdLinesOnReqWkshWithoutLocation()
    begin
        // Test when Sales Order has both Special Order and Drop Shipment lines without Location, all Special Order lines
        // of same vendor should be created into single Purchase Order when carried out via Req. Worksheet.
        Initialize();
        CarryOutActMsgForSpclOrdLinesOnReqWksh('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActMsgForDropShptLinesOnReqWkshWithLocation()
    begin
        // Test when Sales Order has both Special Order and Drop Shipment lines with Location, all Drop Shipment lines
        // of same vendor should be created into single Purchase Order when carried out via Req. Worksheet.
        Initialize();
        CarryOutActMsgForDropShptLinesOnReqWksh(LocationBlue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActMsgForDropShptLinesOnReqWkshWithoutLocation()
    begin
        // Test when Sales Order has both Special Order and Drop Shipment lines without Location, all Drop Shipment lines
        // of same vendor should be created into single Purchase Order when carried out via Req. Worksheet.
        Initialize();
        CarryOutActMsgForDropShptLinesOnReqWksh('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyPostingSalesInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Setup: Create and register Put-away from Purchase Order. Create and Register Pick from Sales Order. Post Warehouse Shipment.
        Initialize();
        GeneralSetupForRegisterPutAway(PurchaseLine);
        CreateAndRegisterPickFromSalesOrder(SalesHeader, PurchaseLine);
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        FindPostedWhseShipmentLine(
          PostedWhseShipmentLine, PostedWhseShipmentLine."Source Document"::"Sales Order", PurchaseLine."No.");

        // Exercise: Create Sales Invoice by Get Shipment Lines. Partially posting the Invoice.
        CreateAndPostSalesInvoiceAfterGetShipmentLine(
          SalesHeader, PostedWhseShipmentLine."Posted Source No.",
          SalesHeader."Sell-to Customer No.", PostedWhseShipmentLine.Quantity / 2);

        // Verify: Verify Qty. to Invoice on orignal Sales Order Line.
        VerifyQtyToInvoiceOnSalesLine(
          PurchaseLine."No.", SalesLine."Document Type"::Order, PostedWhseShipmentLine.Quantity / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyPostingSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // Setup: Create and register Put-away from Purchase Order. Create and Register Pick from Sales Order.
        // Create and Register Put-away from Sales Return Order.
        Initialize();
        GeneralSetupForRegisterPutAway(PurchaseLine);
        CreateAndRegisterPickFromSalesOrder(SalesHeader, PurchaseLine);
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        CreateAndRegisterPutAwayFromSalesReturnOrder(
          SalesHeader."Sell-to Customer No.", PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity / 2);
        FindReturnReceiptLine(ReturnReceiptLine, PurchaseLine."No.");

        // Exercise: Create Sales Credit Memo by Get Return Receipt Lines. Partially posting the Credit Memo.
        CreateAndPostSalesCreditMemoAfterGetReturnReceiptLine(
          SalesHeader, ReturnReceiptLine."Document No.", SalesHeader."Sell-to Customer No.", ReturnReceiptLine.Quantity / 2);

        // Verify: Verify Qty. to Invoice on orignal Sales Return Order Line.
        VerifyQtyToInvoiceOnSalesLine(
          PurchaseLine."No.", SalesLine."Document Type"::"Return Order", ReturnReceiptLine.Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler2')]
    [Scope('OnPrem')]
    procedure CarryOutActMsgForSpclOrdLinesOnReqWkshNewOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // Test when Sales Order has Special Order, Special Order line of same vendor should be created into single Purchase Order when carried
        // out via Req. Worksheet. If someone applies the Reserve Functionality on a new Sales Order, Purchase Special Orders should be excluded
        Initialize();

        ItemNo := CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, SalesLine);
        GetSalesOrderForSpecialOrderOnRequisitionWkshtAndCarryOutActionMsg(ItemNo);
        CreateNewSalesOrderOpenReservation(SalesHeader."Sell-to Customer No.", ItemNo, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromShipmentLineWhenSalesOrderFullReservedFromPurchaseOrder()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesHeaderNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create Purchase Order with Locaiton and Expected Receive Date = Work Date. Create Sales
        // Order with same quantity on Purchase Order. And full reserved from Purchase Order in ReserveFromCurrentLineHandler.
        // Partially post Receipt and Put-away. Then create Pick for Sales Order.
        // Create and post another supply.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        SalesHeaderNo :=
          GeneralPreparationWithPurchaseOrderAndSalesOrder(Quantity, Quantity - LibraryRandom.RandInt(5), Quantity);

        // Exercise: Create Pick from Whse. Shipment.
        asserterror CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);

        // Verify: Verify the error message pops up to prevent pick creating from another supply.
        Assert.ExpectedError(NothingToHandleErr);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromShipmentLineWhenSalesOrderPartialReservedFromPurchaseOrder()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesHeaderNo: Code[20];
        QtyOnPurchLine: Decimal;
        QtyToHandle: Decimal;
        QtyOnSalesLine: Decimal;
    begin
        // Setup: Create Item. Create Purchase Order with Locaiton and Expected Receive Date = Work Date. Create Sales
        // Order with Quantity greater than the one on Purchase Order. And partial reserved from Purchase Order in
        // ReserveFromCurrentLineHandler. Partially post Receipt and Put-away. Then create Pick for Sales Order.
        // Create and post another supply.
        Initialize();
        QtyOnPurchLine := LibraryRandom.RandIntInRange(10, 20);
        QtyToHandle := QtyOnPurchLine - LibraryRandom.RandInt(5);
        QtyOnSalesLine := QtyOnPurchLine + LibraryRandom.RandInt(5); // Make sure QtyOnSalesLine > QtyOnPurchLine.
        SalesHeaderNo :=
          GeneralPreparationWithPurchaseOrderAndSalesOrder(QtyOnPurchLine, QtyToHandle, QtyOnSalesLine);

        // Exercise: Create Pick from Whse. Shipment successfully.
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);

        // Verify: Verify Quantity in Warehouse Activity Lines.
        // 2nd pick qty = QtyOnSalesLine - QtyOnPurchLine.
        VerifyQuantityOnWarehouseActivityLine(SalesHeaderNo, QtyToHandle + (QtyOnSalesLine - QtyOnPurchLine));
    end;

    [Test]
    [HandlerFunctions('MoveNegativeSalesLinesHandler,YesConfirmHandler,SalesOrderHandler')]
    [Scope('OnPrem')]
    procedure MoveNegativeLinesFromSalesReturnOrder()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        SalesLine: Record "Sales Line";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Copy Document] [Sales] [Order] [Return Order] [Line Discount]
        // [SCENARIO 269464] "Unit Price" and "Line Discount %" are copied from sales return order to sales order when using "Move Negative Sales Lines" functionality, regardless of Sales Price and Sales Line Discount settings of the customer.
        Initialize();

        // [GIVEN] Customer "C" with set up sales price = "X1" and sales line discount = "Y1" for item "I".
        LibraryInventory.CreateItem(Item);
        CreateSalesPriceForCustomer(SalesPrice, Customer, Item."No.", 0);
        CreateSalesLineDiscount(SalesLineDiscount, Item, SalesLineDiscount."Sales Type"::Customer, Customer."No.", 0D, 0);

        // [GIVEN] Sales return order line with negative quantity for customer "C" and item "I".
        // [GIVEN] Set "Unit Price" = "X2" and "Line Discount %" = "Y2" on the return order line.
        SalesHeaderNo :=
          CreateSalesReturnOrderWithUnitPriceAndLineDiscount(Customer."No.", Item."No.", -LibraryRandom.RandInt(10));

        // [WHEN] Run "Move Negative Lines".
        FindSalesLine(SalesLine, SalesHeaderNo);
        LibraryVariableStorage.Enqueue(SalesLine."Unit Price");
        LibraryVariableStorage.Enqueue(SalesLine."Line Discount %");
        MoveNegativeLines(SalesHeaderNo);

        // [THEN] "Unit Price" = "X2", "Line Discount %" = "Y2" on the new sales order line.
        // Verifications are performed in SalesOrderHandler.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageWithSalesShipSuggestHandler,SalesShipmentLinePageHandler,ItemStatisticsMatrixPageHandler2')]
    [Scope('OnPrem')]
    procedure ViewItemStatisticsMatrixPageWithItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
        PostedDocumentNo: Code[20];
    begin
        // View that amounts for Item Charge in columns as days are correct in Item Statistics.

        // Setup
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        PostedDocumentNo :=
          CreateAndPostSalesDocument(
            SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, Customer."No.",
            Item."No.", LibraryRandom.RandIntInRange(10, 100), WorkDate(), '',
            LibraryRandom.RandDecInDecimalRange(10, 100, 2), false);

        CreatePurchaseInvoice(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Charge (Item)", LibraryPurchase.CreateVendorNo(),
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandIntInRange(1, 5));

        LibraryVariableStorage.Enqueue(PostedDocumentNo);
        LibraryVariableStorage.Enqueue(1); // Enqueue for ItemChargeAssignmentMenuHandler, choice for assignment.
        PurchaseLine.ShowItemChargeAssgnt();

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        InvokeShowMatrixOnItemStatisticsPage(Item."No.", DimColumnOption::Period);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePagePurchRcptHandler')]
    [Scope('OnPrem')]
    procedure VATIdentifierGetPostedDocLineToReverseReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        VATIdentifier: Code[20];
    begin
        // Check Purchase Return Order line has VAT Identifier = VAT Identifier from Initial Purchase Order
        // after Get Posted Document Lines to Reverse
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Post Purchase Order (Receipt) and Create Purchase Return Order and Get Posted Document Lines to Reverse
        LibraryVariableStorage.Enqueue(CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            LibraryRandom.RandInt(50), false));
        VATIdentifier := GetPurchLineVATIdentifier(PurchaseHeader."No.");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");
        GetPostedDocumentLines(PurchaseHeader."No.");

        // Verify Purchase Return Order line has VAT Identifier = VAT Identifier from Initial Purchase Order
        VerifyPurchLineVATIdentifier(PurchaseHeader."No.", PurchaseHeader."Document Type", VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextForMoveNegativeLinesOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ItemNo: array[2] of Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Extended Text]
        // [SCENARIO 376033] Move Negative Lines should not copy Extended Text lines that are attached to Sales Lines with positive Quantity
        Initialize();

        // [GIVEN] Sales Order with two Lines
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [GIVEN] Sales Order Line with Quantity > 0; Extended Text = "T1"
        ItemNo[1] := CreateItemWithExtText();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo[1], LibraryRandom.RandInt(100));
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true) then
            TransferExtendedText.InsertSalesExtText(SalesLine);

        // [GIVEN] Sales Order Line with Quantity < 0; Extended Text = "T2"
        ItemNo[2] := CreateItemWithExtText();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo[2], -LibraryRandom.RandInt(100));
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true) then
            TransferExtendedText.InsertSalesExtText(SalesLine);

        // [WHEN] Move Negative Lines
        MoveNegativeLinesOnSalesOrder(SalesHeader);

        // [THEN] Sales Return Order is created with "T2" Line but not with "T1" Line
        FilterSalesReturnExtLine(SalesLine, CustomerNo);
        SalesLine.SetRange(Description, ItemNo[2]);
        Assert.AreEqual(1, SalesLine.Count, ExtendedTextErr);
        SalesLine.SetRange(Description, ItemNo[1]);
        Assert.AreEqual(0, SalesLine.Count, ExtendedTextErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterShimpentDateInSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Sales Order] [Reservation]
        // [SCENARIO] Validating Shimpent Date in Sales Order should validate Shipment Date in appropriate Reservation Entry
        Initialize();

        // [GIVEN] Sales Order with "Shipment Date" = "X"
        LibraryInventory.CreateItem(Item);
        UpdateItemReserveField(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipment Date", WorkDate());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] Set "Shipment Date" to "Y"
        SalesHeader.Validate("Shipment Date", WorkDate() + 1);
        SalesHeader.Modify(true);

        // [THEN] Appropriate Reservation Entry has "Shipment Date" = "Y"
        ReservEntry.SetRange("Item No.", Item."No.");
        ReservEntry.FindFirst();
        ReservEntry.TestField("Shipment Date", WorkDate() + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedSalesReturnOrderUom()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Return Order] [Unit of Measure] [UT]
        // [SCENARIO 376171] Validating of Unit of Measure code should be prohibited if "Return Qty. Received" is not zero.
        Initialize();

        // [GIVEN] Sales Return Order Line with "Return Qty. Received " <> 0
        CreateSalesOrderWithQuantityReceived(SalesLine, 0, LibraryRandom.RandInt(10));

        // [WHEN] Validate Unit Of Measure Code
        asserterror SalesLine.Validate("Unit of Measure Code");

        // [THEN] Error is thrown: "Return Qty. Received must be equal to '0'  in Purchase Line"
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Return Qty. Received"), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedSalesReturnOrderUomBase()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Return Order] [Unit of Measure] [UT]
        // [SCENARIO 376171] Validating of Unit of Measure code should be prohibited if "Return Qty. Received (Base)" is not zero.
        Initialize();

        // [GIVEN] Sales Return Order Line with "Return Qty. Received (Base)" <> 0
        CreateSalesOrderWithQuantityReceived(SalesLine, LibraryRandom.RandInt(10), 0);

        // [WHEN] Validate Unit Of Measure Code
        asserterror SalesLine.Validate("Unit of Measure Code");

        // [THEN] Error is thrown: "Return Qty. Received (Base) must be equal to '0'  in Purchase Line"
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Return Qty. Received (Base)"), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderShipmentLinesShowSourceDocLines()
    var
        ServiceOrder: TestPage "Service Order";
        WhseShipmentLines: TestPage "Whse. Shipment Lines";
        ServiceLineList: TestPage "Service Line List";
    begin
        // [FEATURE] [Service Order] [Warehouse Shipment] [UI]
        // [SCENARIO 380715] When Warehouse Shipment is created from Service Order then action Show Source Document Line of Whse. Shipment Lines page shows related Service Line List page.
        Initialize();

        // [GIVEN] Service Order and Warehouse Shipment for it, page of Service Order is opened.
        CreateServiceOrderAndShipment(ServiceOrder);

        // [GIVEN] Whse. Shipment Lines page for this Service Order is opened.
        WhseShipmentLines.Trap();
        ServiceOrder."Warehouse Shipment Lines".Invoke();

        // [WHEN] Invoke action Show Source Document Line of Whse. Shipment Lines
        ServiceLineList.Trap();
        WhseShipmentLines.ShowSourceDocumentLine.Invoke();

        // [THEN] Page Service Line List opens and its "Document No." is the same as Service Order "No.".
        Assert.AreEqual(ServiceOrder."No.".Value, ServiceLineList."Document No.".Value, ServiceNoMismatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetShipmentLinesWithExtendedText()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Extended Text]
        // [SCENARIO 376583] Get Shipment Lines Job should copy "Attached to Line No." for Extended Text Lines
        Initialize();

        // [GIVEN] Shipped Sales Order with Line "X" and Extended Text Line "Y" attached to "X"
        PostedDocumentNo := CreateAndPostSalesOrderWithExtendedText(SalesHeader."Document Type"::Order, CustomerNo, ItemNo);

        // [GIVEN] Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [WHEN] Get Shipment Lines
        GetShipmentLine(SalesHeader, PostedDocumentNo, 0);

        // [THEN] Sales Invloice Line "Y" is attached to "X"
        VerifyExtSalesLine(SalesHeader."No.", ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetReturnReceiptLinesWithExtendedText()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Extended Text]
        // [SCENARIO 376583] Get Return Receipt Lines Job should copy "Attached to Line No." for Extended Text Lines
        Initialize();

        // [GIVEN] Shipped Sales Return Order with Line "X" and Extended Text Line "Y" attached to "X"
        PostedDocumentNo := CreateAndPostSalesOrderWithExtendedText(SalesHeader."Document Type"::"Return Order", CustomerNo, ItemNo);

        // [GIVEN] Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Get Return Receipt Lines
        GetReturnReceiptLine(SalesHeader, PostedDocumentNo, 0);

        // [THEN] Sales Creadit Memo Line "Y" is attached to "X"
        VerifyExtSalesLine(SalesHeader."No.", ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNotShippedIfPostingFails()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 382353] "Ship" field in sales order should not be updated if posting of shipment failed due to dimension check error.
        Initialize();

        // [GIVEN] Enable "Calc. Inv. Discount" in Sales & Receivables setup.
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Customer "C" with default dimension "D" that is set to have a mandatory value.
        CreateCustomerWithMandatoryDimensionValueCode(Customer);

        // [GIVEN] Sales Order for customer "C". Mandatory value for dimension "D" in the order has not been selected.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item, Customer."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '');

        // Commit is required so the sales order will not be rolled back on posting error.
        Commit();

        // [WHEN] Post the sales order with "Ship" option.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "Ship" field in the sales order = FALSE.
        SalesHeader.Find();
        SalesHeader.TestField(Ship, false);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSubstitutionAutoReservationSpecifiedQuantity()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Substitution] [Reservation]
        // [SCENARIO 206142] When item substition from Item "I" to Substitution Item "S" is done through Sales Order Page, "S" is autoreserved if its Property Reserve = Always, no error occurs when changing back to "I".

        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Sales Oder "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateSalesOrderSingleLineAutoReservedSpecifiedQuantity(SalesHeader, SalesLine, Item."No.", Quantity);

        // [WHEN] Select Item Substitution through Sales Order Page and changing "I" to "S"
        SelectItemSubstitutionThroughSalesOrderPage(SalesHeader, SalesOrder);

        // [THEN] "SL" contains "S" as "No.", "S" also is autoreserved, quantity is the same;
        VerifySalesLineByItemNoWithReservation(SalesLine, SubstitutionItem."No.");

        // [GIVEN] Drop current reservation;
        SalesLineReserve.DeleteLine(SalesLine);

        // [WHEN] Set "I" to "SL" through Sales Order Page
        SetLineItemNoThroughSalesOrderPage(SalesOrder, Item."No.");

        // [THEN] "SL" contains "I" as "No.", "I" also is autoreserved, no error occured, quantity is the same.
        VerifySalesLineByItemNoWithReservation(SalesLine, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSubstitutionAutoReservationDefaultQuantity()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Substitution] [Reservation]
        // [SCENARIO 207723] When "Default Item Quantity" is enabled in "Sales & Receivables Setup" item substition from Item "I" to Substitution Item "S" is done through Sales Order Page, "S" is autoreserved if its Property Reserve = Always, no error occu

        Initialize();

        // [GIVEN] "Default Item Quantity" is enabled in "Sales & Receivables Setup";
        EnableSalesReceivablesSetupDefaultItemQuantity();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, 1);

        // [GIVEN] Sales Oder "SO" with single Line "SL" for "I", quantity isn't specified during creation and is one (automatic), line is autoreserved from Inventory;
        CreateSalesOrderSingleLineAutoReservedUnspecifiedQuantity(SalesHeader, SalesLine, Item."No.");

        // [WHEN] Select Item Substitution through Sales Order Page and changing "I" to "S"
        SelectItemSubstitutionThroughSalesOrderPage(SalesHeader, SalesOrder);

        // [THEN] "SL" contains "S" as "No.", "S" also is autoreserved, quantity is the same - one;
        VerifySalesLineByItemNoWithReservation(SalesLine, SubstitutionItem."No.");

        // [GIVEN] Drop current reservation;
        SalesLineReserve.DeleteLine(SalesLine);

        // [WHEN] Set "I" to "SL" through Sales Order Page
        SetLineItemNoThroughSalesOrderPage(SalesOrder, Item."No.");

        // [THEN] "SL" contains "I" as "No.", "I" also is autoreserved, no error occured, quantity is the same - one.
        VerifySalesLineByItemNoWithReservation(SalesLine, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ServiceItemSubstitutionsOKModalPageHandler,ServiceLinesSelectItemSubstitutionAndRevertToOldNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderSubstitutionAutoReservationSpecifiedQuantity()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Service] [Substitution] [Reservation]
        // [SCENARIO 206142] When item substition from Item "I" to Substitution Item "S" is done through Service Order Page, "S" is autoreserved if its Property Reserve = Always, no error occurs when changing back to "I".

        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Service Oder "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateServiceOrderSingleLine(ServiceHeader, ServiceLine, Item."No.", Quantity);

        // [WHEN] Select Item Substitution through Service Order Page and changing "I" to "S"
        // [THEN] "SL" contains "S" as "No.", "S" also is autoreserved, quantity is the same;
        // [GIVEN] Drop current reservation;
        // [WHEN] Set "I" to "SL" through Service Order Page
        // [THEN] "SL" contains "I" as "No.", "I" also is autoreserved, no error occured, quantity is the same.
        SelectItemSubstitutionAndRevertItemNoThroughServiceOrderPage(ServiceHeader, SubstitutionItem."No.");
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderSubstitutionAutoReservationSpecifiedQuantity()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ProdOrderComponents: TestPage "Prod. Order Components";
        Quantity: Decimal;
    begin
        // [FEATURE] [Production Order] [Substitution] [Reservation]
        // [SCENARIO 206142] When item substition from Item "I" to Substitution Item "S" is done through Production Order Page, "S" is autoreserved if its Property Reserve = Always, no error occurs when changing back to "I".

        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Production Oder "PO" with single Line "L" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdOrderComponent, Item."No.", Quantity);

        // [WHEN] Select Item Substitution through Production Order Page and changing "I" to "S"
        SelectItemSubstitutionThroughProductionOrderPage(ProductionOrder, ReleasedProductionOrder, ProdOrderComponents);

        // [THEN] "L" contains "S" as "No.", "S" also is autoreserved, quantity is the same;
        VerifyProdOrderComponentByItemNoWithReservation(ProdOrderComponent, SubstitutionItem."No.");

        // [GIVEN] Drop current reservation;
        ProdOrderCompReserve.DeleteLine(ProdOrderComponent);

        // [WHEN] Set "I" to "L" through Production Order Page
        SetItemNoThroughProdOrderComponentsPage(ReleasedProductionOrder, ProdOrderComponents, Item."No.");

        // [THEN] "L" contains "I" as "No.", "I" also is autoreserved, no error occured, quantity is the same.
        VerifyProdOrderComponentByItemNoWithReservation(ProdOrderComponent, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderSubstitutionAutoReservationSpecifiedQuantity()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AssemblyOrder: TestPage "Assembly Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Assembly Order] [Substitution] [Reservation]
        // [SCENARIO 206142] When item substition from Item "I" to Substitution Item "S" is done through Assembly Order Page, "S" is autoreserved if its Property Reserve = Always, no error occurs when changing back to "I".

        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Assembly Oder "AO" with single Line "L" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateAssemblyOrder(AssemblyHeader, AssemblyLine, Item."No.", Quantity);

        // [WHEN] Select Item Substitution through Assembly Order Page and changing "I" to "S"
        SelectItemSubstitutionThroughAssemblyOrderPage(AssemblyHeader, AssemblyOrder);

        // [THEN] "L" contains "S" as "No.", "S" also is autoreserved, quantity is the same;
        VerifyAssemblyLineByItemNoWithReservation(AssemblyLine, SubstitutionItem."No.");

        // [GIVEN] Drop current reservation;
        AssemblyLineReserve.DeleteLine(AssemblyLine);

        // [WHEN] Set "I" to "L" through Assembly Order Page
        SetItemNoThroughAssemblyOrderPage(AssemblyOrder, Item."No.");

        // [THEN] "L" contains "I" as "No.", "I" also is autoreserved, no error occured, quantity is the same.
        VerifyAssemblyLineByItemNoWithReservation(AssemblyLine, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSubstitutionAutoReservationThroughFactBox()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Substitution] [Reservation]
        // [SCENARIO 209766] When item substition from Item "I" to Substitution Item "S" is done through Sales Order Page Fact Box Area, "S" is autoreserved if its Property Reserve = Always, no error occurs when changing back to "I".

        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Sales Oder "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateSalesOrderSingleLineAutoReservedSpecifiedQuantity(SalesHeader, SalesLine, Item."No.", Quantity);

        // [WHEN] Select Item Substitution through Sales Order Page Fact Box Area and changing "I" to "S"
        SelectItemSubstitutionThroughSalesOrderPageFactBox(SalesHeader, SalesOrder);

        // [THEN] "SL" contains "S" as "No.", "S" also is autoreserved, quantity is the same;
        VerifySalesLineByItemNoWithReservation(SalesLine, SubstitutionItem."No.");

        // [GIVEN] Drop current reservation;
        SalesLineReserve.DeleteLine(SalesLine);

        // [WHEN] Set "I" to "SL" through Sales Order Page
        SetLineItemNoThroughSalesOrderPage(SalesOrder, Item."No.");

        // [THEN] "SL" contains "I" as "No.", "I" also is autoreserved, no error occured, quantity is the same.
        VerifySalesLineByItemNoWithReservation(SalesLine, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSubstitutionAutoReservationCancelLookup()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Substitution] [Reservation]
        // [SCENARIO 206142] When the reservation of item has been canceled, looking up item substitutions through sales order page does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Sales Order "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateSalesOrderSingleLineAutoReservedSpecifiedQuantity(SalesHeader, SalesLine, Item."No.", Quantity);

        // [GIVEN] Drop current reservation.
        SalesLineReserve.DeleteLine(SalesLine);

        // [WHEN] Look up item substitutions through Sales Order page but cancel the choice.
        SelectItemSubstitutionThroughSalesOrderPage(SalesHeader, SalesOrder);

        // [THEN] Item no. on the sales line is not changed.
        // [THEN] The line is not reserved.
        SalesLine.Find();
        SalesLine.TestField("No.", Item."No.");
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesSelectItemSubstitutionModalPageHandler,ServiceItemSubstitutionsCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderSubstitutionAutoReservationCancelLookup()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        ServiceOrder: TestPage "Service Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Service] [Substitution] [Reservation]
        // [SCENARIO 206142] When the reservation of item has been canceled, looking up item substitutions through service order page does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Service Order "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateServiceOrderSingleLine(ServiceHeader, ServiceLine, Item."No.", Quantity);

        // [GIVEN] Drop current reservation.
        ServiceLineReserve.DeleteLine(ServiceLine);

        // [WHEN] Look up item substitutions through Service Order page but cancel the choice.
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] Item no. on the service line is not changed.
        // [THEN] The line is not reserved.
        ServiceLine.Find();
        ServiceLine.TestField("No.", Item."No.");
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderSubstitutionAutoReservationCancelLookup()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ProdOrderComponents: TestPage "Prod. Order Components";
        Quantity: Decimal;
    begin
        // [FEATURE] [Production Order] [Substitution] [Reservation]
        // [SCENARIO 206142] When the reservation of item has been canceled, looking up item substitutions through production order page does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Production Order "PO" with single Line "L" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdOrderComponent, Item."No.", Quantity);

        // [GIVEN] Drop current reservation;
        ProdOrderCompReserve.DeleteLine(ProdOrderComponent);

        // [WHEN] Look up item substitutions through Production Order page but cancel the choice.
        SelectItemSubstitutionThroughProductionOrderPage(ProductionOrder, ReleasedProductionOrder, ProdOrderComponents);

        // [THEN] Item no. on the prod. order component is not changed.
        // [THEN] The component is not reserved.
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Item No.", Item."No.");
        ProdOrderComponent.CalcFields("Reserved Quantity");
        ProdOrderComponent.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderSubstitutionAutoReservationCancelLookup()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AssemblyOrder: TestPage "Assembly Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Assembly Order] [Substitution] [Reservation]
        // [SCENARIO 206142] When the reservation of item has been canceled, looking up item substitutions through assembly order page does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Assembly Oder "AO" with single Line "L" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateAssemblyOrder(AssemblyHeader, AssemblyLine, Item."No.", Quantity);

        // [GIVEN] Drop current reservation;
        AssemblyLineReserve.DeleteLine(AssemblyLine);

        // [WHEN] Look up item substitutions through Assembly Order page but cancel the choice.
        SelectItemSubstitutionThroughAssemblyOrderPage(AssemblyHeader, AssemblyOrder);

        // [THEN] Item no. on the assembly line is not changed.
        // [THEN] The line is not reserved.
        AssemblyLine.Find();
        AssemblyLine.TestField("No.", Item."No.");
        AssemblyLine.CalcFields("Reserved Quantity");
        AssemblyLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesCancelModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSubstitutionAutoReservationThroughFactBoxCancelLookup()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Substitution] [Reservation]
        // [SCENARIO 206142] When the reservation of item has been canceled, looking up item substitutions through sales order factbox does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, both Reserve = Always;
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Sales Oder "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateSalesOrderSingleLineAutoReservedSpecifiedQuantity(SalesHeader, SalesLine, Item."No.", Quantity);

        // [GIVEN] Drop current reservation;
        SalesLineReserve.DeleteLine(SalesLine);

        // [WHEN] Look up item substitutions through Sales order factbox but cancel the choice.
        SelectItemSubstitutionThroughSalesOrderPageFactBox(SalesHeader, SalesOrder);

        // [THEN] Item no. on the sales line is not changed.
        // [THEN] The line is not reserved.
        SalesLine.Find();
        SalesLine.TestField("No.", Item."No.");
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSubstitutionAutoReservationSelectNoReserveItem()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Substitution] [Reservation]
        // [SCENARIO 206142] Selecting substitution item with Reserve <> Always through sales order page does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, item "I" has Reserve = Always, item "S" has Reserve = Optional.
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithOptionalReserveSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Sales Order "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateSalesOrderSingleLineAutoReservedSpecifiedQuantity(SalesHeader, SalesLine, Item."No.", Quantity);

        // [GIVEN] Drop current reservation.
        SalesLineReserve.DeleteLine(SalesLine);

        // [WHEN] Look up item substitutions through Sales Order page and select item "S".
        SelectItemSubstitutionThroughSalesOrderPage(SalesHeader, SalesOrder);

        // [THEN] Item no. on the sales line is changed to "S".
        // [THEN] The line is not reserved.
        SalesLine.Find();
        SalesLine.TestField("No.", SubstitutionItem."No.");
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesSelectItemSubstitutionModalPageHandler,ServiceItemSubstitutionsOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderSubstitutionAutoReservationSelectNoReserveItem()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        ServiceOrder: TestPage "Service Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Service] [Substitution] [Reservation]
        // [SCENARIO 206142] Selecting substitution item with Reserve <> Always through service order page does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, item "I" has Reserve = Always, item "S" has Reserve = Optional.
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithOptionalReserveSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Service Order "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateServiceOrderSingleLine(ServiceHeader, ServiceLine, Item."No.", Quantity);

        // [GIVEN] Drop current reservation.
        ServiceLineReserve.DeleteLine(ServiceLine);

        // [WHEN] Look up item substitutions through Service Order page and select item "S".
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] Item no. on the service line is changed to "S".
        // [THEN] The line is not reserved.
        ServiceLine.Find();
        ServiceLine.TestField("No.", SubstitutionItem."No.");
        ServiceLine.CalcFields("Reserved Quantity");
        ServiceLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderSubstitutionAutoReservationSelectNoReserveItem()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ProdOrderComponents: TestPage "Prod. Order Components";
        Quantity: Decimal;
    begin
        // [FEATURE] [Production Order] [Substitution] [Reservation]
        // [SCENARIO 206142] Selecting substitution item with Reserve <> Always through production order page does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, item "I" has Reserve = Always, item "S" has Reserve = Optional.
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithOptionalReserveSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Production Order "PO" with single Line "L" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdOrderComponent, Item."No.", Quantity);

        // [GIVEN] Drop current reservation;
        ProdOrderCompReserve.DeleteLine(ProdOrderComponent);

        // [WHEN] Look up item substitutions through Production Order page and select item "S".
        SelectItemSubstitutionThroughProductionOrderPage(ProductionOrder, ReleasedProductionOrder, ProdOrderComponents);

        // [THEN] Item no. on the prod. order component is changed to "S".
        // [THEN] The component is not reserved.
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Item No.", SubstitutionItem."No.");
        ProdOrderComponent.CalcFields("Reserved Quantity");
        ProdOrderComponent.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderSubstitutionAutoReservationSelectNoReserveItem()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AssemblyOrder: TestPage "Assembly Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Assembly Order] [Substitution] [Reservation]
        // [SCENARIO 206142] Selecting substitution item with Reserve <> Always through assembly order page does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, item "I" has Reserve = Always, item "S" has Reserve = Optional.
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithOptionalReserveSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Assembly Order "AO" with single Line "L" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateAssemblyOrder(AssemblyHeader, AssemblyLine, Item."No.", Quantity);

        // [GIVEN] Drop current reservation;
        AssemblyLineReserve.DeleteLine(AssemblyLine);

        // [WHEN] Look up item substitutions through Assembly Order page and select item "S".
        SelectItemSubstitutionThroughAssemblyOrderPage(AssemblyHeader, AssemblyOrder);

        // [THEN] Item no. on the assembly line is changed to "S".
        // [THEN] The line is not reserved.
        AssemblyLine.Find();
        AssemblyLine.TestField("No.", SubstitutionItem."No.");
        AssemblyLine.CalcFields("Reserved Quantity");
        AssemblyLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSubstitutionAutoReservationThroughFactBoxSelectNoReserveItem()
    var
        Item: Record Item;
        SubstitutionItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Substitution] [Reservation]
        // [SCENARIO 206142] Selecting substitution item with Reserve <> Always through sales order factbox does not invoke auto-reservation.
        Initialize();

        // [GIVEN] Item "I" and the "Item Substitution" "S" for it, both sufficient inventory, item "I" has Reserve = Always, item "S" has Reserve = Optional.
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateAutoReserveItemWithOptionalReserveSubstitution(Item, SubstitutionItem, Quantity);

        // [GIVEN] Sales Order "SO" with single Line "SL" for "I", some quantity is specified during creation, line is autoreserved from Inventory;
        CreateSalesOrderSingleLineAutoReservedSpecifiedQuantity(SalesHeader, SalesLine, Item."No.", Quantity);

        // [GIVEN] Drop current reservation;
        SalesLineReserve.DeleteLine(SalesLine);

        // [WHEN] Look up item substitutions through Sales order factbox and select item "S".
        SelectItemSubstitutionThroughSalesOrderPageFactBox(SalesHeader, SalesOrder);

        // [THEN] Item no. on the sales line is changed to "S".
        // [THEN] The line is not reserved.
        SalesLine.Find();
        SalesLine.TestField("No.", SubstitutionItem."No.");
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineBlankTypeDifferentBillToCustomerNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 222055] When Sales Document has lines with blank Type it is possible to set "Bill-to Customer No." different with "Sell-to Customer No."
        Initialize();

        // [GIVEN] Sales Order with Header "H" and Line "L", "L" has blank Type
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", '', 0);
        SalesLine.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(SalesLine.Description)));

        // [WHEN] Set in "H" "Bill-to Customer No." the value "C" different with "Sell-to Customer No."
        CustomerNo := LibrarySales.CreateCustomerNo();
        SalesHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);

        // [THEN] no error occurs and "H"."Bill-to Customer No." = "C"
        SalesHeader.TestField("Bill-to Customer No.", CustomerNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineBlankTypeDifferentPayToVendorNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 222055] When Purchase Document has lines with blank Type it is possible to set "Pay-to Vendor No." different with "Buy-from Vendor No."
        Initialize();

        // [GIVEN] Purchase Order with Header "H" and Line "L", "L" has blank Type
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::" ", '', 0);
        PurchaseLine.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseLine.Description)));

        // [WHEN] Set in "H" "Pay-to Vendor No." the value "V" different with "Buy-from Vendor No."
        VendorNo := LibraryPurchase.CreateVendorNo();
        PurchaseHeader.Validate("Pay-to Vendor No.", VendorNo);
        PurchaseHeader.Modify(true);

        // [THEN] no error occurs and "H"."Pay-to Vendor No." = "V"
        PurchaseHeader.TestField("Pay-to Vendor No.", VendorNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoUnappliedJobRelatedPurchaseReceipt()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Purchase] [Undo Receipt] [Job] [Item Application]
        // [SCENARIO 230497] No errors occur because of item application when undo receipt of received job related purchase order with unapplied item operations
        Initialize();

        // [GIVEN] Item "I" with type Service
        CreateItemWithTypeService(Item);

        UndoReceiptOfReceivedJobAndVerifyQuantitiesOfLedger(Item);

        // [GIVEN] Item "I" with type Non-Inventory
        LibraryInventory.CreateNonInventoryTypeItem(Item);

        UndoReceiptOfReceivedJobAndVerifyQuantitiesOfLedger(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountIsNotResetWhenSetSalesLineForDropShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineDiscPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Drop Shipment] [Line Discount] [UT]
        // [SCENARIO 277278] "Line Discount %" is not reset when a user sets a mark in "Drop Shipment" field on sales line.
        Initialize();

        LineDiscPercent := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Create a sales order and set "Line Discount %" = "X" on the sales line.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesLine.Validate("Line Discount %", LineDiscPercent);
        SalesLine.Modify(true);

        // [WHEN] Set "Drop Shipment" to TRUE on the sales line.
        SalesLine.Validate("Drop Shipment", true);

        // [THEN] "Line Discount %" is equal to "X".
        SalesLine.TestField("Line Discount %", LineDiscPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountIsNotResetWhenSetPurchasingCodeOnSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineDiscPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Drop Shipment] [Line Discount] [UT]
        // [SCENARIO 277278] "Line Discount %" is not reset when a user selects a purchasing code for drop shipment on sales line.
        Initialize();

        LineDiscPercent := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Create a sales order and set "Line Discount %" = "X" on the sales line.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesLine.Validate("Line Discount %", LineDiscPercent);
        SalesLine.Modify(true);

        // [WHEN] Select a purchasing code for drop shipment on the sales line.
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));

        // [THEN] "Line Discount %" is equal to "X".
        SalesLine.TestField("Line Discount %", LineDiscPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountPercIsZeroWhenAllowLineDiscDisabledOnCustomer()
    var
        Item: Record Item;
        Customer: Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        SalesLineDiscount: Record "Sales Line Discount";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Line Discount] [Customer Discount Group] [Sales Line Discount]
        // [SCENARIO 283694] "Line Discount %" on sales lines is 0 when "Allow Line Disc." is disabled in customer.
        Initialize();

        // [GIVEN] Item "I".
        // [GIVEN] Customer discount group "DISC".
        // [GIVEN] Set sales line discount for customer discount group "DISC" and item "I".
        LibraryInventory.CreateItem(Item);
        CreateCustomerDiscountGroupWithSalesLineDiscount(CustomerDiscountGroup, SalesLineDiscount, Item);

        // [GIVEN] Customer "C" with customer discount group "DISC" and disabled "Allow Line Disc." setting.
        Customer.Get(CreateCustomerWithCustomerDiscountGroup(CustomerDiscountGroup.Code));
        Customer.Validate("Allow Line Disc.", false);
        Customer.Modify(true);

        // [GIVEN] Sales order for customer "C" and item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Item."No.");

        // [WHEN] Set non-zero quantity on the sales line in order to calculate "Line Discount %".
        SalesLine.Validate(Quantity, LibraryRandom.RandInt(10));

        // [THEN] "Line Discount %" on the sales line is zero.
        SalesLine.TestField("Line Discount %", 0);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderWithOrderTrackingCannotBePostedWithoutAppliedEntry()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Return Order] [Exact Cost Reversing Mandatory] [Order Tracking]
        // [SCENARIO 292638] Exact Cost Reversing Mandatory setting blocks posting sales return order with blank Applies-from Item Entry field.
        Initialize();

        // [GIVEN] "Exact Cost Reversing Mandatory" is enabled in Sales & Receivables Setup.
        LibrarySales.SetExactCostReversingMandatory(true);

        // [GIVEN] Item set up for order tracking.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Sales order.
        Qty := LibraryRandom.RandInt(10);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());

        // [GIVEN] Sales return order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', Item."No.", Qty, '', WorkDate());

        // [WHEN] Receive the sales return.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "Applies-from Item Entry must have a value..." error message is thrown.
        Assert.ExpectedError(ApplFromItemEntryBlankErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderWithOrderTrackingCannotBePostedWithoutAppliedEntry()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order] [Exact Cost Reversing Mandatory] [Order Tracking]
        // [SCENARIO 292638] Exact Cost Reversing Mandatory setting blocks posting purchase return order with blank Applies-to Item Entry field.
        Initialize();

        // [GIVEN] "Exact Cost Reversing Mandatory" is enabled in Purchases & Payables Setup.
        LibraryPurchase.SetExactCostReversingMandatory(true);

        // [GIVEN] Item set up for order tracking.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Purchase order.
        Qty := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());

        // [GIVEN] Purchase return order.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Item."No.", Qty, '', WorkDate());

        // [WHEN] Ship the purchase return.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] "Applies-to Item Entry must have a value..." error message is thrown.
        Assert.ExpectedError(ApplToItemEntryBlankErr);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderReservedForOrderCannotBePostedWithoutAppliedEntry()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Return Order] [Order] [Reservation] [Exact Cost Reversing Mandatory]
        // [SCENARIO 292638] Sales return order reserved for an active sales order cannot be posted without "Applies-from Item Entry" when Exact Cost Reversing Mandatory setting is on.
        Initialize();

        // [GIVEN] "Exact Cost Reversing Mandatory" is enabled in Sales & Receivables Setup.
        LibrarySales.SetExactCostReversingMandatory(true);

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales order.
        Qty := LibraryRandom.RandInt(10);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());

        // [GIVEN] Sales return order reserved for the sales order.
        // [GIVEN] Leave "Applied-to Item Entry" field blank.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', Item."No.", Qty, '', WorkDate());
        SalesLine.ShowReservation();

        // [WHEN] Receive the sales return.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "Applies-from Item Entry must have a value..." error message is thrown.
        Assert.ExpectedError(ApplFromItemEntryBlankErr);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderReservedFromInventoryCanBePostedWithoutAppliedEntry()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order] [Order] [Reservation] [Exact Cost Reversing Mandatory]
        // [SCENARIO 292638] Purchase return order reserved from inventory does not require "Applies-to Item Entry" to be populated even if Exact Cost Reversing Mandatory setting is on.
        Initialize();

        // [GIVEN] "Exact Cost Reversing Mandatory" is enabled in Purchases & Payables Setup.
        LibraryPurchase.SetExactCostReversingMandatory(true);

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order.
        Qty := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());

        // [GIVEN] Post the purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Purchase return order reserved from the inventory.
        // [GIVEN] Leave "Applied-to Item Entry" field blank.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Item."No.", Qty, '', WorkDate());
        PurchaseLine.ShowReservation();

        // [WHEN] Ship the purchase return.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The purchase return is successfully posted.
        PurchaseLine.Find();
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderReservedFromOrderCannotBePostedWithoutAppliedEntry()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order] [Order] [Reservation] [Exact Cost Reversing Mandatory]
        // [SCENARIO 292638] Purchase return order reserved from an active purchase order cannot be posted without "Applies-to Item Entry" when Exact Cost Reversing Mandatory setting is on.
        Initialize();

        // [GIVEN] "Exact Cost Reversing Mandatory" is enabled in Purchases & Payables Setup.
        LibraryPurchase.SetExactCostReversingMandatory(true);

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order.
        Qty := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());

        // [GIVEN] Purchase return order reserve from the purchase order.
        // [GIVEN] Leave "Applied-to Item Entry" field blank.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Item."No.", Qty, '', WorkDate());
        PurchaseLine.ShowReservation();

        // [WHEN] Ship the purchase return.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] "Applies-to Item Entry must have a value..." error message is thrown.
        Assert.ExpectedError(ApplToItemEntryBlankErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineIsProperlyUpdatedAfterPostingPurchaseLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Jobs] [Job Planning Line]
        // [SCENARIO 355575] Job planning line remaining quantity is properly updated on posting several purchase lines.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Job, Job Task and Job Planning Line with item "I" and quantity = 90.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 3 * Qty);
        JobPlanningLine.Modify(true);

        // [GIVEN] A purchase order with two lines, each for item "I" and quantity = 30.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithJob(PurchaseLine, PurchaseHeader, JobPlanningLine, Qty);
        CreatePurchaseLineWithJob(PurchaseLine, PurchaseHeader, JobPlanningLine, Qty);

        // [WHEN] Receive and invoice the purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Quantity on the job planning line remains 90.
        // [THEN] Remaining quantity on the job planning line = 30.
        JobPlanningLine.Find();
        JobPlanningLine.TestField(Quantity, 3 * Qty);
        JobPlanningLine.TestField("Remaining Qty.", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQtyOnSOAfterSortingOnReservedField()
    var
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 400405] Allow change of quantity in Sales Order after user changed sorting of "Reserved" field
        Initialize();

        // [GIVEN] Posted Purchase order with Items "I1" and "I2"
        CreateItemWithReserveAsAlways(Item[1]);
        CreateItemWithReserveAsAlways(Item[2]);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item[1]."No.", 10);
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationBlue.Code);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item[2]."No.", 10);
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationBlue.Code);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Sales Order with Item "I1" - qty = 1, Item "I2" - qty = 2.
        CreateSalesOrder(
            SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(),
            Item[1]."No.", 1, LocationBlue.Code);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[2]."No.", 2);
        SalesLine.Validate("Location Code", LocationBlue.Code);
        SalesLine.Modify(true);

        // [GIVEN] Sales Order page is opened and Lines sorted by "Reserved Quantity"
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.Filter.SetCurrentKey("Reserved Quantity");

        // [WHEN] Quantity set to 3 for line with Item "I1"
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Quantity.SetValue(3);

        // [THEN] No error appears and "Reserved Quantity" = 3
        SalesOrder.SalesLines."No.".AssertEquals(Item[1]."No.");
        SalesOrder.SalesLines."Reserved Quantity".AssertEquals(3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSucceedsWithNotEnoughUnreservedQtyInInventoryWhenBinNotMandatory()
    var
        Item: Record Item;
        SalesHeader1: Record "Sales Header";
        SalesLine11: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine21: Record "Sales Line";
    begin
        // [SCENARIO] Posting succeeds even when there is not enough unreserved quantity in the inventory on location where BinMandatory = false
        Initialize();

        // [GIVEN] An item with a quantity in inventory location where BinMandatory = false
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", 1, LocationBlue.Code, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Sales Order where all the inventory is reserved on a sales line
        CreateSalesOrder(
            SalesHeader1, SalesLine11, SalesLine11.Type::Item, LibrarySales.CreateCustomerNo(),
            Item."No.", 1, LocationBlue.Code);
        LibrarySales.CreateSalesLine(SalesLine11, SalesHeader1, SalesLine11.Type::Item, Item."No.", 1);
        SalesLine11.Validate("Location Code", LocationBlue.Code);
        SalesLine11.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine11);

        // [GIVEN] Another Sales Order where item quantity is not reserved
        CreateSalesOrder(
            SalesHeader2, SalesLine21, SalesLine21.Type::Item, LibrarySales.CreateCustomerNo(),
            Item."No.", 1, LocationBlue.Code);
        LibrarySales.CreateSalesLine(SalesLine21, SalesHeader2, SalesLine21.Type::Item, Item."No.", 1);
        SalesLine21.Validate("Location Code", LocationBlue.Code);
        SalesLine21.Modify(true);

        // [WHEN] Posting is called
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // [THEN] Posting succeeds
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowLocationForNonInventoryItemsOnServiceLine()
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        NonInventoryItem: Record Item;
    begin
        // [SCENARIO] It is allowed to set location for non-inventory items on service lines.
        Initialize();

        // [GIVEN] A service order with a service item.
        LibraryWarehouse.CreateLocation(Location);
        CreateNonInvItem(NonInventoryItem);
        CreateServiceOrderSingleLine(ServiceHeader, ServiceLine, NonInventoryItem."No.", 1);

        // [WHEN] Setting location for a non-inventory item on the service line.
        ServiceLine.Validate("Location Code", Location.Code);

        // [THEN] No error occurs.
    end;

    [Test]
    procedure ReservedStockFullStatusStatisticsAssemblyOrderOnInventoryItem()
    var
        Item: array[2] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        AssemblyItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservationFromStock: Enum "Reservation From Stock";
        Quantity: Decimal;
    begin
        // [SCENARIO 563164] Reserved from Stock has "Full" status on Statistics page of Assembly Order when there is non-inventory Item is in the Assembly Lines.
        Initialize();

        // [GIVEN] Store Quanitity in Variable.
        Quantity := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create an Item with Reserve Always.
        CreateItemWithReserveAsAlways(Item[1]);

        // [GIVEN] Create an Item Journal Line.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item[1]."No.", '', '', LibraryRandom.RandIntInRange(300, 350));

        // [GIVEN] Post an Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create an Non Inventory Item.
        LibraryInventory.CreateNonInventoryTypeItem(Item[2]);

        // [GIVEN] Create an Assembly Header.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item[1]."No.", '', Quantity, '');

        // [GIVEN] Create an Assembly Line.
        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item[1]."No.",
            AssemblyItem."Base Unit of Measure", Quantity, LibraryRandom.RandIntInRange(1, 1), '');

        // [GIVEN] Create An Auto Reserve.
        AssemblyLine.AutoReserve();

        // [WHEN] Create Assembly Line with Non Invenotry Item.
        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item[2]."No.",
            AssemblyItem."Base Unit of Measure", Quantity, LibraryRandom.RandIntInRange(1, 1), '');

        // [THEN] Reservation from stock must be Full in Assembly Header.
        Assert.AreEqual(
            ReservationFromStock::Full,
            AssemblyHeader.GetQtyReservedFromStockState(),
            StrSubstNo(
                ReservationFromStockErr,
                ReservationFromStock::Full,
                AssemblyHeader.TableCaption()));
    end;

    [Test]
    procedure SalesLineWithDocumentTypeInvoiceCannotCreateWithTypeItemHDefaultPurchasingCodeDropShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchasingCode: Code[10];
    begin
        // [SCENARIO 574904] Verify that a sales line with the document type 'Invoice' cannot be created with Type 'Item' for an Item No. that has a default Purchasing Code of 'Drop Shipment'.
        Initialize();

        // [GIVEN] Create Purchasing Code and Set Drop Shipment true.
        PurchasingCode := CreatePurchasingCode(true, false); // Drop Shipment

        // [GIVEN] Create an item and assign a Purchasing Code to it.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Code", PurchasingCode);
        Item.Modify(true);

        // [GIVEN] Create a sales header with the document type set to 'Invoice'.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [WHEN] A sales line with the document type 'Invoice' was inserted using an item that has a Purchasing Code.
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Ensure that the Purchasing Code field in the Sales Line is blank.
        Assert.AreEqual('', SalesLine."Purchasing Code", StrSubstNo(PurchasingCodeOnSalesInvoiceErr, SalesLine."No."));

        // [THEN] Ensure that the Drop Shipment field in the Sales Line is false.
        Assert.IsFalse(SalesLine."Drop Shipment", StrSubstNo(DropShipmentErr, SalesLine."No."));

        // [THEN] Post the Sales Document.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    procedure MoveNegativeLines_SetsReturnOrderShipToAddressToCompany()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CompanyInfo: Record "Company Information";
    begin
        // [SCENARIO 580640] Verify Ship to Address of Return Order when Move Negative Lines on the Sales Order.
        Initialize();

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Sales Header with Document Type as Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create SalesLine with Negative Quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandIntInRange(-5, -10));

        // [WHEN] Move Negative Lines
        MoveNegativeLinesOnSalesOrder(SalesHeader);

        // [GIVEN] Get company address
        CompanyInfo.Get();

        // [THEN] Sales Return Order is created with Ship to Address as Company Address.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();
        Assert.AreEqual(
            CompanyInfo."Ship-to Address", SalesHeader."Ship-to Address", ShipToAddressErr);
        Assert.AreEqual(
            CompanyInfo."Ship-to City", SalesHeader."Ship-to City", ShipToAddressErr);
    end;

    local procedure Initialize()
    var
        PriceListLine: Record "Price List Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.ClearState();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Orders IV");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        LibraryERM.SetWorkDate(); // IT.
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());
        PriceListLine.DeleteAll();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Orders IV");

        InitializeCountryData();

        NoSeriesSetup();
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        LocationSetup();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Orders IV");
    end;

    local procedure InitializeCountryData()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup(); // NL
        LibraryERMCountryData.UpdateSalesReceivablesSetup(); // GB.
    end;

    local procedure NoSeriesSetup()
    begin
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    [Scope('OnPrem')]
    procedure EnableSalesReceivablesSetupDefaultItemQuantity()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Item Quantity", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure LocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        CreateAndUpdateLocation(LocationRed, false, false, false);  // Location Blue2 with Require put-away and Require Pick.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, true);
        CreateAndUpdateLocation(LocationGreen, false, true, true);  // Location Green with Require put-away, Require Pick, Require Receive and Require Shipment.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
    end;

    local procedure InvoiceDiscountSetupForSales(var CustInvoiceDisc: Record "Cust. Invoice Disc."; CustomerNo: Code[20]; InvoiceDiscPct: Decimal)
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
        CustInvoiceDisc.Validate("Discount %", InvoiceDiscPct);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CannotUndoSalesDocumentWithReservation(DocumentType: Enum "Sales Document Type"; SignFactor: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and Post Sales Document. Create Sales order and Reserve it.
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostSalesDocument(
            SalesHeader, DocumentType, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", Quantity * SignFactor,
            WorkDate(), '', 0, false);
        CreateSalesOrder(SalesHeader2, SalesLine, SalesLine.Type::Item, SalesHeader."Sell-to Customer No.", Item."No.", Quantity, '');
        SalesLine.ShowReservation();

        // Exercise.
        if DocumentType = SalesHeader."Document Type"::Order then
            asserterror UndoSalesShipmentLine(PostedDocumentNo)
        else
            asserterror UndoReturnReceiptLine(PostedDocumentNo);

        // Verify: Error Message Cannot Undo for Reserved Quantity.
        Assert.ExpectedTestFieldError(ItemLedgEntry.FieldCaption("Reserved Quantity"), Format(0));
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
    end;

    local procedure CreateAndPostInventoryPutAwayAndPickFromSalesOrderWithShippingAdviceComplete(ShowError: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Create and Post Item Journal line. Create and release Sales Order. Create Inventory Put-Away and Pick from Sales Order.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationRed.Code, Quantity);
        CreateAndReleaseSalesOrderWithMutipleLines(SalesHeader, Item."No.", Quantity, LocationRed.Code);
        LibraryVariableStorage.Enqueue(InventoryPutAwayCreatedMsg);  // Enqueue for MessageHandler.
        CreateInventoryPutAwayPick(SalesHeader."No.");

        // Exercise.
        PostInventoryActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away", Quantity / 2);  // Value required for the test.

        // Verify.
        VerifyPostedInventoryPutAwayLine(SalesHeader."No.", LocationRed.Code, Item."No.", Quantity / 2);  // Value required for the test.

        if ShowError then begin
            // Exercise.
            asserterror PostInventoryActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick", Quantity / 2);  // Value required for the test.

            // Verify.
            Assert.ExpectedError(StrSubstNo(OrderMustBeCompleteShipmentErr));
        end;
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        if LocationCode <> '' then
            ItemJournalLine.Validate("Location Code", LocationCode);
        if UnitAmount <> 0 then
            ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20]; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Invoice: Boolean) PostedDocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType, Type, VendorNo, ItemNo, Quantity);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);  // Post as Receive.
    end;

    local procedure CreateAndPostSalesCreditMemoAfterGetReturnReceiptLine(var SalesHeader: Record "Sales Header"; PostedDocumentNo: Code[20]; CustomerNo: Code[20]; Qty: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Reason Code", CreateReasonCode());
        SalesHeader.Modify(true);
        GetReturnReceiptLine(SalesHeader, PostedDocumentNo, Qty);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.
    end;

    local procedure CreateAndPostSalesInvoiceAfterGetShipmentLine(var SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; CustomerNo: Code[20]; Qty: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Reason Code", CreateReasonCode());
        SalesHeader.Modify(true);
        GetShipmentLine(SalesHeader, DocumentNo, Qty);
        LibrarySales.PostSalesDocument(SalesHeader, false, false);
    end;

    local procedure CreateAndPostSalesReturnOrderWithCopySalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PostedSalesInvoiceNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        LibrarySales.CopySalesDocument(
            SalesHeader, "Sales Document Type From"::"Posted Invoice", PostedSalesInvoiceNo, false, true);  // TRUE for RecalculateLines.
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", '');
        SalesLine.DeleteAll(true);  // Required for DK.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as SHIP.
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date; LocationCode: Code[10]; UnitPrice: Decimal; Invoice: Boolean) PostedDocumentNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, Type, CustomerNo, ItemNo, Quantity, LocationCode);
        UpdatePostingDateOnSalesOrder(SalesHeader, PostingDate);
        if Type = SalesLine.Type::"Charge (Item)" then begin
            LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
            SalesLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        end;  // Required for DK.
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);  // Post as Ship and Invoice.
    end;

    local procedure CreateAndPostSalesOrderAsShip(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Customer: Record Customer): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item, Customer."No.", Item."No.",
          LibraryRandom.RandInt(50), '');
        UpdateUnitPriceOnSalesLine(SalesLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Post as SHIP.
    end;

    local procedure CreateAndPostSalesOrderWithExtendedText(DocType: Enum "Sales Document Type"; var CustomerNo: Code[20]; var ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);

        ItemNo := CreateItemWithExtText();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true) then
            TransferExtendedText.InsertSalesExtText(SalesLine);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndShipSalesOrderWithItemCharge(var SalesHeader: Record "Sales Header"; var ItemSalesLine: Record "Sales Line"; var ChargeSalesLine: Record "Sales Line"; var Customer: Record Customer; var Item: Record Item)
    var
        ItemChargeAssignment: Option " ",GetShipmentLines,GetReturnReceiptLines;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(ItemChargeAssignment);  // Enqueue for ItemChargeAssignmentSalesPageHandler.
        LibraryVariableStorage.Enqueue(1);  // Enqueue for ItemChargeAssignmentMenuHandler.
        CreateSalesOrder(
          SalesHeader, ItemSalesLine, ItemSalesLine.Type::Item, Customer."No.", Item."No.", LibraryRandom.RandInt(50), '');
        UpdateUnitPriceOnSalesLine(ItemSalesLine);
        CreateSalesLine(
          SalesHeader, ChargeSalesLine, ChargeSalesLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), ItemSalesLine.Quantity, '');
        UpdateUnitPriceOnSalesLine(ChargeSalesLine);
        ChargeSalesLine.ShowItemChargeAssgnt();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.
    end;

    local procedure CreateAndPostWarehouseReceiptFromPO(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateAndPostWarehouseReceiptFromPOPartially(var PurchaseHeader: Record "Purchase Header"; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceiptPartially(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", QtyToReceive);
    end;

    local procedure CreateAndPostWarehouseReceiptFromSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.");
    end;

    local procedure CreateAndRegisterPickFromSalesOrder(var SalesHeader: Record "Sales Header"; PurchaseLine: Record "Purchase Line")
    var
        Customer: Record Customer;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreatePickFromSalesOrder(
          SalesHeader, Customer."No.", PurchaseLine."No.", PurchaseLine.Quantity / 2, PurchaseLine."Location Code");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", PurchaseLine."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), ItemNo, LibraryRandom.RandDec(10, 2));
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithMutipleLines(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(
          SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), ItemNo, -Quantity, LocationCode);
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, ItemNo, Quantity, LocationCode);
        UpdateShippingAdviceAsCompleteOnSalesOrder(SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesReturnOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, CustomerNo, ItemNo, Quantity,
          LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithLocationAndExptRcptD(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), ItemNo, Quantity);
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationCode);
        UpdateExpectedReceiptDateOnPurchaseLine(PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', ItemNo, Quantity, LocationCode);
        SalesLine.ShowReservation(); // Invokes ReserveFromCurrentLineHandler.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LocationCode);
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          ItemNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAutoReserveItemWithSubstitution(var Item: Record Item; var SubstitutionItem: Record Item; Quantity: Decimal)
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        CreateItemWithReserveAsAlways(Item);
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, Item."No.");
        SubstitutionItem.Get(ItemSubstitution."Substitute No.");
        SubstitutionItem.Validate(Reserve, Item.Reserve::Always);
        SubstitutionItem.Modify(true);
        UpdateItemInventoryNoLocation(Item."No.", Quantity);
        UpdateItemInventoryNoLocation(SubstitutionItem."No.", Quantity);
    end;

    local procedure CreateAutoReserveItemWithOptionalReserveSubstitution(var Item: Record Item; var SubstitutionItem: Record Item; Quantity: Decimal)
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        CreateItemWithReserveAsAlways(Item);
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, Item."No.");
        SubstitutionItem.Get(ItemSubstitution."Substitute No.");
        UpdateItemInventoryNoLocation(Item."No.", Quantity);
        UpdateItemInventoryNoLocation(SubstitutionItem."No.", Quantity);
    end;

    local procedure CreateAndRegisterPutAwayFromSalesReturnOrder(CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleaseSalesReturnOrder(SalesHeader, ItemNo, CustomerNo, Qty, LocationCode);
        CreateAndPostWarehouseReceiptFromSalesReturnOrder(SalesHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          ItemNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; BinMandatory: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Shipment", RequireShipment);
        Location."Bin Mandatory" := BinMandatory;
        Location.Modify(true);
    end;

    local procedure CreateItemWithTypeService(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);
    end;

    local procedure CreateBlockedItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure CreateCustomerDiscountGroupWithSalesLineDiscount(var CustomerDiscountGroup: Record "Customer Discount Group"; var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item)
    begin
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        CreateSalesLineDiscount(
          SalesLineDiscount, Item, SalesLineDiscount."Sales Type"::"Customer Disc. Group", CustomerDiscountGroup.Code, WorkDate(),
          LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateCustomerWithCustomerDiscountGroup(CustomerDiscountGroupCode: Code[20]) CustomerNo: Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Disc. Group", CustomerDiscountGroupCode);
        Customer.Modify(true);
        CustomerNo := Customer."No.";
    end;
    local procedure CreateCustomerWithInvoiceDiscount(var Customer: Record Customer; InvoiceDiscPct: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibrarySales.CreateCustomer(Customer);
        InvoiceDiscountSetupForSales(CustInvoiceDisc, Customer."No.", InvoiceDiscPct);
    end;

    local procedure CreateCustomerWithMandatoryDimensionValueCode(var Customer: Record Customer)
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateItemWithReserveAsAlways(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure CreateItemWithVendorNo(var Item: Record Item)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
    end;

    local procedure CreateItemWithExtText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, Item."No.");
        ExtendedTextLine.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithSimpleBOM(var Item: Record Item; ItemNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ItemNo, 1);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateInventoryPutAwayPick(SourceNo: Code[20])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Sales Order");
        WarehouseRequest.SetRange("Source No.", SourceNo);
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, true, false);  // TRUE for Put-Away and Pick.
    end;

    local procedure CreateMovementFromMovementWorksheetLine(Bin: Record Bin; Bin2: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, Bin2, ItemNo, '', Quantity);
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);
    end;

    local procedure CreatePickFromSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, ItemNo, Quantity, LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePickFromWarehouseShipment(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Type, VendorNo, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Type, VendorNo, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", Type, VendorNo, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseLineDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount"; Item: Record Item; Quantity: Decimal)
    begin
        LibraryERM.CreateLineDiscForVendor(PurchaseLineDiscount, Item."No.", Item."Vendor No.", 0D, '', '', '', Quantity);
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLineDiscount.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(50, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithJob(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; JobPlanningLine: Record "Job Planning Line"; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, JobPlanningLine."No.", Qty);
        PurchaseLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchaseLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchasePriceForVendor(var PurchasePrice: Record "Purchase Price"; Item: Record Item; Quantity: Decimal)
    begin
        LibraryCosting.CreatePurchasePrice(PurchasePrice, Item."Vendor No.", Item."No.", 0D, '', '', '', Quantity);
        PurchasePrice.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchasePrice.Modify(true);
    end;

    local procedure CreatePurchasingCode(DropShipment: Boolean; SpecialOrder: Boolean) PurchasingCode: Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", DropShipment);
        Purchasing.Validate("Special Order", SpecialOrder);
        Purchasing.Modify(true);
        PurchasingCode := Purchasing.Code
    end;

    local procedure CreateReasonCode() "Code": Code[10]
    var
        ReasonCode: Record "Reason Code";
    begin
        LibraryERM.CreateReasonCode(ReasonCode);
        Code := ReasonCode.Code;
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Tax Area Code", '');  // Required for CA.
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, Type, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreateSalesReturnOrderWithUnitPriceAndLineDiscount(CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, CustomerNo, ItemNo, Qty, '');
        UpdateUnitPriceOnSalesLine(SalesLine);
        UpdateLineDiscountOnSalesLine(SalesLine, LibraryRandom.RandInt(10));
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Type, CustomerNo, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Type, CustomerNo, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreateSalesOrderByPage(var SalesOrder: TestPage "Sales Order")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
        EnqueueForChangeOfSellToCustomerOrBuyFromVendor();
        EnqueueForChangeOfSellToCustomerOrBuyFromVendor();
    end;

    local procedure CreateSalesOrderWithTwoLines(var SalesLine: array[2] of Record "Sales Line"; ItemNo: Code[20]; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::Item, ItemNo, LibraryRandom.RandInt(50) + LibraryUtility.GenerateRandomFraction());
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, ItemNo, LibraryRandom.RandInt(50));
        SalesHeader."Shipment Date" := ShipmentDate;
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithItemChargeAssignment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; PostedDocumentNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal)
    var
        ItemChargeAssignment: Option " ",GetShipmentLines,GetReturnReceiptLines;
    begin
        EnqueueValuesForItemCharge(ItemChargeAssignment::GetShipmentLines, PostedDocumentNo);
        CreateSalesDocument(
          SalesHeader, SalesLine, DocumentType, SalesLine.Type::"Charge (Item)", CustomerNo,
          LibraryInventory.CreateItemChargeNo(), Quantity, '');
        UpdateUnitPriceOnSalesLine(SalesLine);
        SalesLine.ShowItemChargeAssgnt();
    end;

    local procedure CreateSalesDocumentWithItemChargeAssignmentWithLnDiscAndInvDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PricesIncludingVAT: Boolean; Quantity: Decimal; UnitPrice: Decimal; LnDiscPct: Decimal): Decimal
    var
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", Quantity);
        SalesLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", LnDiscPct);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Modify(true);
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreateSalesOrderWithDropShipment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, CustomerNo, ItemNo, Quantity, '');
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));  // Drop Shipment as TRUE.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithSpecialOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, CustomerNo, ItemNo, Quantity, '');
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(false, true));  // Special Order as TRUE.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithMultipleLinesWithDiffPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine2: Record "Sales Line"; Quantity: Decimal; LocationCode: Code[10]): Code[20]
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        SpecialOrderCode: Code[10];
        DropShipmentCode: Code[10];
        i: Integer;
    begin
        CreateItemWithVendorNo(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SpecialOrderCode := CreatePurchasingCode(false, true);
        DropShipmentCode := CreatePurchasingCode(true, false);

        for i := 1 to 2 do begin
            CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, Item."No.", Quantity, LocationCode);
            SalesLine.Validate("Purchasing Code", SpecialOrderCode);
            SalesLine.Modify(true);
            CreateSalesLine(SalesHeader, SalesLine2, SalesLine2.Type::Item, Item."No.", Quantity, LocationCode);
            SalesLine2.Validate("Purchasing Code", DropShipmentCode);
            SalesLine2.Modify(true);
        end;
        exit(Item."No.");
    end;

    local procedure CreateSalesOrderSingleLineAutoReservedSpecifiedQuantity(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, 0, '', WorkDate());
        UpdateSalesLineQuantityAndAutoReserve(SalesLine, Quantity);
    end;

    local procedure CreateSalesOrderSingleLineAutoReservedUnspecifiedQuantity(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, 0, '', WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure UpdateSalesLineQuantityAndAutoReserve(var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CreateSalesOrderWithPurchasingCodeSpecialOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Code[20]
    var
        Item: Record Item;
        Customer: Record Customer;
        SpecialOrderCode: Code[10];
    begin
        CreateItemWithVendorNo(Item);
        UpdateItemReserveField(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SpecialOrderCode := CreatePurchasingCode(false, true);

        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10), '', SpecialOrderCode);
        exit(Item."No.");
    end;

    local procedure CreateNewSalesOrderOpenReservation(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        CreateSalesOrder(
          SalesHeader, SalesLine, SalesLine.Type::Item, CustomerNo, ItemNo, Quantity, '');
        SalesLine.Validate(Reserve, SalesLine.Reserve::Optional);
        SalesLine.Modify(true);

        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.FILTER.SetFilter("No.", ItemNo);
        SalesOrder.SalesLines.Reserve.Invoke();
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        if LocationCode <> '' then
            SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; PurchasingCode: Code[10])
    begin
        CreateSalesLine(SalesHeader, SalesLine, Type, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesQuoteWithResponsibilityCenter(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        SalesHeader.Validate("Responsibility Center", ResponsibilityCenter.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item; SalesType: Option; SalesCode: Code[20]; StartingDate: Date; Quantity: Decimal)
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesType, SalesCode, StartingDate, '', '', Item."Base Unit of Measure",
          Quantity);
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateSalesLineDiscountWithType(Type: Enum "Sales Line Discount Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLineDiscount: Record "Sales Line Discount";
        ItemDiscountGroup: Record "Item Discount Group";
        CustomerDiscountGroup: Record "Customer Discount Group";
        ConfigTemplateHeader: Record "Config. Template Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        // Setup: Create Customer and Item Code same as Field Length.
        CustomerNo := GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("No.")));
        ItemNo := GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Item, Item.FieldNo("No.")));

        LibrarySmallBusiness.CreateCustomerTemplate(ConfigTemplateHeader);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(ConfigTemplateHeader.Code);
        LibraryVariableStorage.Enqueue(false);

        CustomerNo := LibrarySales.CreateCustomerNo();
        ItemNo := LibraryInventory.CreateItemNo();

        // Exercise: Create Sales Line Discount for Type Item Discount Group.
        ItemDiscountGroup.FindFirst();
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::"Item Disc. Group", ItemDiscountGroup.Code, SalesLineDiscount."Sales Type"::Customer,
          CustomerNo, 0D, '', '', '', 0);  // Taking StartingDate, MinimumQuantity as Zero.

        // Verify.
        VerifySalesLineDiscount(SalesLineDiscount);

        if Type = SalesLineDiscount.Type::Item then begin
            // Exercise: Create Sales Line Discount for Type Item.
            CustomerDiscountGroup.FindFirst();
            LibraryERM.CreateLineDiscForCustomer(
              SalesLineDiscount, SalesLineDiscount.Type::Item, ItemNo, SalesLineDiscount."Sales Type"::"Customer Disc. Group",
              CustomerDiscountGroup.Code, 0D, '', '', '', 0);  // Taking StartingDate, MinimumQuantity as Zero.

            // Verify.
            VerifySalesLineDiscount(SalesLineDiscount);
        end;
    end;

    local procedure CreateSalesPriceForCustomer(var SalesPrice: Record "Sales Price"; var Customer: Record Customer; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryCosting.CreateSalesPrice(SalesPrice, "Sales Price Type"::Customer, Customer."No.", ItemNo, 0D, '', '', '', Quantity);  // Use 0D for Blank Date.
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(50, 2));
        SalesPrice.Modify(true);
    end;

    local procedure CreateServiceOrderByPage(var ServiceOrder: TestPage "Service Order")
    begin
        ServiceOrder.OpenNew();
        ServiceOrder."Customer No.".SetValue(LibrarySales.CreateCustomerNo());
        EnqueueForChangeOfSellToCustomerOrBuyFromVendor();
        EnqueueForChangeOfSellToCustomerOrBuyFromVendor();
    end;

    local procedure CreateRealeasedServiceOrder(var ServiceHeader: Record "Service Header"; LocationCode: Code[10])
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        if LocationCode <> '' then
            ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
    end;

    local procedure CreateServiceOrderSingleLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ProductionItem: Record Item;
    begin
        CreateItemWithSimpleBOM(ProductionItem, ItemNo, ProductionItem."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProductionItem."No.", Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        AssemblyItem: Record Item;
    begin
        CreateItemWithSimpleBOM(AssemblyItem, ItemNo, AssemblyItem."Replenishment System"::Assembly);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), AssemblyItem."No.", '', Quantity, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemNo, AssemblyItem."Base Unit of Measure", Quantity, 1, '');
    end;

    local procedure CreateServiceOrderAndShipment(var ServiceOrder: TestPage "Service Order")
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 10);
        CreateRealeasedServiceOrder(ServiceHeader, Location.Code);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        ServiceOrder.OpenView();
        ServiceOrder.GotoRecord(ServiceHeader);
    end;

    local procedure CreateWarehouseShipmentFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateJobRelatedPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, '', WorkDate());
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CarryOutActMsgForSpclOrdLinesOnReqWksh(LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // Setup: Create Sales Order with four lines, two lines are for Speical Order
        // and other two lines are for Drop Shipment.
        ItemNo := CreateSalesOrderWithMultipleLinesWithDiffPurchasingCode(
            SalesHeader, SalesLine, LibraryRandom.RandInt(10), LocationCode);

        // Exercise: Get Sales Order with Speicial Order on Requisition Worksheet and carry out.
        GetSalesOrderForSpecialOrderOnRequisitionWkshtAndCarryOutActionMsg(ItemNo);

        // Verify: All Special Order lines of same vendor can be created into single Purchase Order.
        VerifyPurchaseOrdContainsTwoLines(SalesHeader, true);
    end;

    local procedure CarryOutActMsgForDropShptLinesOnReqWksh(LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Sales Order with four lines, two lines are for Speical Order
        // and other two lines are for Drop Shiment.
        CreateSalesOrderWithMultipleLinesWithDiffPurchasingCode(
          SalesHeader, SalesLine, LibraryRandom.RandInt(10), LocationCode);

        // Exercise: Get Sales Order with Drop Shipment on Requisition Worksheet and carry out.
        GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // Verify: All Drop Shipment lines of same vendor can be created into single Purchase Order.
        VerifyPurchaseOrdContainsTwoLines(SalesHeader, false);
    end;

    local procedure CarryOutActionMessageOnRequisitionWorksheet(SpecialOrder: Boolean)
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Create Item with Vendor. Create Sales Price for Customer and Sales Line Discount. Create Purchase Price for Vendor and Purchase Line Discount.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithVendorNo(Item);
        CreateSalesPriceForCustomer(SalesPrice, Customer, Item."No.", Quantity);
        CreateSalesLineDiscount(SalesLineDiscount, Item, SalesLineDiscount."Sales Type"::Customer, Customer."No.", 0D, Quantity);  // Use 0D for Blank Date.
        CreatePurchasePriceForVendor(PurchasePrice, Item, Quantity);
        CreatePurchaseLineDiscount(PurchaseLineDiscount, Item, Quantity);
        CopyAllSalesPriceToPriceListLine();
        CopyAllPurchPriceToPriceListLine();
        if SpecialOrder then
            CreateSalesOrderWithSpecialOrder(SalesHeader, Customer."No.", Item."No.", Quantity)
        else
            CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, Customer."No.", Item."No.", Quantity);

        // Exercise: Get Sales Order on Requisition Worksheet.
        if SpecialOrder then
            GetSalesOrderForSpecialOrderOnRequisitionWkshtAndCarryOutActionMsg(Item."No.")
        else
            GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // Verify: Verify Purchase Line.
        VerifyPurchaseLine(PurchaseLine, Item."No.", Quantity, PurchasePrice."Direct Unit Cost", PurchaseLineDiscount."Line Discount %");

        // Exercise: Post Purchase Order and Sales Order.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive as TRUE.
        SalesHeader.Find();  // Require for Posting.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify: Verify Posted Sales Invoice Line.
        VerifyPostedSalesInvoiceLine(PostedDocumentNo, SalesPrice."Unit Price", SalesLineDiscount."Line Discount %", Quantity);
    end;

    local procedure EnqueueForChangeOfSellToCustomerOrBuyFromVendor()
    begin
        LibraryVariableStorage.Enqueue(ConfirmTextForChangeOfSellToCustomerOrBuyFromVendorQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
    end;

    local procedure EnqueueValuesForItemCharge(ItemChargeAssignment: Option " ",GetShipmentLines,GetReturnReceiptLines; PostedDocumentNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemChargeAssignment);
        LibraryVariableStorage.Enqueue(PostedDocumentNo);  // PostedDocumentNo used in SalesShipmentLinePageHandler.
    end;

    local procedure EnqueueValuesForMultipleItemCharges(ItemChargeAssignment: Option " ",GetShipmentLines,GetReturnReceiptLines; PostedDocumentNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemChargeAssignment);
        LibraryVariableStorage.Enqueue(PostedDocumentNo);  // PostedDocumentNo used in SalesShipmentLinePageHandler.
        LibraryVariableStorage.Enqueue(1);
    end;

    local procedure FindBinForPickZone(var Bin: Record Bin; LocationCode: Code[10]; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, Pick));
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindPostedWhseShipmentLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; ItemNo: Code[20])
    begin
        PostedWhseShipmentLine.SetRange("Source Document", SourceDocument);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; No: Code[20])
    begin
        ReturnReceiptLine.SetRange("No.", No);
        ReturnReceiptLine.FindFirst();
    end;

    local procedure FindRegisteredWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; SalesHeaderNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Quote No.", SalesHeaderNo);
        SalesHeader.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindSalesLine2(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FilterSalesReturnExtLine(var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", '');
    end;

    local procedure FilterSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; CustomerDiscountGroupCode: Code[20])
    begin
        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::"Customer Disc. Group");
        SalesLineDiscount.SetRange("Sales Code", CustomerDiscountGroupCode);
    end;

    local procedure FilterSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.SetRange("No.", SalesHeader."No.");
    end;

    local procedure FindSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") ExpdTotalDisAmt: Decimal
    begin
        SalesHeader.SetRange("Document Type", SalesLine."Document Type");
        SalesHeader.SetRange("No.", SalesLine."Document No.");
        SalesHeader.FindFirst();
        ExpdTotalDisAmt := SalesLine."Line Discount Amount" + SalesLine."Inv. Discount Amount";
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure GeneralSetupForRegisterPutAway(var PurchaseLine: Record "Purchase Line")
    var
        Location: Record Location;
        Item: Record Item;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        CreateFullWarehouseSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromPurchaseOrder(PurchaseLine, Item."No.", Location.Code);
    end;

    local procedure GeneralPreparationWithPurchaseOrderAndSalesOrder(PurchLineQty: Decimal; QtyToReceive: Decimal; SalesLineQty: Decimal): Code[20]
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrderWithLocationAndExptRcptD(PurchaseLine, Item."No.", PurchLineQty, LocationWhite.Code);
        RegisterPutAwayAfterPostWarehouseReceiptFromPOPartially(PurchaseLine, QtyToReceive); // Partial receive.

        CreateAndReleaseSalesOrderWithReservation(SalesLine, Item."No.", LocationWhite.Code, SalesLineQty);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Create and post another supply.
        CreateAndReleasePurchaseOrderWithLocationAndExptRcptD(PurchaseLine, Item."No.", PurchLineQty + SalesLineQty, LocationWhite.Code);
        RegisterPutAwayAfterPostWarehouseReceiptFromPOPartially(PurchaseLine, SalesLineQty); // Full posting and make sure enough supply qty.

        exit(SalesHeader."No.");
    end;

    local procedure GetRandomCode(FieldLength: Integer): Code[20]
    var
        RandomCode: Code[20];
    begin
        RandomCode := LibraryUtility.GenerateGUID();
        repeat
            RandomCode += 'A';  // Value Required for test.
        until StrLen(RandomCode) = FieldLength;
        exit(RandomCode);
    end;

    local procedure GetReturnReceiptLine(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; Qty: Decimal)
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        ReturnReceiptLine.SetRange("Document No.", DocumentNo);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
        if Qty <> 0 then
            UpdateQuantityOnSalesCreditMemoLineByPage(SalesHeader."No.", ReturnReceiptLine."No.", Qty);
    end;

    local procedure GetShipmentLine(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; Qty: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        if Qty <> 0 then
            UpdateQuantityOnSalesInvoiceLineByPage(SalesHeader."No.", SalesShipmentLine."No.", Qty);
    end;

    local procedure GetPurchLineVATIdentifier(DocumentNo: Code[20]): Code[10]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        exit(PurchaseLine."VAT Identifier");
    end;

    local procedure GetPostedDocumentLines(DocumentNo: Code[20])
    var
        PurchReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchReturnOrder.OpenEdit();
        PurchReturnOrder.FILTER.SetFilter("No.", DocumentNo);
        PurchReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetSalesShipmentHeader(OrderNo: Code[20]) SalesShipmentHeaderNo: Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        SalesShipmentHeaderNo := SalesShipmentHeader."No.";
    end;

    local procedure GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, SelectRequisitionTemplate());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure GetSalesOrderForSpecialOrderOnRequisitionWkshtAndCarryOutActionMsg(ItemNo: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, SelectRequisitionTemplate());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CreateSalesInvoiceWithItemChargeWithLnDiscAndInvDisc(var SalesHeader2: Record "Sales Header"; var GeneralPostingSetup: Record "General Posting Setup"; PricesIncludingVAT: Boolean) ExpdTotalDisAmt: Decimal
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: array[3] of Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PostedDocNo: array[3] of Code[20];
        i: Integer;
        VATPct: Decimal;
        ItemChargeAssignment: Option " ",GetShipmentLines,GetReturnReceiptLines;
    begin
        // General preparation for create sales invoice with item charge with line discount and invoice discount.
        CreateCustomerWithInvoiceDiscount(Customer, 5); // Using hardcode to test rounding.
        LibraryInventory.CreateItem(Item);

        for i := 1 to 3 do
            PostedDocNo[i] :=
              CreateAndPostSalesDocument(SalesHeader[i], SalesHeader[i]."Document Type"::Order, SalesLine[i].Type::Item,
                Customer."No.", Item."No.", LibraryRandom.RandDec(10, 5), WorkDate(), '',
                LibraryRandom.RandDec(10, 2), false); // Post as Ship.

        VATPct :=
          CreateSalesDocumentWithItemChargeAssignmentWithLnDiscAndInvDisc(
            SalesHeader2, SalesLine2, SalesHeader2."Document Type"::Invoice, Customer."No.",
            PricesIncludingVAT, 3.333, 6.999, 10);

        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine2); // Calculate Invoice Discount.

        EnqueueValuesForItemCharge(ItemChargeAssignment::GetShipmentLines, PostedDocNo[i]);
        for i := 1 to 3 do begin
            SalesLine2.ShowItemChargeAssgnt();
            EnqueueValuesForMultipleItemCharges(ItemChargeAssignment::GetShipmentLines, PostedDocNo[i]);
        end;

        ExpdTotalDisAmt := FindSalesInvoice(SalesHeader2, SalesLine2); // Need find it before posting.

        if PricesIncludingVAT then
            ExpdTotalDisAmt := Round(ExpdTotalDisAmt / (1 + VATPct / 100));

        GeneralPostingSetup.Get(SalesLine2."Gen. Bus. Posting Group", SalesLine2."Gen. Prod. Posting Group");
    end;

    local procedure CreateSalesOrderWithQuantityReceived(var SalesLine: Record "Sales Line"; ReturnQtyReceivedBase: Decimal; ReturnQtyReceived: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', '', LibraryRandom.RandIntInRange(10, 20), '');
        SalesLine.Validate("Return Qty. Received (Base)", ReturnQtyReceivedBase);
        SalesLine.Validate("Return Qty. Received", ReturnQtyReceived);
        SalesLine.Modify(true);
    end;

    local procedure InvokeShowMatrixOnItemStatisticsPage(ItemNo: Code[20]; DimColumnOption: Option Location,Period)
    var
        Location: Record Location;
        ItemStatistics: TestPage "Item Statistics";
    begin
        ItemStatistics.OpenEdit();
        ItemStatistics.ItemFilter.SetValue(ItemNo);
        case DimColumnOption of
            DimColumnOption::Location:
                ItemStatistics.ColumnDimCode.SetValue(Location.TableCaption());
            DimColumnOption::Period:
                ItemStatistics.ColumnDimCode.SetValue(PeriodTxt);
        end;
        ItemStatistics.ShowMatrix.Invoke();
    end;

    local procedure PostInventoryActivity(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; QuantityToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo, ActivityType);
        WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Receive.
    end;

    local procedure PostSalesOrderWithItemChargeAssignment(PartialInvoice: Boolean)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup2: Record "General Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        PostedDocumentNo: Code[20];
        PostedDocumentNo2: Code[20];
    begin
        // Create and post Sales Order with Item Charge Assignment. Update blank Quantity to Invoice on Sales Line.
        CreateAndShipSalesOrderWithItemCharge(SalesHeader, SalesLine2, SalesLine, Customer, Item);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        UpdateQuantityToInvoiceOnSalesLine(SalesHeader."No.", 0);  // Value 0 required for test.

        // Exercise.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);  // Post as Invoice.

        // Verify.
        GeneralPostingSetup2.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedDocumentNo, GeneralPostingSetup2."Sales Account", -SalesLine."Line Amount");
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedDocumentNo, CustomerPostingGroup."Receivables Account", SalesLine."Amount Including VAT");

        if PartialInvoice then begin
            // Exercise.
            UpdateQuantityToInvoiceOnSalesLine(SalesHeader."No.", SalesLine.Quantity / 2);  // Value required for Partial quantity.
            PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);  // Post as Invoice.
            PostedDocumentNo2 := LibrarySales.PostSalesDocument(SalesHeader, false, true);  // Post as Invoice.

            // Verify.
            GeneralPostingSetup2.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
            VerifyGLEntry(
              GLEntry."Document Type"::Invoice, PostedDocumentNo, GeneralPostingSetup2."Sales Account", -SalesLine2."Line Amount" / 2);  // Value required for Partial quantity.
            VerifyGLEntry(
              GLEntry."Document Type"::Invoice, PostedDocumentNo, CustomerPostingGroup."Receivables Account",
              SalesLine2."Amount Including VAT" / 2);  // Value required for Partial quantity.
            VerifyGLEntry(
              GLEntry."Document Type"::Invoice, PostedDocumentNo2, GeneralPostingSetup2."Sales Account", -SalesLine2."Line Amount" / 2);  // Value required for Partial quantity.
            VerifyGLEntry(
              GLEntry."Document Type"::Invoice, PostedDocumentNo2, CustomerPostingGroup."Receivables Account",
              SalesLine2."Amount Including VAT" / 2);  // Value required for Partial quantity.
        end;
    end;

    local procedure PostSalesReturnOrderWithExactCostReversingMandatory(ExactCostReversingMandatory: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Quantity2: Decimal;
        Quantity: Decimal;
        PostedSalesInvoiceNo: Code[20];
        OldCreditWarnings: Option;
        OldExactCostReversingMandatory: Boolean;
        OldStockoutWarning: Boolean;
    begin
        // Create and Post Purchase Order. Create and post two Sales Orders and set Exact Cost Reversing Mandatory.
        OldStockoutWarning := UpdateStockOutWarningOnSalesReceivablesSetup(false);
        OldCreditWarnings := UpdateCreditWarningOnSalesAndReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        OldExactCostReversingMandatory := UpdateExactCostReversingMandatoryOnSalesReceivableSetup(ExactCostReversingMandatory);
        Quantity := LibraryRandom.RandInt(50);
        Quantity2 := Quantity + LibraryRandom.RandInt(20);  // Greater Value required for the Quantity.
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
          Quantity + Quantity2, true);  // True for INVOICE. Value required for the test.
        CreateAndPostSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.",
          Quantity2, WorkDate(), LocationBlue.Code, LibraryRandom.RandDec(10, 2), true);  // TRUE for Post as INVOICE.
        PostedSalesInvoiceNo :=
          CreateAndPostSalesDocument(
            SalesHeader2, SalesHeader2."Document Type"::Order, SalesLine.Type::Item, SalesHeader."Sell-to Customer No.", Item."No.",
            Quantity, WorkDate(), LocationBlue.Code, LibraryRandom.RandDec(10, 2), true);  // TRUE for Post as INVOICE.

        // Exercise.
        CreateAndPostSalesReturnOrderWithCopySalesDocument(SalesHeader3, SalesHeader."Sell-to Customer No.", PostedSalesInvoiceNo);

        // Verify.
        if ExactCostReversingMandatory then begin
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Sales Shipment", GetSalesShipmentHeader(SalesHeader."No."),
              ItemLedgerEntry."Entry Type"::Sale, Item."No.", Quantity - Quantity2);  // Value required for the test.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Sales Shipment", GetSalesShipmentHeader(SalesHeader2."No."),
              ItemLedgerEntry."Entry Type"::Sale, Item."No.", -Quantity);
        end else begin
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Sales Shipment", GetSalesShipmentHeader(SalesHeader."No."),
              ItemLedgerEntry."Entry Type"::Sale, Item."No.", Quantity - Quantity2);  // Value required for the test.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Sales Shipment", GetSalesShipmentHeader(SalesHeader2."No."),
              ItemLedgerEntry."Entry Type"::Sale, Item."No.", -Quantity);
        end;

        // Tear Down.
        UpdateStockOutWarningOnSalesReceivablesSetup(OldStockoutWarning);
        UpdateCreditWarningOnSalesAndReceivablesSetup(OldCreditWarnings);
        UpdateExactCostReversingMandatoryOnSalesReceivableSetup(OldExactCostReversingMandatory);
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseReceiptPartially(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; QtyToReceive: Decimal)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        UpdateQtyToReceiveOnWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo, QtyToReceive);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseShipment(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure RegisterPutAwayAfterPostWarehouseReceiptFromPO(PurchaseLine: Record "Purchase Line")
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader);
        FindBinForPickZone(Bin, PurchaseLine."Location Code", true);
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Bin.Code, Bin."Zone Code");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", PurchaseLine."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure RegisterPutAwayAfterPostWarehouseReceiptFromPOPartially(PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreateAndPostWarehouseReceiptFromPOPartially(PurchaseHeader, QtyToReceive);
        FindBinForPickZone(Bin, PurchaseLine."Location Code", true);
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Bin.Code, Bin."Zone Code");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", PurchaseLine."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RunDeleteInvoicedSalesReturnOrdersReport(var SalesHeader: Record "Sales Header")
    var
        DeleteInvdSalesRetOrders: Report "Delete Invd Sales Ret. Orders";
    begin
        Clear(DeleteInvdSalesRetOrders);
        DeleteInvdSalesRetOrders.SetTableView(SalesHeader);
        DeleteInvdSalesRetOrders.UseRequestPage(false);
        DeleteInvdSalesRetOrders.Run();
    end;

    local procedure SelectRequisitionTemplate() ReqWkshTemplateName: Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        ReqWkshTemplateName := ReqWkshTemplate.Name
    end;

    local procedure UndoSalesShipmentLine(DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoShipmentMsg);  // UndoShipmentMessage Used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UndoReturnReceiptLine(DocumentNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        LibraryVariableStorage.Enqueue(UndoReturnReceiptMsg);  // UndoReturnShipmentMessage Used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
        ReturnReceiptLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);
    end;

    local procedure UndoSalesDocumentForAppliedQuantity(DocumentType: Enum "Sales Document Type"; SignFactor: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and Post Sales Document. Create Sales Order Apply with Posted Sales Document and Post.
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostSalesDocument(
            SalesHeader, DocumentType, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", Quantity * SignFactor,
            WorkDate(), '', 0, false);
        CreateSalesOrder(SalesHeader2, SalesLine, SalesLine.Type::Item, SalesHeader."Sell-to Customer No.", Item."No.", Quantity, '');
        if DocumentType = SalesHeader."Document Type"::Order then
            FindItemLedgerEntry(
              ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Shipment", PostedDocumentNo, ItemLedgerEntry."Entry Type"::Sale,
              Item."No.")
        else
            FindItemLedgerEntry(
              ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Return Receipt", PostedDocumentNo,
              ItemLedgerEntry."Entry Type"::Sale, Item."No.");
        UpdateApplyToItemEntryOnSalesLine(SalesLine, ItemLedgerEntry."Entry No.");
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);  // Post as Ship and Invoice

        // Exercise.
        if DocumentType = SalesHeader."Document Type"::Order then
            asserterror UndoSalesShipmentLine(PostedDocumentNo)
        else
            asserterror UndoReturnReceiptLine(PostedDocumentNo);

        // Verify: Error Message Cannot Undo Applied Quantity.
        Assert.ExpectedTestFieldError(ItemLedgerEntry.FieldCaption("Remaining Quantity"), Format(Quantity));
    end;

    local procedure UpdateApplyToItemEntryOnSalesLine(var SalesLine: Record "Sales Line"; ApplToItemEntry: Integer)
    begin
        SalesLine.Validate("Appl.-to Item Entry", ApplToItemEntry);
        SalesLine.Modify(true);
    end;

    local procedure UpdateExactCostReversingMandatoryOnSalesReceivableSetup(NewExactCostReversingMandatory: Boolean) OldExactCostReversingMandatory: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldExactCostReversingMandatory := SalesReceivablesSetup."Exact Cost Reversing Mandatory";
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", NewExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateDiscountOnSalesReceivableSetup(IsDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Post Invoice Discount" := IsDiscount;
        SalesReceivablesSetup."Post Line Discount" := IsDiscount;
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateExpectedReceiptDateOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Expected Receipt Date", WorkDate());
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateInventoryUsingWhseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Bin."Location Code", WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure UpdateLocationOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    begin
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdatePostingDateOnSalesOrder(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateQuantityToInvoiceOnSalesLine(DocumentNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentNo);
        SalesLine.Validate("Qty. to Invoice", Quantity);
        SalesLine.Modify(true);
    end;

    local procedure UpdateShippingAdviceAsCompleteOnSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Shipping Advice", SalesHeader."Shipping Advice"::Complete);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateCreditWarningOnSalesAndReceivablesSetup(NewCreditWarnings: Option) OldCreditWarning: Integer
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCreditWarning := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateStockOutWarningOnSalesReceivablesSetup(NewStockOutWarning: Boolean) OldStockOutWarning: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockOutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockOutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateUnitPriceOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure UpdateLineDiscountOnSalesLine(var SalesLine: Record "Sales Line"; LineDiscount: Decimal)
    begin
        SalesLine.Validate("Line Discount %", LineDiscount);
        SalesLine.Modify(true);
    end;

    local procedure UpdateZoneAndBinCodeOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; BinCode: Code[20]; ZoneCode: Code[10])
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(
WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.ModifyAll("Zone Code", ZoneCode, true);
        WarehouseActivityLine.ModifyAll("Bin Code", BinCode, true);
    end;

    local procedure UpdateQuantityOnSalesInvoiceLineByPage(No: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
        SalesInvoice.SalesLines.FILTER.SetFilter("No.", ItemNo);
        SalesInvoice.SalesLines.Quantity.SetValue(Qty); // Update Quantity for posting Sales Invoice partially.
        SalesInvoice.OK().Invoke();
    end;

    local procedure UpdateQuantityOnSalesCreditMemoLineByPage(No: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
        SalesCreditMemo.SalesLines.FILTER.SetFilter("No.", ItemNo);
        SalesCreditMemo.SalesLines.Quantity.SetValue(Qty); // Update Quantity for posting Sales Credit Memo partially.
        SalesCreditMemo.OK().Invoke();
    end;

    local procedure UpdateQtyToReceiveOnWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; QtyToReceive: Decimal)
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateItemReserveField(var Item: Record Item)
    begin
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Modify(true);
    end;

    local procedure SelectItemSubstitutionThroughSalesOrderPage(var SalesHeader: Record "Sales Header"; var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.SelectItemSubstitution.Invoke();
    end;

    local procedure SelectItemSubstitutionThroughSalesOrderPageFactBox(var SalesHeader: Record "Sales Header"; var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.First();
        SalesOrder.Control1906127307.Substitutions.DrillDown();
    end;

    local procedure SelectItemSubstitutionAndRevertItemNoThroughServiceOrderPage(var ServiceHeader: Record "Service Header"; SubstItemNo: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        LibraryVariableStorage.Enqueue(ServiceHeader."Document Type");
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(SubstItemNo);
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Close();
    end;

    local procedure SelectItemSubstitutionThroughProductionOrderPage(var ProductionOrder: Record "Production Order"; var ReleasedProductionOrder: TestPage "Released Production Order"; var ProdOrderComponents: TestPage "Prod. Order Components")
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);
        ReleasedProductionOrder.ProdOrderLines.First();

        ProdOrderComponents.Trap();

        ReleasedProductionOrder.ProdOrderLines.Components.Invoke();

        ProdOrderComponents.First();
        ProdOrderComponents.SelectItemSubstitution.Invoke();
    end;

    local procedure SelectItemSubstitutionThroughAssemblyOrderPage(var AssemblyHeader: Record "Assembly Header"; var AssemblyOrder: TestPage "Assembly Order")
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.GotoRecord(AssemblyHeader);
        AssemblyOrder.Lines.First();

        AssemblyOrder.Lines.SelectItemSubstitution.Invoke();
    end;

    local procedure SetLineItemNoThroughSalesOrderPage(var SalesOrder: TestPage "Sales Order"; ItemNo: Code[20])
    begin
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.Close();
    end;

    local procedure SetItemNoThroughProdOrderComponentsPage(var ReleasedProductionOrder: TestPage "Released Production Order"; var ProdOrderComponents: TestPage "Prod. Order Components"; ItemNo: Code[20])
    begin
        ProdOrderComponents."Item No.".SetValue(ItemNo);
        ProdOrderComponents.Close();
        ReleasedProductionOrder.Close();
    end;

    local procedure SetItemNoThroughAssemblyOrderPage(var AssemblyOrder: TestPage "Assembly Order"; ItemNo: Code[20])
    begin
        AssemblyOrder.Lines."No.".SetValue(ItemNo);
        AssemblyOrder.Close();
    end;

    local procedure UpdateItemInventoryNoLocation(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure FilterReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; LocationCode: Code[10]; SourceTypeFilter: Text; Quantity: Decimal)
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetFilter("Source Type", SourceTypeFilter);
        ReservationEntry.SetFilter(Quantity, '%1|%2', Quantity, -Quantity);
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyItemLedgerEntry(DocumentType: Enum "Item Ledger Document Type"; OrderNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, DocumentType, OrderNo, EntryType, ItemNo);
        ItemLedgerEntry.TestField("Remaining Quantity", ExpectedQuantity);
    end;

    local procedure VerifyPostedInventoryPutAwayLine(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
    begin
        PostedInvtPutAwayLine.SetRange("Source Document", PostedInvtPutAwayLine."Source Document"::"Sales Order");
        PostedInvtPutAwayLine.SetRange("Source No.", SourceNo);
        PostedInvtPutAwayLine.FindFirst();
        PostedInvtPutAwayLine.TestField("Location Code", LocationCode);
        PostedInvtPutAwayLine.TestField("Item No.", ItemNo);
        PostedInvtPutAwayLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedSalesInvoiceLine(DocumentNo: Code[20]; UnitPrice: Decimal; LineDiscount: Decimal; Quantity: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Unit Price", UnitPrice);
        SalesInvoiceLine.TestField("Line Discount %", LineDiscount);
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; LineDiscount: Decimal)
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField(Quantity, Quantity);
        PurchaseLine.TestField("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.TestField("Line Discount %", LineDiscount);
    end;

    local procedure VerifyQtyToInvoiceOnSalesLine(ItemNo: Code[20]; DocumentType: Enum "Sales Document Type"; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine2(SalesLine, DocumentType, ItemNo);
        SalesLine.TestField("Qty. to Invoice", Quantity);
    end;

    local procedure VerifyRegisteredPutAwayLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Sales Return Order", SourceNo,
          RegisteredWhseActivityLine."Activity Type"::"Put-away");
        RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesLineDiscount(SalesLineDiscount: Record "Sales Line Discount")
    var
        SalesLineDiscount2: Record "Sales Line Discount";
    begin
        SalesLineDiscount2.SetRange(Type, SalesLineDiscount.Type);
        SalesLineDiscount2.SetRange(Code, SalesLineDiscount.Code);
        SalesLineDiscount2.SetRange("Sales Type", SalesLineDiscount."Sales Type");
        SalesLineDiscount2.SetRange("Sales Code", SalesLineDiscount."Sales Code");
        SalesLineDiscount2.FindFirst();
    end;

    local procedure VerifySalesLineForLineDiscount(SalesLine: Record "Sales Line"; SalesLineDiscount: Record "Sales Line Discount")
    begin
        SalesLine.TestField("Line Discount %", SalesLineDiscount."Line Discount %");
        SalesLine.TestField("No.", SalesLineDiscount.Code);
        SalesLine.TestField(
          "Line Discount Amount",
          Round(SalesLine."Line Amount" * SalesLineDiscount."Line Discount %" / 100, LibraryERM.GetAmountRoundingPrecision()));
        SalesLine.TestField(Quantity, SalesLineDiscount."Minimum Quantity");
    end;

    local procedure VerifySalesOrder(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
    begin
        FindSalesHeader(SalesHeader2, SalesHeader."No.");
        FindSalesLine(SalesLine2, SalesHeader2."No.");
        SalesHeader2.TestField("Responsibility Center", SalesHeader."Responsibility Center");
        SalesHeader2.TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesLine2.TestField("Responsibility Center", SalesLine."Responsibility Center");
        SalesLine2.TestField("No.", SalesLine."No.");
        SalesLine2.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyExtSalesLine(SalesHeaderNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        LineNo: Integer;
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
        LineNo := SalesLine."Line No.";
        SalesLine.SetRange("No.", '');
        SalesLine.SetRange(Description, ItemNo);
        SalesLine.FindFirst();
        SalesLine.TestField("Attached to Line No.", LineNo);
    end;

    local procedure VerifyNoSeriesOnPostedWhseReceipt(ItemNo: Code[20]; NoSeries: Code[20])
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange("Source Document", PostedWhseReceiptLine."Source Document"::"Purchase Order");
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.FindFirst();
        PostedWhseReceiptHeader.Get(PostedWhseReceiptLine."No.");
        PostedWhseReceiptHeader.TestField("No. Series", NoSeries);
    end;

    local procedure VerifyNoSeriesOnRegisteredWhseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; NoSeries: Code[20])
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLine(RegisteredWhseActivityLine, SourceDocument, SourceNo, ActivityType);
        RegisteredWhseActivityHdr.Get(RegisteredWhseActivityLine."Activity Type", RegisteredWhseActivityLine."No.");
        RegisteredWhseActivityHdr.TestField("No. Series", NoSeries);
    end;

    local procedure VerifyNoSeriesOnPostedWhseShipment(ItemNo: Code[20]; NoSeries: Code[20])
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        FindPostedWhseShipmentLine(PostedWhseShipmentLine, PostedWhseShipmentLine."Source Document"::"Sales Order", ItemNo);
        PostedWhseShipmentHeader.Get(PostedWhseShipmentLine."No.");
        PostedWhseShipmentHeader.TestField("No. Series", NoSeries);
    end;

    local procedure VerifyReturnReceiptLine(PostedDocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Next: Boolean)
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("Document No.", PostedDocumentNo);
        ReturnReceiptLine.SetRange("No.", ItemNo);
        ReturnReceiptLine.FindSet();
        if Next then
            ReturnReceiptLine.Next();
        ReturnReceiptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesShipmentLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Next: Boolean)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindSet();
        if Next then
            SalesShipmentLine.Next();
        SalesShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyDiscountAmountInValueEntry(PostedDocNo: Code[20]; ExpdTotalDisAmt: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ActualTotalDisAmt: Decimal;
    begin
        ValueEntry.SetRange("Document No.", PostedDocNo);
        ValueEntry.FindSet();
        repeat
            ActualTotalDisAmt := ActualTotalDisAmt + Abs(ValueEntry."Discount Amount");
        until ValueEntry.Next() = 0;
        Assert.AreEqual(ExpdTotalDisAmt, ActualTotalDisAmt, DiscountErr);
    end;

    local procedure VerifyDiscountAmountInGLEntry(PostedDocNo: Code[20]; LineDiscAccount: Code[20]; InvDiscAccount: Code[20]; ExpdTotalDisAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        TotalAMount: Decimal;
    begin
        GLEntry.SetRange("Document No.", PostedDocNo);
        GLEntry.SetFilter("G/L Account No.", '%1|%2', LineDiscAccount, InvDiscAccount);
        GLEntry.FindSet();
        repeat
            TotalAMount += GLEntry.Amount;
        until GLEntry.Next() = 0;

        Assert.AreEqual(ExpdTotalDisAmt, TotalAMount, DiscountErr);
    end;

    local procedure VerifyPurchaseOrdContainsTwoLines(var SalesHeader: Record "Sales Header"; SpecialOrder: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        FirstPurchaseHeaderNo: Code[20];
    begin
        if SpecialOrder then
            PurchaseLine.SetRange("Special Order Sales No.", SalesHeader."No.")
        else
            PurchaseLine.SetRange("Sales Order No.", SalesHeader."No."); // For DropShipment.
        PurchaseLine.Find('-');
        FirstPurchaseHeaderNo := PurchaseLine."Document No.";
        PurchaseLine.Next();
        PurchaseLine.TestField("Document No.", FirstPurchaseHeaderNo);
    end;

    local procedure VerifyQuantityOnWarehouseActivityLine(SourceNo: Code[20]; ExpectedQty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.CalcSums(Quantity); // It includes two lines with Action Type = Take.
        Assert.AreEqual(ExpectedQty, WarehouseActivityLine.Quantity, QtyOnWhseActivLineErr);
    end;

    local procedure VerifyPurchLineVATIdentifier(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; VATIdentifier: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetFilter("No.", '<>''''');
        // To skip Description line
        PurchaseLine.FindFirst();
        Assert.AreEqual(
          VATIdentifier, PurchaseLine."VAT Identifier", StrSubstNo(WrongValueErr, PurchaseLine.FieldCaption("VAT Identifier")));
    end;

    local procedure VerifySalesLineByItemNoWithReservation(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        SalesLine.Find();
        SalesLine.TestField("No.", ItemNo);
        VerifyReservation(ItemNo, '', StrSubstNo('%1|%2', DATABASE::"Item Ledger Entry", DATABASE::"Sales Line"), SalesLine.Quantity);
    end;

    local procedure VerifyReservation(ItemNo: Code[20]; LocationCode: Code[10]; SourceTypeFilter: Text; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservationEntry(ReservationEntry, ItemNo, LocationCode, SourceTypeFilter, Quantity);
        Assert.RecordCount(ReservationEntry, 2);
    end;

    local procedure VerifyServiceLineByItemNoWithReservation(var ServiceLine: Record "Service Line"; ItemNo: Code[20])
    begin
        ServiceLine.Find();
        ServiceLine.TestField("No.", ItemNo);
        VerifyReservation(ItemNo, '', StrSubstNo('%1|%2', DATABASE::"Item Ledger Entry", DATABASE::"Service Line"), ServiceLine.Quantity);
    end;

    local procedure VerifyProdOrderComponentByItemNoWithReservation(var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20])
    begin
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Item No.", ItemNo);
        VerifyReservation(
          ItemNo, '', StrSubstNo('%1|%2', DATABASE::"Item Ledger Entry", DATABASE::"Prod. Order Component"),
          ProdOrderComponent."Remaining Quantity");
    end;

    local procedure VerifyAssemblyLineByItemNoWithReservation(var AssemblyLine: Record "Assembly Line"; ItemNo: Code[20])
    begin
        AssemblyLine.Find();
        AssemblyLine.TestField("No.", ItemNo);
        VerifyReservation(ItemNo, '', StrSubstNo('%1|%2', DATABASE::"Item Ledger Entry", DATABASE::"Assembly Line"), AssemblyLine.Quantity);
    end;

    local procedure VerifyItemLedgerEntryByEntryTypeAndQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal; "Count": Integer)
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange(Quantity, Quantity);
        Assert.RecordCount(ItemLedgerEntry, Count);
    end;

    [ModalPageHandler]
    procedure CheckPurchaseInvoiceLinesModalPageHandler(var PostedPurchaseInvoiceLines: TestPage "Posted Purchase Invoice Lines")
    var
        VendorNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Vendor No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedPurchaseInvoiceLines.First();
        repeat
            if PostedPurchaseInvoiceLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedPurchaseInvoiceLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedPurchaseInvoiceLines.Quantity.Value()));
                Assert.AreEqual(VendorNo, PostedPurchaseInvoiceLines."Buy-from Vendor No.".Value(), StrSubstNo(DocumentLineSourceNoErr, VendorNo, PostedPurchaseInvoiceLines."Buy-from Vendor No.".Value()));
            end;
        until not PostedPurchaseInvoiceLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure CheckPurchaseReceiptLinesModalPageHandler(var PostedPurchaseReceiptLines: TestPage "Posted Purchase Receipt Lines")
    var
        VendorNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Vendor No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedPurchaseReceiptLines.First();
        repeat
            if PostedPurchaseReceiptLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedPurchaseReceiptLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedPurchaseReceiptLines.Quantity.Value()));
                Assert.AreEqual(VendorNo, PostedPurchaseReceiptLines."Buy-from Vendor No.".Value(), StrSubstNo(DocumentLineSourceNoErr, VendorNo, PostedPurchaseReceiptLines."Buy-from Vendor No.".Value()));
            end;
        until not PostedPurchaseReceiptLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure CheckPurchaseCreditMemoLinesModalPageHandler(var PostedPurchaseCrMemoLines: TestPage "Posted Purchase Cr. Memo Lines")
    var
        VendorNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Vendor No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedPurchaseCrMemoLines.First();
        repeat
            if PostedPurchaseCrMemoLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedPurchaseCrMemoLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedPurchaseCrMemoLines.Quantity.Value()));
                Assert.AreEqual(VendorNo, PostedPurchaseCrMemoLines."Buy-from Vendor No.".Value(), StrSubstNo(DocumentLineSourceNoErr, VendorNo, PostedPurchaseCrMemoLines."Buy-from Vendor No.".Value()));
            end;
        until not PostedPurchaseCrMemoLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure CheckPurchaseReturnShipmentLinesModalPageHandler(var PostedReturnShipmentLines: TestPage "Posted Return Shipment Lines")
    var
        VendorNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Vendor No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedReturnShipmentLines.First();
        repeat
            if PostedReturnShipmentLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedReturnShipmentLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedReturnShipmentLines.Quantity.Value()));
                Assert.AreEqual(VendorNo, PostedReturnShipmentLines."Buy-from Vendor No.".Value(), StrSubstNo(DocumentLineSourceNoErr, VendorNo, PostedReturnShipmentLines."Buy-from Vendor No.".Value()));
            end;
        until not PostedReturnShipmentLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure CheckSalesInvoiceLinesModalPageHandler(var PostedSalesInvoiceLines: TestPage "Posted Sales Invoice Lines")
    var
        CustomerNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Customer No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedSalesInvoiceLines.First();
        repeat
            if PostedSalesInvoiceLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedSalesInvoiceLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedSalesInvoiceLines.Quantity.Value()));
                Assert.AreEqual(CustomerNo, PostedSalesInvoiceLines."Sell-to Customer No.".Value(), StrSubstNo(DocumentLineSourceNoErr, CustomerNo, PostedSalesInvoiceLines."Sell-to Customer No.".Value()));
            end;
        until not PostedSalesInvoiceLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure CheckSalesShipmentLinesModalPageHandler(var PostedSalesShipmentLines: TestPage "Posted Sales Shipment Lines")
    var
        CustomerNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Customer No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedSalesShipmentLines.First();
        repeat
            if PostedSalesShipmentLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedSalesShipmentLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedSalesShipmentLines.Quantity.Value()));
                Assert.AreEqual(CustomerNo, PostedSalesShipmentLines."Sell-to Customer No.".Value(), StrSubstNo(DocumentLineSourceNoErr, CustomerNo, PostedSalesShipmentLines."Sell-to Customer No.".Value()));
            end;
        until not PostedSalesShipmentLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure CheckSalesCreditMemoLinesModalPageHandler(var PostedSalesCreditMemoLines: TestPage "Posted Sales Credit Memo Lines")
    var
        CustomerNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Customer No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedSalesCreditMemoLines.First();
        repeat
            if PostedSalesCreditMemoLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedSalesCreditMemoLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedSalesCreditMemoLines.Quantity.Value()));
                Assert.AreEqual(CustomerNo, PostedSalesCreditMemoLines."Sell-to Customer No.".Value(), StrSubstNo(DocumentLineSourceNoErr, CustomerNo, PostedSalesCreditMemoLines."Sell-to Customer No.".Value()));
            end;
        until not PostedSalesCreditMemoLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure CheckSalesReturnReceiptLinesModalPageHandler(var PostedReturnReceiptLines: TestPage "Posted Return Receipt Lines")
    var
        CustomerNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Customer No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedReturnReceiptLines.First();
        repeat
            if PostedReturnReceiptLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedReturnReceiptLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedReturnReceiptLines.Quantity.Value()));
                Assert.AreEqual(CustomerNo, PostedReturnReceiptLines."Sell-to Customer No.".Value(), StrSubstNo(DocumentLineSourceNoErr, CustomerNo, PostedReturnReceiptLines."Sell-to Customer No.".Value()));
            end;
        until not PostedReturnReceiptLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure ServiceShipmentLinesModalPageHandler_RunItemInvoiceLines(var PostedServiceShipmentLines: TestPage "Posted Service Shipment Lines")
    begin
        PostedServiceShipmentLines.First();
        PostedServiceShipmentLines.ItemInvoiceLines.Invoke();
    end;

    [ModalPageHandler]
    procedure CheckServiceInvoiceLinesModalPageHandler(var PostedServiceInvoiceLines: TestPage "Posted Service Invoice Lines")
    var
        CustomerNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Customer No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedServiceInvoiceLines.First();
        repeat
            if PostedServiceInvoiceLines.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedServiceInvoiceLines.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedServiceInvoiceLines.Quantity.Value()));
                Assert.AreEqual(CustomerNo, PostedServiceInvoiceLines."Customer No.".Value(), StrSubstNo(DocumentLineSourceNoErr, CustomerNo, PostedServiceInvoiceLines."Customer No.".Value()));
            end;
        until not PostedServiceInvoiceLines.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    procedure CheckServiceShipmentLinesModalPageHandler(var PostedServShptLineList: TestPage "Posted Serv. Shpt. Line List")
    var
        CustomerNo: Code[20];
        LineCount: Integer;
        Quantity: Integer;
    begin
        // [THEN] The 'Quantity' invoice lines are found each with the expected "Customer No." and quantity
        Quantity := LibraryVariableStorage.DequeueInteger();
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        PostedServShptLineList.First();
        repeat
            if PostedServShptLineList.Quantity.Value() <> '' then begin
                LineCount += 1;
                Assert.AreEqual('1', PostedServShptLineList.Quantity.Value(), StrSubstNo(DocumentLineQuantityErr, PostedServShptLineList.Quantity.Value()));
                Assert.AreEqual(CustomerNo, PostedServShptLineList."Customer No.".Value(), StrSubstNo(DocumentLineSourceNoErr, CustomerNo, PostedServShptLineList."Customer No.".Value()));
            end;
        until not PostedServShptLineList.Next();
        Assert.AreEqual(Quantity, LineCount, StrSubstNo(DocumentCountErr, Quantity, LineCount));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionEntriesOKModalPageHandler(var ItemSubstitutionEntries: TestPage "Item Substitution Entries")
    begin
        ItemSubstitutionEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemSubstitutionsOKModalPageHandler(var ServiceItemSubstitutions: TestPage "Service Item Substitutions")
    begin
        ServiceItemSubstitutions.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionEntriesCancelModalPageHandler(var ItemSubstitutionEntries: TestPage "Item Substitution Entries")
    begin
        ItemSubstitutionEntries.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemSubstitutionsCancelModalPageHandler(var ServiceItemSubstitutions: TestPage "Service Item Substitutions")
    begin
        ServiceItemSubstitutions.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesSelectItemSubstitutionAndRevertToOldNoModalPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        OldItemNo: Code[20];
    begin
        ServiceLines.First();
        OldItemNo := ServiceLines."No.".Value();
        ServiceLines.SelectItemSubstitution.Invoke();

        ServiceLine.SetRange("Document Type", LibraryVariableStorage.DequeueInteger());
        ServiceLine.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        ServiceLine.FindFirst();
        VerifyServiceLineByItemNoWithReservation(ServiceLine, CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ServiceLine."No.")));

        ServiceLineReserve.DeleteLine(ServiceLine);
        ServiceLines."No.".SetValue(OldItemNo);
        VerifyServiceLineByItemNoWithReservation(ServiceLine, OldItemNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesSelectItemSubstitutionModalPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines.First();
        ServiceLines.SelectItemSubstitution.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(ConfirmMessage, LocalMessage) > 0, ConfirmMessage);
        LibraryVariableStorage.Dequeue(DequeueVariable);
        Reply := DequeueVariable;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixPageHandler(var ItemStatisticsMatrix: TestPage "Item Statistics Matrix")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemStatisticsMatrix.Amount.AssertEquals(Format(DequeueVariable, 0, LibraryAccountSchedule.GetAutoFormatString()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixPageHandler2(var ItemStatisticsMatrix: TestPage "Item Statistics Matrix")
    begin
        ItemStatisticsMatrix.FindFirstField(Name, NonInvtblCostTxt);

        Assert.AreNotEqual(
          0, ItemStatisticsMatrix.Field1.AsDecimal(),
          StrSubstNo(WrongAmountValueErr, ItemStatisticsMatrix.Field1.Caption));
        Assert.AreEqual(
          0, ItemStatisticsMatrix.Field2.AsDecimal(),
          StrSubstNo(WrongAmountValueErr, ItemStatisticsMatrix.Field2.Caption));
        Assert.AreEqual(
          0, ItemStatisticsMatrix.Field3.AsDecimal(),
          StrSubstNo(WrongAmountValueErr, ItemStatisticsMatrix.Field3.Caption));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageWithSalesShipSuggestHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetSalesShipmentLines.Invoke();
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        OptionCount: Variant;
    begin
        LibraryVariableStorage.Dequeue(OptionCount);  // Dequeue variable.
        Choice := OptionCount;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    var
        ItemChargeAssignment: Variant;
        ItemChargeAssignment2: Option " ",GetShipmentLines,GetReturnReceiptLines;
    begin
        LibraryVariableStorage.Dequeue(ItemChargeAssignment);
        ItemChargeAssignment2 := ItemChargeAssignment;
        case ItemChargeAssignment2 of
            ItemChargeAssignment2::GetShipmentLines:
                ItemChargeAssignmentSales.GetShipmentLines.Invoke();
            ItemChargeAssignment2::GetReturnReceiptLines:
                ItemChargeAssignmentSales.GetReturnReceiptLines.Invoke();
        end;
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinePagePurchRcptHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentNo: Variant;
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Receipts"));
        PostedPurchaseDocumentLines.PostedRcpts.FILTER.SetFilter("Document No.", DocumentNo);
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReturnReceiptLinesPageHandler(var ReturnReceiptLines: TestPage "Return Receipt Lines")
    var
        PostedDocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostedDocumentNo);
        ReturnReceiptLines.FILTER.SetFilter("Document No.", PostedDocumentNo);
        ReturnReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentLinePageHandler(var SalesShipmentLines: TestPage "Sales Shipment Lines")
    var
        PostedDocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostedDocumentNo);
        SalesShipmentLines.FILTER.SetFilter("Document No.", PostedDocumentNo);
        SalesShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler2(var Reservation: TestPage Reservation)
    begin
        Reservation.First();
        Reservation."Total Quantity".AssertEquals(0);
        Reservation."Summary Type".AssertEquals('');
    end;

    local procedure MoveNegativeLines(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        Commit(); // Commit required before invoke Move Negative Lines.
        SalesReturnOrder.MoveNegativeLines.Invoke();
    end;

    local procedure MoveNegativeLinesOnSalesOrder(SalesHeader: Record "Sales Header")
    var
        MoveNegSalesLines: Report "Move Negative Sales Lines";
        FromDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo";
        ToDocType: Option ,,"Order",Invoice,"Return Order","Credit Memo";
    begin
        MoveNegSalesLines.SetSalesHeader(SalesHeader);
        MoveNegSalesLines.InitializeRequest(FromDocType::Order, ToDocType::"Return Order", ToDocType::"Return Order");
        MoveNegSalesLines.UseRequestPage(false);
        MoveNegSalesLines.RunModal();
    end;

    local procedure CreateNonInvItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
        Commit();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MoveNegativeSalesLinesHandler(var MoveNegativeSalesLines: TestRequestPage "Move Negative Sales Lines")
    begin
        MoveNegativeSalesLines.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure UndoReceiptOfReceivedJobAndVerifyQuantitiesOfLedger(Item: Record Item)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // [GIVEN] Purchase order "P" with one line "L" of "I" where fields "Job No." and "Job Task No." with values "J" and "JT" are populated, quantity "Q" of "I"
        Quantity := LibraryRandom.RandInt(10);
        CreateJobRelatedPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", Quantity);

        // [GIVEN] The Receive of "P" is posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo receipt of line of "P"
        FindPurchRcptLine(PurchRcptLine, Item."No.");
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] No errors occur, "L"."Qty. to Receive" is equal to "Q"
        PurchaseLine.Find();
        PurchaseLine.TestField("Qty. to Receive", Quantity);

        // [THEN] "Item Ledger Entry" contains 4 records "ILE" for "I", "J", "JT", "Applies-to Entry" are blank
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Applies-to Entry", 0);
        ItemLedgerEntry.SetRange("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.SetRange("Job Task No.", PurchaseLine."Job Task No.");
        Assert.RecordCount(ItemLedgerEntry, 4);

        // [THEN] among "ILE" two records have "Entry Type" = Purchase and Quantities "Q" and -"Q"
        VerifyItemLedgerEntryByEntryTypeAndQuantity(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine.Quantity, 1);
        VerifyItemLedgerEntryByEntryTypeAndQuantity(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Negative Adjmt.", -PurchaseLine.Quantity, 1);

        // [THEN] and two records have "Entry Type" = "Negative Adjmt." and Quantities "Q" and -"Q"
        VerifyItemLedgerEntryByEntryTypeAndQuantity(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, -PurchaseLine.Quantity, 1);
        VerifyItemLedgerEntryByEntryTypeAndQuantity(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Negative Adjmt.", PurchaseLine.Quantity, 1);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderHandler(var SalesOrder: TestPage "Sales Order")
    var
        UnitPrice: Variant;
        LineDiscount: Variant;
    begin
        LibraryVariableStorage.Dequeue(UnitPrice);
        LibraryVariableStorage.Dequeue(LineDiscount);
        SalesOrder.SalesLines."Unit Price".AssertEquals(UnitPrice);
        SalesOrder.SalesLines."Line Discount %".AssertEquals(LineDiscount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagePageHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.OK().Invoke();
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}
