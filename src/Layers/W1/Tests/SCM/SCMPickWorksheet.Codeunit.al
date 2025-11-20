codeunit 137015 "SCM Pick Worksheet"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Pick] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ErrorDifferentQtyToHandle: Label 'Quantity to Handle on pick worksheet line different from expected.';
        ErrorDifferentQty: Label 'Quantity on pick worksheet line different from expected.';
        ErrorDifferentAvailQty: Label 'Quantity Available to Pick on pick worksheet line different from expected.';
        ErrorDifferentQtyOnPickLine: Label 'Quantity to Handle on pick line different from expected.';
        IsInitialized: Boolean;
        AvailableQtyToPickMsg: Label 'AvailableQtyToPick returned wrong value.';

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC17TC19()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Shipment1No: Code[20];
        Shipment2No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 10);
        Shipment1No := CreateSales(Item."No.", Location.Code, 5, true, true, false, 0);
        Shipment2No := CreateSales(Item."No.", Location.Code, 3, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment1No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 10);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment2No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 7);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 3, 5);

        // Exercise.
        CreatePickFromWksh(WhseWorksheetLine, 20000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        CreatePickFromWksh(WhseWorksheetLine, 10000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // Validate.
        ValidatePick(WhseActivityLine."Action Type"::Take, Shipment1No, 5);
        ValidatePick(WhseActivityLine."Action Type"::Place, Shipment1No, 5);
        ValidatePick(WhseActivityLine."Action Type"::Take, Shipment2No, 3);
        ValidatePick(WhseActivityLine."Action Type"::Place, Shipment2No, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC18TC20()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Shipment1No: Code[20];
        Shipment2No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 8);
        Shipment1No := CreateSales(Item."No.", Location.Code, 5, true, true, false, 0);
        Shipment2No := CreateSales(Item."No.", Location.Code, 3, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment1No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 8);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment2No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 5);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 3, 3);

        // Exercise.
        CreatePickFromWksh(WhseWorksheetLine, 20000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        CreatePickFromWksh(WhseWorksheetLine, 10000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // Validate.
        ValidatePick(WhseActivityLine."Action Type"::Take, Shipment1No, 5);
        ValidatePick(WhseActivityLine."Action Type"::Place, Shipment1No, 5);
        ValidatePick(WhseActivityLine."Action Type"::Take, Shipment2No, 3);
        ValidatePick(WhseActivityLine."Action Type"::Place, Shipment2No, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC21()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Shipment2No: Code[20];
        Shipment3No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 9);
        CreateSales(Item."No.", Location.Code, 5, false, true, true, 2);
        Shipment2No := CreateSales(Item."No.", Location.Code, 1, false, true, false, 0);
        Shipment3No := CreateSales(Item."No.", Location.Code, 3, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment2No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 1, 1, 4);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment3No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 1, 1, 1);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 3, 3);

        // Exercise.
        CreatePickFromWksh(WhseWorksheetLine, 20000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        CreatePickFromWksh(WhseWorksheetLine, 10000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // Validate.
        ValidatePick(WhseActivityLine."Action Type"::Take, Shipment2No, 1);
        ValidatePick(WhseActivityLine."Action Type"::Place, Shipment2No, 1);
        ValidatePick(WhseActivityLine."Action Type"::Take, Shipment3No, 3);
        ValidatePick(WhseActivityLine."Action Type"::Place, Shipment3No, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC22()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Shipment1No: Code[20];
        Shipment2No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 10);
        Shipment1No := CreateSales(Item."No.", Location.Code, 5, true, true, false, 0);
        Shipment2No := CreateSales(Item."No.", Location.Code, 3, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment1No);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment2No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 7);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 3, 5);

        // Exercise.
        PickWorksheetUpdateQtyToHandle(WhseWorksheetLine, 20000, 2);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 8);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 2, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC23()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Shipment1No: Code[20];
        Shipment2No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 8);
        Shipment1No := CreateSales(Item."No.", Location.Code, 5, true, true, false, 0);
        Shipment2No := CreateSales(Item."No.", Location.Code, 3, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment1No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 8);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment2No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 5);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 3, 3);

        // Exercise.
        PickWorksheetUpdateQtyToHandle(WhseWorksheetLine, 20000, 2);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 5, 6);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC24()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Shipment3No: Code[20];
        Shipment4No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 9);
        CreateSales(Item."No.", Location.Code, 5, false, true, true, 2);
        CreateSales(Item."No.", Location.Code, 4, true, false, false, 0);
        Shipment3No := CreateSales(Item."No.", Location.Code, 5, false, true, false, 0);
        Shipment4No := CreateSales(Item."No.", Location.Code, 8, false, true, false, 0);
        CreateSales(Item."No.", Location.Code, 8, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment3No);

        // Validate.
        // 4 will be reserved against RECEIVE bin and 1 can be picked from the PICK bin.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 1, 1);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment4No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 1, 1);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 8, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC25()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Shipment3No: Code[20];
        Shipment4No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 9);
        CreateSales(Item."No.", Location.Code, 5, false, true, true, 3);
        CreateSales(Item."No.", Location.Code, 1, true, false, false, 0);
        Shipment3No := CreateSales(Item."No.", Location.Code, 4, false, true, false, 0);
        Shipment4No := CreateSales(Item."No.", Location.Code, 2, false, true, false, 0);
        CreateSales(Item."No.", Location.Code, 2, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment3No);

        // Validate.
        // 4 will be reserved against RECEIVE bin and 1 can be picked from the PICK bin.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 4, 4, 4);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment4No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 4, 4, 4);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 2, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC26()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Shipment2No: Code[20];
        Shipment3No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 9);
        CreateSales(Item."No.", Location.Code, 5, false, true, true, 2);
        Shipment2No := CreateSales(Item."No.", Location.Code, 5, false, true, false, 0);
        Shipment3No := CreateSales(Item."No.", Location.Code, 8, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment2No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 4, 4);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment3No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 5, 4, 4);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 8, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GREENTC1()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Shipment2No: Code[20];
        Shipment3No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, false, true, false);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 10);
        CreateSales(Item."No.", Location.Code, 5, false, true, true, 2);
        Shipment2No := CreateSales(Item."No.", Location.Code, 2, false, true, false, 0);
        Shipment3No := CreateSales(Item."No.", Location.Code, 3, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment2No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 2, 2, 5);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment3No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 2, 2, 2);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 3, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GREENTC2()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Shipment2No: Code[20];
        Shipment3No: Code[20];
    begin
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, false, true, false);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 10);
        CreateSales(Item."No.", Location.Code, 5, false, true, true, 2);
        Shipment2No := CreateSales(Item."No.", Location.Code, 6, false, true, false, 0);
        Shipment3No := CreateSales(Item."No.", Location.Code, 3, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment2No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 6, 5, 5);

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment3No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 6, 5, 5);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 3, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailabilityWithReservationsOnMultipleLines()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseEmployee: Record "Warehouse Employee";
        PickWorksheetTestPage: TestPage "Pick Worksheet";
        Shipment3No: Code[20];
        Shipment4No: Code[20];
        Shipment5No: Code[20];
        Shipment6No: Code[20];
    begin
        // [SCENARIO 359031] Nothing to handle fix: Qty. available to pick on pick worksheet. The UI shows the minimum of available quantity to pick and quantity.
        // Setup.
        Initialize();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        WhseWorksheetLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        CreatePurchase(Item."No.", Location.Code, 10, 10);
        Shipment3No := CreateSales(Item."No.", Location.Code, 1, true, true, false, 0);
        Shipment4No := CreateSales(Item."No.", Location.Code, 2, false, true, false, 0);
        Shipment5No := CreateSales(Item."No.", Location.Code, 3, true, true, false, 0);
        Shipment6No := CreateSales(Item."No.", Location.Code, 4, false, true, false, 0);

        // Exercise.
        GetPickWksheetName(WhseWorksheetName);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment3No);

        // Validate.
        // (Total available qty - Qty to Handle on other worksheet lines) - Reserved qty on other worksheet lines
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 1, 1, 7); // QtyAvailToPick = min(10, (10 - 3)); 3 is reserved for Shipment5No

        // Validate Pick Worksheet Page field: Qty. Available to Pick. It will be minimum of available quantity to pick and quantity.
        PickWorksheetTestPage.OpenView();
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 10000);
        Assert.AreEqual(1, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.Close();

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment4No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 1, 1, 5); // QtyAvailToPick = min((10 - 2), (10 - 2 - 3));
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 2, 2, 6); // QtyAvailToPick = min((10 - 1), (10 - 1 - 3));

        // Validate Pick Worksheet Page field: Qty. Available to Pick. It will be minimum of available quantity to pick and quantity.
        PickWorksheetTestPage.OpenView();
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 10000);
        Assert.AreEqual(1, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 20000);
        Assert.AreEqual(2, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.Close();

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment5No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 1, 1, 5); // QtyAvailToPick = min((10 - 2 - 3), 0)
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 2, 2, 6); // QtyAvailToPick = min((10 - 1 - 3), 0); 
        PickWorkSheetValidateLine(WhseWorksheetLine, 30000, 3, 3, 7); // QtyAvailToPick = min((10 - 1 - 2), 0);

        // Validate Pick Worksheet Page field: Qty. Available to Pick. It will be minimum of available quantity to pick and quantity.
        PickWorksheetTestPage.OpenView();
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 10000);
        Assert.AreEqual(1, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 20000);
        Assert.AreEqual(2, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 30000);
        Assert.AreEqual(3, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.Close();

        // Exercise.
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, Shipment6No);

        // Validate.
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 2, 2, 2); // QtyAvailToPick = min((10 - 1 - 3 - 4), 0)
        PickWorkSheetValidateLine(WhseWorksheetLine, 30000, 3, 3, 3); // QtyAvailToPick = min((10 - 1 - 2 - 4), 0)
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 1, 1, 1); // QtyAvailToPick = min((10 - 2 - 3 - 4), 0)
        PickWorkSheetValidateLine(WhseWorksheetLine, 40000, 4, 4, 4); // QtyAvailToPick = min((10 - 1 - 2 - 3), 0)
        WhseWorksheetLine.AvailableQtyToPickForCurrentLine();

        // Validate Pick Worksheet Page field: Qty. Available to Pick. It will be minimum of available quantity to pick and quantity.
        PickWorksheetTestPage.OpenView();
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 10000);
        Assert.AreEqual(1, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 20000);
        Assert.AreEqual(2, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 30000);
        Assert.AreEqual(3, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.GoToKey(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 40000);
        Assert.AreEqual(4, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBinBlank()
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Whse. Worksheet Line]
        // [SCENARIO 378631] Procedure "GetBin" of "Whse. Worksheet Line" table should clear global variable Bin if Bin code is blank
        Initialize();

        // [GIVEN] Location "L" with Adjustment Bin Code "X"
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, false, false);

        // [GIVEN] Run CheckBin for Location "L" and Bin "X"
        asserterror WhseWorksheetLine.CheckBin(Location.Code, Location."Adjustment Bin Code", false);

        // [GIVEN] Catch Error "Adjustment Bin must be equal to 'No'"
        Assert.ExpectedTestFieldError(Bin.FieldCaption("Adjustment Bin"), Format(false));

        // [WHEN] Run CheckBin again with Location "X" and Bin blank
        WhseWorksheetLine.CheckBin(Location.Code, '', false);

        // [THEN] No error is thrown
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure PickWorksheetQtyToHandleValidatedWithReservAndNonPickableAllocation()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Bin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PurchaseQty: Decimal;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Pick Worksheet]
        // [SCENARIO 204644] It should be possible to set "Qty. to Handle" in the pick worksheet when item is reserved for the line's source document, and stock is partially allocated in a non-pickable bin
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Create a warehouse receipt for 20 pcs of item "I" on a location with "Directed Put-away and Pick"
        PurchaseQty := LibraryRandom.RandIntInRange(20, 50);
        // [GIVEN] Register a put-away for 10 pcs of item "I"
        CreatePurchase(Item."No.", Location.Code, PurchaseQty, PurchaseQty / 2);

        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();

        // [GIVEN] Put-away remaining 10 pcs into a put-away bin (non-pickable)
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, false));
        Bin.FindFirst();

        WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        SalesQty := PurchaseQty - LibraryRandom.RandInt(10);
        // [GIVEN] Create a sales order for 15 pcs of item "I" and reserve, do not post
        CreateSales(Item."No.", Location.Code, SalesQty, true, false, false, 0);
        // [GIVEN] Create another sales order for 5 pcs of item "I", reserve, release and create a warehouse shipment "WS"
        CreateSales(Item."No.", Location.Code, PurchaseQty - SalesQty, true, true, false, 0);

        // [GIVEN] In the pick worksheet, run "Get Warehouse Documents" and choose the shipment "WS" as a source
        LibraryVariableStorage.Enqueue(Location.Code);
        GetSingleWhsePickDoc(WhseWorksheetLine, Location.Code);

        // [WHEN] In the created pick worksheet lines, set "Qty. to Handle" = 5
        WhseWorksheetLine.Validate("Qty. to Handle", WhseWorksheetLine.Quantity);

        // [THEN] Quantity is validated successfully
        WhseWorksheetLine.TestField("Qty. to Handle (Base)", WhseWorksheetLine."Qty. (Base)");
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPickWithReservationAndPickedNotShippedLines()
    var
        Item: Record Item;
        Location: Record Location;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQty: Decimal;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Pick Worksheet] [Reservation]
        // [SCENARIO 204644] "Available Qty. to Pick" should be 0 in the pick worksheet when all stock is either reserved or pick, but not yet shipped
        Initialize();
        WhseWorksheetLine.DeleteAll();

        ResetDefaultSafetyLeadTime();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Post inventory of 10 pcs of item "I"
        PurchaseQty := LibraryRandom.RandIntInRange(20, 50);
        CreatePurchase(Item."No.", Location.Code, PurchaseQty, PurchaseQty);

        // [GIVEN] Create a purchase order for 15 pcs of item "I"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, Item."No.", PurchaseQty * 1.5, Location.Code);

        // [GIVEN] Sales order for 25 pcs item "I". Reserve all 25 pcs, create a warehouse shipment and pick. Do not register.
        SalesQty := PurchaseQty * 2.5;
        CreateSales(Item."No.", Location.Code, SalesQty, true, true, true, 0);

        // [GIVEN] Open the pick worksheet and set "Qty. to Handle" = 15 (quantity not yet on pick lines)
        LibraryVariableStorage.Enqueue(Location.Code);
        GetSingleWhsePickDoc(WhseWorksheetLine, Location.Code);

        WhseWorksheetLine.Validate("Qty. to Handle", WhseWorksheetLine."Qty. Outstanding");

        // [WHEN] Calculate available quantity to pic on the pick worksheet line
        // [THEN] Quantity available to pick is 0
        Assert.AreEqual(0, WhseWorksheetLine.AvailableQtyToPick(), ErrorDifferentQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWhenSalesReservationIsSplitOnInventory()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        BaseQty: Decimal;
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 305229] It should be possible to pick an item for a sales order when the sales document is reserved against the inventory, and reservation of each line is split on several item ledger entries

        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Post stock of item "I" in two parts: 1 piece and 2 pcs
        BaseQty := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, Item."No.", BaseQty, Location.Code);
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, Item."No.", BaseQty * 2, Location.Code);

        CreateWarehouseReceiptFromPurchOrder(WhseReceiptHeader, PurchaseHeader);
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Put-away", DATABASE::"Purchase Line",
          WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", 0, '', '');

        // [GIVEN] Create a sales order for item "I" with two lines: 2 pcs and 1 piece
        // [GIVEN] Reserve both sales lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineWithLocation(SalesLine, SalesHeader, Item."No.", BaseQty * 2, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        CreateSalesLineWithLocation(SalesLine, SalesHeader, Item."No.", BaseQty, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Release the sales order and create warehouse shipment
        CreateWarehouseShipmentFromSalesOrder(WhseShipmentHeader, SalesHeader);

        // [WHEN] Create pick from warehouse shipment
        LibraryWarehouse.CreatePick(WhseShipmentHeader);

        // [THEN] Total quantity in the pick is 3
        WhseActivityLine.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Sales Order");
        WhseActivityLine.SetRange("Whse. Document No.", WhseShipmentHeader."No.");
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.CalcSums(Quantity);
        WhseActivityLine.TestField(Quantity, BaseQty * 3);
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure PickWorksheetWithReservationSimpleLocation()
    var
        LocationYellow: Record Location;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [Pick Worksheet]
        // [SCENARIO 227780] It should be possible to pick quantity for a sales order when the sales document is reserved against the inventory and Location has no Bins

        Initialize();

        // [GIVEN] Create a new location
        LibraryWarehouse.CreateLocationWMS(LocationYellow, false, true, true, true, true);

        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Create new Item, Stock, Reserved and Released Sales Order, Released Whse. Shipment
        CreateInitialSetupForPickWorksheet(LocationYellow.Code, '', Quantity);

        // [GIVEN] Create new Pick Worksheet
        LibraryVariableStorage.Enqueue(LocationYellow.Code);
        GetSingleWhsePickDoc(WhseWorksheetLine, LocationYellow.Code);

        // [WHEN] Trying to assign all the reserved Qty for the Sales Order to "Qty. to Handle" field
        WhseWorksheetLine.Validate("Qty. to Handle", Quantity);
        WhseWorksheetLine.Modify(true);

        // [THEN] "Qty. to Handle" field value must be equal to assigned Qty; NO error must occur.
        WhseWorksheetLine.TestField("Qty. to Handle", Quantity);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleOnPickWorksheetWithReservationAtLocationWithBin()
    var
        LocationOrange: Record Location;
        Bin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [Pick Worksheet]
        // [SCENARIO 270423] It should be possible to pick quantity for a sales order, when the sales document is reserved against the inventory and bin is mandatory for the location.
        Initialize();

        Quantity := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Create a location with "Bin Mandatory" = TRUE.
        LibraryWarehouse.CreateLocationWMS(LocationOrange, true, true, true, true, true);
        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', 3, false);

        // [GIVEN] Create new Item, stock, reserved and released sales order, released whse. shipment.
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);
        CreateInitialSetupForPickWorksheet(LocationOrange.Code, Bin.Code, Quantity);

        // [WHEN] Open pick worksheet, invoke "Get Warehouse Documents", select the new whse. shipment.
        LibraryVariableStorage.Enqueue(LocationOrange.Code);
        GetSingleWhsePickDoc(WhseWorksheetLine, LocationOrange.Code);

        // [THEN] "Qty. to Handle" on whse. worksheet line is equal to the quantity in the shipment.
        WhseWorksheetLine.TestField("Qty. to Handle", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure QuantitiesOnPickWorksheetAtLocationWhite()
    var
        Item: Record Item;
        LocationWhite: Record Location;
        ShipmentNo: array[3] of Code[20];
    begin
        // [FEATURE] [Reservation] [Pick Worksheet]
        // [SCENARIO 270423] "Qty. to Handle" and "Available Qty. to Pick" on pick worksheet line are correct for lines, representing reserved and not reserved sales shipment at location with directed put-away and pick.
        Initialize();

        // [GIVEN] Location "White" set up for directed put-away and pick.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 3);

        // [GIVEN] 80 pcs of an item are in inventory.
        CreatePurchase(Item."No.", LocationWhite.Code, 80, 80);

        // [GIVEN] Create three sales orders, collectively for 90 pcs -
        // [GIVEN] 1st order is for 20 pcs, and it is reserved from the inventory.
        // [GIVEN] 2nd order is for 30 pcs, not reserved.
        // [GIVEN] 3rd order is for 40 pcs, reserved from the inventory.
        // [GIVEN] Create whse. shipments for all sales orders.
        ShipmentNo[1] := CreateSales(Item."No.", LocationWhite.Code, 20, true, true, false, 0);
        ShipmentNo[2] := CreateSales(Item."No.", LocationWhite.Code, 30, false, true, false, 0);
        ShipmentNo[3] := CreateSales(Item."No.", LocationWhite.Code, 40, true, true, false, 0);

        // [WHEN] Invoke "Get outbound documents", manually modify "Qty. to Handle" on all lines and run "Autofill Qty. to Handle" in pick worksheet.
        InvokeGetShipmentUpdateQtyToHandleAndAutofillInPickWorksheet(LocationWhite.Code, ShipmentNo);

        // [THEN] Quantity, "Qty. to Handle" and "Avail. Qty. to Pick" values are calculated correctly on each step for all three pick worksheet lines.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure QuantitiesOnPickWorksheetAtLocationOrange()
    var
        Item: Record Item;
        LocationOrange: Record Location;
        Bin: array[2] of Record Bin;
        ShipmentNo: array[3] of Code[20];
    begin
        // [FEATURE] [Reservation] [Pick Worksheet]
        // [SCENARIO 270423] "Qty. to Handle" and "Available Qty. to Pick" on pick worksheet line are correct for lines, representing reserved and not reserved sales shipment at location with mandatory bin, but disabled directed put-away and pick.
        Initialize();

        // [GIVEN] Location "Orange" with mandatory bin and required all warehouse documents, but disabled directed put-away and pick.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(LocationOrange, true, true, true, true, true);
        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', 3, false);
        LibraryWarehouse.FindBin(Bin[1], LocationOrange.Code, '', 1);
        LibraryWarehouse.FindBin(Bin[2], LocationOrange.Code, '', 2);
        LocationOrange.Validate("Receipt Bin Code", Bin[1].Code);
        LocationOrange.Validate("Shipment Bin Code", Bin[2].Code);
        LocationOrange.Modify(true);

        // [GIVEN] 80 pcs of an item are in inventory.
        CreatePurchase(Item."No.", LocationOrange.Code, 80, 80);

        // [GIVEN] Create three sales orders, collectively for 90 pcs -
        // [GIVEN] 1st order is for 20 pcs, and it is reserved from the inventory.
        // [GIVEN] 2nd order is for 30 pcs, not reserved.
        // [GIVEN] 3rd order is for 40 pcs, reserved from the inventory.
        // [GIVEN] Create whse. shipments for all sales orders.
        ShipmentNo[1] := CreateSales(Item."No.", LocationOrange.Code, 20, true, true, false, 0);
        ShipmentNo[2] := CreateSales(Item."No.", LocationOrange.Code, 30, false, true, false, 0);
        ShipmentNo[3] := CreateSales(Item."No.", LocationOrange.Code, 40, true, true, false, 0);

        // [WHEN] Invoke "Get outbound documents", manually modify "Qty. to Handle" on all lines and run "Autofill Qty. to Handle" in pick worksheet.
        InvokeGetShipmentUpdateQtyToHandleAndAutofillInPickWorksheet(LocationOrange.Code, ShipmentNo);

        // [THEN] Quantity, "Qty. to Handle" and "Avail. Qty. to Pick" values are calculated correctly on each step for all three pick worksheet lines.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure QuantitiesOnPickWorksheetAtLocationGreen()
    var
        Item: Record Item;
        LocationGreen: Record Location;
        ShipmentNo: array[3] of Code[20];
    begin
        // [FEATURE] [Reservation] [Pick Worksheet]
        // [SCENARIO 270423] "Qty. to Handle" and "Available Qty. to Pick" on pick worksheet line are correct for lines, representing reserved and not reserved sales shipment at location with no bins.
        Initialize();

        // [GIVEN] Location "Green" with no bins, but set up for required receive, ship, put-away and pick.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(LocationGreen, false, true, true, true, true);

        // [GIVEN] 80 pcs of an item are in inventory.
        CreatePurchase(Item."No.", LocationGreen.Code, 80, 80);

        // [GIVEN] Create three sales orders, collectively for 90 pcs -
        // [GIVEN] 1st order is for 20 pcs, and it is reserved from the inventory.
        // [GIVEN] 2nd order is for 30 pcs, not reserved.
        // [GIVEN] 3rd order is for 40 pcs, reserved from the inventory.
        // [GIVEN] Create whse. shipments for all sales orders.
        ShipmentNo[1] := CreateSales(Item."No.", LocationGreen.Code, 20, true, true, false, 0);
        ShipmentNo[2] := CreateSales(Item."No.", LocationGreen.Code, 30, false, true, false, 0);
        ShipmentNo[3] := CreateSales(Item."No.", LocationGreen.Code, 40, true, true, false, 0);

        // [WHEN] Invoke "Get outbound documents", manually modify "Qty. to Handle" on all lines and run "Autofill Qty. to Handle" in pick worksheet.
        InvokeGetShipmentUpdateQtyToHandleAndAutofillInPickWorksheet(LocationGreen.Code, ShipmentNo);

        // [THEN] Quantity, "Qty. to Handle" and "Avail. Qty. to Pick" values are calculated correctly on each step for all three pick worksheet lines.
    end;

    [Test]
    procedure AvailableToPickCannotBeNegative()
    var
        Location: Record Location;
        Item: Record Item;
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WarehouseEmployee: Record "Warehouse Employee";
        PickWorksheetTestPage: TestPage "Pick Worksheet";
        ShipmentNo: array[2] of Code[20];
        Qty: Integer;
    begin
        // [SCENARIO] [BUG] [486361] Pick worksheet: Available to Pick cannot be negative for directed put-away and pick location
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick enabled
        WhseWorksheetLine.DeleteAll();
        WarehouseEmployee.DeleteAll();
        GetPickWksheetTemplate(WhseWorksheetTemplate);
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Item with not inventory
        LibraryInventory.CreateItem(Item);

        // [GIVEN] 2 Warehouse shipments for same item
        Qty := 100;
        ShipmentNo[1] := CreateSales(Item."No.", Location.Code, Qty, false, true, false, 0);
        ShipmentNo[2] := CreateSales(Item."No.", Location.Code, Qty, false, true, false, 0);

        // [WHEN] Get the shipment in the pick worksheet
        WhseWorksheetName.SetRange("Template Type", WhseWorksheetName."Template Type"::Pick);
        WhseWorksheetName.SetRange("Location Code", Location.Code);
        WhseWorksheetName.FindFirst();
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, ShipmentNo[1]);
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, ShipmentNo[2]);

        // [THEN] Quantity available to pick is 0
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, Qty, 0, 0);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, Qty, 0, 0);

        // [WHEN] Update the quantity to handle from UI
        PickWorksheetTestPage.OpenEdit();
        WhseWorksheetLine.SetRange("Line No.", 10000);
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.FindFirst();
        PickWorksheetTestPage.GoToRecord(WhseWorksheetLine);
        PickWorksheetTestPage."Qty. to Handle".SetValue(Qty);

        // [THEN] Quantity available to pick is 0
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, Qty, Qty, 0);
        Assert.AreEqual(0, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.Close();

        // [WHEN] Update the quantity to handle from UI
        PickWorksheetTestPage.OpenEdit();
        WhseWorksheetLine.SetRange("Line No.", 20000);
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.FindFirst();
        PickWorksheetTestPage.GoToRecord(WhseWorksheetLine);
        PickWorksheetTestPage."Qty. to Handle".SetValue(Qty);

        // [THEN] Quantity available to pick is 0
        Assert.AreEqual(0, PickWorksheetTestPage.AvailableQtyToPickExcludingQCBins.AsDecimal(), ErrorDifferentAvailQty);
        PickWorksheetTestPage.Close();

        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, Qty, Qty, 0);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, Qty, Qty, 0);
    end;

    [Test]
    procedure QtyToHandleIsSetToMaximumAvailableQtyOnGetSrcDoc()
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Item: Record Item;
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WarehouseEmployee: Record "Warehouse Employee";
        ShipmentNo: Code[20];
        BinCode: array[2] of Code[20];
        ZoneCode: array[2] of Code[10];
        SalesLineQty: Decimal;
        Qty: array[2] of Decimal;
    begin
        // [SCENARIO 487516] Set the qty. to handle to max available to pick regardless of the settings of location always create pick line
        Initialize();
        Qty[1] := 10;
        Qty[2] := 10;
        LibraryInventory.CreateItem(Item);
        WhseWorksheetLine.DeleteAll();
        GetPickWksheetTemplate(WhseWorksheetTemplate);

        // [GIVEN] Location with Directed Put-away and Pick enabled with two bins:
        // [GIVEN] Put-away only Bin "BPW"
        // [GIVEN] Bin "BP" with Pick enabled
        SetupLocation(Location, WhseWorksheetTemplate.Name, true, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        FindZoneAndBinWithPickDisabled(
          BinCode[1], ZoneCode[1], Location.Code, StrSubstNo('<>%1', Location."Adjustment Bin Code"),
          GetBinTypeFilterPickDisabled(true));
        FindZoneAndBinWithPickEnabled(BinCode[2], ZoneCode[2], Location.Code);

        // [GIVEN] Location has Always Create Pick Line as false
        Location.Validate("Always Create Pick Line", false);
        Location.Modify();

        // [GIVEN] Two Warehouse Journal Lines were registered: first with Bin "BPW" and Quantity 10 and second with Bin "BP" and Quantity 10
        // [GIVEN] Ran Calc. Whse Adj. in Item Journal and posted Item Journal Line
        CreateTwoWarehouseJnlLinesWithBinsAndZones(
          WarehouseJournalLine, Location.Code, Item."No.", BinCode, ZoneCode, Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);
        PostWhseAdjustment(WarehouseJournalLine."Item No.");

        // [GIVEN] 2 Warehouse shipments for same item
        SalesLineQty := 100;
        ShipmentNo := CreateSales(Item."No.", Location.Code, SalesLineQty, false, true, false, 0);

        // [WHEN] Get the shipment in the pick worksheet
        WhseWorksheetName.SetRange("Template Type", WhseWorksheetName."Template Type"::Pick);
        WhseWorksheetName.SetRange("Location Code", Location.Code);
        WhseWorksheetName.FindFirst();
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, ShipmentNo);

        // [THEN] Quantity to handle is set to available quantity to pick
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, SalesLineQty, Qty[2], Qty[2]);

        // [GIVEN] Delete the pick worksheet lines
        WhseWorksheetLine.SetRange("Line No.", 10000);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.Delete();

        // [GIVEN] Set the Always Create Pick Line to true
        Location.Validate("Always Create Pick Line", true);
        Location.Modify();

        // [WHEN] Get the shipment in the pick worksheet
        PickWorksheetGetSourceDocument(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, 0, ShipmentNo);

        // [THEN] Quantity to handle is set to available quantity to pick
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, SalesLineQty, Qty[2], Qty[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickExcludesQCBin()
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseEmployee: Record "Warehouse Employee";
        BinCode: array[2] of Code[20];
        ZoneCode: array[2] of Code[10];
        Qty: array[2] of Decimal;
        AvailableQtyToPick: Decimal;
    begin
        // [FEATURE] [Available Qty. To Pick]
        // [SCENARIO 297609] Whse. Worksheet Line AvailableQtyToPickExcludingQCBins when QC Bin
        Initialize();
        Qty[1] := LibraryRandom.RandDec(100, 2);
        Qty[2] := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Location with Directed Put-away and Pick enabled with two bins:
        // [GIVEN] QC Bin "BQC" (Pick/Put-away/Ship/Receive all disabled)
        // [GIVEN] Bin "BP" with Pick enabled
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        FindZoneAndBinWithPickDisabled(
          BinCode[1], ZoneCode[1], Location.Code, StrSubstNo('<>%1', Location."Adjustment Bin Code"),
          GetBinTypeFilterPickDisabled(false));
        FindZoneAndBinWithPickEnabled(BinCode[2], ZoneCode[2], Location.Code);

        // [GIVEN] Two Warehouse Journal Lines were registered: first with Bin "BQC" and Quantity 2 and second with Bin "BP" and Quantity 3
        // [GIVEN] Ran Calc. Whse Adj. in Item Journal and posted Item Journal Line
        CreateTwoWarehouseJnlLinesWithBinsAndZones(
          WarehouseJournalLine, Location.Code, LibraryInventory.CreateItemNo(), BinCode, ZoneCode, Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);
        PostWhseAdjustment(WarehouseJournalLine."Item No.");

        // [GIVEN] Created and released Sales Order and Warehouse Shipment (Whse. Pick Request was created)
        CreateSalesOrderWithItemAndLocation(
          SalesHeader, Location.Code, WarehouseJournalLine."Item No.", LibraryRandom.RandDec(100, 2));
        CreateWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Created Whse. Worksheet Line from Whse. Pick Request
        FindWhsePickRequestByWhseShipmentHeader(WhsePickRequest, WarehouseShipmentHeader."No.");
        CreateWhseWorksheetLineFromWhsePickRequest(WhseWorksheetLine, WhsePickRequest);

        // [WHEN] Run AvailableQtyToPickExcludingQCBins from Whse. Worksheet Line
        AvailableQtyToPick := WhseWorksheetLine.AvailableQtyToPick();

        // [THEN] AvailableQtyToPick returns 3
        WhseWorksheetLine.TestField("Item No.", WarehouseJournalLine."Item No.");
        Assert.AreEqual(Qty[2], AvailableQtyToPick, AvailableQtyToPickMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickExcludesPutAwayBin()
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseEmployee: Record "Warehouse Employee";
        BinCode: array[2] of Code[20];
        ZoneCode: array[2] of Code[10];
        Qty: array[2] of Decimal;
        AvailableQtyToPick: Decimal;
    begin
        // [FEATURE] [Available Qty. To Pick] [Qty. to Handle]
        // [SCENARIO 309257] Whse. Worksheet Line AvailableQtyToPickExcludingQCBins when Put-away Bin
        // [SCENARIO 312457] Whse. Worksheet Line Qty. to Handle doesn't exceed availability when Whse. Worksheet Line created from Whse. Pick Request
        Initialize();
        Qty[1] := LibraryRandom.RandDec(100, 2);
        Qty[2] := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Location with Directed Put-away and Pick enabled with two bins:
        // [GIVEN] Put-away only Bin "BPW"
        // [GIVEN] Bin "BP" with Pick enabled
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        FindZoneAndBinWithPickDisabled(
          BinCode[1], ZoneCode[1], Location.Code, StrSubstNo('<>%1', Location."Adjustment Bin Code"),
          GetBinTypeFilterPickDisabled(true));
        FindZoneAndBinWithPickEnabled(BinCode[2], ZoneCode[2], Location.Code);

        // [GIVEN] Two Warehouse Journal Lines were registered: first with Bin "BPW" and Quantity 2 and second with Bin "BP" and Quantity 3
        // [GIVEN] Ran Calc. Whse Adj. in Item Journal and posted Item Journal Line
        CreateTwoWarehouseJnlLinesWithBinsAndZones(
          WarehouseJournalLine, Location.Code, LibraryInventory.CreateItemNo(), BinCode, ZoneCode, Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);
        PostWhseAdjustment(WarehouseJournalLine."Item No.");

        // [GIVEN] Created and released Sales Order with 5 PCS and Warehouse Shipment (Whse. Pick Request was created)
        CreateSalesOrderWithItemAndLocation(SalesHeader, Location.Code, WarehouseJournalLine."Item No.", Qty[1] + Qty[2]);
        CreateWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Created Whse. Worksheet Line from Whse. Pick Request
        FindWhsePickRequestByWhseShipmentHeader(WhsePickRequest, WarehouseShipmentHeader."No.");
        CreateWhseWorksheetLineFromWhsePickRequest(WhseWorksheetLine, WhsePickRequest);

        // [WHEN] Run AvailableQtyToPickExcludingQCBins from Whse. Worksheet Line
        AvailableQtyToPick := WhseWorksheetLine.AvailableQtyToPick();

        // [THEN] AvailableQtyToPick returns 3
        WhseWorksheetLine.TestField("Item No.", WarehouseJournalLine."Item No.");
        Assert.AreEqual(Qty[2], AvailableQtyToPick, AvailableQtyToPickMsg);

        // [THEN] Qty. To Handle = 3 in Whse. Worksheet Line
        WhseWorksheetLine.TestField("Qty. to Handle", Qty[2]);

        // [THEN] Qty. Outstanding = 5 in Whse. Worksheet Line
        WhseWorksheetLine.TestField("Qty. Outstanding", Qty[1] + Qty[2]);
    end;

    [Test]
    procedure AvailableQtyToPickDoesNotModifyDescription()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Description: Text[100];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 420219] CalcAvailableQtyBase function in pick worksheet does not change description.
        Initialize();
        Description := LibraryUtility.GenerateGUID();

        WhseWorksheetLine.Init();
        WhseWorksheetLine."Item No." := LibraryInventory.CreateItemNo();
        WhseWorksheetLine.Description := Description;
        WhseWorksheetLine.Insert();

        WhseWorksheetLine.CalcAvailableQtyBase();
        WhseWorksheetLine.TestField(Description, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickExcludesBlockedPutAway()
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseEmployee: Record "Warehouse Employee";
        BinContent: Record "Bin Content";
        Item: Record Item;
        BinCode: array[2] of Code[20];
        ZoneCode: array[2] of Code[10];
        Qty: array[2] of Decimal;
        AvailableQtyToPick: Decimal;
    begin
        // [FEATURE] [Available Qty. To Pick]
        // [SCENARIO 433489] Whse. Worksheet Line AvailableQtyToPickExcludingQCBins when PutAway Bin with Blocked movement
        Initialize();
        Qty[1] := LibraryRandom.RandInt(10);
        Qty[2] := LibraryRandom.RandIntInRange(11, 100);

        // [GIVEN] Location with Directed Put-away and Pick enabled with two bins:
        // [GIVEN] Bin "BP" with Pick enabled
        // [GIVEN] Bin "BPWMD" (PutAway enabled, other disabled)
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        FindZoneAndBinWithPickEnabled(BinCode[1], ZoneCode[1], Location.Code);
        FindZoneAndBinWithPickDisabled(
          BinCode[2], ZoneCode[2], Location.Code, StrSubstNo('<>%1', Location."Adjustment Bin Code"),
          GetBinTypeFilterPickDisabled(true));

        // [GIVEN] Two Warehouse Journal Lines were registered: first with Bin "BP" and Quantity 2 and second with Bin "BPWMD" and Quantity 3
        // [GIVEN] Ran Calc. Whse Adj. in Item Journal and posted Item Journal Line
        CreateTwoWarehouseJnlLinesWithBinsAndZones(
          WarehouseJournalLine, Location.Code, LibraryInventory.CreateItemNo(), BinCode, ZoneCode, Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);
        PostWhseAdjustment(WarehouseJournalLine."Item No.");

        // [GIVEN] Created and released Sales Order and Warehouse Shipment (Whse. Pick Request was created)
        CreateSalesOrderWithItemAndLocation(
          SalesHeader, Location.Code, WarehouseJournalLine."Item No.", LibraryRandom.RandDec(100, 2));
        CreateWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Created Whse. Worksheet Line from Whse. Pick Request
        FindWhsePickRequestByWhseShipmentHeader(WhsePickRequest, WarehouseShipmentHeader."No.");
        CreateWhseWorksheetLineFromWhsePickRequest(WhseWorksheetLine, WhsePickRequest);
        Item.Get(WarehouseJournalLine."Item No.");

        // [GIVEN] Bin "BPWMD" has Block Movement = All
        BinContent.Get(Location.Code, BinCode[2], WarehouseJournalLine."Item No.", '', WarehouseJournalLine."Unit of Measure Code");
        BinContent.Validate("Block Movement", BinContent."Block Movement"::All);
        BinContent.Modify();

        // [WHEN] Run AvailableQtyToPickExcludingQCBins from Whse. Worksheet Line
        AvailableQtyToPick := WhseWorksheetLine.AvailableQtyToPick();

        // [THEN] AvailableQtyToPick returns 2 (quantity on blocked bin is not included) - before the fix the value was 0
        WhseWorksheetLine.TestField("Item No.", WarehouseJournalLine."Item No.");
        Assert.AreEqual(Qty[1], AvailableQtyToPick, AvailableQtyToPickMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickExcludesPutAway()
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        BinCode: array[2] of Code[20];
        ZoneCode: array[2] of Code[10];
        Qty: array[2] of Decimal;
        AvailableQtyToPick: Decimal;
    begin
        // [FEATURE] [Available Qty. To Pick]
        // [SCENARIO 433489] Whse. Worksheet Line AvailableQtyToPickExcludingQCBins when PutAway Bin 
        Initialize();
        Qty[1] := LibraryRandom.RandInt(10);
        Qty[2] := LibraryRandom.RandIntInRange(11, 100);

        // [GIVEN] Location with Directed Put-away and Pick enabled with two bins:
        // [GIVEN] Bin "BP" with Pick enabled
        // [GIVEN] Bin "BPWMD" (PutAway enabled, other disabled)
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        FindZoneAndBinWithPickEnabled(BinCode[1], ZoneCode[1], Location.Code);
        FindZoneAndBinWithPickDisabled(
          BinCode[2], ZoneCode[2], Location.Code, StrSubstNo('<>%1', Location."Adjustment Bin Code"),
          GetBinTypeFilterPickDisabled(true));

        // [GIVEN] Two Warehouse Journal Lines were registered: first with Bin "BP" and Quantity 2 and second with Bin "BPWMD" and Quantity 3
        // [GIVEN] Ran Calc. Whse Adj. in Item Journal and posted Item Journal Line
        CreateTwoWarehouseJnlLinesWithBinsAndZones(
          WarehouseJournalLine, Location.Code, LibraryInventory.CreateItemNo(), BinCode, ZoneCode, Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);
        PostWhseAdjustment(WarehouseJournalLine."Item No.");

        // [GIVEN] Created and released Sales Order and Warehouse Shipment (Whse. Pick Request was created)
        CreateSalesOrderWithItemAndLocation(
          SalesHeader, Location.Code, WarehouseJournalLine."Item No.", LibraryRandom.RandDec(100, 2));
        CreateWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Created Whse. Worksheet Line from Whse. Pick Request
        FindWhsePickRequestByWhseShipmentHeader(WhsePickRequest, WarehouseShipmentHeader."No.");
        CreateWhseWorksheetLineFromWhsePickRequest(WhseWorksheetLine, WhsePickRequest);
        Item.Get(WarehouseJournalLine."Item No.");

        // [WHEN] Run AvailableQtyToPickExcludingQCBins from Whse. Worksheet Line
        AvailableQtyToPick := WhseWorksheetLine.AvailableQtyToPick();

        // [THEN] AvailableQtyToPick returns 2 (quantity on blocked bin is not included) - it should not be 2 + 3 = 5
        WhseWorksheetLine.TestField("Item No.", WarehouseJournalLine."Item No.");
        Assert.AreEqual(Qty[1], AvailableQtyToPick, AvailableQtyToPickMsg);
    end;

    [Test]
    procedure NonInventoryItemsAreExcluded()
    var
        AssemblyItem: Record Item;
        InventoryItem: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ATOLink: Record "Assemble-to-Order Link";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // [SCENARIO] When creating warehouse worksheet lines from warehouse pick requests, then non-inventory items
        // are ignored.

        // [GIVEN] an assemble-to-order item with an assembly BOM containing an inventory & non-inventory item.
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", AssemblyItem."Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Modify(true);

        LibraryInventory.CreateItem(InventoryItem);

        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        LibraryAssembly.CreateAssemblyListComponent(
            "BOM Component Type"::Item, InventoryItem."No.", AssemblyItem."No.", '',
            BOMComponent."Resource Usage Type", 1, true);

        LibraryAssembly.CreateAssemblyListComponent(
        "BOM Component Type"::Item, NonInventoryItem."No.", AssemblyItem."No.", '',
        BOMComponent."Resource Usage Type", 1, true);

        // [GIVEN] A location requiring pick & shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);

        CreateAndPostItemJournalLine(InventoryItem."No.", 1, Location.Code, '');

        // [WHEN] Creating a sales order containing the assembly item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Shipment Date", CalcDate('<+1W>', WorkDate()));
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AssemblyItem."No.", 1);

        // [THEN] An assembly order is automatically created.
        Assert.IsTrue(ATOLink.AsmExistsForSalesLine(SalesLine), 'Expected Assemble-to-Order link to be created');

        // [GIVEN] A warehouse shipment for the sales order.
        CreateWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Creating work sheet lines via pick request.
        FindWhsePickRequestByWhseShipmentHeader(WhsePickRequest, WarehouseShipmentHeader."No.");
        CreateWhseWorksheetLineFromWhsePickRequest(WhseWorksheetLine, WhsePickRequest);

        // [THEN] Only a worksheet line for the inventory item is created.
        Assert.AreEqual(1, WhseWorksheetLine.Count(), 'Expected only one worksheet line to be created.');
        WhseWorksheetLine.TestField("Item No.", InventoryItem."No.");
        WhseWorksheetLine.TestField("Location Code", Location.Code);
        WhseWorksheetLine.TestField("Qty. (Base)", 1);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Pick Worksheet");
        // Initialize setup.
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Pick Worksheet");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Pick Worksheet");
    end;

    local procedure FindWhsePickRequestByWhseShipmentHeader(var WhsePickRequest: Record "Whse. Pick Request"; WarehouseShipmentHeaderNo: Code[20])
    begin
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
        WhsePickRequest.SetRange("Document No.", WarehouseShipmentHeaderNo);
        WhsePickRequest.FindFirst();
    end;

    local procedure CreateWhseWorksheetLineFromWhsePickRequest(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhsePickRequest: Record "Whse. Pick Request")
    begin
        LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWorksheetLine, WhsePickRequest, LibraryUtility.GenerateGUID());
        WhseWorksheetLine.SetRange("Location Code", WhsePickRequest."Location Code");
        WhseWorksheetLine.FindFirst();
    end;

    local procedure CreateTwoWarehouseJnlLinesWithBinsAndZones(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; ItemNo: Code[20]; BinCode: array[2] of Code[20]; ZoneCode: array[2] of Code[10]; Qty: array[2] of Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Index: Integer;
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationCode);
        for Index := 1 to ArrayLen(BinCode) do
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, ZoneCode[Index],
              BinCode[Index], WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty[Index]);
    end;

    local procedure CreateSalesOrderWithItemAndLocation(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure PostWhseAdjustment(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        LibraryWarehouse.PostWhseAdjustment(Item);
    end;

    local procedure FindZoneAndBinWithPickDisabled(var BinCode: Code[20]; var ZoneCode: Code[10]; LocationCode: Code[10]; BinCodeFilter: Text; BinTypeCodeFilter: Text)
    var
        Bin: Record Bin;
    begin
        Bin.SetFilter(Code, BinCodeFilter);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetFilter("Bin Type Code", BinTypeCodeFilter);
        Bin.FindFirst();
        BinCode := Bin.Code;
        ZoneCode := Bin."Zone Code";
    end;

    local procedure GetBinTypeFilterPickDisabled(IsPutAway: Boolean) BinTypeFilter: Text
    var
        BinType: Record "Bin Type";
    begin
        BinType.SetRange(Pick, false);
        BinType.SetRange("Put Away", IsPutAway);
        BinType.SetRange(Ship, false);
        BinType.SetRange(Receive, false);
        BinType.FindSet();
        repeat
            BinTypeFilter += BinType.Code + '|';
        until BinType.Next() = 0;
        BinTypeFilter := DelChr(BinTypeFilter, '>', '|');
        exit(BinTypeFilter);
    end;

    local procedure FindZoneAndBinWithPickEnabled(var BinCode: Code[20]; var ZoneCode: Code[10]; LocationCode: Code[10])
    var
        Bin: Record Bin;
        CreatePick: Codeunit "Create Pick";
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetFilter("Bin Type Code", CreatePick.GetBinTypeFilter(3));
        Bin.FindFirst();
        BinCode := Bin.Code;
        ZoneCode := Bin."Zone Code";
    end;

    local procedure CreateSales(ItemNo: Code[20]; Location: Code[10]; Quantity: Decimal; Reserve: Boolean; CreateShipment: Boolean; CreatePick: Boolean; QtyToRegister: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithLocation(SalesLine, SalesHeader, ItemNo, Quantity, Location);

        if Reserve then
            LibrarySales.AutoReserveSalesLine(SalesLine);

        if CreateShipment then begin
            CreateWarehouseShipmentFromSalesOrder(WhseShipmentHeader, SalesHeader);

            if CreatePick then begin
                LibraryWarehouse.CreatePick(WhseShipmentHeader);

                if QtyToRegister <> 0 then
                    RegisterWhseActivity(
                      WhseActivityLine."Activity Type"::Pick, 37,
                      WhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", QtyToRegister, '', '');
            end;
        end;

        exit(WhseShipmentHeader."No.");
    end;

    local procedure CreatePurchase(ItemNo: Code[20]; Location: Code[10]; Quantity: Decimal; QtyToRegister: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, ItemNo, Quantity, Location);

        CreateWarehouseReceiptFromPurchOrder(WhseReceiptHeader, PurchaseHeader);
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", QtyToRegister, '', GetBin(Location, false, false, true, true));
    end;

    local procedure PickWorksheetGetSourceDocument(WkshTemplateName: Code[10]; Name: Code[10]; Location: Code[10]; DocType: Option; DocNo: Code[20])
    var
        WhsePickRqst: Record "Whse. Pick Request";
        GetOutboundSourceDocuments: Report "Get Outbound Source Documents";
    begin
        GetOutboundSourceDocuments.SetPickWkshName(WkshTemplateName, Name, Location);
        WhsePickRqst.SetRange("Document Type", DocType);
        WhsePickRqst.SetRange("Document No.", DocNo);
        WhsePickRqst.FindFirst();
        GetOutboundSourceDocuments.SetHideDialog(true);
        GetOutboundSourceDocuments.UseRequestPage(false);
        GetOutboundSourceDocuments.SetTableView(WhsePickRqst);
        GetOutboundSourceDocuments.RunModal();
    end;

    local procedure PickWorkSheetValidateLine(WhseWorksheetLine: Record "Whse. Worksheet Line"; LineNo: Integer; Qty: Decimal; QtyToHandle: Decimal; QtyAvailToPick: Decimal)
    begin
        WhseWorksheetLine.SetRange("Line No.", LineNo);
        WhseWorksheetLine.FindFirst();
        Assert.AreEqual(Qty, WhseWorksheetLine.Quantity, ErrorDifferentQty);
        Assert.AreEqual(QtyToHandle, WhseWorksheetLine."Qty. to Handle", ErrorDifferentQtyToHandle);
        Assert.AreEqual(QtyAvailToPick, WhseWorksheetLine.AvailableQtyToPick(), ErrorDifferentAvailQty);
    end;

    local procedure PickWorksheetUpdateQtyToHandle(WhseWorksheetLine: Record "Whse. Worksheet Line"; LineNo: Integer; QtyToHandle: Decimal)
    begin
        WhseWorksheetLine.SetRange("Line No.", LineNo);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.Validate("Qty. to Handle", QtyToHandle);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure InvokeGetShipmentUpdateQtyToHandleAndAutofillInPickWorksheet(LocationCode: Code[10]; ShipmentNo: array[3] of Code[20])
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        i: Integer;
    begin
        WhseWorksheetLine.DeleteAll();
        GetPickWksheetName(WhseWorksheetName);

        // test quantity fields on pick worksheet lines after getting source documents
        for i := 1 to ArrayLen(ShipmentNo) do
            PickWorksheetGetSourceDocument(
              WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode, 0, ShipmentNo[i]);
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 20, 20, 20);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 30, 20, 20);
        PickWorkSheetValidateLine(WhseWorksheetLine, 30000, 40, 40, 40);

        // test quantity fields on pick worksheet lines after update quantity to handle
        PickWorksheetUpdateQtyToHandle(WhseWorksheetLine, 10000, 10);
        PickWorksheetUpdateQtyToHandle(WhseWorksheetLine, 20000, 30);
        PickWorksheetUpdateQtyToHandle(WhseWorksheetLine, 30000, 30);
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 20, 10, 20);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 30, 20, 20);
        PickWorkSheetValidateLine(WhseWorksheetLine, 30000, 40, 30, 40);

        // test quantity fields on pick worksheet lines after invoking "Autofill Qty. to Handle"
        WhseWorksheetLine.AutofillQtyToHandle(WhseWorksheetLine);
        PickWorkSheetValidateLine(WhseWorksheetLine, 10000, 20, 20, 20);
        PickWorkSheetValidateLine(WhseWorksheetLine, 20000, 30, 20, 20);
        PickWorkSheetValidateLine(WhseWorksheetLine, 30000, 40, 40, 40);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateInitialSetupForPickWorksheet(LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationCode, BinCode);
        exit(CreateSales(Item."No.", LocationCode, Quantity, true, true, false, 0));
    end;

    local procedure CreatePickFromWksh(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LineNo: Integer; WkshTemplateName: Code[10]; Name: Code[10]; LocationCode: Code[10]; AssignedID: Code[10]; MaxNoOfLines: Integer; MaxNoOfSourceDoc: Integer; SortPick: Enum "Whse. Activity Sorting Method"; PerShipTo: Boolean; PerItem: Boolean; PerZone: Boolean; PerBin: Boolean; PerWhseDoc: Boolean; PerDate: Boolean; PrintPick: Boolean)
    var
        WhseWorksheetLine2: Record "Whse. Worksheet Line";
        CreatePick: Report "Create Pick";
    begin
        WhseWorksheetLine2 := WhseWorksheetLine;
        WhseWorksheetLine2.SetRange("Worksheet Template Name", WkshTemplateName);
        WhseWorksheetLine2.SetRange(Name, Name);
        WhseWorksheetLine2.SetRange("Location Code", LocationCode);
        WhseWorksheetLine2.SetRange("Line No.", LineNo);

        CreatePick.InitializeReport(
          AssignedID, MaxNoOfLines, MaxNoOfSourceDoc, SortPick, PerShipTo, PerItem,
          PerZone, PerBin, PerWhseDoc, PerDate, PrintPick, false, false);
        CreatePick.UseRequestPage(false);
        CreatePick.SetWkshPickLine(WhseWorksheetLine2);
        CreatePick.RunModal();
        Clear(CreatePick);

        WhseWorksheetLine := WhseWorksheetLine2;
    end;

    local procedure CreatePurchaseLineWithLocation(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLineWithLocation(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateWarehouseReceiptFromPurchOrder(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var PurchaseHeader: Record "Purchase Header")
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
    end;

    local procedure CreateWarehouseShipmentFromSalesOrder(var WhseShipmentHeader: Record "Warehouse Shipment Header"; var SalesHeader: Record "Sales Header")
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WhseShipmentHeader);
    end;

    local procedure GetSingleWhsePickDoc(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);

        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode);
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure ValidatePick(LineType: Enum "Warehouse Action Type"; ShipmentNo: Code[20]; ExpectedQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Source Type", 37);
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Sales Order");
        WhseActivityLine.SetRange("Whse. Document No.", ShipmentNo);
        WhseActivityLine.SetRange("Action Type", LineType);
        WhseActivityLine.FindFirst();
        Assert.AreEqual(ExpectedQty, WhseActivityLine.Quantity, ErrorDifferentQtyOnPickLine);
    end;

    local procedure SetupLocation(var Location: Record Location; WorksheetTemplateName: Code[20]; IsDirected: Boolean; ShipmentRequired: Boolean; BinMandatory: Boolean)
    var
        Bin: Record Bin;
    begin
        Location.Init();
        if not IsDirected then begin
            Location.SetRange("Bin Mandatory", BinMandatory);
            Location.SetRange("Require Shipment", ShipmentRequired);
            Location.SetRange("Require Receive", true);
            Location.SetRange("Require Pick", true);
            Location.SetRange("Require Put-away", true);
            Location.SetRange("Directed Put-away and Pick", IsDirected);
            if not Location.FindFirst() then begin
                LibraryWarehouse.CreateLocation(Location);
                Location.Validate("Require Put-away", true);
                Location.Validate("Always Create Put-away Line", true);
                Location.Validate("Require Pick", true);
                Location.Validate("Require Receive", ShipmentRequired);
                Location.Validate("Require Shipment", ShipmentRequired);
                Location.Validate("Bin Mandatory", BinMandatory);
                Location.Modify(true);
                CreateBin(Bin, Location.Code, 'RECEIPT', '', '');
                CreateBin(Bin, Location.Code, WorksheetTemplateName, '', '');
                CreateBin(Bin, Location.Code, 'SHIPMENT', '', '');
            end;
        end else begin
            Location.SetRange("Directed Put-away and Pick", IsDirected);
            Location.FindFirst();
        end;
        Location.Validate("Always Create Pick Line", false);
        Location.Modify(true);
    end;

    local procedure CreateBin(var Bin: Record Bin; LocationCode: Text[10]; BinCode: Text[20]; ZoneCode: Text[10]; BinTypeCode: Text[10])
    begin
        Clear(Bin);
        Bin.Init();
        Bin.Validate("Location Code", LocationCode);
        Bin.Validate(Code, BinCode);
        Bin.Validate("Zone Code", ZoneCode);
        Bin.Validate("Bin Type Code", BinTypeCode);
        Bin.Insert(true);
    end;

    local procedure RegisterWhseActivity(ActivityType: Enum "Warehouse Activity Type"; SourceType: Integer; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; QtyToHandle: Decimal; TakeBinCode: Code[10]; PlaceBinCode: Code[10])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Source Type", SourceType);
        WhseActivityLine.SetRange("Source Document", SourceDocument);
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.FindSet();
        repeat
            if QtyToHandle <> 0 then
                WhseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Take) and (TakeBinCode <> '') then
                WhseActivityLine."Bin Code" := TakeBinCode
            else
                if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Place) and (PlaceBinCode <> '') then
                    WhseActivityLine."Bin Code" := PlaceBinCode;

            WhseActivityLine.Modify();
        until WhseActivityLine.Next() = 0;

        Clear(WhseActivityHeader);
        WhseActivityHeader.SetRange(Type, ActivityType);
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();
        if (ActivityType = ActivityType::"Put-away") or (ActivityType = ActivityType::Pick) then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader)
        else
            LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
    end;

    local procedure ResetDefaultSafetyLeadTime()
    begin
        LibraryPlanning.SetDefaultSafetyLeadTime('<0D>');
    end;

    local procedure GetPickWksheetTemplate(var WhseWorksheetTemplate: Record "Whse. Worksheet Template")
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Pick);
        WhseWorksheetTemplate.FindFirst();
    end;

    local procedure GetPickWksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name")
    begin
        WhseWorksheetName.SetRange("Template Type", WhseWorksheetName."Template Type"::Pick);
        WhseWorksheetName.FindFirst();
    end;

    local procedure GetBin(LocationCode: Code[10]; Receive: Boolean; Ship: Boolean; Putaway: Boolean; Pick: Boolean): Code[10]
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(Receive, Ship, Putaway, Pick));
        if Bin.FindFirst() then
            exit(Bin.Code);

        exit('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelection: Page "Pick Selection"; var Response: Action)
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        WhsePickRequest.SetRange("Location Code", LibraryVariableStorage.DequeueText());
        WhsePickRequest.FindFirst();
        PickSelection.SetRecord(WhsePickRequest);
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

