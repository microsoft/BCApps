// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;

codeunit 137039 "SCM Manuf Low Level Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Item] [Low-Level Code] [SCM]
    end;

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithLowLevelCodeZero()
    var
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ItemNo: array[20] of Code[20];
    begin
        // Setup: Dynamic Low-Level Code set to true in Manufacturing setup.
        Initialize();
        UpdateManufacturingSetup(TempManufacturingSetup, true);

        // Exercise: Create Item.
        CreateItems(ItemNo);

        // Verify: Verify Low Level code in all the Items must be zero.
        VerifyLowLevelCode(ItemNo[1], ItemNo[6], 0);

        // Tear Down: Dynamic Low-Level Code set to Default in Manufacturing setup.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithLowLevelCodeTwo()
    var
        Item: Record Item;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemNo: array[20] of Code[20];
    begin
        // Setup: Dynamic Low-Level Code set to true in Manufacturing setup.
        Initialize();
        UpdateManufacturingSetup(TempManufacturingSetup, true);

        // Exercise: Create Item and Production BOM.Update Item with Production BOM.
        CreateItems(ItemNo);
        Item.Get(ItemNo[1]);
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[1], '', Item."Base Unit of Measure", false);
        UpdateItemProdBOM(ItemNo[3], ProductionBOMHeader."No.");
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[2], '', Item."Base Unit of Measure", false);
        UpdateItemProdBOM(ItemNo[4], ProductionBOMHeader."No.");
        CreateProdBOM(
          ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[5], ItemNo[6], Item."Base Unit of Measure", true);
        UpdateItemProdBOM(ItemNo[1], ProductionBOMHeader."No.");

        // Verify: Verify Low Level code in all the Items with maximum of 2 levels.
        VerifyLowLevelCode(ItemNo[3], ItemNo[4], 0);
        VerifyLowLevelCode(ItemNo[1], ItemNo[2], 1);
        VerifyLowLevelCode(ItemNo[5], ItemNo[6], 2);

        // Tear Down: Dynamic Low-Level Code set to Default in Manufacturing setup.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithLowLevelCodeThree()
    var
        Item: Record Item;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemNo: array[20] of Code[20];
    begin
        // Setup: Dynamic Low-Level Code set to true in Manufacturing setup.
        Initialize();
        UpdateManufacturingSetup(TempManufacturingSetup, true);

        // Exercise: Create Item and Production BOM.Update Item with Production BOM.
        CreateItems(ItemNo);
        Item.Get(ItemNo[1]);
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[4], ItemNo[5], Item."Base Unit of Measure", true);
        UpdateItemProdBOM(ItemNo[1], ProductionBOMHeader."No.");
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[1], ItemNo[2], Item."Base Unit of Measure", true);
        UpdateItemProdBOM(ItemNo[3], ProductionBOMHeader."No.");
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[3], ItemNo[4], Item."Base Unit of Measure", true);
        UpdateItemProdBOM(ItemNo[6], ProductionBOMHeader."No.");

        // Verify: Verify Low Level code in all the Items with maximum of three levels.
        VerifyLowLevelCode(ItemNo[1], ItemNo[2], 2);
        VerifyLowLevelCode(ItemNo[3], '', 1);
        VerifyLowLevelCode(ItemNo[4], ItemNo[5], 3);
        VerifyLowLevelCode(ItemNo[6], '', 0);

        // Tear Down: Dynamic Low-Level Code set to Default in Manufacturing setup.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithLowLevelCodeTypeBOM()
    var
        Item: Record Item;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMNo: Code[20];
        ItemNo: array[20] of Code[20];
    begin
        // Setup: Dynamic Low-Level Code set to true in Manufacturing setup.
        Initialize();
        UpdateManufacturingSetup(TempManufacturingSetup, true);

        // Exercise: Create Item and Production BOM one of them with line type as 'Production BOM'.
        // Update Item with Production BOM.
        CreateItems(ItemNo);
        Item.Get(ItemNo[1]);
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[1], ItemNo[2], Item."Base Unit of Measure", true);
        UpdateItemProdBOM(ItemNo[3], ProductionBOMHeader."No.");
        ProductionBOMNo := ProductionBOMHeader."No.";
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::"Production BOM", ProductionBOMNo, '', Item."Base Unit of Measure", false);
        UpdateItemProdBOM(ItemNo[4], ProductionBOMHeader."No.");
        CreateProdBOM(
          ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[5], ItemNo[6], Item."Base Unit of Measure", true);
        UpdateItemProdBOM(ItemNo[1], ProductionBOMHeader."No.");

        // Verify: Verify Low Level code in all the Items.
        VerifyLowLevelCode(ItemNo[1], ItemNo[2], 1);
        VerifyLowLevelCode(ItemNo[3], ItemNo[4], 0);
        VerifyLowLevelCode(ItemNo[5], ItemNo[6], 2);

        // Tear Down: Dynamic Low-Level Code set to Default in Manufacturing setup.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithLowLevelCodeTypeBoth()
    var
        Item: Record Item;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMNo: Code[20];
        ItemNo: array[20] of Code[20];
    begin
        // Setup: Dynamic Low-Level Code set to true in Manufacturing setup.
        Initialize();
        UpdateManufacturingSetup(TempManufacturingSetup, true);

        // Exercise: Create Item and Production BOM one of them with line type as both 'Production BOM' and Item.
        // Update Item with Production BOM.
        CreateItems(ItemNo);
        Item.Get(ItemNo[1]);
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[1], ItemNo[2], Item."Base Unit of Measure", true);
        UpdateItemProdBOM(ItemNo[3], ProductionBOMHeader."No.");
        ProductionBOMNo := ProductionBOMHeader."No.";
        CreateProdBOM(
          ProductionBOMHeader, ProductionBOMLine.Type::"Production BOM", ProductionBOMNo, '', Item."Base Unit of Measure", false);
        UpdateProductionBom(ProductionBOMHeader, ItemNo[3]);
        UpdateItemProdBOM(ItemNo[4], ProductionBOMHeader."No.");
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, ItemNo[4], ItemNo[5], Item."Base Unit of Measure", true);
        UpdateItemProdBOM(ItemNo[6], ProductionBOMHeader."No.");

        // Verify: Verify Low Level code in all the Items.
        VerifyLowLevelCode(ItemNo[1], ItemNo[2], 3);
        VerifyLowLevelCode(ItemNo[3], '', 2);
        VerifyLowLevelCode(ItemNo[4], ItemNo[5], 1);
        VerifyLowLevelCode(ItemNo[6], '', 0);

        // Tear Down: Dynamic Low-Level Code set to Default in Manufacturing setup.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowLevelCodeWithSKULevelProductionBOM()
    var
        CompItem: Record Item;
        SemiItem: Record Item;
        FinishedItem: Record Item;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        LocationCode: Code[10];
    begin
        // [SCENARIO 648732] [AI] 0.2 Multi-level BOMs assigned on Stockkeeping Units must get correct Low-Level Codes in a single pass.
        // [GIVEN] Dynamic Low-Level Code enabled.
        Initialize();
        UpdateManufacturingSetup(TempManufacturingSetup, true);
        LocationCode := CreateLocation();

        // [GIVEN] Three items: Component, Semi-finished and Finished, none carrying an Item-card Production BOM.
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(SemiItem);
        LibraryInventory.CreateItem(FinishedItem);

        // [GIVEN] Semi-finished item has a certified BOM (with the Component) assigned on its SKU.
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, CompItem."No.", '', SemiItem."Base Unit of Measure", false);
        CreateSKUWithProdBOM(SemiItem."No.", LocationCode, ProductionBOMHeader."No.");

        // [GIVEN] Finished item has a certified BOM (with the Semi-finished item) assigned on its SKU.
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, SemiItem."No.", '', FinishedItem."Base Unit of Measure", false);
        CreateSKUWithProdBOM(FinishedItem."No.", LocationCode, ProductionBOMHeader."No.");

        // [THEN] Low-Level Codes reflect the full multi-level SKU BOM structure without a second calculation.
        VerifyLowLevelCode(FinishedItem."No.", '', 0);
        VerifyLowLevelCode(SemiItem."No.", '', 1);
        VerifyLowLevelCode(CompItem."No.", '', 2);

        // Tear Down: Dynamic Low-Level Code set to Default in Manufacturing setup.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateLowLevelCodeWithExistingSKULevelProductionBOM()
    var
        CompItem: Record Item;
        SemiItem: Record Item;
        FinishedItem: Record Item;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        LocationCode: Code[10];
        SemiBOMNo: Code[20];
        FinishedBOMNo: Code[20];
    begin
        // [SCENARIO 648732] [AI] 0.2 Recalculating an item through Calculate Low-Level Code must resolve the full multi-level chain when the BOMs already exist on Stockkeeping Units.
        // [GIVEN] Dynamic Low-Level Code enabled and a 3-level SKU-only BOM structure (Finished -> Semi -> Component).
        Initialize();
        UpdateManufacturingSetup(TempManufacturingSetup, true);
        LocationCode := CreateLocation();

        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(SemiItem);
        LibraryInventory.CreateItem(FinishedItem);

        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, CompItem."No.", '', SemiItem."Base Unit of Measure", false);
        SemiBOMNo := ProductionBOMHeader."No.";
        CreateSKUWithProdBOM(SemiItem."No.", LocationCode, SemiBOMNo);

        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, SemiItem."No.", '', FinishedItem."Base Unit of Measure", false);
        FinishedBOMNo := ProductionBOMHeader."No.";
        CreateSKUWithProdBOM(FinishedItem."No.", LocationCode, FinishedBOMNo);

        // [GIVEN] All low-level codes are reset, simulating a recalculation over pre-existing data.
        ResetItemLowLevelCode(CompItem."No.");
        ResetItemLowLevelCode(SemiItem."No.");
        ResetItemLowLevelCode(FinishedItem."No.");
        ResetProdBOMLowLevelCode(SemiBOMNo);
        ResetProdBOMLowLevelCode(FinishedBOMNo);

        // [WHEN] Calculate Low-Level Code is run for the finished item (OnRun -> RecalcSKULowerLevels cascades down through SKU-level BOMs).
        RunCalculateLowLevelCode(FinishedItem."No.");

        // [THEN] The whole chain is recalculated through the SKU-level BOMs in a single pass.
        VerifyLowLevelCode(FinishedItem."No.", '', 0);
        VerifyLowLevelCode(SemiItem."No.", '', 1);
        VerifyLowLevelCode(CompItem."No.", '', 2);

        // [WHEN] Only the component is reset and recalculated (CalcLevels walks up through the SKU-level parents).
        ResetItemLowLevelCode(CompItem."No.");
        RunCalculateLowLevelCode(CompItem."No.");

        // [THEN] The component still resolves to level 2 by traversing its SKU-level BOM parents.
        VerifyLowLevelCode(CompItem."No.", '', 2);

        // Tear Down: Dynamic Low-Level Code set to Default in Manufacturing setup.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowLevelCodeWithMultipleSKUsForSameItemAndBOM()
    var
        CompItem: Record Item;
        ParentItem: Record Item;
        TempManufacturingSetup: Record "Manufacturing Setup" temporary;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        FirstLocationCode: Code[10];
        SecondLocationCode: Code[10];
        ParentBOMNo: Code[20];
    begin
        // [SCENARIO 648732] [AI] 0.2 Calculate Low-Level Code must resolve correctly and process the item only once when several SKUs of the same item share the same production BOM.
        // [GIVEN] Dynamic Low-Level Code enabled and two locations.
        Initialize();
        UpdateManufacturingSetup(TempManufacturingSetup, true);
        FirstLocationCode := CreateLocation();
        SecondLocationCode := CreateLocation();

        // [GIVEN] A component item and a parent item, with the parent's certified BOM (containing the component) assigned to two SKUs of the same parent item.
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(ParentItem);
        CreateProdBOM(ProductionBOMHeader, ProductionBOMLine.Type::Item, CompItem."No.", '', ParentItem."Base Unit of Measure", false);
        ParentBOMNo := ProductionBOMHeader."No.";
        CreateSKUWithProdBOM(ParentItem."No.", FirstLocationCode, ParentBOMNo);
        CreateSKUWithProdBOM(ParentItem."No.", SecondLocationCode, ParentBOMNo);

        // [GIVEN] All low-level codes are reset, simulating a recalculation over pre-existing data.
        ResetItemLowLevelCode(CompItem."No.");
        ResetItemLowLevelCode(ParentItem."No.");
        ResetProdBOMLowLevelCode(ParentBOMNo);

        // [WHEN] Calculate Low-Level Code is run for the component (CalcLevels walks up through both SKUs pointing to the same BOM).
        RunCalculateLowLevelCode(CompItem."No.");

        // [THEN] The codes resolve correctly regardless of the number of duplicate SKUs pointing to the same BOM.
        VerifyLowLevelCode(ParentItem."No.", '', 0);
        VerifyLowLevelCode(CompItem."No.", '', 1);

        // Tear Down: Dynamic Low-Level Code set to Default in Manufacturing setup.
        RestoreManufacturingSetup(TempManufacturingSetup);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Manuf Low Level Code");
        ManufacturingSetup.Get();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Manuf Low Level Code");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Manuf Low Level Code");
    end;

    [Normal]
    local procedure UpdateManufacturingSetup(var BaseManufacturingSetup: Record "Manufacturing Setup"; DynamicLowLevelCode: Boolean)
    begin
        ManufacturingSetup.Get();
        BaseManufacturingSetup := ManufacturingSetup;
        BaseManufacturingSetup.Insert(true);

        ManufacturingSetup."Dynamic Low-Level Code" := DynamicLowLevelCode;
        ManufacturingSetup.Modify(true);
    end;

    local procedure RestoreManufacturingSetup(TempManufacturingSetup: Record "Manufacturing Setup" temporary)
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Dynamic Low-Level Code" := TempManufacturingSetup."Dynamic Low-Level Code";
        ManufacturingSetup.Modify(true);
    end;

    local procedure CreateItems(var ItemNo: array[20] of Code[20])
    var
        Item: Record Item;
        i: Integer;
    begin
        for i := 1 to 6 do begin
            LibraryInventory.CreateItem(Item);
            ItemNo[i] := Item."No.";
        end;
    end;

    local procedure CreateProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; Type: Enum "Production BOM Line Type"; No: Code[20]; No2: Code[20]; BaseUnitofMeasure: Code[10]; MultipleBOMLine: Boolean)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitofMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No, 1);
        if MultipleBOMLine then
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No2, 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateItemProdBOM(ItemNo: Code[20]; ProductionBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        exit(LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
    end;

    local procedure CreateSKUWithProdBOM(ItemNo: Code[20]; LocationCode: Code[10]; ProductionBOMNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Production BOM No.", ProductionBOMNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure ResetItemLowLevelCode(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item."Low-Level Code" := 0;
        Item.Modify();
    end;

    local procedure ResetProdBOMLowLevelCode(ProductionBOMNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        ProductionBOMHeader."Low-Level Code" := 0;
        ProductionBOMHeader.Modify();
    end;

    local procedure RunCalculateLowLevelCode(ItemNo: Code[20])
    var
        Item: Record Item;
        CalculateLowLevelCode: Codeunit "Calculate Low-Level Code";
    begin
        Item.Get(ItemNo);
        CalculateLowLevelCode.Run(Item);
    end;

    local procedure UpdateProductionBom(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure VerifyLowLevelCode(No: Code[20]; No2: Code[20]; LowLevelCode: Integer)
    var
        Item: Record Item;
    begin
        if No2 <> '' then
            Item.SetRange("No.", No, No2);
        Item.SetRange("No.", No);
        Item.FindSet();
        repeat
            Item.TestField("Low-Level Code", LowLevelCode);
        until Item.Next() = 0;
    end;
}

