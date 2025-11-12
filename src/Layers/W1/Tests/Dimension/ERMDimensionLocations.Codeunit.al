codeunit 134474 "ERM Dimension Locations"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Locations]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        IsInitialized: Boolean;
        DimPostErr: Label 'Select a Dimension Value Code for the Dimension Code';
        ProjectTaskDimensionErr: Label 'Project Task Dimension must be updated as per Default Dimension.';
        DimensionsNotEqualErr: Label 'Dimensions are not equal';

    [Test]
    [Scope('OnPrem')]
    procedure LocationWithDefaultDimensions()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        // [SCENARIO 324149] Create default dimensions for location
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Create default dimensions "DD1" and "DD2" for "L"
        for i := 1 to 2 do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        end;

        // [THEN] There are two records in "Default Dimension" table for "L"
        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", Database::Location);
        DefaultDimension.SetRange("No.", Location.Code);
        Assert.RecordCount(DefaultDimension, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLocationWithDefaultDimensions()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 324149] Delete location with default dimensions
        Initialize();

        // [GIVEN] Location "L" with default dimensions
        CreateLocationWithDefaultDimensions(Location);

        // [WHEN] Delete "L"
        Location.Delete(true);

        // [THEN] There are no records in "Default Dimension" table for "L"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordIsEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameLocationWithDefaultDimemsions()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        OldLocationCode: Code[10];
    begin
        // [SCENARIO 324149] Rename location with default dimensions
        Initialize();

        // [GIVEN] Location "L" with default dimensions
        OldLocationCode := CreateLocationWithDefaultDimensions(Location);

        // [WHEN] Rename "L" to "L1"
        Location.Rename(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), Database::Location));

        // [THEN] There are no records in "Default Dimension" for "L"
        GetLocationDefaultDimensions(DefaultDimension, OldLocationCode);
        Assert.RecordIsEmpty(DefaultDimension);
        // [THEN] There are records in "Default Dimension" table for "L1"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordIsNotEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDefaultDimensionsLocationCard()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LocationCard: TestPage "Location Card";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [SCENARIO 324149] Create default dimensions for location on the "Location Card" page
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Dimension "D" with dimension value "DV"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [WHEN] Invoke "Dimensions" action on the "Location Card" page
        LocationCard.OpenView();
        LocationCard.GoToRecord(Location);
        DefaultDimensions.Trap();
        LocationCard.Dimensions.Invoke();
        // [WHEN] Assign "Dimension Code" = "D", "Dimension Value Code" = "DV"
        DefaultDimensions."Dimension Code".SetValue(DimensionValue."Dimension Code");
        DefaultDimensions."Dimension Value Code".SetValue(DimensionValue.Code);
        DefaultDimensions.Close();

        // [THEN] There is one record in "Default Dimension" table for "L"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordCount(DefaultDimension, 1);
        // [THEN] Default "Dimension Code" = "D", default "Dimension Value Code" = "DV"
        DefaultDimension.FindFirst();
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDefaultDimensionsLocationList()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LocationList: TestPage "Location List";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [SCENARIO 324149] Create single default dimensions for location on the "Location List" page
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Dimension "D" with dimension value "DV"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [WHEN] Invoke "Dimensions-Single" action on the "Location List" page
        LocationList.OpenView();
        LocationList.GoToRecord(Location);
        DefaultDimensions.Trap();
        LocationList.DimensionsSingle.Invoke();
        // [WHEN] Assign "Dimension Code" = "D", "Dimension Value Code" = "DV"
        DefaultDimensions."Dimension Code".SetValue(DimensionValue."Dimension Code");
        DefaultDimensions."Dimension Value Code".SetValue(DimensionValue.Code);
        DefaultDimensions.Close();

        // [THEN] There is one record in "Default Dimension" table for "L"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordCount(DefaultDimension, 1);
        // [THEN] Default "Dimension Code" = "D", default "Dimension Value Code" = "DV"
        DefaultDimension.FindFirst();
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandler')]
    procedure SetDefaultDimensionsMultipleLocationList()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LocationList: TestPage "Location List";
    begin
        // [SCENARIO 324149] Create multiple default dimensions for location on the "Location List" page
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Dimension "D" with dimension value "DV"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);

        // [WHEN] Invoke "Dimensions-Multiple" action on the "Location List" page
        LocationList.OpenView();
        LocationList.GoToRecord(Location);
        LocationList.DimensionsMultiple.Invoke();
        // [WHEN] Assign "Dimension Code" = "D", "Dimension Value Code" = "DV" (DefaultDimensionsMultipleModalPageHandler)

        // [THEN] There is one record in "Default Dimension" table for "L"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordCount(DefaultDimension, 1);
        // [THEN] Default "Dimension Code" = "D", default "Dimension Value Code" = "DV"
        DefaultDimension.FindFirst();
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesHeaderWithLocationWithMandatoryDefaultDimension()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 436796] Post sales order with header with location with mandatory default dimension
        Initialize();

        // [GIVEN] Location "L" with mandatory default dimension "D"
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Sales order with header with "L" and removed "D"
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Validate("Dimension Set ID", 0);
        SalesHeader.Modify(true);

        // [WHEN] Post sales order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There is error that document cannot be posted without "D"
        Assert.ExpectedError(DimPostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesLineWithLocationWithMandatoryDefaultDimension()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 436796] Post sales order with line with location with mandatory default dimension
        Initialize();

        // [GIVEN] Location "L" with mandatory default dimension "D"
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Sales order with line with "L" and removed "D"
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Dimension Set ID", 0);
        SalesLine.Modify(true);

        // [WHEN] Post sales order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There is error that document cannot be posted without "D"
        Assert.ExpectedError(DimPostErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseHeaderWithLocationWithMandatoryDefaultDimension()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 436796] Post Purchase order with header with location with mandatory default dimension
        Initialize();

        // [GIVEN] Location "L" with mandatory default dimension "D"
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Purchase order with header with "L" and removed "D"
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Validate("Dimension Set ID", 0);
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There is error that document cannot be posted without "D"
        Assert.ExpectedError(DimPostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseLineWithLocationWithMandatoryDefaultDimension()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 436796] Post Purchase order with line with location with mandatory default dimension
        Initialize();

        // [GIVEN] Location "L" with mandatory default dimension "D"
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Purchase order with line with "L" and removed "D"
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Dimension Set ID", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There is error that document cannot be posted without "D"
        Assert.ExpectedError(DimPostErr);
    end;

    [Test]
    procedure OverrideDimWithLocationsOnItemJournalLine()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal Line]
        // [SCENARIO 459647] Select item, then location with the same dimension on item journal line - the program will override the item's dimension with the location's.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));

        CreateItemWithDefaultDimension(Item, DimensionValue[1]);
        CreateLocationWithDefaultDimension(Location, DimensionValue[2]);

        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine.Validate("Item No.", Item."No.");
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);

        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[2].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[2]);
    end;

    [Test]
    procedure MergeDimsFromItemAndLocationOnItemJournalLine()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal Line]
        // [SCENARIO 459647] Select item, then location with different dimensions on item journal line - the program will take both dimensions.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(2));

        CreateItemWithDefaultDimension(Item, DimensionValue[1]);
        CreateLocationWithDefaultDimension(Location, DimensionValue[2]);

        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine.Validate("Item No.", Item."No.");
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        ItemJournalLine.TestField("Shortcut Dimension 2 Code", '');
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);

        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        ItemJournalLine.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[2]);
    end;

    [Test]
    procedure DoNotOverrideDimFromItemWithBlankOnItemJournalLine()
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal Line]
        // [SCENARIO 459647] Select item with dimension, then location without dimensions on item journal line - the program will keep the item's dimension.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        CreateItemWithDefaultDimension(Item, DimensionValue);
        LibraryWarehouse.CreateLocation(Location);

        CreateItemJournalLine(ItemJournalLine);
        ItemJournalLine.Validate("Item No.", Item."No.");
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue);

        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    procedure OverrideDimWithNewLocationsOnItemJournalLine()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal Line]
        // [SCENARIO 459647] Select Location Code, then New Location Code on item journal line - the program will update "Dimension Set ID" and "New Dimension Set ID".
        Initialize();

        // [GIVEN] Global dimension 1 values "V1" and "V2".
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Assign value "V1" to location "BLUE".
        // [GIVEN] Assign value "V2" to location "RED".
        LibraryInventory.CreateItem(Item);
        CreateLocationWithDefaultDimension(LocationFrom, DimensionValue[1]);
        CreateLocationWithDefaultDimension(LocationTo, DimensionValue[2]);

        // [GIVEN] Create item reclassification journal line.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, "Item Ledger Entry Type"::Transfer);
        ItemJournalline.Validate("Item No.", Item."No.");

        // [GIVEN] Set "Location Code" = "BLUE" on the item journal line.
        // [GIVEN] Verify that "Shortcut Dimension 1 Code" = "V1".
        // [GIVEN] Verify that "Dimension Set ID" includes value "V1".
        ItemJournalLine.Validate("Location Code", LocationFrom.Code);
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);

        // [WHEN] Set "New Location Code" = "RED".
        ItemJournalLine.Validate("New Location Code", LocationTo.Code);

        // [THEN] "New Shortcut Dimension 1 Code" = "V2".
        // [THEN] "New Dimension Set ID" includes value "V2".
        ItemJournalLine.TestField("New Shortcut Dimension 1 Code", DimensionValue[2].Code);
        VerifyDimensionValue(ItemJournalLine."New Dimension Set ID", DimensionValue[2]);

        // [THEN] "Shortcut Dimension 1 Code" remains "V1".
        // [THEN] "Dimension Set ID" is not changed.
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DimensionsFromLocationOnPhysInvtOrder()
    var
        DimensionValue: Record "Dimension Value";
        Location: Record Location;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [FEATURE] [Physical Inventory Order]
        // [SCENARIO 459647] Select location code with dimension on physical inventory order header - the system will propagate the dimension to the lines.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        CreateLocationWithDefaultDimension(Location, DimensionValue);

        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", LibraryInventory.CreateItemNo());

        PhysInvtOrderHeader.Validate("Location Code", Location.Code);
        PhysInvtOrderHeader.Modify(true);

        PhysInvtOrderHeader.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
        VerifyDimensionValue(PhysInvtOrderHeader."Dimension Set ID", DimensionValue);

        PhysInvtOrderLine.Find();
        PhysInvtOrderLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
        VerifyDimensionValue(PhysInvtOrderLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    procedure OverrideDimWithLocationsOnPhysInvtLine()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        Location: Record Location;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [FEATURE] [Physical Inventory Order]
        // [SCENARIO 459647] Select item, then location with the same dimension on physical inventory order line - the system will override the item's dimension with the location's one.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));
        CreateItemWithDefaultDimension(Item, DimensionValue[1]);
        CreateLocationWithDefaultDimension(Location, DimensionValue[2]);

        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        PhysInvtOrderLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(PhysInvtOrderLine."Dimension Set ID", DimensionValue[1]);

        PhysInvtOrderLine.Validate("Location Code", Location.Code);
        PhysInvtOrderLine.TestField("Shortcut Dimension 1 Code", DimensionValue[2].Code);
        VerifyDimensionValue(PhysInvtOrderLine."Dimension Set ID", DimensionValue[2]);
    end;

    [Test]
    procedure DoNotOverrideDimFromItemWithBlankOnPhysInvtLine()
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        Location: Record Location;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [FEATURE] [Physical Inventory Order]
        // [SCENARIO 459647] Select item with dimension, then location without dimension on physical inventory order line - the system will keep the item's dimension value.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        CreateItemWithDefaultDimension(Item, DimensionValue);
        LibraryWarehouse.CreateLocation(Location);

        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        PhysInvtOrderLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
        VerifyDimensionValue(PhysInvtOrderLine."Dimension Set ID", DimensionValue);

        PhysInvtOrderLine.Validate("Location Code", Location.Code);
        PhysInvtOrderLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
        VerifyDimensionValue(PhysInvtOrderLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DimensionsFromLocationToOnTransfer()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        LocationFrom: array[2] of Record Location;
        LocationTo: array[2] of Record Location;
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferRoute: Record "Transfer Route";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 459647] Select Transfer-from Code, then Transfer-to Code on transfer header - the system will override the from-location's dimension value with the to-location's one.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));
        LibraryWarehouse.CreateLocation(LocationFrom[1]);
        LibraryWarehouse.CreateLocation(LocationTo[1]);
        CreateLocationWithDefaultDimension(LocationFrom[2], DimensionValue[1]);
        CreateLocationWithDefaultDimension(LocationTo[2], DimensionValue[2]);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.CreateAndUpdateTransferRoute(TransferRoute, LocationFrom[1].Code, LocationTo[1].Code, LocationInTransit.Code, '', '');
        LibraryInventory.CreateAndUpdateTransferRoute(TransferRoute, LocationFrom[2].Code, LocationTo[2].Code, LocationInTransit.Code, '', '');

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom[1].Code, LocationTo[1].Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        TransferHeader.Validate("Transfer-from Code", LocationFrom[2].Code);
        TransferHeader.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(TransferHeader."Dimension Set ID", DimensionValue[1]);

        TransferHeader.Validate("Transfer-to Code", LocationTo[2].Code);
        TransferHeader.TestField("Shortcut Dimension 1 Code", DimensionValue[2].Code);
        VerifyDimensionValue(TransferHeader."Dimension Set ID", DimensionValue[2]);

        TransferLine.Find();
        TransferLine.TestField("Shortcut Dimension 1 Code", DimensionValue[2].Code);
        VerifyDimensionValue(TransferLine."Dimension Set ID", DimensionValue[2]);
    end;

    [Test]
    procedure MergeDimsFromHeaderAndItemOnTransferLine()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferRoute: Record "Transfer Route";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 459647] Select Transfer-from Code with one dimension on transfer header, then validate item with another dimension on transfer line - the system will merge the location's dimension value with the item's one.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(2));
        CreateLocationWithDefaultDimension(LocationFrom, DimensionValue[1]);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.CreateAndUpdateTransferRoute(TransferRoute, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code, '', '');

        CreateItemWithDefaultDimension(Item, DimensionValue[2]);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));
        TransferLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(TransferLine."Dimension Set ID", DimensionValue[1]);
        TransferLine.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        VerifyDimensionValue(TransferLine."Dimension Set ID", DimensionValue[2]);
    end;

    [Test]
    procedure ValuePostingRespectedForLocationDimForItemJournalLine()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 461631] Value Posting property on location's dimension is respected when posting item journal line.
        Initialize();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, Location.Code, LibraryERM.GetGlobalDimensionCode(1), '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, LibraryInventory.CreateItemNo(), Location.Code, '', LibraryRandom.RandInt(10));

        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        Assert.ExpectedError(LibraryERM.GetGlobalDimensionCode(1));
    end;

    [Test]
    procedure ValuePostingRespectedForLocationDimForTransferShipment()
    var
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        DefaultDimension: Record "Default Dimension";
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferRoute: Record "Transfer Route";
    begin
        // [FEATURE] [Transfer Order] [Shipment]
        // [SCENARIO 461631] Value Posting property on location's dimension is respected when posting transfer shipment.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.CreateAndUpdateTransferRoute(TransferRoute, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code, '', '');

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", LocationFrom.Code, '', LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, LocationFrom.Code, LibraryERM.GetGlobalDimensionCode(1), '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        Assert.ExpectedError(LibraryERM.GetGlobalDimensionCode(1));
    end;

    [Test]
    procedure ValuePostingRespectedForLocationDimForTransferReceipt()
    var
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        DefaultDimension: Record "Default Dimension";
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferRoute: Record "Transfer Route";
    begin
        // [FEATURE] [Transfer Order] [Receipt]
        // [SCENARIO 461631] Value Posting property on location's dimension is respected when posting transfer receipt.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.CreateAndUpdateTransferRoute(TransferRoute, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code, '', '');

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", LocationFrom.Code, '', LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, LocationTo.Code, LibraryERM.GetGlobalDimensionCode(1), '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        Assert.ExpectedError(LibraryERM.GetGlobalDimensionCode(1));
    end;

    [Test]
    procedure ValuePostingRespectedForLocationDimForPhysInvtOrder()
    var
        Item: Record Item;
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        ItemJournalLine: Record "Item Journal Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [FEATURE] [Physical Inventory Order]
        // [SCENARIO 461631] Value Posting property on location's dimension is respected when posting physical inventory order.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, Location.Code, LibraryERM.GetGlobalDimensionCode(1), '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        PhysInvtOrderHeader.Validate("Location Code", Location.Code);
        PhysInvtOrderHeader.Modify(true);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
        PhysInvtOrderLine.Modify();

        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        PhysInvtRecordHeader.Validate("Location Code", Location.Code);
        PhysInvtRecordHeader.Modify(true);
        LibraryInventory.CreatePhysInvtRecordLine(
          PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", 1);
        Codeunit.Run(CODEUNIT::"Phys. Invt. Rec.-Finish", PhysInvtRecordHeader);
        Codeunit.Run(CODEUNIT::"Phys. Invt. Order-Finish", PhysInvtOrderHeader);

        PhysInvtOrderHeader.Get(PhysInvtOrderHeader."No.");
        asserterror Codeunit.Run(Codeunit::"Phys. Invt. Order-Post", PhysInvtOrderHeader);

        Assert.ExpectedError(LibraryERM.GetGlobalDimensionCode(1));
    end;

    [Test]
    procedure OverrideDimWithLocationsOnJobJournalLine()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        Location: Record Location;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // [FEATURE] [Job Journal Line]
        // [SCENARIO 463987] Select item, then location with the same dimension on job journal line - the program will override the item's dimension with the location's.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));

        CreateItemWithDefaultDimension(Item, DimensionValue[1]);
        CreateLocationWithDefaultDimension(Location, DimensionValue[2]);

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(JobJournalLine."Dimension Set ID", DimensionValue[1]);

        JobJournalLine.Validate("Location Code", Location.Code);
        JobJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[2].Code);
        VerifyDimensionValue(JobJournalLine."Dimension Set ID", DimensionValue[2]);
    end;

    [Test]
    procedure DoNotOverrideDimFromItemWithBlankOnJobJournalLine()
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        Location: Record Location;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // [FEATURE] [Job Journal Line]
        // [SCENARIO 463987] Select item with dimension, then location without dimensions on job journal line - the program will keep the item's dimension.
        Initialize();

        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        CreateItemWithDefaultDimension(Item, DimensionValue);
        LibraryWarehouse.CreateLocation(Location);

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
        VerifyDimensionValue(JobJournalLine."Dimension Set ID", DimensionValue);

        JobJournalLine.Validate("Location Code", Location.Code);
        JobJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
        VerifyDimensionValue(JobJournalLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ValuePostingRespectedForLocationDimForJobJournalLine()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // [FEATURE] [Job Journal Line]
        // [SCENARIO 461631] Value Posting property on location's dimension is respected when posting job journal line.
        Initialize();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, Location.Code, LibraryERM.GetGlobalDimensionCode(1), '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", LibraryInventory.CreateItemNo());
        JobJournalLine.Validate("Location Code", Location.Code);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));
        JobJournalLine.Modify(true);

        asserterror LibraryJob.PostJobJournal(JobJournalLine);

        Assert.ExpectedError(LibraryERM.GetGlobalDimensionCode(1));
    end;

    [Test]
    procedure VerifyDefaultDimensionOnTransferOrder()
    var
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        TransferHeader: Record "Transfer Header";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO 472831] Verify Transfer Header should automatically be created when a default dimension is assigned to the Transfer-from Location.
        Initialize();

        // [GIVEN] Create Dimension and Dimension Value.
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Create a Location with Default Dimension.
        CreateLocationWithDefaultDimension(Location, DimensionValue);

        // [GIVEN] Open a new Transfer Order.
        TransferOrder.OpenNew();

        // [THEN] Assign a Location with Default Dimension to "Transfer-from Code".
        TransferOrder."Transfer-from Code".SetValue(Location.Code);

        // [THEN] Get the Transfer Header.
        TransferHeader.Get(TransferOrder."No.".Value());
        TransferOrder.OK().Invoke();

        // [VERIFY] Verify Default Dimension on the Transfer Header.
        VerifyDimensionValue(TransferHeader."Dimension Set ID", DimensionValue);
    end;

    [Test]
    procedure ItemReclassificationJournalShouldPostWithoutDimensionError()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 482814] Dimension Error in Item Reclassification Journal
        Initialize();

        // [GIVEN] Global dimension 1 values "V1" and "V2".
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Assign value "V1" to location "BLUE".
        // [GIVEN] Assign value "V2" to location "RED".
        LibraryInventory.CreateItem(Item);
        CreateLocationWithDefaultDimension(LocationFrom, DimensionValue[1]);
        CreateLocationWithDefaultDimension(LocationTo, DimensionValue[2]);

        // [GIVEN] Create item reclassification journal line.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, "Item Ledger Entry Type"::Transfer);
        ItemJournalline.Validate("Item No.", Item."No.");

        // [GIVEN] Set "Location Code" = "BLUE" on the item journal line.
        // [GIVEN] Verify that "Shortcut Dimension 1 Code" = "V1".
        // [GIVEN] Verify that "Dimension Set ID" includes value "V1".
        ItemJournalLine.Validate("Location Code", LocationFrom.Code);
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);

        // [WHEN] Set "New Location Code" = "RED".
        ItemJournalLine.Validate("New Location Code", LocationTo.Code);

        // [THEN] "New Shortcut Dimension 1 Code" = "V2".
        // [THEN] "New Dimension Set ID" includes value "V2".
        ItemJournalLine.TestField("New Shortcut Dimension 1 Code", DimensionValue[2].Code);
        VerifyDimensionValue(ItemJournalLine."New Dimension Set ID", DimensionValue[2]);

        // [THEN] "Shortcut Dimension 1 Code" remains "V1".
        // [THEN] "Dimension Set ID" is not changed.
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);

        // [VERIFY] Verify: Item Reclassification Journal should post successfully
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Test]
    procedure ItemReclassificationJournalShouldNotPostDueToDimensionError()
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 485261] 'New Project Code' is not validated on 'Reclassification Journal' even when the 'Value Posting' is marked as 'Code Mandatory'
        Initialize();

        // [GIVEN] Create 2 Locations e.g. "L1" and "L2"
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);

        // [GIVEN] Global Dimension 2 values "V1"
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Create Item with Default Dimension Values Posting as Code Mandatory
        CreateItemWithDefaultDimensionAndCodeMandatory(Item, DimensionValue);

        // [GIVEN] Create item reclassification journal line.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
            ItemJournalLine,
            ItemJournalBatch,
            ItemJournalTemplate.Name,
            ItemJournalBatch.Name,
            "Item Ledger Entry Type"::Transfer);
        ItemJournalline.Validate("Item No.", Item."No.");

        // [GIVEN] Set "Location Code" = "BLUE" and "New Location Code" = "RED" on the item journal line.
        ItemJournalLine.Validate("Location Code", LocationFrom.Code);
        ItemJournalLine.Validate("New Location Code", LocationTo.Code);
        ItemJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));

        // [GIVEN] Set "Shortcut Dimension 2 Code" = Project Code on the item journal line.
        ItemJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        ItemJournalLine.Modify(true);

        // [VERIFY] Verify: Item Reclassification Journal should not post 
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        Assert.ExpectedError(LibraryERM.GetGlobalDimensionCode(2));
    end;

    [Test]
    procedure ItemReclassificationJournalShouldPostWhenDimensionExistInNewShortcutDimension()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 485261] 'New Project Code' is not validated on 'Reclassification Journal' even when the 'Value Posting' is marked as 'Code Mandatory'
        Initialize();

        // [GIVEN] Create 2 Locations e.g. "L1" and "L2"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Global dimension 1 values "V1" and "V2".
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(2));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Create Item with Default Dimension Values Posting as Code Mandatory
        CreateItemWithDefaultDimensionAndCodeMandatory(Item, DimensionValue[1]);

        // [GIVEN] Post inventory for the item by creating item journal line.
        LibraryInventory.CreateItemJournalLineInItemTemplate(
            ItemJournalLine, Item."No.", LocationFrom.Code, '', LibraryRandom.RandIntInRange(50, 100));
        ItemJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue[1].Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.Reset();

        // [GIVEN] Create item reclassification journal line.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
            ItemJournalLine,
            ItemJournalBatch,
            ItemJournalTemplate.Name,
            ItemJournalBatch.Name,
            "Item Ledger Entry Type"::Transfer);
        ItemJournalline.Validate("Item No.", Item."No.");

        // [GIVEN] Set "Location Code" = "BLUE" and "New Location Code" = "RED" on the item journal line.
        ItemJournalLine.Validate("Location Code", LocationFrom.Code);
        ItemJournalLine.Validate("New Location Code", LocationTo.Code);
        ItemJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));

        // [GIVEN] Set "Shortcut Dimension 2 Code" and "New Shortcut Dimension 2 Code" as  Project Code on the item journal line.
        ItemJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue[1].Code);
        ItemJournalLine.Validate("New Shortcut Dimension 2 Code", DimensionValue[2].Code);
        ItemJournalLine.Modify(true);

        // [VERIFY] Verify: Item Reclassification Journal should post successfully
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Test]
    procedure ProjectAndProjectTaskDimensionReplacesLocationDimensionInProjectJournals()
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        Location: Record Location;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // [SCENARIO 543630] Location ID Dimension does not overrides the Project No. and Project Task No. Dimension in the Project Journals.
        Initialize();

        // [GIVEN] Create Dimension Value for Global Dimension 1.
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Dimension.
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Create Dimension Value for Dimension.
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Default Dimension for Location.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension,
            Database::Location,
            Location.Code,
            DimensionValue[2]."Dimension Code",
            DimensionValue[2].Code);

        // [GIVEN] Create a Job.
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create a Job Task with the Job and Validate the Dimension.
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("Global Dimension 1 Code", DimensionValue[1].Code);
        JobTask.Modify(true);

        // [GIVEN] Create Job Journal Line and Validate Item.
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");

        // [WHEN] Validate Location Code in Job Journal Line.
        JobJournalLine.Validate("Location Code", Location.Code);
        JobJournalLine.Modify(true);

        // [THEN] Dimension must be avilable in Job Journal Line.
        Assert.AreEqual(JobJournalLine."Shortcut Dimension 1 Code", DimensionValue[1].Code, ProjectTaskDimensionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerfiyDefaultDimensionPriorityOnTransferLine()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: array[6] of Record "Dimension Value";
        Item: Record Item;
        Location: array[3] of Record Location;
        SourceCodeSetup: Record "Source Code Setup";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [SCENARIO 556718] The default dimension priority should be respected when entering the item in the line of a transfer order.
        Initialize();

        // [GIVEN] Create Global Dimesnion with Dimension Values.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);

        // [GIVEN] Create Dimension Values.
        LibraryDimension.CreateDimensionValue(DimensionValue[3], DimensionValue[1]."Dimension Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[4], DimensionValue[2]."Dimension Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[5], DimensionValue[1]."Dimension Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[6], DimensionValue[2]."Dimension Code");

        // [GIVEN] Create Location 1 with Default Dimension Values.
        CreateLocationWithDefaultDimension(Location[1], DimensionValue[1]);
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension,
            Database::Location,
            Location[1].Code,
            DimensionValue[2]."Dimension Code",
            DimensionValue[2].Code);

        // [GIVEN] Create Location 2 with Default Dimension Values.
        CreateLocationWithDefaultDimension(Location[2], DimensionValue[3]);
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension,
            Database::Location,
            Location[2].Code,
            DimensionValue[2]."Dimension Code",
            DimensionValue[4].Code);

        // [GIVEN] Create Item with Default Dimension Values.
        CreateItemWithDefaultDimension(Item, DimensionValue[5]);
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension,
            Database::Item,
            Item."No.",
            DimensionValue[2]."Dimension Code",
            DimensionValue[6].Code);

        // [GIVEN] Create Default Dimension Priority 1 for Item, 2 for Location with source code.
        SourceCodeSetup.Get();
        SetDefaultDimensionPriority(SourceCodeSetup.Transfer);

        // [WHEN] Create Transfer Order.
        LibraryWarehouse.CreateInTransitLocation(Location[3]);
        LibraryInventory.CreateTransferHeader(
            TransferHeader,
            Location[1].Code,
            Location[2].Code,
            Location[3].Code);
        LibraryInventory.CreateTransferLine(
            TransferHeader,
            TransferLine,
            Item."No.",
            LibraryRandom.RandInt(10));

        // [THEN] The Default Dimension Prioritization is not ignored in the Transfer Order Line.
        Assert.AreNotEqual(TransferHeader."Shortcut Dimension 1 Code", TransferLine."Shortcut Dimension 1 Code", DimensionsNotEqualErr);
        Assert.AreNotEqual(TransferHeader."Shortcut Dimension 2 Code", TransferLine."Shortcut Dimension 2 Code", DimensionsNotEqualErr);
    end;

    [Test]
    procedure OverrideDimWithNewLocationsAndSalespersonOnItemJournalLine()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [SCENARIO 596687] In the Item Reclassification Journal is the Dimension value wrongly updated by adding a Sales Person to the line
        Initialize();

        // [GIVEN] Global dimension 1 values "V1" and "V2".
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Assign value "V1" to location "BLUE".
        // [GIVEN] Assign value "V2" to location "RED".
        LibraryInventory.CreateItem(Item);
        CreateLocationWithDefaultDimension(LocationFrom, DimensionValue[1]);
        CreateLocationWithDefaultDimension(LocationTo, DimensionValue[2]);

        // [GIVEN] Create item reclassification journal line.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, "Item Ledger Entry Type"::Transfer);
        ItemJournalline.Validate("Item No.", Item."No.");

        // [GIVEN] Set "Location Code" = "BLUE" on the item journal line.
        // [GIVEN] Verify that "Shortcut Dimension 1 Code" = "V1".
        // [GIVEN] Verify that "Dimension Set ID" includes value "V1".
        ItemJournalLine.Validate("Location Code", LocationFrom.Code);
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);

        // [WHEN] Set "New Location Code" = "RED".
        ItemJournalLine.Validate("New Location Code", LocationTo.Code);

        // [WHEN] Set "Sales Person Purchaser" = "RED".
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CreateDefaultDimensionWithSpecCode(SalespersonPurchaser.Code, DATABASE::"Salesperson/Purchaser");
        ItemJournalLine.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);

        // [THEN] "New Shortcut Dimension 1 Code" = "V2".
        // [THEN] "New Dimension Set ID" includes value "V2".
        ItemJournalLine.TestField("New Shortcut Dimension 1 Code", DimensionValue[2].Code);
        VerifyDimensionValue(ItemJournalLine."New Dimension Set ID", DimensionValue[2]);

        // [THEN] "Shortcut Dimension 1 Code" remains "V1".
        // [THEN] "Dimension Set ID" is not changed.
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        VerifyDimensionValue(ItemJournalLine."Dimension Set ID", DimensionValue[1]);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Dimension Locations");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Dimension Locations");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Dimension Locations");
    end;

    local procedure CreateItemWithDefaultDimension(var Item: Record Item; DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateLocationWithDefaultDimension(var Location: Record Location; DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateLocationWithDefaultDimensions(var Location: Record Location): Code[10]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibraryWarehouse.CreateLocation(Location);
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        end;
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, "Item Ledger Entry Type"::"Positive Adjmt.");
    end;

    local procedure GetLocationDefaultDimensions(var DefaultDimension: Record "Default Dimension"; LocationCode: Code[10])
    begin
        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", Database::Location);
        DefaultDimension.SetRange("No.", LocationCode);
    end;

    local procedure VerifyDimensionValue(DimensionSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure CreateItemWithDefaultDimensionAndCodeMandatory(var Item: Record Item; DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
    end;

    local procedure SetDefaultDimensionPriority(SourceCode: Code[10])
    begin
        ClearDefaultDimensionPriorities(SourceCode);
        CreateDefaultDimensionPriority(SourceCode, Database::Item, 1);
        CreateDefaultDimensionPriority(SourceCode, Database::Location, 2);
    end;

    local procedure ClearDefaultDimensionPriorities(SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll(true);
    end;

    local procedure CreateDefaultDimensionPriority(SourceCode: Code[10]; TableID: Integer; Priority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, TableID);
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Modify(true);
    end;

    local procedure CreateDefaultDimensionWithSpecCode(AccountNo: Code[20]; TableID: Integer)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        CreateDimensionValueWithSpecCode(DimensionValue, AccountNo, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, AccountNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateDimensionValueWithSpecCode(var DimensionValue: Record "Dimension Value"; DimensionValueCode: Code[20]; DimensionCode: Code[20])
    begin
        DimensionValue.Init();
        DimensionValue.Validate("Dimension Code", DimensionCode);
        DimensionValue.Validate(Code, DimensionValueCode);
        DimensionValue.Insert(true);
    end;

    [ModalPageHandler]
    procedure DefaultDimensionsMultipleModalPageHandler(var DefaultDimensionsMultiple: TestPage "Default Dimensions-Multiple")
    begin
        DefaultDimensionsMultiple.New();
        DefaultDimensionsMultiple."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple."Dimension Value Code".SetValue(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}