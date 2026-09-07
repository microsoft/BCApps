// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using System.TestLibraries.Utilities;

codeunit 137436 "Prod. BOM Comment Line Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ProdBOMVersionListModalPageHandler')]
    procedure VersionCodeLookupShowsVersionsForProductionBOM()
    var
        Item: Record Item;
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
        ProductionBOMHeader: Record "Production BOM Header";
        OtherProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCommentLineTest: TestPage "Prod. BOM Comment Line Test";
        VersionCode1: Code[20];
        VersionCode2: Code[20];
        OtherVersionCode: Code[20];
        ActualVersionCode1: Text;
        ActualVersionCode2: Text;
        ActualVersionCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 640428] Version Code lookup is not restricted to the comment line's current version.
        Initialize();

        // [GIVEN] Production BOM "B" with versions "V1" and "V2".
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        VersionCode1 := 'V1';
        VersionCode2 := 'V2';
        LibraryManufacturing.CreateProductionBOMVersion(
            ProductionBOMVersion, ProductionBOMHeader."No.", VersionCode1, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMVersion(
            ProductionBOMVersion, ProductionBOMHeader."No.", VersionCode2, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, VersionCode1, ProductionBOMLine.Type::Item, Item."No.", 1);

        // [GIVEN] Another Production BOM with version "V3".
        LibraryManufacturing.CreateProductionBOMHeader(OtherProductionBOMHeader, Item."Base Unit of Measure");
        OtherVersionCode := 'V3';
        LibraryManufacturing.CreateProductionBOMVersion(
            ProductionBOMVersion, OtherProductionBOMHeader."No.", OtherVersionCode, Item."Base Unit of Measure");

        // [GIVEN] Production BOM comment line for a line in "V1".
        LibraryManufacturing.CreateProductionBOMCommentLine(ProductionBOMLine);
        ProductionBOMCommentLine.Get(
            ProductionBOMLine."Production BOM No.", ProductionBOMLine."Line No.", ProductionBOMLine."Version Code", 10000);
        ProductionBOMCommentLineTest.OpenEdit();
        ProductionBOMCommentLineTest.GoToRecord(ProductionBOMCommentLine);

        // [WHEN] Version Code lookup is opened.
        ProductionBOMCommentLineTest."Version Code".Lookup();

        // [THEN] The lookup contains only "V1" and "V2".
        ActualVersionCount := LibraryVariableStorage.DequeueInteger();
        ActualVersionCode1 := LibraryVariableStorage.DequeueText();
        ActualVersionCode2 := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(2, ActualVersionCount, 'The Version Code lookup must show all versions for the production BOM.');
        Assert.AreEqual(VersionCode1, ActualVersionCode1, 'The first version in the lookup is incorrect.');
        Assert.AreEqual(VersionCode2, ActualVersionCode2, 'The second version in the lookup is incorrect.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure BOMLineNoRejectsLineFromDifferentVersion()
    var
        Item: Record Item;
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLineVersion1: Record "Production BOM Line";
        ProductionBOMLineVersion2: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        VersionCode1: Code[20];
        VersionCode2: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 640428] BOM Line No. rejects a line that belongs to another production BOM version.
        Initialize();

        // [GIVEN] Production BOM "B" with versions "V1" and "V2".
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        VersionCode1 := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(VersionCode1));
        VersionCode2 := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(VersionCode2));
        LibraryManufacturing.CreateProductionBOMVersion(
            ProductionBOMVersion, ProductionBOMHeader."No.", VersionCode1, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMVersion(
            ProductionBOMVersion, ProductionBOMHeader."No.", VersionCode2, Item."Base Unit of Measure");

        // [GIVEN] Production BOM line "L1" belongs to "V1" and line "L2" belongs only to "V2".
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLineVersion1, VersionCode1,
            ProductionBOMLineVersion1.Type::Item, Item."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLineVersion2, VersionCode2,
            ProductionBOMLineVersion2.Type::Item, Item."No.", 1);
        ProductionBOMLineVersion2.Rename(
            ProductionBOMLineVersion2."Production BOM No.", ProductionBOMLineVersion2."Version Code",
            ProductionBOMLineVersion1."Line No." + 10000);

        // [GIVEN] Production BOM comment line for "L1" in "V1".
        LibraryManufacturing.CreateProductionBOMCommentLine(ProductionBOMLineVersion1);
        ProductionBOMCommentLine.Get(
            ProductionBOMLineVersion1."Production BOM No.", ProductionBOMLineVersion1."Line No.",
            ProductionBOMLineVersion1."Version Code", 10000);

        // [WHEN] BOM Line No. is changed to the line from "V2".
        asserterror ProductionBOMCommentLine.Validate("BOM Line No.", ProductionBOMLineVersion2."Line No.");

        // [THEN] The line is rejected because it does not belong to "V1".
        Assert.ExpectedErrorCannotFind(Database::"Production BOM Line");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. BOM Comment Line Tests");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. BOM Comment Line Tests");
        LibrarySetupStorage.SaveManufacturingSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. BOM Comment Line Tests");
    end;

    [ModalPageHandler]
    procedure ProdBOMVersionListModalPageHandler(var ProductionBOMVersionList: TestPage "Prod. BOM Version List")
    var
        VersionCode1: Text;
        VersionCode2: Text;
        VersionCount: Integer;
    begin
        if ProductionBOMVersionList.First() then
            repeat
                VersionCount += 1;
                case VersionCount of
                    1:
                        VersionCode1 := ProductionBOMVersionList."Version Code".Value();
                    2:
                        VersionCode2 := ProductionBOMVersionList."Version Code".Value();
                end;
            until not ProductionBOMVersionList.Next();

        LibraryVariableStorage.Enqueue(VersionCount);
        LibraryVariableStorage.Enqueue(VersionCode1);
        LibraryVariableStorage.Enqueue(VersionCode2);
        ProductionBOMVersionList.Cancel().Invoke();
    end;
}
