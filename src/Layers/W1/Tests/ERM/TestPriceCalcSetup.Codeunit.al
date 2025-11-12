codeunit 134158 "Test Price Calc. Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Setup]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        NotImplementedMethodErr: Label 'Method %1 does not have active implementations for %2 price type.', Comment = '%1 - method name, %2 - price type name';

    [Test]
    procedure T000_VerifyMethodImplementedAnyOnEmptySetup()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Lowest Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        asserterror PriceCalculationMgt.VerifyMethodImplemented(PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Any);
        Assert.ExpectedError(StrSubstNo(NotImplementedMethodErr, PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Any));
    end;

    [Test]
    procedure T001_VerifyMethodImplementedAnyOnSaleSetup()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        PriceCalculationMgt.VerifyMethodImplemented(PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Any);
    end;

    [Test]
    procedure T002_VerifyMethodImplementedAnyOnPurchSetup()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        PriceCalculationMgt.VerifyMethodImplemented(PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Any);
    end;

    [Test]
    procedure T003_VerifyMethodImplementedSale()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        asserterror PriceCalculationMgt.VerifyMethodImplemented(PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Sale);
        Assert.ExpectedError(StrSubstNo(NotImplementedMethodErr, PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Sale));
    end;

    [Test]
    procedure T004_VerifyMethodImplementedPurch()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        asserterror PriceCalculationMgt.VerifyMethodImplemented(PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Purchase);
        Assert.ExpectedError(StrSubstNo(NotImplementedMethodErr, PriceCalculationSetup.Method::"Test Price", PriceCalculationSetup.Type::Purchase));
    end;

    [Test]
    procedure T005_DefaultFlagsDontOverwriteActualDefault()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        Guids: array[2] of Guid;
        i: Integer;
        TestPriceCalcSetup: Codeunit "Test Price Calc. Setup";
    begin
        // [FEATURE] [UI]
        Initialize();
        BindSubscription(TestPriceCalcSetup); // to handle OnFindSupportedSetup
        // [GIVEN] Subscribers added 4 setup records for "Lowest Price", where 2 'V16' have "Default" 'Yes'
        PriceCalculationSetup.DeleteAll();
        PriceCalculationMgt.Run();

        PriceCalculationSetup.SetRange(Method, PriceCalculationSetup.Method::"Lowest Price");
        Assert.RecordCount(PriceCalculationSetup, 6);
        PriceCalculationSetup.SetRange(
            Implementation, PriceCalculationSetup.Implementation::"Business Central (Version 16.0)");
        PriceCalculationSetup.SetRange(Default, true);
        Assert.RecordCount(PriceCalculationSetup, 2);
        // [GIVEN] User sets 'Test' as defaults
        PriceCalculationSetup.Reset();
        PriceCalculationSetup.SetRange(Method, PriceCalculationSetup.Method::"Lowest Price");
        PriceCalculationSetup.SetRange(
            Implementation, PriceCalculationSetup.Implementation::Test);
        i := 0;
        PriceCalculationSetup.FindSet();
        repeat
            PriceCalculationSetup.Validate(Default, true);
            PriceCalculationSetup.Modify(true);
            i += 1;
            Guids[i] := PriceCalculationSetup.SystemId;
        until PriceCalculationSetup.Next() = 0;

        PriceCalculationSetup.SetRange(
            Implementation, PriceCalculationSetup.Implementation::"Business Central (Version 16.0)");
        PriceCalculationSetup.SetRange(Default, true);
        Assert.RecordCount(PriceCalculationSetup, 0);

        // [WHEN] Refresh setup
        PriceCalculationMgt.Run();

        // [THEN] Two records with 'Test' are defaults
        PriceCalculationSetup.Reset();
        PriceCalculationSetup.SetRange(Method, PriceCalculationSetup.Method::"Lowest Price");
        PriceCalculationSetup.SetRange(
            Implementation, PriceCalculationSetup.Implementation::Test);
        PriceCalculationSetup.SetRange(Default, true);
        Assert.RecordCount(PriceCalculationSetup, 2);
        // [THEN] Records have the same SystemID (were not recreated)
        Assert.IsTrue(PriceCalculationSetup.GetBySystemId(Guids[1]), 'not found setup by guid #1');
        Assert.IsTrue(PriceCalculationSetup.GetBySystemId(Guids[2]), 'not found setup by guid #2');
        // [THEN] Two records with 'V16' are not defaults
        PriceCalculationSetup.SetRange(
            Implementation, PriceCalculationSetup.Implementation::"Business Central (Version 16.0)");
        PriceCalculationSetup.SetRange(Default, false);
        Assert.RecordCount(PriceCalculationSetup, 2);
    end;

    [Test]
    procedure T006_GroupIdSetOnInsert()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        Initialize();
        // [GIVEN] Setup, where Method 'Lowest Price', Type is 'Sale', "Asset Type" is 'Item'
        PriceCalculationSetup.Method := PriceCalculationSetup.Method::"Lowest Price";
        PriceCalculationSetup.Type := PriceCalculationSetup.Type::Sale;
        PriceCalculationSetup."Asset Type" := PriceCalculationSetup."Asset Type"::Item;
        PriceCalculationSetup.Implementation := PriceCalculationSetup.Implementation::"Business Central (Version 16.0)";
        // [WHEN] Insert
        PriceCalculationSetup.Insert(true);

        // [THEN] "Group Id" is '1-1-10', Code is '[1-1-10]-7002'
        Assert.AreEqual(PriceCalculationSetup."Group Id", '1-1-10', 'GroupID');
        Assert.AreEqual(PriceCalculationSetup.Code, '[1-1-10]-7002', 'Code');
    end;

    [Test]
    procedure T007_DefaultPriceCalcSetupGotRemovedExceptions()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        Initialize();
        // [GIVEN] Setup 'A', where Default is 'No', with one exception record
        PriceCalculationSetup.Code := 'A';
        PriceCalculationSetup.Default := false;
        PriceCalculationSetup.Insert();

        DtldPriceCalculationSetup."Setup Code" := PriceCalculationSetup.Code;
        DtldPriceCalculationSetup."Line No." := 1;
        DtldPriceCalculationSetup.Insert();

        // [GIVEN] One exception record fro Setup 'B'
        DtldPriceCalculationSetup."Setup Code" := 'B';
        DtldPriceCalculationSetup."Line No." := 2;
        DtldPriceCalculationSetup.Insert();

        // [WHEN] Set Default as 'Yes' to Setup 'A'
        PriceCalculationSetup.Validate(Default, true);

        // [THEN] No exception record for Setup 'A' and one for 'B'
        DtldPriceCalculationSetup.SetRange("Setup Code", PriceCalculationSetup.Code);
        Assert.RecordCount(DtldPriceCalculationSetup, 0);
        DtldPriceCalculationSetup.Reset();
        Assert.RecordCount(DtldPriceCalculationSetup, 1);
    end;

    [Test]
    procedure T010_OneSourceOneAssetSkipDisabledDtldSetup()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X'
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'D' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'Customer' 'Y' sells Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[1]."Source Group"::Customer, CustomerNo);
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'Customer' 'Y' sells Item 'X', "Enabled" is 'No'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[2], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[2]."Source Group"::Customer, CustomerNo);
        LibraryPriceCalculation.DisableDtldSetup(DtldPriceCalculationSetup[2]);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[3].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[1]."Line No.");
    end;

    [Test]
    procedure T011_OneSourceOneAsset()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();

        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'C' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'All' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[1]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'All' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[2], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[2]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where 'Customer' sources sell all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[3], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[3]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'Customer' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[4], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[4]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'Customer' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[5], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[5]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where Customer 'Y' sells all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[6], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[6]."Source Group"::Customer, CustomerNo);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'Customer' 'Y' sells Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[7], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[7]."Source Group"::Customer, CustomerNo);
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'Customer' 'Y' sells Item 'x'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[8], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[8]."Source Group"::Customer, CustomerNo);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'D' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[4].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[8]."Line No.");
    end;

    [Test]
    procedure T012_OneSourceAssetType()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'D' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'All' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[1]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'All' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[2], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[2]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where 'Customer' sources sell all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[3], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[3]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'Customer' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[4], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[4]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'Customer' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[5], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[5]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where Customer 'Y' sells all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[6], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[6]."Source Group"::Customer, CustomerNo);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'Customer' 'Y' sells Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[7], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[7]."Source Group"::Customer, CustomerNo);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[3].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[7]."Line No.");
    end;

    [Test]
    procedure T013_OneSourceAllAssets()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();

        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'C' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'All' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[1]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'All' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[2], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[2]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where 'Customer' sources sell all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[3], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[3]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'Customer' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[4], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[4]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'Customer' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[5], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[5]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where Customer 'Y' sells all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[6], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[6]."Source Group"::Customer, CustomerNo);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'B' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[2].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[6]."Line No.");
    end;

    [Test]
    procedure T014_SourceGroupOneAsset()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'C' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'All' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[1]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'All' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[2], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[2]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where 'Customer' sources sell all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[3], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[3]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'Customer' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[4], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[4]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'Customer' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[5], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[5]."Source Group"::Customer, '');

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'D' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[4].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[5]."Line No.");
    end;

    [Test]
    procedure T015_SourceGroupAssetType()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'D' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'All' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[1]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'All' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[2], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[2]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where 'Customer' sources sell all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[3], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[3]."Source Group"::Customer, '');
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'Customer' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[4], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[4]."Source Group"::Customer, '');

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[3].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[4]."Line No.");
    end;

    [Test]
    procedure T016_SourceGroupAllAssets()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'C' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'All' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[1]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'All' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[2], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[2]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'B', where 'Customer' sources sell all assets
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[3], PriceCalculationSetup[2].Code, '', DtldPriceCalculationSetup[3]."Source Group"::Customer, '');

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'B' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[2].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[3]."Line No.");
    end;

    [Test]
    procedure T017_AllSourcesOneAsset()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'C' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'All' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[3].Code, '', DtldPriceCalculationSetup[1]."Source Group"::All, '');
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'All' sources sell Item 'X'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[2], PriceCalculationSetup[4].Code, ItemNo, DtldPriceCalculationSetup[2]."Source Group"::All, '');

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'D' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[4].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[2]."Line No.");
    end;

    [Test]
    procedure T018_AllSourcesAssetTypeDefault()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: array[10] of Record "Dtld. Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        Assert.IsTrue(LineWithPrice.SetAssetSourceForSetup(TempDtldPriceCalculationSetup), 'SetAssetSource');
        // [GIVEN] 4 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default; 'C','D' for 'Sale' for 'Item', 'C' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Detailed Setup linked to Setup 'D', where 'All' sources sell all Items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup[1], PriceCalculationSetup[4].Code, '', DtldPriceCalculationSetup[1]."Source Group"::All, '');

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup is not found');

        // [THEN] Setup 'D' is returned
        TempDtldPriceCalculationSetup.TestField("Setup Code", PriceCalculationSetup[4].Code);
        TempDtldPriceCalculationSetup.TestField("Line No.", DtldPriceCalculationSetup[1]."Line No.");
    end;

    [Test]
    procedure T019_AllSourcesAllAssetsDefault()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        TempDtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup" temporary;
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
        LineWithPrice: Interface "Line With Price";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Detailed Setup] [UT]
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'A' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsFalse(PriceCalculationDtldSetup.FindSetup(TempDtldPriceCalculationSetup), 'Setup should no be found');
        // [THEN] Detaled setup is not found
        TempDtldPriceCalculationSetup.TestField("Setup Code", '');

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'Setup is not found');

        // [THEN] Setup 'A' is returned
        PriceCalculationSetup[5].TestField(Code, PriceCalculationSetup[1].Code);
    end;

    [Test]
    procedure T020_FindSetupForSalesDocDefaultMethod()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        Method: Enum "Price Calculation Method";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Sales] [UT]
        Initialize();
        // [GIVEN] 2 setup lines for "Lowest Price" method: 'A','B' for 'Sale' for 'All' asset types, 'A' - default
        // [GIVEN] 2 setup lines for "Test" method: 'C','D' for 'Sale' for 'All' asset types, 'C' - default
        AddFourSetupLines(PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup);
        // [GIVEN] Customer 'Y', where "Default Price Calc. Method" is 'Test Price'
        CustomerNo := CreateCustomerWithMethod(Method::"Test Price");
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        PriceCalculationSetup[5].TestField(Code, PriceCalculationSetup[3].Code);
    end;

    [Test]
    procedure T021_FindSetupForServiceDocDefaultMethod()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        Method: Enum "Price Calculation Method";
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Service] [UT]
        Initialize();
        // [GIVEN] 2 setup lines for "Lowest Price" method: 'A','B' for 'Sale' for 'All' asset types, 'A' - default
        // [GIVEN] 2 setup lines for "Test" method: 'C','D' for 'Sale' for 'All' asset types, 'C' - default
        AddFourSetupLines(PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup);
        // [GIVEN] Customer 'Y', where "Default Price Calc. Method" is 'Test Price'
        CustomerNo := CreateCustomerWithMethod(Method::"Test Price");
        // [GIVEN] Document Line, where Customer 'Y' sells Item 'X' 
        ServiceLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        PriceCalculationSetup[5].TestField(Code, PriceCalculationSetup[3].Code);
    end;

    [Test]
    procedure T022_FindSetupForPurchDocDefaultMethod()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        Method: Enum "Price Calculation Method";
        VendorNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Purchase] [UT]
        Initialize();
        // [GIVEN] 2 setup lines for "Lowest Price" method: 'A','B' for 'Purchase' for 'All' asset types, 'A' - default
        // [GIVEN] 2 setup lines for "Test" method: 'C','D' for 'Purchase' for 'All' asset types, 'C' - default
        AddFourSetupLines(PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup);
        // [GIVEN] Vendor 'Y', where "Default Price Calc. Method" is 'Test Price'
        VendorNo := CreateVendorWithMethod(Method::"Test Price");
        // [GIVEN] Document Line, where Vendor 'Y' sells Item 'X' 
        PurchLineAsLineWithPrice(ItemNo, VendorNo, LineWithPrice);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        PriceCalculationSetup[5].TestField(Code, PriceCalculationSetup[3].Code);
    end;

    [Test]
    procedure T023_FindSetupForRequisitionLineDefaultMethod()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        Method: Enum "Price Calculation Method";
        VendorNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Requisition Line] [UT]
        Initialize();
        // [GIVEN] 2 setup lines for "Lowest Price" method: 'A','B' for 'Purchase' for 'All' asset types, 'A' - default
        // [GIVEN] 2 setup lines for "Test" method: 'C','D' for 'Purchase' for 'All' asset types, 'C' - default
        AddFourSetupLines(PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup);
        // [GIVEN] Vendor 'Y', where "Default Price Calc. Method" is 'Test Price'
        VendorNo := CreateVendorWithMethod(Method::"Test Price");
        // [GIVEN] Requisition Line, where Vendor 'Y' sells Item 'X' 
        RequisitionLineAsLineWithPrice(ItemNo, VendorNo, LineWithPrice);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        PriceCalculationSetup[5].TestField(Code, PriceCalculationSetup[3].Code);
    end;

    [Test]
    procedure T024_FindSetupForItemJnlLineDefaultMethod()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        Method: Enum "Price Calculation Method";
        ItemNo: code[20];
    begin
        // [FEATURE] [Item Journal Line] [UT]
        Initialize();
        // [GIVEN] 2 setup lines for "Lowest Price" method: 'A','B' for 'Purchase' for 'All' asset types, 'A' - default
        // [GIVEN] 2 setup lines for "Test" method: 'C','D' for 'Purchase' for 'All' asset types, 'C' - default
        AddFourSetupLines(PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup);
        // [GIVEN] Item Jnl. Line, where Item 'X' and Method 'Test'
        ItemJnlLineAsLineWithPrice(ItemNo, Method::"Test Price", LineWithPrice);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        PriceCalculationSetup[5].TestField(Code, PriceCalculationSetup[3].Code);
    end;

    [Test]
    procedure T025_FindSetupForJobJnlLineDefaultMethod()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        Method: Enum "Price Calculation Method";
        JobNo: Code[20];
    begin
        // [FEATURE] [Standard Item Journal Line] [UT]
        Initialize();
        // [GIVEN] 2 setup lines for "Lowest Price" method: 'A','B' for 'Purchase' for 'All' asset types, 'A' - default
        // [GIVEN] 2 setup lines for "Test" method: 'C','D' for 'Purchase' for 'All' asset types, 'C' - default
        AddFourSetupLines(PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup);
        // [GIVEN] Job Jnl. Line, where Job 'J', Job Task 'JT' and Method 'Test'
        JobJnlLineAsLineWithPrice(JobNo, Method::"Test Price", LineWithPrice);
        // [GIVEN] Detailed Setup line for D, where Source is Job 'J'
        LibraryPriceCalculation.AddDtldSetup(
            DtldPriceCalculationSetup, PriceCalculationSetup[4].Code, '', DtldPriceCalculationSetup."Source Group"::Job, JobNo);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'Setup is not found');

        // [THEN] Setup 'D' is returned
        PriceCalculationSetup[5].TestField(Code, PriceCalculationSetup[4].Code);
    end;

    [Test]
    procedure T026_FindSetupForRequisitionLineDefaultMethodBlankVendor()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        VendorNo: Code[20];
        ItemNo: code[20];
    begin
        // [FEATURE] [Requisition Line] [UT]
        Initialize();
        // [GIVEN] 2 setup lines for "Lowest Price" method: 'A','B' for 'Purchase' for 'All' asset types, 'A' - default
        // [GIVEN] 2 setup lines for "Test" method: 'C','D' for 'Purchase' for 'All' asset types, 'C' - default
        AddFourSetupLines(PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup);
        // [GIVEN] Purchase Setup, where "Default Price Calc. Method" is 'Test Price'
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Price Calculation Method" := PurchasesPayablesSetup."Price Calculation Method"::"Test Price";
        PurchasesPayablesSetup.Modify();
        VendorNo := '';
        // [GIVEN] Requisition Line, where Vendor <blank> sells Item 'X' 
        RequisitionLineAsLineWithPrice(ItemNo, VendorNo, LineWithPrice);

        // [WHEN] FindSetup() for the Document Line
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'Setup is not found');

        // [THEN] Setup 'C' is returned
        PriceCalculationSetup[5].TestField(Code, PriceCalculationSetup[3].Code);
    end;

    [Test]
    procedure T030_SetAssetSourceForSetupSalesLine()
    var
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceType: Enum "Price Type";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        ExpectedMethod := ExpectedMethod::"Test Price";
        SalesLine."Price Calculation Method" := ExpectedMethod;
        SalesLinePrice.SetLine(PriceType::Sale, SalesLine);

        SalesLinePrice.SetAssetSourceForSetup(DtldPriceCalculationSetup);

        DtldPriceCalculationSetup.TestField(Method, ExpectedMethod);
    end;

    [Test]
    procedure T031_SetAssetSourceForSetupServiceLine()
    var
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceType: Enum "Price Type";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        ExpectedMethod := ExpectedMethod::"Test Price (not Implemented)";
        ServiceLine."Price Calculation Method" := ExpectedMethod;
        ServiceLinePrice.SetLine(PriceType::Sale, ServiceLine);

        ServiceLinePrice.SetAssetSourceForSetup(DtldPriceCalculationSetup);

        DtldPriceCalculationSetup.TestField(Method, ExpectedMethod);
    end;

    [Test]
    procedure T032_SetAssetSourceForSetupPurchaseLine()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceType: Enum "Price Type";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        ExpectedMethod := ExpectedMethod::"Test Price (not Implemented)";
        PurchaseLine."Price Calculation Method" := ExpectedMethod;
        PurchaseLinePrice.SetLine(PriceType::Sale, PurchaseLine);

        PurchaseLinePrice.SetAssetSourceForSetup(DtldPriceCalculationSetup);

        DtldPriceCalculationSetup.TestField(Method, ExpectedMethod);
    end;

    [Test]
    procedure T033_SetAssetSourceForSetupRequisitionLine()
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceType: Enum "Price Type";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        ExpectedMethod := ExpectedMethod::"Test Price (not Implemented)";
        RequisitionLine."Price Calculation Method" := ExpectedMethod;
        RequisitionLinePrice.SetLine(PriceType::Sale, RequisitionLine);

        RequisitionLinePrice.SetAssetSourceForSetup(DtldPriceCalculationSetup);

        DtldPriceCalculationSetup.TestField(Method, ExpectedMethod);
    end;

    [Test]
    procedure T034_SetAssetSourceForSetupItemJnlLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceType: Enum "Price Type";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        ExpectedMethod := ExpectedMethod::"Test Price (not Implemented)";
        ItemJournalLine."Price Calculation Method" := ExpectedMethod;
        ItemJournalLinePrice.SetLine(PriceType::Sale, ItemJournalLine);

        ItemJournalLinePrice.SetAssetSourceForSetup(DtldPriceCalculationSetup);

        DtldPriceCalculationSetup.TestField(Method, ExpectedMethod);
    end;

    [Test]
    procedure T035_SetAssetSourceForSetupJobJnlLine()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceType: Enum "Price Type";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        ExpectedMethod := ExpectedMethod::"Test Price (not Implemented)";
        LibraryJob.CreateJob(Job);
        JobJournalLine."Job No." := Job."No.";
        JobJournalLine."Price Calculation Method" := ExpectedMethod;
        JobJournalLinePrice.SetLine(PriceType::Sale, JobJournalLine);

        JobJournalLinePrice.SetAssetSourceForSetup(DtldPriceCalculationSetup);

        DtldPriceCalculationSetup.TestField(Method, ExpectedMethod);
    end;

    [Test]
    procedure T036_SetAssetSourceForSetupJobPlanningLine()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLinePrice: Codeunit "Job Planning Line - Price";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceType: Enum "Price Type";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        ExpectedMethod := ExpectedMethod::"Test Price (not Implemented)";
        LibraryJob.CreateJob(Job);
        JobPlanningLine."Job No." := Job."No.";
        JobPlanningLine."Price Calculation Method" := ExpectedMethod;
        JobPlanningLinePrice.SetLine(PriceType::Purchase, JobPlanningLine);

        JobPlanningLinePrice.SetAssetSourceForSetup(DtldPriceCalculationSetup);

        DtldPriceCalculationSetup.TestField(Method, ExpectedMethod);
    end;

    [Test]
    procedure T037_SetAssetSourceForSetupStdItemJnlLine()
    var
        StdItemJournalLine: Record "Standard Item Journal Line";
        StdItemJournalLinePrice: Codeunit "Std. Item Jnl. Line - Price";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceType: Enum "Price Type";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        ExpectedMethod := ExpectedMethod::"Test Price (not Implemented)";
        StdItemJournalLine."Price Calculation Method" := ExpectedMethod;
        StdItemJournalLinePrice.SetLine(PriceType::Sale, StdItemJournalLine);

        StdItemJournalLinePrice.SetAssetSourceForSetup(DtldPriceCalculationSetup);

        DtldPriceCalculationSetup.TestField(Method, ExpectedMethod);
    end;

    [Test]
    procedure T040_SalesLineGetsMethodFromSalesSetup()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        ExpectedMethod := ExpectedMethod::"Test Price";
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Price Calculation Method" := ExpectedMethod;
        SalesReceivablesSetup.Modify();

        // [WHEN] Set "Sell-to Customer No." as 'C', where "Price Calculation Method" is <blank>
        SalesHeader.Init();
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        // [THEN] Header, where "Price Calculation Method" is 'X'
        SalesHeader.Testfield("Price Calculation Method", ExpectedMethod);
    end;

    [Test]
    procedure T041_SalesLineGetsMethodFromCustomerPriceGroup()
    var
        Customer: Record Customer;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        ExpectedMethod := ExpectedMethod::"Test Price";
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Price Calculation Method" := ExpectedMethod;
        SalesReceivablesSetup.Modify();
        // [GIVEN] CustomerPriceGroup 'CPG', where "Price Calculation Method" is 'Y'
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup."Price Calculation Method" := ExpectedMethod::"Test Price (not Implemented)";
        CustomerPriceGroup.Modify();
        // [GIVEN] Customer 'C', where "Customer Price Group" is 'CPG', "Price Calculation Method" is <blank>
        LibrarySales.CreateCustomer(Customer);
        Customer."Customer Price Group" := CustomerPriceGroup.Code;
        Customer.Modify();

        // [WHEN] Set "Sell-to Customer No." as 'C', where "Price Calculation Method" is <blank>
        SalesHeader.Init();
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] Header, where "Price Calculation Method" is 'Y'
        SalesHeader.Testfield("Price Calculation Method", ExpectedMethod);
    end;

    [Test]
    procedure T042_SalesLineGetsMethodFromCustomer()
    var
        Customer: Record Customer;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ExpectedMethod: Enum "Price Calculation Method";
    begin
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Price Calculation Method" := ExpectedMethod::"Lowest Price";
        SalesReceivablesSetup.Modify();

        // [GIVEN] CustomerPriceGroup 'CPG', where "Price Calculation Method" is 'Y'
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup."Price Calculation Method" := ExpectedMethod::"Test Price (not Implemented)";
        CustomerPriceGroup.Modify();

        // [GIVEN] Customer 'C', where "Price Calculation Method" is 'Z'
        LibrarySales.CreateCustomer(Customer);
        Customer."Customer Price Group" := CustomerPriceGroup.Code;
        Customer."Price Calculation Method" := ExpectedMethod::"Test Price";
        Customer.Modify();

        // [WHEN] Set "Sell-to Customer No." as 'C', 
        SalesHeader.Init();
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");

        // [THEN] Header, where "Price Calculation Method" is 'Z'
        SalesHeader.Testfield("Price Calculation Method", ExpectedMethod::"Test Price");
    end;

    [Test]
    procedure T051_GetSourceAssetPairForSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempPriceSource: Record "Price Source" temporary;
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceType: Enum "Price Type";
    begin
        // [FEATURE] [Detailed Setup] [UT] [Sales Line]
        SalesHeader."Bill-to Customer No." := LibrarySales.CreateCustomerNo();
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := LibraryInventory.CreateItemNo();
        SalesLinePrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);
        Assert.IsTrue(SalesLinePrice.CopyToBuffer(PriceCalculationBufferMgt), 'CopyToBuffer');
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.Testfield("Price Type", PriceType::Sale);
        PriceCalculationBuffer.Testfield("Asset Type", PriceCalculationBuffer."Asset Type"::Item);
        PriceCalculationBuffer.Testfield("Asset No.", SalesLine."No.");
        Assert.AreEqual(PriceCalculationBufferMgt.GetSource(Enum::"Price Source Type"::Customer), SalesHeader."Bill-to Customer No.", 'Wrong Source Customer');
        Assert.IsTrue(PriceCalculationBufferMgt.GetSources(TempPriceSource), 'GetSources has failed');
        Assert.RecordCount(TempPriceSource, 2);
        TempPriceSource.FindFirst();
        TempPriceSource.TestField("Source Type", Enum::"Price Source Type"::"All Customers");
    end;

    [Test]
    procedure T052_GetSourceAssetPairForPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempPriceSource: Record "Price Source" temporary;
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceType: Enum "Price Type";
    begin
        // [FEATURE] [Detailed Setup] [UT] [Purchase Line]
        PurchaseHeader."Buy-from Vendor No." := LibraryPurchase.CreateVendorNo();
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        PurchaseLine."No." := LibraryERM.CreateGLAccountNo();
        PurchaseLinePrice.Setline(PriceType::Purchase, PurchaseHeader, PurchaseLine);
        Assert.IsTrue(PurchaseLinePrice.CopyToBuffer(PriceCalculationBufferMgt), 'CopyToBuffer');
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.Testfield("Price Type", PriceType::Purchase);
        PriceCalculationBuffer.Testfield("Asset Type", PriceCalculationBuffer."Asset Type"::"G/L Account");
        PriceCalculationBuffer.Testfield("Asset No.", PurchaseLine."No.");
        Assert.AreEqual(PriceCalculationBufferMgt.GetSource(Enum::"Price Source Type"::Vendor), PurchaseHeader."Buy-from Vendor No.", 'Wrong Source Vendor');
        Assert.IsTrue(PriceCalculationBufferMgt.GetSources(TempPriceSource), 'GetSources has failed');
        Assert.RecordCount(TempPriceSource, 2);
        TempPriceSource.FindFirst();
        TempPriceSource.TestField("Source Type", Enum::"Price Source Type"::"All Vendors");
    end;

    [Test]
    procedure T053_GetSourceAssetPairForJobJnlLine()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        Resource: Record Resource;
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempPriceSource: Record "Price Source" temporary;
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceType: Enum "Price Type";
    begin
        // [FEATURE] [Detailed Setup] [UT] [Job Journal]
        JobJournalLine."Entry Type" := JobJournalLine."Entry Type"::Usage;
        JobJournalLine.Type := JobJournalLine.Type::Resource;
        JobJournalLine."No." := 'R';
        JobJournalLine."Job No." := 'J';
        Resource."No." := JobJournalLine."No.";
        if Resource.Insert() then;
        Job."No." := JobJournalLine."Job No.";
        if Job.Insert() then;

        JobJournalLinePrice.SetLine(PriceType::Purchase, JobJournalLine);
        Assert.IsTrue(JobJournalLinePrice.CopyToBuffer(PriceCalculationBufferMgt), 'CopyToBuffer');
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.Testfield("Price Type", PriceType::Purchase);
        PriceCalculationBuffer.Testfield("Asset Type", PriceCalculationBuffer."Asset Type"::Resource);
        PriceCalculationBuffer.Testfield("Asset No.", Resource."No.");
        Assert.IsTrue(PriceCalculationBufferMgt.GetSources(TempPriceSource), 'GetSources has failed');
        Assert.RecordCount(TempPriceSource, 3);
        TempPriceSource.FindSet();
        TempPriceSource.TestField("Source Type", Enum::"Price Source Type"::"All Vendors");
        TempPriceSource.TestField(Level, 0);
        TempPriceSource.Next();
        TempPriceSource.TestField("Source Type", Enum::"Price Source Type"::"All Jobs");
        TempPriceSource.TestField(Level, 1);
        TempPriceSource.Next();
        TempPriceSource.TestField("Source Type", Enum::"Price Source Type"::Job);
        TempPriceSource.TestField("Source No.", Job."No.");
        TempPriceSource.TestField(Level, 2);
    end;

    [Test]
    procedure T070_DefaultMethodItemJnlLineOnEntryType()
    var
        ItemJournalLine: Record "Item Journal Line";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Item Journal Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);

        ItemJournalLine.Init();
        ItemJournalLine.TestField("Price Calculation Method", ItemJournalLine."Price Calculation Method"::" ");
        // [WHEN] Set "Entry Type" as 'Positive Adjmt.'
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, ItemJournalLine."Price Calculation Method", 'Positive Adjmt.');

        // [WHEN] Set "Entry Type" as 'Sale'
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Sale);
        // [THEN] "Price Calculation Method" is 'X'
        Assert.AreEqual(ExpectedMethod[1], ItemJournalLine."Price Calculation Method", 'Sale');

        // [WHEN] Set "Entry Type" as 'Negative Adjmt.'
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, ItemJournalLine."Price Calculation Method", 'Negative Adjmt.');

        // [WHEN] Set "Entry Type" as 'Output'
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Output);
        // [THEN] "Price Calculation Method" is 'Y'
        Assert.AreEqual(ExpectedMethod[2], ItemJournalLine."Price Calculation Method", 'Output');

        // [WHEN] Set "Entry Type" as 'Assembly Consumption'
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Assembly Consumption");
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, ItemJournalLine."Price Calculation Method", 'Assembly Consumption');

        // [WHEN] Set "Entry Type" as 'Assembly Output'
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Assembly Output");
        // [THEN] "Price Calculation Method" is 'Y'
        Assert.AreEqual(ExpectedMethod[2], ItemJournalLine."Price Calculation Method", 'Assembly Output');

        // [WHEN] Set "Entry Type" as 'Consumption'
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, ItemJournalLine."Price Calculation Method", 'Consumption');

        // [WHEN] Set "Entry Type" as 'Transfer'
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Transfer);
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, ItemJournalLine."Price Calculation Method", 'Transfer');
    end;

    [Test]
    procedure T071_DefaultMethodItemJnlLineOnNewEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LastItemJournalLine: Record "Item Journal Line";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Item Journal Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);

        // [GIVEN] Last Item Journal line , where "Entry Type" is 'Purchase'
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LastItemJournalLine."Entry Type" := LastItemJournalLine."Entry Type"::Purchase;
        LastItemJournalLine.TestField("Price Calculation Method", ItemJournalLine."Price Calculation Method"::" ");

        // [WHEN] SetUpNewLine()
        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := ItemJournalTemplate.Name;
        ItemJournalLine."Journal Batch Name" := ItemJournalBatch.Name;
        ItemJournalLine.SetUpNewLine(LastItemJournalLine);

        // [THEN] "Price Calculation Method" is 'Y'
        ItemJournalLine.TestField("Price Calculation Method", ExpectedMethod[2]);
    end;

    [Test]
    procedure T072_DefaultMethodStandardItemJnlLineOnEntryType()
    var
        StandardItemJournalLine: Record "Standard Item Journal Line";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Standard Item Journal Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);

        StandardItemJournalLine.Init();
        StandardItemJournalLine.TestField("Price Calculation Method", StandardItemJournalLine."Price Calculation Method"::" ");
        // [WHEN] Set "Entry Type" as 'Positive Adjmt.'
        StandardItemJournalLine.Validate("Entry Type", StandardItemJournalLine."Entry Type"::"Positive Adjmt.");
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, StandardItemJournalLine."Price Calculation Method", 'Positive Adjmt.');

        // [WHEN] Set "Entry Type" as 'Sale'
        StandardItemJournalLine.Validate("Entry Type", StandardItemJournalLine."Entry Type"::Sale);
        // [THEN] "Price Calculation Method" is 'X'
        Assert.AreEqual(ExpectedMethod[1], StandardItemJournalLine."Price Calculation Method", 'Sale');

        // [WHEN] Set "Entry Type" as 'Negative Adjmt.'
        StandardItemJournalLine.Validate("Entry Type", StandardItemJournalLine."Entry Type"::"Negative Adjmt.");
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, StandardItemJournalLine."Price Calculation Method", 'Negative Adjmt.');

        // [WHEN] Set "Entry Type" as 'Output'
        StandardItemJournalLine.Validate("Entry Type", StandardItemJournalLine."Entry Type"::Output);
        // [THEN] "Price Calculation Method" is 'Y'
        Assert.AreEqual(ExpectedMethod[2], StandardItemJournalLine."Price Calculation Method", 'Output');

        // [WHEN] Set "Entry Type" as 'Assembly Consumption'
        StandardItemJournalLine.Validate("Entry Type", StandardItemJournalLine."Entry Type"::"Assembly Consumption");
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, StandardItemJournalLine."Price Calculation Method", 'Assembly Consumption');

        // [WHEN] Set "Entry Type" as 'Assembly Output'
        StandardItemJournalLine.Validate("Entry Type", StandardItemJournalLine."Entry Type"::"Assembly Output");
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, StandardItemJournalLine."Price Calculation Method", 'Assembly Output');

        // [WHEN] Set "Entry Type" as 'Consumption'
        StandardItemJournalLine.Validate("Entry Type", StandardItemJournalLine."Entry Type"::Consumption);
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, StandardItemJournalLine."Price Calculation Method", 'Consumption');

        // [WHEN] Set "Entry Type" as 'Transfer'
        StandardItemJournalLine.Validate("Entry Type", StandardItemJournalLine."Entry Type"::Transfer);
        // [THEN] "Price Calculation Method" is <blank>
        Assert.AreEqual(0, StandardItemJournalLine."Price Calculation Method", 'Transfer');
    end;

    [Test]
    procedure T073_DefaultMethodRequisitionLineOnVendorNo()
    var
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Requisition Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);
        // [GIVEN] Vendor "V", where "Price Calculation Method" is 'Z'
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Price Calculation Method" := ExpectedMethod[3];
        Vendor.Modify();

        // [WHEN] Set "Vendor No." as 'V'
        RequisitionLine.Init();
        RequisitionLine.TestField("Price Calculation Method", RequisitionLine."Price Calculation Method"::" ");
        RequisitionLine.Validate("Vendor No.", Vendor."No.");
        // [THEN] "Price Calculation Method" is 'Z'
        RequisitionLine.TestField("Price Calculation Method", ExpectedMethod[3]);
    end;

    [Test]
    procedure T074_DefaultMethodRequisitionLineOnBlankVendorNo()
    var
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Requisition Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);

        // [GIVEN] Vendor "V", where "Price Calculation Method" is 'Z'
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Price Calculation Method" := ExpectedMethod[3];
        Vendor.Modify();

        // [WHEN] Set "Vendor No." as <blank>
        RequisitionLine.Init();
        RequisitionLine.Validate("Vendor No.", '');
        // [THEN] "Price Calculation Method" is 'Y' (from Purchase Setup)
        RequisitionLine.TestField("Price Calculation Method", ExpectedMethod[2]);
    end;

    [Test]
    procedure T075_DefaultMethodRequisitionLineOnInvalidVendorNo()
    var
        RequisitionLine: Record "Requisition Line";
        VendorNo: Code[20];
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Requisition Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);

        // [GIVEN] Vendor "V" does no exist
        VendorNo := LibraryRandom.RandText(20);

        // [WHEN] Set "Vendor No." as 'V'
        RequisitionLine.Init();
        RequisitionLine.Validate("Vendor No.", VendorNo);
        // [THEN] "Price Calculation Method" is 'Y' (from Purchase Setup)
        RequisitionLine.TestField("Price Calculation Method", ExpectedMethod[2]);
    end;

    [Test]
    procedure T076_DefaultMethodRequisitionLineOnNewLine()
    var
        RequisitionLine: Record "Requisition Line";
        LastRequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Requisition Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);

        // [WHEN] SetUpNewLine()
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName());
        RequisitionLine.Init();
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        RequisitionLine.SetUpNewLine(LastRequisitionLine);
        // [THEN] "Price Calculation Method" is 'Y' (from Purchase Setup)
        RequisitionLine.TestField("Price Calculation Method", ExpectedMethod[2]);
    end;

    [Test]
    procedure T080_DefaultMethodJobJnlLineOnNewLine()
    var
        JobJournalLine: Record "Job Journal Line";
        LastJobJournalLine: Record "Job Journal Line";
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Job Journal Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);

        // [WHEN] SetUpNewLine()
        LibraryJob.CreateJobJournalTemplate(JobJnlTemplate);
        LibraryJob.CreateJobJournalBatch(JobJnlTemplate.Name, JobJnlBatch);
        JobJournalLine.Init();
        JobJournalLine."Journal Template Name" := JobJnlTemplate.Name;
        JobJournalLine."Journal Batch Name" := JobJnlBatch.Name;
        JobJournalLine.SetUpNewLine(LastJobJournalLine);

        // [THEN] "Price Calculation Method" is 'X' (from Sales Setup)
        JobJournalLine.TestField("Price Calculation Method", ExpectedMethod[1]);
        // [THEN] "Cost Calculation Method" is 'Y' (from Purchase Setup)
        JobJournalLine.TestField("Cost Calculation Method", ExpectedMethod[2]);
    end;

    [Test]
    procedure T081_DefaultMethodJobJnlLineOnJobNo()
    var
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Job Journal Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);
        // [GIVEN] Job 'J', where "Price Calculation Method" is 'Y', "Cost Calculation Method" is 'Z'
        LibraryJob.CreateJob(Job);
        Job."Price Calculation Method" := ExpectedMethod[2];
        Job."Cost Calculation Method" := ExpectedMethod[3];
        Job.Modify();

        // [WHEN] Set "Job No." as 'J'
        JobJournalLine.Init();
        JobJournalLine.Validate("Job No.", Job."No.");

        // [THEN] "Price Calculation Method" is 'Y'
        JobJournalLine.TestField("Price Calculation Method", ExpectedMethod[2]);
        // [THEN] "Cost Calculation Method" is 'Z' 
        JobJournalLine.TestField("Cost Calculation Method", ExpectedMethod[3]);
    end;

    [Test]
    procedure T082_DefaultMethodJobJnlLineOnJobNoWithCustPriceGroup()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Job Journal Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);
        // [GIVEN] CustomerPriceGroup 'CPG', where "Price Calculation Method" is 'Z'
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup."Price Calculation Method" := ExpectedMethod::"Test Price (not Implemented)";
        CustomerPriceGroup.Modify();
        // [GIVEN] Job 'J', where "Customer Price Group" is 'CPG', "Price Calculation Method" is <blank>, "Cost Calculation Method" is <blank>
        LibraryJob.CreateJob(Job);
        Job."Customer Price Group" := CustomerPriceGroup.Code;
        Job."Price Calculation Method" := Job."Price Calculation Method"::" ";
        Job."Cost Calculation Method" := Job."Cost Calculation Method"::" ";
        Job.Modify();

        // [WHEN] Set "Job No." as 'J'
        JobJournalLine.Init();
        JobJournalLine.Validate("Job No.", Job."No.");

        // [THEN] "Price Calculation Method" is 'Z' (from Customer Price Group)
        JobJournalLine.TestField("Price Calculation Method", ExpectedMethod[3]);
        // [THEN] "Cost Calculation Method" is 'Y' (from Purchase Setup)
        JobJournalLine.TestField("Cost Calculation Method", ExpectedMethod[2]);
    end;

    [Test]
    procedure T085_DefaultMethodJobPlanningLineOnNewLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        LastJobPlanningLine: Record "Job Planning Line";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Job Planning Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);

        // [WHEN] SetUpNewLine()
        JobPlanningLine.Init();
        JobPlanningLine.SetUpNewLine(LastJobPlanningLine);

        // [THEN] "Price Calculation Method" is 'X' (from Sales Setup)
        JobPlanningLine.TestField("Price Calculation Method", ExpectedMethod[1]);
        // [THEN] "Cost Calculation Method" is 'Y' (from Purchase Setup)
        JobPlanningLine.TestField("Cost Calculation Method", ExpectedMethod[2]);
    end;

    [Test]
    procedure T086_DefaultMethodJobPlanningLineOnJobNo()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Job Planning Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);
        // [GIVEN] Job 'J', where "Price Calculation Method" is 'Y', "Cost Calculation Method" is 'Z'
        LibraryJob.CreateJob(Job);
        Job."Price Calculation Method" := ExpectedMethod[2];
        Job."Cost Calculation Method" := ExpectedMethod[3];
        Job.Modify();
        // [GIVEN] Set "Job No." as 'J'
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);

        // [WHEN] Validate "No." as an Item
        JobPlanningLine.Validate("No.", LibraryInventory.CreateItemNo());

        // [THEN] "Price Calculation Method" is 'Y'
        JobPlanningLine.TestField("Price Calculation Method", ExpectedMethod[2]);
        // [THEN] "Cost Calculation Method" is 'Z' 
        JobPlanningLine.TestField("Cost Calculation Method", ExpectedMethod[3]);
    end;

    [Test]
    procedure T087_DefaultMethodJobPlanningLineOnJobNoWithCustPriceGroup()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        ExpectedMethod: array[3] of Enum "Price Calculation Method";
    begin
        // [FEATURE] [Job Planning Line] [UT]
        Initialize();
        // [GIVEN] Sales Setup, where "Price Calculation Method" is 'X'
        // [GIVEN] Purchase Setup, where "Price Calculation Method" is 'Y'
        SetupSalesPurchaseMethods(ExpectedMethod);
        // [GIVEN] CustomerPriceGroup 'CPG', where "Price Calculation Method" is 'Z'
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup."Price Calculation Method" := ExpectedMethod::"Test Price (not Implemented)";
        CustomerPriceGroup.Modify();
        // [GIVEN] Job 'J', where "Customer Price Group" is 'CPG', "Price Calculation Method" is <blank>, "Cost Calculation Method" is <blank>
        LibraryJob.CreateJob(Job);
        Job."Customer Price Group" := CustomerPriceGroup.Code;
        Job."Price Calculation Method" := Job."Price Calculation Method"::" ";
        Job."Cost Calculation Method" := Job."Cost Calculation Method"::" ";
        Job.Modify();
        // [GIVEN] Set "Job No." as 'J'
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);

        // [WHEN] Validate "No." as an Item
        JobPlanningLine.Validate("No.", LibraryInventory.CreateItemNo());

        // [THEN] "Price Calculation Method" is 'Z' (from Customer Price Group)
        JobPlanningLine.TestField("Price Calculation Method", ExpectedMethod[3]);
        // [THEN] "Cost Calculation Method" is 'Y' (from Purchase Setup)
        JobPlanningLine.TestField("Cost Calculation Method", ExpectedMethod[2]);
    end;

    [Test]
    procedure T090_PriceCalcMethodVisibleOnItemJournalPage()
    var
        ItemJournal: TestPage "Item Journal";
        TestPriceCalcSetup: Codeunit "Test Price Calc. Setup";
    begin
        // [FEATURE] [UI]
        Initialize();
        BindSubscription(TestPriceCalcSetup); // to handle OnBeforeOpenJournal
        // [THEN] "Price Calculation Method" is not visible if feature disabled
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        ItemJournal.OpenView();
        Assert.IsFalse(ItemJournal."Price Calculation Method".Visible(), '"Price Calculation Method" should not be Visible');
        ItemJournal.Close();
        Commit();

        // [THEN] "Price Calculation Method" visible if feature enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        ItemJournal.OpenView();
        Assert.IsTrue(ItemJournal."Price Calculation Method".Visible(), '"Price Calculation Method" should be Visible');
        ItemJournal.Close();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Journal", 'OnBeforeOpenJournal', '', false, false)]
    local procedure OnBeforeOpenItemJournal(var ItemJournalLine: Record "Item Journal Line"; var ItemJnlMgt: Codeunit ItemJnlManagement; CurrentJnlBatchName: Code[10]; var IsHandled: Boolean);
    begin
        IsHandled := true;
    end;

    [Test]
    procedure T091_PriceCalcMethodVisibleOnItemJournalLinesPage()
    var
        ItemJournalLines: TestPage "Item Journal Lines";
    begin
        // [FEATURE] [UI]
        Initialize();
        // [THEN] "Price Calculation Method" is not visible if feature disabled
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        ItemJournalLines.OpenView();
        Assert.IsFalse(ItemJournalLines."Price Calculation Method".Visible(), '"Price Calculation Method" should not be Visible');
        ItemJournalLines.Close();
        Commit();

        // [THEN] "Price Calculation Method" visible if feature enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        ItemJournalLines.OpenView();
        Assert.IsTrue(ItemJournalLines."Price Calculation Method".Visible(), '"Price Calculation Method" should be Visible');
        ItemJournalLines.Close();
    end;

    [Test]
    procedure T092_PriceCalcMethodVisibleOnJobJournalPage()
    var
        JobJournal: TestPage "Job Journal";
        TestPriceCalcSetup: Codeunit "Test Price Calc. Setup";
    begin
        // [FEATURE] [UI]
        Initialize();
        BindSubscription(TestPriceCalcSetup); // to handle OnBeforeOpenJournal
        // [THEN] "Price Calculation Method" is not visible if feature disabled
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        JobJournal.OpenView();
        Assert.IsFalse(JobJournal."Price Calculation Method".Visible(), '"Price Calculation Method" should not be Visible');
        JobJournal.Close();
        Commit();

        // [THEN] "Price Calculation Method" visible if feature enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        JobJournal.OpenView();
        Assert.IsTrue(JobJournal."Price Calculation Method".Visible(), '"Price Calculation Method" should be Visible');
        JobJournal.Close();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Journal", 'OnBeforeOpenJournal', '', false, false)]
    local procedure OnBeforeOpenJobJournal(var JobJournalLine: Record "Job Journal Line"; var JobJnlManagement: Codeunit JobJnlManagement; CurrentJnlBatchName: Code[10]; var IsHandled: Boolean);
    begin
        IsHandled := true;
    end;

    [Test]
    procedure T093_PriceCalcMethodVisibleOnJobPlanningLinesPage()
    var
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [FEATURE] [UI]
        Initialize();
        // [THEN] "Price Calculation Method" is not visible if feature disabled
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        JobPlanningLines.OpenView();
        Assert.IsFalse(JobPlanningLines."Price Calculation Method".Visible(), '"Price Calculation Method" should not be Visible');
        JobPlanningLines.Close();
        Commit();

        // [THEN] "Price Calculation Method" visible if feature enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        JobPlanningLines.OpenView();
        Assert.IsTrue(JobPlanningLines."Price Calculation Method".Visible(), '"Price Calculation Method" should be Visible');
        JobPlanningLines.Close();
    end;

    [Test]
    procedure T094_PriceCalcMethodVisibleOnRequisitionLinesPage()
    var
        RequisitionLines: TestPage "Requisition Lines";
    begin
        // [FEATURE] [UI]
        Initialize();
        // [THEN] "Price Calculation Method" is not visible if feature disabled
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        RequisitionLines.OpenView();
        Assert.IsFalse(RequisitionLines."Price Calculation Method".Visible(), '"Price Calculation Method" should not be Visible');
        RequisitionLines.Close();
        Commit();

        // [THEN] "Price Calculation Method" visible if feature enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        RequisitionLines.OpenView();
        Assert.IsTrue(RequisitionLines."Price Calculation Method".Visible(), '"Price Calculation Method" should be Visible');
        RequisitionLines.Close();
    end;

    [Test]
    procedure T095_PriceCalcMethodVisibleOnReqWorksheetPage()
    var
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [FEATURE] [UI]
        Initialize();
        // [THEN] "Price Calculation Method" is not visible if feature disabled
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        ReqWorksheet.OpenView();
        Assert.IsFalse(ReqWorksheet."Price Calculation Method".Visible(), '"Price Calculation Method" should not be Visible');
        ReqWorksheet.Close();
        Commit();

        // [THEN] "Price Calculation Method" visible if feature enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        ReqWorksheet.OpenView();
        Assert.IsTrue(ReqWorksheet."Price Calculation Method".Visible(), '"Price Calculation Method" should be Visible');
        ReqWorksheet.Close();
    end;

    [Test]
    procedure T096_PriceCalcMethodVisibleOnStdItemJournalPage()
    var
        StandardItemJournal: TestPage "Standard Item Journal";
    begin
        Initialize();
        // [THEN] "Price Calculation Method" is not visible if feature disabled
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        StandardItemJournal.OpenView();
        Assert.IsFalse(StandardItemJournal.StdItemJnlLines."Price Calculation Method".Visible(), '"Price Calculation Method" should not be Visible');
        StandardItemJournal.Close();
        Commit();

        // [THEN] "Price Calculation Method" visible if feature enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        StandardItemJournal.OpenView();
        Assert.IsTrue(StandardItemJournal.StdItemJnlLines."Price Calculation Method".Visible(), '"Price Calculation Method" should be Visible');
        StandardItemJournal.Close();
    end;

    [Test]
    procedure T100_FindSetupOfTwo()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        ExpectedCode: Code[100];
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        Initialize();
        // [GIVEN] 4 setup lines: 'A','B', where 'A' and 'B' are 'Sale' for 'All', 'A' - default; 'C' and 'D' are 'Purchase' for 'All', 'C' - default
        PriceCalculationSetup[5].DeleteAll();
        ExpectedCode := LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Sales Line, where Item 'X' and Customer 'Y'
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);

        // [WHEN] FindSetup()
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'not found setup');

        // [THEN] Setup 'C' is returned
        PriceCalculationSetup[5].TestField(Code, ExpectedCode);
    end;

    [Test]
    procedure T101_FindSetupOfTwoDefaultIsDisabled()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        ExpectedCode: Code[100];
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        Initialize();
        // [GIVEN] 4 setup lines: 'A','B', where 'A' and 'B' are 'Sale' for 'All', 'A' - default, but disabled; 'C' and 'D' are 'Purchase' for 'All', 'C' - default
        PriceCalculationSetup[5].DeleteAll();
        ExpectedCode := LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.DisableSetup(PriceCalculationSetup[1]);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Purchase, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Sales Line, where Item 'X' and Customer 'Y'
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);

        // [WHEN] FindSetup()
        // [THEN] Setup is not found
        Assert.IsFalse(PriceCalculationMgt.FindSetup(LineWithPrice, PriceCalculationSetup[5]), 'not found setup');
    end;


    [Test]
    procedure T110_FindSetupAssetTypeItemSet()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        FoundPriceCalculationSetup: Record "Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        ExpectedCode: Code[100];
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        Initialize();
        // [GIVEN] 4 setup lines: 'A','B','C','D', where 'A' and 'B' are for 'All', 'A' - default; 'C' and 'D' are for 'Item', 'C' - default.
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        ExpectedCode := LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        // [GIVEN] Sales Line, where Item 'X' and Customer 'Y'
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);

        // [WHEN] FindSetup()
        assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, FoundPriceCalculationSetup), 'not found setup');

        // [THEN] Setup 'C' is returned
        FoundPriceCalculationSetup.TestField(Code, ExpectedCode);
        // DtldPriceCalculationSetup.TestField("Codeunit Id", Codeunit::"Test Price Calc. Setup");
    end;

    [Test]
    procedure T111_FindSetupDtldSetupForCustomerAndItem()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        FoundPriceCalculationSetup: Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        ExpectedCode: Code[100];
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        Initialize();
        // [GIVEN] 4 setup lines: 'A','B','C','D', where 'A' and 'B' are for 'All', 'A' - default; 'C' and 'D' are for 'Item', 'D' - default.
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        ExpectedCode := LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        // [GIVEN] Sales Line, where Item 'X' and Customer 'Y'
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);

        // [GIVEN] Detailed Setup linked to Setup 'C', where Item 'X' and 'Customer' 'Y'
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup, ExpectedCode, ItemNo, DtldPriceCalculationSetup."Source Group"::Customer, CustomerNo);

        // [WHEN] FindSetup()
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, FoundPriceCalculationSetup), 'not found setup');

        // [THEN] Setup 'C' is returned
        FoundPriceCalculationSetup.TestField(Code, ExpectedCode);
    end;

    [Test]
    procedure T112_FindSetupDtldSetupForCustomerAndAllItems()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        FoundPriceCalculationSetup: Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        ExpectedCode: Code[100];
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        Initialize();
        // [GIVEN] 4 setup lines: 'A','B','C','D', where 'A' and 'B' are for 'All', 'A' - default; 'C' and 'D' are for 'Item', 'D' - default.
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        ExpectedCode := LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        // [GIVEN] Sales Line, where Item 'X' and Customer 'Y'
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);
        // [GIVEN] Detailed Setup linked to Setup 'C', where Customer 'Y' sells 'All' items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup, ExpectedCode, '', DtldPriceCalculationSetup."Source Group"::Customer, CustomerNo);

        // [WHEN] FindSetup()
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, FoundPriceCalculationSetup), 'not found setup');

        // [THEN] Setup 'C' is returned
        FoundPriceCalculationSetup.TestField(Code, ExpectedCode);
        // DtldPriceCalculationSetup.TestField("Codeunit Id", Codeunit::"Test Price Calc. Setup");
    end;

    [Test]
    procedure T113_FindSetupDtldSetupForAllCustomersAndAllItems()
    var
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        FoundPriceCalculationSetup: Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        ExpectedCode: Code[100];
        CustomerNo: Code[20];
        ItemNo: code[20];
    begin
        Initialize();
        // [GIVEN] 4 setup lines: 'A','B','C','D', where 'A' and 'B' are for 'All', 'A' - default; 'C' and 'D' are for 'Item', 'D' - default.
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        ExpectedCode := LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::Test, false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        // [GIVEN] Detailed Setup linked to Setup 'C', where 'All' Customers sell 'All' items
        LibraryPriceCalculation.AddDtldSetup(DtldPriceCalculationSetup, ExpectedCode, '', DtldPriceCalculationSetup."Source Group"::Customer, '');

        // [GIVEN] Sales Line, where Item 'X' and Customer 'Y'
        SalesLineAsLineWithPrice(ItemNo, CustomerNo, LineWithPrice);

        // [WHEN] FindSetup()
        Assert.IsTrue(PriceCalculationMgt.FindSetup(LineWithPrice, FoundPriceCalculationSetup), 'not found setup');

        // [THEN] Setup 'C' is returned
        FoundPriceCalculationSetup.TestField(Code, ExpectedCode);
    end;

    [Test]
    procedure T200_SalesSetupInitialDefaultMethod()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales]
        Initialize();

        SalesReceivablesSetup.Delete();
        SalesReceivablesSetup.Init();
        SalesReceivablesSetup.Insert();

        SalesReceivablesSetup.TestField(
            "Price Calculation Method", SalesReceivablesSetup."Price Calculation Method"::"Lowest Price");
    end;

    [Test]
    procedure T201_SalesSetupValidateImplementedMethod()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] "Lowest Price" and "Test Price" have implementations for Sale.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Test Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Test Price'
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Price Calculation Method", Method::"Test Price".AsInteger());

        // [THEN] "Price Calculation Method" is 'Test Price'
        SalesReceivablesSetup.TestField("Price Calculation Method", Method::"Test Price".AsInteger());
    end;

    [Test]
    procedure T202_SalesSetupValidateNotImplementedMethod()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] "Test Price" does not have implementations for Sale.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Test Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Test Price'
        SalesReceivablesSetup.Get();
        asserterror SalesReceivablesSetup.Validate("Price Calculation Method", Method::"Test Price".AsInteger());

        // [THEN] Error message: "The method Test Price has not implementations for purchase."
        Assert.ExpectedError(StrSubstNo(NotImplementedMethodErr, Method::"Test Price", PriceCalculationSetup.Type::Sale));
    end;

    [Test]
    procedure T203_SalesSetupValidateNotDefinedMethod()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] "Lowest Price" has implementations for Sale.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Not Defined'
        SalesReceivablesSetup.Get();
        asserterror SalesReceivablesSetup.Validate("Price Calculation Method", Method::" ".AsInteger());

        // [THEN] Error message: "The method Test Price has not implementations for Sale."
        Assert.ExpectedError(StrSubstNo(NotImplementedMethodErr, Method::" ", PriceCalculationSetup.Type::Sale));
    end;

    [Test]
    procedure T204_CustomerPriceGroupValidateNotDefinedMethod()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] "Lowest Price" has implementation for Sale.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Not Defined' in CustomerPriceGroup 'CPR'
        CustomerPriceGroup.Init();
        CustomerPriceGroup."Price Calculation Method" := CustomerPriceGroup."Price Calculation Method"::"Lowest Price";
        CustomerPriceGroup.Validate("Price Calculation Method", Method::" ".AsInteger());

        // [THEN] CustomerPriceGroup 'CPR', where "Price Calculation Method" is 'Not Defined'
        CustomerPriceGroup.Testfield("Price Calculation Method", Method::" ");
    end;

    [Test]
    procedure T205_CustomerValidateNotDefinedMethod()
    var
        Customer: Record Customer;
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] "Lowest Price" has implementation for Sale.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Not Defined' in Customer 'C'
        Customer.Init();
        Customer."Price Calculation Method" := Customer."Price Calculation Method"::"Lowest Price";
        Customer.Validate("Price Calculation Method", Method::" ".AsInteger());

        // [THEN] Customer 'C', where "Price Calculation Method" is 'Not Defined'
        Customer.Testfield("Price Calculation Method", Method::" ");
    end;

    [Test]
    procedure T206_JobValidateNotDefinedMethod()
    var
        Job: Record Job;
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] "Lowest Price" has implementation for Sale.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Sale,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Not Defined' in Job 'J'
        Job.Init();
        Job."Price Calculation Method" := Job."Price Calculation Method"::"Lowest Price";
        Job.Validate("Price Calculation Method", Method::" ".AsInteger());

        // [THEN] Job 'J', where "Price Calculation Method" is 'Not Defined'
        Job.Testfield("Price Calculation Method", Method::" ");
    end;

    [Test]
    procedure T210_PurchSetupInitialDefaultMethod()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Purchase]
        Initialize();

        PurchasesPayablesSetup.Delete();
        PurchasesPayablesSetup.Init();
        PurchasesPayablesSetup.Insert();

        PurchasesPayablesSetup.TestField(
            "Price Calculation Method", PurchasesPayablesSetup."Price Calculation Method"::"Lowest Price");
    end;

    [Test]
    procedure T211_PurchSetupValidateImplementedMethod()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] "Lowest Price" and "Test Price" have implementations for Purchase.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Test Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Test Price'
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Price Calculation Method", Method::"Test Price".AsInteger());

        // [THEN] "Price Calculation Method" is 'Test Price'
        PurchasesPayablesSetup.TestField("Price Calculation Method", Method::"Test Price".AsInteger());
    end;

    [Test]
    procedure T212_PurchSetupValidateNotEnabledMethod()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] "Test Price" has a not enabled implementation for Purchase.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Test Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        PriceCalculationSetup.SetRange(Method, Method::"Test Price".AsInteger());
        PriceCalculationSetup.ModifyAll(Enabled, false);

        // [WHEN] Set "Price Calculation Method" as 'Test Price'
        PurchasesPayablesSetup.Get();
        asserterror PurchasesPayablesSetup.Validate("Price Calculation Method", Method::"Test Price".AsInteger());

        // [THEN] Error message: "The method Test Price has not implementations for purchase."
        Assert.ExpectedError(StrSubstNo(NotImplementedMethodErr, Method::"Test Price", PriceCalculationSetup.Type::Purchase));
    end;

    [Test]
    procedure T213_PurchSetupValidateNotDefinedMethod()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] "Lowest Price" has an enabled implementation for Purchase.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Not Defined'
        PurchasesPayablesSetup.Get();
        asserterror PurchasesPayablesSetup.Validate("Price Calculation Method", Method::" ".AsInteger());

        // [THEN] Error message: "The method Test Price has not implementations for purchase."
        Assert.ExpectedError(StrSubstNo(NotImplementedMethodErr, Method::" ", PriceCalculationSetup.Type::Purchase));
    end;

    [Test]
    procedure T215_VendorValidateNotDefinedMethod()
    var
        Vendor: Record Vendor;
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] "Lowest Price" has an enabled implementation for Purchase.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Price Calculation Method" as 'Not Defined' for Vendor 'V'
        Vendor.Init();
        Vendor."Price Calculation Method" := Vendor."Price Calculation Method"::"Lowest Price";
        Vendor.Validate("Price Calculation Method", Method::" ".AsInteger());

        // [THEN] Vendor 'V', where "Price Calculation Method" is 'Not Defined'
        Vendor.Testfield("Price Calculation Method", Method::" ");
    end;

    [Test]
    procedure T216_JobValidateNotDefinedMethod()
    var
        Job: Record Job;
        PriceCalculationSetup: Record "Price Calculation Setup";
        Method: Enum "Price Calculation Method";
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] "Lowest Price" has implementation for Purchase.
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, Method::"Lowest Price", PriceCalculationSetup.Type::Purchase,
            PriceCalculationSetup."Asset Type"::" ", "Price Calculation Handler"::Test, true);

        // [WHEN] Set "Cost Calculation Method" as 'Not Defined' in Job 'J'
        Job.Init();
        Job."Price Calculation Method" := Job."Price Calculation Method"::"Lowest Price";
        Job.Validate("Cost Calculation Method", Method::" ".AsInteger());

        // [THEN] Job 'J', where "Price Calculation Method" is 'Not Defined'
        Job.Testfield("Cost Calculation Method", Method::" ");
    end;

    [Test]
    procedure T300_FindActivePricingSubscription()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        TestPriceCalcSetup: Codeunit "Test Price Calc. Setup";
    begin
        // [GIVEN] There is a subscription to "Price Asset - Item" 
        BindSubscription(TestPriceCalcSetup); // to activate OnAfterGetAssetTypeHandler

        // [THEN] FindActivePricingSubscription() returns Yes
        Assert.ExpectedMessage('7020-OnAfterGetAssetTypeHandler;Manual-1;', PriceCalculationMgt.FindActiveSubscriptions());

        // [GIVEN] There is no subscription to "Price Asset - Item" 
        UnbindSubscription(TestPriceCalcSetup); // to deactivate OnAfterGetAssetTypeHandler

        // [THEN] FindActivePricingSubscription() returns No
        Assert.AreEqual('7020-OnAfterGetAssetTypeHandler;Manual-0;7021-OnAfterSetFilterByFilterPageBuilder;Manual-0;', PriceCalculationMgt.FindActiveSubscriptions(), 'unbound');
    end;

    local procedure Initialize()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Price Calc. Setup");
        PriceCalculationSetup.DeleteAll();
        DtldPriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.SetMethodInSalesSetup();
        LibraryPriceCalculation.SetMethodInPurchSetup();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Price Calc. Setup");
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Price Calc. Setup");
    end;

    local procedure AddFourSetupLines(PriceType: Enum "Price Type"; var PriceCalculationSetup: array[5] of Record "Price Calculation Setup")
    begin
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceType, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceType, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[3], PriceCalculationSetup[5].Method::"Test Price", PriceType, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, true);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[4], PriceCalculationSetup[5].Method::"Test Price", PriceType, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", false);
    end;

    local procedure SetupSalesPurchaseMethods(var ExpectedMethod: array[3] of Enum "Price Calculation Method")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        ExpectedMethod[1] := ExpectedMethod[1] ::"Test Price";
        ExpectedMethod[2] := ExpectedMethod[2] ::"Lowest Price";
        ExpectedMethod[3] := ExpectedMethod[2] ::"Test Price (not Implemented)";

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Price Calculation Method" := ExpectedMethod[1];
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Price Calculation Method" := ExpectedMethod[2];
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SalesLineAsLineWithPrice(var ItemNo: Code[20]; var CustomerNo: Code[20]; var LineWithPrice: Interface "Line With Price")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceType: Enum "Price Type";
    begin
        if CustomerNo = '' then
            CustomerNo := LibrarySales.CreateCustomerNo();
        if ItemNo = '' then
            ItemNo := LibraryInventory.CreateItemNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", ItemNo);

        SalesLinePrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);
        LineWithPrice := SalesLinePrice;
    end;

    local procedure ServiceLineAsLineWithPrice(var ItemNo: Code[20]; var CustomerNo: Code[20]; var LineWithPrice: Interface "Line With Price")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceType: Enum "Price Type";
    begin
        if CustomerNo = '' then
            CustomerNo := LibrarySales.CreateCustomerNo();
        if ItemNo = '' then
            ItemNo := LibraryInventory.CreateItemNo();
        ServiceHeader."No." := LibraryRandom.RandText(20);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);

        ServiceLinePrice.SetLine(PriceType::Sale, ServiceHeader, ServiceLine);
        LineWithPrice := ServiceLinePrice;
    end;

    local procedure CreateCustomerWithMethod(NewMethod: Enum "Price Calculation Method"): Code[20];
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Price Calculation Method", NewMethod);
        Customer.Modify(true);
        exit(Customer."No.")
    end;

    local procedure PurchLineAsLineWithPrice(var ItemNo: Code[20]; var VendorNo: Code[20]; var LineWithPrice: Interface "Line With Price")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceType: Enum "Price Type";
    begin
        if VendorNo = '' then
            VendorNo := LibraryPurchase.CreateVendorNo();
        if ItemNo = '' then
            ItemNo := LibraryInventory.CreateItemNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine.Validate("No.", ItemNo);

        PurchaseLinePrice.SetLine(PriceType::Purchase, PurchaseHeader, PurchaseLine);
        LineWithPrice := PurchaseLinePrice;
    end;

    local procedure RequisitionLineAsLineWithPrice(var ItemNo: Code[20]; var VendorNo: Code[20]; var LineWithPrice: Interface "Line With Price")
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
        PriceType: Enum "Price Type";
    begin
        if ItemNo = '' then
            ItemNo := LibraryInventory.CreateItemNo();

        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine.Validate("No.", ItemNo);

        RequisitionLinePrice.SetLine(PriceType::Purchase, RequisitionLine);
        LineWithPrice := RequisitionLinePrice;
    end;

    local procedure ItemJnlLineAsLineWithPrice(var ItemNo: Code[20]; Method: Enum "Price Calculation Method"; var LineWithPrice: Interface "Line With Price")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
        PriceType: Enum "Price Type";
    begin
        if ItemNo = '' then
            ItemNo := LibraryInventory.CreateItemNo();

        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, 3);
        ItemJournalLine."Price Calculation Method" := Method;

        ItemJournalLinePrice.SetLine(PriceType::Purchase, ItemJournalLine);
        LineWithPrice := ItemJournalLinePrice;
    end;

    local procedure JobJnlLineAsLineWithPrice(var JobNo: Code[20]; Method: Enum "Price Calculation Method"; var LineWithPrice: Interface "Line With Price")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalLine: Record "Job Journal Line";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceType: Enum "Price Type";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobNo := Job."No.";
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine."Cost Calculation Method" := Method;

        JobJournalLinePrice.SetLine(PriceType::Purchase, JobJournalLine);
        LineWithPrice := JobJournalLinePrice;
    end;

    local procedure CreateVendorWithMethod(NewMethod: Enum "Price Calculation Method"): Code[20];
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Price Calculation Method", NewMethod);
        Vendor.Modify(true);
        exit(Vendor."No.")
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Mgt.", 'OnFindSupportedSetup', '', false, false)]
    local procedure OnFindImplementationHandler(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        AddSupportedSetup(TempPriceCalculationSetup);
    end;

    local procedure AddSupportedSetup(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        TempPriceCalculationSetup.Init();
        TempPriceCalculationSetup.Validate(Implementation, TempPriceCalculationSetup.Implementation::Test);
        TempPriceCalculationSetup.Method := TempPriceCalculationSetup.Method::"Lowest Price";
        TempPriceCalculationSetup.Enabled := true;
        TempPriceCalculationSetup.Default := false;
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Purchase;
        TempPriceCalculationSetup.Insert(true);
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Sale;
        TempPriceCalculationSetup.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Line - Price", 'OnAfterGetAssetType', '', false, false)]
    local procedure OnAfterGetAssetTypeHandler(SalesLine: Record "Sales Line"; var AssetType: Enum "Price Asset Type");
    begin
    end;

}