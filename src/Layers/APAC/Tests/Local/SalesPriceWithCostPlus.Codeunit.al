#pragma warning disable AS0072
codeunit 141051 "Sales Price With Cost Plus"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Price] [Cost-plus %]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        UnitPriceMustBeSameMsg: Label 'Unit Price must be same.';
        ModifiedLines: Dictionary of [Text, Integer];

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceWithCostPlusWithoutDate()
    var
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for single customer when Starting Date and Ending Date field is not filled on the Sales Price.

        // Setup: Create Customer.
        CustomerNo := CreateCustomer();
        CustomerSalesPriceWithCostPlusStartingdate(SalesPrice."Sales Type"::Customer, CustomerNo, CustomerNo, 0D);  // Starting Date - 0D.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllCustomerSalesPriceWithCostPlusWithDate()
    var
        SalesPrice: Record "Sales Price";
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for all customers if Posting Date specified on the sales Order is within the date range specified on the Sales Price.

        // Setup.
        CustomerSalesPriceWithCostPlusStartingdate(SalesPrice."Sales Type"::"All Customers", '', CreateCustomer(), WorkDate());  // Sales Code - blank and Starting Date - Workdate.
    end;

    local procedure CustomerSalesPriceWithCostPlusStartingdate(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; CustomerNo: Code[20]; StartingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
    begin
        // Create Sales Price with Cost Plus.
        CreateSalesPriceWithCostPlus(SalesPrice, SalesType, SalesCode, StartingDate, LibraryRandom.RandDec(10, 2));  // Random Minimum Quantity.

        // Exercise: Create Sales Order.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, '', SalesPrice."Item No.", SalesPrice."Minimum Quantity");  // Campaign Number - blank.

        // Verify: Verify Unit Price on Sales line with Unit Price of Sales Price.
        Assert.AreNearlyEqual(
          SalesPrice."Unit Price", SalesLine."Unit Price", LibraryERM.GetAmountRoundingPrecision(), UnitPriceMustBeSameMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceWithCostPlusWithBelowMinQty()
    var
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for single customer when Quantity on Sales Line less than Minimum Quantity.

        // Setup: Create Customer.
        CustomerNo := CreateCustomer();
        CustomerSalesPriceWithCostPlusDateRange(SalesPrice."Sales Type"::Customer, CustomerNo, CustomerNo, 0D, LibraryRandom.RandInt(5));  // Starting Date - 0D and Random Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceWithCostPlusWithDateDiffCustomer()
    var
        SalesPrice: Record "Sales Price";
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for single customer when Starting Date and Ending Date field is not filled on the Sales Price and different customer on sales.

        // Setup.
        CustomerSalesPriceWithCostPlusDateRange(SalesPrice."Sales Type"::Customer, CreateCustomer(), CreateCustomer(), 0D, 0);  // Starting Date - 0D and Quantity - 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllCustomerSalesPriceWithCostPlusWithOutsideDateRange()
    var
        SalesPrice: Record "Sales Price";
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for all customers if Posting Date specified on the sales order is not within the date range specified on the Sales Price.

        // Setup.
        CustomerSalesPriceWithCostPlusDateRange(
          SalesPrice."Sales Type"::"All Customers", '', CreateCustomer(),
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), 0);   // Sales Code - blank, Starting Date - less than Workdate and Quantity - 0.
    end;

    local procedure CustomerSalesPriceWithCostPlusDateRange(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; CustomerNo: Code[20]; StartingDate: Date; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
    begin
        // Create Sales Price with Cost Plus.
        CreateSalesPriceWithCostPlus(SalesPrice, SalesType, SalesCode, StartingDate, LibraryRandom.RandDecInDecimalRange(10, 20, 2));  // Random Minimum Quantity.

        // Exercise: Create Sales Order.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, '', SalesPrice."Item No.", SalesPrice."Minimum Quantity" - Quantity);  // Campaign Number - blank and Sales Line Quantity less than Minimum Quantity of Sales Price.

        // Verify: Verify Unit Price on Sales line with Unit Price of Item.
        VerifyUnitPriceOnSalesLine(SalesPrice."Item No.", SalesLine."Unit Price", 0);  // Discount Amount - 0.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignSalesPriceWithCostPlus()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
        ContactNo: Code[20];
        CampaignNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for Campaign.

        // Setup: Create Contact and Customer, create and activate Campaign, create Sales Price with Cost Plus using Campaign.
        ContactNo := CreateContactWithCustomer();
        CustomerNo := FindCustomerFromContactBusinessRelation(ContactNo);
        CampaignNo := CreateAndActivateCampaign(ContactNo);
        CreateSalesPriceWithCostPlus(
          SalesPrice, SalesPrice."Sales Type"::Campaign, CampaignNo, WorkDate(), LibraryRandom.RandDec(10, 2));  // Random Minimum Quantity.

        // Exercise: Create Sales Order.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, CampaignNo, SalesPrice."Item No.", SalesPrice."Minimum Quantity");

        // Verify: Verify Unit Price on Sales line with Unit Price of Sales Price.
        Assert.AreNearlyEqual(
          SalesPrice."Unit Price", SalesLine."Unit Price", LibraryERM.GetAmountRoundingPrecision(), UnitPriceMustBeSameMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceWithCostPlusMultipleLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        SalesPrice2: Record "Sales Price";
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus for single customer using different Quantity.

        // Setup: Create multiple Sales Price for single customer.
        CreateSalesPriceWithCostPlus(
          SalesPrice, SalesPrice."Sales Type"::Customer, CreateCustomer(), 0D, LibraryRandom.RandDecInDecimalRange(10, 50, 2));  // Starting Date - 0D and Random Minimum Quantity.
        CreateSalesPriceWithCostPlus(
          SalesPrice2, SalesPrice2."Sales Type"::Customer, SalesPrice."Sales Code", 0D, LibraryRandom.RandDecInDecimalRange(100, 200, 2));  // Starting Date - 0D and Random Minimum Quantity.

        // Exercise: Create Sales Invoice with multiple line with different Quantitiy.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, SalesPrice."Sales Code", '', SalesPrice."Item No.",
          SalesPrice."Minimum Quantity" - LibraryRandom.RandInt(5));  // Reduce Sales line - Quantity.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, SalesPrice."Item No.", SalesPrice."Minimum Quantity");
        LibrarySales.CreateSalesLine(SalesLine3, SalesHeader, SalesLine3.Type::Item, SalesPrice2."Item No.", SalesPrice2."Minimum Quantity");

        // Verify: Verify Unit Price on multiple Sales line with Unit Price of Sales Price and Item.
        VerifyUnitPriceOnSalesLine(SalesPrice."Item No.", SalesLine."Unit Price", 0);  // Discount Amount - 0.
        Assert.AreNearlyEqual(
          SalesPrice."Unit Price", SalesLine2."Unit Price", LibraryERM.GetAmountRoundingPrecision(), UnitPriceMustBeSameMsg);
        Assert.AreNearlyEqual(
          SalesPrice2."Unit Price", SalesLine3."Unit Price", LibraryERM.GetAmountRoundingPrecision(), UnitPriceMustBeSameMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceWithDiscountAmtAndCostPlus()
    var
        SalesPrice: Record "Sales Price";
    begin
        // [SCENARIO] Discount Amount are blank on the Sales Price when update Cost-plus.

        // Setup: Create Sales Price with Discount Amount.
        CreateSalesPriceWithDiscountAmount(SalesPrice, SalesPrice."Sales Type"::Customer, CreateCustomer(), 0D);  // Starting Date - 0D.

        // Exercise.
        UpdateCostPlusPctOnSalesPrice(SalesPrice);

        // Verify: Verify after updating Cost-plus Pct on Sales Price, Discount Amount change to zero value.
        SalesPrice.Get(
          SalesPrice."Item No.", SalesPrice."Sales Type", SalesPrice."Sales Code", SalesPrice."Starting Date", SalesPrice."Currency Code",
          SalesPrice."Variant Code", SalesPrice."Unit of Measure Code", SalesPrice."Minimum Quantity");
        SalesPrice.TestField("Discount Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceDiscountAmtWithoutDate()
    var
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on discount allowed to single customer when Starting Date and ending Date fields are blank on the Sales Price.

        // Setup: Create Customer.
        CustomerNo := CreateCustomer();
        CustomerSalesPriceDiscountAmtWithStartingDate(SalesPrice."Sales Type"::Customer, CustomerNo, CustomerNo, 0D);  // Starting Date - 0D.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCustomerSalesPriceDiscountAmtWithDate()
    var
        SalesPrice: Record "Sales Price";
    begin
        // [SCENARIO] Calculate Sales Price based on discount allowed for all customers if Posting Date specified on the sales Invoice is within the date range specified on the Sales Price.

        // Setup.
        CustomerSalesPriceDiscountAmtWithStartingDate(SalesPrice."Sales Type"::"All Customers", '', CreateCustomer(), WorkDate());  // Sales Code - blank and Starting Date - Workdate.
    end;

    local procedure CustomerSalesPriceDiscountAmtWithStartingDate(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; CustomerNo: Code[20]; StartingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
    begin
        // Create Sales Price with Discount Amount.
        CreateSalesPriceWithDiscountAmount(SalesPrice, SalesType, SalesCode, StartingDate);

        // Exercise: Create Sales Invoice.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo, '', SalesPrice."Item No.", SalesPrice."Minimum Quantity");  // Campaign Number - blank.

        // Verify: Verify Unit Price on Sales line with Unit Price of Item and deduct Discount Amount.
        VerifyUnitPriceOnSalesLine(SalesPrice."Item No.", SalesLine."Unit Price", SalesPrice."Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllCustomerSalesPriceDiscountAmtWithOutsideDateRange()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
    begin
        // [SCENARIO] Calculate Sales Price based on discount allowed for all customers if Posting Date specified on the sales Invoice is not within the date range specified on the Sales Price.

        // Setup.
        CreateSalesPriceWithDiscountAmount(
          SalesPrice, SalesPrice."Sales Type"::"All Customers", '',
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Customer Number - blank and Starting Date - less than Workdate.

        // Exercise: Create Sales Invoice.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomer(), '', SalesPrice."Item No.", SalesPrice."Minimum Quantity");

        // Verify: Verify Unit Price on Sales line with Unit Price of Item.
        VerifyUnitPriceOnSalesLine(SalesPrice."Item No.", SalesLine."Unit Price", 0);  // Discount Amount - 0.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure CampaignSalesPriceDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        CustomerNo: Code[20];
        ContactNo: Code[20];
        CampaignNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Discount allowed for Campaign.

        // Setup: Create Contact and Customer, create and activate Campaign, create Sales Price with Discount Amount using Campaign.
        ContactNo := CreateContactWithCustomer();
        CampaignNo := CreateAndActivateCampaign(ContactNo);
        CustomerNo := FindCustomerFromContactBusinessRelation(ContactNo);
        CreateSalesPriceWithDiscountAmount(SalesPrice, SalesPrice."Sales Type"::Campaign, CampaignNo, WorkDate());  // Starting Date - Workdate.

        // Exercise: Create Sales Order.
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, CampaignNo, SalesPrice."Item No.", SalesPrice."Minimum Quantity");

        // Verify: Verify Unit Price on Sales line with Unit Price of Item and deduct Discount Amount.
        VerifyUnitPriceOnSalesLine(SalesPrice."Item No.", SalesLine."Unit Price", SalesPrice."Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceSalesPriceDiscountAmt()
    var
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        OldAutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Calculate Sales Price based on Cost-plus, Verify Unit price on Posted Sales Invoice.

        // Setup: Update Automatic Cost Adjustment on Inventory Setup, Create Sales Price with Cost Plus and create Sales Order.
        UpdateAutomaticCostAdjustmentOnInventorySetup(OldAutomaticCostAdjustment, InventorySetup."Automatic Cost Adjustment"::Day);
        CreateSalesPriceWithCostPlus(
          SalesPrice, SalesPrice."Sales Type"::"All Customers", '', WorkDate(), LibraryRandom.RandDec(10, 2));  // Customer Number - blank and Random Minimum Quantity.

        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), '', SalesPrice."Item No.", SalesPrice."Minimum Quantity");  // Campaign Number - blank.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post Sales Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Unit Price on Sales Invoice Line based on Sales Price - Unit Price.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", SalesPrice."Item No.");
        SalesInvoiceLine.FindFirst();
        Assert.AreNearlyEqual(
          SalesPrice."Unit Price", SalesInvoiceLine."Unit Price", LibraryERM.GetAmountRoundingPrecision(), UnitPriceMustBeSameMsg);

        // Teardown.
        UpdateAutomaticCostAdjustmentOnInventorySetup(OldAutomaticCostAdjustment, OldAutomaticCostAdjustment);
    end;

    [Test]
    procedure CopySalesPriceToPriceListLineAndBack()
    var
        Item: Record Item;
        TempSalesPrice: Record "Sales Price" temporary;
        PriceListLine: Record "Price List Line";
        CopyFromToPriceListLine: codeunit CopyFromToPriceListLine;
        CostPlusPct: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        TempSalesPrice."Sales Type" := TempSalesPrice."Sales Type"::"All Customers";
        TempSalesPrice."Item No." := Item."No.";
        CostPlusPct := LibraryRandom.RandDec(10, 2);
        TempSalesPrice."Cost-plus %" := CostPlusPct;
        TempSalesPrice.Insert();
        TempSalesPrice := TempSalesPrice;
        TempSalesPrice."Starting Date" := WorkDate();
        TempSalesPrice."Cost-plus %" := 0;
        TempSalesPrice."Discount Amount" := CostPlusPct * 10;
        TempSalesPrice.Insert();

        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(TempSalesPrice, PriceListLine);
        TempSalesPrice.DeleteAll();
        CopyFromToPriceListLine.CopyTo(TempSalesPrice, PriceListLine);

        Assert.RecordCount(TempSalesPrice, 2);
        TempSalesPrice.FindSet();
        TempSalesPrice.TestField("Cost-plus %", CostPlusPct);
        TempSalesPrice.Next();
        TempSalesPrice.TestField("Discount Amount", CostPlusPct * 10);
    end;

    [Test]
    procedure AutoAdjCostDoesNotModifyCostPlusPriceIfCostHasNotChanged()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesPrice2: Record "Sales Price";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesPriceWithCostPlus: Codeunit "Sales Price With Cost Plus";
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        // [SCENARIO 409350] Cost adjust does not call for 'Cost-Plus %' price line update if cost is not changed.

        // [GIVEN] Enable automatic cost adjustment and automatic cost posting on Inventory Setup.
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAutomaticCostPosting(true);
        // [GIVEN] Item 'I', where "Costing Method" is 'Average', "Unit Cost" is 100
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);
        UnitCost := Item."Unit Cost";
        // [GIVEN] 2 Sales Price List lines, where "Asset No." is 'I', "Cost-Plus %" is 50
        CreateCostPlusSalesPriceLine(SalesPrice2, LibraryInventory.CreateItemNo());
        CreateCostPlusSalesPriceLine(SalesPrice, Item."No.");
        UnitPrice := SalesPrice."Unit Price";

        // [GIVEN] Purchase Invoice, where "Direct Unit Cost" is 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        BindSubscription(SalesPriceWithCostPlus); // to count modify calls
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Item 'I', where "Unit Cost" is 100 (not changed)
        Item.Find();
        Item.TestField("Unit Cost", UnitCost);
        // [THEN] Price List Line for 'I', where "Unit Price" is 'X' (not changed)
        SalesPrice.Find();
        SalesPrice.Testfield("Unit Price", UnitPrice);
        // [THEN] Price lines were not modified
        Assert.AreEqual(0, SalesPriceWithCostPlus.GetModifiedLines(SalesPrice."Sales Code"), 'number of modified Price List Lines');
        Assert.AreEqual(0, SalesPriceWithCostPlus.GetModifiedLines(SalesPrice2."Sales Code"), 'number of modified Price List Line #2');
    end;

    [Test]
    procedure AutoAdjCostModifiesJustOneCostPlusPriceIfCostHasBeenChangedByLostDirectCost()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesPrice2: Record "Sales Price";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesPriceWithCostPlus: Codeunit "Sales Price With Cost Plus";
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        // [SCENARIO 409350] 'Cost-Plus %' price line updated by posting a document with the new "last direct cost"
        // [GIVEN] Enable automatic cost adjustment and automatic cost posting on Inventory Setup.
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAutomaticCostPosting(true);
        // [GIVEN] Item 'I', where "Costing Method" is 'Average', "Unit Cost" is 100
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);
        UnitCost := Item."Unit Cost";
        // [GIVEN] 2 Sales Price List lines, where "Asset No." is 'I', "Cost-Plus %" is 50
        CreateCostPlusSalesPriceLine(SalesPrice2, LibraryInventory.CreateItemNo());
        UnitPrice := CreateCostPlusSalesPriceLine(SalesPrice, Item."No.");

        // [GIVEN] Purchase Invoice, where "Direct Unit Cost" is 101
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost + 1);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        BindSubscription(SalesPriceWithCostPlus); // to count modify calls
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Item 'I', where "Unit Cost" is 101 (changed)
        Item.Find();
        Item.TestField("Unit Cost", UnitCost + 1);
        // [THEN] Price List Line for 'I', where "Unit Price" is proportionally changed
        SalesPrice.Find();
        Assert.AreNearlyEqual(UnitPrice * Item."Unit Cost" / UnitCost, SalesPrice."Unit Price", 0.01, 'Wromg new price');
        // [THEN] Price line is modified once
        Assert.AreEqual(1, SalesPriceWithCostPlus.GetModifiedLines(SalesPrice."Sales Code"), 'number of modified Price List Lines');
        Assert.AreEqual(0, SalesPriceWithCostPlus.GetModifiedLines(SalesPrice2."Sales Code"), 'number of modified Price List Line #2');
    end;

    [Test]
    procedure AutoAdjCostModifiesJustOneCostPlusPriceIfCostHasBeenChangedByAdjustment()
    var
        Item: Record Item;
        SalesPrice: array[4] of Record "Sales Price";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesPriceWithCostPlus: Codeunit "Sales Price With Cost Plus";
        UnitCost: Decimal;
        UnitPrice: array[2] of Decimal;
    begin
        // [SCENARIO 409350] 'Cost-Plus %' price lines updated by automatic cost adjustment

        // [GIVEN] Enable automatic cost adjustment and automatic cost posting on Inventory Setup.
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAutomaticCostPosting(true);
        // [GIVEN] Item 'I', where "Costing Method" is 'Average', "Unit Cost" is 100
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);
        UnitCost := Item."Unit Cost";
        // [GIVEN] 2 Sales Price List lines, where "Asset No." is 'I', "Cost-Plus %" is 50
        UnitPrice[1] := CreateCostPlusSalesPriceLine(SalesPrice[1], Item."No.");
        UnitPrice[2] := CreateCostPlusSalesPriceLine(SalesPrice[2], Item."No.");
        // [GIVEN] Price lines with Item 'I' and another Item, where "Cost-Plus %" is 0
        CreateSalesPrice(
            SalesPrice[3], "Sales Price Type"::Customer, LibrarySales.CreateCustomerNo(), 0D, 0, Item);
        CreateSalesPrice(
            SalesPrice[4], "Sales Price Type"::Customer, LibrarySales.CreateCustomerNo(), 0D, 0);

        // [GIVEN] Purchase Invoice with 2 lines for 'I', where "Direct Unit Cost" is 101 and 103
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost + 1);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost + 3);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        BindSubscription(SalesPriceWithCostPlus); // to count modify calls
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Item 'I', where "Unit Cost" is 102 (changed)
        Item.Find();
        Item.TestField("Unit Cost", UnitCost + 2);
        // [THEN] Price List Lines for 'I', where "Unit Price" are proportionally changed
        SalesPrice[1].Find();
        Assert.AreNearlyEqual(UnitPrice[1] * Item."Unit Cost" / UnitCost, SalesPrice[1]."Unit Price", 0.01, 'Wromg new price #1');
        SalesPrice[2].Find();
        Assert.AreNearlyEqual(UnitPrice[2] * Item."Unit Cost" / UnitCost, SalesPrice[2]."Unit Price", 0.01, 'Wromg new price #2');
        // [THEN] Each Price line with 'I' and "Cost-Plus %" is modified twice
        Assert.AreEqual(2, SalesPriceWithCostPlus.GetModifiedLines(SalesPrice[1]."Sales Code"), 'number of modified Price List Lines #1');
        Assert.AreEqual(2, SalesPriceWithCostPlus.GetModifiedLines(SalesPrice[2]."Sales Code"), 'number of modified Price List Lines #2');
        // [THEN] Other price lines are not modified
        Assert.AreEqual(0, SalesPriceWithCostPlus.GetModifiedLines(SalesPrice[3]."Sales Code"), 'number of modified Price List Line #3');
        Assert.AreEqual(0, SalesPriceWithCostPlus.GetModifiedLines(SalesPrice[4]."Sales Code"), 'number of modified Price List Line #4');
    end;

    local procedure CreateAndActivateCampaign(ContactNo: Code[20]): Code[20]
    var
        Campaign: Record Campaign;
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate());
        Campaign.Modify(true);
        CreateSegmentHeaderWithLine(Campaign."No.", ContactNo);
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);
        exit(Campaign."No.");
    end;

    local procedure CreateContactWithCustomer(): Code[20]
    var
        Contact: Record Contact;
        CustomerTempl: Record "Customer Templ.";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        CustomerTempl.SetRange("Currency Code", '');
        CustomerTempl.FindFirst();
        Contact.CreateCustomerFromTemplate(CustomerTempl.Code);
        exit(Contact."No.")
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(100, 200, 2));
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemWithCostingMethod(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateCostPlusSalesPriceLine(var SalesPrice: Record "Sales Price"; ItemNo: Code[20]): Decimal;
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        CreateSalesPriceWithCostPlus(SalesPrice, "Sales Price Type"::Customer, LibrarySales.CreateCustomerNo(), 0D, 0, Item);
        exit(Salesprice."Unit Price");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; CampaignNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Campaign No.", CampaignNo);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesPrice(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; CustomerNo: Code[20]; StartingDate: Date; MinimumQuantity: Decimal)
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesType, CustomerNo, Item."No.", StartingDate, '', '', Item."Base Unit of Measure", MinimumQuantity);  // Currency Code and Variant Code as blank.
        SalesPrice.Validate("Ending Date", SalesPrice."Starting Date");
        SalesPrice.Modify(true);
    end;

    local procedure CreateSalesPrice(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; CustomerNo: Code[20]; StartingDate: Date; MinimumQuantity: Decimal; Item: Record Item)
    begin
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesType, CustomerNo, Item."No.", StartingDate, '', '', Item."Base Unit of Measure", MinimumQuantity);  // Currency Code and Variant Code as blank.
        SalesPrice.Validate("Ending Date", SalesPrice."Starting Date");
        SalesPrice.Modify(true);
    end;

    local procedure CreateSalesPriceWithCostPlus(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; CustomerNo: Code[20]; StartingDate: Date; MinimumQuantity: Decimal)
    begin
        CreateSalesPrice(SalesPrice, SalesType, CustomerNo, StartingDate, MinimumQuantity);
        UpdateCostPlusPctOnSalesPrice(SalesPrice);
    end;

    local procedure CreateSalesPriceWithCostPlus(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; CustomerNo: Code[20]; StartingDate: Date; MinimumQuantity: Decimal; Item: Record Item)
    begin
        CreateSalesPrice(SalesPrice, SalesType, CustomerNo, StartingDate, MinimumQuantity, Item);
        UpdateCostPlusPctOnSalesPrice(SalesPrice);
    end;

    local procedure CreateSalesPriceWithDiscountAmount(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; CustomerNo: Code[20]; StartingDate: Date)
    begin
        CreateSalesPrice(SalesPrice, SalesType, CustomerNo, StartingDate, LibraryRandom.RandDecInDecimalRange(10, 20, 2));  // Random range for Minimum Quantity
        SalesPrice.Validate("Discount Amount", LibraryRandom.RandDec(10, 2));
        SalesPrice.Modify(true);
    end;

    local procedure CreateSegmentHeaderWithLine(CampaignNo: Code[20]; ContactNo: Code[20])
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Campaign No.", CampaignNo);
        SegmentHeader.Modify(true);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Validate("Campaign Target", true);
        SegmentLine.Modify(true);
    end;

    local procedure FindCustomerFromContactBusinessRelation(ContactNo: Code[20]) CustomerNo: Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.FindFirst();
        CustomerNo := ContactBusinessRelation."No.";
    end;

    local procedure UpdateAutomaticCostAdjustmentOnInventorySetup(var OldAutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type"; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldAutomaticCostAdjustment := InventorySetup."Automatic Cost Adjustment";
        InventorySetup."Automatic Cost Adjustment" := AutomaticCostAdjustment;
        InventorySetup.Modify(true);
    end;

    local procedure UpdateCostPlusPctOnSalesPrice(var SalesPrice: Record "Sales Price")
    begin
        SalesPrice.Validate("Cost-plus %", LibraryRandom.RandIntInRange(10, 20));
        SalesPrice.Modify(true);
    end;

    local procedure VerifyUnitPriceOnSalesLine(ItemNo: Code[10]; UnitPrice: Decimal; DiscountAmount: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreNearlyEqual(UnitPrice, Item."Unit Price" - DiscountAmount, LibraryERM.GetAmountRoundingPrecision(), UnitPriceMustBeSameMsg);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    procedure GetModifiedLines(SalesCode: Text): Integer;
    begin
        if ModifiedLines.ContainsKey(SalesCode) then
            exit(ModifiedLines.Get(SalesCode));
        exit(0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Price", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyPriceLine(var Rec: Record "Sales Price");
    begin
        if not ModifiedLines.ContainsKey(Rec."Sales Code") then
            ModifiedLines.Add(Rec."Sales Code", 0);
        ModifiedLines.Set(Rec."Sales Code", ModifiedLines.Get(Rec."Sales Code") + 1);
    end;
}
