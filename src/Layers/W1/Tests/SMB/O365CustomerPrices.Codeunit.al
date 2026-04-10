codeunit 138020 "O365 Customer Prices"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Price and Line Discount] [SMB] [Sales]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        CustomerTempl: Record "Customer Templ.";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Customer Prices");
        LibraryVariableStorage.Clear();
        CustomerTempl.DeleteAll(true);
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Customer Prices");

        LibraryTemplates.EnableTemplatesFeature();
        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Customer Prices");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Job: Record Job;
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Res. Ledger Entry":
                ResLedgerEntry.DeleteAll();
            DATABASE::Job:
                Job.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [Test]
    [HandlerFunctions('ShowItemPage')]
    [Scope('OnPrem')]
    procedure OpenSMBItemList()
    var
        Item: Record Item;
        SalesPriceAndLineDiscountsTestPage: TestPage "Sales Price and Line Discounts";
        SalesPriceAndLineDiscountsPage: Page "Sales Price and Line Discounts";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);
        SalesPriceAndLineDiscountsPage.LoadItem(Item);
        SalesPriceAndLineDiscountsTestPage.Trap();
        SalesPriceAndLineDiscountsPage.Run();
        SalesPriceAndLineDiscountsTestPage.Code.Lookup(); // handled by ShowItemPage
        SalesPriceAndLineDiscountsPage.Close();
    end;

    [Test]
    [HandlerFunctions('ShowItemDiscGroupsPage')]
    [Scope('OnPrem')]
    procedure OpenSMBItemDiscGroupList()
    var
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        SalesPriceAndLineDiscounts: TestPage "Sales Price and Line Discounts";
        SalesPriceAndLineDiscountsPage: Page "Sales Price and Line Discounts";
    begin
        Initialize();

        ItemDiscountGroup.Init();
        ItemDiscountGroup.Code := LibraryUtility.GenerateGUID();
        ItemDiscountGroup.Insert();

        Item.Init();
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        Item.Insert(true);

        SalesLineDiscount.Init();
        SalesLineDiscount.Code := Item."No.";
        SalesLineDiscount.Type := SalesLineDiscount.Type::Item;
        SalesLineDiscount."Sales Type" := SalesLineDiscount."Sales Type"::"All Customers";
        SalesLineDiscount.Insert(true);

        SalesPriceAndLineDiscountsPage.LoadItem(Item);
        SalesPriceAndLineDiscounts.Trap();
        SalesPriceAndLineDiscountsPage.Run();
        SalesPriceAndLineDiscounts."Line Type".Value :=
          Format(SalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount");
        SalesPriceAndLineDiscounts.Type.Value := Format(SalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        SalesPriceAndLineDiscounts.Code.Lookup(); // handled by ShowItemDiscGroupsPage
        SalesPriceAndLineDiscounts.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_RenameRecord()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Customer);
        TempSalesPriceAndLineDiscBuff.FindFirst();
        TempSalesPriceAndLineDiscBuff.Rename(
          TempSalesPriceAndLineDiscBuff."Line Type", TempSalesPriceAndLineDiscBuff.Type, TempSalesPriceAndLineDiscBuff.Code, TempSalesPriceAndLineDiscBuff."Sales Type", 'TEST',
          TempSalesPriceAndLineDiscBuff."Starting Date", TempSalesPriceAndLineDiscBuff."Currency Code", TempSalesPriceAndLineDiscBuff."Variant Code",
          TempSalesPriceAndLineDiscBuff."Unit of Measure Code", TempSalesPriceAndLineDiscBuff."Minimum Quantity", TempSalesPriceAndLineDiscBuff."Loaded Item No.",
          TempSalesPriceAndLineDiscBuff."Loaded Disc. Group", TempSalesPriceAndLineDiscBuff."Loaded Customer No.", TempSalesPriceAndLineDiscBuff."Loaded Price Group");

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::"All Customers");
        TempSalesPriceAndLineDiscBuff.FindFirst();
        TempSalesPriceAndLineDiscBuff.Rename(
          TempSalesPriceAndLineDiscBuff."Line Type", TempSalesPriceAndLineDiscBuff.Type, TempSalesPriceAndLineDiscBuff.Code, TempSalesPriceAndLineDiscBuff."Sales Type", '',
          TempSalesPriceAndLineDiscBuff."Starting Date", TempSalesPriceAndLineDiscBuff."Currency Code", TempSalesPriceAndLineDiscBuff."Variant Code",
          TempSalesPriceAndLineDiscBuff."Unit of Measure Code", TempSalesPriceAndLineDiscBuff."Minimum Quantity", TempSalesPriceAndLineDiscBuff."Loaded Item No.",
          TempSalesPriceAndLineDiscBuff."Loaded Disc. Group", TempSalesPriceAndLineDiscBuff."Loaded Customer No.", '2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_RenameRecord_Neg()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Customer);
        TempSalesPriceAndLineDiscBuff.FindFirst();
        asserterror
          TempSalesPriceAndLineDiscBuff.Rename(
            TempSalesPriceAndLineDiscBuff."Line Type", TempSalesPriceAndLineDiscBuff.Type, TempSalesPriceAndLineDiscBuff.Code, TempSalesPriceAndLineDiscBuff."Sales Type", '',
            TempSalesPriceAndLineDiscBuff."Starting Date", TempSalesPriceAndLineDiscBuff."Currency Code", TempSalesPriceAndLineDiscBuff."Variant Code",
            TempSalesPriceAndLineDiscBuff."Unit of Measure Code", TempSalesPriceAndLineDiscBuff."Minimum Quantity", TempSalesPriceAndLineDiscBuff."Loaded Item No.",
            TempSalesPriceAndLineDiscBuff."Loaded Disc. Group", TempSalesPriceAndLineDiscBuff."Loaded Customer No.", TempSalesPriceAndLineDiscBuff."Loaded Price Group");

        Assert.ExpectedError('Sales Code must have a value in');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Dates()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff.Validate("Starting Date", Today);
        TempSalesPriceAndLineDiscBuff.Validate("Ending Date", Today);

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Dates_Neg()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff.Validate("Starting Date", Today - 1);
        asserterror
          TempSalesPriceAndLineDiscBuff.Validate("Ending Date", Today - 2);
        Assert.ExpectedError('Starting Date cannot be after Ending Date.');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Type4Item()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Loaded Item No." := Item."No.";
        TempSalesPriceAndLineDiscBuff.Validate(Type, TempSalesPriceAndLineDiscBuff.Type::Item);

        Assert.AreEqual(Item."No.", TempSalesPriceAndLineDiscBuff.Code, 'Wrong Code.');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Type4ItemDiscGr()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Loaded Item No." := Item."No.";
        TempSalesPriceAndLineDiscBuff."Loaded Disc. Group" := 'G' + Format(LibraryRandom.RandInt(1000));
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount";

        asserterror
          TempSalesPriceAndLineDiscBuff.Validate(Type, TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        Assert.ExpectedError('that cannot be found in the related table');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Type4ItemDiscGr_Neg()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Loaded Item No." := Item."No.";
        TempSalesPriceAndLineDiscBuff."Loaded Disc. Group" := '';

        asserterror
          TempSalesPriceAndLineDiscBuff.Validate(Type, TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        Assert.ExpectedError('This item is not assigned to any discount group, therefore a discount group could not be used');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Code_TypeItem()
    var
        Item: Record Item;
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Item.Init();
        Item."Sales Unit of Measure" := 'UM' + Format(LibraryRandom.RandInt(100));
        Item.Insert(true);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        TempSalesPriceAndLineDiscBuff.SetRange(Type, TempSalesPriceAndLineDiscBuff.Type::Item);
        TempSalesPriceAndLineDiscBuff.FindFirst();
        TempSalesPriceAndLineDiscBuff.Validate(Code, Item."No.");

        Assert.AreEqual(Item."Sales Unit of Measure", TempSalesPriceAndLineDiscBuff."Unit of Measure Code", 'Unit of Measure Code was not updated from Item');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Code_LineTypeSalesPrice1()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        CustPriceGr: Record "Customer Price Group";
    begin
        Initialize();

        CreateCustPriceGr(CustPriceGr);

        Item.Init();
        Item.Insert(true);

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price";
        TempSalesPriceAndLineDiscBuff."Sales Type" := TempSalesPriceAndLineDiscBuff."Sales Type"::"Customer Price/Disc. Group";
        TempSalesPriceAndLineDiscBuff."Sales Code" := CustPriceGr.Code;
        TempSalesPriceAndLineDiscBuff."Allow Invoice Disc." := CustPriceGr."Allow Invoice Disc.";

        TempSalesPriceAndLineDiscBuff."Unit of Measure Code" := 'UMC';
        TempSalesPriceAndLineDiscBuff."Variant Code" := 'VC';

        TempSalesPriceAndLineDiscBuff.Validate(Code, Item."No.");

        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff."Unit of Measure Code", 'Unit of Measure Code should be removed.');
        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff."Variant Code", 'Variant Code should be removed.');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Code_LineTypeSalesPrice2()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        Item.Init();
        Item."Allow Invoice Disc." := true;
        Item."Price Includes VAT" := true;
        Item."VAT Bus. Posting Gr. (Price)" := 'VAT_G' + Format(LibraryRandom.RandInt(1000));
        Item.Insert(true);

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price";
        TempSalesPriceAndLineDiscBuff."Sales Type" := TempSalesPriceAndLineDiscBuff."Sales Type"::Customer;

        TempSalesPriceAndLineDiscBuff."Allow Invoice Disc." := false;
        TempSalesPriceAndLineDiscBuff."Price Includes VAT" := false;
        TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)" := 'V';

        TempSalesPriceAndLineDiscBuff.Validate(Code, Item."No.");

        Assert.AreEqual(Item."Allow Invoice Disc.", TempSalesPriceAndLineDiscBuff."Allow Invoice Disc.", 'Wrong Allow Invoice Disc.');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_Code_LineTypeSalesPrice3()
    var
        Item: Record Item;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        Item.Init();
        Item."Allow Invoice Disc." := true;
        Item."Price Includes VAT" := true;
        Item."VAT Bus. Posting Gr. (Price)" := 'VAT_G' + Format(LibraryRandom.RandInt(1000));
        Item.Insert(true);

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price";
        TempSalesPriceAndLineDiscBuff."Sales Type" := TempSalesPriceAndLineDiscBuff."Sales Type"::"All Customers";

        TempSalesPriceAndLineDiscBuff."Allow Invoice Disc." := false;
        TempSalesPriceAndLineDiscBuff."Price Includes VAT" := false;
        TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)" := 'V';

        TempSalesPriceAndLineDiscBuff.Validate(Code, Item."No.");

        Assert.AreEqual(Item."Allow Invoice Disc.", TempSalesPriceAndLineDiscBuff."Allow Invoice Disc.",
          'Wrong "Allow Invoice Disc."');
        Assert.AreEqual(Item."Price Includes VAT", TempSalesPriceAndLineDiscBuff."Price Includes VAT",
          'Wrong "Price Includes VAT"');
        Assert.AreEqual(
          Item."VAT Bus. Posting Gr. (Price)",
          TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)",
          'Wrong "VAT Bus. Posting Gr. (Price)"');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesType_Customer()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" := 10;
        TempSalesPriceAndLineDiscBuff."Sales Code" := 'SC' + Format(LibraryRandom.RandInt(1000));

        TempSalesPriceAndLineDiscBuff.Validate("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Customer);

        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff."Sales Code", 'Wrong "Sales Code"');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesType_AllCustomer()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" := 10;
        TempSalesPriceAndLineDiscBuff."Sales Code" := 'SC' + Format(LibraryRandom.RandInt(1000));

        TempSalesPriceAndLineDiscBuff.Validate("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::"All Customers");

        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff."Sales Code", 'Wrong "Sales Code"');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesType_PriceDiscGr()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" := 10;
        TempSalesPriceAndLineDiscBuff."Sales Code" := 'SC' + Format(LibraryRandom.RandInt(1000));
        TempSalesPriceAndLineDiscBuff."Loaded Customer No." := '';

        TempSalesPriceAndLineDiscBuff.Validate("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::"Customer Price/Disc. Group");

        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff."Sales Code", 'Wrong "Sales Code"');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesType_SalesPrice()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" := 10;
        TempSalesPriceAndLineDiscBuff."Loaded Customer No." := 'LCN' + Format(LibraryRandom.RandInt(1000));
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price";
        TempSalesPriceAndLineDiscBuff."Loaded Price Group" := 'G' + Format(LibraryRandom.RandInt(1000));
        TempSalesPriceAndLineDiscBuff."Loaded Disc. Group" := '';

        asserterror
          TempSalesPriceAndLineDiscBuff.Validate("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::"Customer Price/Disc. Group");
        Assert.ExpectedError('that cannot be found in the related table');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesType_SalesPrice_Neg()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" := 10;
        TempSalesPriceAndLineDiscBuff."Loaded Customer No." := 'LCN' + Format(LibraryRandom.RandInt(1000));
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price";
        TempSalesPriceAndLineDiscBuff."Loaded Price Group" := '';
        TempSalesPriceAndLineDiscBuff."Loaded Disc. Group" := '';

        asserterror
          TempSalesPriceAndLineDiscBuff.Validate("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::"Customer Price/Disc. Group");
        Assert.ExpectedError('This customer is not assigned to any price group, therefore a price group could not be used');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesType_SalesDisc()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" := 10;
        TempSalesPriceAndLineDiscBuff."Loaded Customer No." := 'LCN' + Format(LibraryRandom.RandInt(1000));
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount";
        TempSalesPriceAndLineDiscBuff."Loaded Price Group" := '';
        TempSalesPriceAndLineDiscBuff."Loaded Disc. Group" := 'G' + Format(LibraryRandom.RandInt(1000));

        asserterror
          TempSalesPriceAndLineDiscBuff.Validate("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::"Customer Price/Disc. Group");
        Assert.ExpectedError('that cannot be found in the related table');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesType_SalesDisc_Neg()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" := 10;
        TempSalesPriceAndLineDiscBuff."Loaded Customer No." := 'LCN' + Format(LibraryRandom.RandInt(1000));
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount";
        TempSalesPriceAndLineDiscBuff."Loaded Price Group" := '';
        TempSalesPriceAndLineDiscBuff."Loaded Disc. Group" := '';

        asserterror
          TempSalesPriceAndLineDiscBuff.Validate("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::"Customer Price/Disc. Group");
        Assert.ExpectedError('This customer is not assigned to any discount group, therefore a discount group could not be used');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesCode4AllCust()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" :=
          TempSalesPriceAndLineDiscBuff."Sales Type"::"All Customers";

        asserterror
          TempSalesPriceAndLineDiscBuff.Validate("Sales Code", 'R');
        Assert.ExpectedError('Sales Code must be blank.');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesCode4Group()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        CustPriceGr: Record "Customer Price Group";
    begin
        Initialize();

        CreateCustPriceGr(CustPriceGr);

        TempSalesPriceAndLineDiscBuff."Sales Type" :=
          TempSalesPriceAndLineDiscBuff."Sales Type"::"Customer Price/Disc. Group";
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price";

        TempSalesPriceAndLineDiscBuff."Price Includes VAT" := false;
        TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)" := '';
        TempSalesPriceAndLineDiscBuff."Allow Line Disc." := false;
        TempSalesPriceAndLineDiscBuff."Allow Invoice Disc." := false;

        TempSalesPriceAndLineDiscBuff.Validate("Sales Code", CustPriceGr.Code);

        Assert.AreEqual(CustPriceGr."Price Includes VAT", TempSalesPriceAndLineDiscBuff."Price Includes VAT", 'Wrong "Price Includes VAT"');
        Assert.AreEqual(
          CustPriceGr."VAT Bus. Posting Gr. (Price)", TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Gr. (Price)"');
        Assert.AreEqual(CustPriceGr."Allow Line Disc.", TempSalesPriceAndLineDiscBuff."Allow Line Disc.", 'Wrong "Allow Line Disc."');
        Assert.AreEqual(CustPriceGr."Allow Invoice Disc.", TempSalesPriceAndLineDiscBuff."Allow Invoice Disc.", 'Wrong "Allow Invoice Disc."');

        TempSalesPriceAndLineDiscBuff.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_SalesCode4Cust()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        Customer.Init();
        Customer."Currency Code" := 'CC';
        Customer."Prices Including VAT" := true;
        Customer."VAT Bus. Posting Group" := 'VAT';
        Customer."Allow Line Disc." := true;
        Customer.Insert(true);

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff."Sales Type" := TempSalesPriceAndLineDiscBuff."Sales Type"::Customer;
        TempSalesPriceAndLineDiscBuff."Sales Code" := Customer."No.";
        TempSalesPriceAndLineDiscBuff."Line Type" := TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price";

        TempSalesPriceAndLineDiscBuff.Validate("Sales Code", Customer."No.");

        Assert.AreEqual(
          Customer."Currency Code", TempSalesPriceAndLineDiscBuff."Currency Code", 'Wrong "Currency Code"');
        Assert.AreEqual(
          Customer."Prices Including VAT", TempSalesPriceAndLineDiscBuff."Price Includes VAT", 'Wrong "Prices Including VAT"');
        Assert.AreEqual(
          Customer."VAT Bus. Posting Group", TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)", 'Wrong "VAT Bus. Posting Group"');
        Assert.AreEqual(
          Customer."Allow Line Disc.", TempSalesPriceAndLineDiscBuff."Allow Line Disc.", 'Wrong "Allow Line Disc."');

        TempSalesPriceAndLineDiscBuff.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_UnitOfMeasureCode()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Type := TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group";
        asserterror
          TempSalesPriceAndLineDiscBuff.Validate("Unit of Measure Code", 'V');

        Assert.ExpectedTestFieldError(Format(TempSalesPriceAndLineDiscBuff.Type), '');

        TempSalesPriceAndLineDiscBuff.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTrigger_VariantCode()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        TempSalesPriceAndLineDiscBuff.Init();
        TempSalesPriceAndLineDiscBuff.Type := TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group";
        asserterror
          TempSalesPriceAndLineDiscBuff.Validate("Variant Code", 'V');
        Assert.ExpectedTestFieldError(Format(TempSalesPriceAndLineDiscBuff.Type), '');

        TempSalesPriceAndLineDiscBuff.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Validate_FilterToActualRecords()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ExpectedCount: Integer;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        TempSalesPriceAndLineDiscBuff.FilterToActualRecords();
        ExpectedCount := TempSalesPriceAndLineDiscBuff.Count;

        TempSalesPriceAndLineDiscBuff.FindFirst();
        TempSalesPriceAndLineDiscBuff."Ending Date" := Today - 1;
        TempSalesPriceAndLineDiscBuff.Modify(true);

        TempSalesPriceAndLineDiscBuff.Reset();
        TempSalesPriceAndLineDiscBuff.FilterToActualRecords();
        Assert.AreEqual(ExpectedCount - 1, TempSalesPriceAndLineDiscBuff.Count, 'Wrong filter after run FilterToActualRecords');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifyFieldVisibilityOnSalesPriceAndLineDiscountsPageHandler')]
    procedure Validate_PageInit4CustCard()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();
        ClearTable(DATABASE::Job);
        ClearTable(DATABASE::"Res. Ledger Entry");

        CustomerCard.OpenNew();
        CustomerCard."Prices and Discounts Overview".Invoke();

        // Verification is done in the modal page handler
        CustomerCard.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustHasLines_Neg()
    var
        Cust: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();

        CreateBlankCustomer(Cust);
        SalesPrice.DeleteAll();
        SalesLineDiscount.DeleteAll();

        Assert.IsFalse(SalesPriceAndLineDiscBuff.CustHasLines(Cust), 'Customer should not have lines in Prices and Disc');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustHasLines_AllCustOnSalesDisc()
    var
        Cust: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();

        CreateBlankCustomer(Cust);
        SalesPrice.DeleteAll();
        SalesLineDiscount.DeleteAll();

        CreateSalesLineDiscountLine(Cust."No.", SalesLineDiscount.Type::Item, false);

        Assert.IsTrue(SalesPriceAndLineDiscBuff.CustHasLines(Cust), 'Customer should have lines in Prices and Disc');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustHasLines_AllCustOnSalesPrice()
    var
        Cust: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();

        CreateBlankCustomer(Cust);
        SalesPrice.DeleteAll();
        SalesLineDiscount.DeleteAll();

        CreateSalesLineDiscountLine(GetDiscGroupCode(Cust."No."), SalesLineDiscount.Type::"Item Disc. Group", false);

        Assert.IsTrue(SalesPriceAndLineDiscBuff.CustHasLines(Cust), 'Customer should have lines in Prices and Disc');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustHasLines_CustOnSalesPrice()
    var
        Cust: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();

        CreateBlankCustomer(Cust);
        SalesPrice.DeleteAll();
        SalesLineDiscount.DeleteAll();

        SalesPrice.Init();
        SalesPrice."Sales Type" := SalesPrice."Sales Type"::Customer;
        SalesPrice."Sales Code" := Cust."No.";
        SalesPrice.Insert();

        Assert.IsTrue(SalesPriceAndLineDiscBuff.CustHasLines(Cust), 'Customer should have lines in Prices and Disc');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustHasLines_CustOnSalesDisc()
    var
        Cust: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();

        CreateBlankCustomer(Cust);
        SalesPrice.DeleteAll();
        SalesLineDiscount.DeleteAll();

        SalesLineDiscount.Init();
        SalesLineDiscount."Sales Type" := SalesLineDiscount."Sales Type"::Customer;
        SalesLineDiscount."Sales Code" := Cust."No.";
        SalesLineDiscount.Insert();

        Assert.IsTrue(SalesPriceAndLineDiscBuff.CustHasLines(Cust), 'Customer should have lines in Prices and Disc');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustHasLines_CustOnSalesPriceGr()
    var
        Cust: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Cust);
        Cust."Customer Price Group" := GetPriceGroupCode(Cust."No.");
        Cust.Modify();

        SalesPrice.DeleteAll();
        SalesLineDiscount.DeleteAll();

        SalesPrice.Init();
        SalesPrice."Sales Type" := SalesPrice."Sales Type"::"Customer Price Group";
        SalesPrice."Sales Code" := GetPriceGroupCode(Cust."No.");
        SalesPrice.Insert();

        Assert.IsTrue(SalesPriceAndLineDiscBuff.CustHasLines(Cust), 'Customer should have lines in Prices and Disc');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustHasLines_CustOnSalesDiscGr()
    var
        Cust: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        SalesPrice: Record "Sales Price";
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Cust);
        Cust."Customer Disc. Group" := GetDiscGroupCode(Cust."No.");
        Cust.Modify();

        SalesPrice.DeleteAll();
        SalesLineDiscount.DeleteAll();

        SalesLineDiscount.Init();
        SalesLineDiscount."Sales Type" := SalesLineDiscount."Sales Type"::"Customer Disc. Group";
        SalesLineDiscount."Sales Code" := GetDiscGroupCode(Cust."No.");
        SalesLineDiscount.Insert();

        Assert.IsTrue(SalesPriceAndLineDiscBuff.CustHasLines(Cust), 'Customer should have lines in Prices and Disc');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SafeReset()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        CreateBlankCustomer(Customer);
        Customer."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        Customer."Customer Disc. Group" := GetDiscGroupCode(Customer."No.");
        Customer.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        TempSalesPriceAndLineDiscBuff.SetRange("Unit Price", LibraryRandom.RandDec(10, 2));
        TempSalesPriceAndLineDiscBuff.Reset();

        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff."Loaded Item No.", '<Item No.> incorrect');
        Assert.AreEqual(Customer."No.", TempSalesPriceAndLineDiscBuff."Loaded Customer No.", '<Customer No.> was reseted');
        Assert.AreEqual(
          Customer."Customer Disc. Group", TempSalesPriceAndLineDiscBuff."Loaded Disc. Group", '<Disc. Group> was reseted');
        Assert.AreEqual(
          Customer."Customer Price Group", TempSalesPriceAndLineDiscBuff."Loaded Price Group", '<Price Group> was reseted');

        Assert.AreEqual('', TempSalesPriceAndLineDiscBuff.GetFilters, 'Filters was not removed');

        if TempSalesPriceAndLineDiscBuff.Insert() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyLoad()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        // nor rec check;
        Initialize();

        InitCustomerAndDiscAndPrices(Customer1);
        CreateBlankCustomer(Customer2);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer2);
        TempSalesPriceAndLineDiscBuff.SetFilter("Sales Type", '<>%1', TempSalesPriceAndLineDiscBuff."Sales Type"::"All Customers");
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Incorrect load. TempSalesPriceAndLineDiscBuff should be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BasicDiscLinesInsertedIntoBufferForCustomer()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesLineDiscount4Cust: Record "Sales Line Discount";
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        GetSLDiscountsForCustomer(SalesLineDiscount4Cust, Customer);
        CompareBuffAgainstDiscLines(SalesLineDiscount4Cust, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BasicDiscLinesInsertedIntoBufferForAllCustomer()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesLineDiscount4AllCust: Record "Sales Line Discount";
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        GetSLDiscountsForAllCustomers(SalesLineDiscount4AllCust);
        CompareBuffAgainstDiscLines(SalesLineDiscount4AllCust, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BasicDiscLinesInsertedIntoBufferForCustDiscGr()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesLineDiscount4CustDiscGr: Record "Sales Line Discount";
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Disc. Group" := GetDiscGroupCode(Customer."No.");
        Customer.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        GetSLDiscountsForCustDiscGr(SalesLineDiscount4CustDiscGr, Customer);
        CompareBuffAgainstDiscLines(SalesLineDiscount4CustDiscGr, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BasicPriceLinesInsertedIntoBufferForCustomer()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesPrice4Cust: Record "Sales Price";
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);

        GetSPricesForCustomer(SalesPrice4Cust, Customer."No.");
        CompareBuffAgainstPrices(SalesPrice4Cust, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BasicPriceLinesInsertedIntoBufferForAllCust()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesPrice4AllCust: Record "Sales Price";
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);

        GetSPricesForAllCustomers(SalesPrice4AllCust);
        CompareBuffAgainstPrices(SalesPrice4AllCust, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BasicPriceLinesInsertedIntoBufferForCustPriceGr()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        SalesPrice4CustDiscGr: Record "Sales Price";
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        Customer.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);

        GetSPricesForPrGroup(SalesPrice4CustDiscGr, Customer."Customer Price Group");
        CompareBuffAgainstPrices(SalesPrice4CustDiscGr, TempSalesPriceAndLineDiscBuff);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBufferForCustomer()
    var
        Customer: Record Customer;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        DoValidateDiscountLinesInsertedIntoBuffer(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBufferForCustomerWithDiscGroup()
    var
        Customer: Record Customer;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Disc. Group" := GetDiscGroupCode(Customer."No.");
        Customer.Modify();

        DoValidateDiscountLinesInsertedIntoBuffer(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePriceLinesInsertedIntoBufferForCustomer()
    var
        Customer: Record Customer;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        DoValidatePriceLinesInsertedIntoBuffer(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePriceLinesInsertedIntoBufferForCustomerWithPriceGroup()
    var
        Customer: Record Customer;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        Customer.Modify();

        DoValidatePriceLinesInsertedIntoBuffer(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBufferForCust_NegForCamp()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Campaign);
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Campaign should not be inserted to the Buffer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBufferForCustWith2Group_NegForCamp()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        Customer."Customer Disc. Group" := GetDiscGroupCode(Customer."No.");
        Customer.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Campaign);
        Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Campaign should not be inserted to the Buffer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBuffer_NegForOtherCust()
    var
        WrongCust: Record Customer;
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        CreateBlankCustomer(WrongCust);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Customer);
        TempSalesPriceAndLineDiscBuff.SetFilter("Sales Code", '<>%1', Customer."No.");
        if TempSalesPriceAndLineDiscBuff.FindFirst() then
            Assert.AreEqual(
              0, TempSalesPriceAndLineDiscBuff.Count,
              'Lines for wrong Customer in the Buffer table' + Format(TempSalesPriceAndLineDiscBuff."Sales Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBuffer_NegForOtherCustAndTheSameDiscGr()
    var
        Customer: Record Customer;
        WrongCust: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        Customer."Customer Disc. Group" := GetDiscGroupCode(Customer."No.");
        Customer.Modify();

        // Wrong Customer with the same Disc. Group
        CreateBlankCustomer(WrongCust);
        WrongCust."Customer Disc. Group" := GetDiscGroupCode(Customer."No.");
        WrongCust."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        WrongCust.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Customer);
        TempSalesPriceAndLineDiscBuff.SetFilter("Sales Code", '<>%1', Customer."No.");
        if TempSalesPriceAndLineDiscBuff.FindFirst() then
            Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Lines for wrong Customer Gr. in the Buffer table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDiscountLinesInsertedIntoBuffer_NegForOtherCustDiscGr()
    var
        Customer: Record Customer;
        WrongCust: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        CreateBlankCustomer(WrongCust);
        WrongCust."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        WrongCust."Customer Disc. Group" := GetDiscGroupCode(Customer."No.");
        WrongCust.Modify();

        Customer."Customer Price Group" := GetPriceGroupCode(WrongCust."No.");
        Customer."Customer Disc. Group" := GetDiscGroupCode(WrongCust."No.");
        Customer.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);

        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::"Customer Price/Disc. Group");
        TempSalesPriceAndLineDiscBuff.SetFilter("Sales Code", '<>%1', Customer."Customer Price Group");
        if TempSalesPriceAndLineDiscBuff.FindFirst() then
            Assert.AreEqual(0, TempSalesPriceAndLineDiscBuff.Count, 'Lines for wrong Cust Group in the Buffer table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Added_CustomerDiscountLine()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        DuplicateLineInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::Item);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        CompareBuffAgainstActualDiscounts(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Modif_CustomerDiscountLine()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);
        UpdateLinesInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::Item);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        CompareBuffAgainstActualDiscounts(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Del_CustomerDiscountLine()
    var
        Customer: Record Customer;
        ActualTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        ExpectedTempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(ExpectedTempSalesPriceAndLineDiscBuff);

        DeleteLineInBuffer(ExpectedTempSalesPriceAndLineDiscBuff);

        SetBufferOnlyToSLDiscounts(ExpectedTempSalesPriceAndLineDiscBuff);

        ActualTempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(ActualTempSalesPriceAndLineDiscBuff);

        Assert.AreEqual(ExpectedTempSalesPriceAndLineDiscBuff.Count, ActualTempSalesPriceAndLineDiscBuff.Count, 'Record was not deleted');

        CompareBuffAgainstActualDiscounts(ExpectedTempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Added_CustomerDiscountGrLine()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        Customer.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        DuplicateLineInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        CompareBuffAgainstActualDiscounts(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Modif_CustomerDiscountGrLine()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        Customer.Modify();

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        UpdateLinesInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::"Item Disc. Group");
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        CompareBuffAgainstActualDiscounts(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Del_CustomerDiscountGrLine()
    var
        Customer: Record Customer;
        ActualTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);
        Customer."Customer Price Group" := GetPriceGroupCode(Customer."No.");
        Customer.Modify();

        ExpectedTempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(ExpectedTempSalesPriceAndLineDiscBuff);

        DeleteLineInBuffer(ExpectedTempSalesPriceAndLineDiscBuff);

        SetBufferOnlyToSLDiscounts(ExpectedTempSalesPriceAndLineDiscBuff);

        ActualTempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(ActualTempSalesPriceAndLineDiscBuff);

        Assert.AreEqual(ExpectedTempSalesPriceAndLineDiscBuff.Count, ActualTempSalesPriceAndLineDiscBuff.Count, 'Record was not deleted');
        // in case of error: <The Sales Price and Line Disc Buff does not exist...> Record was not deleted from original table.
        CompareBuffAgainstActualDiscounts(ExpectedTempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Added_CustomerPriceLine()
    var
        Customer: Record Customer;
        ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        ExpectedTempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSPrices(ExpectedTempSalesPriceAndLineDiscBuff);

        DuplicateLineInBuffer(ExpectedTempSalesPriceAndLineDiscBuff, ExpectedTempSalesPriceAndLineDiscBuff.Type::Item);
        SetBufferOnlyToSPrices(ExpectedTempSalesPriceAndLineDiscBuff);

        CompareBuffAgainstActualPrices(ExpectedTempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Modif_CustomerPriceLine()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);

        UpdateLinesInBuffer(TempSalesPriceAndLineDiscBuff, TempSalesPriceAndLineDiscBuff.Type::Item);
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);

        CompareBuffAgainstActualPrices(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_Del_CustomerPriceLine()
    var
        Customer: Record Customer;
        ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        ActualTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        ExpectedTempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSPrices(ExpectedTempSalesPriceAndLineDiscBuff);

        DeleteLineInBuffer(ExpectedTempSalesPriceAndLineDiscBuff);

        SetBufferOnlyToSPrices(ExpectedTempSalesPriceAndLineDiscBuff);

        ActualTempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSPrices(ActualTempSalesPriceAndLineDiscBuff);

        Assert.AreEqual(ExpectedTempSalesPriceAndLineDiscBuff.Count, ActualTempSalesPriceAndLineDiscBuff.Count, 'Record was not deleted');
        CompareBuffAgainstActualPrices(ExpectedTempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_TheSameValuesForPrices()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        TempSalesPriceAndLineDiscBuff.Modify(true);

        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);
        CompareBuffAgainstActualPrices(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Publish_TheSameValuesForCustomerDiscounts()
    var
        Customer: Record Customer;
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        Initialize();

        InitCustomerAndDiscAndPrices(Customer);

        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        TempSalesPriceAndLineDiscBuff.Modify(true);

        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);
        CompareBuffAgainstActualDiscounts(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifySalesPriceInSalesPriceAndLineDiscountsPageHandler')]
    procedure SetSalesPricesOnCustomerCardSubpageIsLinkedToSalesCodeAndItem()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [UT]
        // [SCENARIO 296601] "Set Special Prices" action on "Special Prices & Discounts" subpage on customer card shows Sales Prices page filtered by current customer and item.
        Initialize();

        CreateBlankCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::Customer, Customer."No.", 0D, '', '',
          Item."Base Unit of Measure", 0, LibraryRandom.RandDec(10, 2));

        CustomerCard.OpenEdit();
        CustomerCard.GotoKey(Customer."No.");

        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        CustomerCard."Prices and Discounts Overview".Invoke();

        // Verification is done in the modal page handler
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifySalesPriceActionInSalesPriceAndLineDiscountsPageHandler')]
    procedure SetSalesPricesOnCustomerCardSubpageEnabledOnlyForSalesPriceLineType()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO 296601] "Set Special Prices" action on "Special Prices & Discounts" subpage on customer card is enabled for item lines and disabled for line discount lines.
        Initialize();

        LibrarySales.CreateCustomer(Customer);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::Customer, Customer."No.", 0D, '', '',
          Item."Base Unit of Measure", 0, LibraryRandom.RandDec(10, 2));

        CreateSalesLineDiscountLine(Customer."No.", SalesLineDiscount.Type::Item, false);
        FindSalesLineDiscount(SalesLineDiscount, Customer."No.");

        CustomerCard.OpenEdit();
        CustomerCard.GotoKey(Customer."No.");

        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        CustomerCard."Prices and Discounts Overview".Invoke();

        // Verification is done in the modal page handler
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifySalesLineDiscountInSalesPriceAndLineDiscountsPageHandler')]
    procedure SetLineDiscountsOnCustomerCardSubpageIsLinkedToSalesCodeAndItem()
    var
        Customer: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [UT]
        // [SCENARIO 296601] "Set Special Discounts" action on "Special Prices & Discounts" subpage on customer card shows Sales Line Discounts page filtered by current customer and item.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateSalesLineDiscountLine(Customer."No.", SalesLineDiscount.Type::Item, false);
        FindSalesLineDiscount(SalesLineDiscount, Customer."No.");

        CustomerCard.OpenEdit();
        CustomerCard.GotoKey(Customer."No.");

        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(SalesLineDiscount.Code);
        CustomerCard."Prices and Discounts Overview".Invoke();

        // Verification is done in the modal page handler
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifySalesLineDiscountInSalesPriceAndLineDiscountsPageHandler')]
    procedure SetLineDiscountsOnCustomerCardSubpageIsLinkedToSalesCodeAndItemDiscGroup()
    var
        Customer: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [UT]
        // [SCENARIO 296601] "Set Special Discounts" action on "Special Prices & Discounts" subpage on customer card shows Sales Line Discounts page filtered by current customer and item discount group.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateSalesLineDiscountLine(Customer."No.", SalesLineDiscount.Type::"Item Disc. Group", false);
        FindSalesLineDiscount(SalesLineDiscount, Customer."No.");

        CustomerCard.OpenEdit();
        CustomerCard.GotoKey(Customer."No.");

        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(SalesLineDiscount.Code);
        CustomerCard."Prices and Discounts Overview".Invoke();

        // Verification is done in the modal page handler
    end;

    [Test]
    [HandlerFunctions('SalesPricesOverviewSetPricesHandler')]
    [Scope('OnPrem')]
    procedure OpenPricesFromCustomerCard()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPrice: Record "Sales Price";
        SalesType: Text;
        SalesCode: Text;
    begin
        Initialize();
        SalesLineDiscount.DeleteAll();
        SalesPrice.DeleteAll();

        Customer.Init();
        Customer.Insert(true);
        CustomerCard.OpenView();
        CustomerCard.Filter.SetFilter("No.", Customer."No.");
        CustomerCard."Prices and Discounts Overview".Invoke();
        CustomerCard.Close();

        SalesType := LibraryVariableStorage.DequeueText();
        SalesCode := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('Customer', SalesType, 'wrong Sales Type filteer');
        Assert.AreEqual(Customer."No.", SalesCode, 'wrong Sales code filter');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure DoValidateDiscountLinesInsertedIntoBuffer(Customer: Record Customer)
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSLDiscounts(TempSalesPriceAndLineDiscBuff);

        CompareBuffAgainstActualDiscounts(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    local procedure DoValidatePriceLinesInsertedIntoBuffer(Customer: Record Customer)
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
    begin
        TempSalesPriceAndLineDiscBuff.LoadDataForCustomer(Customer);
        SetBufferOnlyToSPrices(TempSalesPriceAndLineDiscBuff);

        CompareBuffAgainstActualPrices(TempSalesPriceAndLineDiscBuff, Customer);
    end;

    local procedure CompareBuffAgainstDiscLines(var SalesLineDiscount: Record "Sales Line Discount"; var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        if SalesLineDiscount.FindFirst() then
            repeat
                TempSalesPriceAndLineDiscBuff.Get(
                  TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount",
                  SalesLineDiscount.Type,
                  SalesLineDiscount.Code,
                  SalesLineDiscount."Sales Type",
                  SalesLineDiscount."Sales Code",
                  SalesLineDiscount."Starting Date",
                  SalesLineDiscount."Currency Code",
                  SalesLineDiscount."Variant Code",
                  SalesLineDiscount."Unit of Measure Code",
                  SalesLineDiscount."Minimum Quantity",
                  '',
                  TempSalesPriceAndLineDiscBuff."Loaded Disc. Group",
                  TempSalesPriceAndLineDiscBuff."Loaded Customer No.",
                  TempSalesPriceAndLineDiscBuff."Loaded Price Group");

                Assert.AreEqual(SalesLineDiscount."Ending Date", TempSalesPriceAndLineDiscBuff."Ending Date", 'Wrong value');
                Assert.AreEqual(SalesLineDiscount."Line Discount %", TempSalesPriceAndLineDiscBuff."Line Discount %", 'Wrong value');
            until SalesLineDiscount.Next() = 0;
    end;

    local procedure CompareBuffAgainstPrices(var SalesPrice: Record "Sales Price"; var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        if SalesPrice.FindFirst() then
            repeat
                TempSalesPriceAndLineDiscBuff.Get(
                  TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price",
                  TempSalesPriceAndLineDiscBuff.Type::Item,
                  SalesPrice."Item No.",
                  SalesPrice."Sales Type",
                  SalesPrice."Sales Code",
                  SalesPrice."Starting Date",
                  SalesPrice."Currency Code",
                  SalesPrice."Variant Code",
                  SalesPrice."Unit of Measure Code",
                  SalesPrice."Minimum Quantity",
                  '',
                  TempSalesPriceAndLineDiscBuff."Loaded Disc. Group",
                  TempSalesPriceAndLineDiscBuff."Loaded Customer No.",
                  TempSalesPriceAndLineDiscBuff."Loaded Price Group");

                Assert.AreEqual(
                  SalesPrice."Allow Invoice Disc.", TempSalesPriceAndLineDiscBuff."Allow Invoice Disc.", 'Wrong value in Allow Invoice Disc.');
                Assert.AreEqual(SalesPrice."Allow Line Disc.", TempSalesPriceAndLineDiscBuff."Allow Line Disc.", 'Wrong value in Allow Line Disc.');
                Assert.AreEqual(SalesPrice."Ending Date", TempSalesPriceAndLineDiscBuff."Ending Date", 'Wrong value in Ending Date');
                Assert.AreEqual(
                  SalesPrice."Price Includes VAT", TempSalesPriceAndLineDiscBuff."Price Includes VAT", 'Wrong value in Price Includes VAT');
                Assert.AreEqual(SalesPrice."Unit Price", TempSalesPriceAndLineDiscBuff."Unit Price", 'Wrong value in Unit Price');
                Assert.AreEqual(
                  SalesPrice."VAT Bus. Posting Gr. (Price)", TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)",
                  'Wrong value in VAT Bus. Posting Gr. (Price)');

            until SalesPrice.Next() = 0;
    end;

    local procedure CompareBuffAgainstActualDiscounts(var ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; Customer: Record Customer)
    var
        SalesLineDiscount4Cust: Record "Sales Line Discount";
        SalesLineDiscount4AllCust: Record "Sales Line Discount";
        SalesLineDiscount4CustDiscGr: Record "Sales Line Discount";
    begin
        GetSLDiscountsForCustomer(SalesLineDiscount4Cust, Customer);
        CompareBuffAgainstDiscLines(SalesLineDiscount4Cust, ExpectedTempSalesPriceAndLineDiscBuff);

        GetSLDiscountsForAllCustomers(SalesLineDiscount4AllCust);
        CompareBuffAgainstDiscLines(SalesLineDiscount4AllCust, ExpectedTempSalesPriceAndLineDiscBuff);

        GetSLDiscountsForCustDiscGr(SalesLineDiscount4CustDiscGr, Customer);
        CompareBuffAgainstDiscLines(SalesLineDiscount4CustDiscGr, ExpectedTempSalesPriceAndLineDiscBuff);

        Assert.AreEqual(
          ExpectedTempSalesPriceAndLineDiscBuff.Count,
          SalesLineDiscount4Cust.Count + SalesLineDiscount4AllCust.Count + SalesLineDiscount4CustDiscGr.Count,
          'incorect counts');
    end;

    local procedure CompareBuffAgainstActualPrices(var ExpectedTempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; Customer: Record Customer)
    var
        SalesPrice4Cust: Record "Sales Price";
        SalesPrice4AllCust: Record "Sales Price";
        SalesPrice4CustDiscGr: Record "Sales Price";
    begin
        GetSPricesForCustomer(SalesPrice4Cust, Customer."No.");
        CompareBuffAgainstPrices(SalesPrice4Cust, ExpectedTempSalesPriceAndLineDiscBuff);

        GetSPricesForAllCustomers(SalesPrice4AllCust);
        CompareBuffAgainstPrices(SalesPrice4AllCust, ExpectedTempSalesPriceAndLineDiscBuff);

        GetSPricesForPrGroup(SalesPrice4CustDiscGr, Customer."Customer Price Group");
        CompareBuffAgainstPrices(SalesPrice4CustDiscGr, ExpectedTempSalesPriceAndLineDiscBuff);

        Assert.AreEqual(
          ExpectedTempSalesPriceAndLineDiscBuff.Count,
          SalesPrice4Cust.Count + SalesPrice4AllCust.Count + SalesPrice4CustDiscGr.Count,
          'incorect counts');
    end;

    local procedure CreateCustPriceGr(var CustPriceGr: Record "Customer Price Group")
    var
        CustPriceGrCode: Code[10];
    begin
        CustPriceGr.Init();
        CustPriceGrCode := 'PG' + Format(LibraryRandom.RandInt(100));
        if CustPriceGr.Get(CustPriceGrCode) then
            exit;
        CustPriceGr.Code := CustPriceGrCode;
        CustPriceGr."Price Includes VAT" := true;
        CustPriceGr."VAT Bus. Posting Gr. (Price)" := 'VAT' + Format(LibraryRandom.RandInt(100));
        CustPriceGr."Allow Line Disc." := true;
        CustPriceGr."Allow Invoice Disc." := true;
        CustPriceGr.Insert(true);
    end;

    local procedure CreateBlankCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer.Insert(true);
    end;

    local procedure InitCustomerAndDiscAndPrices(var Customer: Record Customer)
    begin
        CreateBlankCustomer(Customer);
        CreateSalesLineDiscounts(Customer."No.");
        CreateSalesPrices(Customer."No.");
    end;

    local procedure CreateSalesPrices(CustomerNo: Code[20])
    var
        SalesPrice: Record "Sales Price";
        i: Integer;
    begin
        SalesPrice.DeleteAll();

        // at least 3 lines and one in the past
        for i := 0 to 3 do begin
            // Correct Customer/Group Prise
            CreateSalesPriceLine(CustomerNo, i = 0);
            CreateSalesPriceLine(GetPriceGroupCode(CustomerNo), i = 0);

            // Incorrect lines
            CreateSalesPriceLine('TEST', i = 0);
        end;
    end;

    local procedure CreateSalesLineDiscounts(CustomerNo: Code[20])
    var
        SalesLineDiscount: Record "Sales Line Discount";
        i: Integer;
    begin
        SalesLineDiscount.DeleteAll();

        // at least 3 lines and one in the past
        for i := 0 to 3 do begin
            // Correct lines
            CreateSalesLineDiscountLine(CustomerNo, SalesLineDiscount.Type::Item, i = 0);
            CreateSalesLineDiscountLine(GetDiscGroupCode(CustomerNo), SalesLineDiscount.Type::"Item Disc. Group", i = 0);

            // Incorrect lines
            CreateSalesLineDiscountLine(CustomerNo, SalesLineDiscount.Type::"Item Disc. Group", i = 0);
            CreateSalesLineDiscountLine(GetDiscGroupCode(CustomerNo), SalesLineDiscount.Type::Item, i = 0);

            CreateSalesLineDiscountLine('TEST', SalesLineDiscount.Type::Item, i = 0);
            CreateSalesLineDiscountLine('TEST', SalesLineDiscount.Type::"Item Disc. Group", i = 0);
        end;
    end;

    local procedure CreateSalesLineDiscountLine(LineCode: Code[20]; LineType: Enum "Sales Line Discount Type"; InThePast: Boolean)
    var
        SalesLineDiscount: Record "Sales Line Discount";
        i: Integer;
    begin
        for i := 0 to 3 do begin
            SalesLineDiscount.Init();
            SalesLineDiscount."Sales Type" := i;
            if SalesLineDiscount."Sales Type" = SalesLineDiscount."Sales Type"::"All Customers" then
                SalesLineDiscount."Sales Code" := ''
            else
                SalesLineDiscount."Sales Code" := LineCode;

            SalesLineDiscount.Type := LineType;
            SalesLineDiscount.Code := LibraryUtility.GenerateGUID();
            SalesLineDiscount."Currency Code" := 'CC' + Format(LibraryRandom.RandInt(100));
            SalesLineDiscount."Starting Date" := Today - LibraryRandom.RandIntInRange(2, 100);
            SalesLineDiscount."Line Discount %" := LibraryRandom.RandDec(10, 2);
            SalesLineDiscount."Minimum Quantity" := LibraryRandom.RandInt(100);
            if InThePast then
                SalesLineDiscount."Ending Date" := Today - 1
            else
                SalesLineDiscount."Ending Date" := Today + LibraryRandom.RandInt(100);
            SalesLineDiscount."Unit of Measure Code" := 'UMC' + Format(LibraryRandom.RandInt(100));
            SalesLineDiscount."Variant Code" := 'VC' + Format(LibraryRandom.RandInt(100));

            SalesLineDiscount.Insert();
        end;
    end;

    local procedure CreateSalesPriceLine(CustomerNo: Code[20]; InThePast: Boolean)
    var
        SalesPrice: Record "Sales Price";
        i: Integer;
    begin
        // what about the Price Groups?
        for i := 0 to 3 do begin
            SalesPrice.Init();
            SalesPrice."Sales Type" := "Sales Price Type".FromInteger(i);
            if i = SalesPrice."Sales Type"::"All Customers".AsInteger() then
                SalesPrice."Sales Code" := ''
            else
                SalesPrice."Sales Code" := CustomerNo;

            SalesPrice."Item No." := 'C' + Format(LibraryRandom.RandInt(100));
            SalesPrice."Currency Code" := 'CC' + Format(LibraryRandom.RandInt(100));
            SalesPrice."Starting Date" := Today - LibraryRandom.RandIntInRange(2, 100);
            SalesPrice."Unit Price" := LibraryRandom.RandDec(100, 2);
            SalesPrice."Price Includes VAT" := true;
            SalesPrice."Allow Invoice Disc." := true;
            SalesPrice."VAT Bus. Posting Gr. (Price)" := 'VAT BPG' + Format(LibraryRandom.RandInt(100));

            SalesPrice."Minimum Quantity" := LibraryRandom.RandInt(100);
            if InThePast then
                SalesPrice."Ending Date" := Today - 1
            else
                SalesPrice."Ending Date" := Today + LibraryRandom.RandInt(100);
            SalesPrice."Unit of Measure Code" := 'UMC' + Format(LibraryRandom.RandInt(100));
            SalesPrice."Variant Code" := 'VC' + Format(LibraryRandom.RandInt(100));
            SalesPrice."Allow Line Disc." := true;

            SalesPrice.Insert();
        end;
    end;

    local procedure DuplicateLineInBuffer(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; LineDiscType: Enum "Sales Line Discount Type")
    begin
        TempSalesPriceAndLineDiscBuff.SetRange(Type, LineDiscType);
        TempSalesPriceAndLineDiscBuff.FindFirst();

        TempSalesPriceAndLineDiscBuff."Minimum Quantity" := LibraryRandom.RandInt(100);
        TempSalesPriceAndLineDiscBuff."Starting Date" := Today - LibraryRandom.RandIntInRange(2, 100);
        TempSalesPriceAndLineDiscBuff."Ending Date" := Today + LibraryRandom.RandInt(100);

        if TempSalesPriceAndLineDiscBuff."Line Type" = TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount" then
            TempSalesPriceAndLineDiscBuff."Line Discount %" := LibraryRandom.RandDecInRange(10, 90, 2)
        else begin
            TempSalesPriceAndLineDiscBuff."Unit Price" := LibraryRandom.RandDecInRange(10, 100, 2);
            TempSalesPriceAndLineDiscBuff."Price Includes VAT" := not TempSalesPriceAndLineDiscBuff."Price Includes VAT";
            TempSalesPriceAndLineDiscBuff."Allow Invoice Disc." := not TempSalesPriceAndLineDiscBuff."Allow Invoice Disc.";
            TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)" := 'VBP' + Format(LibraryRandom.RandDecInRange(10, 90, 2));
            TempSalesPriceAndLineDiscBuff."Allow Line Disc." := not TempSalesPriceAndLineDiscBuff."Allow Line Disc.";
        end;

        TempSalesPriceAndLineDiscBuff.Insert(true);

        TempSalesPriceAndLineDiscBuff.SetRange(Type);
    end;

    local procedure UpdateLinesInBuffer(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; LineDiscType: Enum "Sales Line Discount Type")
    var
        i: Integer;
    begin
        TempSalesPriceAndLineDiscBuff.SetRange(Type, LineDiscType);
        TempSalesPriceAndLineDiscBuff.FindFirst();

        for i := 0 to 1 do begin
            TempSalesPriceAndLineDiscBuff."Ending Date" := TempSalesPriceAndLineDiscBuff."Ending Date" + LibraryRandom.RandIntInRange(1, 10);
            if TempSalesPriceAndLineDiscBuff."Line Type" = TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount" then
                TempSalesPriceAndLineDiscBuff."Line Discount %" := LibraryRandom.RandDecInRange(10, 90, 2)
            else begin
                TempSalesPriceAndLineDiscBuff."Unit Price" := LibraryRandom.RandDecInRange(10, 100, 2);
                TempSalesPriceAndLineDiscBuff."Price Includes VAT" := not TempSalesPriceAndLineDiscBuff."Price Includes VAT";
                TempSalesPriceAndLineDiscBuff."Allow Invoice Disc." := not TempSalesPriceAndLineDiscBuff."Allow Invoice Disc.";
                TempSalesPriceAndLineDiscBuff."VAT Bus. Posting Gr. (Price)" := 'VBP' + Format(LibraryRandom.RandDecInRange(10, 90, 2));
                TempSalesPriceAndLineDiscBuff."Allow Line Disc." := not TempSalesPriceAndLineDiscBuff."Allow Line Disc.";
            end;

            TempSalesPriceAndLineDiscBuff.Modify(true);
            TempSalesPriceAndLineDiscBuff.Next();
        end;

        TempSalesPriceAndLineDiscBuff.SetRange(Type);
    end;

    local procedure DeleteLineInBuffer(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        TempSalesPriceAndLineDiscBuff.FindFirst();

        TempSalesPriceAndLineDiscBuff.Delete(true);
        TempSalesPriceAndLineDiscBuff.Next();
        TempSalesPriceAndLineDiscBuff.Delete(true);
        TempSalesPriceAndLineDiscBuff.Next();
    end;

    local procedure FindSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; CustomerNo: Code[20])
    begin
        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::Customer);
        SalesLineDiscount.SetRange("Sales Code", CustomerNo);
        SalesLineDiscount.FindFirst();
    end;

    local procedure GetDiscGroupCode(CustomerNo: Code[20]): Code[10]
    begin
        exit(CopyStr('D_GR_' + CustomerNo, 1, 10))
    end;

    local procedure GetPriceGroupCode(CustomerNo: Code[20]): Code[10]
    begin
        exit(CopyStr('P_GR_' + CustomerNo, 1, 10))
    end;

    local procedure SetBufferOnlyToSLDiscounts(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        TempSalesPriceAndLineDiscBuff.SetRange("Line Type", TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Line Discount");
    end;

    local procedure SetBufferOnlyToSPrices(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary)
    begin
        TempSalesPriceAndLineDiscBuff.SetRange("Line Type", TempSalesPriceAndLineDiscBuff."Line Type"::"Sales Price");
    end;

    local procedure GetSLDiscountsForCustomer(var SalesLineDiscount: Record "Sales Line Discount"; Customer: Record Customer)
    begin
        SalesLineDiscount.Reset();
        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::Customer);
        SalesLineDiscount.SetRange("Sales Code", Customer."No.");
    end;

    local procedure GetSLDiscountsForAllCustomers(var SalesLineDiscount: Record "Sales Line Discount")
    begin
        SalesLineDiscount.Reset();
        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::"All Customers");
        SalesLineDiscount.SetRange("Sales Code", '');
    end;

    local procedure GetSLDiscountsForCustDiscGr(var SalesLineDiscount: Record "Sales Line Discount"; Customer: Record Customer)
    begin
        SalesLineDiscount.Reset();
        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::"Customer Disc. Group");
        SalesLineDiscount.SetRange("Sales Code", Customer."Customer Disc. Group");
    end;

    local procedure GetSPricesForCustomer(var SalesPrice: Record "Sales Price"; CustomerNo: Code[20])
    begin
        SalesPrice.Reset();
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.SetRange("Sales Code", CustomerNo);
    end;

    local procedure GetSPricesForAllCustomers(var SalesPrice: Record "Sales Price")
    begin
        SalesPrice.Reset();
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"All Customers");
        SalesPrice.SetRange("Sales Code", '');
    end;

    local procedure GetSPricesForPrGroup(var SalesPrice: Record "Sales Price"; CustomerPriceGroup: Code[20])
    begin
        SalesPrice.Reset();
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroup);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowItemPage(var ItemListPage: TestPage "Item List")
    begin
        ItemListPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowItemDiscGroupsPage(var ItemDiscGroupsPage: TestPage "Item Disc. Groups")
    begin
        ItemDiscGroupsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyFieldVisibilityOnSalesPriceAndLineDiscountsPageHandler(var SalesPrLineDisc: TestPage "Sales Price and Line Discounts")
    begin
        Assert.IsFalse(
          SalesPrLineDisc."Sales Code".Visible(), 'Sales Code should NOT be visible');
        Assert.IsTrue(
          SalesPrLineDisc.Code.Visible(), 'Code should be visible');
        SalesPrLineDisc.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifySalesPriceActionInSalesPriceAndLineDiscountsPageHandler(var SalesPrLineDisc: TestPage "Sales Price and Line Discounts")
    var
        SalesPrices: TestPage "Sales Prices";
        SalesCode: Code[20];
        ItemNo: Code[20];
    begin
        SalesCode := LibraryVariableStorage.DequeueText();
        ItemNo := LibraryVariableStorage.DequeueText();

        SalesPrLineDisc.FILTER.SetFilter(Code, ItemNo);
        Assert.IsTrue(SalesPrLineDisc."Set Special Prices".Enabled(), 'Set Special Prices.Enabled');

        SalesPrLineDisc.Filter.SetFilter("Sales Type", 'All Customers');
        SalesPrLineDisc.FILTER.SetFilter("Sales Code", SalesCode);

        Assert.IsFalse(SalesPrLineDisc.First(), 'should be no filtered lines in the list');
        Assert.IsTrue(SalesPrLineDisc."Set Special Prices".Enabled(), 'Set Special Prices.Enabled on empty list');

        SalesPrices.Trap();
        SalesPrLineDisc."Set Special Prices".Invoke();
        SalesPrices.SalesTypeFilter.AssertEquals('Customer');
        SalesPrices.SalesCodeFilterCtrl.AssertEquals(SalesCode);
        SalesPrices.ItemNoFilterCtrl.AssertEquals('');
        SalesPrices.OK().Invoke();

        SalesPrLineDisc.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifySalesPriceInSalesPriceAndLineDiscountsPageHandler(var SalesPrLineDisc: TestPage "Sales Price and Line Discounts")
    var
        SalesPrices: TestPage "Sales Prices";
        SalesCode: Code[20];
        DiscountCode: Code[20];
    begin
        SalesCode := LibraryVariableStorage.DequeueText();
        DiscountCode := LibraryVariableStorage.DequeueText();

        SalesPrLineDisc.Filter.SetFilter(Code, DiscountCode);

        SalesPrices.Trap();
        SalesPrLineDisc."Set Special Prices".Invoke();

        Assert.AreEqual(DiscountCode, SalesPrices.FILTER.GetFilter("Item No."), '');
        Assert.AreEqual(SalesCode, SalesPrices.FILTER.GetFilter("Sales Code"), '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifySalesLineDiscountInSalesPriceAndLineDiscountsPageHandler(var SalesPrLineDisc: TestPage "Sales Price and Line Discounts")
    var
        SalesLineDiscounts: TestPage "Sales Line Discounts";
        SalesCode: Code[20];
        DiscountCode: Code[20];
    begin
        SalesCode := LibraryVariableStorage.DequeueText();
        DiscountCode := LibraryVariableStorage.DequeueText();

        SalesPrLineDisc.Filter.SetFilter("Sales Code", SalesCode);
        SalesPrLineDisc.Filter.SetFilter(Code, DiscountCode);

        SalesLineDiscounts.Trap();
        SalesPrLineDisc."Set Special Discounts".Invoke();

        Assert.AreEqual(DiscountCode, SalesLineDiscounts.FILTER.GetFilter(Code), '');
        Assert.AreEqual(SalesCode, SalesLineDiscounts.FILTER.GetFilter("Sales Code"), '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPricesOverviewHandler(var SalesPriceAndLineDiscounts: TestPage "Sales Price and Line Discounts")
    var
        Item: Record Item;
        ItemVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemVar);
        Item := ItemVar;
        Assert.AreEqual(Item."No.", SalesPriceAndLineDiscounts.Code.Value, '');
        SalesPriceAndLineDiscounts.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPricesOverviewSetPricesHandler(var SalesPriceAndLineDiscounts: TestPage "Sales Price and Line Discounts")
    var
        SalesPrices: TestPage "Sales Prices";
    begin
        SalesPrices.Trap();
        SalesPriceAndLineDiscounts."Set Special Prices".Invoke();
        LibraryVariableStorage.Enqueue(SalesPrices.SalesTypeFilter.Value());
        LibraryVariableStorage.Enqueue(SalesPrices.SalesCodeFilterCtrl.Value());
        SalesPrices.Close();
    end;
}
