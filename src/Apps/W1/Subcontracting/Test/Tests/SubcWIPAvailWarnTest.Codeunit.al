// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;

codeunit 149912 "Subc. WIP Avail. Warn Test"
{
    // [FEATURE] WIP Item Transfer for Subcontracting
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure AvailabilityCheckNotPerformedForWIPTransferLineQuantityEdit()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        NewQuantity: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 638688] Editing Quantity on a "Transfer WIP Item" line through the Transfer Order page
        // must NOT run the standard item-availability check, because WIP items are intermediate
        // subcontracting goods that standard inventory availability does not apply to.
        Initialize();

        // [GIVEN] From, To and In-Transit locations, and an item with NO inventory at the From location
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A Transfer Order with a "Transfer WIP Item" line (initial quantity 1)
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, 1);
        Commit();

        // [WHEN] The Quantity is increased on the WIP line through the Transfer Order page (sets CurrFieldNo)
        NewQuantity := 10;
        AvailCheckSpy.Reset();
        SetQuantityOnTransferOrderPage(TransferOrder, TransferHeader, TransferLine, NewQuantity);

        // [THEN] The Quantity is persisted and the item-availability warning check was NOT performed for the WIP item
        TransferLine.Find('=');
        Assert.AreEqual(NewQuantity, TransferLine.Quantity, 'Quantity should be updated on the WIP transfer line.');
        Assert.IsFalse(
            AvailCheckSpy.WasInvokedForItem(Item."No."),
            'The item-availability warning check must not run for a Transfer WIP Item line.');
    end;

    [Test]
    procedure AvailabilityCheckPerformedForNonWIPTransferLineQuantityEdit()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        NewQuantity: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 638688] Control test: editing Quantity on a normal (non-WIP) transfer line through the
        // Transfer Order page DOES run the standard item-availability check. This guards the spy mechanism
        // and proves the WIP suppression is specific to WIP lines.
        Initialize();

        // [GIVEN] From, To and In-Transit locations, and an item with NO inventory at the From location
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A Transfer Order with a normal (non-WIP) line (initial quantity 1)
        CreateNonWIPTransferOrder(TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, 1);
        Commit();

        // [WHEN] The Quantity is increased on the line through the Transfer Order page (sets CurrFieldNo)
        NewQuantity := 10;
        AvailCheckSpy.Reset();
        SetQuantityOnTransferOrderPage(TransferOrder, TransferHeader, TransferLine, NewQuantity);

        // [THEN] The item-availability warning check WAS performed for the normal item
        TransferLine.Find('=');
        Assert.AreEqual(NewQuantity, TransferLine.Quantity, 'Quantity should be updated on the transfer line.');
        Assert.IsTrue(
            AvailCheckSpy.WasInvokedForItem(Item."No."),
            'The item-availability warning check should run for a normal (non-WIP) transfer line.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. WIP Avail. Warn Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. WIP Avail. Warn Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. WIP Avail. Warn Test");
    end;

    local procedure SetQuantityOnTransferOrderPage(var TransferOrder: TestPage "Transfer Order"; TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line"; NewQuantity: Decimal)
    begin
        TransferOrder.OpenEdit();
        TransferOrder.GoToRecord(TransferHeader);
        TransferOrder.TransferLines.GoToRecord(TransferLine);
        TransferOrder.TransferLines.Quantity.SetValue(NewQuantity);
        TransferOrder.Close();
    end;

    local procedure CreateNonWIPTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocation: Code[10]; ToLocation: Code[10]; InTransitCode: Code[10]; Item: Record Item; Quantity: Decimal)
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, FromLocation, ToLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, InTransitCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Quantity);
    end;

    var
        Assert: Codeunit Assert;
        AvailCheckSpy: Codeunit "Subc. Avail. Check Spy";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
}
