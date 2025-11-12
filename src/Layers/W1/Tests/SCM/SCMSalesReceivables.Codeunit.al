codeunit 137062 "SCM Sales & Receivables"
{
    Permissions = TableData "Date Compr. Register" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        Initialized := false;
    end;

    var
        LocationSilver: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        NumberofLineErr: Label 'Number of Line must be same.';
        QuantityErr: Label 'Quantity must be same.';
        QtyToReceiveErr: Label 'Qty. to Receive must be equal.';
        QtyToInvoiceErr: Label 'Qty. to invoice must be equal.';
        QtyToShipErr: Label 'Qty. to ship must be equal.';
        LibraryDimension: Codeunit "Library - Dimension";
        NoOfRecordsErr: Label 'No of records must be same.';
        LineDiscountErr: Label 'Line Discount Percentage must be same.';
        LineDiscountAmountErr: Label 'Line Discount Amount must be same.';
        UnitPriceErr: Label 'Unit price must be same.';
        DimensionErr: Label 'Check Dimension Code.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Initialized: Boolean;
        AutomaticReservationMsg: Label 'Automatic reservation is not possible.';
        UndoShipmentQst: Label 'Do you really want to undo the selected Shipment lines?';
        DeletesEntriesMsg: Label 'This batch job deletes entries';
        UpdateAnalysisViewsQst: Label 'Do you wish to update these analysis views?';
        PostDocConfirmQst: Label 'Do you want to post the %1?', Comment = '%1 = Document Type';
        ShipConfirmQst: Label 'Do you want to post the shipment?';
        ShipInvoiceConfirmQst: Label 'Do you want to post the shipment and invoice?';
        ReceiveConfirmQst: Label 'Do you want to post the receipt?';
        ReceiveInvoiceConfirmQst: Label 'Do you want to post the receipt and invoice?';
        CannotPostInvoiceErr: Label 'You cannot post the invoice';

    [Test]
    [Scope('OnPrem')]
    procedure B34576_CopyDocPostedSalesInv()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        Quantity: Decimal;
        DocumentNo: Code[20];
    begin
        // Create Credit Memo using Copy Document of Posted Sales Invoice.
        // 1. Setup.
        Initialize();
        CreateItemWithReserveAlways(Item);
        CustomerNo := LibrarySales.CreateCustomerNo();
        Quantity := LibraryRandom.RandDec(10, 2);

        UpdateItemInventory(Item."No.", Quantity * 2);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, Item."No.", Quantity);
        UpdateLocationOnSalesLine(SalesLine, '');
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2. Exercise:
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);

        // 3. Verify: verify Sales line Quantity.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", Item."No.");
        Assert.AreEqual(1, SalesLine.Count, NumberofLineErr);  // Value is important for Test.
        SalesLine.FindFirst();
        Assert.AreEqual(Quantity, SalesLine.Quantity, QuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B34576_CopyDocSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        LastSalesOrderNo: Text[20];
        Quantity: Decimal;
    begin
        // Create Credit Memo using Copy Document of Sales Order.
        // 1. Setup.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        CreateItemWithReserveAlways(Item);
        CustomerNo := LibrarySales.CreateCustomerNo();
        Quantity := LibraryRandom.RandDec(10, 2);

        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, Item."No.", Quantity);
        UpdateLocationOnSalesLine(SalesLine, '');
        LastSalesOrderNo := SalesHeader."No.";

        // 2. Exercise:
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::Order, LastSalesOrderNo, true, false);

        // 3. Verify: verify Sales line Quantity
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", Item."No.");
        Assert.AreEqual(1, SalesLine.Count, NumberofLineErr);  // Value is important for Test.
        SalesLine.FindFirst();
        Assert.AreEqual(Quantity, SalesLine.Quantity, QuantityErr);
    end;

    [Test]
    [HandlerFunctions('RetrieveDimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure B35809_SalesPriceUOMSame()
    var
        ChildItem: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure2: Record "Unit of Measure";
        QtyOfUOMPerUOM2: Decimal;
    begin
        // Verify Unit price in Sales line when Sales price with same UOM.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        QtyOfUOMPerUOM2 := 2 + LibraryRandom.RandInt(3);   // Value greater than 2 is important for Test.
        CreateItemWithMultipleUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, QtyOfUOMPerUOM2);
        B35809_SalesPriceUOMB(ChildItem, UnitOfMeasure, UnitOfMeasure2, UnitOfMeasure.Code, QtyOfUOMPerUOM2);
    end;

    [Test]
    [HandlerFunctions('RetrieveDimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure B35809_SalesPriceUOMDiff()
    var
        ChildItem: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure2: Record "Unit of Measure";
        QtyOfUOMPerUOM2: Decimal;
    begin
        // Verify Unit price in Sales line when Sales price with different UOM.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        QtyOfUOMPerUOM2 := 2 + LibraryRandom.RandInt(3);  // Value greater than 2 is important for Test.
        CreateItemWithMultipleUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, QtyOfUOMPerUOM2);
        B35809_SalesPriceUOMB(ChildItem, UnitOfMeasure, UnitOfMeasure2, UnitOfMeasure2.Code, QtyOfUOMPerUOM2);
    end;

    [Test]
    [HandlerFunctions('RetrieveDimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure B35809_SalesPriceUOMBlank()
    var
        ChildItem: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure2: Record "Unit of Measure";
        QtyOfUOMPerUOM2: Decimal;
    begin
        // Verify Unit price in Sales line when Sales price with Blank UOM.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        QtyOfUOMPerUOM2 := 2 + LibraryRandom.RandInt(3);  // Value greater than 2 is important for Test.
        CreateItemWithMultipleUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, QtyOfUOMPerUOM2);
        B35809_SalesPriceUOMB(ChildItem, UnitOfMeasure, UnitOfMeasure2, '', QtyOfUOMPerUOM2);
    end;

    local procedure B35809_SalesPriceUOMB(var Item: Record Item; var UnitOfMeasure: Record "Unit of Measure"; var UnitOfMeasure2: Record "Unit of Measure"; SalesPriceUnitOfMeasure: Code[10]; QtyOfUOMPerUOM: Decimal)
    var
        ParentItem: Record Item;
        ItemVariant: Record "Item Variant";
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        UnitPriceOnItemCard: Decimal;
        UnitCostOnItemCard: Decimal;
        UnitSalesPrice: Decimal;
    begin
        // Verify Unit price in Sales line when Sales price with Blank UOM.
        // 1. Setup.
        UnitCostOnItemCard := LibraryRandom.RandDec(100, 2);
        UnitPriceOnItemCard := LibraryRandom.RandDec(100, 2);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // Update item with 3 UOMs,variant code  and Unit price.
        UpdateChildItem(Item, UnitOfMeasure.Code, UnitPriceOnItemCard, UnitCostOnItemCard);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // Create assembly item for 2 UOM of above child item.
        LibraryInventory.CreateItem(ParentItem);
        CreateBOMComponentWithUOM(ParentItem."No.", Item."No.", 2, UnitOfMeasure2.Code, ItemVariant.Code);
        UnitSalesPrice := LibraryRandom.RandDec(100, 2);

        // Change sales price UOM from UOM to <blank>.
        SalesPrice.DeleteAll(true);
        LibraryCosting.CreateSalesPrice(
          SalesPrice, "Sales Price Type"::"All Customers", '', Item."No.", WorkDate(), '', ItemVariant.Code, SalesPriceUnitOfMeasure, 0);
        SalesPrice.Validate("Unit Price", UnitSalesPrice);
        SalesPrice.Modify(true);

        CopyAllSalesPriceToPriceListLine();
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", CustomerNo);

        // 2. Exercise:
        LibrarySales.ExplodeBOM(SalesLine);

        // 3. Verify: Verfiy Unit Price in Sales line.
        VerifySalesUnitPrice(Item."No.", QtyOfUOMPerUOM, UnitPriceOnItemCard, UnitSalesPrice, UnitOfMeasure2.Code, UnitOfMeasure.Code);
    end;

    local procedure CopyAllSalesPriceToPriceListLine()
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();

        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
    end;

    local procedure CopyAllPurchPriceToPriceListLine()
    var
        PurchPrice: Record "Purchase Price";
        PurchLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();

        CopyFromToPriceListLine.CopyFrom(PurchPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(PurchLineDiscount, PriceListLine);
    end;

    [Test]
    [HandlerFunctions('RetrieveDimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure B35809_PurchasePriceUOMSame()
    var
        ChildItem: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure2: Record "Unit of Measure";
        QtyOfUOMPerUOM2: Decimal;
    begin
        // Verify Direct Unit Cost in Purchase line when Purchase price with same UOM.
        Initialize();

        QtyOfUOMPerUOM2 := 2 + LibraryRandom.RandInt(3);  // Value greater than 2 is important for Test.
        CreateItemWithMultipleUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, QtyOfUOMPerUOM2);
        B35809_PurchasePriceUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, UnitOfMeasure.Code, QtyOfUOMPerUOM2);
    end;

    [Test]
    [HandlerFunctions('RetrieveDimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure B35809_PurchasePriceUOMDiff()
    var
        ChildItem: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure2: Record "Unit of Measure";
        QtyOfUOMPerUOM2: Decimal;
    begin
        // Verify Direct Unit Cost in Purchase line when Purchase price with different UOM.
        Initialize();

        QtyOfUOMPerUOM2 := 2 + LibraryRandom.RandInt(3);  // Value greater than 2 is important for Test.
        CreateItemWithMultipleUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, QtyOfUOMPerUOM2);
        B35809_PurchasePriceUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, UnitOfMeasure2.Code, QtyOfUOMPerUOM2);
    end;

    [Test]
    [HandlerFunctions('RetrieveDimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure B35809_PurchasePriceUOMBlank()
    var
        ChildItem: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure2: Record "Unit of Measure";
        QtyOfUOMPerUOM2: Decimal;
    begin
        // Verify Direct Unit Cost in Purchase line when Purchase price with blank UOM.
        Initialize();
        QtyOfUOMPerUOM2 := 2 + LibraryRandom.RandInt(3);  // Value greater than 2 is important for Test.
        CreateItemWithMultipleUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, QtyOfUOMPerUOM2);
        B35809_PurchasePriceUOM(ChildItem, UnitOfMeasure, UnitOfMeasure2, '', QtyOfUOMPerUOM2);
    end;

    local procedure B35809_PurchasePriceUOM(var Item: Record Item; var UnitOfMeasure: Record "Unit of Measure"; var UnitOfMeasure2: Record "Unit of Measure"; PurchPriceUnitOfMeasure: Code[10]; QtyOfUOMPerUOM: Decimal)
    var
        ParentItem: Record Item;
        ItemVariant: Record "Item Variant";
        PurchasePrice: Record "Purchase Price";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        UnitPriceOnItemCard: Decimal;
        UnitCostOnItemCard: Decimal;
        UnitPurchasePrice: Decimal;
    begin
        // Verify Direct Unit Cost in Purchase line when Purchase price with blank UOM.
        // 1. Setup.
        UnitCostOnItemCard := LibraryRandom.RandDec(100, 2);
        UnitPriceOnItemCard := LibraryRandom.RandDec(100, 2);
        VendorNo := LibraryPurchase.CreateVendorNo();

        // Update item with 3 UOMs,variant code  and Unit price.
        UpdateChildItem(Item, UnitOfMeasure.Code, UnitPriceOnItemCard, UnitCostOnItemCard);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // Create assembly item for 2 UOM2 of above child item.
        LibraryInventory.CreateItem(ParentItem);
        CreateBOMComponentWithUOM(ParentItem."No.", Item."No.", 2, UnitOfMeasure2.Code, ItemVariant.Code);

        UnitPurchasePrice := LibraryRandom.RandDec(100, 2);

        // Change purchase price UOM from UOM to <blank>.
        PurchasePrice.DeleteAll(true);
        LibraryCosting.CreatePurchasePrice(PurchasePrice, VendorNo, Item."No.", WorkDate(), '', ItemVariant.Code, PurchPriceUnitOfMeasure, 0);
        PurchasePrice.Validate("Direct Unit Cost", UnitPurchasePrice);
        PurchasePrice.Modify(true);
        CopyAllPurchPriceToPriceListLine();
        CreatePurchOrder(PurchaseHeader, PurchaseLine, ParentItem."No.", VendorNo);

        // 2. Exercise:
        LibraryPurchase.ExplodeBOM(PurchaseLine);

        // 3. Verify: Verfiy Unit Price in Purchase line.
        VerifyPurchUnitPrice(
          Item."No.", QtyOfUOMPerUOM, UnitCostOnItemCard, UnitPurchasePrice, UnitOfMeasure2.Code, UnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B43940_SameDimDateCompress()
    var
        Item: Record Item;
        ItemBudgetEntry: Record "Item Budget Entry";
        DateComprRegister: Record "Date Compr. Register";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionValue3: Record "Dimension Value";
        ItemBudgetName: Record "Item Budget Name";
        DateCompression: Codeunit "Date Compression";
        PeriodLength: Option Day,Week,Month,Quarter,Year,Period;
        DimensionCode: Code[20];
        DimensionCode2: Code[20];
        DimensionCode3: Code[20];
        DimensionCode4: Code[20];
        DimensionCode5: Code[20];
    begin
        // Run Date Compress Item Budget Entries when Same dimension in both Item Budget entry lines.
        // 1. Setup.
        Initialize();
        ClearEntries();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryInventory.CreateItem(Item);

        // Same Dimensions in both Item Budget Entry Lines.
        GeneralLedgerSetup.Get();
        DimensionCode := GeneralLedgerSetup."Global Dimension 1 Code";
        DimensionCode2 := GeneralLedgerSetup."Global Dimension 2 Code";
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.FindDimensionValue(DimensionValue2, DimensionCode2);

        ItemBudgetName.SetRange("Analysis Area", ItemBudgetName."Analysis Area"::Sales);
        ItemBudgetName.SetFilter("Budget Dimension 1 Code", '<> %1', '');
        ItemBudgetName.SetFilter("Budget Dimension 2 Code", '<> %1', '');
        ItemBudgetName.FindFirst();

        DimensionCode3 := ItemBudgetName."Budget Dimension 1 Code";
        DimensionCode4 := ItemBudgetName."Budget Dimension 2 Code";
        DimensionCode5 := ItemBudgetName."Budget Dimension 3 Code";
        LibraryDimension.FindDimensionValue(DimensionValue3, DimensionCode3);

        // Create Item Budget Entries.
        CreateItemBudgetEntry(Item, CalcDate('<-123D>', DateCompression.CalcMaxEndDate()), DimensionValue.Code, DimensionValue2.Code, DimensionValue3.Code);
        CreateItemBudgetEntry(Item, CalcDate('<-122D>', DateCompression.CalcMaxEndDate()), DimensionValue.Code, DimensionValue2.Code, DimensionValue3.Code);
        ItemBudgetEntry.SetRange("Budget Dimension 1 Code", DimensionValue3.Code); // filtering on created.

        // Create Selected Dimensions for Date Compress.
        CreateDimForBudgetEntry(DimensionCode, DimensionCode2, DimensionCode3, DimensionCode4, DimensionCode5);

        // 2. Exercise: Run Date compress entries.
        LibraryVariableStorage.Enqueue(DeletesEntriesMsg);  // Enqueue Value for Confirm Handler.
        LibraryVariableStorage.Enqueue(UpdateAnalysisViewsQst);  // Enqueue Value for Confirm Handler.
        LibraryInventory.DateComprItemBudgetEntries(
          ItemBudgetEntry, 0, CalcDate('<-CY>', DateCompression.CalcMaxEndDate()), DateCompression.CalcMaxEndDate(), PeriodLength::Month, LibraryUtility.GenerateGUID());

        // 3. Verify: verify compressed Item Budget Entries and date compresed Item Budget Entries.
        VerifyDimension(ItemBudgetEntry, 1, DimensionValue.Code, DimensionValue2.Code);  // Value is important for Test.
        DateComprRegister.SetRange("Table ID", DATABASE::"Item Budget Entry");
        VerifyDateComprRegister(DateComprRegister, 1, '1', '2');  // Value is important for Test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B43940_DiffDimDateCompress()
    var
        Item: Record Item;
        ItemBudgetEntry: Record "Item Budget Entry";
        DateComprRegister: Record "Date Compr. Register";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionValue3: Record "Dimension Value";
        ItemBudgetName: Record "Item Budget Name";
        DateCompression: Codeunit "Date Compression";
        PeriodLength: Option Day,Week,Month,Quarter,Year,Period;
        DimensionCode: Code[20];
        DimensionCode2: Code[20];
        DimensionCode3: Code[20];
        DimensionCode4: Code[20];
        DimensionCode5: Code[20];
    begin
        // Run Date Compress Item Budget Entries when Different dimension in both Item Budget entry lines.
        // 1. Setup.
        Initialize();
        ClearEntries();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryInventory.CreateItem(Item);

        // Different Dimensions in both Item Budget Entry lines.
        GeneralLedgerSetup.Get();
        DimensionCode := GeneralLedgerSetup."Global Dimension 1 Code";
        DimensionCode2 := GeneralLedgerSetup."Global Dimension 2 Code";
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.FindDimensionValue(DimensionValue2, DimensionCode2);

        ItemBudgetName.SetRange("Analysis Area", ItemBudgetName."Analysis Area"::Sales);
        ItemBudgetName.SetFilter("Budget Dimension 1 Code", '<> %1', '');
        ItemBudgetName.SetFilter("Budget Dimension 2 Code", '<> %1', '');
        ItemBudgetName.FindFirst();

        DimensionCode3 := ItemBudgetName."Budget Dimension 1 Code";
        DimensionCode4 := ItemBudgetName."Budget Dimension 2 Code";
        DimensionCode5 := ItemBudgetName."Budget Dimension 3 Code";
        LibraryDimension.FindDimensionValue(DimensionValue3, DimensionCode3);

        // Create Item Budget Entries.
        CreateItemBudgetEntry(Item, CalcDate('<-123D>', DateCompression.CalcMaxEndDate()), DimensionValue.Code, '', DimensionValue3.Code);
        CreateItemBudgetEntry(Item, CalcDate('<-122D>', DateCompression.CalcMaxEndDate()), '', DimensionValue2.Code, DimensionValue3.Code);
        ItemBudgetEntry.SetRange("Budget Dimension 1 Code", DimensionValue3.Code); // filtering on created.

        // Create Selected Dimension for Date Compress.
        CreateDimForBudgetEntry(DimensionCode, DimensionCode2, DimensionCode3, DimensionCode4, DimensionCode5);

        // 2. Exercise: Run Date compress entries.
        LibraryVariableStorage.Enqueue(DeletesEntriesMsg);  // Enqueue Value for Confirm Handler.
        LibraryVariableStorage.Enqueue(UpdateAnalysisViewsQst);  // Enqueue Value for Confirm Handler.
        LibraryInventory.DateComprItemBudgetEntries(
          ItemBudgetEntry, 0, CalcDate('<-CY>', DateCompression.CalcMaxEndDate()), DateCompression.CalcMaxEndDate(), PeriodLength::Month, LibraryUtility.GenerateGUID());

        // 3. Verify: verify compressed Item Budget Entries and date compresed Item Budget Entries.
        // Value is important for Test.
        VerifyDimension(ItemBudgetEntry, 2, Format(DimensionValue.Code + ','), Format(',' + DimensionValue2.Code));
        VerifyDateComprRegister(DateComprRegister, 1, '2', '2');
    end;

    [Test]
    [HandlerFunctions('RetrieveDimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure B43974_SalesExplodeBOM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        Item5: Record Item;
        LineDate: Date;
    begin
        // Create a Sales Order with one line of BOM and verify Sales line.
        // 1. Setup: Create Child and Parent Item.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        LineDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);
        LibraryInventory.CreateItem(Item4);
        LibraryInventory.CreateItem(Item5);

        CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item2."No.");
        CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item3."No.");
        CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item4."No.");
        CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item5."No.");

        // Create a Sales Order with one line of BOM.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        SalesHeader.Validate("Location Code", '');
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Shipment Date", LineDate);
        SalesLine.Modify(true);

        // 2. Exercise:
        LibrarySales.ExplodeBOM(SalesLine);

        // 3. Verify: verify results of Sales lines.
        VerifySalesLine(SalesLine."Document Type"::Order, SalesHeader."No.", 5, LineDate);  // Value is important for Test.
    end;

    [Test]
    [HandlerFunctions('RetrieveDimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure B43974_PurchaseExplodeBOM()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        Item5: Record Item;
        LineDate: Date;
    begin
        // Create a Purchase Order with one line of BOM and verify Purchase line.
        // 1. Setup: Create Child and Parent Item.
        Initialize();
        LineDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);
        LibraryInventory.CreateItem(Item4);
        LibraryInventory.CreateItem(Item5);

        CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item2."No.");
        CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item3."No.");
        CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item4."No.");
        CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item5."No.");

        // Create a Purchase Order with one line of BOM.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Expected Receipt Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        PurchaseHeader.Validate("Location Code", '');
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Expected Receipt Date", LineDate);
        PurchaseLine.Modify(true);

        // 2. Exercise:
        LibraryPurchase.ExplodeBOM(PurchaseLine);

        // 3. Verify: verify results of purchase lines.
        VerifyPurchaseLine(PurchaseLine."Document Type"::Order, PurchaseHeader."No.", 5, LineDate);  // Value is important for Test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44247_SalesCopyDocWithDisc()
    var
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        OldLineDiscountPercent: Decimal;
        OldUnitPrice: Decimal;
        OldLineDiscountAmount: Decimal;
        NewLineDiscountPercent: Decimal;
        NewUnitPrice: Decimal;
        NewLineDiscountAmount: Decimal;
    begin
        // Create Sales Credit Memo with copy Document and verify Discount.
        // 1. Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        OldUnitPrice := LibraryRandom.RandDec(100, 2);
        OldLineDiscountPercent := LibraryRandom.RandInt(20);
        LibraryInventory.CreateItem(Item);

        // 2. Exercise: Create Sales Invoice,Post Invoice,Create a Credit Memo and copy document from old Posted Invoice.
        DiscountCopyDocumentSales(
          Item, OldLineDiscountPercent, OldUnitPrice, OldLineDiscountAmount, NewLineDiscountPercent, NewUnitPrice, NewLineDiscountAmount);

        // 3. Verify: Verify the line discount being copied.
        Assert.AreEqual(OldLineDiscountPercent, NewLineDiscountPercent, LineDiscountErr);
        Assert.AreEqual(OldLineDiscountAmount, NewLineDiscountAmount, LineDiscountAmountErr);
        Assert.AreEqual(OldUnitPrice, NewUnitPrice, UnitPriceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44247_PurchaseCopyDocWithDisc()
    var
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        OldLineDiscountPercent: Decimal;
        OldUnitPrice: Decimal;
        OldLineDiscountAmount: Decimal;
        NewLineDiscountPercent: Decimal;
        NewUnitPrice: Decimal;
        NewLineDiscountAmount: Decimal;
    begin
        // Create Purchase Credit Memo with copy Document and verify Discount.
        // 1. Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        OldUnitPrice := LibraryRandom.RandDec(100, 2);
        OldLineDiscountPercent := LibraryRandom.RandInt(20);
        LibraryInventory.CreateItem(Item);

        // 2. Exercise: Create Purchase Invoice,Post Invoice,Create a Credit Memo and copy document from old Posted Invoice.
        DiscountCopyDocumentPurch(
          Item, OldLineDiscountPercent, OldUnitPrice, OldLineDiscountAmount, NewLineDiscountPercent, NewUnitPrice, NewLineDiscountAmount);

        // 3. Verify: Verify the line discount being copied.
        Assert.AreEqual(OldLineDiscountPercent, NewLineDiscountPercent, LineDiscountErr);
        Assert.AreEqual(OldLineDiscountAmount, NewLineDiscountAmount, LineDiscountAmountErr);
        Assert.AreEqual(OldUnitPrice, NewUnitPrice, UnitPriceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44491_SalesBlanketOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        OldQtyToShip: Decimal;
        OldQtyToInvoice: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Blanket Order after create sale order using Blanket order and create Credit Memo with copy document.
        // 1. Setup.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        LibraryInventory.CreateItem(Item);

        // Create a Blanket Order.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo(), Item."No.",
          2 * LibraryRandom.RandDec(100, 2));
        UpdateLocationOnSalesLine(SalesLine, '');

        // Create a Sales Order for Partial Quantity.
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
        SalesLine.Modify(true);
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // Post Ship and Invoice the Sales Order.
        SalesHeader2.SetRange("Document Type", SalesHeader2."Document Type"::Order);
        SalesHeader2.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesHeader2.FindFirst();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        OldQtyToShip := SalesLine."Qty. to Ship";
        OldQtyToInvoice := SalesLine."Qty. to Invoice";

        // 2. Exercise: Create a return order and copy document from the last posted invoice.
        LibrarySales.CreateSalesHeader(
          SalesHeader3, SalesHeader3."Document Type"::"Return Order", SalesHeader2."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(SalesHeader3, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);

        // 3. Verify: Verify that the Qty to Ship for the blanket order line is the same as before.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(OldQtyToShip, SalesLine."Qty. to Ship", QtyToShipErr);
        Assert.AreEqual(OldQtyToInvoice, SalesLine."Qty. to Invoice", QtyToInvoiceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44491_PurchaseBlanketOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeader3: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        OldQtyToRecv: Decimal;
        OldQtyToInvoice: Decimal;
    begin
        // 1. Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        VendorNo := LibraryPurchase.CreateVendorNo();

        // Create a blanket order.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", VendorNo, Item."No.",
          2 * LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Location Code", '');
        PurchaseLine.Modify(true);

        // Create a Purch order for Partial Quantity.
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // Post Receive and invoice of Purch Order.
        PurchaseHeader2.SetRange("Document Type", PurchaseHeader2."Document Type"::Order);
        PurchaseHeader2.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader2.FindFirst();
        PurchaseHeader2.Validate("Vendor Invoice No.", PurchaseHeader2."No.");
        PurchaseHeader2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        OldQtyToRecv := PurchaseLine."Qty. to Receive";
        OldQtyToInvoice := PurchaseLine."Qty. to Invoice";

        // 2. Exercise: Create a Return Order and copy document from the last posted invoice.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader3, PurchaseHeader3."Document Type"::"Return Order", PurchaseHeader2."Buy-from Vendor No.");
        PurchInvHeader.SetRange("Order No.", PurchaseHeader2."No.");
        PurchInvHeader.FindFirst();
        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeader3, "Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", true, false);

        // 3. Verify: Verify that the Qty to Ship for the blanket order line is the same as before.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(OldQtyToRecv, PurchaseLine."Qty. to Receive", QtyToReceiveErr);
        Assert.AreEqual(OldQtyToInvoice, PurchaseLine."Qty. to Invoice", QtyToInvoiceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntriesforSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create Item and increase inventory.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", LibraryRandom.RandDec(100, 2));
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Post Sales Order with Ship and Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Check Value Entries for "Sales Amount (Actual)" field and the "Amount" field on Posted Sales Invoice line.
        VerifyValueEntriesForSalesOrder(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceOnPurchase()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] An Item with Item Reference exist
        LibraryInventory.CreateItem(Item);
        LibraryItemReference.CreateItemReference(
          ItemReference, Item."No.", ItemReference."Reference Type"::"Bar Code", '');

        // [GIVEN] Purchase Order with the item with the reference exist
        CreatePurchaseOrderWithItemRefNo(ItemReference, PurchaseHeader);

        // [WHEN] Post Purchase Order with Receive only.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Item Ledger Entry has item reference
        VerifyItemRefNoInItemLedgerEntry(Enum::"Item Ledger Document Type"::"Purchase Receipt", DocumentNo, ItemReference."Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceOnSales()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] An Item with Item Reference exist
        LibraryInventory.CreateItem(Item);
        LibraryItemReference.CreateItemReference(
          ItemReference, Item."No.", ItemReference."Reference Type"::"Bar Code", '');

        // [GIVEN] Sales Order with the item with the reference exist
        CreateSalesOrderWithItemRefNo(ItemReference, SalesHeader);

        // [WHEN] Post Sales Order with Ship only.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Item Ledger Entry has item reference
        VerifyItemRefNoInItemLedgerEntry(Enum::"Item Ledger Document Type"::"Sales Shipment", DocumentNo, ItemReference."Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithAvailableReservedQuantity()
    begin
        // Verify Reserved Quantity on Sales Order with Sales Return Order when Quantity available for Reservation.
        // Setup.
        Initialize();
        SalesOrderWithReservedQuantity(false);  // Multiple Sales Order as False.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFALSE,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutAvailableReservedQuantity()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Verify Reserved Quantity on Sales Order with Sales Return Order when Quantity not available for Reservation.
        // Setup.
        Initialize();
        SalesOrderWithReservedQuantity(true);  // Multiple Sales Order as True.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure SalesOrderWithReservedQuantity(MultipleSalesOrder: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesHeader3: Record "Sales Header";
        SalesLine3: Record "Sales Line";
    begin
        // Create Item with Reserve Option Always, Create Return Sales Order.
        CreateItemWithReserveAlways(Item);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order",
          LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Create Sales Orders.
        CreateSalesDocument(SalesHeader2, SalesLine2, SalesHeader2."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 0);
        UpdateQuantityOnSalesLinePage(SalesHeader2."No.", SalesLine.Quantity);
        if MultipleSalesOrder then begin
            CreateSalesDocument(SalesHeader3, SalesLine3, SalesHeader3."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 0);
            LibraryVariableStorage.Enqueue(AutomaticReservationMsg);  // Enqueue Value for Confirm Handler.
            UpdateQuantityOnSalesLinePage(SalesHeader3."No.", SalesLine.Quantity);
        end;

        // Verify: Verify Reserved Quantity on Sales Line.
        if MultipleSalesOrder then begin
            SalesLine3.CalcFields("Reserved Quantity");
            SalesLine3.TestField("Reserved Quantity", 0);  // Zero is required, Quantity not available for reservation.
        end else begin
            SalesLine2.CalcFields("Reserved Quantity");
            SalesLine2.TestField("Reserved Quantity", SalesLine.Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure UndoPostedSalesShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Bin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Setup: Create Item and Bin. Create and Post Sales Order with Ship Option.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        UpdateItemInventoryWithLocationAndBin(Item."No.", LocationSilver.Code, Bin.Code, LibraryRandom.RandDec(10, 2) + 100);  // Using large Random Value for Quantity.

        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateLocationOnSalesLine(SalesLine, LocationSilver.Code);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise: Undo Shipment on Posted Sales Shipment.
        FindSalesShipmentHeader(SalesShipmentHeader, SalesHeader."No.");
        UndoShipmentOnPostedSalesShipmentPage(SalesShipmentHeader."No.");

        // Verify: Verify Quantity on Warehouse Entry after Undo Shipment for Warehouse location.
        VerifyWarehouseEntry(SalesShipmentHeader."No.", Item."No.", WarehouseEntry."Entry Type"::"Negative Adjmt.", -SalesLine.Quantity);
        VerifyWarehouseEntry(SalesShipmentHeader."No.", Item."No.", WarehouseEntry."Entry Type"::"Positive Adjmt.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('DimStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ParentItemExtAutoTextRemainsAfterExplodeBOM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BOMComponent: Record "BOM Component";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ParentItemExtText: Text[100];
        ChildItemExtText: Text[100];
    begin
        // [FEATURE] [Production BOM] [Extended Text]
        // [SCENARIO 377475] Parent Item's Auto Extended Text remains after Explode BOM on Sales Line
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Item "A" with "Description" = "A_Desc", "Automatic Ext. Texts" = TRUE, Extended Text = "A_ExtText"
        // [GIVEN] Item "B" with "Description" = "B_Desc", "Automatic Ext. Texts" = TRUE, Extended Text = "B_ExtText"
        CreateItemWithAutoText(ParentItem, ParentItemExtText);
        CreateItemWithAutoText(ChildItem, ChildItemExtText);
        // [GIVEN] BOM Component: parent item "A" with child item "B"
        CreateBOMComponent(BOMComponent, ParentItem."No.", BOMComponent.Type::Item, ChildItem."No.");
        // [GIVEN] Sales Order with item "A" (line1) and auto inserted item's auto text "A_ExtText" (line2)
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerNo(), ParentItem."No.", LibraryRandom.RandInt(10));
        TransferSalesLineExtendedText(SalesLine);

        // [WHEN] Perform Item's Sales Line "Explode BOM" action
        LibrarySales.ExplodeBOM(SalesLine);

        // [THEN] Sales Lines are:
        // [THEN] Line1: Type = "", No = "", Description = "A_Desc", BOM Item No = "A"
        // [THEN] Line2: Type = "", No = "", Description = "A_ExtText", BOM Item No = ""
        // [THEN] Line3: Type = Item, No = "B", Description = "B_Desc", BOM Item No = "A"
        // [THEN] Line4: Type = "", No = "", Description = "B_ExtText", BOM Item No = ""
        VerifySalesLinesAfterExplodeBOMWithAutoExtTexts(SalesLine, ParentItem, ChildItem, ParentItemExtText, ChildItemExtText);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    procedure ShippingInvoicingSalesOrderWithPostingPolicy()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Order]
        // [SCENARIO 461826] Shipping and invoicing sales order with "Prohibited" and "Mandatory" settings of invoice posting policy.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), Qty, '', WorkDate());

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        LibraryVariableStorage.Enqueue(ShipConfirmQst);
        PostSalesDocument(SalesHeader);

        VerifyQtyOnSalesOrderLine(SalesLine, Qty, 0);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);

        LibraryVariableStorage.Enqueue(ShipInvoiceConfirmQst);
        PostSalesDocument(SalesHeader);

        Assert.IsFalse(SalesLine.Find(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    procedure ShippingInvoicingSalesReturnOrderWithPostingPolicy()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Return Order]
        // [SCENARIO 461826] Receiving and invoicing sales return order with "Prohibited" and "Mandatory" settings of invoice posting policy.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '',
          LibraryInventory.CreateItemNo(), Qty, '', WorkDate());

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        LibraryVariableStorage.Enqueue(ReceiveConfirmQst);
        PostSalesDocument(SalesHeader);

        VerifyQtyOnSalesReturnOrderLine(SalesLine, Qty, 0);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);

        LibraryVariableStorage.Enqueue(ReceiveInvoiceConfirmQst);
        PostSalesDocument(SalesHeader);

        Assert.IsFalse(SalesLine.Find(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,MessageHandler')]
    procedure ShippingInvoicingInventoryPickWithPostingPolicy()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Order] [Inventory Pick]
        // [SCENARIO 461826] Shipping and invoicing inventory pick with "Prohibited" and "Mandatory" settings of invoice posting policy.
        Initialize();
        Qty := 2 * LibraryRandom.RandInt(10);

        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", Qty / 2);
        WarehouseActivityLine.Modify(true);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);
        LibraryVariableStorage.Enqueue(ShipConfirmQst);
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Post (Yes/No)", WarehouseActivityLine);

        VerifyQtyOnSalesOrderLine(SalesLine, Qty / 2, 0);

        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", Qty / 2);
        WarehouseActivityLine.Modify(true);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);
        LibraryVariableStorage.Enqueue(ShipInvoiceConfirmQst);
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Post (Yes/No)", WarehouseActivityLine);

        VerifyQtyOnSalesOrderLine(SalesLine, Qty, Qty / 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    procedure CannotPostSalesInvoiceWithProhibitedPostingPolicy()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Invoice]
        // [SCENARIO 461826] Cannot post sales invoice with "Prohibited" invoice posting policy.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '',
          LibraryInventory.CreateItemNo(), Qty, '', WorkDate());

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        Commit();

        asserterror PostSalesDocument(SalesHeader);
        Assert.ExpectedError(CannotPostInvoiceErr);

        VerifyQtyOnSalesOrderLine(SalesLine, 0, 0);

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);

        LibraryVariableStorage.Enqueue(StrSubstNo(PostDocConfirmQst, LowerCase(Format(SalesHeader."Document Type"))));
        PostSalesDocument(SalesHeader);

        Assert.IsFalse(SalesLine.Find(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,ConfirmHandlerFALSE')]
    procedure InterruptPostAndSendOfSalesOrderWithShipFalse()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Posting Selection] [Order] [Post and Send]
        // [SCENARIO 464594] Sales order with "Ship" = False is not shipped if user does not confirm posting shipment in "Post and Send" action.
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader.Ship := false;
        SalesHeader.Modify();

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        LibraryVariableStorage.Enqueue(ShipConfirmQst);
        PostAndSendSalesDocument(SalesHeader);

        VerifyQtyOnSalesOrderLine(SalesLine, 0, 0);
        SalesHeader.TestField(Ship, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes,ConfirmHandlerFALSE')]
    procedure InterruptPostAndSendOfSalesOrderWithShipTrue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Posting Selection] [Order] [Post and Send]
        // [SCENARIO 464594] Sales order with "Ship" = True is not shipped if user does not confirm posting shipment in "Post and Send" action.
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader.Ship := true;
        SalesHeader.Modify();

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        LibraryVariableStorage.Enqueue(ShipConfirmQst);
        PostAndSendSalesDocument(SalesHeader);

        VerifyQtyOnSalesOrderLine(SalesLine, 0, 0);
        SalesHeader.TestField(Ship, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,MessageHandler')]
    procedure PostWhseShptForSalesOrderWithInvoicePostingPolicy()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Order] [Warehouse Shipment]
        // [SCENARIO 461826] Posting warehouse shipment for sales order with "Prohibited" settings of invoice posting policy.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), Qty, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        LibraryVariableStorage.Enqueue(ShipConfirmQst);
        PostWarehouseShipment(WarehouseShipmentHeader);

        VerifyQtyOnSalesOrderLine(SalesLine, Qty, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,MessageHandler')]
    procedure PostAndPrintWhseShptForSalesOrderWithInvoicePostingPolicy()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        SCMSalesReceivables: Codeunit "SCM Sales & Receivables";
        Qty: Decimal;
    begin
        // [FEATURE] [Posting Selection] [Order] [Warehouse Shipment]
        // [SCENARIO 471180] Posting and printing warehouse shipment for sales order with "Prohibited" settings of invoice posting policy.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), Qty, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));

        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        BindSubscription(SCMSalesReceivables);
        LibraryVariableStorage.Enqueue(ShipConfirmQst);
        PostAndPrintWarehouseShipment(WarehouseShipmentHeader);
        UnbindSubscription(SCMSalesReceivables);

        VerifyQtyOnSalesOrderLine(SalesLine, Qty, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Sales & Receivables");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Allowed);

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Sales & Receivables");

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Sales & Receivables");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(ExactCostReversingMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSilver);
        LocationSilver."Bin Mandatory" := true;  // Skip validate trigger for bin mandatory to improve performance.
        LocationSilver.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemInventoryWithLocationAndBin(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure DiscountCopyDocumentSales(var Item: Record Item; OldLineDiscountPercent: Decimal; OldUnitPrice: Decimal; var OldLineDiscountAmount: Decimal; var NewLineDiscountPercent: Decimal; var NewUnitPrice: Decimal; var NewLineDiscountAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();

        // Create Sales Invoice.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", OldUnitPrice); // any decimal value
        SalesLine.Validate("Line Discount %", OldLineDiscountPercent);
        OldLineDiscountAmount := SalesLine."Line Discount Amount";
        SalesLine.Modify(true);

        // Post invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Enable option 'Exact Cost Reversal'
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(true);

        // Create a Credit Memo and copy document from old Posted Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);

        // Return the required figures.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        NewLineDiscountPercent := SalesLine."Line Discount %";
        NewUnitPrice := SalesLine."Unit Price";
        NewLineDiscountAmount := SalesLine."Line Discount Amount";

        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Exact Cost Reversing Mandatory");
    end;

    local procedure DiscountCopyDocumentPurch(var Item: Record Item; OldLineDiscountPercent: Decimal; OldUnitCost: Decimal; var OldLineDiscountAmount: Decimal; var NewLineDiscountPercent: Decimal; var NewUnitCost: Decimal; var NewLineDiscountAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        OldPurchInvoiceNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();

        // Create purchase invoice.
        CreatePurchaseInvoiceHeader(PurchaseHeader, VendorNo);
        OldPurchInvoiceNo := PurchaseHeader."No.";
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", OldUnitCost); // any decimal value
        PurchaseLine.Validate("Line Discount %", OldLineDiscountPercent);
        OldLineDiscountAmount := PurchaseLine."Line Discount Amount";
        PurchaseLine.Modify(true);

        // post invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Create a Credit Memo and copy document from old Posted Invoice.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchInvHeader.SetRange("Pre-Assigned No.", OldPurchInvoiceNo);
        PurchInvHeader.FindLast();
        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", true, false);

        // Return the required figures.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        NewLineDiscountPercent := PurchaseLine."Line Discount %";
        NewUnitCost := PurchaseLine."Direct Unit Cost";
        NewLineDiscountAmount := PurchaseLine."Line Discount Amount";
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate(
          "External Document No.", LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("External Document No."), DATABASE::"Sales Header"));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesItemNo: Code[20]; CustomerNo: Code[20])
    var
        Location: Record Location;
    begin
        // Create Sales Order for Parent item.
        LibraryWarehouse.CreateLocation(Location);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, SalesItemNo, LibraryRandom.RandDec(10, 2));
        UpdateLocationOnSalesLine(SalesLine, Location.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; VendorNo: Code[20])
    var
        Location: Record Location;
    begin
        // Create purchase order for Parent item.
        LibraryWarehouse.CreateLocation(Location);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, ItemNo, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemBudgetEntry(Item: Record Item; Date: Date; DepartmentCode: Code[20]; ProjectCode: Code[20]; CustomerGroupCode: Code[20])
    var
        ItemBudgetEntry: Record "Item Budget Entry";
    begin
        LibraryInventory.CreateItemBudgetEntry(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, FindItemBudgetName(), Date, Item."No.");
        ItemBudgetEntry.Validate("Source Type", ItemBudgetEntry."Source Type"::Customer);
        ItemBudgetEntry.Validate("Source No.", LibrarySales.CreateCustomerNo());
        ItemBudgetEntry.Validate("Global Dimension 1 Code", DepartmentCode);
        ItemBudgetEntry.Validate("Global Dimension 2 Code", ProjectCode);
        ItemBudgetEntry.Validate(Quantity, 1);  // Value is important for Test.
        ItemBudgetEntry.Validate("Cost Amount", LibraryRandom.RandDec(100, 2));
        ItemBudgetEntry.Validate("Sales Amount", LibraryRandom.RandDec(100, 2));
        ItemBudgetEntry.Validate("Budget Dimension 1 Code", CustomerGroupCode);
        ItemBudgetEntry.Modify(true);
    end;

    local procedure CreateDimForBudgetEntry(DimensionCode: Code[20]; DimensionCode2: Code[20]; DimensionCode3: Code[20]; DimensionCode4: Code[20]; DimensionCode5: Code[20])
    var
        SelectedDimension: Record "Selected Dimension";
        AllObj: Record AllObj;
    begin
        SelectedDimension.SetRange("User ID", UserId);
        SelectedDimension.DeleteAll(true);
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, AllObj."Object Type"::Report, REPORT::"Date Comp. Item Budget Entries", '', DimensionCode);
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, AllObj."Object Type"::Report, REPORT::"Date Comp. Item Budget Entries", '', DimensionCode2);
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, AllObj."Object Type"::Report, REPORT::"Date Comp. Item Budget Entries", '', DimensionCode3);
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, AllObj."Object Type"::Report, REPORT::"Date Comp. Item Budget Entries", '', DimensionCode4);
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, AllObj."Object Type"::Report, REPORT::"Date Comp. Item Budget Entries", '', DimensionCode5);
    end;

    local procedure CreateBOMComponent(var BOMComponent: Record "BOM Component"; ParentItemNo: Code[20]; Type: Enum "BOM Component Type"; No: Code[20])
    begin
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItemNo, Type, No, 1, '');
    end;

    local procedure CreatePurchaseInvoiceHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal)
    begin
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasureCode, QtyPerUnitOfMeasure);
    end;

    local procedure CreateBOMComponentWithUOM(ParentItemNo: Code[20]; ChildItemNo: Code[20]; QuantityPer: Decimal; UnitOfMeasureCode: Code[10]; VariantCode: Code[10])
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateBOMComponent(BOMComponent, ParentItemNo, BOMComponent.Type::Item, ChildItemNo);
        BOMComponent.Validate("Quantity per", QuantityPer);
        BOMComponent.Validate("Unit of Measure Code", UnitOfMeasureCode);
        BOMComponent.Validate("Variant Code", VariantCode);
        BOMComponent.Modify(true);
    end;

    local procedure ClearEntries()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        DateComprRegister: Record "Date Compr. Register";
    begin
        ItemBudgetEntry.DeleteAll(true);
        DateComprRegister.DeleteAll(true);
    end;

    local procedure FindItemBudgetName(): Code[10]
    var
        ItemBudgetName: Record "Item Budget Name";
    begin
        ItemBudgetName.SetRange("Analysis Area", ItemBudgetName."Analysis Area"::Sales);
        ItemBudgetName.SetRange(Blocked, false);
        ItemBudgetName.FindFirst();
        exit(ItemBudgetName.Name);
    end;

    local procedure TrimSpaces(String: Text[250]) Result: Text[250]
    begin
        Result := DelChr(String, '<'); // delete leading space chars
        Result := DelChr(String, '>'); // delete trailing space chars
    end;

    local procedure UpdateChildItem(var Item: Record Item; UnitOfMeasureCode: Code[10]; UnitPrice: Decimal; LastDirectCost: Decimal)
    begin
        Item.Validate("Base Unit of Measure", UnitOfMeasureCode);
        Item.Validate("Sales Unit of Measure", UnitOfMeasureCode);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Last Direct Cost", LastDirectCost);
        Item.Modify(true);
    end;

    local procedure CreateItemWithMultipleUOM(var Item: Record Item; var UnitOfMeasure: Record "Unit of Measure"; var UnitOfMeasure2: Record "Unit of Measure"; QtyPerUnitOfMeasure: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure2);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);  // Value is important for Test.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure2.Code, QtyPerUnitOfMeasure);
    end;

    local procedure CreateItemWithAutoText(var Item: Record Item; var ItemExtText: Text[100])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, LibraryUtility.GenerateGUID());
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        CreateItemExtendedText(Item."No.", ItemExtText);
    end;

    local procedure CreateItemExtendedText(ItemNo: Code[20]; var ExtText: Text[100])
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateGUID());
        ExtendedTextLine.Modify(true);
        ExtText := ExtendedTextLine.Text;
    end;

    local procedure CreatePurchaseOrderWithItemRefNo(ItemReference: Record "Item Reference"; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          ItemReference."Item No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Item Reference No.", ItemReference."Reference No.");
        PurchaseLine.Validate("Unit Cost (LCY)", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithItemRefNo(ItemReference: Record "Item Reference"; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          ItemReference."Item No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Item Reference No.", ItemReference."Reference No.");
        SalesLine.Modify(true);
    end;

    local procedure CreateItemWithReserveAlways(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure CreateUserSetupWithPostingPolicy(InvoicePostingPolicy: Enum "Invoice Posting Policy")
    var
        UserSetup: Record "User Setup";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Sales Invoice Posting Policy", InvoicePostingPolicy);
        UserSetup.Modify(true);
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Find();
        Codeunit.Run(Codeunit::"Sales-Post (Yes/No)", SalesHeader);
    end;

    local procedure PostAndSendSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Find();
        Codeunit.Run(Codeunit::"Sales-Post and Send", SalesHeader);
    end;

    local procedure PostWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        Codeunit.Run(Codeunit::"Whse.-Post Shipment (Yes/No)", WarehouseShipmentLine);
    end;

    local procedure PostAndPrintWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        Codeunit.Run(Codeunit::"Whse.-Post Shipment + Print", WarehouseShipmentLine);
    end;

    local procedure TransferSalesLineExtendedText(SalesLine: Record "Sales Line")
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then
            TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    local procedure UpdateLocationOnSalesLine(var SalesLine: Record "Sales Line"; LocationCode: Code[10])
    begin
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityOnSalesLinePage(No: Code[20]; Quantity: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
    end;

    local procedure UndoShipmentOnPostedSalesShipmentPage(No: Code[20])
    var
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        PostedSalesShipment.OpenEdit();
        PostedSalesShipment.FILTER.SetFilter("No.", No);
        LibraryVariableStorage.Enqueue(UndoShipmentQst);  // Enqueue Value for Confirm Handler.
        PostedSalesShipment.SalesShipmLines.UndoShipment.Invoke();
    end;

    local procedure FindSalesShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; OrderNo: Code[20])
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
    end;

    local procedure VerifyDimension(var ItemBudgetEntry: Record "Item Budget Entry"; TotalNoOfRecords: Integer; DepartmentCodes: Text[250]; ProjectCodes: Text[250])
    var
        i: Integer;
    begin
        Assert.AreEqual(TotalNoOfRecords, ItemBudgetEntry.Count, NoOfRecordsErr);
        if TotalNoOfRecords = 0 then
            exit;
        ItemBudgetEntry.FindSet();
        repeat
            i += 1;
            Assert.AreEqual(TrimSpaces(SelectStr(i, DepartmentCodes)), ItemBudgetEntry."Global Dimension 1 Code", DimensionErr);
            Assert.AreEqual(TrimSpaces(SelectStr(i, ProjectCodes)), ItemBudgetEntry."Global Dimension 2 Code", DimensionErr);
        until ItemBudgetEntry.Next() = 0;
    end;

    local procedure VerifyPurchUnitPrice(ItemNo: Text[30]; QtyOfUOMPerUOM2: Decimal; UnitCostOnItemCard: Decimal; UnitPurchPrice: Decimal; UnitOfMeasureCode: Code[10]; UnitOfMeasureCode2: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        PurchasePrice: Record "Purchase Price";
        ExpectedUnitPrice: Decimal;
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindLast();
        PurchaseLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        PurchasePrice.SetRange("Item No.", ItemNo);
        PurchasePrice.FindLast();
        PurchaseLine.TestField("Variant Code", PurchasePrice."Variant Code");
        if PurchasePrice."Unit of Measure Code" = UnitOfMeasureCode then
            ExpectedUnitPrice := UnitPurchPrice;
        if PurchasePrice."Unit of Measure Code" = UnitOfMeasureCode2 then
            ExpectedUnitPrice := QtyOfUOMPerUOM2 * UnitCostOnItemCard;
        if PurchasePrice."Unit of Measure Code" = '' then
            ExpectedUnitPrice := QtyOfUOMPerUOM2 * UnitPurchPrice;
        PurchaseLine.TestField("Direct Unit Cost", ExpectedUnitPrice);
    end;

    local procedure VerifyDateComprRegister(var DateComprRegister: Record "Date Compr. Register"; TotalNoOfRecords: Integer; NumsNewRecords: Text[250]; NumsDelRecords: Text[250])
    var
        i: Integer;
    begin
        Assert.AreEqual(TotalNoOfRecords, DateComprRegister.Count, NoOfRecordsErr);
        if TotalNoOfRecords = 0 then
            exit;
        DateComprRegister.FindSet();
        repeat
            i += 1;
            Assert.AreEqual(
              TrimSpaces(SelectStr(i, NumsNewRecords)), Format(DateComprRegister."No. of New Records"), 'Check created records');
            Assert.AreEqual(
              TrimSpaces(SelectStr(i, NumsDelRecords)), Format(DateComprRegister."No. Records Deleted"), 'Check deleted records');
        until DateComprRegister.Next() = 0;
    end;

    local procedure VerifySalesUnitPrice(ItemNo: Text[30]; QtyOfUOMPerUOM2: Decimal; UnitPriceOnItemCard: Decimal; UnitSalesPrice: Decimal; UnitOfMeasureCode: Code[10]; UnitOfMeasureCode2: Code[10])
    var
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        ExpectedUnitPrice: Decimal;
    begin
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindLast();
        SalesLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        SalesPrice.SetRange("Item No.", ItemNo);
        SalesPrice.FindLast();
        SalesLine.TestField("Variant Code", SalesPrice."Variant Code");
        if SalesPrice."Unit of Measure Code" = UnitOfMeasureCode then
            ExpectedUnitPrice := UnitSalesPrice;
        if SalesPrice."Unit of Measure Code" = UnitOfMeasureCode2 then
            ExpectedUnitPrice := QtyOfUOMPerUOM2 * UnitPriceOnItemCard;
        if SalesPrice."Unit of Measure Code" = '' then
            ExpectedUnitPrice := QtyOfUOMPerUOM2 * UnitSalesPrice;
        SalesLine.TestField("Unit Price", ExpectedUnitPrice);
    end;

    local procedure VerifyPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ExpectedCount: Integer; LineDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
        ActualCount: Integer;
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        ActualCount := PurchaseLine.Count();
        Assert.AreEqual(ExpectedCount, ActualCount, ' Wrong number of sales lines ' + Format(ActualCount));

        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindSet();
        repeat
            Assert.AreEqual(LineDate, PurchaseLine."Expected Receipt Date",
              ' Wrong Shipment Date of purchase line ' + Format(PurchaseLine."Line No."));
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifySalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; ExpectedCount: Integer; LineDate: Date)
    var
        SalesLine: Record "Sales Line";
        ActualCount: Integer;
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        ActualCount := SalesLine.Count();
        Assert.AreEqual(ExpectedCount, ActualCount, ' Wrong number of sales lines ' + Format(ActualCount));

        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindSet();
        repeat
            Assert.AreEqual(LineDate, SalesLine."Shipment Date",
              ' Wrong Shipment Date of sales line ' + Format(SalesLine."Line No."));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyValueEntriesForSalesOrder(DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Verify that the Value of "Sales Amount (Actual)" field in Value Entries matches the value of "Amount" on Posted Sales Invoice line.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        ValueEntry.SetRange("Document No.", SalesInvoiceLine."Document No.");
        ValueEntry.SetRange("Document Line No.", SalesInvoiceLine."Line No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Sales Amount (Actual)", SalesInvoiceLine.Amount);
    end;

    local procedure VerifyItemRefNoInItemLedgerEntry(ItemLedgerEntryDocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; ReferenceNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Item Reference No. in Item Ledger Entry for Posted Receipt.
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntryDocumentType);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item Reference No.", ReferenceNo);
    end;

    local procedure VerifyWarehouseEntry(ReferenceNo: Code[20]; ItemNo: Code[20]; EntryType: Option; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Reference Document", WarehouseEntry."Reference Document"::"Posted Shipment");
        WarehouseEntry.SetRange("Reference No.", ReferenceNo);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesLineDetails(SalesLine: Record "Sales Line"; ExpectedType: Enum "Sales Line Type"; ExpectedNo: Code[20]; ExpectedBOMItemNo: Code[20]; ExpectedDescription: Text[100])
    begin
        Assert.AreEqual(ExpectedType, SalesLine.Type, SalesLine.FieldCaption(Type));
        Assert.AreEqual(ExpectedNo, SalesLine."No.", SalesLine.FieldCaption("No."));
        Assert.AreEqual(ExpectedBOMItemNo, SalesLine."BOM Item No.", SalesLine.FieldCaption("BOM Item No."));
        Assert.AreEqual(ExpectedDescription, SalesLine.Description, SalesLine.FieldCaption(Description));
    end;

    local procedure VerifySalesLinesAfterExplodeBOMWithAutoExtTexts(SalesLine: Record "Sales Line"; ParentItem: Record Item; ChildItem: Record Item; ParentItemExtText: Text[100]; ChildItemExtText: Text[100])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.FindSet();
        VerifySalesLineDetails(SalesLine, SalesLine.Type::" ", '', ParentItem."No.", ParentItem.Description);
        SalesLine.Next();
        VerifySalesLineDetails(SalesLine, SalesLine.Type::" ", '', '', ParentItemExtText);
        SalesLine.Next();
        VerifySalesLineDetails(SalesLine, SalesLine.Type::Item, ChildItem."No.", ParentItem."No.", ChildItem.Description);
        SalesLine.Next();
        VerifySalesLineDetails(SalesLine, SalesLine.Type::" ", '', '', ChildItemExtText);
    end;

    local procedure VerifyQtyOnSalesOrderLine(SalesLine: Record "Sales Line"; QtyShipped: Decimal; QtyInvoiced: Decimal)
    begin
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", QtyShipped);
        SalesLine.TestField("Quantity Invoiced", QtyInvoiced);
    end;

    local procedure VerifyQtyOnSalesReturnOrderLine(SalesLine: Record "Sales Line"; QtyReturned: Decimal; QtyInvoiced: Decimal)
    begin
        SalesLine.Find();
        SalesLine.TestField("Return Qty. Received", QtyReturned);
        SalesLine.TestField("Quantity Invoiced", QtyInvoiced);
    end;

    [ModalPageHandler]
    procedure PostAndSendHandlerYes(var PostandSendConfirm: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirm.Yes().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure RetrieveDimStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Assert.IsTrue(StrPos(Options, 'Retrieve dimensions from components') > 0, Options);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure DimStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1; // Choose "Copy dimensions from BOM"
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFALSE(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [RecallNotificationHandler]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Header", 'OnBeforePrintRecords', '', false, false)]
    local procedure SetSalesShipmentAsPrinted(var SalesShipmentHeader: Record "Sales Shipment Header"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
