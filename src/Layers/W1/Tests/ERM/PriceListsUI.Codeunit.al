codeunit 134117 "Price Lists UI"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FeatureIsOffErr: Label 'This page is used by a feature that is not enabled.';
        IsInitialized: Boolean;
        CreateNewTxt: Label 'Create New...';
        ViewExistingTxt: Label 'View Existing Prices and Discounts...';
        AllLinesVerifiedMsg: Label 'All price list lines which were modified by you were verified.';
        AmountTypeNotAlowedErr: Label '%1 is not allowed for %2.', Comment = '%1 - Amount type, %2 - source type';
        TestFieldErr: Label '%1 must have a value', Comment = '%1 = Field Caption';
        CodeErr: Label '%1 must be %2 in %3.', Comment = '%1 = Code, %2 = Next No. from No. Series, %3 = Sales/Purchase Price List';
        CustDiscountGroupDeleteErr: Label 'You cannot delete the Customer Discount Group %1 because it is used in Customer.', Comment = '%1= Customer Discount Group Code.';
        CustDiscountGroupCodeDeleteErr: Label 'The field Customer Disc. Group of table Sales Line contains a value (%1) that cannot be found in the related table (Customer Discount Group).', Comment = '%1= Customer Discount Group Code.';

    [Test]
    procedure T000_SalesPriceListsPageIsNotEditable()
    var
        PriceListHeader: Record "Price List Header";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Customers', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');

        // [WHEN] Open page "Sales Price Lists" without filters
        SalesPriceLists.Trap();
        Page.Run(Page::"Sales Price Lists");

        // [THEN] The page is not editable, 
        Assert.IsFalse(SalesPriceLists.Editable(), 'the page is editable');
        // [THEN] The columns are Description, Status, "Currency Code", "Source Type", "Source No.", "Starting Date", "Ending Date"
        Assert.IsTrue(SalesPriceLists.Description.Visible(), 'Description is not visible');
        Assert.IsTrue(SalesPriceLists.Status.Visible(), 'Status is not visible');
        Assert.IsTrue(SalesPriceLists.SourceType.Visible(), 'SourceType is not visible');
        Assert.IsTrue(SalesPriceLists.SourceNo.Visible(), 'SourceNo is not visible');
        Assert.IsTrue(SalesPriceLists."Starting Date".Visible(), 'Starting Date is not visible');
        Assert.IsTrue(SalesPriceLists."Ending Date".Visible(), 'Ending Date is not visible');
    end;

    [Test]
    procedure T001_SalesPriceListsShowsAllCustomers()
    var
        PriceListHeader: array[5] of Record "Price List Header";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows prices for "All Customers" if open not from a customer.
        Initialize(true);

        // [GIVEN] Price List #1, where "Source Type" is 'Campaign' 'B', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::Campaign, '');
        // [GIVEN] Price List #2, where "Source Type" is 'All Customers', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Price List #3, where "Source Type" is 'Vendor' 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::"Vendor", '');
        // [GIVEN] Price List #4, where "Source Type" is 'Customer' 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::"Customer", '');
        // [GIVEN] Price List #5, where "Source Type" is 'All Jobs', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Sales Price Lists" without filters
        SalesPriceLists.Trap();
        Page.Run(Page::"Sales Price Lists");

        // [THEN] There are 2 price lists with source types: "All Customers" and "Customer"
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        Assert.IsFalse(SalesPriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T002_SalesPriceListsPricesFromCustomersCard()
    var
        Customer: array[2] of Record Customer;
        PriceListHeader: array[4] of Record "Price List Header";
        CustomerCard: TestPage "Customer Card";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows prices for one customer open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Customer Card for customer 'A'
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Sales Price Lists"
        SalesPriceLists.Trap();
        CustomerCard.PriceLists.Invoke();

        // [THEN] There are 3 price lists - #1, #2, #4
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found third');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        Assert.IsFalse(SalesPriceLists.Next(), 'found 4th');
    end;

    [Test]
    procedure T003_SalesPriceListsDiscountsFromCustomersList()
    var
        Customer: array[2] of Record Customer;
        PriceListHeader: array[4] of Record "Price List Header";
        CustomerList: TestPage "Customer List";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows discounts for one customer open from the customer list.
        Initialize(true);
        // [GIVEN] Customers 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers', "Amount Type" is 'Price&Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader[1].Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader[1].Modify();
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B', "Amount Type" is 'Price&Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        PriceListHeader[3].Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader[3].Modify();
        // [GIVEN] Price List #4, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Customer List for customer 'A'
        CustomerList.OpenEdit();
        CustomerList.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        SalesPriceLists.Trap();
        CustomerList.PriceListsDiscounts.Invoke();

        // [THEN] There are 2 price lists - #1 and #2
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsFalse(SalesPriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T004_SalesPriceLinesFromCustomersCard()
    var
        Customer: array[2] of Record Customer;
        PriceListLine: array[4] of Record "Price List Line";
        CustomerCard: TestPage "Customer Card";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Sales Price Review page shows price lines for one customer open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        // [GIVEN] Price List #4, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Discount'
        CreateSalesPriceLinesForCustomers(Customer, PriceListLine);

        // [GIVEN] Open Customer Card for customer 'A'
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Sales Prices"
        PriceListLineReview.Trap();
        CustomerCard.PriceLines.Invoke();

        // [THEN] There is 1 price line - #2, "Price List Description" is '002'
        Assert.IsTrue(PriceListLineReview.First(), 'not found first');
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        PriceListLineReview.PriceListDescription.AssertEquals(PriceListLine[2].FieldName(Description) + PriceListLine[2]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 2th');
    end;

    [Test]
    procedure T005_SalesDiscountLinesFromCustomersList()
    var
        Customer: array[2] of Record Customer;
        PriceListLine: array[4] of Record "Price List Line";
        CustomerList: TestPage "Customer List";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Sales Price Review page shows discount lines for one customer open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        // [GIVEN] Price List #4, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Discount'
        CreateSalesPriceLinesForCustomers(Customer, PriceListLine);

        // [GIVEN] Open Customer List for customer 'A'
        CustomerList.OpenEdit();
        CustomerList.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Sales Discounts"
        PriceListLineReview.Trap();
        CustomerList.DiscountLines.Invoke();

        // [THEN] There is 1 price line - #4
        Assert.IsTrue(PriceListLineReview.First(), 'not found first');
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[4]."Price List Code");
        PriceListLineReview.PriceListDescription.AssertEquals(PriceListLine[4].FieldName(Description) + PriceListLine[4]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 2th');
    end;

    [Test]
    procedure T006_SalesPriceListsPricesForPriceGroupFromCustomersCard()
    var
        Customer: array[2] of Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        PriceListHeader: array[5] of Record "Price List Header";
        CustomerCard: TestPage "Customer Card";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows prices for one customer and its price group open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A', where "Customer Price Group" is 'X', "Customer Disc. Group" 'Y', and Customer 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer[1]."Customer Price Group" := CustomerPriceGroup.Code;
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        Customer[1]."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer[1].Modify();
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[2]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Customer Price Group' 'X', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();
        // [GIVEN] Price List #5, where "Source Type" is 'Customer Discount Group' 'Y', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup.Code);
        PriceListHeader[5]."Amount Type" := PriceListHeader[5]."Amount Type"::Discount;
        PriceListHeader[5].Modify();

        // [GIVEN] Open Customer Card for customer 'A'
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Sales Price Lists"
        SalesPriceLists.Trap();
        CustomerCard.PriceLists.Invoke();

        // [THEN] There are 4 price lists - #1, #2, #4, #5
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found third');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found 4th');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[5]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[5]."Source No.");
        Assert.IsFalse(SalesPriceLists.Next(), 'found 5th');
    end;

    [Test]
    procedure T007_SalesPriceLinesForPriceGroupFromCustomersCard()
    var
        Customer: array[2] of Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        PriceListLine: array[5] of Record "Price List Line";
        CustomerPriceGroups: TestPage "Customer Price Groups";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Sales Price lists page shows prices for one customer and its price group open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A', where "Customer Price Group" is 'X', "Customer Disc. Group" 'Y', and Customer 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer[1]."Customer Price Group" := CustomerPriceGroup.Code;
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        Customer[1]."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer[1].Modify();
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '001', "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[1]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[1].Modify();
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], '002', "Price Source Type"::Customer, Customer[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], '003', "Price Source Type"::Customer, Customer[2]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[3]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[3].Modify();
        // [GIVEN] Price List #4, where "Source Type" is 'Customer Price Group' 'X', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[4], '004', "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code,
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List #5, where "Source Type" is 'Customer Discount Group' 'Y', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine[4], '004', "Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup.Code,
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Open Customer Price Groups page
        CustomerPriceGroups.OpenEdit();
        CustomerPriceGroups.Filter.SetFilter(Code, CustomerPriceGroup.Code);

        // [WHEN] Run action "Sales Prices"
        PriceListLineReview.Trap();
        CustomerPriceGroups.PriceLines.Invoke();

        // [THEN] There is 1 price line - #4
        Assert.IsTrue(PriceListLineReview.First(), 'not found first');
        PriceListLineReview."Price List Code".AssertEquals('004');
        Assert.IsFalse(PriceListLineReview.Next(), 'found 2nd');
    end;

    [Test]
    procedure T008_SalesPriceListsDiscForDiscGroupFromCustomersCard()
    var
        Customer: array[2] of Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        PriceListHeader: array[5] of Record "Price List Header";
        CustomerCard: TestPage "Customer Card";
        SalesPriceLists: TestPage "Sales Price Lists";
    begin
        // [SCENARIO] Sales Price lists page shows discounts for one customer and its discount group open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A', where "Customer Price Group" is 'X', "Customer Disc. Group" 'Y', and Customer 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer[1]."Customer Price Group" := CustomerPriceGroup.Code;
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        Customer[1]."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer[1].Modify();
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers', "Amount Type" 'Any'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader[1]."Amount Type" := PriceListHeader[1]."Amount Type"::Any;
        PriceListHeader[1].Modify();
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[2]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Customer Price Group' 'X', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();
        // [GIVEN] Price List #4, where "Source Type" is 'Customer Discount Group' 'Y', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup.Code);
        PriceListHeader[5]."Amount Type" := PriceListHeader[5]."Amount Type"::Discount;
        PriceListHeader[5].Modify();

        // [GIVEN] Open Customer Card for customer 'A'
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        SalesPriceLists.Trap();
        CustomerCard.PriceListsDiscounts.Invoke();

        // [THEN] There are 3 price lists - #1, #2, #5
        Assert.IsTrue(SalesPriceLists.First(), 'not found first');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found second');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(SalesPriceLists.Next(), 'not found third');
        SalesPriceLists.SourceType.AssertEquals(PriceListHeader[5]."Source Type");
        SalesPriceLists.SourceNo.AssertEquals(PriceListHeader[5]."Source No.");
        Assert.IsFalse(SalesPriceLists.Next(), 'found fourth');
    end;

    [Test]
    procedure T009_SalesDisounctLinesForDiscGroupFromCustomerDiscountGroups()
    var
        Customer: array[2] of Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        PriceListLine: array[5] of Record "Price List Line";
        CustomerDiscGroups: TestPage "Customer Disc. Groups";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Sales Price lists page shows prices for one customer and its price group open from the customer card.
        Initialize(true);
        // [GIVEN] Customers 'A', where "Customer Price Group" is 'X', "Customer Disc. Group" 'Y', and Customer 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer[1]."Customer Price Group" := CustomerPriceGroup.Code;
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        Customer[1]."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer[1].Modify();
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '001', "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[1]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[1].Modify();
        // [GIVEN] Price List #2, where "Source Type" is 'Customer' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], '002', "Price Source Type"::Customer, Customer[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'B'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], '003', "Price Source Type"::Customer, Customer[2]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[3]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[3].Modify();
        // [GIVEN] Price List #4, where "Source Type" is 'Customer Price Group' 'X', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[4], '004', "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code,
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List #5, where "Source Type" is 'Customer Discount Group' 'Y', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine[4], '005', "Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup.Code,
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        // [GIVEN] Open Customer Discount Groups page
        CustomerDiscGroups.OpenEdit();
        CustomerDiscGroups.Filter.SetFilter(Code, CustomerDiscountGroup.Code);

        // [WHEN] Run action "Sales Discounts"
        PriceListLineReview.Trap();
        CustomerDiscGroups.DiscountLines.Invoke();

        // [THEN] There is 1 price line - #5
        Assert.IsTrue(PriceListLineReview.First(), 'not found first');
        PriceListLineReview."Price List Code".AssertEquals('005');
        Assert.IsFalse(PriceListLineReview.Next(), 'found 2nd');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T010_SalesStatusFromDraftToActive()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] Sales Price list page gets not editable (except Status control) if Status set to Active.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Draft'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        SalesPriceList.OpenEdit();
        SalesPriceList.SourceType.AssertEquals("Price Source Type"::"All Customers");
        Assert.IsFalse(SalesPriceList.JobSourceType.Visible(), 'JobSourceType.Visible');
        // [GIVEN] Price list page open, where Status is 'Draft', all controls are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(SalesPriceList);

        // [WHEN] Change Status to 'Active' (answer 'Yes' to confirmation)
        SalesPriceList.Status.SetValue(PriceListHeader.Status::Active);

        // [THEN] All fields and lines part are not editable,
        VerifyAllControlsNotEditable(SalesPriceList);
        // [GIVEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');
    end;

    [Test]
    procedure T011_SalesStatusFromInactiveToDraft()
    var
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] Sales Price list page gets editable if Status set to Draft.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Inactive'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        PriceListHeader.Modify();
        SalesPriceList.OpenEdit();
        // [GIVEN] Price list page open, where Status is Inactive, all controls are not editable 
        VerifyAllControlsNotEditable(SalesPriceList);
        // [GIVEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');

        // [WHEN] Change Status to 'Draft'
        SalesPriceList.Status.SetValue(PriceListHeader.Status::Draft);

        // [THEN] All fields and lines part are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(SalesPriceList);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T012_SalesStatusFromDraftToActiveIfActiveIsEditable()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] Sales Price list page gets editable if Status set to Active and "Allow Editing Active Price".
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where Status is 'Draft'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        // [GIVEN] Price list page open, where Status is 'Draft', all controls are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(SalesPriceList);

        // [WHEN] Change Status to 'Active' (answer 'Yes' to confirmation)
        SalesPriceList.Status.SetValue(PriceListHeader.Status::Active);

        // [THEN] All fields and lines part are editable,
        VerifyAllControlsEditable(SalesPriceList);
        // [THEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(SalesPriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(SalesPriceList.AmountType.Editable(), 'AmountType.not Editable');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    procedure T013_NewLineAsDraftInActiveEditableSalesPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] New line added to the active (editable) price list gets status 'Draft', gets 'Active' by "Verify Lines" action.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where Status is 'Active'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Add a new line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Price" is 100
        ItemNo := LibraryInventory.CreateItemNo();
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".AssertEquals("Price Asset Type"::"G/L Account"); // Taken from the previous line
        SalesPriceList.Lines."Asset Type".SetValue('Item');
        SalesPriceList.Lines."Asset No.".SetValue(ItemNo);
        SalesPriceList.Lines."Unit Price".SetValue(100);
        SalesPriceList.Lines.First();

        // [THEN] New line, where Status is 'Draft'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", "Price Type"::Sale);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Customers");
        PriceListLine.TestField(Status, "Price Status"::Draft);

        // [WHEN] Run "Verify Lines" action
        SalesPriceList.VerifyLines.Invoke();

        // [THEN] Message "All lines are verified"
        Assert.AreEqual(AllLinesVerifiedMsg, LibraryVariableStorage.DequeueText(), 'Wrong message');
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Both lines are 'Active'
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange(Status, "Price Status"::Active);
        Assert.RecordCount(PriceListLine, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,NotificationHandler,MessageHandler')]
    procedure T014_NewLineAsDraftOnClosingActiveEditableSalesPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] New line added to the active (editable) price list gets status 'Draft', gets 'Active' on page closing.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where Status is 'Active'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Add a new line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Price" is 100
        ItemNo := LibraryInventory.CreateItemNo();
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue('Item');
        SalesPriceList.Lines."Asset No.".SetValue(ItemNo);
        SalesPriceList.Lines."Unit Price".SetValue(100);
        SalesPriceList.Lines.First();

        // [THEN] New line, where Status is 'Draft'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.FindFirst();
        PriceListLine.TestField(Status, "Price Status"::Draft);

        // [WHEN] Close the price list page
        SalesPriceList.Close();
        // [WHEN] Notification appears, click "Verify Lines"
        Assert.AreEqual(PriceListHeader.Code, LibraryVariableStorage.DequeueText(), 'Header Code in notification');

        // [THEN] Message "All lines are verified"
        Assert.AreEqual(AllLinesVerifiedMsg, LibraryVariableStorage.DequeueText(), 'Wrong message');
        // [THEN] Both lines are 'Active'
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange(Status, "Price Status"::Active);
        Assert.RecordCount(PriceListLine, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,NotificationHandlerSkipMessage')]
    procedure NewLineAsDraftOnClosingActiveEditableSalesPriceListWithSkipMessage()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] New line added to the active (editable) price list gets status 'Draft', gets 'Active' on page closing.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where Status is 'Active'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Add a new line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Price" is 100
        ItemNo := LibraryInventory.CreateItemNo();
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue('Item');
        SalesPriceList.Lines."Asset No.".SetValue(ItemNo);
        SalesPriceList.Lines."Unit Price".SetValue(100);
        SalesPriceList.Lines.First();

        // [THEN] New line, where Status is 'Draft'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.FindFirst();
        PriceListLine.TestField(Status, "Price Status"::Draft);

        // [WHEN] Close the price list page
        SalesPriceList.Close();
        // [WHEN] Notification appears, click "Verify Lines"
        Assert.AreEqual(PriceListHeader.Code, LibraryVariableStorage.DequeueText(), 'Header Code in notification');

        // [THEN] Both lines are 'Active'
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange(Status, "Price Status"::Active);
        Assert.RecordCount(PriceListLine, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,DuplicatePriceLinesModalHandler,MessageHandler')]
    procedure T015_NewDuplicateLineAsDraftOnVerifyLinesInActiveEditableSalesPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] New (duplicate) line added to the active (editable) price list needs resolution on "Verify Lines" action.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where Status is 'Active'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [WHEN] Price line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Price" is 50
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, ItemNo);
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [GIVEN] Add a new (duplicate) line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Price" is 100
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue('Item');
        SalesPriceList.Lines."Asset No.".SetValue(ItemNo);
        SalesPriceList.Lines."Unit Price".SetValue(100);
        SalesPriceList.Lines.First();

        // [GIVEN] Run "Verify Lines" action
        SalesPriceList.VerifyLines.Invoke();

        // [WHEN] Opened page "Duplicate Price Lines", where mark first line for removal, and pushed OK (by DuplicatePriceLinesModalHandler)
        // [THEN] Second line is 'Active' and the only line in the price list
        PriceListLine.SetRange("Asset No.");
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange(Status, "Price Status"::Active);
        Assert.RecordCount(PriceListLine, 1);
        // [THEN] Message "All lines are verified"
        Assert.AreEqual(AllLinesVerifiedMsg, LibraryVariableStorage.DequeueText(), 'Wrong message');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T016_SalesStatusFromDraftToActiveWithBlankAssetNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] Cannot set Status to Active if price list line contains the blank asset.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Draft'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        // [GIVEN] Price line, where "Asset No." is <blank>.
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListLine.Validate("Asset Type", "Price Asset Type"::" "); // converted to Item
        PriceListLine.Modify();
        SalesPriceList.OpenEdit();

        Commit();

        // [WHEN] Change Status to 'Active' (answer 'Yes' to confirmation)
        asserterror SalesPriceList.Status.SetValue(PriceListHeader.Status::Active);

        Assert.ExpectedError(StrSubstNo(TestFieldErr, PriceListLine.FieldCaption("Asset No.")));
    end;

    [Test]
    procedure T020_CustomerCardPriceListsActionVisibleIfFeatureOn()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Customer Card"
        CustomerCard.OpenEdit();

        // [THEN] "Sales Price Lists" action is visible, old actions are not visible
        Assert.IsTrue(CustomerCard.PriceLists.Visible(), 'PriceLists. not Visible');
        Assert.IsFalse(CustomerCard.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsFalse(CustomerCard.Prices.Visible(), 'Prices. Visible');
        Assert.IsFalse(CustomerCard."Line Discounts".Visible(), 'Line Discounts. Visible');
    end;

    [Test]
    procedure T021_CustomerCardPriceListsActionNotVisibleIfFeatureOff()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Customer Card"
        CustomerCard.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(CustomerCard.PriceLists.Visible(), 'PriceLists. Visible');
        Assert.IsFalse(CustomerCard.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsTrue(CustomerCard.Prices.Visible(), 'Prices. not Visible');
        Assert.IsTrue(CustomerCard."Line Discounts".Visible(), 'Line Discounts. not Visible');
    end;

    [Test]
    procedure T022_CustomerListPriceListsActionVisibleIfFeatureOn()
    var
        CustomerList: TestPage "Customer List";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Customer List"
        CustomerList.OpenEdit();

        // [THEN] "Sales Price Lists" action is visible, old actions are not visible
        Assert.IsTrue(CustomerList.PriceLists.Visible(), 'PriceLists. not Visible');
        Assert.IsFalse(CustomerList.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsFalse(CustomerList.Prices_Prices.Visible(), 'Prices_Prices. Visible');
        Assert.IsFalse(CustomerList.Prices_LineDiscounts.Visible(), 'Prices_LineDiscounts. Visible');
    end;

    [Test]
    procedure T023_CustomerListPriceListsActionNotVisibleIfFeatureOff()
    var
        CustomerList: TestPage "Customer List";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Customer List"
        CustomerList.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(CustomerList.PriceLists.Visible(), 'PriceLists. Visible');
        Assert.IsFalse(CustomerList.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsTrue(CustomerList.Prices_Prices.Visible(), 'Prices. not Visible');
        Assert.IsTrue(CustomerList.Prices_LineDiscounts.Visible(), 'Line Discounts. not Visible');
    end;

    [Test]
    procedure T024_SalesPriceListsPageNotOpenIfFeatureOff()
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Sales Price Lists" page
        asserterror Page.Run(Page::"Sales Price Lists");
        Assert.ExpectedError(FeatureIsOffErr);
    end;

    [Test]
    procedure T025_SalesPriceListPageNotOpenIfFeatureOff()
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Sales Price List" page
        asserterror Page.Run(Page::"Sales Price List");
        Assert.ExpectedError(FeatureIsOffErr);
    end;

    [Test]
    procedure T026_SalesPriceListPageAllowDiscountsOn()
    var
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);
        // [GIVEN] New sales price list, where AllowLineDisc and AllowInvoiceDisc are on
        SalesPriceList.OpenNew();
        Assert.IsTrue(SalesPriceList.Code.Editable(), 'Code.not Editable after OpenNew');
        SalesPriceList.AllowLineDisc.SetValue(true);
        Assert.IsFalse(SalesPriceList.Code.Editable(), 'Code.Editable after Insert');
        SalesPriceList.AllowInvoiceDisc.SetValue(true);

        // [WHEN] Add a new item line
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue("Price Asset Type"::Item);

        // [THEN] AllowLineDisc and AllowInvoiceDisc are on in the line
        SalesPriceList.Lines."Allow Line Disc.".AssertEquals(true);
        SalesPriceList.Lines."Allow Invoice Disc.".AssertEquals(true);
    end;

    [Test]
    procedure T027_SalesPriceListPageAllowDiscountsOff()
    var
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);
        // [GIVEN] New sales price list, where AllowLineDisc and AllowInvoiceDisc are off
        SalesPriceList.OpenNew();
        SalesPriceList.AllowLineDisc.SetValue(false);
        SalesPriceList.AllowInvoiceDisc.SetValue(false);

        // [WHEN] Add a new item line
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue("Price Asset Type"::Item);

        // [THEN] AllowLineDisc and AllowInvoiceDisc are off in the line
        SalesPriceList.Lines."Allow Line Disc.".AssertEquals(false);
        SalesPriceList.Lines."Allow Invoice Disc.".AssertEquals(false);
    end;

    [Test]
    procedure T028_SalesPriceListPageNewLineWithDefaultAssetType()
    var
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Sales]
        Initialize(true);
        // [GIVEN] New sales price list
        SalesPriceList.OpenNew();

        // [WHEN] Add a new line and put Item No.
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] "Asset Type" is Item, "Price Type" is 'Sale'
        SalesPriceList.Lines."Asset Type".AssertEquals("Price Asset Type"::Item);
        PriceListLine.SetRange("Price List Code", SalesPriceList.Code.Value());
        PriceListLine.FindLast();
        PriceListLine.TestField("Price Type", "Price Type"::Sale);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Customers");
        PriceListLine.TestField("Source No.", '');
    end;

    [Test]
    procedure T029_SalesJobPriceListPageNewLineWithDefaultAssetType()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Sales] [Job]
        Initialize(true);
        // [GIVEN] New sales price list from "Sales Job Price Lists" (simulate page filters)
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Price Type", "Price Type"::Sale);
        PriceListHeader.SetRange("Source Group", "Price Source Group"::Job);
        PriceListHeader.FilterGroup(0);
        SalesPriceList.Trap();
        Page.Run(Page::"Sales Price List", PriceListHeader);
        SalesPriceList.New();

        // [WHEN] Add a new line and put Item No.
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] "Asset Type" is Item, "Price Type" is 'Sale'
        SalesPriceList.Lines."Asset Type".AssertEquals("Price Asset Type"::Item);
        PriceListLine.SetRange("Price List Code", SalesPriceList.Code.Value());
        PriceListLine.FindLast();
        PriceListLine.TestField("Price Type", "Price Type"::Sale);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Jobs");
        PriceListLine.TestField("Source No.", '');
    end;

    [Test]
    procedure T030_OpenItemCardIfItemDiscGroupDeleted()
    var
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListLine: Record "Price List Line";
        ItemCard: TestPage "Item Card";
    begin
        Initialize(true);

        // [GIVEN] Item 'X', where "Item Disc. Group" is 'IDG'
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        Item.Modify();

        // [GIVEN] Purchase Price List Line for Item 'X'
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, Item."No.");
        // [GIVEN] Sales Price List Line for "Item Disc. Group" 'IDG'
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '',
            "Price Asset Type"::"Item Discount Group", ItemDiscountGroup.Code);

        // [GIVEN] Item Discount Group 'IDG' is removed
        ItemDiscountGroup.Delete();

        // [WHEN] Open Item card for 'X'
        ItemCard.Trap();
        Page.Run(Page::"Item Card", Item);

        // [THEN] Item card is open, where Purchase section: 'View existing prices...', Sales section: 'Create new...'
        ItemCard.SpecialPurchPriceListTxt.AssertEquals(ViewExistingTxt);
        ItemCard.SpecialSalesPriceListTxt.AssertEquals(CreateNewTxt);
        ItemCard.Close();
    end;

    [Test]
    procedure T031_ItemCardSpecialSalesPriceListTxtSkipsInactivePrices()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        ItemCard: TestPage "Item Card";
    begin
        Initialize(true);

        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);
        Item.Modify();

        // [GIVEN] Draft Purchase Price List Line for Item 'X'
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Draft;
        PriceListLine.Modify();
        // [GIVEN] Inactive Sales Price List Line for Item 'X'
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Inactive;
        PriceListLine.Modify();

        // [WHEN] Open Item card for 'X'
        ItemCard.Trap();
        Page.Run(Page::"Item Card", Item);

        // [THEN] Item card is open, where Purchase section: 'View existing prices...', Sales section: 'Create new...'
        ItemCard.SpecialPurchPriceListTxt.AssertEquals(ViewExistingTxt);
        ItemCard.SpecialSalesPriceListTxt.AssertEquals(CreateNewTxt);
        ItemCard.Close();
    end;

    [Test]
    procedure T035_AmountTypeValidationCustPriceGroupInSalesPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] Only "Amount Type" 'Price' is allowed for "Customer Price Group", if "Allow Editing Defaults" is No
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where "Customer Price Group", "Allow Editing Defaults" is No
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Price Group", '');
        PriceListHeader.TestField("Allow Updating Defaults", false);
        // [GIVEN] Open price list card, where "Amount Type" is 'Price'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Price);

        // [WHEN] Change "Amount Type" to 'Discount'
        asserterror SalesPriceList.AmountType.SetValue("Price Amount Type"::Discount);
        // [THEN] Error: 'Discount is not allowed ..'
        Assert.ExpectedError(
            StrSubstNo(AmountTypeNotAlowedErr, "Price Amount Type"::Discount, "Price Source Type"::"Customer Price Group"));

        // [WHEN] Change "Amount Type" to 'Price&Discount'
        asserterror SalesPriceList.AmountType.SetValue("Price Amount Type"::Any);
        // [THEN] Error: 'Price&Discount is not allowed ..'
        Assert.ExpectedError(
            StrSubstNo(AmountTypeNotAlowedErr, "Price Amount Type"::Any, "Price Source Type"::"Customer Price Group"));
    end;

    [Test]
    procedure T036_AmountTypeValidationCustPriceGroupInSalesPriceListAllowEditing()
    var
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] All "Amount Type" valies are allowed for "Customer Price Group", if "Allow Editing Defaults" is Yes
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where "Customer Price Group", "Allow Editing Defaults" is Yes
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Price Group", '');
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();

        // [GIVEN] Open price list card, where "Amount Type" is 'Price'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Price);

        // [WHEN] Change "Amount Type" to 'Discount'
        asserterror SalesPriceList.AmountType.SetValue("Price Amount Type"::Discount);
        // [THEN] "Amount Type" is 'Price'
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Price);

        // [WHEN] Change "Amount Type" to 'Price&Discount'
        asserterror SalesPriceList.AmountType.SetValue("Price Amount Type"::Any);
        // [THEN] "Amount Type" is 'Price'
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Price);
    end;

    [Test]
    procedure T037_AmountTypeValidationCustDiscGroupInSalesPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] Only "Amount Type" 'Discount' is allowed for "Customer Disc. Group", if "Allow Editing Defaults" is No
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where "Customer Disc. Group", "Allow Editing Defaults" is No
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Disc. Group", '');
        PriceListHeader.TestField("Allow Updating Defaults", false);
        // [GIVEN] Open price list card, where "Amount Type" is 'Discount'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Discount);

        // [WHEN] Change "Amount Type" to 'Price'
        asserterror SalesPriceList.AmountType.SetValue("Price Amount Type"::Price);
        // [THEN] Error: 'Discount is not allowed ..'
        Assert.ExpectedError(
            StrSubstNo(AmountTypeNotAlowedErr, "Price Amount Type"::Price, "Price Source Type"::"Customer Disc. Group"));

        // [WHEN] Change "Amount Type" to 'Price&Discount'
        asserterror SalesPriceList.AmountType.SetValue("Price Amount Type"::Any);
        // [THEN] Error: 'Price&Discount is not allowed ..'
        Assert.ExpectedError(
            StrSubstNo(AmountTypeNotAlowedErr, "Price Amount Type"::Any, "Price Source Type"::"Customer Disc. Group"));
    end;

    [Test]
    procedure T038_AmountTypeValidationCustDiscGroupInSalesPriceListAllowEditing()
    var
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] All "Amount Type" valies are allowed for "Customer Disc. Group", if "Allow Editing Defaults" is Yes
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List, where "Customer Disc. Group", "Allow Editing Defaults" is Yes
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Disc. Group", '');
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();

        // [GIVEN] Open price list card, where "Amount Type" is 'Discount'
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Discount);

        // [WHEN] Change "Amount Type" to 'Price'
        asserterror SalesPriceList.AmountType.SetValue("Price Amount Type"::Price);
        // [THEN] "Amount Type" is 'Discount'
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Discount);

        // [WHEN] Change "Amount Type" to 'Price&Discount'
        asserterror SalesPriceList.AmountType.SetValue("Price Amount Type"::Any);
        // [THEN] "Amount Type" is 'Discount'
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Discount);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T039_DefaultsCopiedToNewLineInSalesPriceListAllowEditing()
    var
        Currency: Record Currency;
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO] Defaults from the header are copied to the new line, if "Allow Editing Defaults" is Yes
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Price List for Customer X, where 'Starting Date' is 050122, "Allow Editing Defaults" is Yes
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, LibrarySales.CreateCustomerNo());
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader."Starting Date" := WorkDate() + 5;
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Create a new line
        SalesPriceList.Lines.New();

        // [THEN] New line, where Customer X, 'Starting Date' is 050122, "Asset Type" is Item
        SalesPriceList.Lines.SourceType.AssertEquals(PriceListHeader."Source Type");
        SalesPriceList.Lines.SourceNo.AssertEquals(PriceListHeader."Source No.");
        Assert.IsTrue(SalesPriceList.Lines.SourceNo.Visible(), 'SourceNo.not Visible');
        Assert.IsFalse(SalesPriceList.Lines.AssignToNo.Visible(), 'AssignToNo.Visible');
        SalesPriceList.Lines.StartingDate.AssertEquals(PriceListHeader."Starting Date");
        SalesPriceList.Lines."Asset Type".AssertEquals("Price Asset Type"::Item);

        // [GIVEN] Set Item No 'I1'
        SalesPriceList.Lines."Asset No.".SetValue(LibraryInventory.CreateItemNo());

        // [GIVEN] Change the header, "All Customers", "Currency Code" is 'CCC', Ending Date = 100122
        SalesPriceList.SourceType.SetValue("Price Source Type"::"All Customers");
        SalesPriceList.EndingDate.SetValue(WorkDate() + 10);
        LibraryERM.FindCurrency(Currency);
        SalesPriceList.CurrencyCode.SetValue(Currency.Code);

        // [WHEN] Create a new line
        SalesPriceList.Lines.New();

        // [THEN] New line, where All Customers, 'Ending Date' is 100122, "Currency Code" is 'CCC'
        PriceListHeader.Find();
        SalesPriceList.Lines.SourceType.AssertEquals(PriceListHeader."Source Type");
        SalesPriceList.Lines.SourceNo.AssertEquals(PriceListHeader."Source No.");
        SalesPriceList.Lines.StartingDate.AssertEquals(PriceListHeader."Starting Date");
        SalesPriceList.Lines.EndingDate.AssertEquals(PriceListHeader."Ending Date");
        SalesPriceList.Lines.CurrencyCode.AssertEquals(PriceListHeader."Currency Code");
    end;

    [Test]
    procedure T040_ValidateCurrencyCodeDifferentFromSource()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);

        // [GIVEN] Customer 'C', where "Currency Code" is 'USD'
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCurrency(Currency);
        Customer."Currency Code" := Currency.Code;
        Customer.Modify();
        // [GIVEN] Price List header for Customer 'C', but set "Currency Code" to 'EUR'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, Customer."No.");
        LibraryERM.CreateCurrency(Currency);
        PriceListHeader.Validate("Currency Code", Currency.Code);
        PriceListHeader.Modify();

        // [WHEN] Add new price list line for a g/l account
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.SourceType.AssertEquals("Price Source Type"::Customer);
        Assert.IsFalse(SalesPriceList.JobSourceType.Visible(), 'JobSourceType.Visible');
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue("Price Asset Type"::"G/L Account");
        SalesPriceList.Lines."Asset No.".SetValue(LibraryERM.CreateGLAccountNo());

        // [THEN] Price list line added, where "Currency Code" is 'EUR'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::"G/L Account");
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", "Price Type"::Sale);
        PriceListLine.TestField("Source Type", "Price Source Type"::Customer);
        PriceListLine.TestField("Source No.", Customer."No.");
        PriceListLine.TestField("Currency Code", Currency.Code);
    end;

    [Test]
    procedure T041_ValidateCurrencyCodeInLineAllowUpdatingDefaults()
    var
        Currency: array[2] of Record Currency;
        Vendor: array[2] of Record Vendor;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);

        // [GIVEN] Vendor 'C', where "Currency Code" is 'USD'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryERM.CreateCurrency(Currency[1]);
        Vendor[1]."Currency Code" := Currency[1].Code;
        Vendor[1].Modify();
        // [GIVEN] Vendor 'L', where "Currency Code" is 'EUR'
        LibraryPurchase.CreateVendor(Vendor[2]);
        LibraryERM.CreateCurrency(Currency[2]);
        Vendor[2]."Currency Code" := Currency[2].Code;
        Vendor[2].Modify();
        // [GIVEN] Price List header for Vendor 'C', where "Allow Updating Defaults" is 'Yes'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();

        // [WHEN] Add new price list line for Vendor 'L' and a g/l account
        PurchasePriceList.OpenEdit();
        PurchasePriceList.SourceType.AssertEquals("Price Source Type"::Vendor);
        Assert.IsFalse(PurchasePriceList.JobSourceType.Visible(), 'JobSourceType.Visible');
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        PurchasePriceList.Lines.New();
        Assert.IsTrue(PurchasePriceList.Lines.SourceNo.Visible(), 'SourceNo.not Visible');
        Assert.IsFalse(PurchasePriceList.Lines.AssignToNo.Visible(), 'AssignToNo.Visible');
        PurchasePriceList.Lines.SourceNo.SetValue(Vendor[2]."No.");
        PurchasePriceList.Lines."Asset Type".SetValue("Price Asset Type"::"G/L Account");
        Assert.IsTrue(PurchasePriceList.Lines."Asset No.".Visible(), '"Asset No.".not Visible');
        Assert.IsFalse(PurchasePriceList.Lines."Product No.".Visible(), '"Product No.". Visible');
        PurchasePriceList.Lines."Asset No.".SetValue(LibraryERM.CreateGLAccountNo());

        // [THEN] Price list line added, where "Currency Code" is 'EUR'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::"G/L Account");
        PriceListLine.FindFirst();
        PriceListLine.TestField("Source Type", "Price Source Type"::Vendor);
        PriceListLine.TestField("Source No.", Vendor[2]."No.");
        PriceListLine.TestField("Currency Code", Currency[2].Code);
    end;

    [Test]
    procedure T042_ValidateSourceNoInSalesHeaderAllowUpdatingDefaults()
    var
        Currency: array[2] of Record Currency;
        Customer: array[2] of Record Customer;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);

        // [GIVEN] Customer 'C', where "Currency Code" is 'USD'
        LibrarySales.CreateCustomer(Customer[1]);
        LibraryERM.CreateCurrency(Currency[1]);
        Customer[1]."Currency Code" := Currency[1].Code;
        Customer[1].Modify();
        // [GIVEN] Customer 'L', where "Currency Code" is 'EUR'
        LibrarySales.CreateCustomer(Customer[2]);
        LibraryERM.CreateCurrency(Currency[2]);
        Customer[2]."Currency Code" := Currency[2].Code;
        Customer[2].Modify();
        // [GIVEN] Price List header for Customer 'C', where "Allow Updating Defaults" is 'Yes' and one line
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::Customer, Customer[1]."No.",
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Change Customer to 'L' on the header
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        Assert.IsTrue(SalesPriceList.Lines.SourceNo.Visible(), 'SourceNo.not Visible');
        Assert.IsFalse(SalesPriceList.Lines.AssignToNo.Visible(), 'AssignToNo. Visible');
        SalesPriceList.SourceNo.SetValue(Customer[2]."No.");
        SalesPriceList.CurrencyCode.AssertEquals(Customer[2]."Currency Code");

        // [WHEN] Add new price list line with a g/l account
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue("Price Asset Type"::"G/L Account");
        Assert.IsTrue(SalesPriceList.Lines."Asset No.".Visible(), '"Asset No.".not Visible');
        Assert.IsFalse(SalesPriceList.Lines."Product No.".Visible(), '"Product No.". Visible');
        SalesPriceList.Lines."Asset No.".SetValue(LibraryERM.CreateGLAccountNo());

        // [THEN] Price list line added, where "Assign-to" is 'L', "Currency Code" is 'EUR'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::"G/L Account");
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", "Price Type"::Sale);
        PriceListLine.Testfield("Source No.", Customer[1]."No.");
        PriceListLine.TestField("Currency Code", Currency[1].Code);
        Assert.IsFalse(PriceListLine.Next() = 0, 'not found 2nd line');
        PriceListLine.Testfield("Source No.", Customer[2]."No.");
        PriceListLine.TestField("Currency Code", Currency[2].Code);
    end;

    [Test]
    procedure T043_ValidateSourceNoInPurchHeaderAllowUpdatingDefaults()
    var
        Currency: array[2] of Record Currency;
        Vendor: array[2] of Record Vendor;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);

        // [GIVEN] Vendor 'C', where "Currency Code" is 'USD'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryERM.CreateCurrency(Currency[1]);
        Vendor[1]."Currency Code" := Currency[1].Code;
        Vendor[1].Modify();
        // [GIVEN] Vendor 'L', where "Currency Code" is 'EUR'
        LibraryPurchase.CreateVendor(Vendor[2]);
        LibraryERM.CreateCurrency(Currency[2]);
        Vendor[2]."Currency Code" := Currency[2].Code;
        Vendor[2].Modify();
        // [GIVEN] Price List header for Vendor 'C', where "Allow Updating Defaults" is 'Yes' and one line
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::Vendor, Vendor[1]."No.",
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Change vendor to 'L' on the header
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        Assert.IsTrue(PurchasePriceList.Lines.SourceNo.Visible(), 'SourceNo.not Visible');
        Assert.IsFalse(PurchasePriceList.Lines.AssignToNo.Visible(), 'AssignToNo. Visible');
        PurchasePriceList.SourceNo.SetValue(Vendor[2]."No.");
        PurchasePriceList.CurrencyCode.AssertEquals(Vendor[2]."Currency Code");

        // [WHEN] Add new price list line with a g/l account
        PurchasePriceList.Lines.New();
        PurchasePriceList.Lines."Asset Type".SetValue("Price Asset Type"::"G/L Account");
        Assert.IsTrue(PurchasePriceList.Lines."Asset No.".Visible(), '"Asset No.".not Visible');
        Assert.IsFalse(PurchasePriceList.Lines."Product No.".Visible(), '"Product No.". Visible');
        PurchasePriceList.Lines."Asset No.".SetValue(LibraryERM.CreateGLAccountNo());

        // [THEN] Price list line added, where "Assign-to" is 'L', "Currency Code" is 'EUR'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::"G/L Account");
        PriceListLine.FindFirst();
        PriceListLine.Testfield("Source No.", Vendor[1]."No.");
        PriceListLine.TestField("Currency Code", Currency[1].Code);
        Assert.IsFalse(PriceListLine.Next() = 0, 'not found 2nd line');
        PriceListLine.Testfield("Source No.", Vendor[2]."No.");
        PriceListLine.TestField("Currency Code", Currency[2].Code);
    end;

    [Test]
    procedure T044_SalesPriceLinesAllowUpdatingDefaults()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);

        // [GIVEN] Price List header for "All Customers", where "Allow Updating Defaults" is 'Yes' and one line
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Open sales price list
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] "Applie-to Type", "Assign-to", "Currency Code",  "Starting/Ending Date", "Price Includes VAT" are visible and editable
        Assert.IsTrue(SalesPriceList.Lines.SourceType.Visible(), 'SourceType.Visible');
        Assert.IsTrue(SalesPriceList.Lines.SourceNo.Visible(), 'SourceNo.Visible');
        Assert.IsFalse(SalesPriceList.Lines.AssignToNo.Visible(), 'AssignToNo.Visible');
        Assert.IsTrue(SalesPriceList.Lines.CurrencyCode.Visible(), 'CurrencyCode.Visible');
        Assert.IsTrue(SalesPriceList.Lines.StartingDate.Visible(), 'StartingDate.Visible');
        Assert.IsTrue(SalesPriceList.Lines.EndingDate.Visible(), 'EndingDate.Visible');
        Assert.IsTrue(SalesPriceList.Lines.PriceIncludesVAT.Visible(), 'PriceIncludesVAT.No');
        Assert.IsTrue(SalesPriceList.Lines.VATBusPostingGrPrice.Visible(), 'VATBusPostingGrPrice.No');
    end;

    [Test]
    procedure T045_PurchPriceLinesAllowUpdatingDefaults()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchPriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);

        // [GIVEN] Price List header for "All Vendors", where "Allow Updating Defaults" is 'Yes' and one line
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Vendors", '');
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Open Purch price list
        PurchPriceList.OpenEdit();
        PurchPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] "Applie-to Type", "Assign-to", "Currency Code",  "Starting/Ending Date", "Price Includes VAT" are visible and editable
        Assert.IsTrue(PurchPriceList.Lines.SourceType.Visible(), 'SourceType.Visible');
        Assert.IsTrue(PurchPriceList.Lines.SourceNo.Visible(), 'SourceNo.Visible');
        Assert.IsFalse(PurchPriceList.Lines.AssignToNo.Visible(), 'AssignToNo.Visible');
        Assert.IsTrue(PurchPriceList.Lines.CurrencyCode.Visible(), 'CurrencyCode.Visible');
        Assert.IsTrue(PurchPriceList.Lines.StartingDate.Visible(), 'StartingDate.Visible');
        Assert.IsTrue(PurchPriceList.Lines.EndingDate.Visible(), 'EndingDate.Visible');
        Assert.IsTrue(PurchPriceList.Lines.PriceIncludesVAT.Visible(), 'PriceIncludesVAT.No');
        Assert.IsTrue(PurchPriceList.Lines.VATBusPostingGrPrice.Visible(), 'VATBusPostingGrPrice.No');
    end;

    [Test]
    procedure T046_SalesPriceLinesAllowUpdatingDefaultsDropDownLookup()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);
        // [GIVEN] Custom lookup is off
        LibraryPriceCalculation.SetUseCustomLookup(false);

        // [GIVEN] Price List header for "All Customers", where "Allow Updating Defaults" is 'Yes' and one line
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Open sales price list
        SalesPriceList.Trap();
        RunSalesPriceList("Price Source Group"::Customer);
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] "Assign-to Parent No." is not visible in the header
        Assert.IsTrue(SalesPriceList.SourceType.Visible(), 'Header SourceType.Visible');
        Assert.IsFalse(SalesPriceList.JobSourceType.Visible(), 'Header JobSourceType.Visible');
        Assert.IsFalse(SalesPriceList.AssignToParentNo.Visible(), 'Header AssignToParentNo.Visible');
        Assert.IsFalse(SalesPriceList.SourceNo.Visible(), 'Header SourceNo.Visible');
        Assert.IsTrue(SalesPriceList.AssignToNo.Visible(), 'Header AssignToNo.Visible');
        // [THEN] "Applie-to Type", "Assign-to", "Currency Code",  "Starting/Ending Date", "Price Includes VAT" are visible and editable
        Assert.IsTrue(SalesPriceList.Lines.SourceType.Visible(), 'SourceType.Visible');
        Assert.IsTrue(SalesPriceList.Lines.AssignToNo.Visible(), 'AssignToNo.Visible');
        Assert.IsFalse(SalesPriceList.Lines.AssignToParentNo.Visible(), 'AssignToParentNo.Visible');
        Assert.IsTrue(SalesPriceList.Lines.CurrencyCode.Visible(), 'CurrencyCode.Visible');
        Assert.IsTrue(SalesPriceList.Lines.StartingDate.Visible(), 'StartingDate.Visible');
        Assert.IsTrue(SalesPriceList.Lines.EndingDate.Visible(), 'EndingDate.Visible');
        Assert.IsTrue(SalesPriceList.Lines.PriceIncludesVAT.Visible(), 'PriceIncludesVAT.No');
        Assert.IsTrue(SalesPriceList.Lines.VATBusPostingGrPrice.Visible(), 'VATBusPostingGrPrice.No');
        Assert.IsTrue(SalesPriceList.Lines."Product No.".Visible(), '"Product No.".Visible');
        // [THEN] "Source No.", "Asset No." are invisible
        Assert.IsFalse(SalesPriceList.Lines.SourceNo.Visible(), 'SourceNo.Visible');
        Assert.IsFalse(SalesPriceList.Lines."Asset No.".Visible(), '"Asset No.".Visible');
    end;

    [Test]
    procedure T047_PurchPriceLinesAllowUpdatingDefaultsDropDownLookup()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchPriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);
        // [GIVEN] Custom lookup is off
        LibraryPriceCalculation.SetUseCustomLookup(false);

        // [GIVEN] Price List header for "All Vendors", where "Allow Updating Defaults" is 'Yes' and one line
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Vendors", '');
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Open Purch price list
        PurchPriceList.Trap();
        RunPurchPriceList("Price Source Group"::Vendor);
        PurchPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] "Assign-to Parent No." is not visible in the header
        Assert.IsTrue(PurchPriceList.SourceType.Visible(), 'Header SourceType.Visible');
        Assert.IsFalse(PurchPriceList.JobSourceType.Visible(), 'Header JobSourceType.Visible');
        Assert.IsFalse(PurchPriceList.AssignToParentNo.Visible(), 'Header AssignToParentNo.Visible');
        Assert.IsFalse(PurchPriceList.SourceNo.Visible(), 'Header SourceNo.Visible');
        Assert.IsTrue(PurchPriceList.AssignToNo.Visible(), 'Header AssignToNo.Visible');
        // [THEN] "Applie-to Type", "Assign-to", "Currency Code",  "Starting/Ending Date", "Price Includes VAT" are visible and editable
        Assert.IsTrue(PurchPriceList.Lines.SourceType.Visible(), 'SourceType.Visible');
        Assert.IsTrue(PurchPriceList.Lines.AssignToNo.Visible(), 'AssignToNo.Visible');
        Assert.IsFalse(PurchPriceList.Lines.AssignToParentNo.Visible(), 'AssignToParentNo.Visible');
        Assert.IsTrue(PurchPriceList.Lines.CurrencyCode.Visible(), 'CurrencyCode.Visible');
        Assert.IsTrue(PurchPriceList.Lines.StartingDate.Visible(), 'StartingDate.Visible');
        Assert.IsTrue(PurchPriceList.Lines.EndingDate.Visible(), 'EndingDate.Visible');
        Assert.IsTrue(PurchPriceList.Lines.PriceIncludesVAT.Visible(), 'PriceIncludesVAT.No');
        Assert.IsTrue(PurchPriceList.Lines.VATBusPostingGrPrice.Visible(), 'VATBusPostingGrPrice.No');
        Assert.IsTrue(PurchPriceList.Lines."Product No.".Visible(), '"Product No.".Visible');
        // [THEN] "Source No.", "Asset No." are invisible
        Assert.IsFalse(PurchPriceList.Lines.SourceNo.Visible(), 'SourceNo.Visible');
        Assert.IsFalse(PurchPriceList.Lines."Asset No.".Visible(), '"Asset No.".Visible');
    end;

    [Test]
    procedure T048_SalesJobPriceLinesAllowUpdatingDefaultsDropDownLookup()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);
        // [GIVEN] Custom lookup is off
        LibraryPriceCalculation.SetUseCustomLookup(false);

        // [GIVEN] Sales Price List for "All Jobs", where "Allow Updating Defaults" is 'Yes' and one line
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Jobs", '',
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Open Sales Job price list
        SalesPriceList.Trap();
        RunSalesPriceList("Price Source Group"::Job);
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] "Assign-to Parent No." is not visible in the header
        Assert.IsFalse(SalesPriceList.SourceType.Visible(), 'Header SourceType.Visible');
        Assert.IsTrue(SalesPriceList.JobSourceType.Visible(), 'Header JobSourceType.Visible');
        Assert.IsFalse(SalesPriceList.SourceNo.Visible(), 'Header SourceNo.Visible');
        Assert.IsFalse(SalesPriceList.AssignToParentNo.Visible(), 'Header AssignToParentNo.Visible');
        Assert.IsTrue(SalesPriceList.AssignToNo.Visible(), 'Header AssignToNo.Visible');
        // [THEN] "Assign-to Type", "Assign-to", "Currency Code",  "Starting/Ending Date", "Price Includes VAT" are visible and editable
        Assert.IsFalse(SalesPriceList.Lines.SourceType.Visible(), 'SourceType.Visible');
        Assert.IsTrue(SalesPriceList.Lines.JobSourceType.Visible(), 'JobSourceType.Visible');
        Assert.IsTrue(SalesPriceList.Lines.AssignToParentNo.Visible(), 'AssignToParentNo.Visible');
        Assert.IsTrue(SalesPriceList.Lines.AssignToNo.Visible(), 'AssignToNo.Visible');
        Assert.IsTrue(SalesPriceList.Lines.CurrencyCode.Visible(), 'CurrencyCode.Visible');
        Assert.IsTrue(SalesPriceList.Lines.StartingDate.Visible(), 'StartingDate.Visible');
        Assert.IsTrue(SalesPriceList.Lines.EndingDate.Visible(), 'EndingDate.Visible');
        Assert.IsTrue(SalesPriceList.Lines.PriceIncludesVAT.Visible(), 'PriceIncludesVAT.No');
        Assert.IsTrue(SalesPriceList.Lines.VATBusPostingGrPrice.Visible(), 'VATBusPostingGrPrice.No');
        Assert.IsTrue(SalesPriceList.Lines."Product No.".Visible(), '"Product No.".Visible');
        // [THEN] "Source No.", "Asset No." are invisible
        Assert.IsFalse(SalesPriceList.Lines.SourceNo.Visible(), 'SourceNo.Visible');
        Assert.IsFalse(SalesPriceList.Lines."Asset No.".Visible(), '"Asset No.".Visible');
    end;

    [Test]
    procedure T049_PurchJobPriceLinesAllowUpdatingDefaultsDropDownLookup()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchPriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);
        // [GIVEN] Custom lookup is off
        LibraryPriceCalculation.SetUseCustomLookup(false);

        // [GIVEN] Purchase Price List for "Job Task" 'JT', where "Allow Updating Defaults" is 'Yes' and one line
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTAsk(Job, JobTask);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"Job Task", Job."No.", JobTask."Job Task No.");
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::Job, Job."No.",
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Open Purch Job price list
        PurchPriceList.Trap();
        RunPurchPriceList("Price Source Group"::Job);
        PurchPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] "Assign-to Parent No." is visible in the header
        Assert.IsFalse(PurchPriceList.SourceType.Visible(), 'Header SourceType.Visible');
        Assert.IsTrue(PurchPriceList.JobSourceType.Visible(), 'Header JobSourceType.Visible');
        Assert.IsFalse(PurchPriceList.SourceNo.Visible(), 'Header SourceNo.Visible');
        Assert.IsTrue(PurchPriceList.AssignToParentNo.Visible(), 'Header AssignToParentNo.Visible');
        Assert.IsTrue(PurchPriceList.AssignToNo.Visible(), 'Header AssignToNo.Visible');
        // [THEN] "Assign-to Type", "Assign-to", "Currency Code",  "Starting/Ending Date", "Price Includes VAT" are visible and editable
        Assert.IsFalse(PurchPriceList.Lines.SourceType.Visible(), 'SourceType.Visible');
        Assert.IsTrue(PurchPriceList.Lines.JobSourceType.Visible(), 'JobSourceType.Visible');
        Assert.IsTrue(PurchPriceList.Lines.AssignToParentNo.Visible(), 'AssignToParentNo.Visible');
        Assert.IsTrue(PurchPriceList.Lines.AssignToNo.Visible(), 'AssignToNo.Visible');
        Assert.IsTrue(PurchPriceList.Lines.CurrencyCode.Visible(), 'CurrencyCode.Visible');
        Assert.IsTrue(PurchPriceList.Lines.StartingDate.Visible(), 'StartingDate.Visible');
        Assert.IsTrue(PurchPriceList.Lines.EndingDate.Visible(), 'EndingDate.Visible');
        Assert.IsTrue(PurchPriceList.Lines.PriceIncludesVAT.Visible(), 'PriceIncludesVAT.No');
        Assert.IsTrue(PurchPriceList.Lines.VATBusPostingGrPrice.Visible(), 'VATBusPostingGrPrice.No');
        Assert.IsTrue(PurchPriceList.Lines."Product No.".Visible(), '"Product No.".Visible');
        // [THEN] "Source No.", "Asset No." are invisible
        Assert.IsFalse(PurchPriceList.Lines.SourceNo.Visible(), 'SourceNo.Visible');
        Assert.IsFalse(PurchPriceList.Lines."Asset No.".Visible(), '"Asset No.".Visible');
    end;

    [Test]
    procedure T050_PurchasePriceListsPageIsNotEditable()
    var
        PriceListHeader: Record "Price List Header";
        PurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Vendors', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');

        // [WHEN] Open page "Purchase Price Lists" without filters
        PurchasePriceLists.Trap();
        Page.Run(Page::"Purchase Price Lists");

        // [THEN] The page is not editable, 
        Assert.IsFalse(PurchasePriceLists.Editable(), 'the page is editable');
        // [THEN] The columns are Description, Status, "Currency Code", "Source Type", "Source No.", "Starting Date", "Ending Date"
        Assert.IsTrue(PurchasePriceLists.Description.Visible(), 'Description is not visible');
        Assert.IsTrue(PurchasePriceLists.Status.Visible(), 'Status is not visible');
        Assert.IsTrue(PurchasePriceLists.SourceType.Visible(), 'SourceType is not visible');
        Assert.IsTrue(PurchasePriceLists.SourceNo.Visible(), 'SourceNo is not visible');
        Assert.IsTrue(PurchasePriceLists."Starting Date".Visible(), 'Starting Date is not visible');
        Assert.IsTrue(PurchasePriceLists."Ending Date".Visible(), 'Ending Date is not visible');
    end;

    [Test]
    procedure T051_PurchasePriceListsShowsAllVendors()
    var
        PriceListHeader: array[5] of Record "Price List Header";
        PurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows prices for "All Vendors" if open not from a Vendor.
        Initialize(true);

        // [GIVEN] Price List #1, where "Source Type" is 'Campaign' 'B', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::Campaign, '');
        // [GIVEN] Price List #2, where "Source Type" is 'All Vendors', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] Price List #3, where "Source Type" is 'Customer' 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::"Customer", '');
        // [GIVEN] Price List #4, where "Source Type" is 'Vendor' 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::"Vendor", '');
        // [GIVEN] Price List #5, where "Source Type" is 'All Jobs', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[5], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Purchase Price Lists" without filters
        PurchasePriceLists.Trap();
        Page.Run(Page::"Purchase Price Lists");

        // [THEN] There are 2 price lists with source types: "All Vendors" and "Vendor"
        Assert.IsTrue(PurchasePriceLists.First(), 'not found first');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        Assert.IsTrue(PurchasePriceLists.Next(), 'not found second');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        Assert.IsFalse(PurchasePriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T052_PurchasePriceListsPricesFromVendorsCard()
    var
        Vendor: array[2] of Record Vendor;
        PriceListHeader: array[4] of Record "Price List Header";
        VendorCard: TestPage "Vendor Card";
        PurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows prices for one Vendor open from the Vendor card.
        Initialize(true);
        // [GIVEN] Vendors 'A' and 'B'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Vendors'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Vendor' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Vendor Card for Vendor 'A'
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", Vendor[1]."No.");

        // [WHEN] Run action "Price Lists (Prices)"
        PurchasePriceLists.Trap();
        VendorCard.PriceLists.Invoke();

        // [THEN] There are 3 price lists - #1, #2, #4
        Assert.IsTrue(PurchasePriceLists.First(), 'not found first');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(PurchasePriceLists.Next(), 'not found second');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(PurchasePriceLists.Next(), 'not found third');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        Assert.IsFalse(PurchasePriceLists.Next(), 'found 4th');
    end;

    [Test]
    procedure T053_PurchasePriceListsDiscountsFromVendorsList()
    var
        Vendor: array[2] of Record Vendor;
        PriceListHeader: array[4] of Record "Price List Header";
        VendorList: TestPage "Vendor List";
        PurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows discounts for one Vendor open from the Vendor list.
        Initialize(true);
        // [GIVEN] Vendors 'A' and 'B'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Vendors', "Amount Type" is 'Price&Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        PriceListHeader[1].Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader[1].Modify();
        // [GIVEN] Price List #2, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Vendor' 'B', "Amount Type" is 'Price&Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[2]."No.");
        PriceListHeader[3].Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader[3].Modify();
        // [GIVEN] Price List #4, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Vendor List for Vendor 'A'
        VendorList.OpenEdit();
        VendorList.Filter.SetFilter("No.", Vendor[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        PurchasePriceLists.Trap();
        VendorList.PriceListsDiscounts.Invoke();

        // [THEN] There are 2 price lists - #1 and #2
        Assert.IsTrue(PurchasePriceLists.First(), 'not found first');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(PurchasePriceLists.Next(), 'not found second');
        PurchasePriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        PurchasePriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsFalse(PurchasePriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T054_PurchasePriceLinesFromVendorsCard()
    var
        Vendor: array[2] of Record Vendor;
        PriceListLine: array[4] of Record "Price List Line";
        VendorCard: TestPage "Vendor Card";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Purchase Price overview page shows price lines for one Vendor open from the Vendor card.
        Initialize(true);
        // [GIVEN] Vendors 'A' and 'B'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Vendors'
        // [GIVEN] Price List #2, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Price'
        // [GIVEN] Price List #3, where "Source Type" is 'Vendor' 'B'
        // [GIVEN] Price List #4, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Discount'
        CreatePurchPriceLinesForVendors(Vendor, PriceListLine);

        // [GIVEN] Open Vendor Card for Vendor 'A'
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", Vendor[1]."No.");

        // [WHEN] Run action "Purchase Prices"
        PriceListLineReview.Trap();
        VendorCard.PriceLines.Invoke();

        // [THEN] "Source Type", "Source No." are hidden, "Asset Type", "Asset No." are visible
        Assert.IsFalse(PriceListLineReview."Source Type".Visible(), 'Source Type.Visible');
        Assert.IsFalse(PriceListLineReview."Source No.".Visible(), 'Source No.Visible');
        Assert.IsTrue(PriceListLineReview."Asset Type".Visible(), 'Asset Type.Visible');
        Assert.IsTrue(PriceListLineReview."Asset No.".Visible(), 'Asset No.Visible');
        // [THEN] PriceListLineReview page open, where are 1 price line - #2, PriceListDescription is <blank>
        Assert.IsTrue(PriceListLineReview.First(), 'not found first price');
        PriceListLineReview."Price List Code".AssertEquals('002');
        PriceListLineReview.PriceListDescription.AssertEquals('');
        Assert.IsFalse(PriceListLineReview.Next(), 'found second price');
        PriceListLineReview.Close();
    end;

    [Test]
    procedure T055_PurchaseDiscountLinesFromVendorsList()
    var
        Vendor: array[2] of Record Vendor;
        PriceListLine: array[4] of Record "Price List Line";
        VendorList: TestPage "Vendor List";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Purchase Price overview page shows price lines for one Vendor open from the Vendor List.
        Initialize(true);
        // [GIVEN] Vendors 'A' and 'B'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Vendors'
        // [GIVEN] Price List #2, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Price'
        // [GIVEN] Price List #3, where "Source Type" is 'Vendor' 'B'
        // [GIVEN] Price List #4, where "Source Type" is 'Vendor' 'A', "Amount Type" is 'Discount'
        CreatePurchPriceLinesForVendors(Vendor, PriceListLine);

        // [GIVEN] Open Vendor Card for Vendor 'A'
        VendorList.OpenEdit();
        VendorList.Filter.SetFilter("No.", Vendor[1]."No.");

        // [WHEN] Run action "Purchase Discounts"
        PriceListLineReview.Trap();
        VendorList.DiscountLines.Invoke();

        // [THEN] PriceListLineReview page open, where are 1 discount line - #4
        Assert.IsTrue(PriceListLineReview.First(), 'not found first discount');
        PriceListLineReview."Price List Code".AssertEquals('004');
        Assert.IsFalse(PriceListLineReview.Next(), 'found second discount');
        PriceListLineReview.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T060_PurchStatusFromDraftToActive()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [SCENARIO] Purchase Price list page gets not editable (except Status control) if Status set to Active.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Draft'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PurchasePriceList.OpenEdit();
        PurchasePriceList.SourceType.AssertEquals("Price Source Type"::"All Vendors");
        Assert.IsFalse(PurchasePriceList.JobSourceType.Visible(), 'JobSourceType.Visible');
        // [GIVEN] Price list page open, where Status is 'Draft', all controls are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(PurchasePriceList);

        // [WHEN] Change Status to 'Active' (answer 'Yes' to confirmation)
        PurchasePriceList.Status.SetValue(PriceListHeader.Status::Active);

        // [THEN] All fields and lines part are not editable,
        VerifyAllControlsNotEditable(PurchasePriceList);
        // [GIVEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');
    end;

    [Test]
    procedure T061_PurchStatusFromInactiveToDraft()
    var
        PriceListHeader: Record "Price List Header";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [SCENARIO] Purchase Price list page gets editable if Status set to Draft.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] Price List, where Status is 'Inactive'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        PriceListHeader.Modify();
        PurchasePriceList.OpenEdit();
        // [GIVEN] Price list page open, where Status is Inactive, all controls are not editable 
        VerifyAllControlsNotEditable(PurchasePriceList);
        // [GIVEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');

        // [WHEN] Change Status to 'Draft'
        PurchasePriceList.Status.SetValue(PriceListHeader.Status::Draft);

        // [THEN] All fields and lines part are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(PurchasePriceList);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T062_PurchStatusFromDraftToActiveIfActiveIsEditable()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] Purchase Price list page gets editable if Status set to Active and "Allow Editing Active Price".
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Purchase
        LibraryPriceCalculation.AllowEditingActivePurchPrice();
        // [GIVEN] Price List, where Status is 'Draft'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        // [GIVEN] Price list page open, where Status is 'Draft', all controls are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');
        VerifyAllControlsEditable(PurchasePriceList);

        // [WHEN] Change Status to 'Active' (answer 'Yes' to confirmation)
        PurchasePriceList.Status.SetValue(PriceListHeader.Status::Active);

        // [THEN] All fields and lines part are editable,
        VerifyAllControlsEditable(PurchasePriceList);
        // [THEN] Controls "Status", "View Columns For" are editable
        Assert.IsTrue(PurchasePriceList.Status.Editable(), 'Active Status.not Editable');
        Assert.IsTrue(PurchasePriceList.AmountType.Editable(), 'AmountType.not Editable');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    procedure T063_NewLineAsDraftInActiveEditablePurchPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] New line added to the active (editable) price list gets status 'Draft', gets 'Active' by "Verify Lines" action.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Purchase
        LibraryPriceCalculation.AllowEditingActivePurchPrice();
        // [GIVEN] Price List, where Status is 'Active'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Add a new line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Cost" is 100
        ItemNo := LibraryInventory.CreateItemNo();
        PurchasePriceList.Lines.New();
        PurchasePriceList.Lines."Asset Type".AssertEquals("Price Asset Type"::"G/L Account"); // Taken from the previous line
        PurchasePriceList.Lines."Asset Type".SetValue('Item');
        PurchasePriceList.Lines."Asset No.".SetValue(ItemNo);
        PurchasePriceList.Lines."Unit Cost".SetValue(100);
        PurchasePriceList.Lines.First();

        // [THEN] New line, where Status is 'Draft'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", "Price Type"::Purchase);
        PriceListLine.TestField(Status, "Price Status"::Draft);

        // [WHEN] Run "Verify Lines" action
        PurchasePriceList.VerifyLines.Invoke();

        // [THEN] Message "All lines are verified"
        Assert.AreEqual(AllLinesVerifiedMsg, LibraryVariableStorage.DequeueText(), 'Wrong message');
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Both lines are 'Active'
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange(Status, "Price Status"::Active);
        Assert.RecordCount(PriceListLine, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,NotificationHandler,MessageHandler')]
    procedure T064_NewLineAsDraftOnClosingActiveEditablePurchPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] New line added to the active (editable) price list gets status 'Draft', gets 'Active' on page closing.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Purchase
        LibraryPriceCalculation.AllowEditingActivePurchPrice();
        // [GIVEN] Price List, where Status is 'Active'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Add a new line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Cost" is 100
        ItemNo := LibraryInventory.CreateItemNo();
        PurchasePriceList.Lines.New();
        PurchasePriceList.Lines."Asset Type".SetValue('Item');
        PurchasePriceList.Lines."Asset No.".SetValue(ItemNo);
        PurchasePriceList.Lines."Unit Cost".SetValue(100);
        PurchasePriceList.Lines.First();

        // [THEN] New line, where Status is 'Draft'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", "Price Type"::Purchase);
        PriceListLine.TestField(Status, "Price Status"::Draft);

        // [WHEN] Close the price list page
        PurchasePriceList.Close();
        // [WHEN] Notification appears, click "Verify Lines"
        Assert.AreEqual(PriceListHeader.Code, LibraryVariableStorage.DequeueText(), 'Header Code in notification');

        // [THEN] Message "All lines are verified"
        Assert.AreEqual(AllLinesVerifiedMsg, LibraryVariableStorage.DequeueText(), 'Wrong message');
        // [THEN] Both lines are 'Active'
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange(Status, "Price Status"::Active);
        Assert.RecordCount(PriceListLine, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,NotificationHandlerSkipMessage')]
    procedure NewLineAsDraftOnClosingActiveEditablePurchPriceListWithSkipMessage()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] New line added to the active (editable) price list gets status 'Draft', gets 'Active' on page closing.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Purchase
        LibraryPriceCalculation.AllowEditingActivePurchPrice();
        // [GIVEN] Price List, where Status is 'Active'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Add a new line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Cost" is 100
        ItemNo := LibraryInventory.CreateItemNo();
        PurchasePriceList.Lines.New();
        PurchasePriceList.Lines."Asset Type".SetValue('Item');
        PurchasePriceList.Lines."Asset No.".SetValue(ItemNo);
        PurchasePriceList.Lines."Unit Cost".SetValue(100);
        PurchasePriceList.Lines.First();

        // [THEN] New line, where Status is 'Draft'
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", "Price Type"::Purchase);
        PriceListLine.TestField(Status, "Price Status"::Draft);

        // [WHEN] Close the price list page
        PurchasePriceList.Close();
        // [WHEN] Notification appears, click "Verify Lines"
        Assert.AreEqual(PriceListHeader.Code, LibraryVariableStorage.DequeueText(), 'Header Code in notification');

        // [THEN] Both lines are 'Active'
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange(Status, "Price Status"::Active);
        Assert.RecordCount(PriceListLine, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,DuplicatePriceLinesModalHandler,MessageHandler')]
    procedure T065_NewDuplicateLineAsDraftOnVerifyLinesInActiveEditablePurchPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchasePriceList: TestPage "Purchase Price List";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO] New (duplicate) line added to the active (editable) price list needs resolution on "Verify Lines" action.
        Initialize(true);
        BindSubscription(PriceListsUI);
        // [GIVEN] "Allow Editing Active Price" is Yes for Purchase
        LibraryPriceCalculation.AllowEditingActivePurchPrice();
        // [GIVEN] Price List, where Status is 'Active'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        // [WHEN] Price line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Price" is 50
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, ItemNo);
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();

        // [GIVEN] Open price list card
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [GIVEN] Add a new (duplicate) line, where "Asset Type" is 'Item', "Asset No." is 'X', "Unit Cost" is 100
        PurchasePriceList.Lines.New();
        PurchasePriceList.Lines."Asset Type".SetValue('Item');
        PurchasePriceList.Lines."Asset No.".SetValue(ItemNo);
        PurchasePriceList.Lines."Unit Cost".SetValue(100);
        PurchasePriceList.Lines.First();

        // [GIVEN] Run "Verify Lines" action
        PurchasePriceList.VerifyLines.Invoke();

        // [WHEN] Opened page "Duplicate Price Lines", where mark first line for removal, and pushed OK (by DuplicatePriceLinesModalHandler)
        // [THEN] Second line is 'Active' and the only line in the price list
        PriceListLine.SetRange("Asset No.");
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange(Status, "Price Status"::Active);
        Assert.RecordCount(PriceListLine, 1);
        // [THEN] Message "All lines are verified"
        Assert.AreEqual(AllLinesVerifiedMsg, LibraryVariableStorage.DequeueText(), 'Wrong message');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T070_VendorCardPriceListsActionVisibleIfFeatureOn()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Vendor Card"
        VendorCard.OpenEdit();

        // [THEN] "Purchase Price Lists" action is visible, old actions are not visible
        Assert.IsTrue(VendorCard.PriceLists.Visible(), 'PriceLists. not Visible');
        Assert.IsFalse(VendorCard.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsFalse(VendorCard.Prices.Visible(), 'Prices. Visible');
        Assert.IsFalse(VendorCard."Line Discounts".Visible(), 'Line Discounts. Visible');
    end;

    [Test]
    procedure T071_VendorCardPriceListsActionNotVisibleIfFeatureOff()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Vendor Card"
        VendorCard.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(VendorCard.PriceLists.Visible(), 'PriceLists. Visible');
        Assert.IsFalse(VendorCard.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsTrue(VendorCard.Prices.Visible(), 'Prices. not Visible');
        Assert.IsTrue(VendorCard."Line Discounts".Visible(), 'Line Discounts. not Visible');
    end;

    [Test]
    procedure T072_VendorListPriceListsActionVisibleIfFeatureOn()
    var
        VendorList: TestPage "Vendor List";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Vendor List"
        VendorList.OpenEdit();

        // [THEN] "Purchase Price Lists" action is visible, old actions are not visible
        Assert.IsTrue(VendorList.PriceLists.Visible(), 'PriceLists. not Visible');
        Assert.IsFalse(VendorList.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsFalse(VendorList.Prices.Visible(), 'Prices_Prices. Visible');
        Assert.IsFalse(VendorList."Line Discounts".Visible(), 'Prices_LineDiscounts. Visible');
    end;

    [Test]
    procedure T073_VendorListPriceListsActionNotVisibleIfFeatureOff()
    var
        VendorList: TestPage "Vendor List";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Vendor List"
        VendorList.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(VendorList.PriceLists.Visible(), 'PriceLists. Visible');
        Assert.IsFalse(VendorList.PriceListsDiscounts.Visible(), 'PriceListsDiscounts. Visible');
        Assert.IsTrue(VendorList.Prices.Visible(), 'Prices. not Visible');
        Assert.IsTrue(VendorList."Line Discounts".Visible(), 'Line Discounts. not Visible');
    end;

    [Test]
    procedure T074_PurchPriceListsPageNotOpenIfFeatureOff()
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Purchase Price Lists" page
        asserterror Page.Run(Page::"Purchase Price Lists");
        Assert.ExpectedError(FeatureIsOffErr);
    end;

    [Test]
    procedure T075_PurchPriceListPageNotOpenIfFeatureOff()
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Purchase Price List" page
        asserterror Page.Run(Page::"Purchase Price List");
        Assert.ExpectedError(FeatureIsOffErr);
    end;

    [Test]
    procedure T076_PurchPriceListPageAllowDiscountsOn()
    var
        PurchPriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);
        // [GIVEN] New Purch price list, where AllowLineDisc and AllowInvoiceDisc are on
        PurchPriceList.OpenNew();
        Assert.IsTrue(PurchPriceList.Code.Editable(), 'Code.not Editable after OpenNew');
        PurchPriceList.AllowLineDisc.SetValue(true);
        Assert.IsFalse(PurchPriceList.Code.Editable(), 'Code.Editable after Insert');
        PurchPriceList.AllowInvoiceDisc.SetValue(true);

        // [WHEN] Add a new item line
        PurchPriceList.Lines.New();
        PurchPriceList.Lines."Asset Type".SetValue("Price Asset Type"::Item);

        // [THEN] AllowLineDisc and AllowInvoiceDisc are on in the line
        PurchPriceList.Lines."Allow Line Disc.".AssertEquals(true);
        PurchPriceList.Lines."Allow Invoice Disc.".AssertEquals(true);
    end;

    [Test]
    procedure T077_PurchPriceListPageAllowDiscountsOff()
    var
        PurchPriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);
        // [GIVEN] New Purch price list, where AllowLineDisc and AllowInvoiceDisc are off
        PurchPriceList.OpenNew();
        PurchPriceList.AllowLineDisc.SetValue(false);
        PurchPriceList.AllowInvoiceDisc.SetValue(false);

        // [WHEN] Add a new item line
        PurchPriceList.Lines.New();
        PurchPriceList.Lines."Asset Type".SetValue("Price Asset Type"::Item);

        // [THEN] AllowLineDisc and AllowInvoiceDisc are off in the line
        PurchPriceList.Lines."Allow Line Disc.".AssertEquals(false);
        PurchPriceList.Lines."Allow Invoice Disc.".AssertEquals(false);
    end;

    [Test]
    procedure T078_PurchPriceListPageNewLineWithDefaultAssetType()
    var
        PriceListLine: Record "Price List Line";
        PurchPriceList: TestPage "Purchase Price List";
    begin
        // [FEATURE] [Purchase]
        Initialize(true);
        // [GIVEN] New Purch price list
        PurchPriceList.OpenNew();

        // [WHEN] Add a new line, and "Asset No." as Item No.
        PurchPriceList.Lines.New();
        PurchPriceList.Lines."Asset No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] "Asset Type" is Item, "Price Type" is 'Purchase'
        PurchPriceList.Lines."Asset Type".AssertEquals("Price Asset Type"::Item);
        PriceListLine.SetRange("Price List Code", PurchPriceList.Code.Value());
        PriceListLine.FindLast();
        PriceListLine.TestField("Price Type", "Price Type"::Purchase);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Source No.", '');
    end;

    [Test]
    procedure T079_PurchJobPriceListPageNewLineWithDefaultAssetType()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchPriceList: TestPage "Purchase Price List";
    begin
        // [FEATURE] [Purchase] [Job]
        Initialize(true);
        // [GIVEN] New Purch price list from "Purchase Job Price Lists"
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Price Type", "Price Type"::Purchase);
        PriceListHeader.SetRange("Source Group", "Price Source Group"::Job);
        PriceListHeader.FilterGroup(1);
        PurchPriceList.Trap();
        Page.Run(Page::"Purchase Price List", PriceListHeader);
        PurchPriceList.New();

        // [WHEN] Add a new line, and "Asset No." as Item No.
        PurchPriceList.Lines.New();
        PurchPriceList.Lines."Asset No.".SetValue(LibraryInventory.CreateItemNo());

        // [THEN] "Asset Type" is Item, "Price Type" is 'Purchase'
        PurchPriceList.Lines."Asset Type".AssertEquals("Price Asset Type"::Item);
        PriceListLine.SetRange("Price List Code", PurchPriceList.Code.Value());
        PriceListLine.FindLast();
        PriceListLine.TestField("Price Type", "Price Type"::Purchase);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Jobs");
        PriceListLine.TestField("Source No.", '');
    end;

    [Test]
    procedure T080_SalesPriceListManualCode()
    var
        SalesPriceList: TestPage "Sales Price List";
        NewCode: Code[20];
    begin
        // [FEATURE] [Sales]
        Initialize(true);
        // [GIVEN] New Sales price list from "Sales Price Lists"
        SalesPriceList.Trap();
        RunSalesPriceList("Price Source Group"::Customer);
        SalesPriceList.New();
        Assert.IsTrue(SalesPriceList.Code.Editable(), 'Code.must be Editable');

        // [WHEN] Enter Code as 'X' manually
        NewCode := LibraryUtility.GenerateGUID();
        SalesPriceList.Code.SetValue(NewCode);

        // [THEN] Code is 'X', not editable
        SalesPriceList.Code.AssertEquals(NewCode);
        Assert.IsFalse(SalesPriceList.Code.Editable(), 'Code.must not be Editable');
    end;

    [Test]
    procedure T090_PurchPriceListManualCode()
    var
        PurchPriceList: TestPage "Purchase Price List";
        NewCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        Initialize(true);
        // [GIVEN] New Purch price list from "Purchase Price Lists"
        PurchPriceList.Trap();
        RunPurchPriceList("Price Source Group"::Vendor);
        PurchPriceList.New();
        Assert.IsTrue(PurchPriceList.Code.Editable(), 'Code.must be Editable');

        // [WHEN] Enter Code as 'X' manually
        NewCode := LibraryUtility.GenerateGUID();
        PurchPriceList.Code.SetValue(NewCode);

        // [THEN] Code is 'X', not editable
        PurchPriceList.Code.AssertEquals(NewCode);
        Assert.IsFalse(PurchPriceList.Code.Editable(), 'Code.must not be Editable');
    end;

    [Test]
    procedure T100_SalesJobPriceListsPageIsNotEditable()
    var
        PriceListHeader: Record "Price List Header";
        SalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Jobs', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Sales Job Price Lists" without filters
        SalesJobPriceLists.Trap();
        Page.Run(Page::"Sales Job Price Lists");

        // [THEN] The page is not editable, 
        Assert.IsFalse(SalesJobPriceLists.Editable(), 'the page is editable');
        // [THEN] The columns are Description, Status, "Currency Code", "Source Type", "Source No.", "Parent Source No.", "Starting Date", "Ending Date"
        Assert.IsTrue(SalesJobPriceLists.Description.Visible(), 'Description is not visible');
        Assert.IsTrue(SalesJobPriceLists.Status.Visible(), 'Status is not visible');
        Assert.IsTrue(SalesJobPriceLists.SourceType.Visible(), 'SourceType is not visible');
        Assert.IsTrue(SalesJobPriceLists.SourceNo.Visible(), 'SourceNo is not visible');
        Assert.IsTrue(SalesJobPriceLists.ParentSourceNo.Visible(), 'ParentSourceNo is not visible');
        Assert.IsTrue(SalesJobPriceLists."Starting Date".Visible(), 'Starting Date is not visible');
        Assert.IsTrue(SalesJobPriceLists."Ending Date".Visible(), 'Ending Date is not visible');
    end;

    [Test]
    procedure T101_SalesJobPriceListsShowsAllJobs()
    var
        PriceListHeader: array[5] of Record "Price List Header";
        SalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        // [SCENARIO] Sales Job Price lists page shows prices for "All Jobs" if open not from a Job.
        Initialize(true);

        // [GIVEN] Price List #1, where "Source Type" is 'Job Task' 'B' for Job 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"Job Task", '', '');
        // [GIVEN] Price List #2, where "Source Type" is 'All Jobs', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::"Job", '');
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::"Job", '');
        // [GIVEN] Price List #5, where "Source Type" is 'Customer', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"Customer", '');

        // [WHEN] Open page "Sales Price Lists" without filters
        SalesJobPriceLists.Trap();
        Page.Run(Page::"Sales Job Price Lists");

        // [THEN] There are 3 price lists with source types: "All Jobs", "Job", "Job Task" and "Amount Type" 'Sale'.
        Assert.IsTrue(SalesJobPriceLists.First(), 'not found first');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found second');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found third');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        Assert.IsFalse(SalesJobPriceLists.Next(), 'found fourth');
    end;

    [Test]
    procedure T102_SalesJobPriceListsPricesFromJobsCard()
    var
        Job: array[2] of Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: array[5] of Record "Price List Header";
        JobCard: TestPage "Job Card";
        SalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        // [SCENARIO] Sales Job Price lists page shows prices for one job open from the job card.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B', Job Task 'C' for Job 'A'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTAsk(Job[1], JobTask);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Job, Job[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[4].Modify();
        // [GIVEN] Price List #5, where "Source Type" is 'Job Task' 'C', Job 'A'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[5], "Price Type"::Sale, "Price Source Type"::"Job Task", Job[1]."No.", JobTask."Job Task No.");

        // [GIVEN] Open Job Card for Job 'A'
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Sales Price Lists (Prices)"
        SalesJobPriceLists.Trap();
        JobCard.SalesPriceLists.Invoke();

        // [THEN] There are 4 price lists - #1, #2, #4, #5
        Assert.IsTrue(SalesJobPriceLists.First(), 'not found first');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found second');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found third');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        SalesJobPriceLists.ParentSourceNo.AssertEquals('');
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found 4th');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[5]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[5]."Source No.");
        SalesJobPriceLists.ParentSourceNo.AssertEquals(Job[1]."No.");
        Assert.IsFalse(SalesJobPriceLists.Next(), 'found 5th');
    end;

    [Test]
    procedure T103_SalesJobPriceListsDiscountsFromJobsList()
    var
        Job: array[2] of Record Job;
        PriceListHeader: array[4] of Record "Price List Header";
        JobList: TestPage "Job List";
        SalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        // [SCENARIO] Sales Job Price lists page shows discounts for one job open from the job list.
        Initialize(true);
        // [GIVEN] Job 'A' and 'B'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs', "Amount Type" is 'Price&Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        PriceListHeader[1].Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader[1].Modify();
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B', "Amount Type" is 'Price&Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::Job, Job[2]."No.");
        PriceListHeader[3].Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader[3].Modify();
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Sale, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Job List for Job 'A'
        JobList.OpenEdit();
        JobList.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        SalesJobPriceLists.Trap();
        JobList.SalesPriceListsDiscounts.Invoke();

        // [THEN] There are 2 price lists - #1 and #2
        Assert.IsTrue(SalesJobPriceLists.First(), 'not found first');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(SalesJobPriceLists.Next(), 'not found second');
        SalesJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        SalesJobPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsFalse(SalesJobPriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T104_SalesJobPricesFromJobsCard()
    var
        Job: array[2] of Record Job;
        JobTask: Record "Job Task";
        PriceListLine: array[5] of Record "Price List Line";
        JobCard: TestPage "Job Card";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Sales Job Price line review page shows sales price list lines for one job open from the job card.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B', Job Task 'C' for Job 'A'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTAsk(Job[1], JobTask);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        // [GIVEN] Price List #5, where "Source Type" is 'Job Task' 'C', Job 'A'
        CreateSalesPriceLinesForJobs(Job, JobTask, PriceListLine, "Price Amount Type"::Price);

        // [GIVEN] Open Job Card for Job 'A'
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Sales Prices"
        PriceListLineReview.Trap();
        JobCard.SalesPriceLines.Invoke();

        // [THEN] There are 2 price lines - #2, #5
        Assert.IsTrue(PriceListLineReview.First(), 'not found first');
        PriceListLineReview."Price List Code".AssertEquals('002');
        Assert.IsTrue(PriceListLineReview.Next(), 'not found 2th');
        PriceListLineReview."Price List Code".AssertEquals('005');
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd');
    end;

    [Test]
    procedure T105_SalesJobDiscountsFromJobsList()
    var
        Job: array[2] of Record Job;
        JobTask: Record "Job Task";
        PriceListLine: array[5] of Record "Price List Line";
        JobList: TestPage "Job List";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Sales Job Price line review page shows sales price list lines for one job open from the job List.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B', Job Task 'C' for Job 'A'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTAsk(Job[1], JobTask);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        // [GIVEN] Price List #5, where "Source Type" is 'Job Task' 'C', Job 'A', "Amount Type" is 'Discount'
        CreateSalesPriceLinesForJobs(Job, JobTask, PriceListLine, "Price Amount Type"::Discount);

        // [GIVEN] Open Job List for Job 'A'
        JobList.OpenEdit();
        JobList.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Sales Discounts"
        PriceListLineReview.Trap();
        JobList.SalesDiscountLines.Invoke();

        // [THEN] There are 2 price lines - #4, #5
        Assert.IsTrue(PriceListLineReview.First(), 'not found first');
        PriceListLineReview."Price List Code".AssertEquals('004');
        Assert.IsTrue(PriceListLineReview.Next(), 'not found 2th');
        PriceListLineReview."Price List Code".AssertEquals('005');
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd');
    end;

    [Test]
    procedure T106_SalesJobPriceListPageShowsSourceType()
    var
        PriceListHeader: Record "Price List Header";
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Jobs', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Sales Job Price List" 
        SalesPriceList.Trap();
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Price Type", "Price Type"::Sale);
        PriceListHeader.SetRange("Source Group", "Price Source Group"::Job);
        PriceListHeader.FilterGroup(0);
        Page.Run(Page::"Sales Price List", PriceListHeader);

        // [THEN] SourceType is 'All Jobs' 
        Assert.IsFalse(SalesPriceList.SourceType.Visible(), 'SourceType.Visible');
        SalesPriceList.JobSourceType.AssertEquals("Price Source Type"::"All Jobs");
    end;

    [Test]
    procedure T107_SalesPriceListPageKeepsChangedAmountType()
    var
        SalesPriceList: TestPage "Sales Price List";
    begin
        Initialize(true);

        // [GIVEN] new Sales Price list for 'All Customers', where "Amount Type" is 'Price'
        SalesPriceList.OpenNew();
        SalesPriceList.SourceType.SetValue("Price Source Type"::"All Customers");
        SalesPriceList.AmountType.SetValue("Price Amount Type"::Price);

        // [WHEN] Change "Starting Date" to '010122'
        SalesPriceList.StartingDate.SetValue(WorkDate() + 1);

        // [THEN] "Amount Type" is 'Price'
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Price);
    end;

    [Test]
    procedure T120_JobCardPriceListsActionVisibleIfFeatureOn()
    var
        JobCard: TestPage "Job Card";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Job Card"
        JobCard.OpenEdit();

        // [THEN] "Sales/Purchase Price Lists" actions are visible, old actions are not visible
        Assert.IsTrue(JobCard.SalesPriceLists.Visible(), 'S.PriceLists. not Visible');
        Assert.IsTrue(JobCard.PurchasePriceLists.Visible(), 'P.PriceLists. not Visible');
        Assert.IsFalse(JobCard.SalesPriceListsDiscounts.Visible(), 'S.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobCard.PurchasePriceListsDiscounts.Visible(), 'P.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobCard."&Resource".Visible(), '"&Resource". Visible');
        Assert.IsFalse(JobCard."&Item".Visible(), '"&Item". Visible');
        Assert.IsFalse(JobCard."&G/L Account".Visible(), '"&G/L Account". Visible');
    end;

    [Test]
    procedure T121_JobCardPriceListsActionNotVisibleIfFeatureOff()
    var
        JobCard: TestPage "Job Card";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Job Card"
        JobCard.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(JobCard.SalesPriceLists.Visible(), 'S.PriceLists. Visible');
        Assert.IsFalse(JobCard.SalesPriceListsDiscounts.Visible(), 'S.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobCard.PurchasePriceLists.Visible(), 'P.PriceLists. Visible');
        Assert.IsFalse(JobCard.PurchasePriceListsDiscounts.Visible(), 'P.PriceListsDiscounts. Visible');
        Assert.IsTrue(JobCard."&Resource".Visible(), '"&Resource". not Visible');
        Assert.IsTrue(JobCard."&Item".Visible(), '"&Item". not Visible');
        Assert.IsTrue(JobCard."&G/L Account".Visible(), '"&G/L Account". not Visible');
    end;

    [Test]
    procedure T122_JobListPriceListsActionVisibleIfFeatureOn()
    var
        JobList: TestPage "Job List";
    begin
        Initialize(true);
        // [GIVEN] Feature is On

        // [WHEN] Open "Job List"
        JobList.OpenEdit();

        // [THEN] "Sales/Purchase Price Lists" actions are visible, old actions are not visible
        Assert.IsTrue(JobList.SalesPriceLists.Visible(), 'S.PriceLists. not Visible');
        Assert.IsTrue(JobList.PurchasePriceLists.Visible(), 'P.PriceLists. not Visible');
        Assert.IsFalse(JobList.SalesPriceListsDiscounts.Visible(), 'S.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobList.PurchasePriceListsDiscounts.Visible(), 'P.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobList."&Resource".Visible(), '"&Resource". Visible');
        Assert.IsFalse(JobList."&Item".Visible(), '"&Item". Visible');
        Assert.IsFalse(JobList."&G/L Account".Visible(), '"&G/L Account". Visible');
    end;

    [Test]
    procedure T123_JobListPriceListsActionNotVisibleIfFeatureOff()
    var
        JobList: TestPage "Job List";
    begin
        Initialize(false);
        // [GIVEN] Feature is Off

        // [WHEN] Open "Job List"
        JobList.OpenEdit();

        // [THEN] "Price Lists" actions are not visible, old actions are visible
        Assert.IsFalse(JobList.SalesPriceLists.Visible(), 'S.PriceLists. Visible');
        Assert.IsFalse(JobList.SalesPriceListsDiscounts.Visible(), 'S.PriceListsDiscounts. Visible');
        Assert.IsFalse(JobList.PurchasePriceLists.Visible(), 'P.PriceLists. Visible');
        Assert.IsFalse(JobList.PurchasePriceListsDiscounts.Visible(), 'P.PriceListsDiscounts. Visible');
        Assert.IsTrue(JobList."&Resource".Visible(), '"&Resource". not Visible');
        Assert.IsTrue(JobList."&Item".Visible(), '"&Item". not Visible');
        Assert.IsTrue(JobList."&G/L Account".Visible(), '"&G/L Account". not Visible');
    end;

    [Test]
    procedure T124_JobCardFactBoxPricesIfFeatureOn()
    var
        Job: Record Job;
        PriceListLine: array[3] of Record "Price List Line";
        JobCard: TestPage "Job Card";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        Initialize(true);
        // [GIVEN] Feature is On
        // [GIVEN] Job 'J' with price list lines for Item, G/L Account, Resource
        LibraryJob.CreateJob(Job);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::Job, Job."No.", "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListLine[1].Status := PriceListLine[1].Status::Active;
        PriceListLine[1].Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], '', "Price Source Type"::Job, Job."No.", "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[2].Status := PriceListLine[1].Status::Active;
        PriceListLine[2].Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], '', "Price Source Type"::Job, Job."No.", "Price Asset Type"::Resource, LibraryResource.CreateResourceNo());
        PriceListLine[3].Status := PriceListLine[1].Status::Active;
        PriceListLine[3].Modify();

        // [WHEN] Open "Job List"
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job."No.");

        // [THEN] NoOfAccPrices, NoOfItemsPrices, NoOfResPrices are all 1
        Jobcard.Control1902136407.NoOfAccPrices.AssertEquals(1);
        Jobcard.Control1902136407.NoOfItemsPrices.AssertEquals(1);
        Jobcard.Control1902136407.NoOfResPrices.AssertEquals(1);

        // [WHEN] Drill down NoOfAccPrices
        PriceListLineReview.Trap();
        Jobcard.Control1902136407.NoOfAccPrices.Drilldown();

        // [THEN] Open list with the price line for resource
        Assert.Istrue(PriceListLineReview.First(), 'not found the first G/l acc line');
        PriceListLineReview."Asset No.".AssertEquals(PriceListLine[1]."Asset No.");

        // [WHEN] Drill down NoOfItemsPrices
        PriceListLineReview.Trap();
        Jobcard.Control1902136407.NoOfItemsPrices.Drilldown();

        // [THEN] Open list with the price line for resource
        Assert.Istrue(PriceListLineReview.First(), 'not found the first Item line');
        PriceListLineReview."Asset No.".AssertEquals(PriceListLine[2]."Asset No.");
        // [WHEN] Drill down NoOfResPrices
        PriceListLineReview.Trap();
        Jobcard.Control1902136407.NoOfResPrices.Drilldown();

        // [THEN] Open list with the price line for resource
        Assert.Istrue(PriceListLineReview.First(), 'not found the first Resource line');
        PriceListLineReview."Asset No.".AssertEquals(PriceListLine[3]."Asset No.");
    end;

    [Test]
    procedure T125_ResourceListFactBoxPricesIfFeatureOn()
    var
        Resource: Record Resource;
        PriceListLine: array[3] of Record "Price List Line";
        ResourceList: TestPage "Resource List";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        Initialize(true);
        // [GIVEN] Feature is On
        // [GIVEN] Resource 'R' with 2 price list lines for sales and 1 for purchase:
        LibraryResource.CreateResource(Resource, '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Jobs", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine[1].Status := PriceListLine[1].Status::Active;
        PriceListLine[1].Modify();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine[2].Status := PriceListLine[1].Status::Active;
        PriceListLine[2].Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[3], '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine[3].Status := PriceListLine[1].Status::Active;
        PriceListLine[3].Modify();

        // [WHEN] Open "Resource List"
        ResourceList.OpenView();
        ResourceList.Filter.SetFilter("No.", Resource."No.");

        // [THEN] NoOfResCosts is 1, NoOfResPrices is 2
        ResourceList.Control1907012907.NoOfResPrices.AssertEquals(2);
        ResourceList.Control1907012907.NoOfResCosts.AssertEquals(1);

        // [WHEN] Drill down NoOfResPrices
        PriceListLineReview.Trap();
        ResourceList.Control1907012907.NoOfResPrices.Drilldown();

        // [THEN] Open list with the sale price lines for resource
        Assert.Istrue(PriceListLineReview.First(), 'not found the first sales price line');
        PriceListLineReview."Source Type".AssertEquals(PriceListLine[1]."Source Type");
        PriceListLineReview."Unit Price".AssertEquals(PriceListLine[1]."Unit Price");
        Assert.Istrue(PriceListLineReview.Next(), 'not found the second sales price line');
        PriceListLineReview."Source Type".AssertEquals(PriceListLine[2]."Source Type");
        PriceListLineReview."Unit Price".AssertEquals(PriceListLine[2]."Unit Price");

        // [WHEN] Drill down NoOfResCosts
        PriceListLineReview.Trap();
        ResourceList.Control1907012907.NoOfResCosts.Drilldown();

        // [THEN] Open list with the purchase price line for resource
        Assert.Istrue(PriceListLineReview.First(), 'not found the first purch price line');
        PriceListLineReview."Source Type".AssertEquals(PriceListLine[3]."Source Type");
        PriceListLineReview.DirectUnitCost.AssertEquals(PriceListLine[3]."Direct Unit Cost");
    end;

    [Test]
    procedure T150_PurchaseJobPriceListsPageIsNotEditable()
    var
        PriceListHeader: Record "Price List Header";
        PurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Jobs', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Purchase Job Price Lists" without filters
        PurchaseJobPriceLists.Trap();
        Page.Run(Page::"Purchase Job Price Lists");

        // [THEN] The page is not editable, 
        Assert.IsFalse(PurchaseJobPriceLists.Editable(), 'the page is editable');
        // [THEN] The columns are Description, Status, "Currency Code", "Source Type", "Source No.", "Parent Source No.","Starting Date", "Ending Date"
        Assert.IsTrue(PurchaseJobPriceLists.Description.Visible(), 'Description is not visible');
        Assert.IsTrue(PurchaseJobPriceLists.Status.Visible(), 'Status is not visible');
        Assert.IsTrue(PurchaseJobPriceLists.SourceType.Visible(), 'SourceType is not visible');
        Assert.IsTrue(PurchaseJobPriceLists.SourceNo.Visible(), 'SourceNo is not visible');
        Assert.IsTrue(PurchaseJobPriceLists.ParentSourceNo.Visible(), 'ParentSourceNo is not visible');
        Assert.IsTrue(PurchaseJobPriceLists."Starting Date".Visible(), 'Starting Date is not visible');
        Assert.IsTrue(PurchaseJobPriceLists."Ending Date".Visible(), 'Ending Date is not visible');
    end;

    [Test]
    procedure T151_PurchaseJobPriceListsShowsAllJobs()
    var
        PriceListHeader: array[5] of Record "Price List Header";
        PurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        // [SCENARIO] Purchase Job Price lists page shows prices for "All Jobs" if open not from a Job.
        Initialize(true);

        // [GIVEN] Price List #1, where "Source Type" is 'Job Task' 'B' for Job 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"Job Task", '', '');
        // [GIVEN] Price List #2, where "Source Type" is 'All Jobs', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'A', "Price Type" is 'Sale'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Sale, "Price Source Type"::"Job", '');
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::"Job", '');
        // [GIVEN] Price List #5, where "Source Type" is 'Vendor', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[5], "Price Type"::Purchase, "Price Source Type"::"Vendor", '');

        // [WHEN] Open page "Purchase Job Price Lists" without filters
        PurchaseJobPriceLists.Trap();
        Page.Run(Page::"Purchase Job Price Lists");

        // [THEN] There are 3 price lists with source types: "All Jobs", "Job", "Job Task" and "Amount Type" 'Sale'.
        Assert.IsTrue(PurchaseJobPriceLists.First(), 'not found first');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found second');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found third');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        Assert.IsFalse(PurchaseJobPriceLists.Next(), 'found fourth');
    end;

    [Test]
    procedure T152_PurchaseJobPriceListsPricesFromJobCard()
    var
        Job: array[2] of Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: array[5] of Record "Price List Header";
        JobCard: TestPage "Job Card";
        PurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows prices for one Job open from the Job card.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B', Job  Task 'C' for Job 'A'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTask(Job[1], JobTask);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::Job, Job[2]."No.");
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[4].Modify();
        // [GIVEN] Price List #5, where "Source Type" is 'Job Task' 'C', 'Job' 'A'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[5], "Price Type"::Purchase, "Price Source Type"::"Job Task", Job[1]."No.", JobTask."Job Task No.");

        // [GIVEN] Open Job Card for Job 'A'
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Price Lists (Prices)"
        PurchaseJobPriceLists.Trap();
        JobCard.PurchasePriceLists.Invoke();

        // [THEN] There are 4 price lists - #1, #2, #4, #5
        Assert.IsTrue(PurchaseJobPriceLists.First(), 'not found first');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found second');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found third');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[4]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[4]."Source No.");
        PurchaseJobPriceLists.ParentSourceNo.AssertEquals('');
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found 4th');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[5]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[5]."Source No.");
        PurchaseJobPriceLists.ParentSourceNo.AssertEquals(Job[1]."No.");
        Assert.IsFalse(PurchaseJobPriceLists.Next(), 'found 5th');
    end;

    [Test]
    procedure T153_PurchaseJobPriceListsDiscountsFromJobList()
    var
        Job: array[2] of Record Job;
        PriceListHeader: array[4] of Record "Price List Header";
        JobList: TestPage "Job List";
        PurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        // [SCENARIO] Purchase Price lists page shows discounts for one Job open from the Job list.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs', "Amount Type" is 'Price&Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        PriceListHeader[1].Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader[1].Modify();
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[2]."Amount Type" := PriceListHeader[4]."Amount Type"::Discount;
        PriceListHeader[2].Modify();
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B', "Amount Type" is 'Price&Discount'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::Job, Job[2]."No.");
        PriceListHeader[3].Validate("Amount Type", "Price Amount Type"::Any);
        PriceListHeader[3].Modify();
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[4], "Price Type"::Purchase, "Price Source Type"::Job, Job[1]."No.");
        PriceListHeader[4]."Amount Type" := PriceListHeader[4]."Amount Type"::Price;
        PriceListHeader[4].Modify();

        // [GIVEN] Open Job List for Job 'A'
        JobList.OpenEdit();
        JobList.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Price Lists (Discounts)"
        PurchaseJobPriceLists.Trap();
        JobList.PurchasePriceListsDiscounts.Invoke();

        // [THEN] There are 2 price lists - #1 and #2
        Assert.IsTrue(PurchaseJobPriceLists.First(), 'not found first');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[1]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[1]."Source No.");
        Assert.IsTrue(PurchaseJobPriceLists.Next(), 'not found second');
        PurchaseJobPriceLists.SourceType.AssertEquals(PriceListHeader[2]."Source Type");
        PurchaseJobPriceLists.SourceNo.AssertEquals(PriceListHeader[2]."Source No.");
        Assert.IsFalse(PurchaseJobPriceLists.Next(), 'found third');
    end;

    [Test]
    procedure T154_PurchaseJobPricesFromJobsCard()
    var
        Job: array[2] of Record Job;
        JobTask: Record "Job Task";
        PriceListLine: array[5] of Record "Price List Line";
        JobCard: TestPage "Job Card";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Purchase Job Price line review page shows sales price list lines for one job open from the job card.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B', Job Task 'C' for Job 'A'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTAsk(Job[1], JobTask);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        // [GIVEN] Price List #5, where "Source Type" is 'Job Task' 'C', Job 'A'
        CreatePurchPriceLinesForJobs(Job, JobTask, PriceListLine, "Price Amount Type"::Price);

        // [GIVEN] Open Job Card for Job 'A'
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Purchase Prices"
        PriceListLineReview.Trap();
        JobCard.PurchPriceLines.Invoke();

        // [THEN] There are 2 price lines - #2, #5
        Assert.IsTrue(PriceListLineReview.First(), 'not found first');
        PriceListLineReview."Price List Code".AssertEquals('002');
        Assert.IsTrue(PriceListLineReview.Next(), 'not found 2th');
        PriceListLineReview."Price List Code".AssertEquals('005');
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd');
    end;

    [Test]
    procedure T155_PurchaseJobDiscountsFromJobsList()
    var
        Job: array[2] of Record Job;
        JobTask: Record "Job Task";
        PriceListLine: array[5] of Record "Price List Line";
        JobList: TestPage "Job List";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Purchase Job Price line review page shows sales price list lines for one job open from the job List.
        Initialize(true);
        // [GIVEN] Jobs 'A' and 'B', Job Task 'C' for Job 'A'
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTAsk(Job[1], JobTask);
        LibraryJob.CreateJob(Job[2]);

        // [GIVEN] Price List #1, where "Source Type" is 'All Jobs'
        // [GIVEN] Price List #2, where "Source Type" is 'Job' 'A', "Amount Type" is 'Price'
        // [GIVEN] Price List #3, where "Source Type" is 'Job' 'B'
        // [GIVEN] Price List #4, where "Source Type" is 'Job' 'A', "Amount Type" is 'Discount'
        // [GIVEN] Price List #5, where "Source Type" is 'Job Task' 'C', Job 'A'
        CreatePurchPriceLinesForJobs(Job, JobTask, PriceListLine, "Price Amount Type"::Discount);

        // [GIVEN] Open Job List for Job 'A'
        JobList.OpenEdit();
        JobList.Filter.SetFilter("No.", Job[1]."No.");

        // [WHEN] Run action "Purchase Discounts"
        PriceListLineReview.Trap();
        JobList.PurchDiscountLines.Invoke();

        // [THEN] There are 2 price lines - #4, #5
        Assert.IsTrue(PriceListLineReview.First(), 'not found first');
        PriceListLineReview."Price List Code".AssertEquals('004');
        Assert.IsTrue(PriceListLineReview.Next(), 'not found 2th');
        PriceListLineReview."Price List Code".AssertEquals('005');
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd');
    end;

    [Test]
    procedure T156_PurchJobPriceListPageShowsSourceType()
    var
        PriceListHeader: Record "Price List Header";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);

        // [GIVEN] Price List, where "Source Type" is 'All Jobs', "Price Type" is 'Purchase'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');

        // [WHEN] Open page "Purchase Job Price List" 
        PurchasePriceList.Trap();
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Price Type", "Price Type"::Purchase);
        PriceListHeader.SetRange("Source Group", "Price Source Group"::Job);
        PriceListHeader.FilterGroup(0);
        Page.Run(Page::"Purchase Price List", PriceListHeader);

        // [THEN] SourceType is 'All Jobs' 
        Assert.IsFalse(PurchasePriceList.SourceType.Visible(), 'SourceType.Visible');
        PurchasePriceList.JobSourceType.AssertEquals("Price Source Type"::"All Jobs");
    end;

    [Test]
    procedure T157_PurchPriceListPageKeepsChangedAmountType()
    var
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        Initialize(true);

        // [GIVEN] new Sales Price list for 'All Vendors', where "Amount Type" is 'Discount'
        PurchasePriceList.OpenNew();
        PurchasePriceList.SourceType.SetValue("Price Source Type"::"All Vendors");
        PurchasePriceList.AmountType.SetValue("Price Amount Type"::Discount);

        // [WHEN] Change "Starting Date" to '010122'
        PurchasePriceList.StartingDate.SetValue(WorkDate() + 1);

        // [THEN] "Amount Type" is 'Discount'
        PurchasePriceList.AmountType.AssertEquals("Price Amount Type"::Discount);
    end;

    [Test]
    procedure T170_ShowPriceListLinesForItemWithDiscGroup()
    var
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
        ItemDiscGroupPriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item]
        // [SCENARIO 381378] Open price line review for the item, where "No." contains brackets, "Item Disc. Group" is defined.
        Initialize(true);
        // [GIVEN] Item 'X(1)', where "Item Disc. Group" is 'A'
        LibraryInventory.CreateItem(Item);
        Item.Rename(Item."No." + '(1)');
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        Item.Modify();
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::Item, Item."No.");
        // [GIVEN] 2 sales discount lines for "Item Disc. Group" 'A'
        CreatePriceLines(ItemDiscGroupPriceListLine, "Price Asset Type"::"Item Discount Group", Item."Item Disc. Group");

        // [WHEN] Show sales prices&discounts for Item 'X'
        PriceListLineReview.Trap();
        Item.ShowPriceListLines("Price Type"::Sale, "Price Amount Type"::Any);

        // [THEN] Open Price List Line Review page, where "Asset Type", "Asset No.", Description are visible
        Assert.IsTrue(PriceListLineReview."Asset Type".Visible(), 'Asset Type.Visible');
        Assert.IsTrue(PriceListLineReview."Asset No.".Visible(), 'Asset No.Visible');
        Assert.IsTrue(PriceListLineReview.Description.Visible(), 'Description.Visible');
        // [THEN] and where are 6 lines #1-#6 for Item and 2 for Item Disc.Group (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[3]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[5]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(ItemDiscGroupPriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[4]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[6]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(ItemDiscGroupPriceListLine[2]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 9th line');
    end;

    [Test]
    procedure T171_ShowPriceListLinesForItemDiscGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Discount Group]
        Initialize(true);
        // [GIVEN] ItemDiscountGroup 'X'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        // [GIVEN] 2 sales discount lines for "Item Disc. Group" 'A'
        CreatePriceLines(PriceListLine, "Price Asset Type"::"Item Discount Group", ItemDiscountGroup.Code);

        // [WHEN] Show sales discounts for ItemDiscountGroup 'X'
        PriceListLineReview.Trap();
        ItemDiscountGroup.ShowPriceListLines("Price Type"::Sale, "Price Amount Type"::Discount);

        // [THEN] Open Price List Line Review page, where "Asset Type", "Asset No.", Description are not visible
        Assert.IsFalse(PriceListLineReview."Asset Type".Visible(), 'Asset Type.Visible');
        Assert.IsFalse(PriceListLineReview."Asset No.".Visible(), 'Asset No.Visible');
        Assert.IsFalse(PriceListLineReview.Description.Visible(), 'Description.Visible');
        // [THEN] and where are 2 sales discount lines (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd line');
    end;

    [Test]
    procedure T172_ShowPriceListLinesForServiceCost()
    var
        ServiceCost: Record "Service Cost";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Service Cost]
        Initialize(true);
        // [GIVEN] ServiceCost 'X'
        LibraryService.CreateServiceCost(ServiceCost);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::"Service Cost", ServiceCost.Code);

        // [WHEN] Show sales prices for ServiceCost 'X'
        PriceListLineReview.Trap();
        ServiceCost.ShowPriceListLines("Price Type"::Sale, "Price Amount Type"::Price);

        // [THEN] Open Price List Line Review page, where are 4 sales price lines #1-4 (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[3]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[4]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 5th line');
    end;

    [Test]
    procedure T173_ShowPriceListLinesForResource()
    var
        Resource: Record Resource;
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Resource]
        Initialize(true);
        // [GIVEN] Resource 'X'
        LibraryResource.CreateResource(Resource, '');
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::Resource, Resource."No.");

        // [WHEN] Show purchase prices for Resource 'X'
        PriceListLineReview.Trap();
        Resource.ShowPriceListLines("Price Type"::Purchase, "Price Amount Type"::Price);

        // [THEN] Open Price List Line Review page, where are 4 purchase price lines #7-10 (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[9]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[10]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 5th line');
    end;

    [Test]
    procedure T174_ShowPriceListLinesForResourceGroup()
    var
        ResourceGroup: Record "Resource Group";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Resource Group]
        Initialize(true);
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [WHEN] Show purchase discounts for Resource 'X'
        PriceListLineReview.Trap();
        ResourceGroup.ShowPriceListLines("Price Type"::Purchase, "Price Amount Type"::Discount);

        // [THEN] Open Price List Line Review page, where are 4 purchase discount lines #7,8,11,12 (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[11]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[12]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 5th line');
    end;

    [Test]
    procedure T175_ShowPriceListLinesForGLAcount()
    var
        GLAccount: Record "G/L Account";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [G/L Account]
        Initialize(true);
        // [GIVEN] GLAccount 'X'
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Any/Price/Discount, Customer/Vendor/Job
        CreatePriceLines(PriceListLine, "Price Asset Type"::"G/L Account", GLAccount."No.");

        // [WHEN] Show purchase prices&discounts for GLAccount 'X'
        PriceListLineReview.Trap();
        GLAccount.ShowPriceListLines("Price Type"::Purchase, "Price Amount Type"::Any);

        // [THEN] Open Price List Line Review page, where are 6 purchase lines #7-#12 (sorted by Code)
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[9]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[11]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[10]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[12]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 7th line');
    end;

    [Test]
    procedure T180_ShowPriceListLinesPriceForItemVendor()
    var
        ItemVendor: Record "Item Vendor";
        VendorItemCatalog: TestPage "Vendor Item Catalog";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Vendor]
        Initialize(true);
        // [GIVEN] Item Vendor 'I'-'V', where Item 'I', Vendor 'V'
        CreateItemVendor(ItemVendor, false);
        // [GIVEN] 6 Price list lines: combinations of Sales/Purchase, Price/Discount, Customer/Vendor
        CreatePriceLines(PriceListLine, ItemVendor);

        // [GIVEN] Open "Vendor Item Catalog" on record 'I'-'V'
        VendorItemCatalog.OpenView();
        VendorItemCatalog.Filter.SetFilter("Item No.", ItemVendor."Item No.");

        // [WHEN] Show purchase prices for 'I'-'V'
        PriceListLineReview.Trap();
        VendorItemCatalog.Prices.Invoke();

        // [THEN] Open Price List Line Review page, where are two purchase lines #1, #7
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[1]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd line');
    end;

    [Test]
    procedure T181_ShowPriceListLinesDiscountForItemVendor()
    var
        ItemVendor: Record "Item Vendor";
        ItemVendorCatalog: TestPage "Item Vendor Catalog";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Vendor]
        Initialize(true);
        // [GIVEN] Item Vendor 'I'-'V', where Item 'I', Vendor 'V'
        CreateItemVendor(ItemVendor, false);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Price/Discount, Customer/Vendor
        CreatePriceLines(PriceListLine, ItemVendor);

        // [GIVEN] Open "Item Vendor Catalog" on record 'I'-'V'
        ItemVendorCatalog.OpenView();
        ItemVendorCatalog.Filter.SetFilter("Item No.", ItemVendor."Item No.");

        // [WHEN] Show purchase prices for 'I'-'V'
        PriceListLineReview.Trap();
        ItemVendorCatalog.Discounts.Invoke();

        // [THEN] Open Price List Line Review page, where are 2 purchase lines #2, #8
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[2]."Price List Code");
        PriceListLineReview.Next();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd line');
    end;

    [Test]
    procedure T182_ShowPriceListLinesPriceForItemVariantVendor()
    var
        ItemVendor: Record "Item Vendor";
        ItemVendorCatalog: TestPage "Item Vendor Catalog";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Vendor]
        Initialize(true);
        // [GIVEN] Item Vendor 'I'-'V', where Item 'I', Vendor 'V', "Variant Code" 'VC'
        CreateItemVendor(ItemVendor, true);
        // [GIVEN] 6 Price list lines: combinations of Sales/Purchase, Price/Discount, Customer/Vendor
        CreatePriceLines(PriceListLine, ItemVendor);

        // [GIVEN] Open "Item Vendor Catalog" on record 'I'-'V'
        ItemVendorCatalog.OpenView();
        ItemVendorCatalog.Filter.SetFilter("Item No.", ItemVendor."Item No.");

        // [WHEN] Show purchase prices for 'I'-'V'
        PriceListLineReview.Trap();
        ItemVendorCatalog.Prices.Invoke();

        // [THEN] Open Price List Line Review page, where is one purchase line #7
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[7]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 2nd line');
    end;

    [Test]
    procedure T183_ShowPriceListLinesDiscountForItemVariantVendor()
    var
        ItemVendor: Record "Item Vendor";
        VendorItemCatalog: TestPage "Vendor Item Catalog";
        PriceListLineReview: TestPage "Price List Line Review";
        PriceListLine: array[12] of Record "Price List Line";
    begin
        // [FEATURE] [Price Asset] [Item Vendor]
        Initialize(true);
        // [GIVEN] Item Vendor 'I'-'V', where Item 'I', Vendor 'V', "Variant Code" 'VC'
        CreateItemVendor(ItemVendor, true);
        // [GIVEN] 12 Price list lines: combinations of Sales/Purchase, Price/Discount, Customer/Vendor
        CreatePriceLines(PriceListLine, ItemVendor);

        // [GIVEN] Open "Vendor Item Catalog" on record 'I'-'V'
        VendorItemCatalog.OpenView();
        VendorItemCatalog.Filter.SetFilter("Item No.", ItemVendor."Item No.");

        // [WHEN] Show purchase prices for 'I'-'V'
        PriceListLineReview.Trap();
        VendorItemCatalog.Discounts.Invoke();

        // [THEN] Open Price List Line Review page, where is one purchase line #8
        PriceListLineReview.First();
        PriceListLineReview."Price List Code".AssertEquals(PriceListLine[8]."Price List Code");
        Assert.IsFalse(PriceListLineReview.Next(), 'found 2nd line');
    end;

    [Test]
    procedure T190_ActivePriceLineEditableInReviewPageIfEditingAllowed()
    var
        PriceListLine: Record "Price List Line";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [FEATURE] [Allow Editing Active Price]
        Initialize(true);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Active Price list line
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, LibraryUtility.GenerateGUID(), "Price Source Type"::"All Customers", '',
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
        // [GIVEN] Open "Price List Line Review" 
        PriceListLineReview.OpenEdit();
        PriceListLineReview.Filter.Setfilter("Price List Code", PriceListLine."Price List Code");
        // [WHEN] Edit the line: "Minimum Quantity" = 10, "Unit Price" = 1000
        Assert.IsTrue(PriceListLineReview."Minimum Quantity".Editable(), '"Minimum Quantity".Editable');
        PriceListLineReview."Minimum Quantity".SetValue(10);
        Assert.IsTrue(PriceListLineReview."Unit Price".Editable(), '"Unit Price".Editable');
        PriceListLineReview."Unit Price".SetValue(1000);
        // [THEN] "Status" is 'Draft' in the modified line
        Assert.AreEqual('Draft', PriceListLineReview.Status.Value, 'Status.Value');
    end;

    [Test]
    procedure T191_VerifyActiveLineModifiedInReviewPage()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceSource: Record "Price Source";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [FEATURE] [Allow Editing Active Price]
        Initialize(true);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Active Price list line in the active price list
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, LibraryUtility.GenerateGUID(), "Price Source Type"::"All Customers", '',
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
        PriceListHeader.Code := PriceListLine."Price List Code";
        PriceListLine.CopyTo(PriceSource);
        PriceListHeader.CopyFrom(PriceSource);
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert();
        // [GIVEN] Open "Price List Line Review" 
        PriceListLineReview.OpenEdit();
        PriceListLineReview.Filter.Setfilter("Price List Code", PriceListLine."Price List Code");
        Assert.AreEqual(0, PriceListLineReview."Minimum Quantity".AsDecimal(), 'Minimum Quantity');
        // [GIVEN] Change "Minimum Quantity" to 1
        PriceListLineReview."Minimum Quantity".SetValue(1);
        // [WHEN] Run 'Verify Lines' action
        PriceListLineReview.VerifyLines.Invoke();

        // [THEN] "Status" is 'Active' in the modified line
        Assert.AreEqual('Active', PriceListLineReview.Status.Value, 'Status.Value');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,NotificationLineHandler')]
    procedure T192_NotificationToVerifyActiveLineModifiedInReviewPage()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [FEATURE] [Allow Editing Active Price]
        Initialize(true);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] Active Price list line
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();
        // [GIVEN] Open "Price List Line Review" 
        PriceListLineReview.OpenEdit();
        PriceListLineReview.Filter.Setfilter("Price List Code", PriceListLine."Price List Code");
        Assert.AreEqual(0, PriceListLineReview."Minimum Quantity".AsDecimal(), 'Minimum Quantity');
        // [GIVEN] Change "Minimum Quantity" to 1
        PriceListLineReview."Minimum Quantity".SetValue(1);

        // [WHEN] Close the page
        PriceListLineReview.Close();
        // [THEN] Notification (without "Verify Lines" action) appears
        // checked by NotificationLineHandler
        // [THEN] "Status" is still 'Draft' in the modified line
        PriceListLine.Find();
        PriceListLine.TestField(Status, "Price Status"::Draft);
    end;

    [Test]
    [HandlerFunctions('SimpleDuplicatePriceLinesModalHandler')]
    procedure T193_VerifyMultipleActiveLinesModifiedInReviewPage()
    var
        Item: Record Item;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [FEATURE] [Allow Editing Active Price]
        // [SCENARIO 411619] Multiple lines in two price lists become duplicate after modification but can be resolved.
        Initialize(true);
        // [GIVEN] "Allow Editing Active Price" is Yes for Sales
        LibraryPriceCalculation.AllowEditingActiveSalesPrice();
        // [GIVEN] 2 active price lists, each has 1 draft and 1 active lines for Item 'I'
        LibraryInventory.CreateItem(Item);
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader[1].Status := "Price Status"::Active;
        PriceListHeader[1].Modify();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine."Minimum Quantity" := 1;
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();

        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader[2].Status := "Price Status"::Active;
        PriceListHeader[2].Modify();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine."Minimum Quantity" := 1;
        PriceListLine.Modify();
        // [GIVEN] Open "Price List Line Review" 
        PriceListLineReview.OpenEdit();
        PriceListLineReview.Filter.Setfilter(
            "Price List Code", StrSubstNo('%1|%2', PriceListHeader[1].Code, PriceListHeader[2].Code));

        // [WHEN] Run 'Verify Lines' action
        Commit();
        PriceListLineReview.VerifyLines.Invoke();

        // [THEN] "Status" is 'Active' in 2 modified lines
        Assert.AreEqual('Active', PriceListLineReview.Status.Value, 'Status.Value #1');
        PriceListLineReview.PriceListDescription.AssertEquals(PriceListHeader[1].FieldName(Description) + PriceListHeader[1].Code);
        Assert.IsTrue(PriceListLineReview.Next(), 'not found 2nd line');
        Assert.AreEqual('Active', PriceListLineReview.Status.Value, 'Status.Value #2');
        PriceListLineReview.PriceListDescription.AssertEquals(PriceListHeader[2].FieldName(Description) + PriceListHeader[2].Code);
        Assert.IsFalse(PriceListLineReview.Next(), 'found 3rd line');
    end;

    [Test]
    [HandlerFunctions('ResourceListModalHandler')]
    procedure T200_WorkTypeVariantCodeOnSalesPriceListLineResource()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Sales] [Resource]
        Initialize(true);
        // [GIVEN] Resource 'X'
        LibraryResource.CreateResource(Resource, '');

        // [GIVEN] Price list with line, where "Asset Type" 'Resource'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Resource, Resource."No.");

        // [WHEN] Open "Sales Price List" page
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        // [THEN] "Work Type Code" is editable and enabled
        Assert.IsTrue(SalesPriceList.Lines."Work Type Code".Enabled(), '"Work Type Code".Enabled');
        Assert.IsTrue(SalesPriceList.Lines."Work Type Code".Editable(), '"Work Type Code".Editable');
        // [THEN] "Variant Code" is not editable and disabled
        Assert.IsFalse(SalesPriceList.Lines."Variant Code".Enabled(), '"Variant Code".Enabled');
        Assert.IsFalse(SalesPriceList.Lines."Variant Code".Editable(), '"Variant Code".Editable');
        // [THEN] "Unit of Measure Code" is editable and enabled
        Assert.IsTrue(SalesPriceList.Lines."Unit of Measure Code".Enabled(), '"Unit of Measure Code".Enabled');
        Assert.IsTrue(SalesPriceList.Lines."Unit of Measure Code".Editable(), '"Unit of Measure Code".Editable');

        // [WHEN] Add another line for Resource 'X' by lookup
        SalesPriceList.Lines.New();
        SalesPriceList.Lines."Asset Type".SetValue("Price Asset Type"::Resource);
        SalesPriceList.Lines."Asset No.".Lookup();

        // [THEN] "Work Type Code" is editable and enabled
        Assert.IsTrue(SalesPriceList.Lines."Work Type Code".Enabled(), 'new line "Work Type Code".Enabled');
        Assert.IsTrue(SalesPriceList.Lines."Work Type Code".Editable(), 'new line "Work Type Code".Editable');
        // [THEN] "Variant Code" is not editable and disabled
        Assert.IsFalse(SalesPriceList.Lines."Variant Code".Enabled(), 'new line "Variant Code".Enabled');
        Assert.IsFalse(SalesPriceList.Lines."Variant Code".Editable(), 'new line "Variant Code".Editable');
    end;

    [Test]
    procedure T201_WorkTypeVariantCodeOnSalesPriceListLineResourceGroup()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Sales] [Resource Group]
        Initialize(true);
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [GIVEN] Price list with line, where "Asset Type" 'Resource Group'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [WHEN] Open "Sales Price List" page
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        // [THEN] "Work Type Code" is editable and enabled
        Assert.IsTrue(SalesPriceList.Lines."Work Type Code".Enabled(), '"Work Type Code".Enabled');
        Assert.IsTrue(SalesPriceList.Lines."Work Type Code".Editable(), '"Work Type Code".Editable');
        // [THEN] "Variant Code" is not editable and disabled
        Assert.IsFalse(SalesPriceList.Lines."Variant Code".Enabled(), '"Variant Code".Enabled');
        Assert.IsFalse(SalesPriceList.Lines."Variant Code".Editable(), '"Variant Code".Editable');
        // [THEN] "Unit of Measure Code" is editable and enabled
        Assert.IsTrue(SalesPriceList.Lines."Unit of Measure Code".Enabled(), '"Unit of Measure Code".Enabled');
        Assert.IsTrue(SalesPriceList.Lines."Unit of Measure Code".Editable(), '"Unit of Measure Code".Editable');
    end;

    [Test]
    procedure T202_WorkTypeVariantCodeOnSalesPriceListLineItem()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        Item: Record Item;
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Sales] [Item]
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price list with line, where "Asset Type" 'Item'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Open "Sales Price List" page
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        // [THEN] "Work Type Code" is not editable and disabled
        Assert.IsFalse(SalesPriceList.Lines."Work Type Code".Enabled(), '"Work Type Code".Enabled');
        Assert.IsFalse(SalesPriceList.Lines."Work Type Code".Editable(), '"Work Type Code".Editable');
        // [THEN] "Variant Code" is editable and enabled
        Assert.IsTrue(SalesPriceList.Lines."Variant Code".Enabled(), '"Variant Code".Enabled');
        Assert.IsTrue(SalesPriceList.Lines."Variant Code".Editable(), '"Variant Code".Editable');
        // [THEN] "Unit of Measure Code" is editable and enabled
        Assert.IsTrue(SalesPriceList.Lines."Unit of Measure Code".Enabled(), '"Unit of Measure Code".Enabled');
        Assert.IsTrue(SalesPriceList.Lines."Unit of Measure Code".Editable(), '"Unit of Measure Code".Editable');
    end;

    [Test]
    procedure T203_WorkTypeVariantCodeOnSalesPriceListLineGLAccount()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        GLAccount: Record "G/L Account";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [Sales] [Item]
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Price list with line, where "Asset Type" 'G/L Account'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");

        // [WHEN] Open "Sales Price List" page
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] "Work Type Code" is not editable and disabled
        Assert.IsFalse(SalesPriceList.Lines."Work Type Code".Enabled(), '"Work Type Code".Enabled');
        Assert.IsFalse(SalesPriceList.Lines."Work Type Code".Editable(), '"Work Type Code".Editable');
        // [THEN] "Variant Code" is not editable and disabled
        Assert.IsFalse(SalesPriceList.Lines."Variant Code".Enabled(), '"Variant Code".Enabled');
        Assert.IsFalse(SalesPriceList.Lines."Variant Code".Editable(), '"Variant Code".Editable');
        // [THEN] "Unit of Measure Code" is not editable and disabled
        Assert.IsFalse(SalesPriceList.Lines."Unit of Measure Code".Enabled(), '"Unit of Measure Code".Enabled');
        Assert.IsFalse(SalesPriceList.Lines."Unit of Measure Code".Editable(), '"Unit of Measure Code".Editable');
    end;

    [Test]
    [HandlerFunctions('ResourceListModalHandler')]
    procedure T205_WorkTypeVariantCodeOnPurchasePriceListLineResource()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [FEATURE] [Purchase] [Resource]
        Initialize(true);
        // [GIVEN] Resource 'X'
        LibraryResource.CreateResource(Resource, '');

        // [GIVEN] Price list with line, where "Asset Type" 'Resource'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");

        // [WHEN] Open "Purchase Price List" page
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        // [THEN] "Work Type Code" is editable and enabled
        Assert.IsTrue(PurchasePriceList.Lines."Work Type Code".Enabled(), '"Work Type Code".Enabled');
        Assert.IsTrue(PurchasePriceList.Lines."Work Type Code".Editable(), '"Work Type Code".Editable');
        // [THEN] "Variant Code" is not editable and disabled
        Assert.IsFalse(PurchasePriceList.Lines."Variant Code".Enabled(), '"Variant Code".Enabled');
        Assert.IsFalse(PurchasePriceList.Lines."Variant Code".Editable(), '"Variant Code".Editable');
        // [THEN] "Unit of Measure Code" is editable and enabled
        Assert.IsTrue(PurchasePriceList.Lines."Unit of Measure Code".Enabled(), '"Unit of Measure Code".Enabled');
        Assert.IsTrue(PurchasePriceList.Lines."Unit of Measure Code".Editable(), '"Unit of Measure Code".Editable');

        // [WHEN] Add another line for Resource 'X' by lookup
        PurchasePriceList.Lines.New();
        PurchasePriceList.Lines."Asset Type".SetValue("Price Asset Type"::Resource);
        PurchasePriceList.Lines."Asset No.".Lookup();

        // [THEN] "Work Type Code" is editable and enabled
        Assert.IsTrue(PurchasePriceList.Lines."Work Type Code".Enabled(), 'new line "Work Type Code".Enabled');
        Assert.IsTrue(PurchasePriceList.Lines."Work Type Code".Editable(), 'new line "Work Type Code".Editable');
        // [THEN] "Variant Code" is not editable and disabled
        Assert.IsFalse(PurchasePriceList.Lines."Variant Code".Enabled(), 'new line "Variant Code".Enabled');
        Assert.IsFalse(PurchasePriceList.Lines."Variant Code".Editable(), 'new line "Variant Code".Editable');
    end;

    [Test]
    procedure T206_WorkTypeVariantCodeOnPurchasePriceListLineResourceGroup()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ResourceGroup: Record "Resource Group";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [FEATURE] [Purchase] [Resource Group]
        Initialize(true);
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // [GIVEN] Price list with line, where "Asset Type" 'Resource Group'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Vendors", '', "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [WHEN] Open "Purchase Price List" page
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        // [THEN] "Work Type Code" is editable and enabled
        Assert.IsTrue(PurchasePriceList.Lines."Work Type Code".Enabled(), '"Work Type Code".Enabled');
        Assert.IsTrue(PurchasePriceList.Lines."Work Type Code".Editable(), '"Work Type Code".Editable');
        // [THEN] "Variant Code" is not editable and disabled
        Assert.IsFalse(PurchasePriceList.Lines."Variant Code".Enabled(), '"Variant Code".Enabled');
        Assert.IsFalse(PurchasePriceList.Lines."Variant Code".Editable(), '"Variant Code".Editable');
        // [THEN] "Unit of Measure Code" is editable and enabled
        Assert.IsTrue(PurchasePriceList.Lines."Unit of Measure Code".Enabled(), '"Unit of Measure Code".Enabled');
        Assert.IsTrue(PurchasePriceList.Lines."Unit of Measure Code".Editable(), '"Unit of Measure Code".Editable');
    end;

    [Test]
    procedure T207_WorkTypeVariantCodeOnPurchasePriceListLineItem()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        Item: Record Item;
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [FEATURE] [Purchase] [Item]
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price list with line, where "Asset Type" 'Item'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");

        // [WHEN] Open "Purchase Price List" page
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        // [THEN] "Work Type Code" is not editable and disabled
        Assert.IsFalse(PurchasePriceList.Lines."Work Type Code".Enabled(), '"Work Type Code".Enabled');
        Assert.IsFalse(PurchasePriceList.Lines."Work Type Code".Editable(), '"Work Type Code".Editable');
        // [THEN] "Variant Code" is editable and enabled
        Assert.IsTrue(PurchasePriceList.Lines."Variant Code".Enabled(), '"Variant Code".Enabled');
        Assert.IsTrue(PurchasePriceList.Lines."Variant Code".Editable(), '"Variant Code".Editable');
        // [THEN] "Unit of Measure Code" is editable and enabled
        Assert.IsTrue(PurchasePriceList.Lines."Unit of Measure Code".Enabled(), '"Unit of Measure Code".Enabled');
        Assert.IsTrue(PurchasePriceList.Lines."Unit of Measure Code".Editable(), '"Unit of Measure Code".Editable');
    end;

    [Test]
    procedure T208_WorkTypeVariantCodeOnPurchasePriceListLineGLAccount()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        GLAccount: Record "G/L Account";
        PurchasePriceList: TestPage "Purchase Price List";
    begin
        // [FEATURE] [Purchase] [Item]
        Initialize(true);
        // [GIVEN] Item 'X'
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Price list with line, where "Asset Type" 'G/L Account'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Vendors", '', "Price Asset Type"::"G/L Account", GLAccount."No.");

        // [WHEN] Open "Purchase Price List" page
        PurchasePriceList.OpenEdit();
        PurchasePriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] "Work Type Code" is not editable and disabled
        Assert.IsFalse(PurchasePriceList.Lines."Work Type Code".Enabled(), '"Work Type Code".Enabled');
        Assert.IsFalse(PurchasePriceList.Lines."Work Type Code".Editable(), '"Work Type Code".Editable');
        // [THEN] "Variant Code" is not editable and disabled
        Assert.IsFalse(PurchasePriceList.Lines."Variant Code".Enabled(), '"Variant Code".Enabled');
        Assert.IsFalse(PurchasePriceList.Lines."Variant Code".Editable(), '"Variant Code".Editable');
        // [THEN] "Unit of Measure Code" is not editable and disabled
        Assert.IsFalse(PurchasePriceList.Lines."Unit of Measure Code".Enabled(), '"Unit of Measure Code".Enabled');
        Assert.IsFalse(PurchasePriceList.Lines."Unit of Measure Code".Editable(), '"Unit of Measure Code".Editable');
    end;

    [Test]
    procedure PriceListCustomerShowForBillToCustomerNo()
    var
        Customer: array[2] of Record Customer;
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListsUI: Codeunit "Price Lists UI";
        SalesPriceLists: TestPage "Sales Price Lists";
        AmountType: Enum "Price Amount Type";
    begin
        // [SCENARIO 398417] Prices should be shown for "Bill-to Customer No"
        Initialize(true);

        // [GIVEN] Two Customers 'A' and 'B'. Customer "A"."Bill-to Customer No." = 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        Customer[1].Validate("Bill-to Customer No.", Customer[2]."No.");
        Customer[1].Modify();

        // [WHEN] Show Price List for Customer 'A'
        BindSubscription(PriceListsUI);
        PriceListsUI.ClearVariableStorage();
        PriceListsUI.Enqueue(Customer[2]."No.");  //enqueue Customer 'B' for OnAfterGetPriceSource subscriber
        SalesPriceLists.Trap();

        // [THEN] Price List shows Prices for Customer 'B'
        PriceUXManagement.ShowPriceLists(Customer[1], AmountType::Any);
        SalesPriceLists.Close();
        Assert.AreEqual(1, PriceListsUI.Dequeue(), 'Wrong Customer No.'); // returns TempPriceSource count containing Customer 'B'
        UnbindSubscription(PriceListsUI);
    end;

    [Test]
    procedure PriceListVendorShowForPayToVendorNo()
    var
        Vendor: array[2] of Record Vendor;
        PriceUXManagement: Codeunit "Price UX Management";
        PriceListsUI: Codeunit "Price Lists UI";
        PurchPriceLists: TestPage "Purchase Price Lists";
        AmountType: Enum "Price Amount Type";
    begin
        // [SCENARIO 398417] Prices should be shown for "Pay-to Vendor No"
        Initialize(true);

        // [GIVEN] Two Vendors 'A' and 'B'. Vendor "A"."Pay-to Vendor No." = 'B'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        Vendor[1].Validate("Pay-to Vendor No.", Vendor[2]."No.");
        Vendor[1].Modify();

        // [WHEN] Show Price List for Vendor 'A'
        BindSubscription(PriceListsUI);
        PriceListsUI.ClearVariableStorage();
        PriceListsUI.Enqueue(Vendor[2]."No."); //enqueue Vendor 'B' for OnAfterGetPriceSource subscriber
        PurchPriceLists.Trap();

        // [THEN] Price List shows Prices for Vendor 'B'
        PriceUXManagement.ShowPriceLists(Vendor[1], AmountType::Any);
        PurchPriceLists.Close();
        Assert.AreEqual(1, PriceListsUI.Dequeue(), 'Wrong Vendor No.'); // returns TempPriceSource count containing Vendor 'B'
        UnbindSubscription(PriceListsUI);
    end;

    [Test]
    procedure SalesJobPriceListAutofillsJobNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceSource: Record "Price Source";
        Job: Record Job;
        PriceUXManagement: Codeunit "Price UX Management";
        SourceGroup: Enum "Price Source Group";
    begin
        // [SCENARIO 449200] Creating Job Purchase Price List from a Job Card
        Initialize(true);

        // [GIVEN] A Job 
        LibraryJob.CreateJob(Job);

        // [GIVEN] New PriceListHeader similar to opening a new Sales Price List via Job  Card "Sales Price Lists" action, and "New" button.
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Source Group", SourceGroup::Job);
        PriceListHeader.SetFilter("Filter Source No.", Job."No.");
        PriceListHeader.SetRange("Price Type", "Price Type"::Sale);

        // [WHEN] GetFirstSourceFromFilter runs (triggered by New button on Sales Price Lists page)
        PriceUXManagement.GetFirstSourceFromFilter(PriceListHeader, PriceSource, "Price Source Type"::"All Jobs");

        // [THEN] PriceSource has "Source No." and "Source Type" set to Job.No and Job (Which later populates new Price Source List)
        Assert.AreEqual(Job."No.", PriceSource."Source No.", '');
        Assert.AreEqual("Price Source Type"::Job, PriceSource."Source Type", '');
    end;

    [Test]
    procedure PurchaseJobPriceListAutofillsJobNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceSource: Record "Price Source";
        Job: Record Job;
        PriceUXManagement: Codeunit "Price UX Management";
        SourceGroup: Enum "Price Source Group";
    begin
        // [SCENARIO 449200] Creating Job Purchase Price List from a Job Card
        Initialize(true);

        // [GIVEN] A Job 
        LibraryJob.CreateJob(Job);

        // [GIVEN] New PriceListHeader similar to opening a new Purchase Price List via Job  Card "Purchase Price Lists" action, and "New" button.
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Source Group", SourceGroup::Job);
        PriceListHeader.SetFilter("Filter Source No.", Job."No.");
        PriceListHeader.SetRange("Price Type", "Price Type"::Purchase);

        // [WHEN] GetFirstSourceFromFilter runs (triggered by New button on Purchase Price Lists page)
        PriceUXManagement.GetFirstSourceFromFilter(PriceListHeader, PriceSource, "Price Source Type"::"All Jobs");

        // [THEN] PriceSource has "Source No." and "Source Type" set to Job.No and Job (Which later populates new Price Source List)
        Assert.AreEqual(Job."No.", PriceSource."Source No.", '');
        Assert.AreEqual("Price Source Type"::Job, PriceSource."Source Type", '');
    end;

    [Test]
    procedure DefaultAmountTypeInSalesPriceList()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO 488342] Verify Assign-to Type to a type that supports both "Price" and "Discount" as Default.
        Initialize(true);

        // [GIVEN] Create a Sales Price List header.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader,
            "Price Type"::Sale,
            "Price Source Type"::"All Customers",
            '');
        PriceListHeader.Validate("Source Group", PriceListHeader."Source Group"::Customer);
        PriceListHeader.Modify(true);

        // [VERIFY] Check different Default View in Sales Price List. 
        VerifyAmountType(PriceListHeader);
    end;

    [Test]
    procedure NextNoSeriesIsAssignedInCodeFieldOfSalesPriceListWhenCleanEnteredChar()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesPriceList: TestPage "Sales Price List";
        NextNo: Code[20];
    begin
        // [SCENARIO 533390] Next No. Series is assigned in Code field of Sales Price List when Stan types something in it and removes it and then press tab.
        Initialize(true);

        // [GIVEN] Validate Price List Nos. in Sales & Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Generate and save Next No. from No. Series in a Variable.
        NextNo := LibraryUtility.GetNextNoFromNoSeries(SalesReceivablesSetup."Price List Nos.", WorkDate());

        // [GIVEN] Open New Sales Price List.
        SalesPriceList.OpenNew();

        // [WHEN] Set blank in Code field.
        SalesPriceList.Code.SetValue('');
        SalesPriceList.Next();

        // [THEN] Next No. from No. Series and value in Code field of Sales Price List are same.
        Assert.AreEqual(
            NextNo,
            Format(SalesPriceList.Code),
            StrSubstNo(
                CodeErr,
                SalesPriceList.Code.Caption(),
                NextNo,
                SalesPriceList.Caption()));
    end;

    [Test]
    procedure NextNoSeriesIsAssignedInCodeFieldOfPurchPriceListWhenCleanEnteredChar()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchasePriceList: TestPage "Purchase Price List";
        NextNo: Code[20];
    begin
        // [SCENARIO 533390] Next No. Series is assigned in Code field of Purchase Price List when Stan types something in it and removes it and then press tab.
        Initialize(true);

        // [GIVEN] Validate Price List Nos. in Purchases & Payables Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Generate and save Next No. from No. Series in a Variable.
        NextNo := LibraryUtility.GetNextNoFromNoSeries(PurchasesPayablesSetup."Price List Nos.", WorkDate());

        // [GIVEN] Open New Purchase Price List.
        PurchasePriceList.OpenNew();

        // [WHEN] Set blank in Code field.
        PurchasePriceList.Code.SetValue('');
        PurchasePriceList.Next();

        // [THEN] Next No. from No. Series and value in Code field of Purchase Price List are same.
        Assert.AreEqual(
            NextNo,
            Format(PurchasePriceList.Code),
            StrSubstNo(
                CodeErr,
                PurchasePriceList.Code.Caption(),
                NextNo,
                PurchasePriceList.Caption()));
    end;

    [Test]
    procedure AmountTypeFieldDoesNotChangeOnClosePageSalesPriceList()
    var
        PriceListHeader: Record "Price List Header";
        CustomerDiscountGroup: Record "Customer Discount Group";
        SalesPriceList: TestPage "Sales Price List";
        PriceListHeaderCode: Code[20];
    begin
        // [SCENARIO 566994] Bug fix to ensure the field "Amount Type" does not change after closing the page "Sales Price List" 
        Initialize(true);

        // [GIVEN] Sales Price List for discount
        PriceListHeaderCode := LibraryUtility.GenerateGUID();
        SalesPriceList.OpenEdit();
        SalesPriceList.New();
        SalesPriceList.Code.SetValue(PriceListHeaderCode);
        SalesPriceList.Description.SetValue(LibraryUtility.GenerateGUID());
        SalesPriceList.SourceType.SetValue("Price Source Type"::"Customer Disc. Group");
        SalesPriceList.AmountType.SetValue("Price Amount Type"::Discount);
        CustomerDiscountGroup.Init();
        CustomerDiscountGroup.Code := LibraryUtility.GenerateGUID();
        CustomerDiscountGroup.Insert();
        SalesPriceList.AssignToNo.SetValue(CustomerDiscountGroup.Code);
        SalesPriceList.Status.SetValue("Price Status"::Active);

        // [WHEN] Close the page "Sales Price List"
        SalesPriceList.Close();

        // [THEN] Check the field "Amount Type" has not reverted to Price & Discount
        PriceListHeader.Get(PriceListHeaderCode);
        Assert.IsTrue((PriceListHeader."Amount Type" = PriceListHeader."Amount Type"::Discount), 'The field "Amount Type" has changed after closing the page "Sales Price List"');
    end;

    [Test]
    procedure UnitCostFieldDoesAppearinPriceListLineReviewPageForResource()
    var
        Resource: Record Resource;
        PriceListLine: Record "Price List Line";
        LibraryRandom: Codeunit "Library - Random";
        ResourceList: TestPage "Resource List";
        PriceListLineReview: TestPage "Price List Line Review";
    begin
        // [SCENARIO] Unit Cost is Not Visible in Price List Lines because ResourceAsset variable is not initialized
        Initialize(true);

        // [GIVEN] Feature is On
        // [GIVEN] Resource 'R' with 1 price list lines for purchase:
        LibraryResource.CreateResource(Resource, '');
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine.Validate("Unit Cost", LibraryRandom.RandDec(1000, 2));
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [WHEN] Open "Resource List"
        ResourceList.OpenView();
        ResourceList.Filter.SetFilter("No.", Resource."No.");

        // [THEN] NoOfResCosts is 1
        ResourceList.Control1907012907.NoOfResCosts.AssertEquals(1);

        // [WHEN] Drill down NoOfResPrices
        PriceListLineReview.Trap();
        ResourceList.Control1907012907.NoOfResPrices.Drilldown();

        // [WHEN] Drill down NoOfResCosts
        PriceListLineReview.Trap();
        ResourceList.Control1907012907.NoOfResCosts.Drilldown();

        // [THEN] Open list with the purchase price line for resource
        Assert.Istrue(PriceListLineReview.First(), 'not found the first purch price line');
        PriceListLineReview."Source Type".AssertEquals(PriceListLine."Source Type");
        PriceListLineReview."Asset Type".AssertEquals(PriceListLine."Asset Type");
        PriceListLineReview."Unit Cost".AssertEquals(PriceListLine."Unit Cost");
    end;

    [Test]
    procedure ErrorOnCustomerDiscountGroupDeleteWhenAssignedToCustomer()
    var
        Customer: Record Customer;
        CustomerDiscountGroup: array[2] of Record "Customer Discount Group";
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO 595896] The Customer Discount Group assigned to Customer should not be abled to delete.
        Initialize(true);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create an Item.
        Item.Get(LibraryInventory.CreateItemNo());

        // [GIVEN] Assign a Customer Discount Group and assign it to the Customer.
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[1]);
        Customer.Validate("Customer Disc. Group", CustomerDiscountGroup[1].Code);
        Customer.Modify();

        // [GIVEN] Create a Sales Price List line for the Customer Discount Group.
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine,
            LibraryUtility.GenerateGUID(),
            "Price Source Type"::"Customer Disc. Group",
            CustomerDiscountGroup[1].Code,
            "Price Asset Type"::Item,
             Item."No.");

        // [WHEN] Try to delete the Customer Discount Group.
        asserterror CustomerDiscountGroup[1].Delete(true);

        // [THEN] An error occurs that the Customer Discount Group is tried to delete in use by a Customer.
        Assert.ExpectedError(StrSubstNo(CustDiscountGroupDeleteErr, CustomerDiscountGroup[1].Code));
    end;

    [Test]
    procedure ErrorOnSalesLineWhenDeletedCustomerDiscountGroupIsAssigned()
    var
        Customer: Record Customer;
        CustomerDiscountGroup: array[2] of Record "Customer Discount Group";
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 595896] Deleted Customer Discount Group assigned to Customer should give error on Sales Line.
        Initialize(true);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create an Item.
        Item.Get(LibraryInventory.CreateItemNo());

        // [GIVEN] Create a Customer Discount Group and assign it to the Customer.
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[1]);
        Customer.Validate("Customer Disc. Group", CustomerDiscountGroup[1].Code);
        Customer.Modify();

        // [GIVEN] Create a Sales Price List line for the Customer Discount Group.
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine,
            LibraryUtility.GenerateGUID(),
            "Price Source Type"::"Customer Disc. Group",
            CustomerDiscountGroup[1].Code,
            "Price Asset Type"::Item,
             Item."No.");

        // [GIVEN] Delete the Customer Discount Group.
        CustomerDiscountGroup[1].Delete();

        // [GIVEN] Create a Sales Header for the Customer.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Try to create a Sales Line for the Item.
        asserterror LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));

        // [THEN] An error occurs that the Customer Discount Group assigned to the Customer is not found.
        Assert.ExpectedError(
            StrSubstNo(
                CustDiscountGroupCodeDeleteErr,
                CustomerDiscountGroup[1].Code,
                CustomerDiscountGroup[1].TableCaption()));
    end;

    local procedure Initialize(Enable: Boolean)
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Lists UI");

        LibraryPriceCalculation.EnableExtendedPriceCalculation(Enable);
        LibraryPriceCalculation.DisallowEditingActiveSalesPrice();
        LibraryPriceCalculation.DisallowEditingActivePurchPrice();
        LibraryPriceCalculation.SetUseCustomLookup(true);
        PriceListHeader.ModifyAll(Status, PriceListHeader.Status::Draft);
        PriceListHeader.DeleteAll(true);
        PriceListLine.ModifyAll(Status, PriceListLine.Status::Draft);
        PriceListLine.DeleteAll(true);

        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Lists UI");

        FillPriceListNos();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Lists UI");
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; FillVariantCode: Boolean)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Vendor: Record Vendor;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        if FillVariantCode then
            ItemVendor.Rename(Vendor."No.", Item."No.", LibraryInventory.CreateItemVariant(ItemVariant, Item."No."));
    end;

    local procedure CreatePriceLines(var PriceListLine: array[12] of Record "Price List Line"; ItemVendor: Record "Item Vendor")
    var
        i: Integer;
    begin
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], '1', "Price Type"::Purchase, "Price Source Type"::Vendor, ItemVendor."Vendor No.",
            "Price Amount Type"::Price, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], '2', "Price Type"::Purchase, "Price Source Type"::Vendor, ItemVendor."Vendor No.",
            "Price Amount Type"::Discount, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[3], '3', "Price Type"::Purchase, "Price Source Type"::"All Vendors", '',
            "Price Amount Type"::Price, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[4], '4', "Price Type"::Purchase, "Price Source Type"::"All Vendors", '',
            "Price Amount Type"::Discount, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[5], '5', "Price Type"::Sale, "Price Source Type"::"All Customers", '',
            "Price Amount Type"::Price, "Price Asset Type"::Item, ItemVendor."Item No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[6], '6', "Price Type"::Sale, "Price Source Type"::"All Customers", '',
            "Price Amount Type"::Discount, "Price Asset Type"::Item, ItemVendor."Item No.");
        for i := 1 to 2 do begin
            PriceListLine[i + 6] := PriceListLine[i];
            PriceListLine[i + 6]."Price List Code" := Format(i + 6);
            PriceListLine[i + 6]."Variant Code" := ItemVendor."Variant Code";
            PriceListLine[i + 6].Insert();
        end;
    end;

    local procedure CreatePriceLines(var PriceListLine: array[12] of Record "Price List Line"; AssetType: Enum "Price Asset Type"; AssetNo: Code[20])
    var
        PriceType: Enum "Price Type";
        SourceType: Enum "Price Source Type";
        AmountType: array[3] of Enum "Price Amount Type";
        PriceListCode: Code[20];
        I: Integer;
        LineNo: Integer;
    begin
        AmountType[1] := "Price Amount Type"::Any;
        AmountType[2] := "Price Amount Type"::Price;
        AmountType[3] := "Price Amount Type"::Discount;
        SourceType := SourceType::"All Customers";
        for PriceType := PriceType::Sale to PriceType::Purchase do begin
            for I := 1 to ArrayLen(AmountType) do
                if ((AmountType[I] = "Price Amount Type"::Discount) and (PriceType = PriceType::Sale)) or
                    (AssetType <> AssetType::"Item Discount Group")
                then begin
                    LineNo += 1;
                    PriceListCode :=
                        StrSubstNo('%1 %2 %3 %4', PriceType.AsInteger(), SourceType.AsInteger(), AmountType[I].AsInteger(), AssetType.AsInteger());
                    LibraryPriceCalculation.CreatePriceListLine(
                        PriceListLine[LineNo], PriceListCode, PriceType, SourceType, '', AmountType[I], AssetType, AssetNo);
                    LineNo += 1;
                    PriceListCode :=
                        StrSubstNo('%1 %2 %3 %4', PriceType.AsInteger(), SourceType::"All Jobs".AsInteger(), AmountType[I].AsInteger(), AssetType.AsInteger());
                    LibraryPriceCalculation.CreatePriceListLine(
                        PriceListLine[LineNo], PriceListCode, PriceType, SourceType::"All Jobs", '', AmountType[I], AssetType, AssetNo);
                end;
            SourceType := SourceType::"All Vendors";
        end;
    end;

    local procedure CreateSalesPriceLinesForCustomers(Customer: array[2] of Record Customer; var PriceListLine: array[4] of Record "Price List Line")
    var
        PriceListHeader: Record "Price List Header";
    begin
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader.Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[1]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[1].Modify();

        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], PriceListHeader.Code, "Price Source Type"::Customer, Customer[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, Customer[2]."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], PriceListHeader.Code, "Price Source Type"::Customer, Customer[2]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[3]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[3].Modify();

        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::Customer, Customer[1]."No.");
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine[4], PriceListHeader.Code, "Price Source Type"::Customer, Customer[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
    end;

    local procedure CreatePurchPriceLinesForVendors(Vendor: array[2] of Record Vendor; var PriceListLine: array[4] of Record "Price List Line")
    begin
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[1], '001', "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[1]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[1].Modify();

        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[2], '002', "Price Source Type"::Vendor, Vendor[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[3], '003', "Price Source Type"::Vendor, Vendor[2]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        LibraryPriceCalculation.CreatePurchDiscountLine(
            PriceListLine[4], '004', "Price Source Type"::Vendor, Vendor[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
    end;

    local procedure CreatePurchPriceLinesForJobs(Job: array[2] of Record Job; JobTask: Record "Job Task"; var PriceListLine: array[5] of Record "Price List Line"; FifthPriceAmountType: Enum "Price Amount Type")
    begin
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[1], '001', "Price Source Type"::"All Jobs", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[1]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[1].Modify();

        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[2], '002', "Price Source Type"::Job, Job[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[3], '003', "Price Source Type"::Job, Job[2]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[3]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[3].Modify();

        LibraryPriceCalculation.CreatePurchDiscountLine(
            PriceListLine[4], '004', "Price Source Type"::Job, Job[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[5], '005', "Price Type"::Purchase, "Price Source Type"::"Job Task", Job[1]."No.", JobTask."Job Task No.",
            FifthPriceAmountType, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
    end;

    local procedure CreateSalesPriceLinesForJobs(Job: array[2] of Record Job; JobTask: Record "Job Task"; var PriceListLine: array[5] of Record "Price List Line"; FifthPriceAmountType: Enum "Price Amount Type")
    begin
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '001', "Price Source Type"::"All Jobs", '',
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[1]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[1].Modify();

        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], '002', "Price Source Type"::Job, Job[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], '003', "Price Source Type"::Job, Job[2]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        PriceListLine[3]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[3].Modify();

        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine[4], '004', "Price Source Type"::Job, Job[1]."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[5], '005', "Price Type"::Sale, "Price Source Type"::"Job Task", Job[1]."No.", JobTask."Job Task No.",
            FifthPriceAmountType, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
    end;

    local procedure FillPriceListNos()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        JobsSetup: Record "Jobs Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('SAL'));
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('PUR'));
        PurchasesPayablesSetup.Modify();

        JobsSetup.Get();
        JobsSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('JOB'));
        JobsSetup.Modify();
    end;

    local procedure RunPurchPriceList(SourceGroup: Enum "Price Source Group")
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Price Type", "Price Type"::Purchase);
        PriceListHeader.SetRange("Source Group", SourceGroup);
        PriceListHeader.FilterGroup(0);
        Page.Run(Page::"Purchase Price List", PriceListHeader);
    end;

    local procedure RunSalesPriceList(SourceGroup: Enum "Price Source Group")
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Price Type", "Price Type"::Sale);
        PriceListHeader.SetRange("Source Group", SourceGroup);
        PriceListHeader.FilterGroup(0);
        Page.Run(Page::"Sales Price List", PriceListHeader);
    end;

    local procedure VerifyAllControlsEditable(var SalesPriceList: TestPage "Sales Price List")
    begin
        Assert.IsFalse(SalesPriceList.Code.Editable(), 'Code.Editable');
        Assert.IsTrue(SalesPriceList.Description.Editable(), 'Description.not Editable');
        Assert.IsTrue(SalesPriceList.SourceType.Editable(), 'SourceType.not Editable');
        Assert.IsTrue(SalesPriceList.SourceNo.Editable(), 'SourceNo.not Editable');
        Assert.IsTrue(SalesPriceList.SourceNo.Visible(), 'SourceNo.not Visible');
        Assert.IsFalse(SalesPriceList.AssignToNo.Visible(), 'AssignToNo.not Visible');
        Assert.IsTrue(SalesPriceList.StartingDate.Editable(), 'StartingDate.not Editable');
        Assert.IsTrue(SalesPriceList.EndingDate.Editable(), 'EndingDate.not Editable');
        Assert.IsTrue(SalesPriceList.VATBusPostingGrPrice.Editable(), 'VATBusPostingGrPrice.not Editable');
        Assert.IsTrue(SalesPriceList.PriceIncludesVAT.Editable(), 'PriceIncludesVAT.not Editable');
        Assert.IsTrue(SalesPriceList.AllowInvoiceDisc.Editable(), 'AllowInvoiceDisc.not Editable');
        Assert.IsTrue(SalesPriceList.AllowLineDisc.Editable(), 'AllowLineDisc.not Editable');
        Assert.IsTrue(SalesPriceList.Lines.Editable(), 'Lines.not Editable');
        Assert.IsTrue(SalesPriceList.SuggestLines.Enabled(), 'SuggestLines.Enabled');
        Assert.IsTrue(SalesPriceList.CopyLines.Enabled(), 'CopyLines.Enabled');
    end;

    local procedure VerifyAllControlsEditable(var PurchasePriceList: TestPage "Purchase Price List")
    begin
        Assert.IsFalse(PurchasePriceList.Code.Editable(), 'Code.Editable');
        Assert.IsTrue(PurchasePriceList.Description.Editable(), 'Description.not Editable');
        Assert.IsTrue(PurchasePriceList.SourceType.Editable(), 'SourceType.not Editable');
        Assert.IsTrue(PurchasePriceList.SourceNo.Editable(), 'SourceNo.not Editable');
        Assert.IsTrue(PurchasePriceList.SourceNo.Visible(), 'SourceNo.not Visible');
        Assert.IsFalse(PurchasePriceList.AssignToNo.Visible(), 'AssignToNo. Visible');
        Assert.IsTrue(PurchasePriceList.StartingDate.Editable(), 'StartingDate.not Editable');
        Assert.IsTrue(PurchasePriceList.EndingDate.Editable(), 'EndingDate.not Editable');
        Assert.IsTrue(PurchasePriceList.PriceIncludesVAT.Editable(), 'PriceIncludesVAT.not Editable');
        Assert.IsTrue(PurchasePriceList.AllowLineDisc.Editable(), 'AllowLineDisc.not Editable');
        Assert.IsTrue(PurchasePriceList.Lines.Editable(), 'Lines.not Editable');
        Assert.IsTrue(PurchasePriceList.SuggestLines.Enabled(), 'SuggestLines.Enabled');
        Assert.IsTrue(PurchasePriceList.CopyLines.Enabled(), 'CopyLines.Enabled');
    end;

    local procedure VerifyAllControlsNotEditable(var SalesPriceList: TestPage "Sales Price List")
    begin
        Assert.IsFalse(SalesPriceList.Code.Editable(), 'Code.Editable');
        Assert.IsFalse(SalesPriceList.Description.Editable(), 'Description.Editable');
        Assert.IsFalse(SalesPriceList.SourceType.Editable(), 'SourceType.Editable');
        Assert.IsFalse(SalesPriceList.SourceNo.Editable(), 'SourceNo.Editable');
        Assert.IsTrue(SalesPriceList.SourceNo.Visible(), 'SourceNo.not Visible');
        Assert.IsFalse(SalesPriceList.AssignToNo.Visible(), 'AssignToNo.Visible');
        Assert.IsFalse(SalesPriceList.StartingDate.Editable(), 'StartingDate.Editable');
        Assert.IsFalse(SalesPriceList.EndingDate.Editable(), 'EndingDate.Editable');
        Assert.IsFalse(SalesPriceList.VATBusPostingGrPrice.Editable(), 'VATBusPostingGrPrice.Editable');
        Assert.IsFalse(SalesPriceList.PriceIncludesVAT.Editable(), 'PriceIncludesVAT.Editable');
        Assert.IsFalse(SalesPriceList.AllowInvoiceDisc.Editable(), 'AllowInvoiceDisc.Editable');
        Assert.IsFalse(SalesPriceList.AllowLineDisc.Editable(), 'AllowLineDisc.Editable');
        // Assert.IsFalse(SalesPriceList.Lines.Editable(), 'Lines.Editable'); test framework defect?
        Assert.IsFalse(SalesPriceList.SuggestLines.Enabled(), 'SuggestLines.Enabled');
        Assert.IsFalse(SalesPriceList.CopyLines.Enabled(), 'CopyLines.Enabled');
    end;

    local procedure VerifyAllControlsNotEditable(var PurchasePriceList: TestPage "Purchase Price List")
    begin
        Assert.IsFalse(PurchasePriceList.Code.Editable(), 'Code.Editable');
        Assert.IsFalse(PurchasePriceList.Description.Editable(), 'Description.Editable');
        Assert.IsFalse(PurchasePriceList.SourceType.Editable(), 'SourceType.Editable');
        Assert.IsFalse(PurchasePriceList.SourceNo.Editable(), 'SourceNo.Editable');
        Assert.IsTrue(PurchasePriceList.SourceNo.Visible(), 'SourceNo.not Visible');
        Assert.IsFalse(PurchasePriceList.AssignToNo.Visible(), 'AssignToNo.Visible');
        Assert.IsFalse(PurchasePriceList.StartingDate.Editable(), 'StartingDate.Editable');
        Assert.IsFalse(PurchasePriceList.EndingDate.Editable(), 'EndingDate.Editable');
        Assert.IsFalse(PurchasePriceList.PriceIncludesVAT.Editable(), 'PriceIncludesVAT.Editable');
        Assert.IsFalse(PurchasePriceList.AllowLineDisc.Editable(), 'AllowLineDisc.Editable');
        // Assert.IsFalse(PurchasePriceList.Lines.Editable(), 'Lines.Editable'); test framework defect?
        Assert.IsFalse(PurchasePriceList.SuggestLines.Enabled(), 'SuggestLines.Enabled');
        Assert.IsFalse(PurchasePriceList.CopyLines.Enabled(), 'CopyLines.Enabled');
    end;

    local procedure VerifyAmountType(PriceListHeader: Record "Price List Header")
    var
        SalesPriceList: TestPage "Sales Price List";
    begin
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        SalesPriceList.SourceType.SetValue(PriceListHeader."Source Type"::"All Customers");
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Any);
        SalesPriceList.SourceType.SetValue(PriceListHeader."Source Type"::Customer);
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Any);
        SalesPriceList.SourceType.SetValue(PriceListHeader."Source Type"::Campaign);
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Any);
        SalesPriceList.SourceType.SetValue(PriceListHeader."Source Type"::Contact);
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Any);
        SalesPriceList.SourceType.SetValue(PriceListHeader."Source Type"::"Customer Disc. Group");
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Discount);
        SalesPriceList.SourceType.SetValue(PriceListHeader."Source Type"::"Customer Price Group");
        SalesPriceList.AmountType.AssertEquals("Price Amount Type"::Price);
    end;

    [Scope('OnPrem')]
    procedure ClearVariableStorage()
    begin
        LibraryVariableStorage.Clear();
    end;

    [Scope('OnPrem')]
    procedure Enqueue(EnqueueValue: Variant)
    begin
        LibraryVariableStorage.Enqueue(EnqueueValue);
    end;

    [Scope('OnPrem')]
    procedure Dequeue() DequeueValue: Variant
    begin
        LibraryVariableStorage.Dequeue(DequeueValue);
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    procedure PriceListLineReviewModalHandler(var PriceListLineReview: TestPage "Price List Line Review")
    begin
        if PriceListLineReview.First() then
            repeat
                LibraryVariableStorage.Enqueue(PriceListLineReview."Price List Code");
            until not PriceListLineReview.Next();
    end;

    [ModalPageHandler]
    procedure ResourceListModalHandler(var ResourceList: TestPage "Resource List")
    begin
        ResourceList.First();
        ResourceList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure DuplicatePriceLinesModalHandler(var DuplicatePriceLines: TestPage "Duplicate Price Lines")
    begin
        Assert.IsTrue(DuplicatePriceLines.Last(), 'not found the last line');
        DuplicatePriceLines.Remove.SetValue(Format(false));

        Assert.IsTrue(DuplicatePriceLines.First(), 'not found the first line');
        Assert.IsTrue(DuplicatePriceLines.Remove.AsBoolean(), 'Remove.Value must be true in the first line');
        DuplicatePriceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SimpleDuplicatePriceLinesModalHandler(var DuplicatePriceLines: TestPage "Duplicate Price Lines")
    begin
        DuplicatePriceLines.OK().Invoke();
    end;

    [SendNotificationHandler]
    procedure NotificationHandler(var VerifyLineNotification: Notification): Boolean;
    var
        PriceListHeader: Record "Price List Header";
        PriceListManagement: Codeunit "Price List Management";
    begin
        LibraryVariableStorage.Enqueue(VerifyLineNotification.GetData(PriceListHeader.FieldName(Code)));
        // simulate action "Verify Lines" of notification
        PriceListManagement.ActivateDraftLines(VerifyLineNotification);
    end;

    [SendNotificationHandler]
    procedure NotificationHandlerSkipMessage(var VerifyLineNotification: Notification): Boolean;
    var
        PriceListHeader: Record "Price List Header";
        PriceListManagement: Codeunit "Price List Management";
    begin
        LibraryVariableStorage.Enqueue(VerifyLineNotification.GetData(PriceListHeader.FieldName(Code)));
        // simulate action "Verify Lines" of notification
        PriceListManagement.ActivateDraftLines(VerifyLineNotification, true);
    end;

    [SendNotificationHandler]
    procedure NotificationLineHandler(var VerifyLineNotification: Notification): Boolean;
    var
        PriceListHeader: Record "Price List Header";
    begin
        // Notification without 'Verify Lines' action
        Assert.IsFalse(VerifyLineNotification.HasData(PriceListHeader.FieldName(Code)), 'Notification.HasData');
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Msg);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price UX Management", 'OnAfterGetPriceSource', '', false, false)]
    local procedure OnAfterGetPriceSource(FromRecord: Variant; var PriceSourceList: Codeunit "Price Source List");
    var
        TempPriceSource: Record "Price Source" temporary;
    begin
        PriceSourceList.GetList(TempPriceSource);
        TempPriceSource.SetRange("Source No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(TempPriceSource.Count);
    end;
}