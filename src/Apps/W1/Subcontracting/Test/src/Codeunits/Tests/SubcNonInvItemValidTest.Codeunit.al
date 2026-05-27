// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Subcontracting;

codeunit 149916 "Subc. Non-Inv Item Valid. Test"
{
    // [FEATURE] Subcontracting Type Transfer validation for Non-Inventory items
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure NonInventoryItemCannotBeSetToTransferOnProdBOMLine()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        // [SCENARIO 624295] Setting Subcontracting Type = Transfer on a Production BOM Line with a Non-Inventory item must raise an error.

        // [GIVEN] A Non-Inventory item and a Production BOM with a line for that item
        CreateNonInventoryItem(Item);
        CreateProductionBOMWithItem(ProductionBOMHeader, ProductionBOMLine, Item);

        // [WHEN] Setting Subcontracting Type to Transfer on the BOM line
        asserterror ProductionBOMLine.Validate("Subcontracting Type", "Subcontracting Type"::Transfer);

        // [THEN] An error is raised indicating the item type must be Inventory
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Type must be equal to');
    end;

    [Test]
    procedure InventoryItemCanBeSetToTransferOnProdBOMLine()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        // [SCENARIO 624295] Setting Subcontracting Type = Transfer on a Production BOM Line with an Inventory item must succeed.

        // [GIVEN] An Inventory item and a Production BOM with a line for that item
        CreateInventoryItem(Item);
        CreateProductionBOMWithItem(ProductionBOMHeader, ProductionBOMLine, Item);

        // [WHEN] Setting Subcontracting Type to Transfer on the BOM line
        ProductionBOMLine.Validate("Subcontracting Type", "Subcontracting Type"::Transfer);

        // [THEN] No error is raised
        Assert.AreEqual("Subcontracting Type"::Transfer, ProductionBOMLine."Subcontracting Type", 'Subcontracting Type should be Transfer');
    end;

    [Test]
    procedure NonInventoryItemCannotBeSetToTransferOnProdOrderComponent()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
    begin
        // [SCENARIO 624295] Setting Subcontracting Type = Transfer on a Prod. Order Component with a Non-Inventory item must raise an error.

        // [GIVEN] A Non-Inventory item and a Prod. Order Component for that item
        CreateNonInventoryItem(Item);
        CreateProdOrderComponent(ProdOrderComponent, Item);

        // [WHEN] Setting Subcontracting Type to Transfer on the component
        asserterror ProdOrderComponent.Validate("Subcontracting Type", "Subcontracting Type"::Transfer);

        // [THEN] An error is raised indicating the item type must be Inventory
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Type must be equal to');
    end;

    [Test]
    procedure NonInventoryItemCanBeSetToPurchaseOnProdBOMLine()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        // [SCENARIO 624295] Setting Subcontracting Type = Purchase on a Production BOM Line with a Non-Inventory item must succeed (only Transfer is blocked).

        // [GIVEN] A Non-Inventory item and a Production BOM with a line for that item
        CreateNonInventoryItem(Item);
        CreateProductionBOMWithItem(ProductionBOMHeader, ProductionBOMLine, Item);

        // [WHEN] Setting Subcontracting Type to Purchase on the BOM line
        ProductionBOMLine.Validate("Subcontracting Type", "Subcontracting Type"::Purchase);

        // [THEN] No error is raised
        Assert.AreEqual("Subcontracting Type"::Purchase, ProductionBOMLine."Subcontracting Type", 'Subcontracting Type should be Purchase');
    end;

    local procedure CreateNonInventoryItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
    end;

    local procedure CreateInventoryItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreateProductionBOMWithItem(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; Item: Record Item)
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Item: Record Item)
    var
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ParentItem: Record Item;
    begin
        LibraryInventory.CreateItem(ParentItem);
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", 1);
        LibraryManufacturing.CreateProdOrderLine(ProductionOrderLine, ProductionOrder.Status, ProductionOrder."No.", ParentItem."No.", '', '', 1);

        ProdOrderComponent.Init();
        ProdOrderComponent.Status := ProductionOrder.Status;
        ProdOrderComponent."Prod. Order No." := ProductionOrder."No.";
        ProdOrderComponent."Prod. Order Line No." := ProductionOrderLine."Line No.";
        ProdOrderComponent."Line No." := 10000;
        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Insert(true);
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
}
