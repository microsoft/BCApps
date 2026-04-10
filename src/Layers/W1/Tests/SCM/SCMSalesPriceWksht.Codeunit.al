codeunit 137201 "SCM Sales Price Wksht"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price] [Order] [SCM]
        isInitialized := false;
    end;

    var
        InventorySetup: Record "Inventory Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCosting: Codeunit "Library - Costing";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountWithSalesPrice()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        MinimumQty: Decimal;
        NewUnitPrice: Decimal;
    begin
        // Setup: Create Sales Price Setup with Line Discount.
        Initialize();
        CreateSalesPriceSetup(SalesReceivablesSetup, Item, Customer);
        MinimumQty := LibraryRandom.RandDec(5, 2) + 10;  // Random values not important.
        NewUnitPrice := Item."Unit Price" - LibraryRandom.RandInt(5);
        CreateSalesPrice(Item, "Sales Price Type"::Customer, Customer."No.", NewUnitPrice, MinimumQty);
        CreateSalesLineDiscount(Item, Customer."No.", MinimumQty);

        // Exercise: Create Sales Order.
        CreateSalesOrder(SalesLine, Customer."No.", Item."No.", MinimumQty);

        // Verify: Verify Line Amount on Sales Line as per reduced Sales Price.
        VerifySalesLine(SalesLine, NewUnitPrice, MinimumQty, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceWithDiscount()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        SalesPriceWorksheet: Record "Sales Price Worksheet";
        NewUnitPrice: Decimal;
        MinimumQty: Decimal;
    begin
        // Setup: Create Sales Price Setup with Line Discount and suggest new Sales Price.
        Initialize();
        SalesPriceWorksheet.DeleteAll();
        CreateSalesPriceSetup(SalesReceivablesSetup, Item, Customer);
        MinimumQty := LibraryRandom.RandDec(5, 2) + 10;  // Random values not important.
        CreateSalesPrice(
          Item, "Sales Price Type"::Customer, Customer."No.", Item."Unit Price" - LibraryRandom.RandInt(5), MinimumQty);
        CreateSalesLineDiscount(Item, Customer."No.", MinimumQty);
        LibraryCosting.SuggestSalesPriceWorksheet(Item, Customer."No.", "Sales Price Type"::Customer, 0, 1);  // Values important for test.
        NewUnitPrice := ImplementNewSalesPrice();

        // Exercise: Create Sales Order.
        CreateSalesOrder(SalesLine, Customer."No.", Item."No.", MinimumQty);

        // Verify: Verify Line Amount on Sales Line.
        VerifySalesLine(SalesLine, NewUnitPrice, MinimumQty, GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemPriceForCustomer()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        SalesPriceWorksheet: Record "Sales Price Worksheet";
        NewUnitPrice: Decimal;
        MinimumQty: Decimal;
    begin
        // Setup: Create Sales Price Setup. Suggest Item Price and implement new price.
        Initialize();
        SalesPriceWorksheet.DeleteAll();
        CreateSalesPriceSetup(SalesReceivablesSetup, Item, Customer);
        MinimumQty := LibraryRandom.RandDec(5, 2) + 10;  // Random values not important.
        CreateSalesPrice(
          Item, "Sales Price Type"::Customer, Customer."No.", Item."Unit Price" - LibraryRandom.RandInt(5), MinimumQty);
        LibraryCosting.SuggestItemPriceWorksheet(Item, Customer."No.", "Sales Price Type"::Customer, 0, 1);  // Values important for test.
        NewUnitPrice := ImplementNewSalesPrice();

        // Exercise: Create Sales Order.
        CreateSalesOrder(SalesLine, Customer."No.", Item."No.", MinimumQty);

        // Verify: Verify Line Amount on Sales Line.
        SalesLine.TestField(
          "Line Amount", Round(NewUnitPrice * MinimumQty, GeneralLedgerSetup."Inv. Rounding Precision (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceAllCustomers()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        SalesPriceWorksheet: Record "Sales Price Worksheet";
        CustomerPriceGroup: Record "Customer Price Group";
        NewUnitPrice: array[3] of Decimal;
        Quantity: array[3] of Decimal;
        MinimumQty: Decimal;
        NoOfSalesLines: Integer;
        "Count": Integer;
    begin
        // Setup: Create Sales Price Setup.
        Initialize();
        SalesPriceWorksheet.DeleteAll();

        // Create different Sales Prices for Customer, Customer Price Group and All Customer. Unit Prices and Quantities important for test.
        CreateSalesPriceSetup(SalesReceivablesSetup, Item, Customer);
        MinimumQty := LibraryRandom.RandDec(5, 2) + 10;  // Random values not important.
        CreateSalesPrice(
          Item, "Sales Price Type"::Customer, Customer."No.", Item."Unit Price" - LibraryRandom.RandInt(5), MinimumQty);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        UpdateCustomer(Customer, CustomerPriceGroup.Code);
        CreateSalesPrice(
          Item, "Sales Price Type"::"Customer Price Group", CustomerPriceGroup.Code,
          Item."Unit Price" - LibraryRandom.RandInt(5), MinimumQty + 10);
        CreateSalesPrice(
          Item, "Sales Price Type"::"All Customers", '',
          Item."Unit Price" - LibraryRandom.RandInt(5), MinimumQty + 100);
        LibraryCosting.SuggestSalesPriceWorksheet(Item, Customer."No.", "Sales Price Type"::Customer, 0, 1);  // Values important for test.
        NoOfSalesLines := UpdateSalesPriceWorksheet(SalesPriceWorksheet, NewUnitPrice, Quantity);
        LibraryCosting.ImplementPriceChange(SalesPriceWorksheet);

        // Exercise: Create Sales Order with three different Sales line for different Quantities.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        for Count := 1 to NoOfSalesLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity[Count]);

        // Verify: Verify Line Amounts on Sales Lines.
        for Count := 1 to NoOfSalesLines do begin
            SelectSalesLine(SalesLine, SalesHeader, Quantity[Count]);
            SalesLine.TestField(
              "Line Amount",
              Round(NewUnitPrice[Count] * Quantity[Count], GeneralLedgerSetup."Inv. Rounding Precision (LCY)"));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceForCampaign()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        Customer: Record Customer;
        SalesPriceWorksheet: Record "Sales Price Worksheet";
        SalesPrice: Record "Sales Price";
        Campaign: Record Campaign;
        LibraryMarketing: Codeunit "Library - Marketing";
        NewUnitPrice: Decimal;
        MinimumQty: Decimal;
    begin
        // Setup: Create Sales Price Setup for Campaign.
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(false);
        SalesPriceWorksheet.DeleteAll();
        MinimumQty := LibraryRandom.RandDec(5, 2) + 10;  // Random values not important.
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, Item.FieldNo("Unit Price"), LibraryRandom.RandDec(5, 2) + 10);  // Random values not important.
        LibrarySales.CreateCustomer(Customer);
        LibraryMarketing.CreateCampaign(Campaign);
        CreateSalesPrice(
          Item, "Sales Price Type"::Campaign, Campaign."No.",
          Item."Unit Price" - LibraryRandom.RandInt(5), MinimumQty);  // Random values not important.
        LibraryCosting.SuggestItemPriceWorksheet(Item, Campaign."No.", "Sales Price Type"::Campaign, 0, 1);  // Values important for test.
        UpdateCampaignSalesPrices(Item, Campaign."No.", SalesPrice."Minimum Quantity");

        // Exercise: Implement Price Changes.
        NewUnitPrice := ImplementNewSalesPrice();

        // Verify: Verify Unit Price updated with new Sales price.
        SalesPrice.SetRange("Item No.", Item."No.");
        SalesPrice.FindFirst();
        SalesPrice.TestField("Unit Price", NewUnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountWithPurchasePrice()
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchasePrice: Record "Purchase Price";
        MinimumQty: Decimal;
        ExpectedLineAmount: Decimal;
    begin
        // Setup: Create Item, Vendor, Purchase Price and Purchase Line Discount.
        Initialize();
        MinimumQty := LibraryRandom.RandDec(5, 2) + 10;  // Random values not important.
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, Item.FieldNo("Unit Cost"), LibraryRandom.RandDec(5, 2) + 10);  // Random values not important.
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchasePrice(PurchasePrice, Item, Vendor."No.", MinimumQty);
        CreatePurchaseLineDiscount(Item, Vendor."No.", MinimumQty);

        // Exercise: Create Purchase Order.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", MinimumQty);

        // Verify: Verify Line Amount on Purchase Line with reduced unit cost.
        ExpectedLineAmount :=
          Round((PurchasePrice."Direct Unit Cost" * MinimumQty) -
            ((PurchasePrice."Direct Unit Cost" * MinimumQty) * PurchaseLine."Line Discount %" / 100),
            GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        PurchaseLine.TestField("Line Amount", ExpectedLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderExpReceiptDate()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        PurchaseLine: Record "Purchase Line";
        ExpectedReceiptDate: Date;
        DateWithLeadTimeCalc: Date;
        DateWithSafetyLeadTime: Date;
    begin
        // Setup: Create Item, Vendor and Item Vendor with Lead Time Calculation value.
        Initialize();
        InventorySetup.Get();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        UpdateItemVendor(ItemVendor);

        // Exercise: Create Purchase Order with quantity not required on Purchase Line.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", 0);
        DateWithLeadTimeCalc := CalcDate(ItemVendor."Lead Time Calculation", PurchaseLine."Order Date");
        DateWithSafetyLeadTime := CalcDate(InventorySetup."Default Safety Lead Time", DateWithLeadTimeCalc);
        ExpectedReceiptDate := CalcDate(InventorySetup."Inbound Whse. Handling Time", DateWithSafetyLeadTime);

        // Verify: Verify Expected Receipt Date on Purchase Line.
        PurchaseLine.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesPricePageforCustomerPriceGroup()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
    begin
        // Check Customer Price Group page opened successfully with Correct Values.

        // Setup: Create Sales Price Setup.
        Initialize();
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryInventory.CreateItem(Item);

        // Create Sales Prices for Customer Price Group.
        CreateSalesPrice(
          Item, "Sales Price Type"::"Customer Price Group", CustomerPriceGroup.Code,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(5, 10));

        // Verify: Verify Customer Discount Group Code and Type on Sales Price Page.
        VerifySalesPriceLineOnPage(CustomerPriceGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrentPriceIsFilledWithActualSalesPrice()
    var
        Item: Record Item;
        ItemUnitPrice: Decimal;
        ActualSalesPrice: Decimal;
    begin
        // [SCENARIO 381656] Current Unit Price on sales price worksheet is equal to current sales price if the latter exists.
        Initialize();

        // [GIVEN] Item with Unit Price "X".
        ItemUnitPrice := LibraryRandom.RandDec(10, 2);
        CreateItemWithUnitPrice(Item, ItemUnitPrice);

        // [GIVEN] All customers' sales price "Y" for Item.
        ActualSalesPrice := LibraryRandom.RandDecInRange(11, 20, 2);
        CreateSalesPrice(Item, "Sales Price Type"::"All Customers", '', ActualSalesPrice, 0);

        // [WHEN] Run "Suggest Item Price" on sales price worksheet.
        LibraryCosting.SuggestItemPriceWorksheet(
          Item, '', "Sales Price Type"::"All Customers", 0, LibraryRandom.RandIntInRange(2, 5));

        // [THEN] "Current Unit Price" on sales price worksheet line = "Y".
        VerifySalesPriceWorksheet(Item."No.", ActualSalesPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrentPriceIsFilledWithItemUnitPriceIfSalesPriceDoesNotExist()
    var
        Item: Record Item;
        ItemUnitPrice: Decimal;
    begin
        // [SCENARIO 381656] Current Unit Price on sales price worksheet is equal to Unit Price of Item if current sales price does not exist.
        Initialize();

        // [GIVEN] Item with Unit Price "X".
        ItemUnitPrice := LibraryRandom.RandDec(10, 2);
        CreateItemWithUnitPrice(Item, ItemUnitPrice);

        // [WHEN] Run "Suggest Item Price" on sales price worksheet.
        LibraryCosting.SuggestItemPriceWorksheet(
          Item, '', "Sales Price Type"::"All Customers", 0, LibraryRandom.RandIntInRange(2, 5));

        // [THEN] "Current Unit Price" on sales price worksheet line = "X".
        VerifySalesPriceWorksheet(Item."No.", ItemUnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceMultipleSource()
    var
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPriceWorksheet: Record "Sales Price Worksheet";
        I: Integer;
    begin
        // [SCENARIO 328524] Suggest Sales Price Worksheet from multiple source Sales Prices to the same Sales Price Worksheet line raises error
        Initialize();

        // [GIVEN] Created Item "ITEM"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Created Customer Price Groups "RETAIL","WHOLESALE" with Sales Prices for "ITEM"
        for I := 1 to 2 do begin
            LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
            CreateSalesPrice(Item, "Sales Price Type"::"Customer Price Group", CustomerPriceGroup.Code, LibraryRandom.RandDec(100, 2), 0);
        end;

        // [WHEN] Suggest Sales Price Worksheet where "Item No." = "ITEM" with Copy to Sales Price Worksheet for Customer Price Group "WHOLESALE"
        asserterror LibraryCosting.SuggestSalesPriceWorksheet(
            Item, CustomerPriceGroup.Code, SalesPriceWorksheet."Sales Type"::"Customer Price Group", 0, 1.2);

        // [THEN] Error is shown "There are multiple source lines for the record"
        Assert.ExpectedError('There are multiple source lines for the record');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        PriceListLine: Record "Price List Line";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Sales Price Wksht");
        LibrarySetupStorage.Restore();
        PriceListLine.DeleteAll();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Sales Price Wksht");

        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        GeneralLedgerSetup.Get();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Sales Price Wksht");
    end;

    local procedure UpdateSalesReceivablesSetup(StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateItemWithUnitPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, Item.FieldNo("Unit Price"), UnitPrice);
    end;

    local procedure CreateSalesPriceSetup(var SalesReceivablesSetup: Record "Sales & Receivables Setup"; var Item: Record Item; var Customer: Record Customer)
    begin
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(false);
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, Item.FieldNo("Unit Price"), LibraryRandom.RandDec(5, 2) + 100);  // Random values not important.
        LibrarySales.CreateCustomer(Customer);
    end;

    local procedure CreateSalesPrice(Item: Record Item; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; UnitPrice: Decimal; Quantity: Decimal)
    var
        SalesPrice: Record "Sales Price";
        PriceListLine: Record "Price List Line";
    begin
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesType, SalesCode, Item."No.", WorkDate(), '', '', Item."Base Unit of Measure", Quantity);
        SalesPrice.Validate("Unit Price", UnitPrice);
        SalesPrice.Modify(true);
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
    end;

    local procedure CreateSalesLineDiscount(Item: Record Item; CustomerNo: Code[20]; MinimumQty: Decimal)
    var
        SalesLineDiscount: Record "Sales Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        // Random Value for Line Discount percentage is not important.
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.",
          SalesLineDiscount."Sales Type"::Customer, CustomerNo, WorkDate(), '', '', Item."Base Unit of Measure", MinimumQty);
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Modify(true);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
    end;

    local procedure CreatePurchasePrice(var PurchasePrice: Record "Purchase Price"; Item: Record Item; VendorNo: Code[20]; Quantity: Decimal)
    var
        PriceListLine: Record "Price List Line";
    begin
        LibraryCosting.CreatePurchasePrice(
          PurchasePrice, VendorNo, Item."No.", WorkDate(), '', '', Item."Base Unit of Measure", Quantity);
        PurchasePrice.Validate("Direct Unit Cost", Item."Unit Cost" - LibraryRandom.RandInt(5));  // Value important for test.
        PurchasePrice.Modify(true);
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);
    end;

    local procedure CreatePurchaseLineDiscount(Item: Record Item; VendorNo: Code[20]; MinimumQty: Decimal)
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        // Random Value for Line Discount percentage is not important.
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, Item."No.", VendorNo, WorkDate(), '', '', Item."Base Unit of Measure", MinimumQty);
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLineDiscount.Modify(true);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);
    end;

    local procedure UpdateItem(var Item: Record Item; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Item based on Field and its corresponding value.
        RecRef.GetTable(Item);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(Item);
        Item.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; MinimumQty: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, MinimumQty);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; MinimumQty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, MinimumQty);
    end;

    local procedure ImplementNewSalesPrice() NewUnitPrice: Decimal
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        SalesPriceWorksheet.FindFirst();
        SalesPriceWorksheet.Validate(
          "New Unit Price", SalesPriceWorksheet."New Unit Price" - LibraryRandom.RandInt(5));  // Value important for test.
        SalesPriceWorksheet.Modify(true);
        NewUnitPrice := SalesPriceWorksheet."New Unit Price";
        LibraryCosting.ImplementPriceChange(SalesPriceWorksheet);
    end;

    local procedure UpdateSalesPriceWorksheet(var SalesPriceWorksheet: Record "Sales Price Worksheet"; var NewUnitPrice: array[3] of Decimal; var Quantity: array[3] of Decimal) "Count": Integer
    begin
        Count := 0;
        SalesPriceWorksheet.FindSet();
        repeat
            Count += 1;
            SalesPriceWorksheet.Validate("New Unit Price", SalesPriceWorksheet."New Unit Price" - LibraryRandom.RandInt(5));
            SalesPriceWorksheet.Modify(true);
            NewUnitPrice[Count] := SalesPriceWorksheet."New Unit Price";
            Quantity[Count] := SalesPriceWorksheet."Minimum Quantity";
        until SalesPriceWorksheet.Next() = 0;
    end;

    local procedure UpdateCampaignSalesPrices(Item: Record Item; CampaignNo: Code[20]; MinimumQuantity: Decimal)
    var
        SalesPrice: Record "Sales Price";
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        SalesPrice.SetRange("Item No.", Item."No.");
        SalesPrice.FindFirst();
        SalesPriceWorksheet.FindFirst();
        SalesPriceWorksheet.Rename(
          WorkDate(), WorkDate(), "Sales Price Type"::Campaign, CampaignNo, '', Item."No.", '', Item."Base Unit of Measure", MinimumQuantity);
    end;

    local procedure UpdateItemVendor(var ItemVendor: Record "Item Vendor")
    var
        LeadTimeCalculation: DateFormula;
    begin
        Evaluate(LeadTimeCalculation, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');  // Value not important for test.
        ItemVendor.Validate("Lead Time Calculation", LeadTimeCalculation);
        ItemVendor.Modify(true);
    end;

    local procedure UpdateCustomer(var Customer: Record Customer; CustomerPriceGroupCode: Code[10])
    begin
        Customer.Validate("Customer Price Group", CustomerPriceGroupCode);
        Customer.Modify(true);
    end;

    local procedure SelectSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Quantity: Decimal)
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Quantity, Quantity);
        SalesLine.FindFirst();
    end;

    local procedure VerifySalesLine(SalesLine: Record "Sales Line"; UnitPrice: Decimal; MinimumQty: Decimal; InvRoundingPrecision: Decimal)
    var
        ExpectedLineAmount: Decimal;
    begin
        ExpectedLineAmount :=
          Round((UnitPrice * MinimumQty) -
            ((UnitPrice * MinimumQty) * SalesLine."Line Discount %" / 100), InvRoundingPrecision);
        SalesLine.TestField("Line Amount", ExpectedLineAmount);
    end;

    local procedure VerifySalesPriceLineOnPage(CustomerPriceGroup: Record "Customer Price Group")
    var
        CustomerPriceGroups: TestPage "Customer Price Groups";
        SalesPrices: TestPage "Sales Prices";
    begin
        CustomerPriceGroups.OpenEdit();
        CustomerPriceGroups.GotoRecord(CustomerPriceGroup);
        SalesPrices.Trap();
        CustomerPriceGroups.SalesPrices.Invoke();
        SalesPrices.SalesCodeFilterCtrl.AssertEquals(CustomerPriceGroup.Code);
    end;

    local procedure VerifySalesPriceWorksheet(ItemNo: Code[20]; CurrentUnitPrice: Decimal)
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        SalesPriceWorksheet.SetRange("Item No.", ItemNo);
        SalesPriceWorksheet.FindFirst();
        SalesPriceWorksheet.TestField("Current Unit Price", CurrentUnitPrice);
    end;
}
