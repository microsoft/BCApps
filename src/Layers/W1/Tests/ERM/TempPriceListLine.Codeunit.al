codeunit 134223 "Temp Price List Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List Line]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    [Test]
    procedure CalcSalesPriceForTempRecordSimple()
    var
        Item: Record Item;
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        ConfiguredPrice: Decimal;
    begin
        Initialize();

        // [GIVEN] Temporary Sales Header and item with price exists
        LibraryInventory.CreateItem(Item);
        CreateTempSalesHeader(TempSalesHeader, Enum::"Sales Document Type"::Order);
        ConfiguredPrice := LibraryRandom.RandDec(1000, 2);
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Sale, 0D, 0D, ConfiguredPrice);

        // [WHEN] The line is created
        CreateTempSalesLine(TempSalesHeader, TempSalesLine, Item."No.");

        // [THEN] The price is calculated and is the same as the configured price
        Assert.AreEqual(ConfiguredPrice, TempSalesLine."Unit Price", 'Calculated price is different from configured price.');
    end;

    [Test]
    procedure CalcSalesPriceForTempRecordForOrder()
    var
        Item: Record Item;
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        ConfiguredPrice: Decimal;
        DayDifference: Integer;
    begin
        Initialize();

        // [GIVEN] Temporary Sales Header and item with price exists with valid price for the Order Date and Posting Date
        DayDifference := 7;
        LibraryInventory.CreateItem(Item);
        CreateTempSalesHeader(TempSalesHeader, Enum::"Sales Document Type"::Order);
        TempSalesHeader."Document Date" := WorkDate() - DayDifference;
        TempSalesHeader."Order Date" := WorkDate() + DayDifference;
        TempSalesHeader."Posting Date" := WorkDate() - DayDifference;
        TempSalesHeader.Modify();
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Sale, WorkDate() - (2 * DayDifference), WorkDate() - 1, LibraryRandom.RandDec(1000, 2));
        ConfiguredPrice := 1000 + LibraryRandom.RandDec(1000, 2);
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Sale, WorkDate() + 1, WorkDate() + (2 * DayDifference), ConfiguredPrice);

        // [WHEN] The line is created
        CreateTempSalesLine(TempSalesHeader, TempSalesLine, Item."No.");

        // [THEN] The price is calculated and is the same as the configured price for order date
        Assert.AreEqual(ConfiguredPrice, TempSalesLine."Unit Price", 'Calculated price is different from configured price.');
    end;

    [Test]
    procedure CalcSalesPriceForTempRecordForInvoice()
    var
        Item: Record Item;
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        ConfiguredPrice: Decimal;
        DayDifference: Integer;
    begin
        Initialize();

        // [GIVEN] Temporary Sales Header and item with price exists with valid price for the Order Date and Posting Date
        DayDifference := 7;
        LibraryInventory.CreateItem(Item);
        CreateTempSalesHeader(TempSalesHeader, Enum::"Sales Document Type"::Invoice);
        TempSalesHeader."Document Date" := WorkDate() - DayDifference;
        TempSalesHeader."Order Date" := WorkDate() + DayDifference;
        TempSalesHeader."Posting Date" := WorkDate() - DayDifference;
        TempSalesHeader.Modify();
        ConfiguredPrice := 1000 + LibraryRandom.RandDec(1000, 2);
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Sale, WorkDate() - (2 * DayDifference), WorkDate() - 1, ConfiguredPrice);
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Sale, WorkDate() + 1, WorkDate() + (2 * DayDifference), LibraryRandom.RandDec(1000, 2));

        // [WHEN] The line is created
        CreateTempSalesLine(TempSalesHeader, TempSalesLine, Item."No.");

        // [THEN] The price is calculated and is the same as the configured price for posting date
        Assert.AreEqual(ConfiguredPrice, TempSalesLine."Unit Price", 'Calculated price is different from configured price.');
    end;

    [Test]
    procedure CalcPurchasePriceForTempRecordSimple()
    var
        Item: Record Item;
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        ConfiguredPrice: Decimal;
    begin
        Initialize();

        // [GIVEN] Temporary Purchase Header and item with cost exists
        LibraryInventory.CreateItem(Item);
        CreateTempPurchaseHeader(TempPurchaseHeader, Enum::"Purchase Document Type"::Order);
        ConfiguredPrice := LibraryRandom.RandDec(1000, 2);
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Purchase, 0D, 0D, ConfiguredPrice);

        // [WHEN] The line is created
        CreateTempPurchaseLine(TempPurchaseHeader, TempPurchaseLine, Item."No.");

        // [THEN] The cost is calculated and is the same as the configured cost
        Assert.AreEqual(ConfiguredPrice, TempPurchaseLine."Unit Cost", 'Calculated cost is different from configured cost.');
    end;

    [Test]
    procedure CalcPurchasePriceForTempRecordForOrder()
    var
        Item: Record Item;
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        ConfiguredPrice: Decimal;
        DayDifference: Integer;
    begin
        Initialize();

        // [GIVEN] Temporary Purchase Header and item with cost exists with valid cost for the Order Date and Posting Date
        DayDifference := 7;
        LibraryInventory.CreateItem(Item);
        CreateTempPurchaseHeader(TempPurchaseHeader, Enum::"Purchase Document Type"::Order);
        TempPurchaseHeader."Document Date" := WorkDate() - DayDifference;
        TempPurchaseHeader."Order Date" := WorkDate() + DayDifference;
        TempPurchaseHeader."Posting Date" := WorkDate() - DayDifference;
        TempPurchaseHeader.Modify();
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Purchase, WorkDate() - (2 * DayDifference), WorkDate() - 1, LibraryRandom.RandDec(1000, 2));
        ConfiguredPrice := 1000 + LibraryRandom.RandDec(1000, 2);
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Purchase, WorkDate() + 1, WorkDate() + (2 * DayDifference), ConfiguredPrice);

        // [WHEN] The line is created
        CreateTempPurchaseLine(TempPurchaseHeader, TempPurchaseLine, Item."No.");

        // [THEN] The cost is calculated and is the same as the configured cost for order date
        Assert.AreEqual(ConfiguredPrice, TempPurchaseLine."Unit Cost", 'Calculated cost is different from configured cost.');
    end;

    [Test]
    procedure CalcPurchasePriceForTempRecordForInvoice()
    var
        Item: Record Item;
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        ConfiguredPrice: Decimal;
        DayDifference: Integer;
    begin
        Initialize();

        // [GIVEN] Temporary Purchase Header and item with cost exists with valid cost for the Order Date and Posting Date
        DayDifference := 7;
        LibraryInventory.CreateItem(Item);
        CreateTempPurchaseHeader(TempPurchaseHeader, Enum::"Purchase Document Type"::Invoice);
        TempPurchaseHeader."Document Date" := WorkDate() - DayDifference;
        TempPurchaseHeader."Order Date" := WorkDate() + DayDifference;
        TempPurchaseHeader."Posting Date" := WorkDate() - DayDifference;
        TempPurchaseHeader.Modify();
        ConfiguredPrice := 1000 + LibraryRandom.RandDec(1000, 2);
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Purchase, WorkDate() - (2 * DayDifference), WorkDate() - 1, ConfiguredPrice);
        CreatePriceForItem(Item."No.", Enum::"Price Type"::Purchase, WorkDate() + 1, WorkDate() + (2 * DayDifference), LibraryRandom.RandDec(1000, 2));

        // [WHEN] The line is created
        CreateTempPurchaseLine(TempPurchaseHeader, TempPurchaseLine, Item."No.");

        // [THEN] The cost is calculated and is the same as the configured cost for posting date
        Assert.AreEqual(ConfiguredPrice, TempPurchaseLine."Unit Cost", 'Calculated cost is different from configured cost.');
    end;

    local procedure Initialize()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Temp Price List Line");
        LibraryVariableStorage.Clear();

        LibraryPriceCalculation.EnableExtendedPriceCalculation(true);
        LibraryPriceCalculation.SetupDefaultHandler(Enum::"Price Calculation Handler"::"Business Central (Version 16.0)");
        LibraryPriceCalculation.DisallowEditingActiveSalesPrice();
        LibraryPriceCalculation.DisallowEditingActivePurchPrice();
        PriceListHeader.ModifyAll(Status, PriceListHeader.Status::Draft);
        PriceListHeader.DeleteAll(true);
        PriceListLine.ModifyAll(Status, PriceListLine.Status::Draft);
        PriceListLine.DeleteAll(true);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Temp Price List Line");
        LibraryERM.SetBlockDeleteGLAccount(false);
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Temp Price List Line");
    end;

    local procedure CreateTempSalesHeader(var TempSalesHeader: Record "Sales Header" temporary; SalesDocumentType: Enum "Sales Document Type")
    begin
        TempSalesHeader.Init();
        TempSalesHeader."Document Type" := SalesDocumentType;
        TempSalesHeader."No." := LibraryRandom.RandText(MaxStrLen(TempSalesHeader."No."));
        TempSalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        TempSalesHeader.Insert(false);
    end;

    local procedure CreateTempPurchaseHeader(var TempPurchaseHeader: Record "Purchase Header" temporary; PurchaseDocumentType: Enum "Purchase Document Type")
    begin
        TempPurchaseHeader.Init();
        TempPurchaseHeader."Document Type" := PurchaseDocumentType;
        TempPurchaseHeader."No." := LibraryRandom.RandText(MaxStrLen(TempPurchaseHeader."No."));
        TempPurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        TempPurchaseHeader.Insert(false);
    end;

    local procedure CreateTempSalesLine(TempSalesHeader: Record "Sales Header" temporary; var TempSalesLine: Record "Sales Line" temporary; ItemNo: Code[20])
    begin
        Clear(TempSalesLine);
        TempSalesLine.SetSalesHeader(TempSalesHeader);
        TempSalesLine.Init();
        TempSalesLine."Document Type" := TempSalesHeader."Document Type";
        TempSalesLine."Document No." := TempSalesHeader."No.";
        TempSalesLine."Sell-to Customer No." := TempSalesHeader."Sell-to Customer No.";
        TempSalesLine.Type := TempSalesLine.Type::Item;
        TempSalesLine.Validate("No.", ItemNo);
        TempSalesLine.Quantity := 1;
        TempSalesLine."Quantity (Base)" := 1;
        TempSalesLine.Insert(false);
    end;

    local procedure CreateTempPurchaseLine(TempPurchaseHeader: Record "Purchase Header" temporary; var TempPurchaseLine: Record "Purchase Line" temporary; ItemNo: Code[20])
    begin
        Clear(TempPurchaseLine);
        TempPurchaseLine.SetPurchHeader(TempPurchaseHeader);
        TempPurchaseLine.Init();
        TempPurchaseLine."Document Type" := TempPurchaseHeader."Document Type";
        TempPurchaseLine."Document No." := TempPurchaseHeader."No.";
        TempPurchaseLine."Buy-from Vendor No." := TempPurchaseHeader."Buy-from Vendor No.";
        TempPurchaseLine.Type := TempPurchaseLine.Type::Item;
        TempPurchaseLine.Validate("No.", ItemNo);
        TempPurchaseLine.Quantity := 1;
        TempPurchaseLine."Quantity (Base)" := 1;
        TempPurchaseLine.Insert(false);
    end;

    local procedure CreatePriceForItem(ItemNo: Code[20]; PriceType: Enum "Price Type"; FromDate: Date; ToDate: Date; Price: Decimal)
    var
        PriceListLine: Record "Price List Line";
        PriceListHeader: Record "Price List Header";
        PriceSourceType: Enum "Price Source Type";
    begin
        case PriceType of
            PriceType::Sale:
                PriceSourceType := Enum::"Price Source Type"::"All Customers";
            PriceType::Purchase:
                PriceSourceType := Enum::"Price Source Type"::"All Vendors";
        end;
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, PriceType, PriceSourceType, '');
        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, Enum::"Price Amount Type"::Price, Enum::"Price Asset Type"::Item, ItemNo);
        PriceListHeader."Starting Date" := FromDate;
        PriceListHeader."Ending Date" := ToDate;
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Modify();

        case PriceType of
            PriceType::Sale:
                PriceListLine.Validate("Unit Price", Price);
            PriceType::Purchase:
                PriceListLine.Validate("Direct Unit Cost", Price);
        end;
        PriceListLine."Starting Date" := FromDate;
        PriceListLine."Ending Date" := ToDate;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;
}
