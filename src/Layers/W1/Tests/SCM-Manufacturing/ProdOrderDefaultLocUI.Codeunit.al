// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 137438 "Prod. Order Default Loc. UI"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Default Location] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        ManufacturingSetupOpened: Boolean;

    [Test]
    procedure DefaultLocationReleasedCard()
    var
        Location: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
        Fixture: Codeunit "SCM Production Orders";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] A new released order shows the setup location before the user enters any fields.
        Initialize();
        // [GIVEN] A default manufacturing location and a released-order number series.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Fixture.ConfigureDefaultLocation(Location.Code, '');
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Released Order Nos."));
        // [WHEN] A user opens a new released production order.
        ReleasedProductionOrder.OpenNew();
        // [THEN] The location is defaulted before the user supplies any fields.
        ReleasedProductionOrder."Location Code".AssertEquals(Location.Code);
        ReleasedProductionOrder.Close();
        LibrarySetupStorage.Restore();
    end;

    [Test]
    procedure DefaultLocationReleasedCardSaved()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ManufacturingSetup: Record "Manufacturing Setup";
        Fixture: Codeunit "SCM Production Orders";
        ReleasedProductionOrder: TestPage "Released Production Order";
        OrderNo: Code[20];
    begin
        // [SCENARIO] Saving a new released order retains its default location.
        Initialize();
        // [GIVEN] A new released order with a default manufacturing location and an item.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Fixture.ConfigureDefaultLocation(Location.Code, '');
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Released Order Nos."));
        ReleasedProductionOrder.OpenNew();
        // [WHEN] The user enters an item and quantity and saves the order.
        ReleasedProductionOrder."Source No.".SetValue(Item."No.");
        ReleasedProductionOrder.Quantity.SetValue(2);
        OrderNo := CopyStr(ReleasedProductionOrder."No.".Value(), 1, MaxStrLen(OrderNo));
        ReleasedProductionOrder.Close();
        // [THEN] The saved order retains the location and quantity.
        ProductionOrder.Get(ProductionOrder.Status::Released, OrderNo);
        ProductionOrder.TestField("Location Code", Location.Code);
        ProductionOrder.TestField(Quantity, 2);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    procedure DefaultLocationCardOverride()
    var
        Item: Record Item;
        DefaultLocation: Record Location;
        OtherLocation: Record Location;
        ProductionOrder: Record "Production Order";
        ManufacturingSetup: Record "Manufacturing Setup";
        Fixture: Codeunit "SCM Production Orders";
        ReleasedProductionOrder: TestPage "Released Production Order";
        LocationCode: Code[10];
        OrderNo: Code[20];
        Iteration: Integer;
    begin
        // [SCENARIO] Saving source entry preserves a user's cleared or replacement location.
        Initialize();
        // [GIVEN] A default location, an alternative location and an item.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(DefaultLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(OtherLocation);
        Fixture.ConfigureDefaultLocation(DefaultLocation.Code, '');
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Released Order Nos."));
        for Iteration := 1 to 2 do begin
            LocationCode := '';
            if Iteration = 2 then
                LocationCode := OtherLocation.Code;
            ReleasedProductionOrder.OpenNew();
            ReleasedProductionOrder."Location Code".AssertEquals(DefaultLocation.Code);
            // [WHEN] The user saves the order after overriding the location and entering the item.
            ReleasedProductionOrder."Location Code".SetValue(LocationCode);
            ReleasedProductionOrder."Source No.".SetValue(Item."No.");
            ReleasedProductionOrder.Quantity.SetValue(2);
            OrderNo := CopyStr(ReleasedProductionOrder."No.".Value(), 1, MaxStrLen(OrderNo));
            ReleasedProductionOrder.Close();
            // [THEN] The saved order respects the user's location and item.
            ProductionOrder.Get(ProductionOrder.Status::Released, OrderNo);
            ProductionOrder.TestField("Location Code", LocationCode);
            ProductionOrder.TestField("Source No.", Item."No.");
        end;
        LibrarySetupStorage.Restore();
    end;

    [Test]
    procedure DefaultLocationCardOverrideReopened()
    var
        Item: Record Item;
        DefaultLocation: Record Location;
        OtherLocation: Record Location;
        ProductionOrder: Record "Production Order";
        ManufacturingSetup: Record "Manufacturing Setup";
        Fixture: Codeunit "SCM Production Orders";
        ReleasedProductionOrder: TestPage "Released Production Order";
        LocationCode: Code[10];
        OrderNo: Code[20];
        Iteration: Integer;
    begin
        // [SCENARIO] Reopening an existing order does not replace a user's saved blank or explicit location.
        Initialize();
        // [GIVEN] Orders saved through the card with the default cleared or replaced and an item entered.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(DefaultLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(OtherLocation);
        Fixture.ConfigureDefaultLocation(DefaultLocation.Code, '');
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Released Order Nos."));
        for Iteration := 1 to 2 do begin
            LocationCode := '';
            if Iteration = 2 then
                LocationCode := OtherLocation.Code;
            ReleasedProductionOrder.OpenNew();
            ReleasedProductionOrder."Location Code".SetValue(LocationCode);
            ReleasedProductionOrder."Source No.".SetValue(Item."No.");
            ReleasedProductionOrder.Quantity.SetValue(2);
            OrderNo := CopyStr(ReleasedProductionOrder."No.".Value(), 1, MaxStrLen(OrderNo));
            ReleasedProductionOrder.Close();
            ProductionOrder.Get(ProductionOrder.Status::Released, OrderNo);
            // [WHEN] The user reopens the existing order.
            ReleasedProductionOrder.OpenEdit();
            ReleasedProductionOrder.GoToRecord(ProductionOrder);
            // [THEN] The setup default is not applied again.
            ReleasedProductionOrder."Location Code".AssertEquals(LocationCode);
            ReleasedProductionOrder."Source No.".AssertEquals(Item."No.");
            ReleasedProductionOrder.Close();
        end;
        LibrarySetupStorage.Restore();
    end;

    [Test]
    procedure DefaultLocationOtherInitialStatuses()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ManufacturingSetup: Record "Manufacturing Setup";
        Fixture: Codeunit "SCM Production Orders";
        SimulatedProductionOrder: TestPage "Simulated Production Order";
        PlannedProductionOrder: TestPage "Planned Production Order";
        FirmPlannedProductionOrder: TestPage "Firm Planned Prod. Order";
        OrderStatus: Enum "Production Order Status";
        OrderNo: Code[20];
        StatusIndex: Integer;
    begin
        // [SCENARIO] Simulated, planned and firm planned cards default the location on new orders.
        Initialize();
        // [GIVEN] A default manufacturing location and number series for all three statuses.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Fixture.ConfigureDefaultLocation(Location.Code, '');
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Simulated Order Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Planned Order Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Firm Planned Order Nos."));
        for StatusIndex := 0 to 2 do begin
            OrderStatus := Enum::"Production Order Status".FromInteger(StatusIndex);
            // [WHEN] A new order is opened in each card and populated with an item and quantity.
            case OrderStatus of
                OrderStatus::Simulated:
                    begin
                        SimulatedProductionOrder.OpenNew();
                        SimulatedProductionOrder."Location Code".AssertEquals(Location.Code);
                        SimulatedProductionOrder."Source No.".SetValue(Item."No.");
                        SimulatedProductionOrder.Quantity.SetValue(2);
                        OrderNo := CopyStr(SimulatedProductionOrder."No.".Value(), 1, MaxStrLen(OrderNo));
                        SimulatedProductionOrder.Close();
                    end;
                OrderStatus::Planned:
                    begin
                        PlannedProductionOrder.OpenNew();
                        PlannedProductionOrder."Location Code".AssertEquals(Location.Code);
                        PlannedProductionOrder."Source No.".SetValue(Item."No.");
                        PlannedProductionOrder.Quantity.SetValue(2);
                        OrderNo := CopyStr(PlannedProductionOrder."No.".Value(), 1, MaxStrLen(OrderNo));
                        PlannedProductionOrder.Close();
                    end;
                OrderStatus::"Firm Planned":
                    begin
                        FirmPlannedProductionOrder.OpenNew();
                        FirmPlannedProductionOrder."Location Code".AssertEquals(Location.Code);
                        FirmPlannedProductionOrder."Source No.".SetValue(Item."No.");
                        FirmPlannedProductionOrder.Quantity.SetValue(2);
                        OrderNo := CopyStr(FirmPlannedProductionOrder."No.".Value(), 1, MaxStrLen(OrderNo));
                        FirmPlannedProductionOrder.Close();
                    end;
            end;
            // [THEN] Each saved order retains the setup location and entered quantity.
            ProductionOrder.Get(OrderStatus, OrderNo);
            ProductionOrder.TestField("Location Code", Location.Code);
            ProductionOrder.TestField(Quantity, 2);
        end;
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [HandlerFunctions('RefreshLocationWarningHandler')]
    procedure RefreshBlankLocationAccepted()
    var
        ProductionOrder: Record "Production Order";
        Location: Record Location;
        Fixture: Codeunit "SCM Production Orders";
    begin
        // [SCENARIO] Accepting the warning refreshes an intentionally blank order without applying the setup default.
        InitializeRefreshWarning();
        // [GIVEN] A blank-location order and a configured default location.
        CreateOrderForRefresh(ProductionOrder);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Fixture.ConfigureDefaultLocation(Location.Code, '');
        EnqueueRefreshWarning(ProductionOrder, false, 'Continue');
        // [WHEN] The user chooses to continue.
        RunRefresh(ProductionOrder, false);
        // [THEN] A line is created without changing the order's blank location.
        VerifyRefreshed(ProductionOrder, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RefreshLocationWarningHandler')]
    procedure RefreshBlankLocationDeclinedInBatch()
    var
        FirstOrder: Record "Production Order";
        SecondOrder: Record "Production Order";
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Declining one blank-location order does not prevent another selected order from refreshing.
        InitializeRefreshWarning();
        // [GIVEN] Two blank-location orders and no manufacturing default.
        CreateOrderForRefresh(FirstOrder);
        CreateOrderForRefresh(SecondOrder);
        EnqueueRefreshWarning(FirstOrder, true, 'Skip');
        EnqueueRefreshWarning(SecondOrder, true, 'Continue');
        ProductionOrder.SetRange(Status, FirstOrder.Status);
        ProductionOrder.SetFilter("No.", '%1|%2', FirstOrder."No.", SecondOrder."No.");
        // [WHEN] The user declines the first order and accepts the second.
        RunRefresh(ProductionOrder, false);
        // [THEN] Only the accepted order has refreshed lines.
        VerifyRefreshed(FirstOrder, false);
        VerifyRefreshed(SecondOrder, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure RefreshBlankLocationWarningDisabled()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Disabling the refresh warning in My Notifications suppresses the dialog.
        InitializeRefreshWarning();
        // [GIVEN] The user has disabled the warning in My Notifications.
        SetRefreshWarningEnabled(false);
        CreateOrderForRefresh(ProductionOrder);
        // [WHEN] A blank-location order is refreshed with the warning disabled.
        RunRefresh(ProductionOrder, false);
        // [THEN] Refresh proceeds without a dialog.
        VerifyRefreshed(ProductionOrder, true);
    end;

    [Test]
    [HandlerFunctions('RefreshLocationWarningHandler')]
    procedure RefreshBlankLocationWarningReenabled()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Re-enabling a disabled refresh warning restores the dialog.
        InitializeRefreshWarning();
        // [GIVEN] The user disables and re-enables the warning in My Notifications.
        SetRefreshWarningEnabled(false);
        SetRefreshWarningEnabled(true);
        CreateOrderForRefresh(ProductionOrder);
        EnqueueRefreshWarning(ProductionOrder, true, 'Skip');
        // [WHEN] A blank-location order is refreshed and the warning is declined.
        RunRefresh(ProductionOrder, false);
        // [THEN] The warning is shown again and the order is not refreshed.
        VerifyRefreshed(ProductionOrder, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure RefreshPopulatedLocationWithoutWarning()
    var
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // [SCENARIO] An order with a location refreshes without a blank-location warning.
        InitializeRefreshWarning();
        // [GIVEN] An order with an explicit location.
        CreateOrderForRefresh(ProductionOrder);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        // [WHEN] The order is refreshed.
        RunRefresh(ProductionOrder, false);
        // [THEN] Lines are created and the location is retained without prompting.
        VerifyRefreshed(ProductionOrder, true);
    end;

    [Test]
    procedure RefreshLocationWarningHonorsSelectionFilters()
    var
        SelectedOrder: Record "Production Order";
        UnselectedOrder: Record "Production Order";
        OtherStatusOrder: Record "Production Order";
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // [SCENARIO] Warning preflight does not prompt for orders outside the report's status or location filters.
        InitializeRefreshWarning();
        // [GIVEN] A selected order with a location and blank-location orders excluded by status or location.
        CreateOrderForRefresh(SelectedOrder);
        CreateOrderForRefresh(UnselectedOrder);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SelectedOrder.Validate("Location Code", Location.Code);
        SelectedOrder.Modify(true);
        OtherStatusOrder := SelectedOrder;
        OtherStatusOrder.Status := OtherStatusOrder.Status::Planned;
        OtherStatusOrder."Location Code" := '';
        OtherStatusOrder.Insert();
        ProductionOrder.SetRange(Status, SelectedOrder.Status);
        ProductionOrder.SetRange("Location Code", Location.Code);
        ProductionOrder.SetFilter("No.", '%1|%2', SelectedOrder."No.", UnselectedOrder."No.");
        // [WHEN] Only the populated-location order is selected for refresh.
        RunRefresh(ProductionOrder, false);
        // [THEN] Only that order refreshes and no warning is shown for excluded orders.
        VerifyRefreshed(SelectedOrder, true);
        VerifyRefreshed(UnselectedOrder, false);
        VerifyRefreshed(OtherStatusOrder, false);
    end;

    [Test]
    procedure RefreshBlankLocationWithDialogsHidden()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Callers hiding validation dialogs can refresh blank-location orders without interaction.
        InitializeRefreshWarning();
        // [GIVEN] A blank-location order.
        CreateOrderForRefresh(ProductionOrder);
        // [WHEN] Refresh is called with validation dialogs hidden.
        RunRefresh(ProductionOrder, true);
        // [THEN] Lines are created without displaying the warning.
        VerifyRefreshed(ProductionOrder, true);
    end;

    [Test]
    [HandlerFunctions('RefreshLocationWarningHandler,ManufacturingSetupHandler')]
    procedure RefreshOpenSetupStopsEntireBatch()
    var
        FirstOrder: Record "Production Order";
        SecondOrder: Record "Production Order";
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Opening setup from a warning stops the entire refresh before any selected order is changed.
        InitializeRefreshWarning();
        // [GIVEN] Two blank-location orders and no manufacturing default.
        CreateOrderForRefresh(FirstOrder);
        CreateOrderForRefresh(SecondOrder);
        EnqueueRefreshWarning(FirstOrder, true, 'Continue');
        EnqueueRefreshWarning(SecondOrder, true, 'Setup');
        ProductionOrder.SetRange(Status, FirstOrder.Status);
        ProductionOrder.SetFilter("No.", '%1|%2', FirstOrder."No.", SecondOrder."No.");
        // [WHEN] The user accepts the first warning but opens setup from the second.
        RunRefresh(ProductionOrder, false);
        // [THEN] Setup opens and neither order has refreshed lines.
        Assert.IsTrue(ManufacturingSetupOpened, 'Manufacturing Setup must open from the warning.');
        VerifyRefreshed(FirstOrder, false);
        VerifyRefreshed(SecondOrder, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure InitializeRefreshWarning()
    var
        MyNotifications: Record "My Notifications";
        Fixture: Codeunit "SCM Production Orders";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        Initialize();
        LibraryVariableStorage.Clear();
        ManufacturingSetupOpened := false;
        Fixture.ConfigureDefaultLocation('', '');
        InstructionMgt.EnableMessageForCurrentUser(InstructionMgt.RefreshBlankLocationCode());
        InstructionMgt.CreateMissingMyNotificationsWithDefaultState(InstructionMgt.GetRefreshBlankLocationNotificationId());
        MyNotifications.SetStatus(InstructionMgt.GetRefreshBlankLocationNotificationId(), true);
    end;

    local procedure SetRefreshWarningEnabled(Enabled: Boolean)
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        MyNotifications: TestPage "My Notifications";
    begin
        MyNotifications.OpenEdit();
        MyNotifications.Filter.SetFilter("Notification Id", InstructionMgt.GetRefreshBlankLocationNotificationId());
        MyNotifications.Enabled.SetValue(Enabled);
        MyNotifications.Close();
        Assert.AreEqual(
            Enabled, InstructionMgt.IsEnabled(InstructionMgt.RefreshBlankLocationCode()),
            'The notification setting must update the refresh warning preference.');
    end;

    local procedure CreateOrderForRefresh(var ProductionOrder: Record "Production Order")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.", 1);
        ProductionOrder.Validate("Location Code", '');
        ProductionOrder.Modify(true);
    end;

    local procedure EnqueueRefreshWarning(ProductionOrder: Record "Production Order"; SetupMissing: Boolean; Choice: Text)
    begin
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(SetupMissing);
        LibraryVariableStorage.Enqueue(Choice);
    end;

    local procedure RunRefresh(var ProductionOrder: Record "Production Order"; HideDialogs: Boolean)
    var
        OrderFilter: Record "Production Order";
        RefreshProductionOrder: Report "Refresh Production Order";
    begin
        if ProductionOrder.HasFilter() then
            OrderFilter.CopyFilters(ProductionOrder)
        else begin
            OrderFilter.SetRange(Status, ProductionOrder.Status);
            OrderFilter.SetRange("No.", ProductionOrder."No.");
        end;
        Commit();
        RefreshProductionOrder.SetTableView(OrderFilter);
        RefreshProductionOrder.InitializeRequest(1, true, true, true, false);
        RefreshProductionOrder.SetHideValidationDialog(HideDialogs);
        RefreshProductionOrder.UseRequestPage(false);
        RefreshProductionOrder.RunModal();
    end;

    local procedure VerifyRefreshed(ProductionOrder: Record "Production Order"; ExpectedRefreshed: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        LocationCode: Code[10];
    begin
        LocationCode := ProductionOrder."Location Code";
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder.TestField("Location Code", LocationCode);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(ExpectedRefreshed, not ProdOrderLine.IsEmpty(), 'Unexpected refresh result.');
        if ExpectedRefreshed then begin
            ProdOrderLine.FindFirst();
            ProdOrderLine.TestField("Location Code", LocationCode);
        end;
    end;

    [ModalPageHandler]
    procedure RefreshLocationWarningHandler(var Warning: TestPage "Refresh Prod. Order Warning")
    var
        Choice: Text;
    begin
        Warning."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(
            LibraryVariableStorage.DequeueBoolean(), Warning.OpenManufacturingSetup.Visible(),
            'The setup link must only be available when no manufacturing default is configured.');
        Assert.AreEqual(
            Warning.OpenManufacturingSetup.Visible(), Warning.SetupInstructions.Visible(),
            'The setup instructions and setup link must be shown together.');
        Choice := LibraryVariableStorage.DequeueText();
        case Choice of
            'Continue':
                Warning.Yes().Invoke();
            'Skip':
                Warning.No().Invoke();
            'Setup':
                begin
                    // Closing a page from a drilldown also closes its TestPage.
                    asserterror Warning.OpenManufacturingSetup.Drilldown();
                    Assert.ExpectedError('The TestPage is not open.');
                end;
        end;
    end;

    [PageHandler]
    procedure ManufacturingSetupHandler(var ManufacturingSetup: TestPage "Manufacturing Setup")
    begin
        ManufacturingSetupOpened := true;
        ManufacturingSetup.Close();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Order Default Loc. UI");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Order Default Loc. UI");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveInventorySetup();
        LibrarySetupStorage.SaveManufacturingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Order Default Loc. UI");
    end;
}
