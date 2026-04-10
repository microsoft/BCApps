codeunit 137057 "SCM Whse. UOM Rnding. UT"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        QtyRoundingErr: Label 'is of lower precision than expected';
        BaseQtyRoundingErr: Label 'to be out of balance';

    [Test]
    procedure RoundingErrorThrownWhenBaseQuantityRoundsTo0OnWarehouseActivityLine()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Activity Line setup with the created item and the non base UOM
        CreateWarehouseActivityLine(WarehouseActivityLine, Item."No.", NonBaseItemUnitOfMeasure.Code, NonBaseQtyPerUOM, 0, BaseQtyRoundingPrecision);

        // [WHEN] Quantity is set to a value that causes the base quantity to round to 0
        asserterror WarehouseActivityLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(BaseQtyRoundingErr);
    end;

    [Test]
    procedure RoundingErrorThrownWhenQuantityRoundsTo0OnWarehouseActivityLine()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Activity Line setup with the created item and the non base UOM
        CreateWarehouseActivityLine(WarehouseActivityLine, Item."No.", BaseItemUnitOfMeasure.Code, 1, BaseQtyRoundingPrecision, BaseQtyRoundingPrecision);

        // [WHEN] Quantity is set with a value that rounds to 0
        asserterror WarehouseActivityLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(QtyRoundingErr);
    end;

    [Test]
    procedure WarehouseActivityLineBaseQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Activity Line setup with the created item and the non base UOM
        CreateWarehouseActivityLine(WarehouseActivityLine, Item."No.", NonBaseItemUnitOfMeasure.Code, NonBaseQtyPerUOM, 0, BaseQtyRoundingPrecision);

        // [WHEN] Quantity is set
        WarehouseActivityLine.Validate(Quantity, LibraryRandom.RandInt(10));

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WarehouseActivityLine.TestField("Qty. (Base)", Round(WarehouseActivityLine.Quantity * NonBaseQtyPerUOM, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure WarehouseActivityLineQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
        InputQty: Integer;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Activity Line setup with the created item and the non base UOM
        CreateWarehouseActivityLine(WarehouseActivityLine, Item."No.", BaseItemUnitOfMeasure.Code, 1, BaseQtyRoundingPrecision, BaseQtyRoundingPrecision);

        // [WHEN] Quantity is set
        InputQty := LibraryRandom.RandInt(10);
        WarehouseActivityLine.Validate(Quantity, InputQty);

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WarehouseActivityLine.TestField(Quantity, Round(InputQty, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure RoundingErrorThrownWhenBaseQuantityRoundsTo0OnWarehouseJournalLine()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        Bin: Record Bin;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Journal Line setup with the created item and the non base UOM
        WhiteLocationSetup(Bin);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, Item."No.");
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseJournalLine."Item No." := Item."No.";
        WarehouseJournalLine."Unit of Measure Code" := NonBaseItemUnitOfMeasure.Code;
        WarehouseJournalLine."Qty. per Unit of Measure" := NonBaseQtyPerUOM;
        WarehouseJournalLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set to a value that causes the base quantity to round to 0
        asserterror WarehouseJournalLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(BaseQtyRoundingErr);
    end;

    [Test]
    procedure RoundingErrorThrownWhenQuantityRoundsTo0OnWarehouseJournalLine()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        Bin: Record Bin;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Journal Line setup with the created item and the non base UOM
        WhiteLocationSetup(Bin);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, Item."No.");
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseJournalLine."Item No." := Item."No.";
        WarehouseJournalLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        WarehouseJournalLine."Qty. per Unit of Measure" := 1;
        WarehouseJournalLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseJournalLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set with a value that rounds to 0
        asserterror WarehouseJournalLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(QtyRoundingErr);
    end;

    [Test]
    procedure WarehouseJournalLineBaseQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        Bin: Record Bin;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Journal Line setup with the created item and the non base UOM
        WhiteLocationSetup(Bin);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, Item."No.");
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseJournalLine."Item No." := Item."No.";
        WarehouseJournalLine."Unit of Measure Code" := NonBaseItemUnitOfMeasure.Code;
        WarehouseJournalLine."Qty. per Unit of Measure" := NonBaseQtyPerUOM;
        WarehouseJournalLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseJournalLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set
        WarehouseJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WarehouseJournalLine.TestField("Qty. (Base)", Round(WarehouseJournalLine.Quantity * NonBaseQtyPerUOM, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure WarehouseJournalLineQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        Bin: Record Bin;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
        InputQty: Integer;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Journal Line setup with the created item and the non base UOM
        WhiteLocationSetup(Bin);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, Item."No.");
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseJournalLine."Item No." := Item."No.";
        WarehouseJournalLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        WarehouseJournalLine."Qty. per Unit of Measure" := 1;
        WarehouseJournalLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseJournalLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set
        InputQty := LibraryRandom.RandInt(10);
        WarehouseJournalLine.Validate(Quantity, InputQty);

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WarehouseJournalLine.TestField(Quantity, Round(InputQty, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure RoundingErrorThrownWhenQuantityRoundsTo0OnWhseWorksheetLine()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        Bin: Record Bin;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Worksheet Line setup with the created item and the non base UOM
        WhiteLocationSetup(Bin);
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Bin."Location Code");

        LibraryWarehouse.CreateWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Bin."Location Code", WhseWorksheetLine."Whse. Document Type"::"Internal Pick");
        WhseWorksheetLine."Item No." := Item."No.";
        WhseWorksheetLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        WhseWorksheetLine."Qty. per Unit of Measure" := 1;
        WhseWorksheetLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WhseWorksheetLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set with a value that rounds to 0
        asserterror WhseWorksheetLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(BaseQtyRoundingErr);
    end;

    [Test]
    procedure WhseWorksheetLinBaseQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        Bin: Record Bin;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Worksheet Line setup with the created item and the non base UOM
        WhiteLocationSetup(Bin);
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Bin."Location Code");

        LibraryWarehouse.CreateWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Bin."Location Code", WhseWorksheetLine."Whse. Document Type"::"Internal Pick");
        WhseWorksheetLine."Item No." := Item."No.";
        WhseWorksheetLine."Unit of Measure Code" := NonBaseItemUnitOfMeasure.Code;
        WhseWorksheetLine."Qty. per Unit of Measure" := NonBaseQtyPerUOM;
        WhseWorksheetLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set
        WhseWorksheetLine.Validate(Quantity, LibraryRandom.RandInt(10));

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WhseWorksheetLine.TestField("Qty. (Base)", Round(WhseWorksheetLine.Quantity * NonBaseQtyPerUOM, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure WhseWorksheetLinQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        Bin: Record Bin;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
        InputQty: Integer;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Worksheet Line setup with the created item and the non base UOM
        WhiteLocationSetup(Bin);
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Bin."Location Code");

        LibraryWarehouse.CreateWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Bin."Location Code", WhseWorksheetLine."Whse. Document Type"::"Internal Pick");
        WhseWorksheetLine."Item No." := Item."No.";
        WhseWorksheetLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        WhseWorksheetLine."Qty. per Unit of Measure" := 1;
        WhseWorksheetLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WhseWorksheetLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set
        InputQty := LibraryRandom.RandInt(10);
        WhseWorksheetLine.Validate(Quantity, InputQty);

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WhseWorksheetLine.TestField(Quantity, Round(InputQty, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure RoundingErrorThrownWhenBaseQuantityRoundsTo0OnWarehouseReceiptLine()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Receipt Line setup with the created item and the non base UOM
        WarehouseReceiptLine.Init();
        WarehouseReceiptLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseReceiptLine."Item No." := Item."No.";
        WarehouseReceiptLine."Unit of Measure Code" := NonBaseItemUnitOfMeasure.Code;
        WarehouseReceiptLine."Qty. per Unit of Measure" := NonBaseQtyPerUOM;
        WarehouseReceiptLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;
        WarehouseReceiptLine."Unit of Measure Code" := NonBaseItemUnitOfMeasure.Code;
        WarehouseReceiptLine."Qty. per Unit of Measure" := NonBaseQtyPerUOM;
        WarehouseReceiptLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set to a value that causes the base quantity to round to 0
        asserterror WarehouseReceiptLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(BaseQtyRoundingErr);
    end;

    [Test]
    procedure RoundingErrorThrownWhenQuantityRoundsTo0OnWarehouseReceiptLine()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Receipt Line setup with the created item and the non base UOM
        WarehouseReceiptLine.Init();
        WarehouseReceiptLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseReceiptLine."Item No." := Item."No.";
        WarehouseReceiptLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        WarehouseReceiptLine."Qty. per Unit of Measure" := 1;
        WarehouseReceiptLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseReceiptLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set with a value that rounds to 0
        asserterror WarehouseReceiptLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(QtyRoundingErr);
    end;

    [Test]
    procedure WarehouseReceiptLineBaseQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Receipt Line setup with the created item and the non base UOM
        WarehouseReceiptLine.Init();
        WarehouseReceiptLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseReceiptLine."Item No." := Item."No.";
        WarehouseReceiptLine."Unit of Measure Code" := NonBaseItemUnitOfMeasure.Code;
        WarehouseReceiptLine."Qty. per Unit of Measure" := NonBaseQtyPerUOM;
        WarehouseReceiptLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseReceiptLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set
        WarehouseReceiptLine.Validate(Quantity, LibraryRandom.RandInt(10));

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WarehouseReceiptLine.TestField("Qty. (Base)", Round(WarehouseReceiptLine.Quantity * NonBaseQtyPerUOM, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure WarehouseReceiptLineQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
        InputQty: Integer;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Receipt Line setup with the created item and the non base UOM
        WarehouseReceiptLine.Init();
        WarehouseReceiptLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseReceiptLine."Item No." := Item."No.";
        WarehouseReceiptLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        WarehouseReceiptLine."Qty. per Unit of Measure" := 1;
        WarehouseReceiptLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseReceiptLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set
        InputQty := LibraryRandom.RandInt(10);
        WarehouseReceiptLine.Validate(Quantity, InputQty);

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WarehouseReceiptLine.TestField(Quantity, Round(InputQty, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure RoundingErrorThrownWhenBaseQuantityRoundsTo0OnWarehouseShipmentLine()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Shipment Line setup with the created item and the non base UOM
        CreateWarehouseShipmentLine(WarehouseShipmentLine, Item."No.", NonBaseQtyPerUOM);
        WarehouseShipmentLine."Unit of Measure Code" := NonBaseItemUnitOfMeasure.Code;
        WarehouseShipmentLine."Qty. per Unit of Measure" := NonBaseQtyPerUOM;
        WarehouseShipmentLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set to a value that causes the base quantity to round to 0
        asserterror WarehouseShipmentLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(BaseQtyRoundingErr);
    end;

    [Test]
    procedure RoundingErrorThrownWhenQuantityRoundsTo0OnWarehouseShipmentLine()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Shipment Line setup with the created item and the non base UOM
        CreateWarehouseShipmentLine(WarehouseShipmentLine, Item."No.", NonBaseQtyPerUOM);
        WarehouseShipmentLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        WarehouseShipmentLine."Qty. per Unit of Measure" := 1;
        WarehouseShipmentLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseShipmentLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set with a value that rounds to 0
        asserterror WarehouseShipmentLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 500));

        // [THEN] Error is thrown
        Assert.ExpectedError(QtyRoundingErr);
    end;

    [Test]
    procedure WarehouseShipmentLineBaseQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Shipment Line setup with the created item and the non base UOM
        CreateWarehouseShipmentLine(WarehouseShipmentLine, Item."No.", NonBaseQtyPerUOM);
        WarehouseShipmentLine."Unit of Measure Code" := NonBaseItemUnitOfMeasure.Code;
        WarehouseShipmentLine."Qty. per Unit of Measure" := NonBaseQtyPerUOM;
        WarehouseShipmentLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseShipmentLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set
        WarehouseShipmentLine.Validate(Quantity, WarehouseShipmentLine."Qty. Outstanding");

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WarehouseShipmentLine.TestField("Qty. (Base)", Round(WarehouseShipmentLine.Quantity * NonBaseQtyPerUOM, BaseQtyRoundingPrecision));
    end;

    [Test]
    procedure WarehouseShipmentLineQuantityRoundedToSpecifiedRoundingPrecision()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        NonBaseQtyPerUOM: Decimal;
        BaseQtyRoundingPrecision: Decimal;
        InputQty: Integer;
    begin
        Initialize();

        // [GIVEN] An item with two UOMs setup
        CreateItemWithTwoItemUnitOfMeasures(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, BaseQtyRoundingPrecision, NonBaseQtyPerUOM);

        // [GIVEN] Warehouse Shipment Line setup with the created item and the non base UOM
        CreateWarehouseShipmentLine(WarehouseShipmentLine, Item."No.", NonBaseQtyPerUOM);
        WarehouseShipmentLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        WarehouseShipmentLine."Qty. per Unit of Measure" := 1;
        WarehouseShipmentLine."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        WarehouseShipmentLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;

        // [WHEN] Quantity is set
        InputQty := LibraryRandom.RandInt(10);
        WarehouseShipmentLine.Validate(Quantity, InputQty);

        // [THEN] Quantity (Base) is rounded to with the specified rounding precision
        WarehouseShipmentLine.TestField(Quantity, Round(InputQty, BaseQtyRoundingPrecision));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Whse. UOM Rnding. UT");

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Whse. UOM Rnding. UT");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Whse. UOM Rnding. UT");
    end;

    local procedure CreateItemWithTwoItemUnitOfMeasures(var Item: Record Item; BaseItemUnitOfMeasure: Record "Item Unit of Measure"; NonBaseItemUnitOfMeasure: Record "Item Unit of Measure"; var BaseQtyRoundingPrecision: Decimal; var NonBaseQtyPerUOM: Decimal)
    var
        BaseUoM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
    begin
        // Create an item
        LibraryInventory.CreateItem(Item);

        // Two UOMs with Qty. rounding precision defined on the base UOM.
        BaseQtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        NonBaseQtyPerUOM := BaseQtyRoundingPrecision * LibraryRandom.RandInt(100);

        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(BaseItemUnitOfMeasure, Item."No.", BaseUOM.Code, 1);
        BaseItemUnitOfMeasure."Qty. Rounding Precision" := BaseQtyRoundingPrecision;
        BaseItemUnitOfMeasure.Modify();
        Item.Validate("Base Unit of Measure", BaseItemUnitOfMeasure.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(NonBaseItemUnitOfMeasure, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);
    end;

    local procedure CreateWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; NonBaseItemUnitOfMeasureCode: Code[10]; QtyPerUOM: Decimal; QtyRoundingPrecision: Decimal; BaseQtyRoundingPrecision: Decimal)
    begin
        WarehouseActivityLine.Init();
        WarehouseActivityLine."No." := LibraryUtility.GenerateRandomCode20(WarehouseActivityLine.FieldNo("No."), DATABASE::"Warehouse Activity Line");
        WarehouseActivityLine."Line No." := LibraryRandom.RandInt(10000);
        WarehouseActivityLine."Item No." := ItemNo;
        WarehouseActivityLine."Unit of Measure Code" := NonBaseItemUnitOfMeasureCode;
        WarehouseActivityLine."Qty. per Unit of Measure" := QtyPerUOM;
        WarehouseActivityLine."Qty. Rounding Precision" := QtyRoundingPrecision;
        WarehouseActivityLine."Qty. Rounding Precision (Base)" := BaseQtyRoundingPrecision;
    end;

    local procedure CreateWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; ItemNo: Code[20])
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        // Use Random value for Quantity.
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin."Location Code", Bin."Zone Code", Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 0);
    end;

    local procedure WhiteLocationSetup(var Bin: Record Bin)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);  // Use 1 for No. of Bins per Zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.FindBin(Bin, Location.Code, FindPickZone(Location.Code), 1);  // 1 is for Bin Index.
    end;

    local procedure FindPickZone(LocationCode: Code[10]): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
        exit(Zone.Code);
    end;

    local procedure CreateWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; ItemNo: Code[20]; NonBaseQtyPerUOM: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        LibraryWarehouse.CreateWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);

        WarehouseShipmentLine."Source Type" := DATABASE::"Sales Line";
        WarehouseShipmentLine."Source Subtype" := SalesLine."Document Type".AsInteger();
        WarehouseShipmentLine."Source No." := SalesLine."Document No.";
        WarehouseShipmentLine."Source Line No." := SalesLine."Line No.";
        WarehouseShipmentLine."Item No." := ItemNo;
        WarehouseShipmentLine.Validate(Quantity, NonBaseQtyPerUOM);
    end;
}