// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Utilities;
using System.Environment.Configuration;

codeunit 137439 "Prod. Order Refresh Location"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Refresh] [Location]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;

    [Test]
    procedure RefreshPopulatedLocationWithoutWarning()
    var
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // [SCENARIO] An order with a location refreshes without a blank-location warning.
        Initialize();
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
        Initialize();
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
        Initialize();
        // [GIVEN] A blank-location order.
        CreateOrderForRefresh(ProductionOrder);
        // [WHEN] Refresh is called with validation dialogs hidden.
        RunRefresh(ProductionOrder, true);
        // [THEN] Lines are created without displaying the warning.
        VerifyRefreshed(ProductionOrder, true);
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

    local procedure RunRefresh(ProductionOrder: Record "Production Order"; HideDialogs: Boolean)
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

    local procedure Initialize()
    var
        MyNotifications: Record "My Notifications";
        Fixture: Codeunit "SCM Production Orders";
        InstructionMgt: Codeunit "Instruction Mgt.";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Order Refresh Location");
        LibrarySetupStorage.Restore();
        if not IsInitialized then begin
            LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Order Refresh Location");
            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.UpdateGeneralPostingSetup();
            LibrarySetupStorage.SaveInventorySetup();
            LibrarySetupStorage.SaveManufacturingSetup();
            IsInitialized := true;
            Commit();
            LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Order Refresh Location");
        end;
        Fixture.ConfigureDefaultLocation('', '');
        InstructionMgt.EnableMessageForCurrentUser(InstructionMgt.RefreshBlankLocationCode());
        InstructionMgt.CreateMissingMyNotificationsWithDefaultState(InstructionMgt.GetRefreshBlankLocationNotificationId());
        MyNotifications.SetStatus(InstructionMgt.GetRefreshBlankLocationNotificationId(), true);
    end;
}
