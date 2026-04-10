codeunit 132537 SelectionFilterManagementTest
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Selection Filter Management]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCurrency()
    var
        Currency: Record Currency;
        SelectionString: Text;
    begin
        if not Currency.FindFirst() then begin
            Currency.Init();
            Currency.Code := '1';
            Currency.Insert();
        end;
        Currency.Mark(true);
        Currency.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(Currency.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCurrency(Currency));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomerPriceGroup()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        SelectionString: Text;
    begin
        if not CustomerPriceGroup.FindFirst() then begin
            CustomerPriceGroup.Init();
            CustomerPriceGroup.Code := '1';
            CustomerPriceGroup.Insert();
        end;
        CustomerPriceGroup.Mark(true);
        CustomerPriceGroup.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(CustomerPriceGroup.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCustomerPriceGroup(CustomerPriceGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForLocation()
    var
        Location: Record Location;
        SelectionString: Text;
    begin
        if not Location.FindFirst() then begin
            Location.Init();
            Location.Code := '1';
            Location.Insert();
        end;
        Location.Mark(true);
        Location.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(Location.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForLocation(Location));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForGLAccount()
    var
        GLAccount: Record "G/L Account";
        SelectionString: Text;
    begin
        if not GLAccount.FindFirst() then begin
            GLAccount.Init();
            GLAccount."No." := '1';
            GLAccount.Insert();
        end;
        GLAccount.Mark(true);
        GLAccount.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(GLAccount."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForGLAccount(GLAccount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomer()
    var
        Customer: Record Customer;
        SelectionString: Text;
    begin
        if not Customer.FindFirst() then begin
            Customer.Init();
            Customer."No." := '1';
            Customer.Insert();
        end;
        Customer.Mark(true);
        Customer.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(Customer."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCustomer(Customer));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForContact()
    var
        Contact: Record Contact;
        SelectionString: Text;
    begin
        if not Contact.FindFirst() then begin
            Contact.Init();
            Contact."No." := '1';
            Contact.Insert();
        end;
        Contact.Mark(true);
        Contact.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(Contact."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForContact(Contact));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForVendor()
    var
        Vendor: Record Vendor;
        SelectionString: Text;
    begin
        if not Vendor.FindFirst() then begin
            Vendor.Init();
            Vendor."No." := '1';
            Vendor.Insert();
        end;
        Vendor.Mark(true);
        Vendor.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(Vendor."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForVendor(Vendor));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForItem()
    var
        Item: Record Item;
        SelectionString: Text;
    begin
        if not Item.FindFirst() then begin
            Item.Init();
            Item."No." := '1';
            Item.Insert();
        end;
        Item.Mark(true);
        Item.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(Item."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForItem(Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForResource()
    var
        Resource: Record Resource;
        SelectionString: Text;
    begin
        if not Resource.FindFirst() then begin
            Resource.Init();
            Resource."No." := '1';
            Resource.Insert();
        end;
        Resource.Mark(true);
        Resource.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(Resource."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForResource(Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForInventoryPostingGroup()
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        SelectionString: Text;
    begin
        if not InventoryPostingGroup.FindFirst() then begin
            InventoryPostingGroup.Init();
            InventoryPostingGroup.Code := '1';
            InventoryPostingGroup.Insert();
        end;
        InventoryPostingGroup.Mark(true);
        InventoryPostingGroup.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(InventoryPostingGroup.Code);

        CheckGetSelectionResults(
          SelectionString, SelectionFilterManagement.GetSelectionFilterForInventoryPostingGroup(InventoryPostingGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForGLBudgetName()
    var
        GLBudgetName: Record "G/L Budget Name";
        SelectionString: Text;
    begin
        if not GLBudgetName.FindFirst() then begin
            GLBudgetName.Init();
            GLBudgetName.Name := '1';
            GLBudgetName.Insert();
        end;
        GLBudgetName.Mark(true);
        GLBudgetName.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(GLBudgetName.Name);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForGLBudgetName(GLBudgetName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForBusinessUnit()
    var
        BusinessUnit: Record "Business Unit";
        SelectionString: Text;
    begin
        if not BusinessUnit.FindFirst() then begin
            BusinessUnit.Init();
            BusinessUnit.Code := '1';
            BusinessUnit.Insert();
        end;
        BusinessUnit.Mark(true);
        BusinessUnit.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(BusinessUnit.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForBusinessUnit(BusinessUnit));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomerDiscountGroup()
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
        SelectionString: Text;
    begin
        if not CustomerDiscountGroup.FindFirst() then begin
            CustomerDiscountGroup.Init();
            CustomerDiscountGroup.Code := '1';
            CustomerDiscountGroup.Insert();
        end;
        CustomerDiscountGroup.Mark(true);
        CustomerDiscountGroup.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(CustomerDiscountGroup.Code);

        CheckGetSelectionResults(
          SelectionString, SelectionFilterManagement.GetSelectionFilterForCustomerDiscountGroup(CustomerDiscountGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForItemDiscountGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        SelectionString: Text;
    begin
        if not ItemDiscountGroup.FindFirst() then begin
            ItemDiscountGroup.Init();
            ItemDiscountGroup.Code := '1';
            ItemDiscountGroup.Insert();
        end;
        ItemDiscountGroup.Mark(true);
        ItemDiscountGroup.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(ItemDiscountGroup.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForItemDiscountGroup(ItemDiscountGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForItemCategory()
    var
        ItemCategory: Record "Item Category";
        SelectionString: Text;
    begin
        if not ItemCategory.FindFirst() then begin
            ItemCategory.Init();
            ItemCategory.Code := '1';
            ItemCategory.Insert();
        end;
        ItemCategory.Mark(true);
        ItemCategory.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(ItemCategory.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForItemCategory(ItemCategory));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForDimensionValue()
    var
        DimensionValue: Record "Dimension Value";
        SelectionString: Text;
    begin
        if not DimensionValue.FindFirst() then begin
            DimensionValue.Init();
            DimensionValue.Code := '1';
            DimensionValue.Insert();
        end;
        DimensionValue.Mark(true);
        DimensionValue.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(DimensionValue.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForDimensionValue(DimensionValue));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddQuotesTest()
    var
        TestString: Text;
        ActualString: Text;
        ExpectedString: Text;
    begin
        TestString := 'NormalString';
        ExpectedString := TestString;
        ActualString := SelectionFilterManagement.AddQuotes(TestString);

        Assert.AreEqual(ExpectedString, ActualString, '');

        TestString := 'Single''NoSpecialChar';
        ExpectedString := 'Single''''NoSpecialChar';
        ActualString := SelectionFilterManagement.AddQuotes(TestString);

        Assert.AreEqual(ExpectedString, ActualString, '');

        TestString := 'String with single '' quotes';
        ExpectedString := '''String with single '''' quotes''';
        ActualString := SelectionFilterManagement.AddQuotes(TestString);

        Assert.AreEqual(ExpectedString, ActualString, '');

        TestString := 'String with special char: %&';
        ExpectedString := '''String with special char: %&''';
        ActualString := SelectionFilterManagement.AddQuotes(TestString);

        Assert.AreEqual(ExpectedString, ActualString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetSelectionFilterForDimensionValueWithSpecialSymbols()
    var
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Dimension] [Dimension Value] [UT]
        // [SCENARIO 312912] Function GetSelectionFilterForDimensionValue of SelectionFilterManagement puts Dimension Value Code between single quotes in case Code contains chars &.@<>=

        // [GIVEN] Dimension Values A, A1, B, B1, C, C1, D, D1, E with Code, that contains chars &.@<>=
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK&N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK&X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK.N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK.X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK@N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK@X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK<>N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK<X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK=N7S', LibraryERM.GetGlobalDimensionCode(1));

        // [WHEN] Filter Dimension Value to "A|B|C|D|E". Run GetSelectionFilterForDimensionValue of SelectionFilterManagement codeunit on the filtered record.
        // [THEN] Function returns "'A'|'B'|'C'|'D'|'E'", i.e. each Dimension Value Code is put between single quotes.
        DimensionValue.SetFilter(Code, '*N7S');
        Assert.AreEqual(
          '''XK&N7S''|''XK.N7S''|''XK@N7S''|''XK<>N7S''|''XK=N7S''',
          SelectionFilterManagement.GetSelectionFilterForDimensionValue(DimensionValue), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForICPartner()
    var
        ICPartner: Record "IC Partner";
        SelectionString: Text;
    begin
        if not ICPartner.FindFirst() then begin
            ICPartner.Init();
            ICPartner.Code := '1';
            ICPartner.Insert();
        end;
        ICPartner.Mark(true);
        ICPartner.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(ICPartner.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForICPartner(ICPartner));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCashFlow()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SelectionString: Text;
    begin
        if not CashFlowForecast.FindFirst() then begin
            CashFlowForecast.Init();
            CashFlowForecast."No." := '1';
            CashFlowForecast.Insert();
        end;
        CashFlowForecast.Mark(true);
        CashFlowForecast.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(CashFlowForecast."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCashFlow(CashFlowForecast));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCashFlowAccount()
    var
        CashFlowAccount: Record "Cash Flow Account";
        SelectionString: Text;
    begin
        if not CashFlowAccount.FindFirst() then begin
            CashFlowAccount.Init();
            CashFlowAccount."No." := '1';
            CashFlowAccount.Insert();
        end;
        CashFlowAccount.Mark(true);
        CashFlowAccount.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(CashFlowAccount."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCashFlowAccount(CashFlowAccount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCostBudgetName()
    var
        CostBudgetName: Record "Cost Budget Name";
        SelectionString: Text;
    begin
        if not CostBudgetName.FindFirst() then begin
            CostBudgetName.Init();
            CostBudgetName.Name := '1';
            CostBudgetName.Insert();
        end;
        CostBudgetName.Mark(true);
        CostBudgetName.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(CostBudgetName.Name);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCostBudgetName(CostBudgetName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCostCenter()
    var
        CostCenter: Record "Cost Center";
        SelectionString: Text;
    begin
        if not CostCenter.FindFirst() then begin
            CostCenter.Init();
            CostCenter.Code := '1';
            CostCenter.Insert();
        end;
        CostCenter.Mark(true);
        CostCenter.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(CostCenter.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCostCenter(CostCenter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCostObject()
    var
        CostObject: Record "Cost Object";
        SelectionString: Text;
    begin
        if not CostObject.FindFirst() then begin
            CostObject.Init();
            CostObject.Code := '1';
            CostObject.Insert();
        end;
        CostObject.Mark(true);
        CostObject.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(CostObject.Code);

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCostObject(CostObject));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCostType()
    var
        CostType: Record "Cost Type";
        SelectionString: Text;
    begin
        if not CostType.FindFirst() then begin
            CostType.Init();
            CostType."No." := '1';
            CostType.Insert();
        end;
        CostType.Mark(true);
        CostType.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(CostType."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCostType(CostType));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCampaign()
    var
        Campaign: Record Campaign;
        SelectionString: Text;
    begin
        if not Campaign.FindFirst() then begin
            Campaign.Init();
            Campaign."No." := '1';
            Campaign.Insert();
        end;
        Campaign.Mark(true);
        Campaign.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(Campaign."No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForCampaign(Campaign));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForLotNoInformation()
    var
        LotNoInformation: Record "Lot No. Information";
        SelectionString: Text;
    begin
        if not LotNoInformation.FindFirst() then begin
            LotNoInformation.Init();
            LotNoInformation."Lot No." := '1';
            LotNoInformation.Insert();
        end;
        LotNoInformation.Mark(true);
        LotNoInformation.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(LotNoInformation."Lot No.");

        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilterForLotNoInformation(LotNoInformation));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForSerialNoInformation()
    var
        SerialNoInformation: Record "Serial No. Information";
        SelectionString: Text;
    begin
        if not SerialNoInformation.FindFirst() then begin
            SerialNoInformation.Init();
            SerialNoInformation."Serial No." := '1';
            SerialNoInformation.Insert();
        end;
        SerialNoInformation.Mark(true);
        SerialNoInformation.MarkedOnly(true);
        SelectionString := SelectionFilterManagement.AddQuotes(SerialNoInformation."Serial No.");

        CheckGetSelectionResults(
          SelectionString, SelectionFilterManagement.GetSelectionFilterForSerialNoInformation(SerialNoInformation));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromTempCustomerTableNotAllRecords()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
        Customers: List of [Code[20]];
        FilterString: Text;
        i: Integer;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Customer temporary table in case temporary table does not contain all Customer records.

        // [GIVEN] Customers C1, C2,..., C10. Customers C1, C2, C3, C5, C7, C8, C9, C10 are added to temporary Customer table.
        for i := 1 to 10 do begin
            LibrarySales.CreateCustomer(Customer);
            Customers.Add(Customer."No.");
            TempCustomer := Customer;
            TempCustomer.Insert();
        end;
        TempCustomer.SetFilter("No.", '%1|%2', Customers.Get(4), Customers.Get(6));
        TempCustomer.DeleteAll();
        TempCustomer.Reset();

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on temporary Customer table.
        TempRecRef.GetTable(TempCustomer);
        RecRef.GetTable(Customer);
        FilterString := SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Customer.FieldNo("No."));

        // [THEN] The function CreateFilterFromTempTable returns 'C1..C3|C5|C7..C10'.
        Assert.AreEqual(
            StrSubstNo('%1..%2|%3|%4..%5', Customers.Get(1), Customers.Get(3), Customers.Get(5), Customers.Get(7), Customers.Get(10)), FilterString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromTempVendorTableAllRecords()
    var
        Vendor: Record Vendor;
        TempVendor: Record Vendor temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
        Vendors: List of [Code[20]];
        FilterString: Text;
        i: Integer;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Vendor temporary table in case temporary table contains consecutive Vendor records.

        // [GIVEN] Vendors V1, V2,..., V5. All these Vendors are added to temporary Vendor table.
        for i := 1 to 5 do begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendors.Add(Vendor."No.");
            TempVendor := Vendor;
            TempVendor.Insert();
        end;

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on temporary Vendor table.
        TempRecRef.GetTable(TempVendor);
        RecRef.GetTable(Vendor);
        FilterString := SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Vendor.FieldNo("No."));

        // [THEN] The function CreateFilterFromTempTable returns 'V1..V5'.
        Assert.AreEqual(
            StrSubstNo('%1..%2', Vendors.Get(1), Vendors.Get(Vendors.Count())), FilterString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromTempItemTableNoConsecutiveRecords()
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
        Items: List of [Code[20]];
        FilterString: Text;
        i: Integer;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Item temporary table in case temporary table does not contain consecutive Item records.

        // [GIVEN] Items I1, I2,..., I7. Items I1, I3, I5, I7 are added to temporary Item table.
        for i := 1 to 7 do begin
            LibraryInventory.CreateItem(Item);
            Items.Add(Item."No.");
            TempItem := Item;
            TempItem.Insert();
        end;
        TempItem.SetFilter("No.", '%1|%2|%3', Items.Get(2), Items.Get(4), Items.Get(6));
        TempItem.DeleteAll();
        TempItem.Reset();

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on temporary Item table.
        TempRecRef.GetTable(TempItem);
        RecRef.GetTable(Item);
        FilterString := SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Item.FieldNo("No."));

        // [THEN] The function CreateFilterFromTempTable returns 'I1|I3|I5|I7'.
        Assert.AreEqual(
            StrSubstNo('%1|%2|%3|%4', Items.Get(1), Items.Get(3), Items.Get(5), Items.Get(7)), FilterString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromEmptyTempCustomerTable()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
        FilterString: Text;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Customer temporary table in case temporary table does not contain any records.

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on empty temporary Customer table.
        TempRecRef.GetTable(TempCustomer);
        RecRef.GetTable(Customer);
        FilterString := SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Customer.FieldNo("No."));

        // [THEN] The function CreateFilterFromTempTable returns empty string ''.
        Assert.AreEqual('', FilterString, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFilterFromTempCustomerTableRecordNotExist()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        TempRecRef: RecordRef;
        RecRef: RecordRef;
    begin
        // [SCENARIO 365286] Run CreateFilterFromTempTable function for Customer temporary table in case temporary table contains non-existing record.

        // [GIVEN] Temporary Customer table contains one existing record and one non-existing record.
        LibrarySales.CreateCustomer(Customer);
        TempCustomer := Customer;
        TempCustomer.Insert();

        Customer.Init();
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer.SetRecFilter();
        Assert.RecordIsEmpty(Customer);
        TempCustomer := Customer;
        TempCustomer.Insert();

        // [WHEN] Run CreateFilterFromTempTable of SelectionFilterManagement codeunit on temporary Customer table.
        TempRecRef.GetTable(TempCustomer);
        RecRef.GetTable(Customer);
        asserterror SelectionFilterManagement.CreateFilterFromTempTable(TempRecRef, RecRef, Customer.FieldNo("No."));

        // [THEN] An error "The Customer does not exist" is thrown.
        Assert.ExpectedErrorCannotFind(Database::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEither()
    begin
        ComplexTestForGetSelectionFilter('2|5', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInterval()
    begin
        ComplexTestForGetSelectionFilter('2..5', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEitherPlsInterval()
    begin
        ComplexTestForGetSelectionFilter('2|4..6', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIntervalPlsEither()
    begin
        ComplexTestForGetSelectionFilter('2..4|8', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEitherPlsIntervalPlsEither()
    begin
        ComplexTestForGetSelectionFilter('2|4..6|8', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSortingOfNonNumericCodes()
    begin
        // should pin bug 275352
        ComplexTestForGetSelectionFilter('2T..5', true);
    end;

    local procedure ComplexTestForGetSelectionFilter(SelectionString: Text; AddNonNumerical: Boolean)
    var
        SerialNoInformation: Record "Serial No. Information";
        ItemNo: Code[20];
    begin
        ItemNo := InsertTestValues();
        if AddNonNumerical then
            InsertSerialNoInformation(ItemNo, '2T');

        SerialNoInformation.SetFilter("Item No.", ItemNo);
        SerialNoInformation.SetFilter("Serial No.", SelectionString);
        repeat
            SerialNoInformation.Mark(true);
        until SerialNoInformation.Next() = 0;
        SerialNoInformation.SetRange("Serial No.");
        SerialNoInformation.SetRange("Item No.");
        SerialNoInformation.MarkedOnly(true);

        CheckGetSelectionResults(
          SelectionString, SelectionFilterManagement.GetSelectionFilterForSerialNoInformation(SerialNoInformation));
    end;

    local procedure CheckGetSelectionResults(SelectionString: Text; SelectionString2: Text)
    begin
        Assert.AreEqual(
          SelectionString,
          SelectionString2,
          StrSubstNo(
            'Problem with SelectionFilterManagement: \Original selection: <%1>. \Returned selection: <%2>',
            SelectionString, SelectionString2));
    end;

    local procedure InsertSerialNoInformation(ItemNo: Code[20]; SerialNo: Code[50])
    var
        SerialNoInformation: Record "Serial No. Information";
    begin
        SerialNoInformation.Init();
        SerialNoInformation."Item No." := ItemNo;
        SerialNoInformation."Serial No." := SerialNo;
        SerialNoInformation.Insert();
    end;

    local procedure InsertTestValues(): Code[20]
    var
        SerialNoInformation: Record "Serial No. Information";
        Item: Record Item;
        ItemNo: Code[20];
        i: Integer;
    begin
        SerialNoInformation.DeleteAll();
        Item.FindSet();
        Item.Next(LibraryRandom.RandInt(Item.Count));
        ItemNo := Item."No.";
        for i := 1 to 8 do
            InsertSerialNoInformation(ItemNo, Format(i));

        exit(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomerComputingRangesOnLists()
    var
        Customer: Record Customer;
        CurrencyRecordRef: RecordRef;
        SelectionString: Text;
    begin
        // [SCENARIO] GetSelectionFilter procedure can be used to get the filter on the primary key from the selected (marked) records.

        // [GIVEN] A table (Currency) with at least 1 record
        if not Customer.FindFirst() then begin
            Customer.Init();
            Customer."No." := 'ABC';
            Customer.Insert();
        end;

        // [WHEN] A record in the table is selected (marked).
        Customer.Mark(true);
        Customer.MarkedOnly(true);
        CurrencyRecordRef.GetTable(Customer);

        // [THEN] The filter consists of just one value - the primary key field value of the selected record (Currency.Code).
        SelectionString := SelectionFilterManagement.AddQuotes(Customer."No.");
        CheckGetSelectionResults(SelectionString, SelectionFilterManagement.GetSelectionFilter(CurrencyRecordRef, Customer.FieldNo("No."), false));
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetSelectionFilterForDimensionValueWithSpecialSymbolsComputingRangesOnLists()
    var
        DimensionValue: Record "Dimension Value";
        DimensionValueRecordRef: RecordRef;
    begin
        // [FEATURE] [Dimension] [Dimension Value] [UT]
        // [SCENARIO 312912] Function GetSelectionFilterForDimensionValue of SelectionFilterManagement puts Dimension Value Code between single quotes in case Code contains chars &.@<>=

        // [GIVEN] Dimension Values A, A1, B, B1, C, C1, D, D1, E with Code, that contains chars &.@<>=
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK&N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK&X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK.N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK.X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK@N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK@X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK<>N7S', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK<X', LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, 'XK=N7S', LibraryERM.GetGlobalDimensionCode(1));

        // [WHEN] Filter Dimension Value to "A|B|C|D|E". Run GetSelectionFilterForDimensionValue of SelectionFilterManagement codeunit on the filtered record.
        // [THEN] Function returns "'A'|'B'|'C'|'D'|'E'", i.e. each Dimension Value Code is put between single quotes.
        DimensionValue.SetFilter(Code, '*N7S');
        DimensionValueRecordRef.GetTable(DimensionValue);
        Assert.AreEqual(
          '''XK&N7S''|''XK.N7S''|''XK@N7S''|''XK<>N7S''|''XK=N7S''',
          SelectionFilterManagement.GetSelectionFilter(DimensionValueRecordRef, DimensionValue.FieldNo(Code), false), '');
    end;
}

