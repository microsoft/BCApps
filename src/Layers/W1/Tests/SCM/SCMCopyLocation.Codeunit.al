codeunit 137223 "SCM Copy Location"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Location] [Copy] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        CopyLocationTestSubscriber: Codeunit "Copy Location Test Subscriber";
        IsInitialized: Boolean;
        TargetLocationCodeEmptyErr: Label 'You must specify the target location code.';
        TargetLocationAlreadyExistsErr: Label 'Target location code %1 already exists.', Comment = '%1 - location code.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Copy Location");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Copy Location");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Copy Location");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationBasicFields()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location]
        // [SCENARIO] Basic location fields are copied to new location.
        Initialize();

        // [GIVEN] Source location with basic fields populated.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        SourceLocation.Name := 'Source Location Name';
        SourceLocation.Address := '123 Main Street';
        SourceLocation.City := 'Seattle';
        SourceLocation."Post Code" := '98101';
        SourceLocation."Country/Region Code" := 'US';
        SourceLocation.Modify(true);

        // [GIVEN] Copy location buffer with target code.
        TargetCode := LibraryUtility.GenerateGUID();
        TargetCode := CopyStr(TargetCode, 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created with source location fields.
        TargetLocation.Get(TargetCode);
        Assert.AreEqual(SourceLocation.Name, TargetLocation.Name, 'Name should match');
        Assert.AreEqual(SourceLocation.Address, TargetLocation.Address, 'Address should match');
        Assert.AreEqual(SourceLocation.City, TargetLocation.City, 'City should match');
        Assert.AreEqual(SourceLocation."Post Code", TargetLocation."Post Code", 'Post Code should match');
        Assert.AreEqual(SourceLocation."Country/Region Code", TargetLocation."Country/Region Code", 'Country/Region Code should match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationWithZones()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        TargetZone: Record Zone;
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location] [Zone]
        // [SCENARIO] Zones are copied when Zones flag is enabled.
        Initialize();

        // [GIVEN] Source location with zones.
        LibraryWarehouse.CreateFullWMSLocation(SourceLocation, 1);

        // [GIVEN] Copy location buffer with zones enabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);
        TempCopyLocationBuffer.Zones := true;

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created with zones.
        TargetLocation.Get(TargetCode);
        TargetZone.SetRange("Location Code", TargetCode);
        Assert.AreEqual(9, TargetZone.Count, '9 zones should be copied');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationWithZonesAndBins()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        SourceZone: Record Zone;
        SourceBin: Record Bin;
        TargetBin: Record Bin;
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location] [Zone] [Bin]
        // [SCENARIO] Bins are copied when both Zones and Bins flags are enabled.
        Initialize();

        // [GIVEN] Source location with zones and bins.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        LibraryWarehouse.CreateZone(SourceZone, 'ZONE1', SourceLocation.Code, '', '', '', 0, false);
        LibraryWarehouse.CreateBin(SourceBin, SourceLocation.Code, 'BIN001', SourceZone.Code, '');
        LibraryWarehouse.CreateBin(SourceBin, SourceLocation.Code, 'BIN002', SourceZone.Code, '');

        // [GIVEN] Copy location buffer with zones and bins enabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);
        TempCopyLocationBuffer.Zones := true;
        TempCopyLocationBuffer.Bins := true;

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created with bins.
        TargetLocation.Get(TargetCode);
        TargetBin.SetRange("Location Code", TargetCode);
        Assert.AreEqual(2, TargetBin.Count, 'Two bins should be copied');

        Assert.IsTrue(TargetBin.Get(TargetCode, 'BIN001'), 'BIN001 should exist');
        Assert.AreEqual(SourceZone.Code, TargetBin."Zone Code", 'Zone code should match');

        Assert.IsTrue(TargetBin.Get(TargetCode, 'BIN002'), 'BIN002 should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationBinsNotCopiedWithoutZones()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        SourceZone: Record Zone;
        SourceBin: Record Bin;
        TargetBin: Record Bin;
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location] [Zone] [Bin]
        // [SCENARIO] Bins are not copied when Zones flag is disabled, even if Bins flag is enabled.
        Initialize();

        // [GIVEN] Source location with zones and bins.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        LibraryWarehouse.CreateZone(SourceZone, 'ZONE1', SourceLocation.Code, '', '', '', 0, false);
        LibraryWarehouse.CreateBin(SourceBin, SourceLocation.Code, 'BIN001', SourceZone.Code, '');

        // [GIVEN] Copy location buffer with bins enabled but zones disabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);
        TempCopyLocationBuffer.Zones := false;
        TempCopyLocationBuffer.Bins := true;

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created without bins.
        TargetLocation.Get(TargetCode);
        TargetBin.SetRange("Location Code", TargetCode);
        Assert.AreEqual(0, TargetBin.Count, 'No bins should be copied without zones');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationWithWarehouseEmployees()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        SourceWarehouseEmployee: Record "Warehouse Employee";
        TargetWarehouseEmployee: Record "Warehouse Employee";
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
        UserId1: Code[50];
        UserId2: Code[50];
    begin
        // [FEATURE] [Copy Location] [Warehouse Employee]
        // [SCENARIO] Warehouse employees are copied when Warehouse Employees flag is enabled.
        Initialize();

        // [GIVEN] Source location with warehouse employees.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        UserId1 := CopyStr(LibraryUtility.GenerateGUID(), 1, 50);
        UserId2 := CopyStr(LibraryUtility.GenerateGUID(), 1, 50);
        CreateWarehouseEmployee(SourceWarehouseEmployee, SourceLocation.Code, UserId1, false);
        CreateWarehouseEmployee(SourceWarehouseEmployee, SourceLocation.Code, UserId2, true);

        // [GIVEN] Copy location buffer with warehouse employees enabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);
        TempCopyLocationBuffer."Warehouse Employees" := true;

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created with warehouse employees.
        TargetLocation.Get(TargetCode);
        TargetWarehouseEmployee.SetRange("Location Code", TargetCode);
        Assert.AreEqual(2, TargetWarehouseEmployee.Count, 'Two warehouse employees should be copied');

        Assert.IsTrue(TargetWarehouseEmployee.Get(UserId1, TargetCode), 'First employee should exist');
        Assert.IsTrue(TargetWarehouseEmployee.Get(UserId2, TargetCode), 'Second employee should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationWithInventoryPostingSetup()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        InventoryPostingGroup: Record "Inventory Posting Group";
        SourceInventoryPostingSetup: Record "Inventory Posting Setup";
        TargetInventoryPostingSetup: Record "Inventory Posting Setup";
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location] [Inventory Posting Setup]
        // [SCENARIO] Inventory posting setup is copied when Inventory Posting Setup flag is enabled.
        Initialize();

        // [GIVEN] Source location with inventory posting setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryInventory.CreateInventoryPostingSetup(SourceInventoryPostingSetup, SourceLocation.Code, InventoryPostingGroup.Code);

        // [GIVEN] Copy location buffer with inventory posting setup enabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);
        TempCopyLocationBuffer."Inventory Posting Setup" := true;

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created with inventory posting setup.
        TargetLocation.Get(TargetCode);
        TargetInventoryPostingSetup.SetRange("Location Code", TargetCode);
        Assert.AreNotEqual(0, TargetInventoryPostingSetup.Count, 'Inventory posting setup should be copied');

        Assert.IsTrue(TargetInventoryPostingSetup.Get(TargetCode, InventoryPostingGroup.Code), 'Inventory posting setup should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationWithDimensions()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        DimensionValue: Record "Dimension Value";
        SourceDefaultDimension: Record "Default Dimension";
        TargetDefaultDimension: Record "Default Dimension";
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
        DimensionCode: Code[20];
    begin
        // [FEATURE] [Copy Location] [Dimension]
        // [SCENARIO] Dimensions are copied when Dimensions flag is enabled.
        Initialize();

        // [GIVEN] Source location with dimensions.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionCode := DimensionValue."Dimension Code";
        LibraryDimension.CreateDefaultDimension(SourceDefaultDimension, Database::Location, SourceLocation.Code, DimensionCode, DimensionValue.Code);
        SourceDefaultDimension."Table ID" := Database::Location;
        SourceDefaultDimension."No." := SourceLocation.Code;
        SourceDefaultDimension.Modify(true);

        // [GIVEN] Copy location buffer with dimensions enabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);
        TempCopyLocationBuffer.Dimensions := true;

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created with dimensions.
        TargetLocation.Get(TargetCode);
        TargetDefaultDimension.SetRange("Table ID", Database::Location);
        TargetDefaultDimension.SetRange("No.", TargetCode);
        Assert.AreEqual(1, TargetDefaultDimension.Count, 'One dimension should be copied');

        TargetDefaultDimension.Get(Database::Location, TargetCode, DimensionCode);
        Assert.AreEqual(DimensionValue.Code, TargetDefaultDimension."Dimension Value Code", 'Dimension value should match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationWithTransferRoutes()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        OtherLocation: Record Location;
        SourceTransferRoute: Record "Transfer Route";
        TargetTransferRoute: Record "Transfer Route";
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location] [Transfer Route]
        // [SCENARIO] Transfer routes are copied when Transfer Routes flag is enabled.
        Initialize();

        // [GIVEN] Source location with transfer routes.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(OtherLocation);
        LibraryWarehouse.CreateTransferRoute(SourceTransferRoute, SourceLocation.Code, OtherLocation.Code);
        LibraryWarehouse.CreateTransferRoute(SourceTransferRoute, OtherLocation.Code, SourceLocation.Code);

        // [GIVEN] Copy location buffer with transfer routes enabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);
        TempCopyLocationBuffer."Transfer Routes" := true;

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created with transfer routes.
        TargetLocation.Get(TargetCode);
        TargetTransferRoute.SetFilter("Transfer-from Code", '%1|%2', TargetCode, OtherLocation.Code);
        TargetTransferRoute.SetFilter("Transfer-to Code", '%1|%2', TargetCode, OtherLocation.Code);
        Assert.AreNotEqual(0, TargetTransferRoute.Count, 'Transfer routes should be copied');

        Assert.IsTrue(TargetTransferRoute.Get(TargetCode, OtherLocation.Code), 'Transfer route from target to other should exist');
        Assert.IsTrue(TargetTransferRoute.Get(OtherLocation.Code, TargetCode), 'Transfer route from other to target should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationErrorWhenTargetCodeEmpty()
    var
        SourceLocation: Record Location;
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
    begin
        // [FEATURE] [Copy Location]
        // [SCENARIO] Error is raised when target location code is empty.
        Initialize();

        // [GIVEN] Source location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);

        // [GIVEN] Copy location buffer with empty target code.
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, '');

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        asserterror CopyLocation.DoCopyLocation();

        // [THEN] Error is raised about empty target code.
        Assert.ExpectedError(TargetLocationCodeEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationErrorWhenTargetAlreadyExists()
    var
        SourceLocation: Record Location;
        ExistingLocation: Record Location;
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
    begin
        // [FEATURE] [Copy Location]
        // [SCENARIO] Error is raised when target location code already exists.
        Initialize();

        // [GIVEN] Source location and existing target location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ExistingLocation);

        // [GIVEN] Copy location buffer with existing target code.
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, ExistingLocation.Code);

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        asserterror CopyLocation.DoCopyLocation();

        // [THEN] Error is raised about existing location.
        Assert.ExpectedError(StrSubstNo(TargetLocationAlreadyExistsErr, ExistingLocation.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationGetNewLocationCode()
    var
        SourceLocation: Record Location;
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location]
        // [SCENARIO] GetNewLocationCode returns the newly created location code.
        Initialize();

        // [GIVEN] Source location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);

        // [GIVEN] Copy location buffer with target code.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] GetNewLocationCode returns the target code.
        Assert.AreEqual(TargetCode, CopyLocation.GetNewLocationCode(), 'New location code should match target code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationTransferRoutesBothDirections()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        SourceTransferRoute: Record "Transfer Route";
        TargetTransferRoute: Record "Transfer Route";
        TempCopyLocationBuffer: Record "Copy Location Buffer" temporary;
        CopyLocation: Codeunit "Copy Location";
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location] [Transfer Route]
        // [SCENARIO] Transfer routes are copied with both source as from and to location.
        Initialize();

        // [GIVEN] Source location with transfer route to itself.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        LibraryWarehouse.CreateTransferRoute(SourceTransferRoute, SourceLocation.Code, SourceLocation.Code);

        // [GIVEN] Copy location buffer with transfer routes enabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        PrepareCopyLocationBuffer(TempCopyLocationBuffer, SourceLocation.Code, TargetCode);
        TempCopyLocationBuffer."Transfer Routes" := true;

        // [WHEN] Copy location is executed.
        CopyLocation.SetCopyLocationBuffer(TempCopyLocationBuffer);
        CopyLocation.DoCopyLocation();

        // [THEN] Target location is created with self-referencing transfer route.
        TargetLocation.Get(TargetCode);
        Assert.IsTrue(TargetTransferRoute.Get(TargetCode, TargetCode), 'Self-referencing transfer route should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationFromLocationCard()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location]
        // [SCENARIO] Copy Location can be triggered from Location Card action.
        Initialize();

        // [GIVEN] Source location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        SourceLocation.Name := 'Source Location';
        SourceLocation.Modify(true);

        // [GIVEN] Subscribe to OnBeforeOnRun event to bypass page and set parameters.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        BindSubscription(CopyLocationTestSubscriber);
        CopyLocationTestSubscriber.SetTargetLocationCode(TargetCode);

        // [WHEN] Copy Location is triggered from Location Card (simulated by CODEUNIT.Run).
        CODEUNIT.Run(CODEUNIT::"Copy Location", SourceLocation);

        // [THEN] Target location is created.
        TargetLocation.Get(TargetCode);
        Assert.AreEqual(SourceLocation.Name, TargetLocation.Name, 'Location should be copied');

        UnbindSubscription(CopyLocationTestSubscriber);
        LibraryNotificationMgt.RecallNotificationsForRecord(SourceLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyLocationFromLocationCardWithAllOptions()
    var
        SourceLocation: Record Location;
        TargetLocation: Record Location;
        SourceZone: Record Zone;
        TargetZone: Record Zone;
        TargetCode: Code[10];
    begin
        // [FEATURE] [Copy Location]
        // [SCENARIO] Copy Location from Location Card copies all selected options.
        Initialize();

        // [GIVEN] Source location with zones.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        LibraryWarehouse.CreateZone(SourceZone, 'ZONE1', SourceLocation.Code, '', '', '', 0, false);

        // [GIVEN] Subscribe to OnBeforeOnRun event with all options enabled.
        TargetCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 10);
        BindSubscription(CopyLocationTestSubscriber);
        CopyLocationTestSubscriber.SetTargetLocationCode(TargetCode);
        CopyLocationTestSubscriber.SetCopyAllOptions(true);

        // [WHEN] Copy Location is triggered from Location Card.
        CODEUNIT.Run(CODEUNIT::"Copy Location", SourceLocation);

        // [THEN] Target location is created with all options.
        TargetLocation.Get(TargetCode);
        TargetZone.SetRange("Location Code", TargetCode);
        Assert.AreEqual(1, TargetZone.Count, 'Zones should be copied');

        UnbindSubscription(CopyLocationTestSubscriber);
        LibraryNotificationMgt.RecallNotificationsForRecord(SourceLocation);
    end;

    local procedure CreateWarehouseEmployee(var WarehouseEmployee: Record "Warehouse Employee"; LocationCode: Code[10]; UserId: Code[50]; IsDefault: Boolean)
    begin
        WarehouseEmployee.Init();
        WarehouseEmployee."User ID" := UserId;
        WarehouseEmployee."Location Code" := LocationCode;
        WarehouseEmployee.Default := IsDefault;
        WarehouseEmployee.Insert(true);
    end;

    local procedure PrepareCopyLocationBuffer(var CopyLocationBuffer: Record "Copy Location Buffer" temporary; SourceCode: Code[10]; TargetCode: Code[10])
    begin
        CopyLocationBuffer.Init();
        CopyLocationBuffer."Source Location Code" := SourceCode;
        CopyLocationBuffer."Target Location Code" := TargetCode;
        CopyLocationBuffer.Zones := false;
        CopyLocationBuffer.Bins := false;
        CopyLocationBuffer."Warehouse Employees" := false;
        CopyLocationBuffer."Inventory Posting Setup" := false;
        CopyLocationBuffer.Dimensions := false;
        CopyLocationBuffer."Transfer Routes" := false;
        CopyLocationBuffer.Insert();
    end;
}
