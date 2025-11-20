// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.NoSeries;
using Microsoft.Finance.Analysis;

codeunit 137210 "SCM Copy Production BOM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Production BOM] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        ErrAutoCopy: Label 'The Production BOM Header cannot be copied to itself.';
        ErrBOMIsCertified: Label 'Status on Production BOM Header %1 must not be Certified';
        ProdBOMVersionCode: Code[20];
        ErrBomVersionIsCertified: Label 'Status on Production BOM Version %1';
        ProdBOMNo: Code[20];
        CountError: Label 'Version Count Must Match.';
        OverHeadCostErr: Label 'Overhead Cost must be %1 in %2.', Comment = '%1= Field Value, %2= FieldCaption.';
        ManufacturingOverhead: Label 'Expected Overhead = %1, but Statistics shows = %2', Comment = '%1=Expected Overhead, %2=Overhead from Statistics page.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Copy Production BOM");
        Clear(ProdBOMNo);
        Clear(ProdBOMVersionCode);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Copy Production BOM");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Copy Production BOM");
    end;

    [Normal]
    local procedure CopyToHeader(var ProductionBOMHeader: Record "Production BOM Header"; BOMStatus: Enum "BOM Status")
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and Version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, BOMStatus);

        // Create destination Production BOM Header.
        CreateProductionBOM(ProductionBOMHeader);

        // Set status on destination BOM Header.
        ProductionBOMHeader.Validate(Status, BOMStatus);
        ProductionBOMHeader.Modify(true);

        // Exercise: Copy BOM from source Production BOM Header.
        ProductionBOMCopy.CopyBOM(ProdBOMNo, '', ProductionBOMHeader, '');

        // Verify: Production BOM lines are retrieved from source Production BOM.
        VerifyProductionBOMLines(ProdBOMNo, ProductionBOMHeader."No.", '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CopyToHeader(ProductionBOMHeader, ProductionBOMHeader.Status::New);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToCertifiedHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        asserterror CopyToHeader(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // Verify: Error: Destination BOM should not be certified.
        Assert.AreEqual(StrSubstNo(ErrBOMIsCertified, ProductionBOMHeader."No."), GetLastErrorText, '');
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToSameHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyToHeader(ProductionBOMHeader, ProductionBOMHeader.Status::New);

        // Exercise: Copy BOM from the same Production BOM Header.
        ProductionBOMHeader.Get(ProdBOMNo);
        asserterror ProductionBOMCopy.CopyBOM(ProdBOMNo, '', ProductionBOMHeader, '');

        // Verify: Error: BOM header cannot be copied to itself.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrAutoCopy) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromSameHeaderTwiceToHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyToHeader(ProductionBOMHeader, ProductionBOMHeader.Status::New);

        // Exercise: Copy again from Production BOM Header.
        ProductionBOMCopy.CopyBOM(ProdBOMNo, '', ProductionBOMHeader, '');

        // Verify: Production BOM lines are retrieved from source Production BOM.
        VerifyProductionBOMLines(ProdBOMNo, ProductionBOMHeader."No.", '', '');
    end;

    [Normal]
    local procedure CopyFromHeaderToVersion(var ProductionBOMVersion: Record "Production BOM Version"; BOMStatus: Enum "BOM Status")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, BOMStatus);

        // Exercise: Copy BOM from source Production BOM Header.
        ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate("Unit of Measure Code", ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Modify(true);

        // Verify: Production BOM lines are retrieved from source Production BOM Header.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", '', ProductionBOMVersion."Version Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        CopyFromHeaderToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToCertifiedVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        asserterror CopyFromHeaderToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::Certified);

        // Verify: Error: destination should not be certified.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrBomVersionIsCertified, ProdBOMNo)) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromSameHeaderTwiceToVersion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyFromHeaderToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);

        // Exercise: Copy BOM from source Production BOM Header again.
        ProductionBOMHeader.Get(ProdBOMNo);
        ProductionBOMCopy.CopyBOM(ProdBOMNo, '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate("Unit of Measure Code", ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Modify(true);

        // Verify: Production BOM lines are retrieved from source Production BOM Header.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", '', ProductionBOMVersion."Version Code");
    end;

    [Normal]
    local procedure CopyFromVersionToVersion(var ProductionBOMVersion: Record "Production BOM Version"; BOMStatus: Enum "BOM Status")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, BOMStatus);

        // Exercise: Copy BOM version from the desired BOM version.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);

        // Verify: Production BOM lines are retrieved from source Production BOM Version.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", ProdBOMVersionCode,
          ProductionBOMVersion."Version Code");
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromVersionToVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        CopyFromVersionToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromVersionToSameVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyFromVersionToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);

        // Exercise: Copy BOM version to same BOM version.
        ProductionBOMVersion.Get(ProdBOMNo, ProdBOMVersionCode);
        asserterror ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);

        // Verify: Error: Cannot use the same version as source.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrAutoCopy) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromVersionToCertifiedVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        asserterror CopyFromVersionToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::Certified);

        // Verify: Error: destination should not be certified.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrBomVersionIsCertified, ProdBOMNo)) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromSameVersionTwiceToVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyFromVersionToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);

        // Exercise: Copy again from same version.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);

        // Verify: Production BOM lines are retrieved from source Production BOM Version.
        VerifyProductionBOMLines(ProdBOMNo, ProdBOMNo, ProdBOMVersionCode, ProductionBOMVersion."Version Code");
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromVersionThenHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::New);

        // Exercise: Copy BOM version, first from the BOM version, then from the Production BOM header.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);
        ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate("Unit of Measure Code", ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Modify(true);

        // Verify: BOM lines are copied from previous header only once.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", '', ProductionBOMVersion."Version Code");
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromHeaderThenVersion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::New);

        // Exercise: Copy BOM version from Header, then from the other Production BOM version.
        ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);

        // Verify: Error: BOM lines are copied from previous version only once.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", ProdBOMVersionCode,
          ProductionBOMVersion."Version Code");
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure MatrixPageVersionToVersion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
        VersionCode: array[32] of Text[80];
        VersionCount: Integer;
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMVersion.Status::New);

        // Exercise: Copy BOM version from the desired BOM version, Generating Matrix Data and Calculating Total No. of Version Count And
        // version.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);
        VersionCount := GenerateMatrixData(VersionCode, ProductionBOMHeader."No.");

        // Verify : BOM Matrix Column Count And Column with source Production BOM Version.
        VerifyMatrixBOMVersion(ProductionBOMHeader."No.", VersionCode, VersionCount);
    end;

    [Test]
    [HandlerFunctions('ProductionBOMVersionPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyProductionBOMVersionFromItemCard()
    var
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 346526] Verify Production BOM Version page should open when there is active version of production BOM and should be certified from Item Card page.
        Initialize();

        // [GIVEN] Create a Production BOM with BOM Versions.
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Create and update Production Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Base Unit of Measure", ProductionBOMHeader."Unit of Measure Code");
        ProdItem."Replenishment System" := ProdItem."Replenishment System"::"Prod. Order";
        ProdItem."Manufacturing Policy" := ProdItem."Manufacturing Policy"::"Make-to-Order";
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Open Production BOM Version page from Item Card.
        LibraryVariableStorage.Enqueue(ProductionBOMVersion."Version Code");
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(ProdItem);
        ItemCard."Prod. Active BOM Version".Invoke();

        // [Verify] Verify Production BOM Version through "ProductionBOMVersionPageHandler".
    end;

    [Test]
    [HandlerFunctions('ProductionBOMVersionPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyProductionBOMVersionFromItemList()
    var
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 346526] Verify Production BOM Version page should open when there is active version of production BOM and should be certified from Item List page.
        Initialize();

        // [GIVEN] Create a Production BOM with BOM Versions.
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Create and update Production Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Base Unit of Measure", ProductionBOMHeader."Unit of Measure Code");
        ProdItem."Replenishment System" := ProdItem."Replenishment System"::"Prod. Order";
        ProdItem."Manufacturing Policy" := ProdItem."Manufacturing Policy"::"Make-to-Order";
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Open Production BOM Version page from Item List.
        LibraryVariableStorage.Enqueue(ProductionBOMVersion."Version Code");
        ItemList.OpenEdit();
        ItemList.GotoRecord(ProdItem);
        ItemList."Prod. Active BOM Version".Invoke();

        // [Verify] Verify Production BOM Version through "ProductionBOMVersionPageHandler".
    end;

    [Test]
    [HandlerFunctions('SelectMultiItemsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdBOMVersionLinesSelectMultipleItems()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersionTestPage: TestPage "Production BOM Version";
    begin
        // [SCENARIO 347825] Run Action "Select items" on Prod. BOM Version Lines Page adds selected items.
        Initialize();

        // [GIVEN] Create a Production BOM with BOM Versions.
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::New);

        // [WHEN] Run action "Select items" on Production BOM Version Lines Page.
        ProductionBOMVersionTestPage.OpenEdit();
        ProductionBOMVersionTestPage.GoToRecord(ProductionBOMVersion);
        ProductionBOMVersionTestPage.ProdBOMLine.SelectMultiItems.Invoke();

        // [THEN] Verify the count of Prod. BOM Version Line as one line is added.
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMVersion."Production BOM No.");
        ProductionBOMLine.SetRange("Version Code", ProductionBOMVersion."Version Code");
        Assert.RecordCount(ProductionBOMLine, 1);
    end;

    [Test]
    [HandlerFunctions('SelectCancelMultiItemsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdBOMVersionLinesCancelSelectMultipleItems()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersionTestPage: TestPage "Production BOM Version";
    begin
        // [SCENARIO 347825] Run Action "Select items" on Prod. BOM Version Lines Page not add selected items.
        Initialize();

        // [GIVEN] Create a Production BOM with BOM Versions.
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::New);

        // [WHEN] Run action "Select items" on Production BOM Version Lines Page.
        ProductionBOMVersionTestPage.OpenEdit();
        ProductionBOMVersionTestPage.GoToRecord(ProductionBOMVersion);
        ProductionBOMVersionTestPage.ProdBOMLine.SelectMultiItems.Invoke();

        // [THEN] Verify the count of Prod. BOM Version Line as line is not added.
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMVersion."Production BOM No.");
        ProductionBOMLine.SetRange("Version Code", ProductionBOMVersion."Version Code");
        Assert.RecordCount(ProductionBOMLine, 0);
    end;

    [Test]
    [HandlerFunctions('SelectMultiItemsModalPageHandlerForService')]
    procedure VerifyProdBOMVersionLinesCannotShowServiceItemOnSelectMultipleItems()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMVersionTestPage: TestPage "Production BOM Version";
    begin
        // [SCENARIO 560153] Verify Service items are not shown When Run Action "Select items" on Prod. BOM Version Lines Page.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Update Type in Item.
        Item.Validate(Type, Item.Type::Service);
        Item.Modify();

        // [GIVEN] Create a Production BOM with BOM Versions.
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::New);

        // [GIVEN] Enqueue Item No. 
        LibraryVariableStorage.Enqueue(Item."No.");

        // [WHEN] Run action "Select items" on Production BOM Version Lines Page.
        ProductionBOMVersionTestPage.OpenEdit();
        ProductionBOMVersionTestPage.GoToRecord(ProductionBOMVersion);
        ProductionBOMVersionTestPage.ProdBOMLine.SelectMultiItems.Invoke();

        // [THEN] Verify Service items are not shown When Run Action "Select items" on Prod. BOM Version Lines Page through SelectMultiItemsModalPageHandlerForService Handler.
    end;

    [Test]
    procedure ReleasedProductionOrderStatisticsCorrectExpectedCosts()
    var
        Item: array[4] of Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ExpectedMfgCost: Decimal;
        ExpectedMfgOverheadCost: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 561759] Released Production Order Statistics shows correct Expected Costs.
        Initialize();

        // [GIVEN] Create Items with Standard Cost and Overhead Cost.
        CreateItem(Item[1], LibraryRandom.RandIntInRange(2, 2), 0);
        CreateItem(Item[2], LibraryRandom.RandIntInRange(6, 6), LibraryRandom.RandIntInRange(4, 4));
        CreateItem(Item[3], LibraryRandom.RandIntInRange(7, 7), 0);
        CreateItem(Item[4], LibraryRandom.RandIntInRange(7, 7), LibraryRandom.RandIntInRange(2, 2));

        // [GIVEN] Create Work Center and Work Center Calendar.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1Y>', WorkDate()), CalcDate('<1Y>', WorkDate()));

        // [GIVEN] Create Routing Header.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Create Routing Line with Work Center.
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)),
            RoutingLine.Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Validate Setup Time, Run Time and Concurrent Capacities.
        RoutingLine.Validate("Setup Time", LibraryRandom.RandIntInRange(1, 1));
        RoutingLine.Validate("Run Time", LibraryRandom.RandIntInRange(3, 3));
        RoutingLine.Validate("Concurrent Capacities", LibraryRandom.RandIntInRange(1, 1));
        RoutingLine.Modify(true);

        // [GIVEN] Certify the Routing Header.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // [GIVEN] Add Routing No. in Items.
        Item[2].Validate("Routing No.", RoutingHeader."No.");
        Item[2].Modify(true);
        Item[4].Validate("Routing No.", RoutingHeader."No.");
        Item[4].Modify(true);

        // [GIVEN] Create Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create Production BOM Line with Items.
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandDec(1, 2));
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[3]."No.", LibraryRandom.RandDecInRange(3, 3, 2));

        // [GIVEN] Store Quantity in Variable.
        Quantity := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Certify the Production BOM Header.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create Production Order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
            Item[1]."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Create Production Order Lines for Items.
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item[2]."No.", '', '', Quantity);
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item[4]."No.", '', '', Quantity);

        // [GIVEN] Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [GIVEN] Calculate Expected Manufacturing Cost.
        ExpectedMfgCost := (Item[2]."Overhead Rate" + Item[4]."Overhead Rate") * Quantity;

        // [WHEN] Open Production Order Statistics.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ProductionOrderStatistics.Trap();
        ReleasedProductionOrder.Statistics.Invoke();

        // [THEN] Store Manufacturing Overhead Expected Cost.
        Evaluate(ExpectedMfgOverheadCost, ProductionOrderStatistics.MfgOverhead_ExpectedCost.Value());

        // [THEN] Manufacturing Overhead Expected Cost is equal to Overhead cost of Items in Production Order.
        Assert.AreEqual(
            ExpectedMfgCost,
            ExpectedMfgOverheadCost,
            StrSubstNo(
                OverHeadCostErr,
                ExpectedMfgOverheadCost,
                ProductionOrderStatistics.MfgOverhead_ExpectedCost.Caption()));
    end;

    [Test]
    procedure FirmedProdOrderStatisticsCheckOverhead()
    var
        ParentItem: Record Item;
        RawItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        FirmedProductionOrder: TestPage "Firm Planned Prod. Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        MfgOverheadExpectedCost: Decimal;
        MfgOverheadExpectedCost1: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 593018] Manufacturing overhead is wrong in the production order statistics page (99000816) and report (99000791).
        Initialize();

        // [GIVEN] Create Raw Item with specified Unit Cost
        CreateItem(RawItem, 0, 0);
        RawItem.Validate(Type, RawItem.Type::Inventory);
        RawItem.Validate("Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        RawItem.Modify(true);

        // [GIVEN] Create Production BOM and add Raw Item with Qty = 1
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, RawItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, RawItem."No.", 1);
        ProductionBOMHeader.Validate("Unit of Measure Code", RawItem."Base Unit of Measure");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create Parent Item with Indirect Cost % and link to BOM
        CreateItem(ParentItem, 0, 0); // No direct cost or overhead
        ParentItem.Validate("Indirect Cost %", LibraryRandom.RandIntInRange(10, 10));
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);

        // [GIVEN] Create Firm Planned Production Order for Parent Item
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, '', 0);

        // [GIVEN] Store Quantity in Variable.
        Quantity := LibraryRandom.RandIntInRange(20, 20);

        // [GIVEN] Create line only (do NOT populate header)
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ParentItem."No.", '', '', Quantity);

        // [WHEN] Refresh Prod Order with Lines = false (header only)
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        MfgOverheadExpectedCost := (RawItem."Unit Cost" * ParentItem."Indirect Cost %" / 100 * Quantity);

        // [GIVEN] Create Firm Planned Production Order for Parent Item
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, '', 0);

        // [GIVEN] Create multiple lines (do NOT populate header)
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ParentItem."No.", '', '', LibraryRandom.RandIntInRange(10, 10));
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ParentItem."No.", '', '', LibraryRandom.RandIntInRange(10, 10));

        // [WHEN] Refresh Prod Order with Lines = false (header only)
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [WHEN] Open Firmed Prod Order Statistics page
        FirmedProductionOrder.OpenEdit();
        FirmedProductionOrder.GoToRecord(ProductionOrder);
        ProductionOrderStatistics.Trap();
        FirmedProductionOrder.Statistics.Invoke();

        // [THEN] Get Mfg Overhead Expected Cost
        Evaluate(MfgOverheadExpectedCost1, ProductionOrderStatistics.MfgOverhead_ExpectedCost.Value());

        // [ASSERT] Overhead in statistics equals expected overhead
        Assert.AreEqual(
            MfgOverheadExpectedCost,
            MfgOverheadExpectedCost1,
            StrSubstNo(ManufacturingOverhead,
                Format(MfgOverheadExpectedCost),
                Format(MfgOverheadExpectedCost1)));
                
    end;

    [Normal]
    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header")
    var
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
        Item: Record Item;
        Counter: Integer;
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);
        ProductionBOMHeader.Validate("Version Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ProductionBOMHeader.Modify(true);

        for Counter := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.",
              LibraryRandom.RandInt(10));
        end;
    end;

    [Normal]
    local procedure FindProductionBOMLines(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20]; VersionCode: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.FindSet();
    end;

    [Normal]
    local procedure VerifyProductionBOMLines(FromProductionBOMNo: Code[20]; ToProductionBOMNo: Code[20]; FromVersionCode: Code[20]; ToVersionCode: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMLine1: Record "Production BOM Line";
        IsLastRecord: Integer;
    begin
        FindProductionBOMLines(ProductionBOMLine, FromProductionBOMNo, FromVersionCode);
        FindProductionBOMLines(ProductionBOMLine1, ToProductionBOMNo, ToVersionCode);

        // Navigate through source and destination Production BOM Lines in parallel.
        repeat
            ProductionBOMLine1.TestField(Type, ProductionBOMLine.Type);
            ProductionBOMLine1.TestField("No.", ProductionBOMLine."No.");
            ProductionBOMLine1.TestField("Unit of Measure Code", ProductionBOMLine."Unit of Measure Code");
            ProductionBOMLine1.TestField(Quantity, ProductionBOMLine.Quantity);
            ProductionBOMLine1.TestField("Variant Code", ProductionBOMLine."Variant Code");
            ProductionBOMLine1.TestField("Starting Date", ProductionBOMLine."Starting Date");
            ProductionBOMLine1.TestField("Ending Date", ProductionBOMLine."Ending Date");
            ProductionBOMLine1.TestField("Calculation Formula", ProductionBOMLine."Calculation Formula");
            ProductionBOMLine1.TestField("Quantity per", ProductionBOMLine."Quantity per");
            IsLastRecord := ProductionBOMLine1.Next();
        until ProductionBOMLine.Next() = 0;

        Assert.AreEqual(0, IsLastRecord, 'There are more lines in the destination Production BOM.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdBOMListHandler(var ProdBOMVersionList: Page "Prod. BOM Version List"; var Response: Action)
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Select source version from Production BOM Version List lookup page.
        ProductionBOMVersion.SetRange("Production BOM No.", ProdBOMNo);
        ProductionBOMVersion.SetRange("Version Code", ProdBOMVersionCode);
        ProductionBOMVersion.FindFirst();
        ProdBOMVersionList.SetTableView(ProductionBOMVersion);
        ProdBOMVersionList.SetRecord(ProductionBOMVersion);
        Response := ACTION::LookupOK;
    end;

    [Normal]
    local procedure SetupCopyBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMVersion: Record "Production BOM Version"; BOMStatus: Enum "BOM Status")
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        NoSeries: Codeunit "No. Series";
        VersionCode: Text[20];
    begin
        // Create source Production BOM Header.
        CreateProductionBOM(ProductionBOMHeader);
        ProdBOMNo := ProductionBOMHeader."No.";

        // Add first version to BOM Header.
        VersionCode := NoSeries.GetNextNo(ProductionBOMHeader."Version Nos.");
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.",
          CopyStr(VersionCode, StrLen(VersionCode) - 9, 10), ProductionBOMHeader."Unit of Measure Code");
        ProdBOMVersionCode := ProductionBOMVersion."Version Code";

        // Make sure the first version is not empty.
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code",
          ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // Create destination version.
        Clear(ProductionBOMVersion);
        VersionCode := NoSeries.GetNextNo(ProductionBOMHeader."Version Nos.");
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.",
          CopyStr(VersionCode, StrLen(VersionCode) - 9, 10), ProductionBOMHeader."Unit of Measure Code");

        // Set status on version.
        ProductionBOMVersion.Validate(Status, BOMStatus);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure GenerateMatrixData(var VersionCode: array[32] of Text[80]; ProductionBOMNo: Code[20]): Integer
    var
        ProductionBOMVersion: Record "Production BOM Version";
        MatrixManagement: Codeunit "Matrix Management";
        RecRef: RecordRef;
        SetWanted: Option First,Previous,Same,Next;
        CaptionRange: Text;
        FirstMatrixRecInSet: Text;
        ColumnCount: Integer;
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        RecRef.GetTable(ProductionBOMVersion);
        MatrixManagement.GenerateMatrixData(
          RecRef, SetWanted::First, ArrayLen(VersionCode), ProductionBOMVersion.FieldNo("Version Code"),
          FirstMatrixRecInSet, VersionCode, CaptionRange, ColumnCount);
        exit(ColumnCount);
    end;

    local procedure VerifyMatrixBOMVersion(ProductionBOMNo: Code[20]; VersionCode: array[32] of Text[80]; VersionCount: Integer)
    var
        ProductionBOMVersion: Record "Production BOM Version";
        I: Integer;
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMVersion.FindFirst();
        Assert.AreEqual(VersionCount, ProductionBOMVersion.Count, CountError);

        for I := 1 to VersionCount do begin
            ProductionBOMVersion.SetRange("Version Code", VersionCode[VersionCount]);
            ProductionBOMVersion.FindFirst();
        end;
    end;

    local procedure CreateItem(var Item: Record Item; StandardCost: Decimal; OverheadRate: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Standard Cost", StandardCost);
        Item.Validate("Overhead Rate", OverheadRate);
        Item.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionBOMVersionPageHandler(var ProductionBOMVersion: TestPage "Production BOM Version")
    begin
        ProductionBOMVersion."Version Code".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectMultiItemsModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Next();
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCancelMultiItemsModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Next();
        ItemList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectMultiItemsModalPageHandlerForService(var ItemList: TestPage "Item List")
    begin
        ItemList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemList."No.".AssertEquals('');
    end;
}

