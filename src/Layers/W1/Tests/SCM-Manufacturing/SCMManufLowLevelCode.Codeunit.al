// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

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

